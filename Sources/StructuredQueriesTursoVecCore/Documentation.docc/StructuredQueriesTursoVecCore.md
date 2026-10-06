# ``StructuredQueriesTursoVecCore``

StructuredQueries helpers for Turso Database vector functions, independent of SQLiteData.

## Overview

``TursoVec`` follows the Rust-based [Turso Database vector API](https://docs.turso.tech/sql-reference/functions/vector).
Importing this target also exports `StructuredQueriesVectorCore`, including `EmbeddingVector` and
the shared byte representations. Tables need only `@Table`; there is no additional vector
conformance. Use these helpers with a Turso Database driver.

### Supported conversions

Conversion results preserve their format. Dense and binary representations expose scalar arrays;
quantized and sparse results expose encoded vector values. Match the column's encoding:

| Conversion | Swift representation |
| --- | --- |
| `vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `vector64` | `[Double].VectorBytesRepresentation` |
| `vector8` | `Quantized8Vector` |
| `vector1bit` | `[Bool].TursoBytesRepresentation` |
| `vector32Sparse` | `SparseFloat32Vector` |

`vector32Sparse` emits SQL's `vector32_sparse` function. Float8 is unsigned-byte quantization
with per-vector scale and shift metadata, rather than an IEEE float8 scalar or SQLiteVec int8.
`Quantized8Vector` stores unsigned `codes`, a nonnegative finite `scale`, and a finite `shift`.
Each code reconstructs as `Float(code) * scale + shift`. Construction validates that reconstructed
values are finite. `init(quantizing:)` applies Turso's min/max affine quantization once;
`init(codes:scale:shift:)` accepts already quantized components. Binding and decoding preserve
those components. Call `decodedValues()` explicitly to reconstruct dense floats.

Create the compressed model's table through your Turso Database driver:

```sql
CREATE TABLE compressed_documents (
  embedding BLOB NOT NULL
);
```

```swift
let compressed = try Quantized8Vector(quantizing: [0, 127.5, 255])
// codes: [0, 128, 255], scale: 1, shift: 0
let values = compressed.decodedValues() // [0, 128, 255]

@Table("compressed_documents")
struct CompressedDocument {
  var embedding: Quantized8Vector
}
```

These are encoded values, so they are column types directly. They do not need an `@Column(as:)`
strategy. Quantization is lossy, but reading and rebinding never requantizes values.

Shared float32 bytes agree with SQLiteVec on little-endian platforms. Float64, float8,
and binary layouts include Turso's format metadata. The executing database checks input formats
and value-dependent restrictions, including restrictions on empty float8 and binary blobs.

### Vector bytes

Encoded values expose their database bytes without requiring a query decoder:

```swift
let vector = try Quantized8Vector(codes: [10, 20], scale: 2, shift: 1)
let restored = try Quantized8Vector(vectorBytes: vector.vectorBytes)
let sparse = try SparseFloat32Vector(dimensions: 6, indices: [2, 5], values: [1.5, 2.5])
let restoredSparse = try SparseFloat32Vector(vectorBytes: sparse.vectorBytes)
```

The same API is available on shared dense vectors and all byte representations. Inline and sized
variants validate the decoded dimensions. Query binding and query decoding delegate to this API.
`Encoding` identifies the canonical representation: inline quantized vectors use `Quantized8Vector`,
and sized sparse vectors use `SparseFloat32Vector`. This lets query helpers match byte layouts
across fixed and variable dimension counts.

### Turso exact search

Following [Turso's schema example](https://turso.tech/blog/a-complete-guide-to-database-per-agent-architecture),
execute this table-creation SQL through your Turso Database driver before using the model below:

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  content TEXT NOT NULL,
  embedding F32_BLOB(4) NOT NULL
);
```

The `NOT NULL` columns match the nonoptional Swift properties. `@Table` models a table for query
generation; execute the creation SQL separately through your driver. A BLOB column supports all
the vector formats listed above. Choose the encoding through a bound value or SQL conversion,
and keep the format and dimensions consistent for distance comparisons.

`F32_BLOB(4)` describes the intended four-dimensional float32 format and has
[BLOB affinity](https://github.com/tursodatabase/turso/blob/2487f62c372c99a21551a6450d4a10309c7dad2b/core/vdbe/affinity.rs#L186-L202);
plain `BLOB` also works. The inspected Rust engine does not enforce the declared dimension count:
an official [driver test](https://github.com/tursodatabase/turso-go/blob/ea06d135c592ae9a653ebf6ba5e069c8417c030c/turso_test.go#L354-L366)
inserts five-dimensional vectors into `F32_BLOB(64)`.

Model the column with `EmbeddingVector<4>` to express the dimensions in Swift and validate them
on decoding. This example requires Swift 6.2 and the supported platforms described in
`StructuredQueriesVectorCore`:

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
let insert = Document.insert { ($0.id, $0.content, $0.embedding) } values: {
  (1, "Introduction to databases", embedding)
}

let queryVector = EmbeddingVector<4>([0.2, 0.4, 0.6, 0.8])
let query = Document
  .order { TursoVec.distanceCosine($0.embedding, to: queryVector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
```

For variable-size float32 models, use `[Float]` with
`@Column(as: [Float].VectorBytesRepresentation.self)` instead.

``TursoVec`` offers cosine and L2 distance, as well as `distanceDot`, the negative dot
product, and `distanceJaccard`, weighted Jaccard distance for numeric values and binary Jaccard
for logical bits. Smaller distances indicate closer matches. Matching formats are enforced by
Swift; the database checks equal dimensionality.

JSON must be converted explicitly before a distance comparison:

```swift
let query = Document.select {
  TursoVec.distanceCosine($0.embedding, to: TursoVec.vector32("[0.2, 0.4, 0.6, 0.8]"))
}
```

Raw JSON defaults to float32 in distance functions. Explicit conversion avoids mismatches with
float64, compressed, binary, or sparse operands. Use the conversion matching the column's format.

### Sparse and binary values

`SparseFloat32Vector` stores `dimensions`, sorted unique `indices: [UInt32]`, and matching
`values: [Float]`. Both Swift storage and the database blob remain sparse. Decoding validates
the format tag, byte lengths, and indices without allocating a dense array.

Use `init(compressing:)` to omit zeros from a dense array, or
`init(dimensions:indices:values:)` to supply sparse components directly. The latter preserves
explicit zeros and IEEE value bit patterns. `denseValues()` allocates a dense array and fills
omitted positions with positive zero. Compression omits both positive and negative zeros.

For example, `[0, 0, 1.5, 0, 0, 2.5]` stores values `[1.5, 2.5]`, indices `[2, 5]`, and a
dimension count of `6`. Each stored entry uses four bytes for its value and four for its index,
plus five bytes per vector for the dimension count and format tag. Sparse storage is useful for
TF-IDF, bag-of-words, and other high-dimensional features with many exact zeros. It generally
adds overhead for dense embeddings. See [Turso's sparse guide](https://docs.turso.tech/guides/vector-search#sparse-vectors).
Sparse encoding alone does not create an index.

Create the sparse model's table with a BLOB column as well:

```sql
CREATE TABLE sparse_documents (
  embedding BLOB NOT NULL
);
```

```swift
@Table("sparse_documents")
struct SparseDocument {
  var embedding: SparseFloat32Vector
}

let embedding = try SparseFloat32Vector(dimensions: 6, indices: [2, 5], values: [1.5, 2.5])

let query = SparseDocument.select {
  TursoVec.distanceJaccard($0.embedding, to: embedding)
}
```

Binary Swift values use `[Bool]` or `BinaryEmbeddingVector<N>`. True corresponds to a positive
component (+1 when extracted); false corresponds to a nonpositive component (-1 when extracted).
`.TursoBytesRepresentation` includes padding and dimension metadata, preserving partial bytes.
SQLiteVec's `.PackedBitsRepresentation` omits metadata and requires dimensions divisible by eight.

For binary vectors, `distanceCosine` calls `vector_distance_cos` but returns Hamming distance,
the count of differing bits. `distanceHamming` provides a binary-only name for that same SQL
function. It returns `Double` because Turso returns SQL REAL, even though the count is integral.
Local `BinaryEmbeddingVector.hammingDistance(to:)` returns `Int`. Binary L2 is unavailable.
Turso's binary dot distance interprets
components as +1/-1, while Jaccard compares the sets of true bits.

Create the binary model's table before running its query:

```sql
CREATE TABLE binary_documents (
  embedding BLOB NOT NULL
);
```

```swift
@Table("binary_documents")
struct BinaryDocument {
  @Column(as: BinaryEmbeddingVector<9>.TursoBytesRepresentation.self)
  var embedding: BinaryEmbeddingVector<9>
}

let binary = BinaryEmbeddingVector<9>(quantizing: EmbeddingVector<9>([1, -1, 1, -1, -1, -1, -1, 1, 1]))
let binding = BinaryEmbeddingVector<9>.TursoBytesRepresentation(queryOutput: binary)
let query = BinaryDocument.select { TursoVec.distanceHamming($0.embedding, to: binding) }
```

The shared binary value stores packed bytes, and its fixed-size database adapters bind and decode
that payload directly. `packedBytes` has no database metadata. Turso's representation adds padding,
the exact dimension count, and the format tag. See
[Turso's binary distance limitations](https://docs.turso.tech/guides/vector-search#limitations).

### Concatenate and slice

Turso utilities can change the dimension count, so their default output has a variable dimension count:

```swift
let joined = TursoVec.concat(TursoVec.vector32("[1, 2]"), TursoVec.vector32("[3, 4]"))
let sliced = TursoVec.slice(joined, from: 1, to: 3)
```

`concat` accepts exactly two matching dense float32 or float64 operands. `slice` accepts dense
float32, float64, or sparse float32, with a zero-based inclusive start and exclusive end.
Neither utility offers float8 or binary overloads.

Direct sparse concatenation is deferred: the
[inspected implementation](https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/concat.rs#L24)
copies the second vector's indices without shifting them. Convert through dense float32 when needed:

```swift
let joined = TursoVec.vector32Sparse(
  TursoVec.concat(TursoVec.vector32(leftSparse), TursoVec.vector32(rightSparse))
)
```

This conversion uses dense intermediate storage.

### Fixed-size results

On Swift 6.2 and supported platforms, `EmbeddingVector<N>` remains directly query-bindable.
Other scalar types use `EmbeddingVector64<N>` and `BinaryEmbeddingVector<N>` with explicit
nested representations.

`InlineQuantized8Vector<N>` stores its `N` unsigned codes in an inline array, with scale and shift
alongside them. `SizedSparseFloat32Vector<N>` fixes the logical dimension count while keeping its
indices and values in arrays: the number of stored entries remains variable. Both types are directly
query-bindable and validate decoded dimensions.

```swift
let quantized = try InlineQuantized8Vector<3>(
  quantizing: EmbeddingVector<3>([0, 127.5, 255])
)
let supplied = try InlineQuantized8Vector<3>(codes: [0, 128, 255], scale: 1, shift: 0)
let sparse = try SizedSparseFloat32Vector<6>(indices: [2, 5], values: [1.5, 2.5])
let dense: EmbeddingVector<6> = sparse.denseValues()
```

The Turso target also adds throwing `EmbeddingVector<N>` conveniences that preserve dimensions:

```swift
let quantized = try EmbeddingVector<3>([0, 127.5, 255]).quantized8()
let sparse = try EmbeddingVector<6>([0, 0, 1.5, 0, 0, 2.5]).sparseFloat32()
```

These four encoded vector types belong to `StructuredQueriesTursoVecCore`. Dense embedding values
and their byte strategies belong to `StructuredQueriesVectorCore`, shared with SQLiteVec. Encoded
value equality and hashing compare stored component bit patterns, including scale/shift and sparse
NaNs; dense embedding equality uses Swift scalar semantics. No raw-memory comparison is used.

Choose the matching representation using `as:` for conversions, concat, or slice:

```swift
let quantized = TursoVec.vector8("[1, 2, 3, 4]", as: InlineQuantized8Vector<4>.self)
let sparse = TursoVec.vector32Sparse("[0, 1, 0, 2]", as: SizedSparseFloat32Vector<4>.self)
let converted = TursoVec.vector64(
  "[1, 2, 3, 4]",
  as: EmbeddingVector64<4>.VectorBytesRepresentation.self
)
let sliced = TursoVec.slice(
  TursoVec.vector32("[1, 2, 3, 4]"),
  from: 1,
  to: 3,
  as: EmbeddingVector<2>.self
)
```

The decoder validates the blob's format and fixed dimension count. See
`StructuredQueriesVectorCore` for availability and scalar equality semantics.

### Search and indexing

The exact-search examples order rows by a distance expression and apply a limit. This scans the
candidate rows; a `where` clause can reduce the candidate set. Turso's experimental sparse index
method uses separate DDL and planner integration, and has no helper in this target. See the
[Turso vector reference](https://docs.turso.tech/sql-reference/functions/vector) for its current
index support.

### Prepare queries for a driver

```swift
let prepared = query.query.prepare { "?\($0)" }
// Pass prepared.sql and prepared.bindings to the compatible database driver.
```

## Testing

Turso tests compare generated SQL and bindings with linked documentation examples. Byte fixtures
link to pinned Turso source revisions. No running Turso instance is required.
