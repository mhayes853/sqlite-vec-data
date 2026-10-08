# Migrating vector APIs

Update existing SQLiteVec clients for the reusable vector core and stricter SQL format checks.

## Overview

This release contains source and behavior changes to the existing SQLiteVec bindings, alongside
the new Turso Database target. The table below identifies the changes to check in existing code.

| Existing API or behavior | Updated API or behavior |
| --- | --- |
| Vector types defined in `StructuredQueriesSQLiteVecCore` | Shared types defined in `StructuredQueriesVectorCore`, re-exported by the SQLiteVec target |
| Nominal `EmbeddingVector<N>` struct | `EmbeddingVector<N>` aliases `FixedEmbeddingVector<N, Float>` |
| `EmbeddingVector<N>.VectorBytesRepresentation` aliases the vector itself | A wrapper whose `queryOutput` is the vector; direct Float32 binding still works |
| Custom `VectorBytesRepresentable` with only a representation type | Also declares `Scalar`, `Encoding`, byte serialization, and byte decoding |
| Client extensions on Float32-only vector types | Add a `Scalar == Float` or `Element == Float` constraint when the extension depends on Float32 |
| Float32 embedding equality compares raw memory | Element-wise equality: signed zeros compare equal and NaNs compare unequal |
| Decoding ignores incomplete floating-point elements | Malformed byte lengths, tags, and fixed dimensions throw |
| SQLiteVec functions accept arbitrary vector representations | Input and output `Encoding` constraints enforce the supported formats |
| Binary functions return Float32 representations | Binary functions return packed-bit representations |
| `quantizeInt8(scale:)` passes an unsupported numeric argument | `quantizeInt8()` emits SQLiteVec's supported `'unit'` argument and returns signed Int8 codes |
| `int8()` exposes Int8 bytes as Float32 values | `Vec.int8` accepts signed-byte expressions or integer JSON and returns an Int8 representation |

### Imports and package products

Existing `SQLiteVecData` and `StructuredQueriesSQLiteVecCore` imports continue to expose the shared
Float32 APIs. You do not need to add another product solely to keep using `EmbeddingVector` or
`[Float].VectorBytesRepresentation`. Existing qualified names such as
`StructuredQueriesSQLiteVecCore.EmbeddingVector` remain available through the re-export.

Add `StructuredQueriesVectorCore` when using shared vector values without either database binding.
Add `StructuredQueriesTursoVecCore` for the Rust-based Turso Database engine. Its APIs do not target
libSQL's DiskANN or `vector_top_k` functionality.

Fixed-size vectors continue to require Swift 6.2 and the documented platform availability
(iOS 26, macOS 26, tvOS 26, watchOS 26, and visionOS 26). Variable-size representations work on the
package's earlier supported platforms.

### Keep existing Float32 values and tables

Ordinary Float32 declarations and bindings can stay as they are:

```swift
@Table("Embeddings")
struct Embedding: Vec0 {
  var embedding: EmbeddingVector<3>
}

let vector = EmbeddingVector<3>([0.1, 0.2, 0.3])
let query = Embedding
  .where { $0.embedding.match(vector) }
  .limit(5)
```

On supported little-endian platforms, valid existing Float32 blobs and Codable scalar arrays retain
the same format. There is no required table recreation or data rewrite for those values. SQLiteVec
reads native Float32 bytes, so this compatibility does not extend to blobs created on big-endian
systems. Int8 and packed-bit payloads have no multibyte scalar endianness.

Malformed blobs that were previously partially decoded now throw. Repair those rows rather than
padding or truncating them implicitly. Fixed-size representations additionally validate that the
stored number of components matches the Swift dimension count.

### Update extensions and representation identities

`EmbeddingVector<N>` and `EmbeddingVector64<N>` are precision aliases of one generic value type.
For an extension that uses Float32 operations, constrain the underlying type explicitly:

```swift
// Before: extension EmbeddingVector { ... }
extension FixedEmbeddingVector where Scalar == Float {
  func squaredNorm() -> Float {
    self.reduce(0) { $0 + $1 * $1 }
  }
}
```

Likewise, Float32-specific extensions on the array representation should constrain `Element`:

```swift
extension Array.VectorBytesRepresentation where Element == Float {
  var squaredNorm: Float {
    self.queryOutput.reduce(0) { $0 + $1 * $1 }
  }
}
```

`EmbeddingVector<N>.VectorBytesRepresentation` is now a distinct wrapper. Update code that relied
on it being the same type as the vector:

```swift
let vector = EmbeddingVector<3>([1, 2, 3])
// Before: let binding: EmbeddingVector<3>.VectorBytesRepresentation = vector
let binding = EmbeddingVector<3>.VectorBytesRepresentation(queryOutput: vector)
```

Float32 vectors remain directly query-bindable, so wrapping is optional when a function accepts
`EmbeddingVector` itself. Float64 and binary values use their explicit column and binding strategies.

### Update custom vector conformances

`Encoding` identifies the byte layout independently of dimensions. Use the existing canonical
representation for the layout you actually serialize. `VectorBytesRepresentation` identifies the
wrapper for your specific value, including any fixed dimensions.

Here is a directly query-bindable custom Float32 representation using the shared serialization:

```swift
struct CustomVector: Hashable, Sendable, QueryBindable, VectorBytesRepresentable {
  typealias Scalar = Float
  typealias Encoding = [Float].VectorBytesRepresentation
  typealias VectorBytesRepresentation = Self

  var queryOutput: [Float]

  init(queryOutput: [Float]) {
    self.queryOutput = queryOutput
  }

  var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

  init(vectorBytes: [UInt8]) throws {
    try self.init(queryOutput: [Float](vectorBytes: vectorBytes))
  }
}
```

The protocol supplies BLOB binding and query decoding defaults for query-bindable conformers.
A fixed-size custom type must validate its own dimension count during byte decoding. Declaring a
Float32 `Encoding` promises Float32-compatible bytes; it does not convert another layout.

Custom `VectorScalar` conformers additionally supply an unsigned fixed-width integer `BitPattern`,
`bitPattern`, and `init(bitPattern:)`. The default codec preserves those bits in little-endian order.
Keep or override `encodeVector(_:)` and `decodeVector(_:)` if your format needs framing. Float and
Double already conform. Adding a scalar conformance does not make a new precision supported by
SQLiteVec or Turso's query helpers.

### Carry encoding constraints in generic SQL helpers

Previously, a generic helper could forward any `VectorBytesRepresentable` to a SQLiteVec
function. Add the operation's supported encoding constraint:

```swift
func float32Length<V: VectorBytesRepresentable>(
  _ vector: some QueryExpression<V>
) -> some QueryExpression<Double> where V.Encoding == [Float].VectorBytesRepresentation {
  Vec.length(vector)
}
```

Float32 and signed Int8 support L1, L2, cosine distance, addition, and subtraction. Normalization
requires Float32. Hamming requires raw packed bits. Inspection, slicing, iteration, and `MATCH`
support Float32, signed Int8, and packed bits. Comparisons require matching encodings; numeric
operations cannot silently mix Float32 and Int8, or raw binary and Turso binary framing.

The result selected by `as:` must match the operation's output encoding. Its dimension constraint
is checked when decoding, so select a fixed result whose count matches a slice's length.

### Decode binary results as bits

Use `[Bool].PackedBitsRepresentation` for variable-size SQLiteVec binary results, or
`BinaryEmbeddingVector<N>.PackedBitsRepresentation` for a fixed logical dimension count:

```swift
let floats: [Float].VectorBytesRepresentation = [1, -1, 1, 0, -1, 1, 0, -1]
let bits = Vec.quantizeBinary(floats)
let fixedBits = Vec.quantizeBinary(
  floats,
  as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
)
```

`Vec.bit` reinterprets existing blob bytes as bits; it does not quantize numerical components.
Use `Vec.quantizeBinary` to quantize Float32 or signed Int8 components by sign. SQLiteVec packed-bit
bindings require dimensions divisible by eight, and binary slice boundaries must be byte-aligned.

When inserting packed bits, use `Vec.bit(binding)` so the expression has SQLiteVec's binary subtype.
Binary scalar helpers and `MATCH` attach this subtype for you. The packed value indexes bits least
significant first within each byte; SQLiteVec's `vec_each` reports bits most significant first.

Turso's `.TursoBytesRepresentation` includes type and dimension metadata and cannot replace
SQLiteVec's raw packed-bit representation.

### Replace the Int8 quantization and conversion APIs

Replace both namespace and column calls that passed `scale:`:

```swift
// Before: Vec.quantizeInt8(Embedding.columns.embedding, scale: 1.0)
let codes = Vec.quantizeInt8(Embedding.columns.embedding)
// Before: Embedding.select { $0.embedding.quantizeInt8(scale: 1.0) }
let query = Embedding.select { $0.embedding.quantizeInt8() }
```

The old numeric argument caused a SQLite error. The new SQL is
`vec_quantize_int8(vector, 'unit')`. It maps components in [-1, 1] to signed codes in [-128, 127],
clamps out-of-range inputs, and truncates toward zero with SQLiteVec's Float32 rounding. It does not
normalize vectors; use `Vec.normalize` explicitly if your input requires unit-length normalization.
The result is `[Int8].Int8BytesRepresentation`, whose query output is `[Int8]`, rather than `[Float]`.
There is no per-vector scale or shift metadata and no implicit dequantization.

`Vec.int8` tags existing signed bytes or parses an integer JSON array. It is not a numeric Float32
conversion. Replace a Float32 column's `.int8()` call with `.quantizeInt8()` if quantization was the
intent; update callers to consume signed codes. Raw byte reinterpretation, if intentionally needed,
can be expressed explicitly in SQL and decoded with the Int8 strategy.

Store signed codes with a strategy from `StructuredQueriesSQLiteVecCore`:

```swift
@Table("Int8Embeddings")
struct Int8Embedding: Vec0 {
  @Column(as: [Int8].Int8BytesRepresentation.self)
  var embedding: [Int8]
  var label: String
}

// CREATE VIRTUAL TABLE Int8Embeddings USING vec0(embedding int8[3], label text);
let codes: [Int8].Int8BytesRepresentation = [-128, 0, 127]
let insert = Int8Embedding.insert { ($0.embedding, $0.label) } values: {
  (Vec.int8(codes), "example")
}
let neighbors = Int8Embedding
  .where { $0.embedding.match(codes) }
  .limit(5)
```

Int8 scalar helpers and `MATCH` attach `vec_int8` automatically because SQL subtypes do not survive
storage or binding. Inserts should use `Vec.int8(binding)` or `Vec.quantizeInt8(floatExpression)`.
Existing valid Int8 payloads retain their one-byte-per-component layout.

For fixed dimensions, use `FixedEmbeddingVector<N, Int8>.Int8BytesRepresentation` with
`@Column(as:)` and the Int8-producing functions' `as:` overloads. This reuses the shared fixed-size
value; Int8 does not conform to the floating-point `VectorScalar` protocol. SQLiteVec signed Int8
codes are not interchangeable with Turso's affine UInt8 `Quantized8Vector`. When moving signed codes
to Turso, first create numeric Float32 components or integer JSON and use the corresponding
`TursoVec` constructor; its blob conversions cannot identify SQLiteVec's raw signed-byte layout.

### Account for equality and decoding behavior

Float32 embedding equality now follows Swift scalar equality. Positive and negative zero compare
equal, and a vector containing a NaN does not compare equal to itself. Hashing follows the same
scalar semantics. If your application needs bit-identical comparisons, compare `vectorBytes`
explicitly. Persist actual vector values rather than Swift hash values.

Byte decoding throws `VectorDecodingError.invalidBytes` for invalid lengths or format metadata,
and `dimensionMismatch(expected:actual:)` for the wrong fixed count. Handle these errors at the
same boundary where you handle other corrupt database values.
