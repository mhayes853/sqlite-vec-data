import CustomDump
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite
struct `SQLiteVecDataTestSupport tests` {
  @Test
  func `Lock Destroys Its Noncopyable Value When Unwinding`() {
    weak var reference: Reference?
    #expect(throws: Failure.expected) {
      let value = Reference()
      reference = value
      let lock = Lock(Resource(reference: value))
      try lock.withLock { _ in throw Failure.expected }
    }
    expectNoDifference(reference == nil, true)
  }
}

private final class Reference: Sendable {}

private struct Resource: ~Copyable, Sendable {
  let reference: Reference
}

private enum Failure: Error {
  case expected
}

#if canImport(Darwin)
  @Suite(.sqliteVecAutoExtension)
  struct `Apple auto extension tests` {
    @Test
    func `Requires Connection Preparation Even With The Suite Trait`() throws {
      let unconfigured = try DatabaseQueue()
      #expect(throws: DatabaseError.self) {
        try unconfigured.read { db in
          try db.execute(sql: "SELECT vec_version()")
        }
      }

      var configuration = Configuration()
      configuration.prepareSQLiteVecExtension()
      let configured = try DatabaseQueue(configuration: configuration)
      let count = try configured.read { db in
        try #sql("SELECT vec_length('[1, 2, 3]')", as: Int.self).fetchOne(db)
      }
      expectNoDifference(count, 3)
    }
  }
#endif
