import CSQLiteVec
import GRDB
import GRDBSQLite

@available(
  macOS,
  deprecated,
  message:
    "Process global auto extensions are not available on macOS. Use ``Database.loadSQLiteVecExtension`` instead."
)
@available(
  iOS,
  deprecated,
  message:
    "Process global auto extensions are not available on iOS. Use ``Database.loadSQLiteVecExtension`` instead."
)
@available(
  tvOS,
  deprecated,
  message:
    "Process global auto extensions are not available on tvOS. Use ``Database.loadSQLiteVecExtension`` instead."
)
@available(
  watchOS,
  deprecated,
  message:
    "Process global auto extensions are not available on watchOS. Use ``Database.loadSQLiteVecExtension`` instead."
)
@available(
  visionOS,
  deprecated,
  message:
    "Process global auto extensions are not available on visionOS. Use ``Database.loadSQLiteVecExtension`` instead."
)
/// Registers sqlite-vec as a process-global SQLite auto extension.
///
/// On Apple platforms, use ``Database/loadSQLiteVecExtension()`` to load sqlite-vec into each
/// database connection instead.
///
/// ```swift
/// #if !canImport(Darwin)
///   try registerSQLiteVecAutoExtension()
///   let database = try DatabaseQueue()
///   try database.write { db in
///     try db.execute(sql: "CREATE VIRTUAL TABLE embeddings USING vec0(embedding float[3])")
///   }
/// #endif
/// ```
public func registerSQLiteVecAutoExtension() throws {
  let vecInit:
    @convention(c) (
      OpaquePointer?,
      UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
      UnsafePointer<sqlite3_api_routines>?
    ) -> Int32 = sqlite3_vec_init
  let code = sqlite3_auto_extension(
    unsafeBitCast(vecInit, to: (@convention(c) () -> Void).self)
  )
  let resultCode = ResultCode(rawValue: code)
  if resultCode != .SQLITE_OK {
    throw DatabaseError(resultCode: resultCode, message: "Failed to load SQLiteVec extension.")
  }
}
