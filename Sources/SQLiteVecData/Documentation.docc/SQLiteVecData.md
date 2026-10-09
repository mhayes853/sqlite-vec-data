# ``SQLiteVecData``

SQLiteData integration for sqlite-vec vector search.

## Overview

This module exports `SQLiteData` and `StructuredQueriesSQLiteVecCore`. Use it to load the extension,
create vec0 tables, and execute StructuredQueries statements through SQLiteData.

### Load the extension

Prepare each database connection, including database pool readers:

```swift
import SQLiteVecData

var configuration = Configuration()
configuration.prepareSQLiteVecExtension()
let database = try SQLiteData.defaultDatabase(configuration: configuration)
```

For process-wide registration on non-Apple platforms, call ``registerSQLiteVecAutoExtension()``
before opening connections instead:

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
// SELECT label, distance FROM Embeddings
// WHERE embedding MATCH ? ORDER BY distance LIMIT ?;

let neighbors = try database.read { db in
  try query.fetchAll(db)
}
```

See the [sqlite-vec query documentation](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
for Float32, signed Int8, binary vectors, and scalar functions.

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
  func `Searches Vectors`() throws {
    try self.database.write { db in
      // Create a vec0 table and run queries here.
    }
  }
}
```

### Turso Database

For native Turso vector queries, use the separate `StructuredQueriesTursoVecCore` product with a
compatible Turso driver. See the [Turso query documentation](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriestursoveccore/).

See the [migration guide](https://github.com/mhayes853/sqlite-vec-data/blob/main/Sources/StructuredQueriesVectorCore/Documentation.docc/VectorMigration.md).
