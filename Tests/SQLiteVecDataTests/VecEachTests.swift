import CustomDump
import SQLiteVecData
import SnapshotTesting
import StructuredQueriesTestSupport
import Testing

@Suite
struct `VecEach tests` {
  private let database: DatabaseQueue

  init() async throws {
    var configuration = Configuration()
    configuration.prepareSQLiteVecExtension()
    self.database = try DatabaseQueue(configuration: configuration)

    try await self.database.write { db in
      try #sql(
        "CREATE VIRTUAL TABLE VecEachEmbeddings USING vec0(embedding float[3], label text)",
        as: Void.self
      )
      .execute(db)
      try VecEachEmbedding.insert {
        VecEachEmbedding(embedding: [1, -2, 3], label: "mixed")
      }
      .execute(db)
    }
  }

  @Test("Vec Each Binds A Vector")
  func vecEachBindsAVector() async throws {
    let rows = try await self.database.read { db in
      let vector: [Float].VectorBytesRepresentation = [1, -2, 3]
      return try Vec.each(vector).order { $0.rowid }.fetchAll(db)
    }

    expectNoDifference(rows.map(\.rowid), [0, 1, 2])
    expectNoDifference(rows.map(\.value), [1, -2, 3])
  }

  @Test("Vec Each Float32 Values Are Real")
  func vecEachFloat32ValuesAreReal() async throws {
    // GRDB widens INTEGER results to Float, so check the storage class SQLite reports.
    let vector: [Float].VectorBytesRepresentation = [1, -2, 3]
    let query = Vec.each(vector).select { #sql("typeof(\($0.value))", as: String.self) }
    let types = try await self.database.read { db in
      try query.fetchAll(db)
    }

    expectNoDifference(types, ["real", "real", "real"])
  }

  @Test("Vec Each Counts Elements")
  func vecEachCountsElements() async throws {
    let query = VecEachEmbedding.select {
      ($0.label, $0.embedding.vecEach().count())
    }

    assertQuery(query) { query in
      try self.database.read { try query.fetchAll($0) }
    } sql: {
      """
      SELECT "VecEachEmbeddings"."label", (
        SELECT count(*)
        FROM "vec_each"
        WHERE ("vec_each"."vector" = "VecEachEmbeddings"."embedding")
      )
      FROM "VecEachEmbeddings"
      """
    } results: {
      """
      ┌─────────┬───┐
      │ "mixed" │ 3 │
      └─────────┴───┘
      """
    }
  }

  @Test("Vec Each Aggregates Elements")
  func vecEachAggregatesElements() async throws {
    let query = VecEachEmbedding.select {
      ($0.label, $0.embedding.vecEach().select { $0.value.max() })
    }

    assertQuery(query) { query in
      try self.database.read { try query.fetchAll($0) }
    } sql: {
      """
      SELECT "VecEachEmbeddings"."label", (
        SELECT max("vec_each"."value")
        FROM "vec_each"
        WHERE ("vec_each"."vector" = "VecEachEmbeddings"."embedding")
      )
      FROM "VecEachEmbeddings"
      """
    } results: {
      """
      ┌─────────┬─────┐
      │ "mixed" │ 3.0 │
      └─────────┴─────┘
      """
    }
  }

  @Test("Vec Each Filters Elements")
  func vecEachFiltersElements() async throws {
    let query =
      VecEachEmbedding
      .where {
        Vec.each($0.embedding)
          .where { $0.value.lt(Float(0)) }
          .exists()
      }
      .select(\.label)

    assertQuery(query) { query in
      try self.database.read { try query.fetchAll($0) }
    } sql: {
      """
      SELECT "VecEachEmbeddings"."label"
      FROM "VecEachEmbeddings"
      WHERE (EXISTS (
        SELECT "vec_each"."rowid", "vec_each"."value"
        FROM "vec_each"
        WHERE ("vec_each"."vector" = "VecEachEmbeddings"."embedding") AND (("vec_each"."value") < (0.0))
      ))
      """
    } results: {
      """
      ┌─────────┐
      │ "mixed" │
      └─────────┘
      """
    }
  }

  @Test("Vec Each Returns Indexed Elements")
  func vecEachReturnsIndexedElements() async throws {
    let query =
      VecEachEmbedding
      .join(VecEachEmbedding.columns.embedding.vecEach()) { _, _ in true }
      .select { ($0.label, $1.rowid, $1.value) }

    assertQuery(query) { query in
      try self.database.read { try query.fetchAll($0) }
    } sql: {
      """
      SELECT "VecEachEmbeddings"."label", "vec_each"."rowid", "vec_each"."value"
      FROM "VecEachEmbeddings"
      JOIN "vec_each" ON 1
      WHERE ("vec_each"."vector" = "VecEachEmbeddings"."embedding")
      """
    } results: {
      """
      ┌─────────┬───┬──────┐
      │ "mixed" │ 0 │ 1.0  │
      │ "mixed" │ 1 │ -2.0 │
      │ "mixed" │ 2 │ 3.0  │
      └─────────┴───┴──────┘
      """
    }
  }
}

@Table("VecEachEmbeddings")
private struct VecEachEmbedding: Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]

  var label: String
}
