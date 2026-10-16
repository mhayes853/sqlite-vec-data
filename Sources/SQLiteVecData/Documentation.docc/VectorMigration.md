# Migrating vector APIs

Update existing SQLiteVec clients for the reusable vector core and stricter SQL format checks.

## Overview

This release changes SQLiteVec APIs and behavior and adds Turso Database support:

| Existing API or behavior | Updated API or behavior |
| --- | --- |
| `.sqliteVecAutoExtension` | Available across platforms; registration is a no-op on Apple. Prepare Apple connections with `Configuration.prepareSQLiteVecExtension()` |
| `AVX` and `NEON` package traits | `SQLiteVecAVX` and `SQLiteVecNEON`, both enabled by default |
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
| `vecEach()` and `Vec.each` always return `SelectOf<VecEach>` with `Float` values | `VecEach` aliases `VecEachOf<Float?>` for Float32 vectors; Int8 and packed bits return `VecEachOf<Int8>` and `VecEachOf<Bool>` |
| Float32 and binary column slices preserve the original vector type | Slices return variable-size representations; use `as:` to select a matching fixed-size result |

### Imports and package products

`SQLiteVecData` and `StructuredQueriesSQLiteVecCore` re-export shared Float32 APIs, including
qualified names. Existing imports need no extra product for `EmbeddingVector` or
`[Float].VectorBytesRepresentation`.

`.PackedBitsRepresentation` remains available through `StructuredQueriesSQLiteVecCore` or
`SQLiteVecData`, with unchanged bytes and dimensions. Core-only and Turso-only imports omit it.
`BinaryEmbeddingVector` and partial-byte `packedBytes` remain in core.

Use `StructuredQueriesVectorCore` for database-independent values; use `StructuredQueriesTursoVecCore`
for Rust-based Turso Database, excluding libSQL DiskANN and `vector_top_k`.

The package requires Swift 6.3. Fixed values require iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.
Variable-size strategies support earlier package platforms.

### Keep existing Float32 values and tables

Keep existing Float32 declarations and bindings:

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

Valid Float32 BLOBs on little-endian platforms and Codable scalar arrays keep their format; no
table or data rewrite is needed. SQLiteVec reads native Float32, so big-endian BLOBs are excluded.
Int8 and packed bits have no multibyte endianness.

Incomplete BLOBs now throw instead of partially decoding; repair affected rows. Fixed strategies
also validate stored component counts.

### Update extensions and representation identities

`EmbeddingVector<N>` and `EmbeddingVector64<N>` alias one generic type. Constrain Float32
extensions explicitly:

```swift
// Before: extension EmbeddingVector { ... }
extension FixedEmbeddingVector where Scalar == Float {
  func squaredNorm() -> Float {
    self.reduce(0) { $0 + $1 * $1 }
  }
}
let squaredNorm = EmbeddingVector<3>([1, 2, 3]).squaredNorm() // 14
```

Constrain Float32 array extensions with `Element == Float`:

```swift
extension Array.VectorBytesRepresentation where Element == Float {
  var squaredNorm: Float {
    self.queryOutput.reduce(0) { $0 + $1 * $1 }
  }
}
let embedding: [Float].VectorBytesRepresentation = [1, 2, 3]
let squaredNorm = embedding.squaredNorm // 14
```

`EmbeddingVector<N>.VectorBytesRepresentation` is a wrapper. Update assumptions of type identity:

```swift
let vector = EmbeddingVector<3>([1, 2, 3])
// Before: let binding: EmbeddingVector<3>.VectorBytesRepresentation = vector
let binding = EmbeddingVector<3>.VectorBytesRepresentation(queryOutput: vector)
```

Float32 remains directly bindable. Float64 and binary use explicit strategies.

### Select Turso floating-point framing explicitly

Shared codecs now store raw little-endian scalars. Float32 rejects trailing tags; Double neither
adds nor consumes Turso's tag.

Use `.TursoFloat64BytesRepresentation` for Double arrays, inline arrays, and `EmbeddingVector64<N>`.
It preserves existing Turso BLOBs without rewriting rows. For tagged Float32 rows, use
`.TursoFloat32BytesRepresentation`; shared Float32 still supports untagged bytes.

```swift
let values = EmbeddingVector64<3>([1, 2, 3])
let binding = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(queryOutput: values)
let candidate: [Double].TursoFloat64BytesRepresentation = [3, 2, 1]
let distance = TursoVec.distanceL2(binding, to: candidate)
// vector_distance_l2(?, ?)
```

Raw and Turso Float64 have distinct `Encoding` identities. Untagged Double bytes would be read as
Float32, so Turso helpers require the tagged strategy.

### Constrain Turso constructor inputs

Turso constructors accept JSON string expressions or vectors with `Encoding: TursoVectorEncoding`;
`extract` requires a vector. Use Turso strategies for Double and binary. Raw Float16 and SQLiteVec
Int8 are unsupported; shared Float32 works directly.

Constrain generic constructor and extraction helpers:

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

The protocol belongs to `StructuredQueriesTursoVecCore`. Existing compatible canonical encodings
need no extra conformance. `@Column(as:)` stays database-independent.

### Update custom vector conformances

`Encoding` identifies the serialized layout; `VectorBytesRepresentation` selects a value wrapper,
including dimensions. Reuse a canonical encoding only when your bytes match.

A custom Float32 binding can reuse shared serialization:

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

The protocol supplies BLOB binding and decoding defaults. Custom fixed types must validate counts;
declaring an encoding promises compatible bytes without converting them.

Both associated representations now conform to `VectorBytesRepresentable` and `QueryBindable`
with matching scalars. The query wrapper preserves `Encoding` and `Dimensions`; inconsistent
metadata fails compilation. Self-representing runtime types declare `Dimensions = Void` to resolve
recursive constraints. Canonical encodings stay independent of fixed counts.

Custom `VectorScalar` conformers supply unsigned fixed-width `BitPattern`, `bitPattern`, and
`init(bitPattern:)`. Generic codec extensions preserve little-endian bits; they are not customization
points. Put database framing in integration strategies. Float16, Float, and Double conform, but
Float16 and new scalar conformances do not imply database query support.

### Validate packed-bit input and carry fixed dimensions

Validate binary inputs with `init(validating:)`. Partial bytes throw `InvalidDimensionsError` with
the rejected `dimensions`. Nonthrowing construction, literals, and mutation precondition alignment:

```swift
let bits = try [Bool].PackedBitsRepresentation(validating: [Bool](repeating: true, count: 16))
let payload = bits.vectorBytes // [0xff, 0xff]; partial bytes throw instead of trapping.
```

`Dimensions` defaults to `Void`; custom fixed types use `VectorDimensions<N>`. Distances, arithmetic,
and `MATCH` reject unequal known counts; the database checks runtime-sized operands. Carry dimensions
in generic helpers:

```swift
func distance<L: VectorBytesRepresentable, R: VectorBytesRepresentable>(
  _ left: some QueryExpression<L>, to right: some QueryExpression<R>
) -> some QueryExpression<Double?>
where L.Encoding == [Float].VectorBytesRepresentation, L.Encoding == R.Encoding,
  L.Dimensions == R.Dimensions
{
  Vec.distanceL2(left, to: right)
}
let expression = distance(EmbeddingVector<3>([1, 0, 0]), to: EmbeddingVector<3>([0, 1, 0]))
// vec_distance_l2(?, ?)
```

Constrain a runtime operand's `Dimensions` to `Void` instead. Length-preserving operations retain
compatible counts, including explicit `as:` results. JSON and variable inputs validate fixed results
when decoding; slices and concat have runtime bounds and result lengths. `Vec.f32` now accepts JSON.

`Vec.bit` and `.bit()` reject Float32. Use `quantizeBinary()` for signs or packed bits for tagging.

Turso constructors retain fixed counts. Forward them explicitly in generic helpers:

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

Use `as:` with a runtime-sized strategy to erase dimensions explicitly.

### Carry encoding constraints in generic SQL helpers

Add the operation's encoding constraint to generic SQLiteVec helpers:

```swift
func float32Length<V: VectorBytesRepresentable>(
  _ vector: some QueryExpression<V>
) -> some QueryExpression<Int> where V.Encoding == [Float].VectorBytesRepresentation {
  Vec.length(vector)
}
let dimensions = float32Length(EmbeddingVector<3>([0.1, 0.2, 0.3]))
// vec_length(?)
```

Float32 and Int8 support numeric distances and arithmetic; only Float32 normalizes. Packed bits
support Hamming. All three support inspection, slices, iteration, and `MATCH`. Comparisons require
matching encodings, preventing mixed numeric formats or binary framing.

Conveniences extend `QueryExpression` for bound values, computed vectors, and BLOB columns.
Slices default to variable-size results:

```swift
let prefix = Embedding.columns.embedding.slice(0..<2)
// vec_slice("Embeddings"."embedding", 0, 2)
let fixedPrefix = Embedding.columns.embedding.slice(0..<2, as: EmbeddingVector<2>.self)
// vec_slice("Embeddings"."embedding", 0, 2)
```

`as:` must match the output encoding and decoded count; select a fixed count equal to slice length.

### Decode lengths and vector elements with their SQL types

`length()` and `Vec.length` now return `QueryExpression<Int>`. Update decoded and compared lengths.

`vec_each` returns REAL for Float32 and integers for Int8/bits. Use `VecEach` (`VecEachOf<Float?>`),
`VecEachOf<Int8>`, or `VecEachOf<Bool>` accordingly. Compare values with matching literals and
update explicit Int8/binary table types.

Distances remain `Double`; Int8 L1 now uses `CAST(... AS REAL)`.

### Decode binary results as bits

Decode binary results with `[Bool].PackedBitsRepresentation` or a fixed binary strategy:

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

`Vec.bit` tags existing bytes; `Vec.quantizeBinary` converts Float32 or Int8 signs. Packed counts
and slice bounds must be byte-aligned.

Inserts require `Vec.bit(binding)`; scalar helpers and `MATCH` tag automatically. Swift indexes bits
least significant first within a byte; `vec_each` uses most significant first.

Turso's binary strategy adds type and dimension metadata and cannot replace SQLiteVec packed bits.

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

`scale:` caused a SQLite error. The replacement emits `vec_quantize_int8(vector, 'unit')`, mapping
[-1, 1] to [-128, 127], clamping, and truncating toward zero with Float32 rounding. It does not
normalize; call `Vec.normalize` if needed. Results are `[Int8].Int8BytesRepresentation`, without
scale, shift, or implicit dequantization.

`Vec.int8` tags signed bytes or parses integer JSON; it does not convert Float32. Replace numeric
`.int8()` calls with `.quantizeInt8()` and consume signed codes. Intentional byte reinterpretation
requires explicit SQL and Int8 decoding.

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

SQL subtypes do not survive storage or binding. Helpers and `MATCH` tag Int8 automatically; inserts
use `Vec.int8` or `Vec.quantizeInt8`. Existing Int8 bytes keep their layout.

Fixed Int8 uses `FixedEmbeddingVector<N, Int8>.Int8BytesRepresentation` for `@Column(as:)` and
`as:` results. Int8 is not a `VectorScalar`. Its signed codes differ from Turso affine UInt8; migrate
through Float32 values or integer JSON, not raw signed bytes.

### Use encoding capabilities in generic helpers

Replace concrete encoding constraints with engine capabilities. SQLiteVec provides numeric,
Float32, Int8, and binary branches; Turso adds Float64, quantized, and sparse. Scalar, encoding,
and dimension relationships remain enforced:

```swift
func numericDistance<L: VectorBytesRepresentable, R: VectorBytesRepresentable>(
  _ left: some QueryExpression<L>, to right: some QueryExpression<R>
) -> some QueryExpression<Double?>
where L.Encoding: SQLiteVecNumericEncoding, L.Encoding == R.Encoding,
  L.Dimensions == R.Dimensions {
  Vec.distanceL2(left, to: right)
}
let left: [Int8].Int8BytesRepresentation = [3, 4, 0]
let right: [Int8].Int8BytesRepresentation = [0, 0, 0]
let distance = numericDistance(left, to: right)
// vec_distance_l2(vec_int8(?), vec_int8(?))
```

Leaf protocols promise exact layouts. SQLiteVec leaves inherit subtype hooks; direct base
conformances supply `sqliteVecExpression`. `TursoVectorEncoding` now inherits
`VectorBytesRepresentable`; built-ins need no changes. Raw IEEE codec adapters retain input checks.

### Account for equality and decoding behavior

Float32 equality and hashing now follow scalar semantics: signed zeros compare equal; NaNs compare
unequal, even to themselves. Compare `vectorBytes` for bit identity; persist values, not Swift hashes.

`VectorDecodingError` is nonexhaustive; include `@unknown default` in switches.

Decoding throws `VectorDecodingError.invalidBytes` for lengths or metadata and
`dimensionMismatch(expected:actual:)` for fixed counts. Handle these alongside corrupt database data.

### Handle nullable results and inputs

Float32 distances, all cosine/Jaccard distances, and Turso floating L2/dot return `Double?`.
SQLiteVec Int8 L1/L2, Turso quantized8 L2/dot, and binary dot/Hamming retain `Double`.
`vec0.distance` is nullable outside KNN or for undefined scores; `k` returns NULL when selected.
Float32 iteration is now `VecEachOf<Float?>`; preserve nil positions instead of dropping components.

Use `whenPresent` to call scalar helpers with nullable vectors or JSON. It guards missing inputs
with CASE and preserves already-nullable results. Pass a second nullable operand as
`left.whenPresent(right) { left, right in ... }`. Existing nonoptional calls retain their SQL.
Filter scores with `.isNot(nil)` or choose an `.ifnull(...)` fallback; ascending SQL puts NULL first.

For nullable columns, wrap the strategy in Optional:

```swift
@Table("optional_documents")
struct OptionalDocument {
  @Column(as: [Float].VectorBytesRepresentation?.self)
  var embedding: [Float]?
}
let lengths = OptionalDocument.select { $0.embedding.whenPresent { Vec.length($0) } }
// SELECT CASE WHEN ("optional_documents"."embedding") IS NULL THEN NULL ELSE vec_length("optional_documents"."embedding") END
// FROM "optional_documents"
```

`VectorBytesRepresentable` stays nonoptional. Optional strategies decode SQL NULL as nil; corrupt
BLOBs still throw. NaN inside a valid vector remains a component, not a missing vector. Raw BLOB
round trips preserve its bits; SQL scalar extraction can expose it as NULL.
