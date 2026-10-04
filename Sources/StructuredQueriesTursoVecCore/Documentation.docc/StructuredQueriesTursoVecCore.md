# ``StructuredQueriesTursoVecCore``

StructuredQueries helpers for Turso Database and libSQL vector functions, independent of SQLiteData.

## Overview

Choose the namespace for the engine executing your queries:

- ``TursoVec`` follows the Rust-based [Turso Database vector API](https://docs.turso.tech/sql-reference/functions/vector).
- ``LibSQLVec`` follows the [libSQL vector API](https://docs.turso.tech/features/ai-and-embeddings),
  including Turso Cloud databases running libSQL.

These engines have overlapping functions and compatible layouts for their shared formats, but
support different operations. Importing this target also exports `StructuredQueriesVectorCore`,
including `EmbeddingVector` and the shared byte representations. Tables need only `@Table`;
there is no additional Turso or libSQL table conformance.

### Supported conversions

Conversion results expose numeric or logical Swift values. Use the representation matching the
column's encoding:

| Conversion | Swift representation | Turso | libSQL |
| --- | --- | --- | --- |
| `vector32` / `vector` | `[Float].VectorBytesRepresentation` | Yes | Yes |
| `vector64` | `[Double].VectorBytesRepresentation` | Yes | Yes |
| `vector16` | `[Float16].VectorBytesRepresentation` | No | Yes |
| `vectorb16` | `[Float].BFloat16Representation` | No | Yes |
| `vector8` | `[Float].Float8Representation` | Yes | Yes |
| `vector1bit` | `[Bool].TursoBytesRepresentation` | Yes | Yes |
| `vector32Sparse` | `[Float].SparseRepresentation` | Yes | No |

`vector32Sparse` emits SQL's `vector32_sparse` function. Float8 is unsigned-byte quantization
with per-vector scale and shift metadata, rather than an IEEE float8 scalar or SQLiteVec int8.
Binding requires finite values and a finite scale; decoding reconstructs stored values.
Bfloat16 truncates each Float's low 16 bits. Both compressed formats are lossy.

Shared float32 bytes agree with SQLiteVec on little-endian platforms. Shared float64, float8,
and binary layouts follow libSQL's metadata conventions, also used by Turso. This does not make
all inputs valid in both engines: Turso rejects float16 and bfloat16 blobs and empty float8 or
binary vectors. The executing database checks input formats and value-dependent restrictions.

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

Both namespaces offer cosine and L2 distance. Turso also offers `distanceDot`, the negative dot
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
float64, compressed, binary, or sparse operands. Use the appropriate namespace and conversion
for the column's format.

### Sparse and binary values

The sparse representation keeps a dense Swift array while storing only nonzero components,
their indices, and the original dimension count. Decoding fills omitted dimensions with zero;
signed zero becomes positive zero. It validates the format tag, byte lengths, and sorted,
unique, in-range indices.

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
Other precisions use `EmbeddingVector64<N>`, `EmbeddingVector16<N>`, and
`BinaryEmbeddingVector<N>` with explicit nested representations. Float32 fixed-size vectors
also provide `.BFloat16Representation`, `.Float8Representation`, and `.SparseRepresentation`.

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

### libSQL indexed search

libSQL supports DiskANN indexes through `libsql_vector_idx` and `vector_top_k`. These helpers
belong to ``LibSQLVec`` and follow the
[libSQL index example](https://docs.turso.tech/features/ai-and-embeddings#index-usage):

```sql
CREATE TABLE movies (title TEXT, year INT, embedding F32_BLOB(4));
```

```swift
@Table("movies")
struct Movie {
  var title: String
  var year: Int
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

let marker = LibSQLVec.index(Movie.columns.embedding)
let createIndex = #sql("CREATE INDEX movies_idx ON movies (\(marker))", as: Void.self)
let neighbors = LibSQLVec.topK(
  index: "movies_idx",
  vector: LibSQLVec.vector32("[0.064, 0.777, 0.661, 0.687]"),
  k: 3
)
let query = Movie
  .where { $0.rowid.in(neighbors) && $0.year.gte(2020) }
  .select { ($0.title, $0.year) }
```

`index(_:settings:)` escapes settings as SQL literals, because DDL cannot contain bound
parameters. For example, use `["metric=l2", "compress_neighbors=float8"]` for index settings.
The column name is quoted, and the marker is valid only inside a vector index definition.

``LibSQLVectorTopK`` selects the function's `id` output column and exposes `tableFragment`
for SQL joins. This does not require an `id` column on the indexed table. Use
`topK(index:vector:k:as:)` for a different primary key representation, such as `String.self`.
Composite primary keys without a row ID are unsupported.

Search is approximate. The query vector must match the indexed column's type and dimensions.
Filters apply after finding neighbors, so fewer than `k` rows may survive. An `IN` subquery
does not preserve result order; add an explicit distance expression to `order` when needed.

The Rust-based Turso engine does not expose these libSQL DiskANN helpers. Its experimental
sparse index method uses different DDL and planner integration; no helper is provided for that
experimental mechanism in this target.

### Prepare queries for a driver

```swift
let prepared = query.query.prepare { "?\($0)" }
// Pass prepared.sql and prepared.bindings to the compatible database driver.
```

## Testing

Separate Turso and libSQL test suites compare generated SQL and bindings with linked documentation
examples. Byte fixtures link to pinned engine source revisions. No running Turso instance is required.
