# ``StructuredQueriesSQLiteVecCore``

StructuredQueries helpers for [sqlite-vec](https://github.com/asg017/sqlite-vec).

## Overview

Model virtual tables with ``Vec0`` and use column helpers or the ``Vec`` namespace for vector
queries. This module exports `StructuredQueriesVectorCore`; load the sqlite-vec extension through
`SQLiteVecData` or your SQLite driver.

SQL comments show the generated queries with placeholders for bound values.

### Create a table and search

Execute the schema before querying:

```swift
import StructuredQueriesSQLite
import StructuredQueriesSQLiteVecCore

// CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
@Table("Embeddings")
struct Embedding: Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
  var label: String
}

let vector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
let query = Embedding
  .where { $0.embedding.match(vector) }
  .order { $0.distance }
  .limit(5)
  .select { ($0.label, $0.distance) }
// SELECT "Embeddings"."label", "Embeddings"."distance"
// FROM "Embeddings"
// WHERE (("Embeddings"."embedding" MATCH ?))
// ORDER BY "Embeddings"."distance"
// LIMIT ?
```

`match` accepts bound values and computed expressions with matching encodings:

```swift
let query = Embedding
  .where { $0.embedding.match(Vec.normalize(vector)) }
  .limit(5)
// SELECT "Embeddings"."embedding", "Embeddings"."label"
// FROM "Embeddings"
// WHERE (("Embeddings"."embedding" MATCH vec_normalize(?)))
// LIMIT ?

let freeform = Embedding
  .where { Vec.match($0.embedding, to: Vec.normalize(vector)) }
  .limit(5)
// SELECT "Embeddings"."embedding", "Embeddings"."label"
// FROM "Embeddings"
// WHERE (("Embeddings"."embedding" MATCH vec_normalize(?)))
// LIMIT ?
```

The left operand must be a vec0 vector column. A nearest-neighbor query requires `LIMIT` or a
constraint on vec0's `k` column.

### Distances and vector operations

```swift
let distances = Embedding.select {
  ($0.label, $0.embedding.distanceCosine(to: vector.normalize()))
}
// SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", vec_normalize(?))
// FROM "Embeddings"

let normalized = Vec.normalize(vector)
// vec_normalize(?)
let prefix = Embedding.columns.embedding.slice(0..<2) // Decodes as [Float]
// vec_slice("Embeddings"."embedding", 0, 2)
let fixedPrefix = Embedding.columns.embedding.slice(0..<2, as: EmbeddingVector<2>.self)
// vec_slice("Embeddings"."embedding", 0, 2)
let sliced = Vec.slice(vector, start: 0, end: 2)
// vec_slice(?, 0, 2)
```

Scalar helpers accept bound values or computed vector expressions and also work on ordinary BLOB
columns. Slices return variable-size results; `as:` selects a matching fixed-size result and validates
its dimensions. `match` remains specific to vec0 columns.

Distance helpers return `REAL` values decoded as `Double`, including the Int8 L1 distance, which
SQLiteVec computes as an integer and the helper casts to `REAL`. `length()` and `Vec.length` return
the dimension count as an `Int`. Float32 iteration yields ``VecEach`` elements, an alias of
`VecEachOf<Float>`; Int8 and packed-bit vectors yield `VecEachOf<Int8>` and `VecEachOf<Bool>`
because SQLiteVec reports their elements as integers.

Column and namespace helpers support these encodings:

| Operation | Float32 | Signed Int8 | Packed bits |
| --- | --- | --- | --- |
| `MATCH`, length, type, JSON, slice, iteration | Yes | Yes | Yes |
| L1, L2, cosine, addition, subtraction | Yes | Yes | — |
| Normalization | Yes | — | — |
| Hamming distance | — | — | Yes |
| Binary sign quantization | Yes | Yes | — |

Comparisons require matching encodings. An `as:` result must match the operation's output encoding;
fixed-size results also validate decoded dimensions. Float64 and Turso-specific formats cannot be
used with sqlite-vec helpers.

### Iterate over elements

``VecEach`` statements expose `rowid` and `value` and support joins, filters, and aggregates:

```swift
let elements = Vec.each(vector)
  .order { $0.rowid }
  .select { ($0.rowid, $0.value) }
// SELECT "vec_each"."rowid", "vec_each"."value"
// FROM "vec_each"
// WHERE ("vec_each"."vector" = ?)
// ORDER BY "vec_each"."rowid"

let joined = Embedding
  .join(Embedding.columns.embedding.vecEach()) { _, _ in true }
  .select { embedding, element in
    (embedding.label, element.rowid, element.value)
  }
// SELECT "Embeddings"."label", "vec_each"."rowid", "vec_each"."value"
// FROM "Embeddings"
// JOIN "vec_each"
// ON ?
// WHERE ("vec_each"."vector" = "Embeddings"."embedding")

let withNegativeElements = Embedding
  .where {
    $0.embedding.vecEach()
      .where { $0.value.lt(Float(0)) }
      .exists()
  }
  .select(\.label)
// SELECT "Embeddings"."label"
// FROM "Embeddings"
// WHERE (EXISTS (SELECT "vec_each"."rowid", "vec_each"."value" FROM "vec_each" WHERE
//   ("vec_each"."vector" = "Embeddings"."embedding") AND (("vec_each"."value") < (?))))
```

Both helpers supply `vec_each`'s hidden vector constraint, including in correlated subqueries.

### Float32 JSON and fixed dimensions

```swift
let vector = Vec.f32("[3, 0, 0]", as: EmbeddingVector<3>.self)
// vec_f32(?)
let normalized = Vec.normalize(vector)
// vec_normalize(vec_f32(?))
let result = Vec.add(normalized, Vec.f32("[0, 2, 0]"))
// vec_add(vec_normalize(vec_f32(?)), vec_f32(?))
```

`Vec.f32` accepts JSON string expressions, with an optional matching `as:` strategy.
Normalization and default arithmetic results retain known dimensions. When one arithmetic operand
is variable-size, the fixed operand determines the result's dimension type. Distances, arithmetic,
and `MATCH` require equal fixed counts; variable-size operands are checked by the database.
`as:` result counts and slice bounds remain runtime decoding constraints.

### Signed Int8 vectors

Use `[Int8].Int8BytesRepresentation` for one signed byte per component:

```swift
// CREATE VIRTUAL TABLE Int8Embeddings USING vec0(embedding int8[3], label text);
@Table("Int8Embeddings")
struct Int8Embedding: Vec0 {
  @Column(as: [Int8].Int8BytesRepresentation.self)
  var embedding: [Int8]
  var label: String
}

let codes: [Int8].Int8BytesRepresentation = [-128, 0, 127]
let insert = Int8Embedding.insert { ($0.embedding, $0.label) } values: {
  (Vec.int8(codes), "example")
}
// INSERT INTO "Int8Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)

let query = Int8Embedding
  .where { $0.embedding.match(codes) }
  .order { $0.distance }
  .limit(5)
// SELECT "Int8Embeddings"."embedding", "Int8Embeddings"."label"
// FROM "Int8Embeddings"
// WHERE (("Int8Embeddings"."embedding" MATCH vec_int8(?)))
// ORDER BY "Int8Embeddings"."distance"
// LIMIT ?
```

`Vec.int8` tags signed bytes or parses integer JSON, such as `Vec.int8("[-128, 0, 127]")`.
Insert and update expressions need that subtype; query helpers attach it automatically.

```swift
let floats: [Float].VectorBytesRepresentation = [-1, 0, 0.5, 2]
let codes = Vec.quantizeInt8(floats)
// vec_quantize_int8(?, 'unit')
let fixedCodes = Vec.quantizeInt8(
  floats,
  as: FixedEmbeddingVector<4, Int8>.Int8BytesRepresentation.self
)
// vec_quantize_int8(?, 'unit')
```

Quantization maps [-1, 1] to signed codes, clamps out-of-range values, and truncates toward zero
using sqlite-vec's Float32 rounding. It does not normalize. These bytes have no scale or shift
metadata. Keep Int8 arithmetic results in range to avoid overflow.

### Binary vectors

This target supplies `.PackedBitsRepresentation` on `[Bool]` and `BinaryEmbeddingVector<N>`.
Both use raw packed bytes, least significant bit first, with no dimension or format metadata.
Dimensions must be divisible by eight. The shared binary value and its `packedBytes` support
partial bytes independently of this strategy.

Validate user-provided components before wrapping them:

```swift
let components = [true, false, true, false, false, false, false, true]
let bits = try [Bool].PackedBitsRepresentation(validating: components)
let fixed = try BinaryEmbeddingVector<8>.PackedBitsRepresentation(
  validating: BinaryEmbeddingVector<8>(packedBytes: bits.vectorBytes)
)
```

Both initializers throw `[Bool].PackedBitsRepresentation.InvalidDimensionsError` for counts not
divisible by eight. Its `dimensions` property identifies the rejected count. The nonthrowing query
strategy initializer, array literals, and mutation precondition alignment immediately.

`[Bool].PackedBitsRepresentation` stores bits without metadata. Dimensions and slice boundaries
must be divisible by eight:

```swift
// CREATE VIRTUAL TABLE BinaryEmbeddings USING vec0(embedding bit[8], label text);
@Table("BinaryEmbeddings")
struct BinaryEmbedding: Vec0 {
  @Column(as: [Bool].PackedBitsRepresentation.self)
  var embedding: [Bool]
  var label: String
}

let bits: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
let insert = BinaryEmbedding.insert { ($0.embedding, $0.label) } values: {
  (Vec.bit(bits), "example")
}
// INSERT INTO "BinaryEmbeddings" ("embedding", "label") VALUES (vec_bit(?), ?)

let query = BinaryEmbedding
  .where { $0.embedding.match(bits) }
  .order { $0.distance }
  .limit(5)
// SELECT "BinaryEmbeddings"."embedding", "BinaryEmbeddings"."label"
// FROM "BinaryEmbeddings"
// WHERE (("BinaryEmbeddings"."embedding" MATCH vec_bit(?)))
// ORDER BY "BinaryEmbeddings"."distance"
// LIMIT ?
```

Use `Vec.bit` for binary insert and update expressions; query helpers apply it automatically.
`Vec.quantizeBinary` converts positive Float32 or Int8 components to true bits and returns a
packed-bit representation. `Vec.bit` tags or reinterprets bytes without numerical quantization.

`Vec.each` iterates bits most significant first within each byte. Swift collection indices and
`Vec.toJSON` use least significant first.

### Fixed-size values

`EmbeddingVector<N>` binds Float32 directly. Signed Int8 and binary columns use
`FixedEmbeddingVector<N, Int8>.Int8BytesRepresentation` and
`BinaryEmbeddingVector<N>.PackedBitsRepresentation`. These types require Swift 6.2 and iOS 26,
macOS 26, tvOS 26, watchOS 26, or visionOS 26.

See the [shared vector documentation](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/),
[sqlite-vec API reference](https://alexgarcia.xyz/sqlite-vec/api-reference.html), and
[migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).
