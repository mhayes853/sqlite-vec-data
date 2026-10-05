# ``StructuredQueriesTursoVecCore``

StructuredQueries helpers for Turso Database vector functions, independent of SQLiteData.

## Overview

``TursoVec`` follows the Rust-based [Turso Database vector API](https://docs.turso.tech/sql-reference/functions/vector).
Importing this target also exports `StructuredQueriesVectorCore`, including `EmbeddingVector` and
the shared byte representations. Tables need only `@Table`; there is no additional vector
conformance. Use these helpers with a Turso Database driver.

### Supported conversions

Conversion results expose numeric or logical Swift values. Use the representation matching the
column's encoding:

| Conversion | Swift representation |
| --- | --- |
| `vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `vector64` | `[Double].VectorBytesRepresentation` |
| `vector8` | `[Float].Float8Representation` |
| `vector1bit` | `[Bool].TursoBytesRepresentation` |
| `vector32Sparse` | `[Float].SparseRepresentation` |

`vector32Sparse` emits SQL's `vector32_sparse` function. Float8 is unsigned-byte quantization
with per-vector scale and shift metadata, rather than an IEEE float8 scalar or SQLiteVec int8.
Binding requires finite values and a finite scale; decoding reconstructs stored values.
This quantized representation is lossy.

Shared float32 bytes agree with SQLiteVec on little-endian platforms. Float64, float8,
and binary layouts include Turso's format metadata. The executing database checks input formats
and value-dependent restrictions, including restrictions on empty float8 and binary blobs.

### Turso exact search

The [Turso example](https://docs.turso.tech/guides/vector-search) stores embeddings in a BLOB column:

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  content TEXT,
  embedding BLOB
);
```

Model the column with a shared representation:

```swift
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore

@Table("documents")
struct Document {
  var id: Int
  var content: String
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

let embedding = TursoVec.vector32("[0.1, 0.3, 0.5, 0.7]")
let insert = Document.insert { ($0.id, $0.content, $0.embedding) } values: {
  (1, "Introduction to databases", embedding)
}

let queryVector: [Float].VectorBytesRepresentation = [0.2, 0.4, 0.6, 0.8]
let query = Document
  .order { TursoVec.distanceCosine($0.embedding, to: queryVector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
```

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

The sparse representation keeps a dense Swift array while storing only nonzero components,
their indices, and the original dimension count. Decoding fills omitted dimensions with zero;
signed zero becomes positive zero. It validates the format tag, byte lengths, and sorted,
unique, in-range indices.

For example, `[0, 0, 1.5, 0, 0, 2.5]` stores values `[1.5, 2.5]`, indices `[2, 5]`, and a
dimension count of `6`. Each stored entry uses four bytes for its value and four for its index,
plus five bytes per vector for the dimension count and format tag. Sparse storage is useful for
TF-IDF, bag-of-words, and other high-dimensional features with many exact zeros. It generally
adds overhead for dense embeddings. See [Turso's sparse guide](https://docs.turso.tech/guides/vector-search#sparse-vectors).
The current Swift representation remains dense, so it saves database storage rather than Swift
array memory. Sparse encoding alone does not create an index.

```swift
@Table("sparse_documents")
struct SparseDocument {
  @Column(as: [Float].SparseRepresentation.self)
  var embedding: [Float]
}

let query = SparseDocument.select {
  TursoVec.distanceJaccard($0.embedding, to: TursoVec.vector32Sparse("[0, 1, 0, 2]"))
}
```

Binary Swift values use `[Bool]` or `BinaryEmbeddingVector<N>`. True corresponds to a positive
component (+1 when extracted); false corresponds to a nonpositive component (-1 when extracted).
`.TursoBytesRepresentation` includes padding and dimension metadata, preserving partial bytes.
SQLiteVec's `.PackedBitsRepresentation` omits metadata and requires dimensions divisible by eight.

For binary vectors, `distanceCosine` calls `vector_distance_cos` but returns Hamming distance,
the count of differing bits. Binary L2 is unavailable. Turso's binary dot distance interprets
components as +1/-1, while Jaccard compares the sets of true bits.

### Concatenate and slice

Turso utilities can change the dimension count, so their default output uses an array representation:

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
nested representations. Float32 fixed-size vectors also provide `.Float8Representation` and
`.SparseRepresentation`.

Choose the matching representation using `as:` for conversions, concat, or slice:

```swift
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
