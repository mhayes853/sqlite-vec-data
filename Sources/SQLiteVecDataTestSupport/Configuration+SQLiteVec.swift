import SQLiteVecData

extension Configuration {
  /// Loads sqlite-vec into every database connection opened with this configuration.
  ///
  /// On Apple platforms, this prepares each connection, including a database pool's readers.
  /// On other platforms, it registers the process-global auto extension once, before opening
  /// connections. Existing database preparation callbacks are preserved.
  ///
  /// ```swift
  /// var configuration = Configuration()
  /// try configuration.prepareSQLiteVec()
  /// let database = try DatabaseQueue(configuration: configuration)
  /// ```
  public mutating func prepareSQLiteVec() throws {
    #if canImport(Darwin)
      self.prepareDatabase { db in
        try db.loadSQLiteVecExtension()
      }
    #else
      try _SQLiteVecAutoExtensionTrait.registerIfNeeded()
    #endif
  }
}
