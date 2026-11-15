# SQLiteVecData

[![CI](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml/badge.svg)](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)

Vector search in Swift with [SQLiteData](https://github.com/pointfreeco/sqlite-data),
[sqlite-vec](https://github.com/asg017/sqlite-vec), and
[Turso Database](https://docs.turso.tech/sql-reference/functions/vector).

SQL comments show generated queries; placeholders represent bound values.

## Installation

Requires Swift 6.3. Array-based APIs support iOS 16, macOS 13, tvOS 16, and watchOS 9 or later,
and Linux. Fixed-size vector types require iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.

```swift
dependencies: [
  .package(url: "https://github.com/mhayes853/sqlite-vec-data", from: "1.0.0")
]
```

Upgrading from 0.x? See the
[migration guide](Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).

Choose the product for your database:

```swift
// sqlite-vec with SQLiteData:
.product(name: "SQLiteVecData", package: "sqlite-vec-data")

// Turso Database query helpers:
.product(name: "StructuredQueriesTursoVecCore", package: "sqlite-vec-data")
```

Standalone query helpers also need `StructuredQueriesSQLite` from
[swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) for `@Table`,
`@Column`, and `#sql`.

SwiftPM patches and compiles the bundled sqlite-vec source with a build tool plugin when building
its integration targets. The plugin runs `/bin/sh`, `git`, and `sha256sum` or `shasum`, which
standard macOS and Linux development environments provide. Xcode asks you to trust the plugin the
first time you build.

## sqlite-vec

### Create, insert, and search

This example uses an in-memory database. Prepare each connection, including database pool readers,
with `prepareSQLiteVecExtension()` on any supported platform:

```swift
import SQLiteVecData

@Table("Embeddings")
struct Embedding: Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
  var label: String
}

var configuration = Configuration()
configuration.prepareSQLiteVecExtension()
let database = try DatabaseQueue(configuration: configuration)

try database.write { db in
  try #sql(
    "CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text)",
    as: Void.self
  ).execute(db)
  try Embedding.insert { ($0.embedding, $0.label) } values: {
    ([Float].VectorBytesRepresentation(queryOutput: [0.1, 0.2, 0.3]), "First document")
  }.execute(db)
}

let vector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
let query = Embedding
  .where { $0.embedding.match(vector) }
  .order { $0.distance }
  .limit(5)
  .select { ($0.label, $0.distance) }
// SELECT "Embeddings"."label", "Embeddings"."distance"
// FROM "Embeddings"
// WHERE (("Embeddings"."embedding" MATCH ?))
// ORDER BY "Embeddings"."distance"
// LIMIT ?

let neighbors = try database.read { db in
  try query.fetchAll(db)
}
// [("First document", Optional(0.0))]
```

For a persistent database, create the schema in a migration. The same configuration works with
`SQLiteData.defaultDatabase(configuration:)`. `match` and `Vec.match` accept bound or computed
vectors with matching encodings.

### Alternative process-wide setup

Per-connection preparation above is recommended on every platform. On non-Apple platforms,
process-wide registration is an alternative; choose one setup method:

```swift
import SQLiteVecData

try registerSQLiteVecAutoExtension()
let database = try SQLiteData.defaultDatabase()
```

### Vector functions

```swift
let distances = Embedding.select {
  ($0.label, $0.embedding.distanceCosine(to: vector.normalize()))
}
// SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", vec_normalize(?))
// FROM "Embeddings"

let normalized = Vec.normalize(vector)
// vec_normalize(?)
let prefix = Embedding.columns.embedding.slice(0..<2) // Decodes as [Float]
// vec_slice("Embeddings"."embedding", 0, 2)
let fixedPrefix = Embedding.columns.embedding.slice(0..<2, as: EmbeddingVector<2>.self)
// vec_slice("Embeddings"."embedding", 0, 2)
let elements = Vec.each(vector)
  .order { $0.rowid }
  .select { ($0.rowid, $0.value) }
// SELECT "vec_each"."rowid", "vec_each"."value"
// FROM "vec_each"
// WHERE ("vec_each"."vector" = ?)
// ORDER BY "vec_each"."rowid"
```

Helpers support bound values, computed expressions, and BLOB columns. Use arithmetic, slices,
inspection, and `.vecEach()` in joins or subqueries. Float32 and Int8 support L1, L2, and cosine;
Float32 supports normalization; binary vectors support Hamming distance.

Float32 distances and cosine return `Double?`; Int8 L1/L2 and Hamming return `Double`.
`length()` returns `Int`.
Iteration returns `VecEachOf<Float?>` (also called `VecEach`), `VecEachOf<Int8>`, or `VecEachOf<Bool>`.
For binary vectors, `Vec.each` visits bits most significant first within each byte; Swift vector
indices and `Vec.toJSON` use least significant first. Iteration row IDs therefore differ from
Swift bit indices.

Construct Float32 from JSON; `as:` selects a fixed-size result:

```swift
let fixed = Vec.f32("[1, 2, 3]", as: EmbeddingVector<3>.self)
// vec_f32(?)
let normalized = Vec.normalize(fixed)
// vec_normalize(vec_f32(?))
```

Length-preserving operations retain fixed counts. Distances, arithmetic, and `MATCH` reject
unequal known dimensions; the database checks variable-size operands.

`as:` rejects conflicting known counts and selects a representation that validates dimensions
when the vector is decoded. It does not add SQL validation: composing the expression into another
function or inserting it does not invoke that decoder. Enforce stored-data invariants in the database
when needed. Slices default to variable-size results. `Vec.bit` tags packed bits;
`quantizeBinary()` converts numeric signs.

`Encoding` capability protocols identify supported layouts and operations for both fixed and
variable-size values. `SQLiteVecNumericEncoding` covers Float32 and signed Int8.

### Missing vectors and undefined scores

Float32 distances and cosine can return `nil` for undefined numerical results, even with nonnull
vectors. Filter scores before ranking; ascending SQL order otherwise puts NULL first:

```swift
let ranked = Embedding
  .where { $0.embedding.distanceCosine(to: vector).isNot(nil) }
  .order { $0.embedding.distanceCosine(to: vector) }
  .select { ($0.label, $0.embedding.distanceCosine(to: vector)) }
// SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", ?)
// FROM "Embeddings"
// WHERE ((vec_distance_cosine("Embeddings"."embedding", ?)) IS NOT (NULL))
// ORDER BY vec_distance_cosine("Embeddings"."embedding", ?)

let score = Vec.distanceCosine(vector, to: vector).ifnull(2)
// ifnull(vec_distance_cosine(?, ?), ?)
```

Choose fallbacks deliberately: replacing a missing distance with zero would rank it as an exact match.
Use `whenPresent` for nullable inputs; its closure receives a nonoptional expression:

```swift
let candidate: [Float].VectorBytesRepresentation? = [0.1, 0.2, 0.3]
let normalized = candidate.whenPresent { Vec.normalize($0) }
// CASE WHEN (?) IS NULL THEN NULL ELSE vec_normalize(?) END
```

`vec0.distance` is also nil outside KNN; `k` is a query constraint and returns NULL when selected.
Float32 iteration yields `(Int, Float?)`: keep nil positions to preserve dimensions. Fetch the vector
BLOB when NaN bit patterns matter.

### Signed Int8 vectors

```swift
// CREATE VIRTUAL TABLE Int8Embeddings USING vec0(embedding int8[3], label text);
@Table("Int8Embeddings")
struct Int8Embedding: Vec0 {
  @Column(as: [Int8].Int8BytesRepresentation.self)
  var embedding: [Int8]
  var label: String
}

let insert = Int8Embedding.insert {
  Int8Embedding(embedding: [-128, 0, 127], label: "example")
}
// INSERT INTO "Int8Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)

let quantized = Vec.quantizeInt8(vector)
// vec_quantize_int8(?, 'unit')
```

`Vec.int8` tags signed bytes or parses integer JSON. `quantizeInt8` maps [-1, 1] to signed codes,
clamping without normalization. Bound Int8 values attach SQLiteVec's subtype in inserts and
queries; use `Vec.int8` to tag other expressions. vec0 cannot update Int8 or binary vectors in place ([sqlite-vec#53](https://github.com/asg017/sqlite-vec/issues/53)); delete and reinsert the row.

### Binary vectors

`StructuredQueriesSQLiteVecCore` supplies `.PackedBitsRepresentation` for `[Bool]` and
`BinaryEmbeddingVector<N>`. Counts must be divisible by eight. `init(validating:)` throws
`InvalidDimensionsError`; nonthrowing construction, literals, and mutation precondition alignment.

```swift
let components = [true, false, true, false, false, false, false, true]
let binding = try [Bool].PackedBitsRepresentation(validating: components)
let payload = binding.vectorBytes // [0x85]: eight logical components in one byte.
```

```swift
// CREATE VIRTUAL TABLE BinaryEmbeddings USING vec0(embedding bit[8], label text);
@Table("BinaryEmbeddings")
struct BinaryEmbedding: Vec0 {
  @Column(as: [Bool].PackedBitsRepresentation.self)
  var embedding: [Bool]
  var label: String
}

let bits: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
let insert = BinaryEmbedding.insert {
  BinaryEmbedding(embedding: [true, false, true, false, false, false, false, true], label: "example")
}
// INSERT INTO "BinaryEmbeddings" ("embedding", "label") VALUES (vec_bit(?), ?)

let query = BinaryEmbedding
  .where { $0.embedding.match(bits) }
  .order { $0.distance }
  .limit(5)
// SELECT "BinaryEmbeddings"."embedding", "BinaryEmbeddings"."label"
// FROM "BinaryEmbeddings"
// WHERE (("BinaryEmbeddings"."embedding" MATCH vec_bit(?)))
// ORDER BY "BinaryEmbeddings"."distance"
// LIMIT ?
```

Binary slices require byte-aligned bounds. `Vec.quantizeBinary` maps positive Float32 or Int8
components to true. Bound packed bits attach the binary subtype in inserts and queries.

## Turso

`StructuredQueriesTursoVecCore` generates native vector SQL and bindings. Execute them with a
compatible Turso driver.

### Create a table and search

Execute this schema through your driver:

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  content TEXT NOT NULL,
  embedding F32_BLOB(4) NOT NULL
);
```

`F32_BLOB(4)` describes four-dimensional Float32 with BLOB affinity; plain `BLOB` also works.
The declaration does not enforce the component count. Keep stored and query formats and dimensions
consistent; fixed-size Swift representations validate dimensions when decoding.

```swift
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore

@Table("documents")
struct Document {
  var id: Int
  var content: String
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

let embedding = TursoVec.vector32("[0.1, 0.3, 0.5, 0.7]")
// vector32(?)
let insert = Document.insert { ($0.id, $0.content, $0.embedding) } values: {
  (1, "Introduction to databases", embedding)
}
// INSERT INTO "documents" ("id", "content", "embedding") VALUES (?, ?, vector32(?))

let vector: [Float].VectorBytesRepresentation = [0.2, 0.4, 0.6, 0.8]
let query = Document
  .where { TursoVec.distanceCosine($0.embedding, to: vector).isNot(nil) }
  .order { TursoVec.distanceCosine($0.embedding, to: vector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
// SELECT "documents"."content", vector_extract("documents"."embedding")
// FROM "documents"
// WHERE ((vector_distance_cos("documents"."embedding", ?)) IS NOT (NULL))
// ORDER BY vector_distance_cos("documents"."embedding", ?) ASC
// LIMIT ?

let prepared = query.query.prepare { "?\($0)" }
// SELECT "documents"."content", vector_extract("documents"."embedding")
// FROM "documents"
// WHERE ((vector_distance_cos("documents"."embedding", ?1)) IS NOT (NULL))
// ORDER BY vector_distance_cos("documents"."embedding", ?2) ASC
// LIMIT ?3
// Pass prepared.sql and prepared.bindings to your driver.
```

The query excludes undefined cosine distances before ranking. Distance ordering searches candidate
rows exactly; narrow them with `where`. Experimental sparse indexing uses separate DDL.

### Missing vectors and undefined scores

Numeric L2/dot (including Quantized8), cosine, and Jaccard return `Double?`: computations that
produce NaN become SQL NULL. SQL quantization can produce nonfinite parameters even from finite
inputs, without invoking Swift constructor validation. Binary dot/Hamming retain `Double` for
nonoptional inputs.

Use `whenPresent` with nullable inputs. Its CASE guard skips the native function for missing
values, and its closure retains encoding and dimension checks:

```swift
let candidate: [Float].VectorBytesRepresentation? = [0.2, 0.4, 0.6, 0.8]
let score = candidate.whenPresent {
  TursoVec.distanceCosine(Document.columns.embedding, to: $0)
}
// CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos("documents"."embedding", ?) END
let fallback = score.ifnull(2)
// ifnull(CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos("documents"."embedding", ?) END, ?)
```

Keep the nullable score to preserve undefined results in fetched rows. For nearest-neighbor
ranking, exclude undefined scores with `.isNot(nil)` or choose an explicit large fallback:

```swift
// CREATE TABLE compressed_documents (id INTEGER PRIMARY KEY, embedding BLOB NOT NULL);
@Table("compressed_documents")
struct CompressedDocument {
  var id: Int
  var embedding: TursoQuantized8Vector
}

let queryVector = try TursoQuantized8Vector(quantizing: [1, 2, 3])
let score = TursoVec.distanceL2(CompressedDocument.columns.embedding, to: queryVector)
let definedMatches = CompressedDocument
  .where { _ in score.isNot(nil) }
  .order { _ in score.asc() }
  .limit(5)
  .select { ($0.id, score) }

let matchesWithFallback = CompressedDocument
  .order { _ in score.ifnull(Double.greatestFiniteMagnitude).asc() }
  .limit(5)
  .select { ($0.id, score) }
```

`definedMatches` excludes undefined distances. `matchesWithFallback` keeps those rows and uses
a large score for ordering; its selected score remains nullable. Avoid a zero fallback for L2:
zero represents a perfect match. Ascending SQL order puts NULL first.
Missing inputs and undefined scores both decode as nil; inspect the input separately when that
distinction matters. Malformed bytes and mismatched dimensions still throw.

### Formats and functions

Convert JSON explicitly with the constructor for the column's format:

| Helper | Swift result |
| --- | --- |
| `TursoVec.vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `TursoVec.vector64` | `[Double].TursoFloat64BytesRepresentation` |
| `TursoVec.vector8` | `TursoQuantized8Vector` |
| `TursoVec.vector1bit` | `[Bool].TursoBinaryBytesRepresentation` |
| `TursoVec.vector32Sparse` | `TursoSparseFloat32Vector` |

Constructors accept JSON strings or vectors with a `TursoVectorEncoding`; `extract` requires a compatible
vector. Shared Float32 works directly. Double requires `.TursoFloat64BytesRepresentation`, and
binary requires `.TursoBinaryBytesRepresentation`. Raw Double, Float16, SQLiteVec Int8, and packed bits
are rejected. Numeric encodings support L2; binary encodings use Turso framing.

The table shows JSON and variable-size results. Fixed inputs retain dimensions across conversions.
Matching numeric formats support cosine, L2, negative dot product, and Jaccard. Binary L2 is
unavailable; `distanceHamming` calls `vector_distance_cos` and returns a `Double` bit count.

`TursoQuantized8Vector` stores affine UInt8 codes, scale, and shift; it differs from FP8 and sqlite-vec
Int8. `TursoSparseFloat32Vector` stores indexed features and a logical count. Both bind directly without
`@Column(as:)`. Turso binary strategies preserve exact counts, including partial bytes.

`concat` accepts dense Float32/Float64; `slice` also accepts sparse Float32. Use `as:` for fixed-size
results. See the [Turso guide](Sources/StructuredQueriesTursoVecCore/Documentation.docc/StructuredQueriesTursoVecCore.md)
for conversion chains, quantization, sparse storage, binary framing, and custom encodings.

## Vector values

Both query modules export `StructuredQueriesVectorCore`. Array strategies support `@Column(as:)`;
fixed values provide mutable collections, hashing, Codable, and dimension-checked decoding.

| Value | Database representation |
| --- | --- |
| `EmbeddingVector<N>` (Float32) | Direct binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` (Float64) | `.TursoFloat64BytesRepresentation` for Turso |
| `BinaryEmbeddingVector<N>` | `.PackedBitsRepresentation` for sqlite-vec; `.TursoBinaryBytesRepresentation` for Turso |
| `FixedEmbeddingVector<N, Int8>` | `.Int8BytesRepresentation` for sqlite-vec |
| `FixedTursoQuantized8Vector<N>` | Direct binding for Turso |
| `FixedTursoSparseFloat32Vector<N>` | Direct binding for Turso |

Fixed-size types require iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.

```swift
let dense = EmbeddingVector<8>([1, -1, 0, 2, -3, 4, 0, 5])
let binary = BinaryEmbeddingVector<8>(quantizing: dense)
let packedBytes = binary.packedBytes // [0xa9]: eight signs stored in one byte.
let candidate = try BinaryEmbeddingVector<8>(packedBytes: [0x85])
let distance = binary.hammingDistance(to: candidate) // 3 differing bits.

// Decode a cached Float32 payload with fixed-dimension validation.
let cachedBytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
let restored = try EmbeddingVector<3>(vectorBytes: cachedBytes) // [1, 0, 0]
```

Both engines share little-endian Float32. Float16 supports serialization only. Helpers enforce
compatible encodings and known dimensions; fixed results also validate decoded counts.

## Testing sqlite-vec

Use the same connection preparation in tests on any platform:

```swift
import SQLiteVecData
import Testing

@Suite
struct `Vector tests` {
  private let database: DatabaseQueue

  init() throws {
    var configuration = Configuration()
    configuration.prepareSQLiteVecExtension()
    self.database = try DatabaseQueue(configuration: configuration)
  }

  @Test
  func `Creates A Vector Table`() throws {
    try self.database.write { db in
      try db.execute(sql: "CREATE VIRTUAL TABLE embeddings USING vec0(embedding float[3])")
    }
  }
}
```

Add `SQLiteVecDataTestSupport` for `.sqliteVecAutoExtension`. It registers process-wide on
non-Apple platforms and does nothing on Apple; prepare Apple connections explicitly:

```swift
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite(.sqliteVecAutoExtension)
struct `Auto Extension Vector tests` {
  @Test
  func `Creates A Vector Table`() throws {
    var configuration = Configuration()
    #if canImport(Darwin)
      configuration.prepareSQLiteVecExtension()
    #endif
    let database = try DatabaseQueue(configuration: configuration)
    try database.write { db in
      try db.execute(sql: "CREATE VIRTUAL TABLE embeddings USING vec0(embedding float[3])")
    }
  }
}
```

Use per-connection preparation on Apple platforms or for isolated registration.

## Products

| Product | Purpose |
| --- | --- |
| `SQLiteVecData` | SQLiteData integration; exports sqlite-vec query helpers |
| `StructuredQueriesSQLiteVecCore` | Standalone sqlite-vec query helpers |
| `StructuredQueriesTursoVecCore` | Turso Database query helpers and encoded values |
| `StructuredQueriesVectorCore` | Shared vector values, byte strategies, and codecs |
| `SQLiteVecDataTestSupport` | Cross-platform suite trait; non-Apple auto registration |
| `CSQLiteVec` | Bundled sqlite-vec C extension |

`SQLiteVecNEON` and `SQLiteVecAVX` are enabled by default. ARM uses NEON; x86 uses AVX when
available and falls back to scalar code otherwise.

The default `SQLiteVecStaticAPI` calls linked SQLite functions and enables non-Apple per-connection setup.
Disable it for custom SQLite builds that require the extension API table; use
`registerSQLiteVecAutoExtension()` on non-Apple platforms in that configuration.

`CSQLiteVec` bundles [sqlite-vec v0.1.9](https://github.com/asg017/sqlite-vec/tree/e9f598abfa0c06b328d8fe5da9c3760cce74be10).
Its build plugin verifies `Sources/CSQLiteVec/SHA256SUMS` and applies `Patches/sqlite-vec/*.patch`
to a build-directory copy. `Scripts/prepare-sqlite-vec.sh` explains how to update the bundled source
and test AVX dispatch.

## Documentation

- [SQLiteVecData](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/sqlitevecdata/)
- [sqlite-vec query helpers](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
- [Turso query helpers](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriestursoveccore/)
- [Shared vector types](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/)
- [Migration guide](Sources/SQLiteVecData/Documentation.docc/VectorMigration.md)

## License

[MIT](LICENSE)
