# SQLiteVecData

[![CI](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml/badge.svg)](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)

Vector search in Swift: [SQLiteData](https://github.com/pointfreeco/sqlite-data) integration for
[sqlite-vec](https://github.com/asg017/sqlite-vec), and StructuredQueries helpers for
[Turso Database](https://docs.turso.tech/sql-reference/functions/vector).

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

For standalone query helpers, also add `StructuredQueriesSQLite` from
[swift-structured-queries](https://github.com/pointfreeco/swift-structured-queries) to use
`@Table`, `@Column`, and `#sql`.

## sqlite-vec

### Set up the database

On Apple platforms, load the extension in the connection preparation callback:

```swift
import SQLiteVecData

var configuration = Configuration()
configuration.prepareDatabase { db in
  try db.loadSQLiteVecExtension()
}
let database = try SQLiteData.defaultDatabase(configuration: configuration)
```

On other platforms, register the extension once before opening any SQLite connections:

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
// SELECT label, distance FROM Embeddings
// WHERE embedding MATCH ? ORDER BY distance LIMIT ?;
```

`match` accepts a bound vector or a computed expression with the same encoding.
`Vec.match(column, to: expression)` provides the namespace form.

### Vector functions

```swift
let distances = Embedding.select {
  ($0.label, $0.embedding.distanceCosine(to: vector))
}
// SELECT label, vec_distance_cosine(embedding, ?) FROM Embeddings;

let normalized = Vec.normalize(vector) // vec_normalize(?)
let elements = Vec.each(vector)
  .order { $0.rowid }
  .select { ($0.rowid, $0.value) }
// SELECT rowid, value FROM vec_each WHERE vector = ? ORDER BY rowid;
```

Column helpers also support arithmetic, slicing, inspection, and `.vecEach()` for joins or
correlated subqueries. Float32 and signed Int8 support L1, L2, and cosine distances;
normalization requires Float32. Binary vectors support Hamming distance.

Distance helpers return `REAL` values decoded as `Double`; the Int8 L1 helper casts SQLiteVec's
integer result. `length()` returns an `Int`. Iteration yields `VecEach` (`VecEachOf<Float>`) for
Float32, and `VecEachOf<Int8>` or `VecEachOf<Bool>` for the integer elements of Int8 and binary
vectors.

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
// INSERT INTO Int8Embeddings (embedding, label) VALUES (vec_int8(?), ?);

let quantized = Vec.quantizeInt8(vector) // vec_quantize_int8(?, 'unit')
```

`Vec.int8` tags signed bytes or parses integer JSON. `quantizeInt8` maps [-1, 1] to signed
codes and clamps values outside that range, without normalizing. Use `Vec.int8` or a
quantization expression when inserting; query helpers attach the required subtype automatically.

### Binary vectors

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
// INSERT INTO BinaryEmbeddings (embedding, label) VALUES (vec_bit(?), ?);

let query = BinaryEmbedding
  .where { $0.embedding.match(bits) }
  .order { $0.distance }
  .limit(5)
```

Packed-bit dimensions and slice boundaries must be divisible by eight. `Vec.quantizeBinary`
converts positive Float32 or Int8 components to true bits. Binary inserts use `Vec.bit`;
query helpers tag the bytes automatically.

## Turso

`StructuredQueriesTursoVecCore` generates SQL and bindings for Turso Database's native vector
functions. Execute them with a compatible Turso driver.

### Create a table and search

Execute this schema through your driver:

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  content TEXT NOT NULL,
  embedding F32_BLOB(4) NOT NULL
);
```

`F32_BLOB(4)` describes a four-dimensional Float32 column with BLOB affinity; plain `BLOB`
also works. Keep stored and query vectors consistent in format and dimensions.

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
let insert = Document.insert { ($0.id, $0.content, $0.embedding) } values: {
  (1, "Introduction to databases", embedding)
}
// INSERT INTO documents (id, content, embedding) VALUES (?, ?, vector32(?));

let vector: [Float].VectorBytesRepresentation = [0.2, 0.4, 0.6, 0.8]
let query = Document
  .order { TursoVec.distanceCosine($0.embedding, to: vector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
// SELECT content, vector_extract(embedding) FROM documents
// ORDER BY vector_distance_cos(embedding, ?) ASC LIMIT ?;

let prepared = query.query.prepare { "?\($0)" }
// Pass prepared.sql and prepared.bindings to your driver.
```

This performs exact search over the candidate rows. Add a `where` clause to narrow them.
The target provides scalar vector functions; experimental sparse indexing uses separate DDL.

### Formats and functions

Convert JSON explicitly with the constructor for the column's format:

| Helper | Swift result |
| --- | --- |
| `TursoVec.vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `TursoVec.vector64` | `[Double].VectorBytesRepresentation` |
| `TursoVec.vector8` | `Quantized8Vector` |
| `TursoVec.vector1bit` | `[Bool].TursoBytesRepresentation` |
| `TursoVec.vector32Sparse` | `SparseFloat32Vector` |

Distance helpers cover cosine, L2, negative dot product, and Jaccard with matching formats.
`concat` joins two dense Float32 or Float64 vectors; `slice` accepts those formats and sparse
Float32. Use `as:` to select a matching fixed-size result.

`Quantized8Vector` stores affine unsigned-byte codes, scale, and shift. It differs from IEEE FP8
and sqlite-vec's signed Int8. `SparseFloat32Vector` stores only entries and their indices, plus the
logical dimension count: useful for TF-IDF, bag-of-words, and other mostly zero feature vectors.
Both types work directly as column values:

```swift
// CREATE TABLE compressed_documents (id INTEGER PRIMARY KEY, embedding BLOB NOT NULL);
@Table("compressed_documents")
struct CompressedDocument {
  var id: Int
  var embedding: Quantized8Vector
}

let compressed = try Quantized8Vector(quantizing: [0, 127.5, 255])
let decoded = compressed.decodedValues() // [0, 128, 255]
let sparse = try SparseFloat32Vector(compressing: [0, 0, 1.5, 0, 0, 2.5])
let dense = sparse.denseValues() // [0, 0, 1.5, 0, 0, 2.5]
```

Turso binary columns use `.TursoBytesRepresentation` on `[Bool]` or `BinaryEmbeddingVector<N>`.
It preserves the exact dimension count, including partial bytes. `distanceHamming` emits
`vector_distance_cos` and returns a `Double` bit count. Binary L2 is unavailable.

## Vector values

Both query modules export `StructuredQueriesVectorCore`. Array strategies work with `@Column(as:)`;
fixed-size values provide mutable collections, hashing, Codable, and dimension-checked decoding.
The Turso target also supplies quantized and sparse values.

| Value | Database representation |
| --- | --- |
| `EmbeddingVector<N>` (Float32) | Direct binding or `.VectorBytesRepresentation` |
| `EmbeddingVector64<N>` (Float64) | `.VectorBytesRepresentation` for Turso |
| `BinaryEmbeddingVector<N>` | `.PackedBitsRepresentation` for sqlite-vec; `.TursoBytesRepresentation` for Turso |
| `FixedEmbeddingVector<N, Int8>` | `.Int8BytesRepresentation` for sqlite-vec |
| `InlineQuantized8Vector<N>` | Direct binding for Turso |
| `SizedSparseFloat32Vector<N>` | Direct binding for Turso |

Fixed-size types require Swift 6.2 and iOS 26, macOS 26, tvOS 26, watchOS 26, or visionOS 26.

```swift
let dense = EmbeddingVector<8>([1, -1, 0, 2, -3, 4, 0, 5])
let binary = BinaryEmbeddingVector<8>(quantizing: dense)
let distance = binary.hammingDistance(to: BinaryEmbeddingVector<8>(repeating: false))

let bytes = [Float(1), 2, 3].vectorBytes
let restored = try EmbeddingVector<3>(vectorBytes: bytes)
```

Float32 bytes are shared by both engines on little-endian platforms. Float16 representations
provide serialization only; neither engine supports binary16 vector queries. Query helpers enforce
compatible encodings, and fixed-size representations validate decoded dimensions.

## Testing sqlite-vec

Use the `.sqliteVecAutoExtension` suite trait on non-Apple platforms; Apple connections load the
extension through their preparation callback:

```swift
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite(.sqliteVecAutoExtension)
struct `Vector tests` {
  private let database: DatabaseQueue

  init() throws {
    var configuration = Configuration()
    #if canImport(Darwin)
      configuration.prepareDatabase { try $0.loadSQLiteVecExtension() }
    #endif
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

## Products

| Product | Purpose |
| --- | --- |
| `SQLiteVecData` | SQLiteData integration; exports sqlite-vec query helpers |
| `StructuredQueriesSQLiteVecCore` | Standalone sqlite-vec query helpers |
| `StructuredQueriesTursoVecCore` | Turso Database query helpers and encoded values |
| `StructuredQueriesVectorCore` | Shared vector values, byte strategies, and codecs |
| `SQLiteVecDataTestSupport` | Swift Testing setup helpers |
| `CSQLiteVec` | Bundled sqlite-vec C extension |

The `NEON` package trait enables ARM SIMD by default; `AVX` enables SIMD on supported x86 processors.

## Documentation

- [SQLiteVecData](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/sqlitevecdata/)
- [sqlite-vec query helpers](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriessqliteveccore/)
- [Turso query helpers](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriestursoveccore/)
- [Shared vector types](https://swiftpackageindex.com/mhayes853/sqlite-vec-data/main/documentation/structuredqueriesvectorcore/)
- [Migration guide](Sources/StructuredQueriesVectorCore/Documentation.docc/VectorMigration.md)

## License

[MIT](LICENSE)
