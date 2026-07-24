import GRDB
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite("DatabaseLoadSQLiteVec tests", .sqliteVecAutoExtension)
struct DatabaseLoadSQLiteVecTests {
  @Test("Loads SQLiteVec Extension Successfully")
  func loadsSQLiteVecExtensionSuccessfully() async throws {
    await #expect(throws: Never.self) {
      let database = try DatabaseQueue()
      try await database.write { db in
        #if canImport(Darwin)
          try db.loadSQLiteVecExtension()
        #endif

        try #sql(
          """
          CREATE VIRTUAL TABLE TestVectors USING vec0(
            sampleEmbeddings float[8]
          )
          """
        )
        .execute(db)
      }
    }
  }

  @Test("Builds With NEON For The Active Architecture")
  func buildsWithNEONForActiveArchitecture() async throws {
    let database = try DatabaseQueue()
    let buildFlags = try await database.write { db in
      #if canImport(Darwin)
        try db.loadSQLiteVecExtension()
      #endif

      return try #sql("SELECT vec_debug()", as: String.self).fetchOne(db)
    }
    let debugDescription = try #require(buildFlags)

    #if arch(arm64)
      #expect(debugDescription.contains("neon"))
    #elseif arch(x86_64)
      #expect(!debugDescription.contains("neon"))
    #endif
  }
}
