# ``StructuredQueriesTursoVecCore``

StructuredQueries helpers for Turso Database's native vector functions.

## Overview

``TursoVec`` generates SQL and bindings for the
[Turso Database vector API](https://docs.turso.tech/sql-reference/functions/vector).
Use a compatible Turso driver to execute statements. This module exports
`StructuredQueriesVectorCore`; ordinary `@Table` models need no extra vector conformance.

SQL comments show the generated queries with placeholders for bound values.

### Create a table and search

Execute this schema through your driver, following
[Turso's table example](https://turso.tech/blog/a-complete-guide-to-database-per-agent-architecture):

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  content TEXT NOT NULL,
  embedding F32_BLOB(4) NOT NULL
);
```

`F32_BLOB(4)` describes four-dimensional Float32 data with
[BLOB affinity](https://github.com/tursodatabase/turso/blob/2487f62c372c99a21551a6450d4a10309c7dad2b/core/vdbe/affinity.rs#L186-L202).
Plain `BLOB` also works. The engine does not enforce the
[declared count](https://github.com/tursodatabase/turso-go/blob/ea06d135c592ae9a653ebf6ba5e069c8417c030c/turso_test.go#L354-L366);
`EmbeddingVector<4>` validates it when decoding. Fixed-size types require Swift 6.2 and iOS 26,
macOS 26, tvOS 26, watchOS 26, or visionOS 26.

```swift
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore

@Table("documents")
struct Document {
  var id: Int
  var content: String
  var embedding: EmbeddingVector<4>
}

let embedding = TursoVec.vector32("[0.1, 0.3, 0.5, 0.7]", as: EmbeddingVector<4>.self)
// vector32(?)
let insert = Document.insert { ($0.id, $0.content, $0.embedding) } values: {
  (1, "Introduction to databases", embedding)
}
// INSERT INTO "documents" ("id", "content", "embedding") VALUES (?, ?, vector32(?))

let vector = EmbeddingVector<4>([0.2, 0.4, 0.6, 0.8])
let query = Document
  .order { TursoVec.distanceCosine($0.embedding, to: vector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
// SELECT "documents"."content", vector_extract("documents"."embedding")
// FROM "documents"
// ORDER BY vector_distance_cos("documents"."embedding", ?) ASC
// LIMIT ?

let prepared = query.query.prepare { "?\($0)" }
// SELECT "documents"."content", vector_extract("documents"."embedding")
// FROM "documents"
// ORDER BY vector_distance_cos("documents"."embedding", ?1) ASC
// LIMIT ?2
// Pass prepared.sql and prepared.bindings to your driver.
```

For variable-size values, use `[Float]` with `@Column(as: [Float].VectorBytesRepresentation.self)`.
Distance ordering performs exact search over candidate rows; a `where` clause can narrow them.
Experimental sparse indexing uses separate DDL and has no helper in this target.

### Formats and distances

Convert JSON explicitly using the constructor for the column's format:

| Helper | SQL function | Default result |
| --- | --- | --- |
| `vector32` / `vector` | `vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `vector64` | `vector64` | `[Double].TursoFloat64BytesRepresentation` |
| `vector8` | `vector8` | `Quantized8Vector` |
| `vector1bit` | `vector1bit` | `[Bool].TursoBytesRepresentation` |
| `vector32Sparse` | `vector32_sparse` | `SparseFloat32Vector` |

```swift
let distances = Document.select {
  TursoVec.distanceCosine($0.embedding, to: TursoVec.vector32("[0.2, 0.4, 0.6, 0.8]"))
}
// SELECT vector_distance_cos("documents"."embedding", vector32(?))
// FROM "documents"
```

`distanceCosine`, `distanceL2`, `distanceDot` (negative dot product), and `distanceJaccard`
use smaller values for closer matches. Swift requires matching encodings; the database checks
matching dimensions. Numeric Jaccard is weighted; binary Jaccard compares true-bit sets.
Binary L2 is unavailable.

### Compatible constructor inputs

Constructors accept JSON string expressions or vectors whose `Encoding` conforms to
``TursoVectorEncoding``. The protocol belongs to this target; shared Float32, Turso Float64,
binary, quantized, and sparse encodings conform. Fixed-size and custom representations inherit
compatibility through their canonical encoding. `extract` requires a compatible vector.

```swift
let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
let precise = TursoVec.vector64(vector)
// vector64(?)
let json = TursoVec.extract(precise)
// vector_extract(vector64(?))
```

Raw Double, Float16, SQLiteVec Int8, and packed-bit strategies cannot be passed to these helpers.
Use `.TursoFloat64BytesRepresentation` for Double and `.TursoBytesRepresentation` for binary values.
Generic forwarding helpers need `where V.Encoding: TursoVectorEncoding`. Operation-specific encoding
constraints still apply.

Ordinary `@Column(as:)` declarations are database-independent and can store arbitrary BLOBs;
these checks apply when using the Turso helpers. The database validates JSON contents, dimensions,
and value-dependent conversion restrictions.

### Floating-point BLOB strategies

Shared `.VectorBytesRepresentation` strategies contain raw little-endian scalar payloads.
Use `.TursoFloat64BytesRepresentation` for Float64 columns and bindings so the required type byte
is written and validated. Float32 can use its shared strategy or `.TursoFloat32BytesRepresentation`,
which additionally accepts the optional Float32 tag when reading existing blobs. The latter writes
raw Float32, so both strategies share an encoding identity and can be compared directly.

```swift
@Table("precise_documents")
struct PreciseDocument {
  @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  var embedding: EmbeddingVector64<3>
}

let raw = [Double].VectorBytesRepresentation(queryOutput: [1, 2, 3])
// raw.vectorBytes.count == 24; this is a raw payload, not a Turso vector.
let turso = [Double].TursoFloat64BytesRepresentation(queryOutput: [1, 2, 3])
// turso.vectorBytes.count == 25, including the Float64 type byte.
let query = PreciseDocument.select { TursoVec.distanceL2($0.embedding, to: turso) }
// SELECT vector_distance_l2("precise_documents"."embedding", ?)
// FROM "precise_documents"
```

These strategies also support scalar arrays and `InlineArray`. Fixed-dimension validation and
floating-point equality and hashing are delegated to the shared raw strategies. Raw Float64 and
Turso Float64 have separate encoding identities; the query helpers require the Turso identity.

### Quantized vectors

``Quantized8Vector`` stores unsigned `codes`, `scale`, and `shift`. Each code reconstructs as
`Float(code) * scale + shift`. This is affine UInt8 quantization, distinct from IEEE FP8 and
sqlite-vec's signed Int8 format.

```swift
// CREATE TABLE compressed_documents (id INTEGER PRIMARY KEY, embedding BLOB NOT NULL);
@Table("compressed_documents")
struct CompressedDocument {
  var id: Int
  var embedding: Quantized8Vector
}

let compressed = try Quantized8Vector(quantizing: [0, 127.5, 255])
// codes: [0, 128, 255], scale: 1, shift: 0
let values = compressed.decodedValues() // [0, 128, 255]
let supplied = try Quantized8Vector(codes: [10, 20], scale: 2, shift: 1)
```

`init(quantizing:)` applies min/max quantization once. `init(codes:scale:shift:)` accepts encoded
components and validates finite values and nonnegative scale. Reading and rebinding preserve the
components; `decodedValues()` explicitly reconstructs floats. Encoded types are column values
directly, without an `@Column(as:)` strategy.

### Sparse vectors

``SparseFloat32Vector`` stores the logical dimension count, sorted unique indices, and Float32
values. Use it for TF-IDF, bag-of-words, and other mostly zero features:

```swift
// CREATE TABLE sparse_documents (id INTEGER PRIMARY KEY, embedding BLOB NOT NULL);
@Table("sparse_documents")
struct SparseDocument {
  var id: Int
  var embedding: SparseFloat32Vector
}

let sparse = try SparseFloat32Vector(compressing: [0, 0, 1.5, 0, 0, 2.5])
// dimensions: 6, indices: [2, 5], values: [1.5, 2.5]
let supplied = try SparseFloat32Vector(dimensions: 6, indices: [2, 5], values: [1.5, 2.5])
let dense = sparse.denseValues() // [0, 0, 1.5, 0, 0, 2.5]
let query = SparseDocument.select { TursoVec.distanceJaccard($0.embedding, to: sparse) }
// SELECT vector_distance_jaccard("sparse_documents"."embedding", ?)
// FROM "sparse_documents"
```

Compression omits positive and negative zeros. The component initializer preserves explicit zeros
and IEEE bits. Decoding keeps sparse storage; `denseValues()` allocates a dense array.
Each entry uses eight bytes for its value and index, plus five bytes per vector for dimensions and
the format tag. This can add overhead for dense embeddings. Sparse storage alone creates no index.

### Binary vectors

Use `.TursoBytesRepresentation` on `[Bool]` or `BinaryEmbeddingVector<N>` to preserve exact
binary dimensions, including partial bytes:

```swift
// CREATE TABLE binary_documents (id INTEGER PRIMARY KEY, embedding BLOB NOT NULL);
@Table("binary_documents")
struct BinaryDocument {
  var id: Int
  @Column(as: BinaryEmbeddingVector<9>.TursoBytesRepresentation.self)
  var embedding: BinaryEmbeddingVector<9>
}

let binary = BinaryEmbeddingVector<9>(quantizing: EmbeddingVector<9>([1, -1, 1, -1, -1, -1, -1, 1, 1]))
let binding = BinaryEmbeddingVector<9>.TursoBytesRepresentation(queryOutput: binary)
let query = BinaryDocument.select { TursoVec.distanceHamming($0.embedding, to: binding) }
// SELECT vector_distance_cos("binary_documents"."embedding", ?)
// FROM "binary_documents"
```

Binary cosine returns Hamming distance; `distanceHamming` names that operation explicitly and
returns `Double` (SQL REAL). Local `BinaryEmbeddingVector.hammingDistance(to:)` returns `Int`.
Extraction and dot distance interpret true as +1 and false as -1; Jaccard compares true-bit sets.

The representation adds padding and format metadata to the shared packed value. `packedBytes`
exposes only the raw payload; bind `.TursoBytesRepresentation` to supply the complete Turso BLOB.
`.PackedBitsRepresentation` belongs to `StructuredQueriesSQLiteVecCore` and has a different layout.

### Concatenate and slice

```swift
let joined = TursoVec.concat(TursoVec.vector32("[1, 2]"), TursoVec.vector32("[3, 4]"))
// vector_concat(vector32(?), vector32(?))
let sliced = TursoVec.slice(joined, from: 1, to: 3)
// vector_slice(vector_concat(vector32(?), vector32(?)), ?, ?)
```

`concat` accepts two matching dense Float32 or Float64 vectors. `slice` accepts those formats
and sparse Float32, with an inclusive start and exclusive end. Neither supports quantized or binary
operands. For sparse concatenation, convert through dense Float32:

```swift
let left = TursoVec.vector32Sparse("[0, 1]")
// vector32_sparse(?)
let right = TursoVec.vector32Sparse("[2, 0]")
// vector32_sparse(?)
let joined = TursoVec.vector32Sparse(
  TursoVec.concat(TursoVec.vector32(left), TursoVec.vector32(right))
)
// vector32_sparse(vector_concat(vector32(vector32_sparse(?)), vector32(vector32_sparse(?))))
```

This workaround uses dense intermediate storage; the
[engine's sparse concat implementation](https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/concat.rs#L24)
does not shift the second operand's indices.

### Fixed-size results and bytes

``InlineQuantized8Vector`` stores unsigned codes inline with scale and shift.
``SizedSparseFloat32Vector`` fixes logical dimensions while keeping a variable number of entries.
Both bind directly and validate decoded dimensions. Their `init(validating:)` initializers preserve
an existing vector's encoded components and check dimensions, without requantizing or expanding
sparse storage:

```swift
let supplied = try Quantized8Vector(codes: [10, 20], scale: 2, shift: 1)
let inline = try InlineQuantized8Vector<2>(validating: supplied)
let sparseComponents = try SparseFloat32Vector(dimensions: 4, indices: [1, 3], values: [2, 5])
let sized = try SizedSparseFloat32Vector<4>(validating: sparseComponents)

let quantized = try EmbeddingVector<3>([0, 127.5, 255]).quantized8()
let sparse = try EmbeddingVector<6>([0, 0, 1.5, 0, 0, 2.5]).sparseFloat32()

let converted = TursoVec.vector8("[1, 2, 3, 4]", as: InlineQuantized8Vector<4>.self)
// vector8(?)
let sparseResult = TursoVec.vector32Sparse("[0, 1, 0, 2]", as: SizedSparseFloat32Vector<4>.self)
// vector32_sparse(?)
let doubles = TursoVec.vector64("[1, 2, 3, 4]", as: EmbeddingVector64<4>.TursoFloat64BytesRepresentation.self)
// vector64(?)
let sliced = TursoVec.slice(TursoVec.vector32("[1, 2, 3, 4]"), from: 1, to: 3, as: EmbeddingVector<2>.self)
// vector_slice(vector32(?), ?, ?)

let restored = try Quantized8Vector(vectorBytes: quantized.vectorBytes)
```

`as:` selects a matching result representation. All vector values and representations expose
`vectorBytes` and `init(vectorBytes:)`. Encoded equality compares stored component bit patterns;
dense equality follows Swift scalar semantics.

Invalid quantized or sparse constructor components throw ``TursoVectorError``. Handle its stable
`code` and use `reason` for diagnostics; codes are extensible, so switches need a default case.
Malformed bytes instead throw `VectorDecodingError`.

See the [shared vector documentation](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/)
and [migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).
