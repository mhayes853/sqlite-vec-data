# ``StructuredQueriesTursoVecCore``

StructuredQueries helpers for [Turso/libSQL native vector search](https://docs.turso.tech/features/ai-and-embeddings)
that are not tied to SQLiteData.

## Overview

Use ``TursoVectorTable`` column helpers and the ``TursoVec`` namespace to build vector search
queries. This target also exports `StructuredQueriesVectorCore`, including `EmbeddingVector`
and `[Float].VectorBytesRepresentation`.

The helpers target the vector functions documented for Turso Cloud and libSQL. They generate
SQL and bindings; execute the resulting statements with a compatible database driver. Native
vector functions require a Turso/libSQL engine that supports them.

### Model a vector column

First, create a table in your migration:

```sql
CREATE TABLE movies (
  title TEXT,
  year INT,
  embedding F32_BLOB(4)
);
```

Then model it in Swift using a shared float representation:

```swift
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore

@Table("movies")
struct Movie: TursoVectorTable {
  var title: String
  var year: Int
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}
```

On Swift 6.2 and supported platforms, you can use `EmbeddingVector<4>` directly for the
`embedding` property.

### Insert vectors

Use ``TursoVec/vector32(_:)`` to convert a JSON array string to a float32 vector, as in the
[Turso insertion example](https://docs.turso.tech/features/ai-and-embeddings#vectors-usage):

```swift
let embedding = TursoVec.vector32("[0.800, 0.579, 0.481, 0.229]")
let query = Movie.insert {
  ($0.title, $0.year, $0.embedding)
} values: {
  ("Napoleon", 2023, embedding)
}
```

You can also bind `[Float].VectorBytesRepresentation` or `EmbeddingVector` directly to an
`F32_BLOB` column. These shared representations store float32 bytes without format metadata.

### Distance functions

Use `distanceCosine(to:)` or `distanceL2(to:)` to compare a vector column with a bound vector
or another expression:

```swift
let queryVector: [Float].VectorBytesRepresentation = [0.064, 0.777, 0.661, 0.687]
let query = Movie
  .order { $0.embedding.distanceCosine(to: queryVector).asc() }
  .limit(5)
  .select { ($0.title, $0.embedding.distanceCosine(to: queryVector)) }
```

These call `vector_distance_cos` and `vector_distance_l2`. Both vectors must have the same type
and dimensionality. Smaller distances indicate more similar vectors; L2 distance is unsupported
for 1-bit vectors.

Use `TursoVec.distanceCosine(_:to:)` and `TursoVec.distanceL2(_:to:)` directly for tables
without the ``TursoVectorTable`` conformance, or to compare converted expressions.

### Extract and convert vectors

Use `toJSON()` or ``TursoVec/extract(_:)`` to call `vector_extract`:

```swift
let query = Movie.select { ($0.title, $0.embedding.toJSON()) }
```

``TursoVec/vector(_:)`` is the float32 alias. Conversion results decode to numeric or logical
values, using a representation that validates the format metadata:

| Conversion | Swift values | Array representation | Fixed-size representation |
| --- | --- | --- | --- |
| `vector32` | `[Float]` | `[Float].VectorBytesRepresentation` | `EmbeddingVector<N>` |
| `vector64` | `[Double]` | `[Double].VectorBytesRepresentation` | `EmbeddingVector64<N>.VectorBytesRepresentation` |
| `vector16` | `[Float16]` | `[Float16].VectorBytesRepresentation` | `EmbeddingVector16<N>.VectorBytesRepresentation` |
| `vectorb16` | `[Float]` | `[Float].BFloat16Representation` | `EmbeddingVector<N>.BFloat16Representation` |
| `vector8` | `[Float]` | `[Float].Float8Representation` | `EmbeddingVector<N>.Float8Representation` |
| `vector1bit` | `[Bool]` | `[Bool].TursoBytesRepresentation` | `BinaryEmbeddingVector<N>.TursoBytesRepresentation` |

Declare a representation for each column so typed inserts, updates, and distances use its encoding:

```swift
@Table("compressed_movies")
struct CompressedMovie: TursoVectorTable {
  var title: String
  @Column(as: [Float].Float8Representation.self)
  var embedding: [Float]
}

let embedding: [Float].Float8Representation = [0.800, 0.579, 0.481, 0.229]
let query = CompressedMovie.select {
  ($0.embedding, $0.embedding.distanceCosine(to: embedding))
}
```

This decodes the stored float8 values directly as floats. Binding quantizes the input values;
reading reconstructs the stored values from their per-vector scale and shift. Float8 is Turso's
quantization format, rather than an IEEE float8 scalar or SQLiteVec's int8 format. Its inputs must
be finite and have a finite scale. Bfloat16 also uses `Float` values and truncates the low 16 bits
when binding, matching libSQL. Both compressed representations are lossy.

For fixed-size results, choose the matching representation with `as:`:

```swift
let query = CompressedMovie.select {
  TursoVec.vector64($0.embedding, as: EmbeddingVector64<4>.VectorBytesRepresentation.self)
}
```

The result is an `EmbeddingVector64<4>`. Decoding throws if the blob has the wrong encoding or
number of dimensions. An incompatible `as:` representation or a typed distance between different
encodings fails to compile. Dimensionality for distance queries is checked by the database.
JSON distance operands also require database type and dimension checks.

### Binary vectors

`BinaryEmbeddingVector<N>` and `[Bool]` model logical bits. True corresponds to a positive
component (+1 when extracted); false corresponds to a nonpositive component (-1 when extracted).
Their `TursoBytesRepresentation`, defined in this target, includes the padding and metadata
needed to preserve the exact number of dimensions:

```swift
@Table("binary_movies")
struct BinaryMovie: TursoVectorTable {
  @Column(as: BinaryEmbeddingVector<4>.TursoBytesRepresentation.self)
  var embedding: BinaryEmbeddingVector<4>
}

let queryVector = BinaryEmbeddingVector<4>.TursoBytesRepresentation(
  queryOutput: BinaryEmbeddingVector<4>([true, false, true, false])
)
let query = BinaryMovie.select { $0.embedding.distanceCosine(to: queryVector) }
```

Typed binary vectors do not offer L2 distance. SQLiteVec uses the shared `PackedBitsRepresentation`
instead: it omits Turso's metadata and requires a dimension count divisible by eight. The two
representations cannot be interchanged in a Turso query.

### Create a vector index

Use `TursoVec.index(_:settings:)` inside `CREATE INDEX` to generate the `libsql_vector_idx`
marker from Turso's [index example](https://docs.turso.tech/features/ai-and-embeddings#vector-index):

```swift
let marker = TursoVec.index(Movie.columns.embedding)
let query = #sql(
  "CREATE INDEX movies_idx ON movies (\(marker))",
  as: Void.self
)
```

Specify index settings with `key=value` strings:

```swift
let marker = TursoVec.index(
  Movie.columns.embedding,
  settings: ["metric=l2", "compress_neighbors=float8"]
)
```

The helper quotes the column name and escapes settings as SQL literals because index definitions
cannot contain bound parameters. The marker is only valid inside a vector index definition.

### Query the vector index

Use ``TursoVec/topK(index:vector:k:)`` to call `vector_top_k` and filter by its returned IDs:

```swift
let neighbors = TursoVec.topK(
  index: "movies_idx",
  vector: TursoVec.vector32("[0.064, 0.777, 0.661, 0.687]"),
  k: 3
)
let query = Movie
  .where { $0.rowid.in(neighbors) && $0.year.gte(2020) }
  .select { ($0.title, $0.year) }
```

This corresponds to the [documented index query](https://docs.turso.tech/features/ai-and-embeddings#index-usage).
The returned ``TursoVectorTopK`` also exposes its table-valued function for SQL joins:

```swift
let query = #sql(
  """
  SELECT title, year
  FROM \(neighbors.tableFragment)
  JOIN movies ON movies.rowid = id
  WHERE year >= 2020
  """,
  as: (String, Int).self
)
```

The function exposes its results in an `id` column, containing row IDs or primary keys rather
than distances. This column belongs to `vector_top_k`; the indexed table does not need a column
named `id`. Use `topK(index:vector:k:as:)` for a different
primary key representation, such as `String.self` for a table with a text primary key and no
row ID. Composite primary keys without a row ID are unsupported.

Index search is approximate, and the query vector must match the indexed column's format and
dimensionality. Filters on the base table apply after selecting neighbors, so fewer than `k`
rows may survive. An `IN` subquery does not preserve the index's ordering; add a distance
expression to `order` when ordering matters.

### Prepare queries for a driver

StructuredQueries keeps values separate from SQL:

```swift
let prepared = query.query.prepare { "?\($0)" }
// Pass prepared.sql and prepared.bindings to your database driver.
```

## Testing

The target's tests compare generated SQL and bindings with linked Turso documentation examples.
They do not require a running Turso instance.
