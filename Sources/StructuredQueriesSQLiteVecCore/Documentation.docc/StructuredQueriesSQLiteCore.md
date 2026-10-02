# ``StructuredQueriesSQLiteVecCore``

StructuredQueries helpers for [sqlite-vec](https://github.com/asg017/sqlite-vec) that are not tied to SQLiteData.

## Overview

Use ``Vec0`` tables, `TableColumnExpression` helpers like ``StructuredQueriesCore/TableColumnExpression/match(_:)`` and ``StructuredQueriesCore/TableColumnExpression/distanceCosine(to:)``, and the ``Vec`` namespace to build vector search queries without writing SQL strings directly.

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

Use ``StructuredQueriesCore/QueryExpression/vecEach()`` to iterate over a vector's indexed
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

Use ``Vec/each(_:)`` to iterate over a bound vector without a table:

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

## Binary vectors

Use `[Bool].PackedBitsRepresentation` or `BinaryEmbeddingVector<N>.PackedBitsRepresentation`
for SQLiteVec binary blobs. They store logical bits without format metadata; binding requires
a dimension count divisible by eight.

```swift
let queryVector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
let query = Vec.bit(queryVector)
```

`Vec.bit` and `Vec.quantizeBinary` return this representation by default. Their `as:` overloads
accept matching packed-bit representations, including fixed-size vectors. This replaces the
previous float32 result representation, which could discard short binary blobs while decoding.
Turso's binary representation includes different metadata and cannot be used in its place.
