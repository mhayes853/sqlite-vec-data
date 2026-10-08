# ``StructuredQueriesVectorCore``

Shared vector values, byte representations, and codecs for StructuredQueries.

## Overview

Both `StructuredQueriesSQLiteVecCore` and `StructuredQueriesTursoVecCore` export this module.
Use byte strategies with `@Column(as:)`, or fixed-size values for dimension-checked decoding.

### Array representations

```swift
import StructuredQueriesSQLite
import StructuredQueriesVectorCore

// CREATE TABLE documents (id INTEGER PRIMARY KEY, embedding BLOB NOT NULL);
@Table("documents")
struct Document {
  var id: Int
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

let vector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
```

| Strategy | Byte format | Vector query support |
| --- | --- | --- |
| `[Float].VectorBytesRepresentation` | Little-endian Float32 | sqlite-vec and Turso |
| `[Double].VectorBytesRepresentation` | Tagged little-endian Float64 | Turso |
| `[Float16].VectorBytesRepresentation` | Raw little-endian binary16 | Serialization only |
| `[Bool].PackedBitsRepresentation` | Packed bits without metadata | sqlite-vec |

SQLiteVec reads native Float32 memory; shared Float32 bytes are compatible on little-endian
platforms. Turso's `.TursoBytesRepresentation` adds binary dimension metadata and belongs to the
Turso target. Signed `.Int8BytesRepresentation` belongs to the sqlite-vec target.

### Fixed-size vectors

``FixedEmbeddingVector`` stores scalars in an inline array and provides a mutable random-access
collection, hashing, and Codable scalar arrays:

| Type | Scalar | Query representation |
| --- | --- | --- |
| `EmbeddingVector<N>` | `Float` | Direct binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` | `Double` | `.VectorBytesRepresentation` |
| `FixedEmbeddingVector<N, Int8>` | `Int8` | `.Int8BytesRepresentation` from the sqlite-vec target |
| `BinaryEmbeddingVector<N>` | `Bool` | Explicit binary strategy |

Fixed-size types require Swift 6.2 and iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.
`InlineArray` also exposes floating-point `VectorBytesRepresentation` strategies.

```swift
let vector = EmbeddingVector<4>([0.1, 0.2, 0.3, 0.4])
let doubles = EmbeddingVector64<4>([0.1, 0.2, 0.3, 0.4])
let binding = EmbeddingVector64<4>.VectorBytesRepresentation(queryOutput: doubles)
```

Use `@Column(as:)` for explicit strategies and `init(queryOutput:)` to wrap bindings.
Dense equality follows scalar semantics: signed zeros compare equal; NaNs compare unequal.

### Packed binary values

``BinaryEmbeddingVector`` exposes mutable Bool elements while storing `ceil(N / 8)` bytes;
1,536 dimensions use 192 bytes. Codable uses a Bool array. `packedBytes` has no database metadata,
and `init(packedBytes:)` checks the byte count and clears unused high bits.

```swift
let dense = EmbeddingVector<8>([1, -1, 0, 2, -3, 4, 0, 5])
var binary = BinaryEmbeddingVector<8>(quantizing: dense)
binary[2] = true
let trueBits = binary.nonzeroBitCount
let distance = binary.hammingDistance(to: BinaryEmbeddingVector<8>(repeating: false))
```

Sign quantization tests `value > 0`: zeros, negatives, and NaNs become false. It discards magnitudes.
Local Hamming distance counts differing bits and returns `Int`.

`.PackedBitsRepresentation` uses least significant bit first and requires dimensions divisible
by eight. The Turso target supplies `.TursoBytesRepresentation`, which preserves partial-byte
lengths. Fixed-size strategies bind and decode packed bytes directly.

### Serialize vector bytes

```swift
let values = [Float(1), 2, 3]
let bytes = values.vectorBytes
let restored = try [Float](vectorBytes: bytes)
let fixed = try EmbeddingVector<3>(vectorBytes: bytes)
let validated = try EmbeddingVector<3>(validating: values)
```

`init(vectorBytes:)` validates byte lengths, format metadata, and fixed dimensions.
`init(validating:)` checks a scalar array's count. Invalid bytes and dimensions throw
``VectorDecodingError``. Query binding wraps these bytes in a BLOB; query decoding uses the same
initializer.

### Codecs and encoding identity

``VectorScalar`` supplies codecs for Float16, Float, and Double through an unsigned integer
`BitPattern`, `bitPattern`, and `init(bitPattern:)`. The default codec preserves IEEE bits in
little-endian order. Float accepts an optional Float32 tag when decoding; Double writes and
validates Turso's Float64 tag. Custom floating-point conformances can reuse or override these codecs.
Serialization support does not add a format to database query helpers.

``VectorBytesRepresentable`` identifies the byte layout through `Encoding`, a canonical
representation independent of dimensions. For example, `EmbeddingVector<3>` and
`[Float].VectorBytesRepresentation` share an encoding. Its `VectorBytesRepresentation` associated
type selects the wrapper for a particular value, including fixed dimensions.

Turso's `InlineQuantized8Vector<N>` shares `Quantized8Vector`'s encoding, and
`SizedSparseFloat32Vector<N>` shares `SparseFloat32Vector`'s encoding. These encoded values live
in the Turso target and bind directly. Their equality compares stored component bit patterns.

See <doc:VectorMigration> for migration guidance.
