import CustomDump
import GRDB
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite("DatabaseLoadSQLiteVec tests")
struct DatabaseLoadSQLiteVecTests {
  @Test("Builds With Enabled SIMD Traits For The Active Architecture")
  func buildsWithEnabledSIMDTraitsForActiveArchitecture() async throws {
    var configuration = Configuration()
    try configuration.prepareSQLiteVec()
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
}
