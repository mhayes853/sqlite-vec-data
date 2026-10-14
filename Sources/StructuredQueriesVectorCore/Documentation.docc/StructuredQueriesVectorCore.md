# ``StructuredQueriesVectorCore``

Shared vector values, byte representations, and codecs for StructuredQueries.

## Overview

Use byte strategies with `@Column(as:)`, or fixed-size values for dimension-checked decoding.
The shared codecs serialize scalar bit patterns; binary values expose raw packed storage.
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

Serialization support does not imply support for vector queries in a database.

### Fixed-size vectors

``FixedEmbeddingVector`` stores scalars in an inline array and provides a mutable random-access
collection, hashing, and Codable scalar arrays:

| Type | Scalar | Query representation |
| --- | --- | --- |
| `EmbeddingVector<N>` | `Float` | Direct raw binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` | `Double` | `.VectorBytesRepresentation` |
| `FixedEmbeddingVector<N, Int8>` | `Int8` | Strategy supplied by a database integration |
| `BinaryEmbeddingVector<N>` | `Bool` | Explicit binary strategy |

Fixed-size types require Swift 6.2 and iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.
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

``BinaryEmbeddingVector`` exposes mutable Bool elements while storing `ceil(N / 8)` bytes;
1,536 dimensions use 192 bytes. Codable uses a Bool array. `packedBytes` has no database metadata,
and `init(packedBytes:)` checks the byte count and clears unused high bits.

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

Sign quantization tests `value > 0`: zeros, negatives, and NaNs become false. It discards magnitudes.
Local Hamming distance counts differing bits and returns `Int`.

Bit zero occupies the least significant bit of the first byte. Logical dimensions need not be
divisible by eight; the value tracks the count and clears unused trailing bits. Raw `packedBytes`
are storage payloads. Database integration targets supply binary binding and decoding strategies.

### Serialize vector bytes

```swift
// A Float32 payload retrieved from a vector cache.
let bytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
let values = try [Float](vectorBytes: bytes) // [1, 0, 0]
let fixed = try EmbeddingVector<3>(vectorBytes: bytes)
let validated = try EmbeddingVector<3>(validating: values)
// A payload or array with a different component count throws.
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

Both associated representations must conform to `VectorBytesRepresentable` and `QueryBindable`.
Their scalars must match the value's scalar, and the query representation must preserve its
`Encoding` and `Dimensions`. The `Document` column strategy above wraps logical values as BLOBs
when inserting:

```swift
let embedding: [Float] = [0.1, 0.2, 0.3]
let insert = Document.insert { ($0.id, $0.embedding) } values: {
  (1, embedding)
}
// INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
```

The `Dimensions` associated type defaults to `Void` for runtime-sized values. Fixed representations
use ``VectorDimensions`` with the same count across scalar types and strategies. Query integrations
use that identity to reject unequal known dimensions while allowing variable-size operands.
Self-representing runtime-sized conformers declare `typealias Dimensions = Void` explicitly;
Swift cannot infer the default through the recursive representation constraint. The canonical
encoding's dimensions remain independent of the value's count.

```swift
func dotProduct<L: Collection & VectorBytesRepresentable, R: Collection & VectorBytesRepresentable>(
  _ left: L, _ right: R
) -> Float where L.Element == Float, R.Element == Float, L.Dimensions == R.Dimensions {
  precondition(left.count == right.count)
  return zip(left, right).reduce(0) { $0 + $1.0 * $1.1 }
}
let score = dotProduct(EmbeddingVector<3>([1, 0, 0]), EmbeddingVector<3>([0.5, 1, 0])) // 0.5
```

Integration targets can adopt this protocol for database-specific encoded values and strategies
while leaving shared scalar serialization unchanged.

``BinaryVectorEncoding`` refines serialized vectors with `Scalar == Bool` without choosing a byte
layout. Integration protocols add exact format and query capabilities; sharing the binary parent
does not make differently framed payloads interchangeable.

See the [migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).
