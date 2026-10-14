# SQLiteVecData

[![CI](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml/badge.svg)](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)

Vector search in Swift with [SQLiteData](https://github.com/pointfreeco/sqlite-data),
[sqlite-vec](https://github.com/asg017/sqlite-vec), and
[Turso Database](https://docs.turso.tech/sql-reference/functions/vector).

SQL comments show generated queries; placeholders represent bound values.

## sqlite-vec

### Set up the database

Prepare each database connection, including database pool readers:

```swift
import SQLiteVecData

var configuration = Configuration()
configuration.prepareSQLiteVecExtension()
let database = try SQLiteData.defaultDatabase(configuration: configuration)
```

On non-Apple platforms, register process-wide before opening connections:

```swift
import SQLiteVecData

try registerSQLiteVecAutoExtension()
let database = try SQLiteData.defaultDatabase()
```

### Create a table and search

Execute the schema in a database migration, then model it with `Vec0`:

```swift
// CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
@Table("Embeddings")
struct Embedding: Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
  var label: String
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
```

`match` and `Vec.match` accept bound or computed vectors with matching encodings.

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

Distances return `Double` (SQL REAL); Int8 L1 is cast to REAL. `length()` returns `Int`.
Iteration returns `VecEachOf<Float>` (also called `VecEach`), `VecEachOf<Int8>`, or `VecEachOf<Bool>`.

Construct Float32 from JSON; `as:` selects a fixed-size result:

```swift
let fixed = Vec.f32("[1, 2, 3]", as: EmbeddingVector<3>.self)
// vec_f32(?)
let normalized = Vec.normalize(fixed)
// vec_normalize(vec_f32(?))
```

Length-preserving operations retain fixed counts. Distances, arithmetic, and `MATCH` reject
unequal known dimensions; the database checks variable-size operands.

`as:` rejects conflicting known counts and validates decoded dimensions. Slices default to
variable-size results. `Vec.bit` tags packed bits; `quantizeBinary()` converts numeric signs.

`Encoding` capability protocols identify supported layouts and operations for both fixed and
variable-size values. `SQLiteVecNumericEncoding` covers Float32 and signed Int8.

### Signed Int8 vectors

```swift
// CREATE VIRTUAL TABLE Int8Embeddings USING vec0(embedding int8[3], label text);
@Table("Int8Embeddings")
struct Int8Embedding: Vec0 {
  @Column(as: [Int8].Int8BytesRepresentation.self)
  var embedding: [Int8]
  var label: String
}

let codes: [Int8].Int8BytesRepresentation = [-128, 0, 127]
let insert = Int8Embedding.insert { ($0.embedding, $0.label) } values: {
  (Vec.int8(codes), "example")
}
// INSERT INTO "Int8Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)

let quantized = Vec.quantizeInt8(vector)
// vec_quantize_int8(?, 'unit')
```

`Vec.int8` tags signed bytes or parses integer JSON. `quantizeInt8` maps [-1, 1] to signed codes,
clamping without normalization. Inserts require either helper; queries attach subtypes automatically.

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
let insert = BinaryEmbedding.insert { ($0.embedding, $0.label) } values: {
  (Vec.bit(bits), "example")
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
components to true. Inserts use `Vec.bit`; queries tag packed bytes automatically.

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
Keep stored and query formats and dimensions consistent.

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
  .order { TursoVec.distanceCosine($0.embedding, to: vector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
// SELECT "documents"."content", vector_extract("documents"."embedding")
// FROM "documents"
// ORDER BY vector_distance_cos("documents"."embedding", ?) ASC
// LIMIT ?

let prepared = query.query.prepare { "?\($0)" }
// SELECT "documents"."content", vector_extract("documents"."embedding")
// FROM "documents"
// ORDER BY vector_distance_cos("documents"."embedding", ?1) ASC
// LIMIT ?2
// Pass prepared.sql and prepared.bindings to your driver.
```

Distance ordering searches candidate rows exactly; narrow them with `where`. Experimental sparse
indexing uses separate DDL.

### Formats and functions

Convert JSON explicitly with the constructor for the column's format:

| Helper | Swift result |
| --- | --- |
| `TursoVec.vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `TursoVec.vector64` | `[Double].TursoFloat64BytesRepresentation` |
| `TursoVec.vector8` | `Quantized8Vector` |
| `TursoVec.vector1bit` | `[Bool].TursoBytesRepresentation` |
| `TursoVec.vector32Sparse` | `SparseFloat32Vector` |

Constructors accept JSON strings or vectors with a `TursoVectorEncoding`; `extract` requires a compatible
vector. Shared Float32 works directly. Double requires `.TursoFloat64BytesRepresentation`, and
binary requires `.TursoBytesRepresentation`. Raw Double, Float16, SQLiteVec Int8, and packed bits
are rejected. Numeric encodings support L2; binary encodings use Turso framing.

The table shows JSON and variable-size results. Fixed inputs retain dimensions across conversions:

```swift
let embedding = EmbeddingVector<3>([0.1, 0.2, 0.3])
let precise = TursoVec.vector64(embedding)
// vector64(?)
let candidate = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(
  queryOutput: EmbeddingVector64<3>([0.2, 0.4, 0.6])
)
let distance = TursoVec.distanceL2(precise, to: candidate)
// vector_distance_l2(vector64(?), ?)
// precise decodes as EmbeddingVector64<3>; comparison with a known count of 4 is rejected.
```

```swift
let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
let precise = TursoVec.vector64(vector)
// vector64(?)
let json = TursoVec.extract(precise)
// vector_extract(vector64(?))
```

Matching formats support cosine, L2, negative dot product, and Jaccard. `concat` accepts dense
Float32/Float64; `slice` also accepts sparse Float32. Use `as:` for fixed-size results.

`Quantized8Vector` stores affine UInt8 codes, scale, and shift, distinct from FP8 and sqlite-vec
Int8. `SparseFloat32Vector` stores indexed features and a logical count, useful for TF-IDF
and bag-of-words. Both bind directly as column values:

```swift
// CREATE TABLE compressed_documents (id INTEGER PRIMARY KEY, embedding BLOB NOT NULL);
@Table("compressed_documents")
struct CompressedDocument {
  var id: Int
  var embedding: Quantized8Vector
}

let compressed = try Quantized8Vector(quantizing: [0, 127.5, 255])
let supplied = try Quantized8Vector(codes: [10, 20], scale: 2, shift: 1)
let inline = try InlineQuantized8Vector<2>(validating: supplied)
let sparseComponents = try SparseFloat32Vector(dimensions: 4, indices: [1, 3], values: [2, 5])
let sized = try SizedSparseFloat32Vector<4>(validating: sparseComponents)
let decoded = compressed.decodedValues() // [0, 128, 255]
let sparse = try SparseFloat32Vector(compressing: [0, 0, 1.5, 0, 0, 2.5])
let dense = sparse.denseValues() // [0, 0, 1.5, 0, 0, 2.5]
let insert = CompressedDocument.insert { ($0.id, $0.embedding) } values: {
  (1, compressed)
}
// INSERT INTO "compressed_documents" ("id", "embedding") VALUES (?, ?)
```

`init(validating:)` checks dimensions while preserving encoded components and sparse storage.

Float64 arrays, inline arrays, and `EmbeddingVector64<N>` require Turso's tagged strategy. Shared
Float64 bytes are raw. `.TursoFloat32BytesRepresentation` writes raw Float32 and also reads tagged
Float32; shared Float32 works directly.

Turso binary strategies preserve exact counts, including partial bytes. `distanceHamming` calls
`vector_distance_cos` and returns a `Double` bit count. Binary L2 is unavailable.

## Vector values

Both query modules export `StructuredQueriesVectorCore`. Array strategies support `@Column(as:)`;
fixed values provide mutable collections, hashing, Codable, and dimension-checked decoding.

| Value | Database representation |
| --- | --- |
| `EmbeddingVector<N>` (Float32) | Direct binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` (Float64) | `.TursoFloat64BytesRepresentation` for Turso |
| `BinaryEmbeddingVector<N>` | `.PackedBitsRepresentation` for sqlite-vec; `.TursoBytesRepresentation` for Turso |
| `FixedEmbeddingVector<N, Int8>` | `.Int8BytesRepresentation` for sqlite-vec |
| `InlineQuantized8Vector<N>` | Direct binding for Turso |
| `SizedSparseFloat32Vector<N>` | Direct binding for Turso |

Fixed-size types require Swift 6.2 and iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.

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

On non-Apple platforms, add `SQLiteVecDataTestSupport` and use `.sqliteVecAutoExtension` to
register sqlite-vec process-wide for subsequent connections:

```swift
#if !canImport(Darwin)
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite(.sqliteVecAutoExtension)
struct `Auto Extension Vector tests` {
  @Test
  func `Creates A Vector Table`() throws {
    let database = try DatabaseQueue()
    try database.write { db in
      try db.execute(sql: "CREATE VIRTUAL TABLE embeddings USING vec0(embedding float[3])")
    }
  }
}
#endif
```

Use per-connection preparation on Apple platforms or for isolated registration.

## Products

| Product | Purpose |
| --- | --- |
| `SQLiteVecData` | SQLiteData integration; exports sqlite-vec query helpers |
| `StructuredQueriesSQLiteVecCore` | Standalone sqlite-vec query helpers |
| `StructuredQueriesTursoVecCore` | Turso Database query helpers and encoded values |
| `StructuredQueriesVectorCore` | Shared vector values, byte strategies, and codecs |
| `SQLiteVecDataTestSupport` | Non-Apple auto-extension suite trait |
| `CSQLiteVec` | Bundled sqlite-vec C extension |

`SQLiteVecNEON` and `SQLiteVecAVX` are enabled by default for ARM and x86, respectively. AVX
requires an AVX-capable CPU; for older x86 CPUs, select only `SQLiteVecNEON` and
`SQLiteVecStaticAPI` traits.

The default `SQLiteVecStaticAPI` calls linked SQLite functions and enables non-Apple per-connection setup.
Disable it for custom SQLite builds that require the extension API table; use
`registerSQLiteVecAutoExtension()` on non-Apple platforms in that configuration.

## Documentation

- [SQLiteVecData](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/sqlitevecdata/)
- [sqlite-vec query helpers](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
- [Turso query helpers](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriestursoveccore/)
- [Shared vector types](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/)
- [Migration guide](Sources/SQLiteVecData/Documentation.docc/VectorMigration.md)

## Installation

Add the package to your Xcode project or `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/mhayes853/sqlite-vec-data", from: "1.0.0")
]
```

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

## License

[MIT](LICENSE)
