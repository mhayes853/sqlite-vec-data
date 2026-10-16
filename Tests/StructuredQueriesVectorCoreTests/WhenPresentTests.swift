import CustomDump
import StructuredQueriesCore
import StructuredQueriesVectorCore
import Testing

@Suite
struct `whenPresent tests` {
  @Test
  func `Generic Guards Preserve Binding Order And One Optional Layer`() {
    let value = "can't truncate bindings"
    let text: String? = value
    let length: Int? = 4
    let count = text.whenPresent { SQLQueryExpression<Int>("length(\($0))") }
    let nonemptyCount = text.whenPresent { SQLQueryExpression<Int?>("nullif(length(\($0)), 0)") }
    let prefix = text.whenPresent(length) {
      SQLQueryExpression<String>("substr(\($0), 1, \($1))")
    }
    let nonemptyPrefix = text.whenPresent(length) {
      SQLQueryExpression<String?>("nullif(substr(\($0), 1, \($1)), '')")
    }
    requireOptionalInt(count)
    requireOptionalInt(nonemptyCount)
    requireOptionalString(prefix)
    requireOptionalString(nonemptyPrefix)
    let unary = [count.queryFragment, nonemptyCount.queryFragment]
      .map {
        $0.prepare { "?\($0)" }
      }
    expectNoDifference(
      unary.map(\.sql),
      [
        "CASE WHEN (?1) IS NULL THEN NULL ELSE length(?2) END",
        "CASE WHEN (?1) IS NULL THEN NULL ELSE nullif(length(?2), 0) END"
      ]
    )
    expectNoDifference(
      unary.map(\.bindings),
      Array(repeating: [.text(value), .text(value)], count: 2)
    )
    let paired = [prefix.queryFragment, nonemptyPrefix.queryFragment]
      .map {
        $0.prepare { "?\($0)" }
      }
    expectNoDifference(
      paired.map(\.sql),
      [
        "CASE WHEN (?1) IS NULL OR (?2) IS NULL THEN NULL ELSE substr(?3, 1, ?4) END",
        "CASE WHEN (?1) IS NULL OR (?2) IS NULL THEN NULL ELSE nullif(substr(?3, 1, ?4), '') END"
      ]
    )
    expectNoDifference(
      paired.map(\.bindings),
      Array(repeating: [.text(value), .int(4), .text(value), .int(4)], count: 2)
    )
  }
}

private func requireOptionalInt(_ expression: some QueryExpression<Int?>) {}
private func requireOptionalString(_ expression: some QueryExpression<String?>) {}
