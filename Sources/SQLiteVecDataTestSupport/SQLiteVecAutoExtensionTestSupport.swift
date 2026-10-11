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
  /// Registers sqlite-vec as a process-global auto extension for non-Apple test suites.
  ///
  /// Use this trait on suites that need `vec0` available before opening SQLite connections. The
  /// registration happens exactly once per process. For tests that also run on Apple platforms,
  /// use `Configuration.prepareSQLiteVecExtension()` to load the extension into each connection.
  ///
  /// ```swift
  /// #if !canImport(Darwin)
  ///   import SQLiteVecData
  ///   import SQLiteVecDataTestSupport
  ///   import Testing
  ///
  ///   @Suite(.sqliteVecAutoExtension)
  ///   struct `Auto Extension Vector tests` {
  ///     @Test
  ///     func `Creates A Vector Table`() throws {
  ///       let database = try DatabaseQueue()
  ///       try database.write { db in
  ///         try db.execute(sql: "CREATE VIRTUAL TABLE embeddings USING vec0(embedding float[3])")
  ///       }
  ///     }
  ///   }
  /// #endif
  /// ```
  @available(
    macOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVecExtension() for each connection."
  )
  @available(
    iOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVecExtension() for each connection."
  )
  @available(
    tvOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVecExtension() for each connection."
  )
  @available(
    watchOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVecExtension() for each connection."
  )
  @available(
    visionOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVecExtension() for each connection."
  )
  public static var sqliteVecAutoExtension: Self {
    Self()
  }
}
