# ``StructuredQueriesTursoVecCore``

StructuredQueries helpers for Turso Database's native vector functions.

## Overview

``TursoVec`` generates SQL and bindings for the
[Turso vector API](https://docs.turso.tech/sql-reference/functions/vector). Execute them with a
compatible driver. This module exports `StructuredQueriesVectorCore` and works with ordinary
`@Table` models.

SQL comments show generated queries; placeholders represent bound values.

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

`F32_BLOB(4)` describes four-dimensional Float32 with
[BLOB affinity](https://github.com/tursodatabase/turso/blob/2487f62c372c99a21551a6450d4a10309c7dad2b/core/vdbe/affinity.rs#L186-L202).
Plain `BLOB` also works. Turso does not enforce the
[declared count](https://github.com/tursodatabase/turso-go/blob/ea06d135c592ae9a653ebf6ba5e069c8417c030c/turso_test.go#L354-L366);
`EmbeddingVector<4>` validates decoded dimensions. Fixed types require iOS 26,
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

For variable-size values, use `[Float].VectorBytesRepresentation` with `@Column(as:)`. Distance
ordering searches candidate rows exactly; narrow them with `where`. Experimental sparse indexing
uses separate DDL without a helper.

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

`distanceCosine`, `distanceL2`, `distanceDot` (negative dot product), and `distanceJaccard` rank
closer matches lower. Operands need matching encodings and equal known counts; Turso checks
variable counts. Numeric Jaccard is weighted; binary Jaccard compares true-bit sets. Binary L2
is unavailable.

### Compatible constructor inputs

Constructors accept JSON strings or vectors with a ``TursoVectorEncoding``: shared Float32, Turso Float64,
binary, quantized, and sparse layouts. Fixed and custom values inherit compatibility from their
canonical encoding. `extract` requires a compatible vector.

```swift
let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
let precise = TursoVec.vector64(vector)
// vector64(?)
let json = TursoVec.extract(precise)
// vector_extract(vector64(?))
```

Raw Double, Float16, SQLiteVec Int8, and packed bits are unsupported. Use
`.TursoFloat64BytesRepresentation` for Double and `.TursoBytesRepresentation` for binary. Generic
forwarding needs `where V.Encoding: TursoVectorEncoding`, plus operation-specific constraints.

`@Column(as:)` can store arbitrary BLOBs; compatibility checks apply to Turso helpers. The database
validates JSON, variable dimensions, and value-dependent conversions.

### Floating-point BLOB strategies

Shared strategies store raw little-endian scalars. `.TursoFloat64BytesRepresentation` writes and
validates the required Float64 type byte. Float32 supports the shared strategy or
`.TursoFloat32BytesRepresentation`, which also reads tagged blobs. The two Float32 strategies write raw bytes and
share an encoding identity.

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

Strategies support arrays, inline arrays, and fixed values, delegating dimensions, equality, and
hashing to the shared strategy. Raw and Turso Float64 have distinct encoding identities.

### Quantized vectors

``Quantized8Vector`` stores UInt8 `codes`, `scale`, and `shift`, reconstructing
`Float(code) * scale + shift`. This affine format differs from FP8 and sqlite-vec Int8.

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
let insert = CompressedDocument.insert { ($0.id, $0.embedding) } values: {
  (1, compressed)
}
// INSERT INTO "compressed_documents" ("id", "embedding") VALUES (?, ?)
```

`init(quantizing:)` applies min/max quantization. `init(codes:scale:shift:)` validates finite
components and nonnegative scale. Reading and rebinding preserve them; `decodedValues()`
reconstructs floats. Values bind directly without `@Column(as:)`.

### Sparse vectors

``SparseFloat32Vector`` stores logical dimensions, sorted unique indices, and Float32 values,
suited to TF-IDF, bag-of-words, and mostly zero features:

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

Compression omits signed zeros; component initialization preserves explicit zeros and IEEE bits.
Decoding stays sparse; `denseValues()` allocates a dense array. Storage uses eight bytes per entry
plus five per vector, so dense embeddings can grow. Sparse storage creates no index.

### Binary vectors

`.TursoBytesRepresentation` on `[Bool]` and `BinaryEmbeddingVector<N>` preserves exact counts,
including partial bytes:

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

Binary cosine is Hamming distance: `distanceHamming` returns `Double` (SQL REAL); local Hamming
returns `Int`. Extraction and dot distance use true = +1, false = -1; Jaccard compares true-bit sets.

`packedBytes` exposes raw payload only; `.TursoBytesRepresentation` adds padding and format
metadata. SQLiteVec's `.PackedBitsRepresentation` uses a different layout.

### Concatenate and slice

```swift
let joined = TursoVec.concat(TursoVec.vector32("[1, 2]"), TursoVec.vector32("[3, 4]"))
// vector_concat(vector32(?), vector32(?))
let sliced = TursoVec.slice(joined, from: 1, to: 3)
// vector_slice(vector_concat(vector32(?), vector32(?)), ?, ?)
```

`concat` accepts matching dense Float32/Float64. `slice` also accepts sparse Float32, with inclusive
start and exclusive end. Neither accepts quantized or binary. For sparse concatenation, convert
through dense Float32:

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

This allocates dense intermediates because the
[engine's sparse concat](https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/concat.rs#L24)
does not shift the second operand's indices.

### Encoding capabilities

``TursoVectorEncoding`` identifies supported layouts. ``TursoNumericVectorEncoding`` supports L2
and branches into ``TursoFloat32Encoding``, ``TursoFloat64Encoding``, ``TursoQuantized8Encoding``,
and ``TursoSparseFloat32Encoding``. ``TursoBinaryEncoding`` refines the base and
`BinaryVectorEncoding`.

```swift
func numericDistance<L: VectorBytesRepresentable & QueryBindable,
  R: VectorBytesRepresentable & QueryBindable>(
  _ left: some QueryExpression<L>, to right: some QueryExpression<R>
) -> some QueryExpression<Double?>
where L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
  L.Dimensions == R.Dimensions {
  TursoVec.distanceL2(left, to: right)
}
let left = EmbeddingVector<3>([3, 4, 0])
let right = EmbeddingVector<3>([0, 0, 0])
let distance = numericDistance(left, to: right)
// vector_distance_l2(?, ?)
```

Conformance promises valid Turso bytes; it does not convert them. Capabilities apply to fixed and
variable values. Slice and concat retain their format restrictions.

### Fixed-size results and bytes

``InlineQuantized8Vector`` stores inline UInt8 codes, scale, and shift. ``SizedSparseFloat32Vector``
fixes logical dimensions with variable entries. Both bind directly; `init(validating:)` and decoding
check counts while preserving encoded components:

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

let suppliedValues = inline.decodedValues() // [21, 41]: scale and shift are preserved.
let sparseEntries = Array(zip(sized.indices, sized.values)) // [(1, 2), (3, 5)]
```

Conversions preserve fixed dimensions through `VectorDimensions<N>`. Length-preserving `as:`
results reject conflicting known counts; JSON and variable inputs validate fixed results when
decoding. Distances reject unequal known counts but allow fixed/variable pairs. Concat accepts
different counts; slices and concat default to variable results, with `as:` for fixed results
validated during decoding.

Values expose `vectorBytes` and `init(vectorBytes:)`. Encoded equality compares component bits;
dense equality follows scalar semantics.

Invalid components throw ``TursoVectorError``: handle `code`, use `reason` for diagnostics, and
include a default in code switches. Malformed bytes throw `VectorDecodingError`.

See the [shared vector documentation](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/)
and [migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).

### Missing vectors and undefined scores

Floating L2/dot, cosine, and Jaccard return `Double?`; undefined results can become SQL NULL.
Quantized8 L2/dot and binary dot/Hamming retain `Double` for nonoptional inputs.

Use `whenPresent` with nullable inputs. Its CASE guard skips the native function for missing
values, and its closure retains encoding and dimension checks:

```swift
let candidate: [Float].VectorBytesRepresentation? = [0.2, 0.4, 0.6, 0.8]
let score = candidate.whenPresent {
  TursoVec.distanceCosine(Document.columns.embedding, to: $0)
}
// CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos("documents"."embedding", ?) END
let fallback = score.ifnull(2)
// ifnull(CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos("documents"."embedding", ?) END, ?)
```

Filter scores with `.isNot(nil)` before ranking, or choose a fallback for your metric. Ascending SQL
order puts NULL first. Missing inputs and undefined scores both decode as nil; inspect the input
separately when that distinction matters. Malformed bytes and mismatched dimensions still throw.
