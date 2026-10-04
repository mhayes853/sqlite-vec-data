# ``StructuredQueriesVectorCore``

Reusable scalar vector values and query representations for StructuredQueries.

## Overview

Both `StructuredQueriesSQLiteVecCore` and `StructuredQueriesTursoVecCore` export this module,
so existing SQLiteVec imports continue to expose `EmbeddingVector`, `VectorBytesRepresentable`,
and float32 vector byte representations.

### Array representations

Use `@Column(as:)` to store scalar values in a blob column:

```swift
import StructuredQueriesSQLite
import StructuredQueriesVectorCore

@Table("documents")
struct Document {
  var id: Int
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
```

`Float` uses raw, little-endian float32 bytes, compatible with Turso `F32_BLOB` columns and
SQLiteVec float columns on little-endian platforms. SQLiteVec reads native float memory, so the
formats are not interchangeable on big-endian systems.

`[Double].VectorBytesRepresentation` and `[Float16].VectorBytesRepresentation` use tagged
float64 and libSQL's float16 blob formats, including their type metadata. These formats are not supported
by SQLiteVec float columns. Decoding validates byte lengths and format tags instead of silently
discarding incomplete elements.

### Fixed-size vectors

``FixedEmbeddingVector`` is a Hashable and Codable fixed-length array alternative to `InlineArray`.
Prefer its aliases for the supported scalar types:

| Value type | Scalar | Default query representation |
| --- | --- | --- |
| `EmbeddingVector<N>` | `Float` | Direct binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` | `Double` | `.VectorBytesRepresentation` |
| `EmbeddingVector16<N>` | `Float16` | `.VectorBytesRepresentation` |
| `BinaryEmbeddingVector<N>` | `Bool` | Explicit binary representation |

Fixed-size types require Swift 6.2 or later and are available on iOS 26.0, macOS 26.0, tvOS 26.0,
watchOS 26.0, and visionOS 26.0. They support mutable random-access collection operations,
element-wise equality and hashing, and Codable scalar arrays. Signed zeros compare equal, and
NaNs compare unequal, matching Swift's floating-point equality. This replaces the former
float32 comparison of raw memory.

```swift
@Table("documents")
struct Document {
  var id: Int
  var embedding: EmbeddingVector<4>
}

let queryVector = EmbeddingVector<4>([0.1, 0.2, 0.3, 0.4])
```

The existing float32 type remains directly query-bindable. For other precisions, specify the
representation with `@Column(as:)` and wrap bound values using `init(queryOutput:)`.
`InlineArray` also provides a `VectorBytesRepresentation` for floating-point scalars.
All fixed-size representations validate the decoded dimension count.

### Binary representations

`[Bool].PackedBitsRepresentation` and `BinaryEmbeddingVector<N>.PackedBitsRepresentation` store
bits without metadata, compatible with SQLiteVec binary vectors. The first element occupies the
least significant bit of the first byte. Binding requires a dimension count divisible by eight,
because this format cannot preserve partial-byte lengths.

The Turso target adds `.TursoBytesRepresentation` to both value types. It includes Turso's binary
format and dimension metadata and supports partial-byte lengths. It also adds
`.BFloat16Representation`, `.Float8Representation`, and `.SparseRepresentation` to float32 arrays
and fixed-size vectors. Bfloat16 and float16 blobs require libSQL; sparse float32 blobs require
the Rust-based Turso engine. The sparse representation exposes dense Swift values and stores
only nonzero components in the database.

### Format matching

The named representations are concrete wrappers that conform to ``VectorBytesRepresentable``.
Its `Scalar` and `Format` associated types let query helpers compare byte layouts and distinguish
floating-point operations from binary operations. ``VectorFormat`` provides type identities such
as `Float32`, `BFloat16`, `PackedBits`, and `TursoBits`; serialization stays in internal helpers.

``VectorScalar`` selects the default format for Float, Double, and Float16. It and
``VectorBytesRepresentable`` are the two vector abstraction protocols. The value and representation
names above are the public entry points for modeling columns, binding values, and selecting
fixed-size results. Engine-specific functions live in the `TursoVec`, `LibSQLVec`, and `Vec`
namespaces; tables need no additional Turso or libSQL conformance.
