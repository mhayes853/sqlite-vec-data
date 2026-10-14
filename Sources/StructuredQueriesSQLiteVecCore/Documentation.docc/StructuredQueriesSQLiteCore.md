# ``StructuredQueriesSQLiteVecCore``

StructuredQueries helpers for [sqlite-vec](https://github.com/asg017/sqlite-vec).

## Overview

Use ``Vec0`` tables, column helpers, or the ``Vec`` namespace. This module exports
`StructuredQueriesVectorCore`; load sqlite-vec through `SQLiteVecData` or your driver.

SQL comments show generated queries; placeholders represent bound values.

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

`match` requires a vec0 vector column. Nearest-neighbor queries require `LIMIT` or a `k` constraint.

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

Scalar helpers accept bound values, computed expressions, and BLOB columns. Slices default to
variable-size results; `as:` selects a fixed result with dimension-checked decoding.

Distances return `Double` (SQL REAL); Int8 L1 is cast from integer to REAL. Length returns `Int`.
Iteration yields `VecEachOf<Float>` (also ``VecEach``), `VecEachOf<Int8>`, or `VecEachOf<Bool>`.

Column and namespace helpers support these encodings:

| Operation | Float32 | Signed Int8 | Packed bits |
| --- | --- | --- | --- |
| `MATCH`, length, type, JSON, slice, iteration | Yes | Yes | Yes |
| L1, L2, cosine, addition, subtraction | Yes | Yes | — |
| Normalization | Yes | — | — |
| Hamming distance | — | — | Yes |
| Binary sign quantization | Yes | Yes | — |

Comparisons require matching encodings; `as:` must match the output encoding. Float64 and
Turso-specific formats are unsupported.

### Iterate over elements

``VecEach`` exposes `rowid` and `value` for joins, filters, and aggregates:

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

Both forms supply the hidden vector constraint, including in correlated subqueries.

### Float32 JSON and fixed dimensions

```swift
let vector = Vec.f32("[3, 0, 0]", as: EmbeddingVector<3>.self)
// vec_f32(?)
let normalized = Vec.normalize(vector)
// vec_normalize(vec_f32(?))
let result = Vec.add(normalized, Vec.f32("[0, 2, 0]"))
// vec_add(vec_normalize(vec_f32(?)), vec_f32(?))
```

`Vec.f32` accepts JSON and optional `as:` strategies. Constructors, quantization, normalization,
and arithmetic preserve known dimensions; a fixed arithmetic operand determines the result count
when the other is variable-size. Distances, arithmetic, and `MATCH` reject unequal fixed counts.
The database checks variable inputs; decoding validates fixed results. Length-preserving `as:`
results require compatible known counts. Slice bounds and lengths remain runtime checks.

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

`Vec.int8` tags signed bytes or parses integer JSON. Inserts and updates require the subtype;
queries attach it automatically.

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

Quantization maps [-1, 1] to signed codes, clamps, and truncates toward zero with Float32 rounding.
It adds no normalization, scale, or shift. Keep arithmetic results in range to avoid overflow.

### Binary vectors

`.PackedBitsRepresentation` on `[Bool]` and `BinaryEmbeddingVector<N>` stores raw bytes, least
significant bit first. Counts must be divisible by eight. The shared binary value supports partial
bytes; this SQLiteVec strategy does not.

Validate user-provided components before wrapping them:

```swift
let components = [true, false, true, false, false, false, false, true]
let bits = try [Bool].PackedBitsRepresentation(validating: components)
let fixed = try BinaryEmbeddingVector<8>.PackedBitsRepresentation(
  validating: BinaryEmbeddingVector<8>(packedBytes: bits.vectorBytes)
)
```

Both initializers throw `[Bool].PackedBitsRepresentation.InvalidDimensionsError` with the rejected
`dimensions`. Nonthrowing construction, literals, and mutation precondition alignment.

Binary slices require byte-aligned bounds:

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

Use `Vec.bit` for inserts and updates; queries tag automatically. `Vec.quantizeBinary` maps
positive Float32 or Int8 components to true bits. `Vec.bit` tags bytes without quantizing.

`Vec.each` iterates most significant bit first; Swift indices and `Vec.toJSON` use least significant
bit first within each byte.

### Encoding capabilities

``SQLiteVecVectorEncoding`` supplies the SQL subtype hook. ``SQLiteVecNumericEncoding`` supports
Float32 and Int8 numeric operations; ``SQLiteVecFloat32Encoding``, ``SQLiteVecInt8Encoding``, and
``SQLiteVecBinaryEncoding`` identify exact layouts. Binary also refines `BinaryVectorEncoding`.

```swift
func numericDistance<L: VectorBytesRepresentable, R: VectorBytesRepresentable>(
  _ left: some QueryExpression<L>, to right: some QueryExpression<R>
) -> some QueryExpression<Double>
where L.Encoding: SQLiteVecNumericEncoding, L.Encoding == R.Encoding,
  L.Dimensions == R.Dimensions {
  Vec.distanceL2(left, to: right)
}
let left: [Int8].Int8BytesRepresentation = [3, 4, 0]
let right: [Int8].Int8BytesRepresentation = [0, 0, 0]
let distance = numericDistance(left, to: right)
// vec_distance_l2(vec_int8(?), vec_int8(?))
```

Custom encodings adopt a leaf protocol and validate bytes and dimensions. Its default
`sqliteVecExpression` tags Int8 and binary; Float32 passes through. Two-vector operations still
require matching canonical encodings and compatible dimensions.

### Fixed-size values

`EmbeddingVector<N>` binds Float32 directly. Int8 uses
`FixedEmbeddingVector<N, Int8>.Int8BytesRepresentation`; binary uses
`BinaryEmbeddingVector<N>.PackedBitsRepresentation`. Fixed types require Swift 6.2 and iOS 26,
macOS 26, tvOS 26, watchOS 26, or visionOS 26.

See the [shared vector documentation](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/),
[sqlite-vec API reference](https://alexgarcia.xyz/sqlite-vec/api-reference.html), and
[migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).
