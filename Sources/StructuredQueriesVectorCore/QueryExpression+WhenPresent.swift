import StructuredQueriesCore

// Swift selects the more-specific nullable-result overloads to avoid nested optionals.
// swift-format-ignore: AmbiguousTrailingClosureOverload
extension QueryExpression {
  /// Transforms a nullable expression when its SQL value is present.
  ///
  /// The closure builds SQL using a nonoptional expression. A `CASE` guard skips that SQL when
  /// the input is NULL. This works with any query value, including strings, numbers, and vectors.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var title: String?
  /// }
  /// let query = Document.select {
  ///   $0.title.whenPresent { title in SQLQueryExpression<Int>("length(\(title))") }
  /// }
  /// // SELECT CASE WHEN ("documents"."title") IS NULL THEN NULL ELSE length("documents"."title") END
  /// // FROM "documents"
  /// ```
  ///
  /// The closure runs during query construction, not once per database row. Input expressions
  /// appear in the guard and may also appear in the result, so use stable input expressions.
  @inlinable
  public func whenPresent<Value, Result>(
    _ transform: (SQLQueryExpression<Value>) -> some QueryExpression<Result>
  ) -> some QueryExpression<Result?> where QueryValue == Value? {
    let result = transform(SQLQueryExpression<Value>(self.queryFragment))
    return SQLQueryExpression<Result?>(
      "CASE WHEN (\(self)) IS NULL THEN NULL ELSE \(result) END"
    )
  }

  /// Transforms a nullable expression, preserving an already-nullable result.
  ///
  /// Both a missing input and a NULL result decode as nil, without adding another optional layer.
  /// Unlike StructuredQueries' `flatMap`, this helper guards the transformed SQL against NULL inputs.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var title: String?
  /// }
  /// let query = Document.select {
  ///   $0.title.whenPresent { title in
  ///     SQLQueryExpression<Int?>("nullif(length(\(title)), 0)")
  ///   }
  /// }
  /// // SELECT CASE WHEN ("documents"."title") IS NULL THEN NULL ELSE nullif(length("documents"."title"), 0) END
  /// // FROM "documents"
  /// ```
  @inlinable
  public func whenPresent<Value, Result>(
    _ transform: (SQLQueryExpression<Value>) -> some QueryExpression<Result?>
  ) -> some QueryExpression<Result?> where QueryValue == Value? {
    let result = transform(SQLQueryExpression<Value>(self.queryFragment))
    return SQLQueryExpression<Result?>(
      "CASE WHEN (\(self)) IS NULL THEN NULL ELSE \(result) END"
    )
  }

  /// Transforms two nullable expressions when both SQL values are present.
  ///
  /// Capture nonoptional operands in the closure; only nullable operands need a guard.
  ///
  /// ```swift
  /// @Table("people")
  /// struct Person {
  ///   var firstName: String?
  ///   var lastName: String?
  /// }
  /// let query = Person.select {
  ///   $0.firstName.whenPresent($0.lastName) { first, last in
  ///     SQLQueryExpression<String>("(\(first) || ' ' || \(last))")
  ///   }
  /// }
  /// // SELECT CASE WHEN ("people"."firstName") IS NULL OR ("people"."lastName") IS NULL THEN NULL ELSE ("people"."firstName" || ' ' || "people"."lastName") END
  /// // FROM "people"
  /// ```
  @inlinable
  public func whenPresent<Value, Other, Result>(
    _ other: some QueryExpression<Other?>,
    _ transform: (SQLQueryExpression<Value>, SQLQueryExpression<Other>) -> some QueryExpression<
      Result
    >
  ) -> some QueryExpression<Result?> where QueryValue == Value? {
    let result = transform(
      SQLQueryExpression<Value>(self.queryFragment),
      SQLQueryExpression<Other>(other.queryFragment)
    )
    return SQLQueryExpression<Result?>(
      "CASE WHEN (\(self)) IS NULL OR (\(other)) IS NULL THEN NULL ELSE \(result) END"
    )
  }

  /// Transforms two nullable expressions, preserving an already-nullable result.
  ///
  /// ```swift
  /// @Table("ratios")
  /// struct Ratio {
  ///   var numerator: Int?
  ///   var denominator: Int?
  /// }
  /// let query = Ratio.select {
  ///   $0.numerator.whenPresent($0.denominator) { numerator, denominator in
  ///     SQLQueryExpression<Double?>("(CAST(\(numerator) AS REAL) / nullif(\(denominator), 0))")
  ///   }
  /// }
  /// // SELECT CASE WHEN ("ratios"."numerator") IS NULL OR ("ratios"."denominator") IS NULL THEN NULL ELSE (CAST("ratios"."numerator" AS REAL) / nullif("ratios"."denominator", 0)) END
  /// // FROM "ratios"
  /// ```
  @inlinable
  public func whenPresent<Value, Other, Result>(
    _ other: some QueryExpression<Other?>,
    _ transform: (SQLQueryExpression<Value>, SQLQueryExpression<Other>) -> some QueryExpression<
      Result?
    >
  ) -> some QueryExpression<Result?> where QueryValue == Value? {
    let result = transform(
      SQLQueryExpression<Value>(self.queryFragment),
      SQLQueryExpression<Other>(other.queryFragment)
    )
    return SQLQueryExpression<Result?>(
      "CASE WHEN (\(self)) IS NULL OR (\(other)) IS NULL THEN NULL ELSE \(result) END"
    )
  }
}
