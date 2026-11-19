import SQLiteVecData
import Testing

public struct _SQLiteVecAutoExtensionTrait: SuiteTrait {
  private static let didRegisterSQLiteVecAutoExtension = Lock(false)

  public func prepare(for test: Test) async throws {
    #if !canImport(Darwin)
      try Self.didRegisterSQLiteVecAutoExtension.withLock { didRegister in
        guard !didRegister else { return }
        try registerSQLiteVecAutoExtension()
        didRegister = true
      }
    #endif
  }
}

extension Trait where Self == _SQLiteVecAutoExtensionTrait {
  /// Registers sqlite-vec process-wide on non-Apple platforms; does nothing on Apple platforms.
  ///
  /// Registration happens once per process. On Apple platforms, prepare each connection with
  /// `Configuration.prepareSQLiteVecExtension()`. The trait can stay on cross-platform suites.
  ///
  /// ```swift
  /// import SQLiteVecData
  /// import SQLiteVecDataTestSupport
  /// import Testing
  ///
  /// @Suite(.sqliteVecAutoExtension)
  /// struct `Auto Extension Vector tests` {
  ///   @Test
  ///   func `Creates A Vector Table`() throws {
  ///     var configuration = Configuration()
  ///     #if canImport(Darwin)
  ///       configuration.prepareSQLiteVecExtension()
  ///     #endif
  ///     let database = try DatabaseQueue(configuration: configuration)
  ///     try database.write { db in
  ///       try db.execute(sql: "CREATE VIRTUAL TABLE embeddings USING vec0(embedding float[3])")
  ///     }
  ///   }
  /// }
  /// ```
  public static var sqliteVecAutoExtension: Self {
    Self()
  }
}
