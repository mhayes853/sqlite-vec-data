# SQLiteVecData
[![CI](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml/badge.svg)](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)

SQLiteData interoperability with [sqlite-vec](https://github.com/asg017/sqlite-vec).

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

## Targets

`SQLiteVecData` is the main integration target that couples SQLiteData with sqlite-vec. It also exports `StructuredQueriesSQLiteVecCore`.

`StructuredQueriesSQLiteVecCore` is a standalone set of query helpers that model sqlite-vec features in StructuredQueries. Use this if you don't plan to use `SQLiteData` directly.

`SQLiteVecDataTestSupport` provides Swift Testing helpers for downstream packages, including the `.sqliteVecAutoExtension` suite trait for Linux test setup.

## Package Traits

The library ships with `NEON` (enabled by default) and `AVX` traits for SIMD in the vendored SQLite Vec code on both ARM and x86 respectively.

## Documentation

The documentation for releases and main are available here.
* [SQLiteVecData (main)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/sqlitevecdata/)
* [SQLiteVecData (0.x.x)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/~/documentation/sqlitevecdata/)
* [StructuredQueriesSQLiteVecCore (main)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
* [StructuredQueriesSQLiteVecCore (0.x.x)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/~/documentation/structuredqueriessqliteveccore/)

## Installation

You can add SQLiteVecData to an Xcode project by adding it to your project as a package.
> https://github.com/mhayes853/sqlite-vec-data

If you want to use SQLiteVecData in a SwiftPM project, add it to your `Package.swift`.

```swift
dependencies: [
  .package(url: "https://github.com/mhayes853/sqlite-vec-data", from: "0.3.0")
]
```

Then add the product to any target that needs it.

```swift
.product(name: "SQLiteVecData", package: "sqlite-vec-data")
```

## License

This library is licensed under an MIT License. See [LICENSE](https://github.com/mhayes853/sqlite-vec-data/blob/main/LICENSE) for details.
