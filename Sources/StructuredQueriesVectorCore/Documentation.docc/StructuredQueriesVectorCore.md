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

`Float` uses raw, little-endian float32 bytes, compatible with Turso BLOB columns and
SQLiteVec float columns on little-endian platforms. SQLiteVec reads native float memory, so the
formats are not interchangeable on big-endian systems.

`[Double].VectorBytesRepresentation` uses Turso's tagged float64 blob format. This format is not
supported by SQLiteVec float columns. Decoding validates byte lengths and format tags instead of
silently discarding incomplete elements.

### Fixed-size vectors

``FixedEmbeddingVector`` is a Hashable and Codable fixed-length array alternative to `InlineArray`.
Prefer its aliases for the supported scalar types:

| Value type | Scalar | Default query representation |
| --- | --- | --- |
| `EmbeddingVector<N>` | `Float` | Direct binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` | `Double` | `.VectorBytesRepresentation` |
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
format and dimension metadata and supports partial-byte lengths. It also provides
`Quantized8Vector`, `InlineQuantized8Vector<N>`, `SparseFloat32Vector`, and
`SizedSparseFloat32Vector<N>` for Turso-specific encoded values. Quantized values retain unsigned
byte codes, scale, and shift. Sparse values retain their entries without expanding into dense
arrays. These types are directly query-bindable and belong to `StructuredQueriesTursoVecCore`.

### Encoding matching

``VectorBytesRepresentable`` identifies a vector's byte layout with its `Encoding` associated
type. That identity is an existing canonical representation, independent of dimensions:

| Vector family | `Encoding` |
| --- | --- |
| Dense float32 | `[Float].VectorBytesRepresentation` |
| Dense float64 | `[Double].VectorBytesRepresentation` |
| SQLiteVec binary | `[Bool].PackedBitsRepresentation` |
| Turso binary | `[Bool].TursoBytesRepresentation` |
| Turso quantized8 | `Quantized8Vector` |
| Turso sparse float32 | `SparseFloat32Vector` |

For example, `EmbeddingVector<3>` and `[Float].VectorBytesRepresentation` share an encoding.
`InlineQuantized8Vector<N>` uses `Quantized8Vector`, and `SizedSparseFloat32Vector<N>` uses
`SparseFloat32Vector`. Those Turso types are defined in `StructuredQueriesTursoVecCore`.

The separate `VectorBytesRepresentation` associated type identifies the wrapper for the particular
value, including any fixed-dimension constraint. Generic query helpers compare `Encoding` types;
there is no separate enum of format markers.

### Serialize without a query decoder

Vector values and representations expose `vectorBytes` and `init(vectorBytes:)`:

```swift
let values = [Float(1), 2, 3]
let bytes = values.vectorBytes
let restored = try [Float](vectorBytes: bytes)
let representation = try [Float].VectorBytesRepresentation(vectorBytes: bytes)

let fixed = try EmbeddingVector<3>(vectorBytes: bytes)
let validated = try EmbeddingVector<3>(validating: values)
```

`init(vectorBytes:)` validates byte lengths, format metadata, and any fixed dimension count.
`FixedEmbeddingVector.init(validating:)` also accepts scalar arrays, including logical binary
values, and throws `VectorDecodingError.dimensionMismatch` when their count differs.
Fixed-size APIs require the platform availability described above.

For query-bindable vectors and representations, `queryBinding` wraps `vectorBytes` in a BLOB,
and `init(decoder:)` passes the decoded BLOB to `init(vectorBytes:)`. Drivers and other consumers
can use the same serialization directly.

``VectorScalar`` requires `encodeVector(_:)` and `decodeVector(_:)`. Float and Double implement
their default byte layouts directly, preserving IEEE bit patterns. Custom conformances supply
these operations instead of relying on a runtime format switch. These methods serialize a whole
vector; Double's encoding includes Turso's float64 type byte.

``VectorScalar`` and ``VectorBytesRepresentable`` are the two vector abstraction protocols.
Engine-specific SQL functions live in the `TursoVec` and `Vec` namespaces; tables need no
additional Turso conformance.
