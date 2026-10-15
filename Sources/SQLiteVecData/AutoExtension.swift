import CSQLiteVec
import GRDB
import GRDBSQLite

/// Registers sqlite-vec as a process-global SQLite auto extension.
///
/// On Apple platforms, prepare each connection with `Configuration.prepareSQLiteVecExtension()`.
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
@available(
  macOS,
  deprecated,
  message:
    "Process global auto extensions are not available on macOS. Use Configuration.prepareSQLiteVecExtension() instead."
)
@available(
  iOS,
  deprecated,
  message:
    "Process global auto extensions are not available on iOS. Use Configuration.prepareSQLiteVecExtension() instead."
)
@available(
  tvOS,
  deprecated,
  message:
    "Process global auto extensions are not available on tvOS. Use Configuration.prepareSQLiteVecExtension() instead."
)
@available(
  watchOS,
  deprecated,
  message:
    "Process global auto extensions are not available on watchOS. Use Configuration.prepareSQLiteVecExtension() instead."
)
@available(
  visionOS,
  deprecated,
  message:
    "Process global auto extensions are not available on visionOS. Use Configuration.prepareSQLiteVecExtension() instead."
)
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
