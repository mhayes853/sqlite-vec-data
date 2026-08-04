import SQLiteVecData
import SQLiteVecDataTestSupport
import SnapshotTesting
import StructuredQueriesTestSupport
import Testing
import CustomDump

@Suite(.sqliteVecAutoExtension)
struct `VecEach tests` {
  private let database: DatabaseQueue

  init() async throws {
    self.database = try DatabaseQueue()

    try await self.database.write { db in
      #if canImport(Darwin)
        try db.loadSQLiteVecExtension()
      #endif
      try #sql(
        """
        CREATE VIRTUAL TABLE VecEachEmbeddings USING vec0(
          embedding float[3],
          label text
        );
        """,
        as: Void.self
      )
      .execute(db)
      try VecEachEmbedding.insert {
        VecEachEmbedding(embedding: [1, -2, 3], label: "mixed")
      }
      .execute(db)
    }
  }

  @Test
  func `Vec Each Binds A Vector`() async throws {
    let rows = try await self.database.read { db in
      let vector: [Float].VectorBytesRepresentation = [1, -2, 3]
      return try Vec.each(vector).order { $0.rowid }.fetchAll(db)
    }

    expectNoDifference(rows.map(\.rowid), [0, 1, 2])
    expectNoDifference(rows.map(\.value), [1, -2, 3])
  }

  @Test
  func `Vec Each Counts Elements`() async throws {
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

  @Test
  func `Vec Each Aggregates Elements`() async throws {
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

  @Test
  func `Vec Each Filters Elements`() async throws {
    let query = VecEachEmbedding
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

  @Test
  func `Vec Each Returns Indexed Elements`() async throws {
    let query = VecEachEmbedding
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
