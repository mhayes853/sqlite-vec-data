import CSQLiteVec
import GRDB

extension Database {
  /// Loads the sqlite-vec extension into the current database connection.
  ///
  /// On Apple platforms, call this at application launch using a `Configuration.prepareDatabase`
  /// callback so every connection loads sqlite-vec.
  ///
  /// On non-Apple platforms, prefer ``registerSQLiteVecAutoExtension()`` before opening any
  /// database connections. Process-global auto extension registration only affects connections
  /// opened after registration.
  ///
  /// ```swift
  /// var configuration = Configuration()
  /// configuration.prepareDatabase { db in
  ///   try db.loadSQLiteVecExtension()
  /// }
  /// let database = try SQLiteData.defaultDatabase(configuration: configuration)
  /// ```
  public func loadSQLiteVecExtension() throws {
    let code = sqlite3_vec_init(self.sqliteConnection, nil, nil)
    let resultCode = ResultCode(rawValue: code)
    if resultCode != .SQLITE_OK {
      throw DatabaseError(resultCode: resultCode, message: "Failed to load SQLiteVec extension.")
    }
  }
}
