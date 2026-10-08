# ``StructuredQueriesSQLiteVecCore``

StructuredQueries helpers for [sqlite-vec](https://github.com/asg017/sqlite-vec).

## Overview

Model virtual tables with ``Vec0`` and use column helpers or the ``Vec`` namespace for vector
queries. This module exports `StructuredQueriesVectorCore`; load the sqlite-vec extension through
`SQLiteVecData` or your SQLite driver.

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
// SELECT label, distance FROM Embeddings
// WHERE embedding MATCH ? ORDER BY distance LIMIT ?;
```

`match` accepts bound values and computed expressions with matching encodings:

```swift
let query = Embedding
  .where { $0.embedding.match(Vec.normalize(vector)) }
  .limit(5)
// WHERE embedding MATCH vec_normalize(?)

let freeform = Embedding
  .where { Vec.match($0.embedding, to: Vec.normalize(vector)) }
  .limit(5)
```

The left operand must be a vec0 vector column. A nearest-neighbor query requires `LIMIT` or a
constraint on vec0's `k` column.

### Distances and vector operations

```swift
let distances = Embedding.select {
  ($0.label, $0.embedding.distanceCosine(to: vector))
}
// SELECT label, vec_distance_cosine(embedding, ?) FROM Embeddings;

let normalized = Vec.normalize(vector) // vec_normalize(?)
let sliced = Vec.slice(vector, start: 0, end: 2) // vec_slice(?, 0, 2)
```

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
// SELECT rowid, value FROM vec_each WHERE vector = ? ORDER BY rowid;

let joined = Embedding
  .join(Embedding.columns.embedding.vecEach()) { _, _ in true }
  .select { embedding, element in
    (embedding.label, element.rowid, element.value)
  }

let withNegativeElements = Embedding
  .where {
    $0.embedding.vecEach()
      .where { $0.value.lt(Float(0)) }
      .exists()
  }
  .select(\.label)
```

Both helpers supply `vec_each`'s hidden vector constraint, including in correlated subqueries.

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
// INSERT INTO Int8Embeddings (embedding, label) VALUES (vec_int8(?), ?);

let query = Int8Embedding
  .where { $0.embedding.match(codes) }
  .order { $0.distance }
  .limit(5)
```

`Vec.int8` tags signed bytes or parses integer JSON, such as `Vec.int8("[-128, 0, 127]")`.
Insert and update expressions need that subtype; query helpers attach it automatically.

```swift
let floats: [Float].VectorBytesRepresentation = [-1, 0, 0.5, 2]
let codes = Vec.quantizeInt8(floats) // vec_quantize_int8(?, 'unit')
let fixedCodes = Vec.quantizeInt8(
  floats,
  as: FixedEmbeddingVector<4, Int8>.Int8BytesRepresentation.self
)
```

Quantization maps [-1, 1] to signed codes, clamps out-of-range values, and truncates toward zero
using sqlite-vec's Float32 rounding. It does not normalize. These bytes have no scale or shift
metadata. Keep Int8 arithmetic results in range to avoid overflow.

### Binary vectors

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
// INSERT INTO BinaryEmbeddings (embedding, label) VALUES (vec_bit(?), ?);

let query = BinaryEmbedding
  .where { $0.embedding.match(bits) }
  .order { $0.distance }
  .limit(5)
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
[migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/StructuredQueriesVectorCore/Documentation.docc/VectorMigration.md).
