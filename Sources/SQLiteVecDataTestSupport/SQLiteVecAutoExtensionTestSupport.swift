import SQLiteVecData
import Testing

public struct _SQLiteVecAutoExtensionTrait: SuiteTrait {
  private static let didRegisterSQLiteVecAutoExtension = Lock(false)

  public func prepare(for test: Test) async throws {
    try Self.registerIfNeeded()
  }

  static func registerIfNeeded() throws {
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
  /// use `Configuration.prepareSQLiteVec()` to load the extension into each connection.
  ///
  /// ```swift
  /// import SQLiteVecDataTestSupport
  /// import Testing
  ///
  /// @Suite(.sqliteVecAutoExtension)
  /// struct `Vector tests` {
  ///   // ...
  /// }
  /// ```
  @available(
    macOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVec() for each connection."
  )
  @available(iOS, unavailable, message: "Use Configuration.prepareSQLiteVec() for each connection.")
  @available(
    tvOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVec() for each connection."
  )
  @available(
    watchOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVec() for each connection."
  )
  @available(
    visionOS,
    unavailable,
    message: "Use Configuration.prepareSQLiteVec() for each connection."
  )
  public static var sqliteVecAutoExtension: Self {
    Self()
  }
}
