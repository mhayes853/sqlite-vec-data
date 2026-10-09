import CSQLiteVec
import GRDB
import GRDBSQLite

extension Database {
  /// Loads the sqlite-vec extension into the current database connection.
  ///
  /// Use `Configuration.prepareSQLiteVecExtension()` to prepare every connection,
  /// including database pool readers, on any platform.
  ///
  /// ```swift
  /// var configuration = Configuration()
  /// configuration.prepareSQLiteVecExtension()
  /// let database = try SQLiteData.defaultDatabase(configuration: configuration)
  /// ```
  public func loadSQLiteVecExtension() throws {
    var errorMessage: UnsafeMutablePointer<CChar>?
    defer { sqlite3_free(errorMessage) }
    let code = sqlite3_vec_init(self.sqliteConnection, &errorMessage, nil)
    let resultCode = ResultCode(rawValue: code)
    if resultCode != .SQLITE_OK {
      throw DatabaseError(
        resultCode: resultCode,
        message: errorMessage.map { String(cString: $0) } ?? "Failed to load SQLiteVec extension."
      )
    }
  }
}
