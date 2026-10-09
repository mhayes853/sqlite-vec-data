import GRDB

extension Configuration {
  /// Loads sqlite-vec into each connection opened with this configuration.
  ///
  /// Includes database pool readers and preserves existing database preparation callbacks.
  /// Registration is scoped to these connections on every platform.
  ///
  /// ```swift
  /// var configuration = Configuration()
  /// configuration.prepareSQLiteVecExtension()
  /// let database = try DatabaseQueue(configuration: configuration)
  /// ```
  public mutating func prepareSQLiteVecExtension() {
    self.prepareDatabase { db in
      try db.loadSQLiteVecExtension()
    }
  }
}
