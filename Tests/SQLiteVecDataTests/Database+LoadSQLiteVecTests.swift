import CustomDump
import Foundation
import GRDB
import SQLiteVecData
import Testing

@Suite
struct `DatabaseLoadSQLiteVec tests` {
  @Test
  func `Builds With Enabled SIMD Traits For The Active Architecture`() async throws {
    var configuration = Configuration()
    configuration.prepareSQLiteVecExtension()
    let database = try DatabaseQueue(configuration: configuration)
    let buildFlags = try await database.write { db in
      return try #sql("SELECT vec_debug()", as: String.self).fetchOne(db)
    }
    let debugDescription = try #require(buildFlags)

    #if arch(arm64)
      expectNoDifference(debugDescription.contains("neon"), true)
      expectNoDifference(debugDescription.contains("avx"), false)
    #elseif arch(x86_64)
      expectNoDifference(debugDescription.contains("neon"), false)
      #if SQLITE_VEC_AVX_ENABLED
        expectNoDifference(debugDescription.contains("avx"), true)
      #else
        expectNoDifference(debugDescription.contains("avx"), false)
      #endif
    #endif
  }

  @Test
  func `Prepares Only Configured Connections Alongside Caller Setup`() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    var configuration = Configuration()
    configuration.prepareDatabase { db in
      try db.execute(sql: "PRAGMA cache_size = 42")
    }
    configuration.prepareSQLiteVecExtension()

    let database = try DatabasePool(
      path: directory.appendingPathComponent("test.sqlite").path,
      configuration: configuration
    )
    defer { try? database.close() }
    let query = #sql(
      "SELECT cache_size, vec_length(vec_f32('[1, 2, 3]')) FROM pragma_cache_size",
      as: (Int, Int).self
    )
    let writer = try database.write { db in
      try db.execute(sql: "CREATE VIRTUAL TABLE vectors USING vec0(embedding float[3])")
      return try query.fetchOne(db)
    }
    let reader = try database.read { db in
      try db.execute(sql: "SELECT * FROM vectors")
      return try query.fetchOne(db)
    }
    let unconfigured = try DatabaseQueue()
    #expect(throws: DatabaseError.self) {
      try unconfigured.read { db in
        try query.fetchOne(db)
      }
    }

    for result in [try #require(writer), try #require(reader)] {
      expectNoDifference(result.0, 42)
      expectNoDifference(result.1, 3)
    }
  }
}
