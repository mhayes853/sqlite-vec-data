# SQLiteVecData

[![CI](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml/badge.svg)](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)

SQLiteData interoperability with [sqlite-vec](https://github.com/asg017/sqlite-vec), and
StructuredQueries helpers for [Turso/libSQL native vector search](https://docs.turso.tech/features/ai-and-embeddings).

## Overview

SQLiteVecData bridges SQLiteData and sqlite-vec so you can create vec0 tables and run vector queries in pure Swift.

## Quick Start

Choose a setup strategy based on the platform where your app runs.

### Apple platforms

Call `loadSQLiteVecExtension` in your database preparation so every connection can use vec0 tables and vector functions.

```swift
import SQLiteVecData

extension DependencyValues {
  mutating func bootstrapDatabase() throws {
    var configuration = Configuration()
    configuration.prepareDatabase = { db in
      try db.loadSQLiteVecExtension()
    }
    let database = try SQLiteData.defaultDatabase(configuration: configuration)
    var migrator = DatabaseMigrator()
    try migrator.migrate(database)
    defaultDatabase = database
  }
}

@main
struct MyApp: App {
  init() {
    prepareDependencies {
      try! $0.bootstrapDatabase()
    }
  }
}
```

### Non-Apple platforms

Call `registerSQLiteVecAutoExtension()` once during process startup before opening any SQLite
connections. This registers sqlite-vec as a process-global SQLite auto extension, so only
connections opened after registration can use vec0 tables and vector functions.

```swift
import SQLiteVecData

@main
enum MyApp {
  static func main() throws {
    try registerSQLiteVecAutoExtension()

    let database = try SQLiteData.defaultDatabase()
    var migrator = DatabaseMigrator()
    try migrator.migrate(database)

    // Start the rest of your application after the database is ready.
  }
}
```

### Create a vec0 table

First, create the vec0 virtual table in your migration.

```sql
CREATE VIRTUAL TABLE "Embeddings" USING vec0(
  embedding FLOAT[1536],
  label TEXT
);
```

Then model the table in Swift by conforming to `Vec0` and using a vector bytes representation.

```swift
@Table("Embeddings")
struct Embedding: Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]

  var label: String
}
```

### Match queries

Use `match` to filter rows by vector similarity, and order by the vec0 `distance` column for nearest neighbors.

```swift
let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
let query = Embedding
  .where { $0.embedding.match(queryVector) }
  .order { $0.distance.asc() }
  .limit(5)
  .select { ($0.label, $0.distance) }
```

### Distance functions

You can also compute distances directly in select clauses.

```swift
let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
let query = Embedding.select {
  ($0.label, $0.embedding.distanceCosine(to: queryVector))
}
```

### Iterate over vector elements

Use `vecEach()` to iterate over a vector's indexed elements with SQLite Vec's `vec_each`
virtual table.

```swift
let query = Embedding
  .join(Embedding.columns.embedding.vecEach()) { _, _ in true }
  .select { embedding, element in
    (embedding.label, element.rowid, element.value)
  }
```

`vecEach()` constrains SQLite Vec's hidden `vector` column, so it can also be used in correlated
subqueries. For example, filter to rows containing a negative element:

```swift
let query = Embedding
  .where {
    $0.embedding.vecEach()
      .where { $0.value.lt(Float(0)) }
      .exists()
  }
  .select(\.label)
```

Or aggregate a vector's elements:

```swift
let query = Embedding.select {
  (
    $0.label,
    $0.embedding.vecEach().count(),
    $0.embedding.vecEach().select { $0.value.max() }
  )
}
```

Use `Vec.each(_:)` to iterate over a bound vector without a table:

```swift
let vector: [Float].VectorBytesRepresentation = [1, -2, 3]
let query = Vec.each(vector)
  .order { $0.rowid }
  .select { ($0.rowid, $0.value) }
```

## Testing

### Apple platforms

You will need to invoke `Database.loadSQLiteVecExtension()` inside the database preparation configuration block for each new database connection.

```swift
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

struct MyDatabaseTests {
  private let database: any DatabaseWriter

  init() throws {
    var configuration = Configuration()
    configuration.prepareDatabase = { db in
      try db.loadSQLiteVecExtension()
    }
    self.database = try SQLiteData.defaultDatabase(configuration: configuration)
  }

  @Test
  func myTest() throws {
    try self.database.write { db in
      // Run vec0 queries here.
    }
  }
}
```

### Non-Apple platforms

Apply the `.sqliteVecAutoExtension` Swift Testing trait to the suite to make sure the database connection is opened with SQLite Vec enabled.

```swift
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite(.sqliteVecAutoExtension)
struct MyDatabaseTests {
  private let database: any DatabaseWriter

  init() throws {
    self.database = try SQLiteData.defaultDatabase()
  }

  @Test
  func myTest() throws {
    try self.database.write { db in
      // Run vec0 queries here.
    }
  }
}
```

## EmbeddingVector

`EmbeddingVector` is a Hashable and Codable fixed-length array alternative to `InlineArray`. It is available on iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, and visionOS 26.0, and it can be stored in vec0 tables or used directly as a query binding.

```swift
@Table("Embeddings")
struct Embedding: Vec0 {
  var id: UUID
  var embedding: EmbeddingVector<1536>
}

let queryVector = EmbeddingVector<1536>([...])
let query = Embedding
  .where { $0.embedding.match(queryVector) }
  .select { ($0.id, $0.distance) }
```

`EmbeddingVector64<N>`, `EmbeddingVector16<N>`, and `BinaryEmbeddingVector<N>` provide the same
collection and Codable support for other scalars. Floating-point vectors use element-wise
comparison: signed zeros compare equal and NaNs compare unequal. This replaces the original
float32 memory comparison.

`Vec.bit` and `Vec.quantizeBinary` now return `[Bool].PackedBitsRepresentation` by default.
Their `as:` overloads require a packed-bit representation. This corrects the previous float32
result representation, which could discard binary data during decoding.

## Targets

`SQLiteVecData` is the main integration target that couples SQLiteData with sqlite-vec. It also exports `StructuredQueriesSQLiteVecCore`.

`StructuredQueriesSQLiteVecCore` is a standalone set of query helpers that model sqlite-vec features in StructuredQueries. Use this if you don't plan to use `SQLiteData` directly.

`StructuredQueriesTursoVecCore` provides `TursoVec` for the Rust-based Turso engine and
`LibSQLVec` for libSQL, including Turso Cloud databases running libSQL. The namespaces generate
vector SQL and bindings for use with a compatible database driver.

`StructuredQueriesVectorCore` contains reusable `EmbeddingVector`, `VectorBytesRepresentable`,
numeric and binary vector types, and their byte representations. Both vector query targets export
it, so existing SQLiteVec imports continue to expose these types.

`SQLiteVecDataTestSupport` provides Swift Testing helpers for downstream packages, including the `.sqliteVecAutoExtension` suite trait for Linux test setup.

## Turso and libSQL Vector Queries

Add `StructuredQueriesTursoVecCore` and import it alongside `StructuredQueriesSQLite`:

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

let queryVector: [Float].VectorBytesRepresentation = [0.2, 0.4, 0.6, 0.8]
let query = Document
  .order { TursoVec.distanceCosine($0.embedding, to: queryVector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
```

For Turso, create the table with a BLOB embedding column. Tables need no additional vector
conformance. Convert JSON explicitly with `TursoVec.vector32`, `vector64`, `vector8`,
`vector1bit`, or `vector32Sparse` before distance comparisons.

| Swift representation | Turso engine | libSQL |
| --- | --- | --- |
| `[Float].VectorBytesRepresentation` | Yes | Yes |
| `[Double].VectorBytesRepresentation` | Yes | Yes |
| `[Float16].VectorBytesRepresentation` | No | Yes |
| `[Float].BFloat16Representation` | No | Yes |
| `[Float].Float8Representation` | Yes | Yes |
| `[Bool].TursoBytesRepresentation` | Yes | Yes |
| `[Float].SparseRepresentation` | Yes | No |

Both namespaces offer cosine and L2 distances with matching formats. `TursoVec` also offers
negative dot product and Jaccard distances, dense concatenation, and dense or sparse slicing.
Binary cosine returns Hamming distance; binary L2 is unavailable. Sparse Swift values remain
dense arrays while blobs store only nonzero entries. Float8 and bfloat16 storage is lossy.

Fixed-size representations are available on the corresponding `EmbeddingVector<N>`,
`EmbeddingVector64<N>`, `EmbeddingVector16<N>`, and `BinaryEmbeddingVector<N>` types. Use
`as:` on conversions, concat, or slice to select a matching fixed-size result.

Shared float32 bytes agree with SQLiteVec on little-endian platforms. SQLiteVec binary columns
use `.PackedBitsRepresentation` (dimensions divisible by eight), while Turso and libSQL use
`.TursoBytesRepresentation` to preserve dimension metadata.

For libSQL DiskANN search, use `LibSQLVec.index` and `LibSQLVec.topK`:

```swift
let marker = LibSQLVec.index(Document.columns.embedding)
let createIndex = #sql("CREATE INDEX documents_idx ON documents (\(marker))", as: Void.self)
let neighbors = LibSQLVec.topK(index: "documents_idx", vector: queryVector, k: 3)
let query = Document.where { $0.id.in(neighbors) }.select(\.content)
```

For indexed libSQL search, declare the embedding column as `F32_BLOB(4)`. The `id` selected by
`LibSQLVectorTopK` belongs to the table-valued function; the indexed table's primary key can have
any name. Indexed search is approximate, filters apply after selecting neighbors, and `IN`
subqueries need explicit ordering when order matters. Turso's experimental sparse indexing uses
a separate mechanism and has no helper in this package.

See the [Turso vector reference](https://docs.turso.tech/sql-reference/functions/vector) and
[libSQL vector guide](https://docs.turso.tech/features/ai-and-embeddings). SQL tests link to each
engine's examples; byte fixtures link to pinned source revisions. They require no Turso instance.

## Package Traits

The library ships with `NEON` (enabled by default) and `AVX` traits for SIMD in the vendored SQLite Vec code on both ARM and x86 respectively.

## Documentation

The documentation for releases and main are available here.

* [SQLiteVecData (main)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/sqlitevecdata/)
* [SQLiteVecData (0.x.x)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/~/documentation/sqlitevecdata/)
* [StructuredQueriesSQLiteVecCore (main)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
* [StructuredQueriesSQLiteVecCore (0.x.x)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/~/documentation/structuredqueriessqliteveccore/)
* [StructuredQueriesTursoVecCore (main)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriestursoveccore/)
* [StructuredQueriesVectorCore (main)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/)

## Installation

You can add SQLiteVecData to an Xcode project by adding it to your project as a package.
> https://github.com/mhayes853/sqlite-vec-data

If you want to use SQLiteVecData in a SwiftPM project, add it to your `Package.swift`.

```swift
dependencies: [
  .package(url: "https://github.com/mhayes853/sqlite-vec-data", from: "0.5.0")
]
```

Then add the product to any target that needs it.

```swift
.product(name: "SQLiteVecData", package: "sqlite-vec-data")
```

For Turso query helpers, use the `StructuredQueriesTursoVecCore` product instead. Add the
`StructuredQueriesSQLite` product from `swift-structured-queries` if your target uses the `@Table`,
`@Column`, or `#sql` macros.

## License

This library is licensed under an MIT License. See [LICENSE](https://github.com/mhayes853/sqlite-vec-data/blob/main/LICENSE) for details.
