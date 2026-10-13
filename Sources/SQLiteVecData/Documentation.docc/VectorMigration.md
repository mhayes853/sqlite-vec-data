# Migrating vector APIs

Update existing SQLiteVec clients for the reusable vector core and stricter SQL format checks.

## Overview

This release contains source and behavior changes to the existing SQLiteVec bindings, alongside
the new Turso Database target. The table below identifies the changes to check in existing code.

| Existing API or behavior | Updated API or behavior |
| --- | --- |
| `.sqliteVecAutoExtension` is a no-op on Apple platforms | Unavailable on Apple; use `Configuration.prepareSQLiteVecExtension()` from `SQLiteVecData` on any platform |
| `AVX` and `NEON` package traits | `SQLiteVecAVX` (opt-in) and `SQLiteVecNEON` (default) |
| sqlite-vec only uses the API table passed to its entry point | The default `SQLiteVecStaticAPI` trait calls the linked SQLite's functions directly; disable it for SQLite builds that do not export them |
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
| `length()` and `Vec.length` return `Double` | They return `Int`, matching the integer SQLiteVec's `vec_length` produces |
| `vecEach()` and `Vec.each` always return `SelectOf<VecEach>` with `Float` values | `VecEach` aliases `VecEachOf<Float>` for Float32 vectors; Int8 and packed bits return `VecEachOf<Int8>` and `VecEachOf<Bool>` |
| Float32 and binary column slices preserve the original vector type | Slices return variable-size representations; use `as:` to select a matching fixed-size result |

### Imports and package products

Existing `SQLiteVecData` and `StructuredQueriesSQLiteVecCore` imports continue to expose the shared
Float32 APIs. You do not need to add another product solely to keep using `EmbeddingVector` or
`[Float].VectorBytesRepresentation`. Existing qualified names such as
`StructuredQueriesSQLiteVecCore.EmbeddingVector` remain available through the re-export.

`.PackedBitsRepresentation` on `[Bool]` and `BinaryEmbeddingVector<N>` is supplied by
`StructuredQueriesSQLiteVecCore`. Import that module or `SQLiteVecData` to use the strategy.
Its public spelling, byte format, and dimension checks are unchanged; stored blobs need no rewrite. Core-only and Turso-only imports do not expose it. `BinaryEmbeddingVector` and
`packedBytes` remain in the shared core, including support for partial bytes.

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
// SELECT "Embeddings"."embedding"
// FROM "Embeddings"
// WHERE (("Embeddings"."embedding" MATCH ?))
// LIMIT ?
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
let squaredNorm = EmbeddingVector<3>([1, 2, 3]).squaredNorm() // 14
```

Likewise, Float32-specific extensions on the array representation should constrain `Element`:

```swift
extension Array.VectorBytesRepresentation where Element == Float {
  var squaredNorm: Float {
    self.queryOutput.reduce(0) { $0 + $1 * $1 }
  }
}
let embedding: [Float].VectorBytesRepresentation = [1, 2, 3]
let squaredNorm = embedding.squaredNorm // 14
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

### Select Turso floating-point framing explicitly

`VectorScalar` and the shared `.VectorBytesRepresentation` strategies now use raw little-endian
payloads for every precision. Float32 decoding rejects incomplete components, including a trailing
type byte; Double no longer appends or consumes Turso's type byte.

Use `.TursoFloat64BytesRepresentation` on `[Double]`, `InlineArray<N, Double>`, and
`EmbeddingVector64<N>` for Turso Float64 columns, bindings, and typed query results. This strategy
retains the existing Turso blob layout. Existing rows need no rewrite when the strategy is updated.
Use `.TursoFloat32BytesRepresentation` when Float32 rows include the optional type byte. Shared
Float32 binding and decoding of untagged Float32 remain supported.

```swift
let values = EmbeddingVector64<3>([1, 2, 3])
let binding = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(queryOutput: values)
let candidate: [Double].TursoFloat64BytesRepresentation = [3, 2, 1]
let distance = TursoVec.distanceL2(binding, to: candidate)
// vector_distance_l2(?, ?)
```

Raw and Turso Float64 have separate `Encoding` identities. Passing an untagged Float64 payload to
Turso would identify it as Float32, so Float64 query helpers require the explicit Turso strategy.

### Constrain Turso constructor inputs

Turso constructors accept `QueryExpression<String>` for JSON or vector expressions whose
`Encoding` conforms to `TursoVectorEncoding`. `extract` accepts only the latter. Replace raw
Double or packed-bit inputs with their Turso strategies; raw Float16 and SQLiteVec Int8 blobs
are unsupported. Shared Float32 inputs continue to work directly.

Generic helpers that forward vectors to constructors or extraction need the encoding constraint:

```swift
func vectorJSON<V: VectorBytesRepresentable & QueryBindable>(
  _ vector: some QueryExpression<V>
) -> some QueryExpression<String> where V.Encoding: TursoVectorEncoding {
  TursoVec.extract(vector)
}
let embedding: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
let json = vectorJSON(embedding)
// vector_extract(?)
```

The protocol lives in `StructuredQueriesTursoVecCore`. A custom representation using an existing
compatible canonical encoding needs no additional conformance. Ordinary `@Column(as:)` declarations
remain database-independent; these constraints apply to the Turso helpers.

### Update custom vector conformances

`Encoding` identifies the byte layout independently of dimensions. Use the existing canonical
representation for the layout you actually serialize. `VectorBytesRepresentation` identifies the
wrapper for your specific value, including any fixed dimensions.

Here is a directly query-bindable custom Float32 representation using the shared serialization:

```swift
struct CustomVector: Hashable, Sendable, QueryBindable, VectorBytesRepresentable {
  typealias Scalar = Float
  typealias Dimensions = Void
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
let embedding = CustomVector(queryOutput: [0.1, 0.2, 0.3])
let queryVector: [Float].VectorBytesRepresentation = [0.2, 0.4, 0.6]
let distance = Vec.distanceL2(embedding, to: queryVector)
// vec_distance_l2(?, ?)
```

The protocol supplies BLOB binding and query decoding defaults for query-bindable conformers.
A fixed-size custom type must validate its own dimension count during byte decoding. Declaring a
Float32 `Encoding` promises Float32-compatible bytes; it does not convert another layout.

`Encoding` and `VectorBytesRepresentation` must now conform to `VectorBytesRepresentable` and
`QueryBindable`, with matching `Scalar` types. The query representation must also preserve the
value's `Encoding` and `Dimensions`. Custom conformances with inconsistent metadata no longer
compile. Self-representing runtime-sized types declare `Dimensions = Void` explicitly to resolve
the recursive constraint. Canonical encodings remain independent of fixed dimensions.

Custom `VectorScalar` conformers additionally supply an unsigned fixed-width integer `BitPattern`,
`bitPattern`, and `init(bitPattern:)`. The generic codec preserves those bits in little-endian order.
`encodeVector(_:)` and `decodeVector(_:)` are extension operations, not protocol requirements.
Put database framing in a representation supplied by the database integration target. Float16, Float, and
Double already conform. Float16 uses raw binary16 serialization and is not a database vector format. Adding a scalar conformance does not make a new precision supported by
SQLiteVec or Turso's query helpers.

### Validate packed-bit input and carry fixed dimensions

Use the throwing `init(validating:)` on array or fixed `.PackedBitsRepresentation` strategies
for user-provided binary data. Partial bytes throw `InvalidDimensionsError`, whose `dimensions`
property records the count. The required nonthrowing initializer and array literals now check
alignment at construction; mutating an array strategy's `queryOutput` checks it immediately too.

```swift
let bits = try [Bool].PackedBitsRepresentation(validating: [Bool](repeating: true, count: 16))
let payload = bits.vectorBytes // [0xff, 0xff]; partial bytes throw instead of trapping.
```

`VectorBytesRepresentable.Dimensions` defaults to `Void`, preserving runtime-sized custom types.
For a custom fixed representation, declare `typealias Dimensions = VectorDimensions<N>` with its
logical component count. Distances, arithmetic, and `MATCH` reject unequal known dimensions;
fixed/variable combinations continue to use database validation. Generic forwarding helpers must
carry the corresponding dimension constraint:

```swift
func distance<L: VectorBytesRepresentable, R: VectorBytesRepresentable>(
  _ left: some QueryExpression<L>, to right: some QueryExpression<R>
) -> some QueryExpression<Double>
where L.Encoding == [Float].VectorBytesRepresentation, L.Encoding == R.Encoding,
  L.Dimensions == R.Dimensions
{
  Vec.distanceL2(left, to: right)
}
let expression = distance(EmbeddingVector<3>([1, 0, 0]), to: EmbeddingVector<3>([0, 1, 0]))
// vec_distance_l2(?, ?)
```

A helper accepting a runtime-sized left or right operand can constrain that operand's `Dimensions`
to `Void` instead. SQLiteVec normalization and arithmetic now return the dimension-preserving
representation, so fixed results decode to their fixed logical value. Length-preserving constructors,
quantization, and explicit `as:` results also retain compatible known counts. JSON and runtime-sized
sources validate fixed results during decoding; slice bounds and concatenated result counts remain
runtime checks. `Vec.f32` also accepts JSON string expressions, matching the
Int8 constructor's typed-result API.

`Vec.bit` and `.bit()` no longer accept Float32 inputs. Use `quantizeBinary()` for sign quantization,
or supply a packed-bit representation to tag binary storage.

Turso constructors infer `VectorDimensions<N>` and return fixed-size results for fixed inputs.
Generic forwarding helpers can carry that count explicitly:

```swift
func precise<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
  _ embedding: some QueryExpression<V>
) -> some QueryExpression<EmbeddingVector64<count>.TursoFloat64BytesRepresentation>
where V.Encoding: TursoVectorEncoding, V.Dimensions == VectorDimensions<count> {
  TursoVec.vector64(embedding)
}
let converted = precise(EmbeddingVector<3>([0.1, 0.2, 0.3]))
// vector64(?)
```

For an intentionally runtime-sized result in a helper with an abstract `Dimensions` type, use an
explicit `as:` array-backed or runtime-sized representation. This makes dimension erasure visible.

### Carry encoding constraints in generic SQL helpers

Previously, a generic helper could forward any `VectorBytesRepresentable` to a SQLiteVec
function. Add the operation's supported encoding constraint:

```swift
func float32Length<V: VectorBytesRepresentable>(
  _ vector: some QueryExpression<V>
) -> some QueryExpression<Int> where V.Encoding == [Float].VectorBytesRepresentation {
  Vec.length(vector)
}
let dimensions = float32Length(EmbeddingVector<3>([0.1, 0.2, 0.3]))
// vec_length(?)
```

Float32 and signed Int8 support L1, L2, cosine distance, addition, and subtraction. Normalization
requires Float32. Hamming requires raw packed bits. Inspection, slicing, iteration, and `MATCH`
support Float32, signed Int8, and packed bits. Comparisons require matching encodings; numeric
operations cannot silently mix Float32 and Int8, or raw binary and Turso binary framing.

Scalar convenience methods extend `QueryExpression`, including computed vectors and ordinary BLOB
columns. Distances and arithmetic accept bound or computed operands with matching encodings.
Column slices return variable-size representations by default:

```swift
let prefix = Embedding.columns.embedding.slice(0..<2)
// vec_slice("Embeddings"."embedding", 0, 2)
let fixedPrefix = Embedding.columns.embedding.slice(0..<2, as: EmbeddingVector<2>.self)
// vec_slice("Embeddings"."embedding", 0, 2)
```

The result selected by `as:` must match the operation's output encoding. Its dimension constraint
is checked when decoding, so select a fixed result whose count matches a slice's length.

### Decode lengths and vector elements with their SQL types

`vec_length` returns an integer, so `length()` and `Vec.length` now return `some QueryExpression<Int>`.
Replace `Double` with `Int` where you decode or compare a length.

`vec_each` reports Float32 elements as `REAL` values, and Int8 and packed-bit elements as integers.
Element tables are now generic over their value type: Float32 vectors keep `VecEach`, an alias of
`VecEachOf<Float>`, while Int8 vectors return `VecEachOf<Int8>` and packed bits return
`VecEachOf<Bool>`. Compare an Int8 element's `value` with `Int8` literals and a bit's `value` with
`true` or `false`, rather than with `Float` values. Code that names `VecEach` for an Int8 or binary
vector must use the matching `VecEachOf` type.

Distance helpers continue to return `Double`. SQLiteVec computes Int8 L1 distances as integers, so
that helper now wraps its SQL in `CAST(... AS REAL)`.

### Decode binary results as bits

Use `[Bool].PackedBitsRepresentation` for variable-size SQLiteVec binary results, or
`BinaryEmbeddingVector<N>.PackedBitsRepresentation` for a fixed logical dimension count:

```swift
let floats: [Float].VectorBytesRepresentation = [1, -1, 1, 0, -1, 1, 0, -1]
let bits = Vec.quantizeBinary(floats)
// vec_quantize_binary(?)
let fixedBits = Vec.quantizeBinary(
  floats,
  as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
)
// vec_quantize_binary(?)
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
// vec_quantize_int8("Embeddings"."embedding", 'unit')
// Before: Embedding.select { $0.embedding.quantizeInt8(scale: 1.0) }
let query = Embedding.select { $0.embedding.quantizeInt8() }
// SELECT vec_quantize_int8("Embeddings"."embedding", 'unit')
// FROM "Embeddings"
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
// INSERT INTO "Int8Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)
let neighbors = Int8Embedding
  .where { $0.embedding.match(codes) }
  .limit(5)
// SELECT "Int8Embeddings"."embedding", "Int8Embeddings"."label"
// FROM "Int8Embeddings"
// WHERE (("Int8Embeddings"."embedding" MATCH vec_int8(?)))
// LIMIT ?
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
