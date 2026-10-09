import CustomDump
import Foundation
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite
struct `SQLiteVecDataTestSupport tests` {
  @Test
  func `Prepares Pool Writers And Readers Alongside Caller Setup`() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    var configuration = Configuration()
    configuration.prepareDatabase { db in
      try db.execute(sql: "PRAGMA cache_size = 42")
    }
    try configuration.prepareSQLiteVec()

    let database = try DatabasePool(
      path: directory.appendingPathComponent("test.sqlite").path,
      configuration: configuration
    )
    defer { try? database.close() }
    let query = #sql(
      "SELECT cache_size, vec_length(vec_f32('[1, 2, 3]')) FROM pragma_cache_size",
      as: (Int, Int).self
    )
    let writer = try database.write { db in
      try db.execute(sql: "CREATE VIRTUAL TABLE vectors USING vec0(embedding float[3])")
      return try query.fetchOne(db)
    }
    let reader = try database.read { db in
      try db.execute(sql: "SELECT * FROM vectors")
      return try query.fetchOne(db)
    }
    for result in [try #require(writer), try #require(reader)] {
      expectNoDifference(result.0, 42)
      expectNoDifference(result.1, 3)
    }
  }

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
