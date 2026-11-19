# SQLiteVecData

[![CI](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml/badge.svg)](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)

Vector search in Swift with [SQLiteData](https://github.com/pointfreeco/sqlite-data),
[sqlite-vec](https://github.com/asg017/sqlite-vec), and
[Turso Database](https://docs.turso.tech/sql-reference/functions/vector).

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

| Product | Use it for |
| --- | --- |
| `SQLiteVecData` | sqlite-vec with SQLiteData. Exports SQLiteData and the sqlite-vec query helpers |
| `StructuredQueriesSQLiteVecCore` | sqlite-vec query helpers alone, for another driver |
| `StructuredQueriesTursoVecCore` | Turso Database query helpers and encoded values |
| `StructuredQueriesVectorCore` | Shared vector values and byte strategies, exported by both query modules |
| `SQLiteVecDataTestSupport` | The `.sqliteVecAutoExtension` suite trait |
| `CSQLiteVec` | The bundled sqlite-vec C extension |

The standalone query modules also need `StructuredQueriesSQLite` from
[swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) for `@Table`,
`@Column`, and `#sql`.

A build tool plugin patches and compiles the bundled sqlite-vec source. It runs `/bin/sh`, `git`,
and `sha256sum` or `shasum`, which standard macOS and Linux development environments provide.
Xcode asks you to trust the plugin the first time you build.

## sqlite-vec

Prepare each connection, including database pool readers, with `prepareSQLiteVecExtension()`:

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

SQL comments show the generated query; `?` marks a bound value. The same configuration works with
`SQLiteData.defaultDatabase(configuration:)`, and in tests. On non-Apple platforms,
`registerSQLiteVecAutoExtension()` is a process-wide alternative; see the
[SQLiteVecData documentation](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/sqlitevecdata/).

### Vector functions

Column helpers and the `Vec` namespace accept bound values, computed expressions, and BLOB columns:

```swift
let distances = Embedding.select {
  ($0.label, $0.embedding.distanceCosine(to: vector.normalize()))
}
// SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", vec_normalize(?))
// FROM "Embeddings"

let prefix = Embedding.columns.embedding.slice(0..<2)
// vec_slice("Embeddings"."embedding", 0, 2)
let elements = Vec.each(vector).select { ($0.rowid, $0.value) }
// SELECT "vec_each"."rowid", "vec_each"."value"
// FROM "vec_each"
// WHERE ("vec_each"."vector" = ?)
```

Float32 and Int8 support L1, L2, cosine, and arithmetic; Float32 also normalizes; binary vectors
support Hamming distance. Operands must share an encoding, and fixed-size operands a dimension
count.

### Undefined scores

Float32 distances, all cosine distances, and vec0's `distance` return `Double?`: sqlite-vec yields
NULL for undefined results, and ascending SQL order puts NULL first. Filter before ranking:

```swift
let ranked = Embedding
  .where { $0.embedding.distanceCosine(to: vector).isNot(nil) }
  .order { $0.embedding.distanceCosine(to: vector) }
  .select { ($0.label, $0.embedding.distanceCosine(to: vector)) }
// SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", ?)
// FROM "Embeddings"
// WHERE ((vec_distance_cosine("Embeddings"."embedding", ?)) IS NOT (NULL))
// ORDER BY vec_distance_cosine("Embeddings"."embedding", ?)
```

Use `whenPresent` to call a helper with a nullable vector.

### Int8 and binary vectors

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

Binary columns use `[Bool].PackedBitsRepresentation` the same way, with counts divisible by eight,
and bind as `vec_bit(?)`. vec0 cannot update Int8 or binary vectors in place
([sqlite-vec#53](https://github.com/asg017/sqlite-vec/issues/53)); delete and reinsert the row.

The [sqlite-vec guide](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
covers every helper, fixed dimensions, quantization, and bit ordering.

## Turso

`StructuredQueriesTursoVecCore` generates native vector SQL and bindings. Execute them with a
compatible Turso driver.

```swift
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore

// CREATE TABLE documents (
//   id INTEGER PRIMARY KEY, content TEXT NOT NULL, embedding F32_BLOB(4) NOT NULL
// );
@Table("documents")
struct Document {
  var id: Int
  var content: String
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

let embedding = TursoVec.vector32("[0.1, 0.3, 0.5, 0.7]")
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
// Pass prepared.sql and prepared.bindings to your driver.
```

Turso does not enforce the count in `F32_BLOB(4)`; keep stored and query dimensions consistent.
Distance ordering searches candidate rows exactly, so narrow them with `where`. Numeric distances
return `Double?`, as with sqlite-vec.

| Constructor | Swift result |
| --- | --- |
| `TursoVec.vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `TursoVec.vector64` | `[Double].TursoFloat64BytesRepresentation` |
| `TursoVec.vector8` | `TursoQuantized8Vector` |
| `TursoVec.vector1bit` | `[Bool].TursoBinaryBytesRepresentation` |
| `TursoVec.vector32Sparse` | `TursoSparseFloat32Vector` |

The [Turso guide](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriestursoveccore/)
covers each format, the distance functions, `concat` and `slice`, and nullable scores.

## Fixed-size vectors

`EmbeddingVector<N>`, `EmbeddingVector64<N>`, and `BinaryEmbeddingVector<N>` carry their dimension
count in the type. Helpers reject mismatched counts at compile time, and decoding validates them:

```swift
let dense = EmbeddingVector<8>([1, -1, 0, 2, -3, 4, 0, 5])
let binary = BinaryEmbeddingVector<8>(quantizing: dense)
let candidate = try BinaryEmbeddingVector<8>(packedBytes: [0x85])
let distance = binary.hammingDistance(to: candidate) // 3 differing bits.
```

See the [shared vector types](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/).

## Package traits

`SQLiteVecNEON` and `SQLiteVecAVX` are enabled by default. ARM uses NEON; x86 uses AVX when
available and falls back to scalar code otherwise.

The default `SQLiteVecStaticAPI` calls the linked SQLite's functions directly, which per-connection
setup needs on non-Apple platforms. Disable it for custom SQLite builds that require the extension
API table, and use `registerSQLiteVecAutoExtension()` on non-Apple platforms instead:

```swift
.package(
  url: "https://github.com/mhayes853/sqlite-vec-data",
  from: "1.0.0",
  traits: ["SQLiteVecNEON", "SQLiteVecAVX"]
)
```

`CSQLiteVec` bundles [sqlite-vec v0.1.9](https://github.com/asg017/sqlite-vec/tree/e9f598abfa0c06b328d8fe5da9c3760cce74be10).
`Scripts/prepare-sqlite-vec.sh` explains how the plugin patches it, how to update it, and how to
test AVX dispatch.

## License

[MIT](LICENSE)
