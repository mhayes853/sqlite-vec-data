# ``SQLiteVecData``

SQLiteData integration for sqlite-vec vector search.

## Overview

This module exports `SQLiteData` and `StructuredQueriesSQLiteVecCore` for loading sqlite-vec,
creating vec0 tables, and executing queries.

### Load the extension

Prepare each database connection, including database pool readers:

```swift
import SQLiteVecData

var configuration = Configuration()
configuration.prepareSQLiteVecExtension()
let database = try SQLiteData.defaultDatabase(configuration: configuration)
```

On non-Apple platforms, call ``registerSQLiteVecAutoExtension()`` before opening connections:

```swift
import SQLiteVecData

try registerSQLiteVecAutoExtension()
let database = try SQLiteData.defaultDatabase()
```

### Create a table and search

Execute the schema in your database migration:

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

let neighbors = try database.read { db in
  try query.fetchAll(db)
}
```

See [sqlite-vec query helpers](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
for Float32, Int8, binary vectors, and scalar functions.

### Testing

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

### Turso Database

Use `StructuredQueriesTursoVecCore` with a compatible driver for
[native Turso queries](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriestursoveccore/).

See the [migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/SQLiteVecData/Documentation.docc/VectorMigration.md).
