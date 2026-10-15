# ``StructuredQueriesVectorCore``

Shared vector values, byte representations, and codecs for StructuredQueries.

## Overview

Use byte strategies with `@Column(as:)` or fixed values for dimension-checked decoding. Codecs
serialize scalar bits; binary values expose packed bytes. Integration targets supply database
formats and queries.

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

| Strategy | Byte format |
| --- | --- |
| `[Float].VectorBytesRepresentation` | Raw little-endian Float32 |
| `[Double].VectorBytesRepresentation` | Raw little-endian Float64 |
| `[Float16].VectorBytesRepresentation` | Raw little-endian binary16 |

Serialization support does not imply support for vector queries in a database.

### Fixed-size vectors

``FixedEmbeddingVector`` stores inline scalars with mutable random access, hashing, and Codable
scalar arrays:

| Type | Scalar | Query representation |
| --- | --- | --- |
| `EmbeddingVector<N>` | `Float` | Direct raw binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` | `Double` | `.VectorBytesRepresentation` |
| `FixedEmbeddingVector<N, Int8>` | `Int8` | Strategy supplied by a database integration |
| `BinaryEmbeddingVector<N>` | `Bool` | Explicit binary strategy |

Fixed-size types require iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.
`InlineArray` also exposes floating-point `VectorBytesRepresentation` strategies.

```swift
let vector = EmbeddingVector<4>([0.1, 0.2, 0.3, 0.4])
let doubles = EmbeddingVector64<4>([0.1, 0.2, 0.3, 0.4])
let binding = EmbeddingVector64<4>.VectorBytesRepresentation(queryOutput: doubles)
let byteCount = binding.vectorBytes.count // 32 raw bytes for four Float64 components.
```

Use `@Column(as:)` for explicit strategies and `init(queryOutput:)` to wrap bindings.
Dense equality follows scalar semantics: signed zeros compare equal; NaNs compare unequal.

### Packed binary values

``BinaryEmbeddingVector`` provides mutable Bool elements in `ceil(N / 8)` bytes: 1,536 dimensions
use 192 bytes. Codable stores Bool arrays. `init(packedBytes:)` checks length and clears unused bits.

```swift
let dense = EmbeddingVector<8>([1, -1, 0, 2, -3, 4, 0, 5])
var binary = BinaryEmbeddingVector<8>(quantizing: dense)
binary[2] = true
let bytes = binary.packedBytes // [0xad]
let partial = BinaryEmbeddingVector<9>(repeating: true)
let restored = try BinaryEmbeddingVector<9>(packedBytes: [0xff, 0xff])
let normalizedBytes = restored.packedBytes // [0xff, 0x01]: unused high bits cleared.
let trueBits = binary.nonzeroBitCount // 5
let candidate = try BinaryEmbeddingVector<8>(packedBytes: [0x85])
let distance = binary.hammingDistance(to: candidate) // 2 differing bits.
```

Sign quantization uses `value > 0`; zeros, negatives, and NaNs become false. Hamming distance
returns the number of differing bits as `Int`.

Bits start at the least significant bit of the first byte. Counts may include partial bytes, with
unused trailing bits cleared. Integration targets add database binding and decoding strategies.

### Serialize vector bytes

```swift
// A Float32 payload retrieved from a vector cache.
let bytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
let values = try [Float](vectorBytes: bytes) // [1, 0, 0]
let fixed = try EmbeddingVector<3>(vectorBytes: bytes)
let validated = try EmbeddingVector<3>(validating: values)
// A payload or array with a different component count throws.
```

`init(vectorBytes:)` validates payloads and fixed dimensions; `init(validating:)` checks array
counts. Failures throw ``VectorDecodingError``. Queries bind these bytes as BLOBs and decode
through the same initializer.

### Codecs and encoding identity

``VectorScalar`` supplies Float16, Float, and Double bit patterns through an unsigned `BitPattern`,
`bitPattern`, and `init(bitPattern:)`. Generic codecs preserve IEEE bits in little-endian order,
reject incomplete components, and add no tags. They are not customization points; scalar
conformance alone does not add database support.

``VectorBytesRepresentable`` uses `Encoding` to identify a layout independently of dimensions:
`EmbeddingVector<3>` and `[Float].VectorBytesRepresentation` share it. The associated
`VectorBytesRepresentation` selects the value's wrapper, including fixed dimensions.

Both associated representations conform to `VectorBytesRepresentable` and `QueryBindable` with
matching scalars. The query wrapper also preserves `Encoding` and `Dimensions`. The `Document`
strategy above wraps values as BLOBs on insert:

```swift
let embedding: [Float] = [0.1, 0.2, 0.3]
let insert = Document.insert { ($0.id, $0.embedding) } values: {
  (1, embedding)
}
// INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
```

`Dimensions` is `Void` for runtime-sized values or ``VectorDimensions`` for a fixed count across
scalar types and strategies. Helpers reject unequal known counts and allow variable operands.
Self-representing runtime types must declare `Dimensions = Void` to resolve recursive constraints.
Canonical encoding dimensions are independent of the value's count.

```swift
func dotProduct<L: Collection & VectorBytesRepresentable, R: Collection & VectorBytesRepresentable>(
  _ left: L, _ right: R
) -> Float where L.Element == Float, R.Element == Float, L.Dimensions == R.Dimensions {
  precondition(left.count == right.count)
  return zip(left, right).reduce(0) { $0 + $1.0 * $1.1 }
}
let score = dotProduct(EmbeddingVector<3>([1, 0, 0]), EmbeddingVector<3>([0.5, 1, 0])) // 0.5
```

Integration targets add encoded values and strategies without changing shared serialization.

``BinaryVectorEncoding`` requires `Scalar == Bool`; integration protocols add layouts and
capabilities. Different binary framing remains incompatible.

See the [migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).
