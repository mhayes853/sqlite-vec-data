import CustomDump
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
