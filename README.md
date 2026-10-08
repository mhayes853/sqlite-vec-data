# SQLiteVecData

[![CI](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml/badge.svg)](https://github.com/mhayes853/sqlite-vec-data/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmhayes853%2Fsqlite-vec-data%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mhayes853/sqlite-vec-data)

SQLiteData interoperability with [sqlite-vec](https://github.com/asg017/sqlite-vec), and
StructuredQueries helpers for [Turso Database native vector search](https://docs.turso.tech/guides/vector-search).

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

`EmbeddingVector64<N>` provides the same collection and Codable support for doubles.
Floating-point vectors use element-wise
comparison: signed zeros compare equal and NaNs compare unequal. This replaces the original
float32 memory comparison.

`BinaryEmbeddingVector<N>` is a concrete packed-bit collection with mutable `Bool` elements and
boolean-array Codable support. It stores only `ceil(N / 8)` bytes: 1,536 dimensions need 192 bytes.
`packedBytes` contains the raw payload, and `init(packedBytes:)` validates its length and clears
unused high bits. Database metadata is added by the explicit byte representations.

```swift
let dense = EmbeddingVector<8>([1, -1, 0, 2, -3, 4, 0, 5])
var binary = BinaryEmbeddingVector<8>(quantizing: dense)
binary[2] = true
let differingBits = binary.hammingDistance(to: BinaryEmbeddingVector<8>(repeating: false))
let trueBits = binary.nonzeroBitCount
```

Sign quantization keeps positive components and discards their magnitudes. Both query targets
share this packed value. SQLiteVec's `.PackedBitsRepresentation` and Turso's
`.TursoBytesRepresentation` bind and decode its packed payload directly. Access logical elements
through the collection API.

`Vec.bit` and `Vec.quantizeBinary` now return `[Bool].PackedBitsRepresentation` by default.
Their `as:` overloads require a packed-bit representation. This corrects the previous float32
result representation, which could discard binary data during decoding.

SQLiteVec helpers check vector encodings at compile time. Float32 vectors support L1, L2, cosine,
arithmetic, and normalization; raw packed bits support Hamming. Both support inspection, slicing,
iteration, and `MATCH`. Comparisons require matching encodings, and vector-result `as:` overloads
require the operation's output encoding. Turso Float64, quantized, sparse, and binary formats cannot
be passed to SQLiteVec helpers.

```swift
// CREATE VIRTUAL TABLE BinaryEmbeddings USING vec0(embedding bit[8], label text);
@Table("BinaryEmbeddings")
struct BinaryEmbedding: Vec0 {
  @Column(as: [Bool].PackedBitsRepresentation.self)
  var embedding: [Bool]
  var label: String
}

let queryVector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
let insert = BinaryEmbedding.insert {
  ($0.embedding, $0.label)
} values: {
  (Vec.bit(queryVector), "example")
}
let query = BinaryEmbedding
  .where { $0.embedding.match(queryVector) }
  .order { $0.distance }
  .limit(5)
  .select { ($0.label, $0.distance) }
```

The column `match` helper also accepts computed vector expressions. Use
`Vec.match(column, to: expression)` for the freeform version; both enforce matching encodings.

Binary query helpers apply `vec_bit(...)` automatically. Binary inserts and updates need `Vec.bit`
in their value expression to attach SQLiteVec's required subtype. Slice boundaries must be divisible
by eight. `Vec.each` follows SQLiteVec's iteration order, most significant bit first within each byte;
packed-vector collection indices and `Vec.toJSON` use least significant bit first.

## Targets

`SQLiteVecData` is the main integration target that couples SQLiteData with sqlite-vec. It also exports `StructuredQueriesSQLiteVecCore`.

`StructuredQueriesSQLiteVecCore` is a standalone set of query helpers that model sqlite-vec features in StructuredQueries. Use this if you don't plan to use `SQLiteData` directly.

`StructuredQueriesTursoVecCore` provides `TursoVec` for Turso Database. It generates vector SQL
and bindings for use with a compatible database driver.

`StructuredQueriesVectorCore` contains reusable `EmbeddingVector`, `VectorBytesRepresentable`,
numeric and binary vector types, and their byte representations. Both vector query targets export
it, so existing SQLiteVec imports continue to expose these types.

`SQLiteVecDataTestSupport` provides Swift Testing helpers for downstream packages, including the `.sqliteVecAutoExtension` suite trait for Linux test setup.

## Turso Vector Queries

Create the table through your Turso Database driver before running the queries below. Following
[Turso's schema example](https://turso.tech/blog/a-complete-guide-to-database-per-agent-architecture),
use `F32_BLOB(4)` to describe four-dimensional float32 embeddings:

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  content TEXT NOT NULL,
  embedding F32_BLOB(4) NOT NULL
);
```

The `NOT NULL` columns match the nonoptional Swift properties below. `@Table` models the table
for query generation; execute the creation SQL separately through your driver.

`F32_BLOB(N)` has
[BLOB affinity](https://github.com/tursodatabase/turso/blob/2487f62c372c99a21551a6450d4a10309c7dad2b/core/vdbe/affinity.rs#L186-L202),
so plain `BLOB` also works. In the inspected Rust Turso engine,
`N` records the intended dimensions but does not enforce them: an official
[driver test](https://github.com/tursodatabase/turso-go/blob/ea06d135c592ae9a653ebf6ba5e069c8417c030c/turso_test.go#L354-L366)
inserts a five-dimensional vector into `F32_BLOB(64)`. `EmbeddingVector<4>` expresses the count
in Swift and validates it when decoding. This fixed-size example requires Swift 6.2 and the
platforms listed under [EmbeddingVector](#embeddingvector).

Add `StructuredQueriesTursoVecCore` and import it alongside `StructuredQueriesSQLite`:

```swift
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore

@Table("documents")
struct Document {
  var id: Int
  var content: String
  var embedding: EmbeddingVector<4>
}

let queryVector = EmbeddingVector<4>([0.2, 0.4, 0.6, 0.8])
let query = Document
  .order { TursoVec.distanceCosine($0.embedding, to: queryVector).asc() }
  .limit(5)
  .select { ($0.content, TursoVec.extract($0.embedding)) }
```

For variable-size float32 models, use `[Float]` with
`@Column(as: [Float].VectorBytesRepresentation.self)`. A plain BLOB column supports dense,
quantized, binary, and sparse vectors; choose the encoding with the bound value or SQL conversion.
Keep the vector format and dimensions consistent for distance comparisons. Tables need no
additional vector conformance.
Convert JSON explicitly with `TursoVec.vector32`, `vector64`, `vector8`,
`vector1bit`, or `vector32Sparse` before distance comparisons.

| Conversion | Swift representation |
| --- | --- |
| `vector32` / `vector` | `[Float].VectorBytesRepresentation` |
| `vector64` | `[Double].VectorBytesRepresentation` |
| `vector8` | `Quantized8Vector` |
| `vector1bit` | `[Bool].TursoBytesRepresentation` |
| `vector32Sparse` | `SparseFloat32Vector` |

`TursoVec` offers cosine, L2, negative dot product, and Jaccard distances with matching formats,
dense concatenation, and dense or sparse slicing. `TursoVec.distanceHamming` expresses binary
Hamming distance using Turso's `vector_distance_cos` SQL function and returns `Double` (SQL REAL).
Local `BinaryEmbeddingVector.hammingDistance(to:)` returns `Int`. Binary L2 is unavailable.
`Quantized8Vector` retains unsigned byte codes, scale, and shift for
Turso's affine 8-bit quantization, rather than IEEE FP8 or signed int8. Use
`try Quantized8Vector(quantizing: values)` to quantize once, or `init(codes:scale:shift:)` for
existing components. Reading and rebinding preserve them; `decodedValues()` reconstructs floats.

Sparse blobs store only nonzero float32 values, their indices, and the original dimension count.
This is useful for TF-IDF, bag-of-words, and other mostly zero feature vectors. The Swift value
retains sparse indices and values. `denseValues()` explicitly expands them. Sparse storage alone
does not create an index.

On Swift 6.2, `InlineQuantized8Vector<N>` stores its codes inline, and
`SizedSparseFloat32Vector<N>` fixes the logical dimensions while keeping a variable number of sparse
entries. These four encoded types live in `StructuredQueriesTursoVecCore` and can be used as column
types directly. Shared dense vectors and byte strategies remain in `StructuredQueriesVectorCore`.

`EmbeddingVector<N>.quantized8()` and `.sparseFloat32()` provide explicit, throwing conversions
to these dimension-preserving types. These conveniences live in the Turso target:

```swift
let quantized = try EmbeddingVector<3>([0, 127.5, 255]).quantized8()
let sparse = try EmbeddingVector<6>([0, 0, 1.5, 0, 0, 2.5]).sparseFloat32()
```

Fixed-size representations are available on the corresponding `EmbeddingVector<N>`,
`EmbeddingVector64<N>` and `BinaryEmbeddingVector<N>` types. Use
`as:` on conversions, concat, or slice to select a matching fixed-size result.

Shared float32 bytes agree with SQLiteVec on little-endian platforms. SQLiteVec binary columns
use `.PackedBitsRepresentation` (dimensions divisible by eight), while Turso uses
`.TursoBytesRepresentation` to preserve dimension metadata.

Vectors and their representations expose `vectorBytes` and `init(vectorBytes:)` independently
of query decoding. Fixed-size byte decoding validates dimensions; `EmbeddingVector<N>(validating:)`
also constructs a fixed vector from a scalar array. For example:

```swift
let bytes = [Float(1), 2, 3].vectorBytes
let restored = try EmbeddingVector<3>(vectorBytes: bytes)
let validated = try EmbeddingVector<3>(validating: [1, 2, 3])
let quantized = try Quantized8Vector(codes: [10, 20], scale: 2, shift: 1)
let decoded = try Quantized8Vector(vectorBytes: quantized.vectorBytes)
```

`VectorBytesRepresentable.Encoding` uses an existing canonical representation to identify the
byte layout. Inline quantized vectors share `Quantized8Vector`'s encoding, and sized sparse vectors
share `SparseFloat32Vector`'s encoding. `VectorScalar` supplies generic little-endian codecs through
an unsigned `BitPattern`, `bitPattern`, and `init(bitPattern:)`. Float and Double use these codecs
with their format framing; other floating-point conformances can reuse or override them.

Turso's experimental sparse indexing uses a separate mechanism and has no helper in this package.
Exact search orders candidate rows by distance; use a `where` clause to reduce the candidate set
when needed.

See the [Turso vector reference](https://docs.turso.tech/sql-reference/functions/vector).
SQL tests link to documentation examples, and byte fixtures link to pinned Turso source revisions.
They require no Turso instance.

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
