# ``StructuredQueriesSQLiteVecCore``

StructuredQueries helpers for [sqlite-vec](https://github.com/asg017/sqlite-vec) that are not tied to SQLiteData.

## Overview

Use ``Vec0`` tables, `TableColumnExpression` helpers like `match(_:)` and ``StructuredQueriesCore/TableColumnExpression/distanceCosine(to:)``, and the ``Vec`` namespace to build vector search queries without writing SQL strings directly.

### Match queries

```swift
@Table("Embeddings")
struct Embedding: Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]

  var label: String
}

let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
let query = Embedding
  .where { $0.embedding.match(queryVector) }
  .order { $0.distance.asc() }
  .limit(5)
  .select { ($0.label, $0.distance) }
```

### Distance functions

```swift
let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
let query = Embedding.select {
  ($0.label, $0.embedding.distanceCosine(to: queryVector))
}
```

### Iterate over vector elements

Use `vecEach()` to iterate over a vector's indexed
elements with SQLite Vec's `vec_each` virtual table.

```swift
let query = Embedding
  .join(Embedding.columns.embedding.vecEach()) { _, _ in true }
  .select { embedding, element in
    (embedding.label, element.rowid, element.value)
  }
```

The returned ``VecEach`` statement can be filtered, ordered, aggregated, and used in correlated
subqueries. For example, filter to rows containing a negative element:

```swift
let query = Embedding
  .where {
    $0.embedding.vecEach()
      .where { $0.value.lt(Float(0)) }
      .exists()
  }
  .select(\.label)
```

Or aggregate a vector's elements:

```swift
let query = Embedding.select {
  (
    $0.label,
    $0.embedding.vecEach().count(),
    $0.embedding.vecEach().select { $0.value.max() }
  )
}
```

Use `Vec.each(_:)` to iterate over a bound vector without a table:

```swift
let vector: [Float].VectorBytesRepresentation = [1, -2, 3]
let query = Vec.each(vector)
  .order { $0.rowid }
  .select { ($0.rowid, $0.value) }
```

## EmbeddingVector

`EmbeddingVector` is a Hashable and Codable fixed-length array alternative to `InlineArray`.
It is provided by the re-exported `StructuredQueriesVectorCore` module, alongside the float
vector byte representations. It is available on iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0,
and visionOS 26.0, and it can be stored in vec0 tables or used directly as a query binding.

```swift
@Table("Embeddings")
struct Embedding: Vec0 {
  var id: UUID
  var embedding: EmbeddingVector<1536>
}

let queryVector = EmbeddingVector<1536>([...])
let query = Embedding
  .where { $0.embedding.match(queryVector) }
  .select { ($0.id, $0.distance) }
```

## Supported vector encodings

SQLiteVec helpers constrain the vector's `Encoding` associated type. Float32 arrays, inline arrays,
and `EmbeddingVector<N>` share `[Float].VectorBytesRepresentation` and can be used together.
Float64, Turso quantized and sparse vectors, and Turso binary framing are rejected at compile time.

L1, L2, cosine, addition, subtraction, and normalization accept Float32. Hamming accepts raw packed
bits. Inspection, slicing, iteration, and `MATCH` support either encoding; comparisons require both
operands to use the same encoding. The `as:` overloads for Float32 operations and packed-bit
operations require a result with the operation's output encoding. Fixed result types additionally
validate dimensions while decoding. Generic client helpers must carry the applicable `Encoding`
constraint.

These checks do not add a signed Int8 representation. Turso's quantized UInt8 format is different
from SQLiteVec's signed Int8 vectors.

## Binary vectors

Use `[Bool].PackedBitsRepresentation` or `BinaryEmbeddingVector<N>.PackedBitsRepresentation`
for SQLiteVec binary blobs. They store logical bits without format metadata; binding requires
a dimension count divisible by eight.

```swift
// CREATE VIRTUAL TABLE BinaryEmbeddings USING vec0(embedding bit[8], label text);
@Table("BinaryEmbeddings")
struct BinaryEmbedding: Vec0 {
  @Column(as: [Bool].PackedBitsRepresentation.self)
  var embedding: [Bool]
  var label: String
}

let queryVector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
let insert = BinaryEmbedding.insert {
  ($0.embedding, $0.label)
} values: {
  (Vec.bit(queryVector), "example")
}
let query = BinaryEmbedding
  .where { $0.embedding.match(queryVector) }
  .order { $0.distance }
  .limit(5)
  .select { ($0.label, $0.distance) }
```

`Vec.bit` and `Vec.quantizeBinary` return this representation by default. Their `as:` overloads
accept matching packed-bit representations, including fixed-size vectors. This replaces the
previous float32 result representation, which could discard short binary blobs while decoding.
Turso's binary representation includes different metadata and cannot be used in its place.

Binary scalar operations and `MATCH` apply `vec_bit(...)` automatically, so bound blobs have the
subtype SQLiteVec requires. When inserting or updating a vec0 binary column, use `Vec.bit` in the
value expression, as in the insert above; binding a table value alone cannot attach a SQLite subtype.
Binary slice boundaries must be divisible by eight.

`Vec.each` and `.vecEach()` follow SQLiteVec's bit iteration order: most significant bit first within
each byte. The packed representations index their logical bits least significant bit first, which
also matches SQLiteVec's `vec_to_json` order.
