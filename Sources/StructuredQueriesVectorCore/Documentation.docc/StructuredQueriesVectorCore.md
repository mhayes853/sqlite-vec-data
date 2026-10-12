# ``StructuredQueriesVectorCore``

Shared vector values, byte representations, and codecs for StructuredQueries.

## Overview

Use byte strategies with `@Column(as:)`, or fixed-size values for dimension-checked decoding.
The shared codecs serialize scalar bit patterns and packed logical bits without database framing.
Database integration targets supply their own formats and query functions.

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
| `[Bool].PackedBitsRepresentation` | Packed bits without metadata |

Serialization support does not imply support for vector queries in a database.

### Fixed-size vectors

``FixedEmbeddingVector`` stores scalars in an inline array and provides a mutable random-access
collection, hashing, and Codable scalar arrays:

| Type | Scalar | Query representation |
| --- | --- | --- |
| `EmbeddingVector<N>` | `Float` | Direct raw binding or `.VectorBytesRepresentation` |
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
by eight. Fixed-size strategies bind and decode packed bytes directly. Database integrations can
supply formats that record partial-byte lengths.

### Serialize vector bytes

```swift
let values = [Float(1), 2, 3]
let bytes = values.vectorBytes
let restored = try [Float](vectorBytes: bytes)
let fixed = try EmbeddingVector<3>(vectorBytes: bytes)
let validated = try EmbeddingVector<3>(validating: values)
```

`init(vectorBytes:)` validates complete scalar payloads and fixed dimensions.
`init(validating:)` checks a scalar array's count. Invalid bytes and dimensions throw
``VectorDecodingError``. Query binding wraps these bytes in a BLOB; query decoding uses the same
initializer.

### Codecs and encoding identity

``VectorScalar`` describes Float16, Float, and Double through an unsigned integer `BitPattern`,
`bitPattern`, and `init(bitPattern:)`. Generic `encodeVector` and `decodeVector` extension methods
preserve IEEE bits in little-endian order and reject incomplete components. These operations add
no format tags and are not protocol customization points. Adding a scalar conformance does not
add a format to database query helpers.

``VectorBytesRepresentable`` identifies the byte layout through `Encoding`, a canonical
representation independent of dimensions. For example, `EmbeddingVector<3>` and
`[Float].VectorBytesRepresentation` share an encoding. Its `VectorBytesRepresentation` associated
type selects the wrapper for a particular value, including fixed dimensions.

Integration targets can adopt this protocol for database-specific encoded values and strategies
while leaving shared scalar serialization unchanged.

See the [migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).
