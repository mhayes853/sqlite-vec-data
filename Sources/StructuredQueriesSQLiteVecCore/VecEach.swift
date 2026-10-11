import StructuredQueriesCore

/// A table representation for `vec_each` over Float32 vectors.
///
/// ```swift
/// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
/// let query = Vec.each(vector).select { ($0.rowid, $0.value) }
/// // SELECT "vec_each"."rowid", "vec_each"."value"
/// // FROM "vec_each"
/// // WHERE ("vec_each"."vector" = ?)
/// ```
public typealias VecEach = VecEachOf<Float>

/// A table representation for `vec_each`.
///
/// The element type matches the storage class SQLiteVec reports for each encoding: Float32
/// vectors yield ``VecEach`` (`VecEachOf<Float>`), Int8 vectors yield `VecEachOf<Int8>`, and
/// packed-bit vectors yield `VecEachOf<Bool>`.
///
/// ```swift
/// let query =
///   Embedding
///   .join(Embedding.columns.embedding.vecEach()) { _, _ in true }
///   .select { embedding, element in
///     (embedding.label, element.rowid, element.value)
///   }
/// // SELECT "Embeddings"."label", "vec_each"."rowid", "vec_each"."value"
/// // FROM "Embeddings"
/// // JOIN "vec_each"
/// // ON ?
/// // WHERE ("vec_each"."vector" = "Embeddings"."embedding")
/// ```
///
/// Do not use static table entry points directly because `vec_each` requires its hidden `vector`
/// column to be constrained:
///
/// ```swift
/// // ❌ Invalid: No vector was provided to SQLite Vec.
/// let query = VecEach.all
/// // SELECT "vec_each"."rowid", "vec_each"."value" FROM "vec_each"
/// ```
///
/// In debug builds, using this invalid entry point triggers a precondition failure.
public struct VecEachOf<Value>: Hashable, Sendable, Table
where Value: QueryBindable & QueryDecodable & Hashable & Sendable, Value.QueryOutput == Value {
  public static var tableName: String { "vec_each" }

  public static var columns: TableColumns { TableColumns() }

  public static var _columnWidth: Int { 2 }

  #if DEBUG
    public static var all: Where<Self> {
      Self.checkedUnscoped
    }

    public static var unscoped: Where<Self> {
      Self.checkedUnscoped
    }

    private static var checkedUnscoped: Where<Self> {
      guard isBuildingVecEachStatement else {
        preconditionFailure(
          """
          VecEachOf cannot be queried through static table entry points because vec_each \
          requires its hidden vector column. Use vecEach() or Vec.each(_:) instead.
          """
        )
      }
      return uncheckedUnscoped(Self.self)
    }
  #endif

  /// The zero-based index of the current vector element.
  ///
  /// ```swift
  /// func positions(_ rows: [VecEach]) -> [Int] {
  ///   rows.map(\.rowid)
  /// }
  /// ```
  public let rowid: Int

  /// The current vector element.
  ///
  /// ```swift
  /// func components(_ rows: [VecEach]) -> [Float] {
  ///   rows.map(\.value)
  /// }
  /// ```
  public let value: Value

  public struct TableColumns: Sendable, TableDefinition {
    public typealias QueryValue = VecEachOf<Value>

    public static var allColumns: [any TableColumnExpression] {
      [TableColumns().rowid, TableColumns().value]
    }

    public static var writableColumns: [any WritableTableColumnExpression] { [] }

    /// The zero-based index of the current vector element.
    /// Selects the zero-based component positions.
    ///
    /// ```swift
    /// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
    /// let query = Vec.each(vector).select { $0.rowid }
    /// // SELECT "vec_each"."rowid"
    /// // FROM "vec_each"
    /// // WHERE ("vec_each"."vector" = ?)
    /// ```
    public var rowid: GeneratedColumn<VecEachOf<Value>, Int> {
      GeneratedColumn("rowid", keyPath: \VecEachOf<Value>.rowid)
    }

    /// The current vector element.
    /// Selects the logical vector components.
    ///
    /// ```swift
    /// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
    /// let query = Vec.each(vector).select { $0.value }
    /// // SELECT "vec_each"."value"
    /// // FROM "vec_each"
    /// // WHERE ("vec_each"."vector" = ?)
    /// ```
    public var value: GeneratedColumn<VecEachOf<Value>, Value> {
      GeneratedColumn("value", keyPath: \VecEachOf<Value>.value)
    }
  }

  public struct Selection: TableExpression {
    public typealias QueryValue = VecEachOf<Value>

    public var allColumns: [any QueryExpression]

    public init(allColumns: [any QueryExpression]) {
      self.allColumns = allColumns
    }
  }
}

extension VecEachOf: QueryRepresentable {
  public typealias QueryOutput = VecEachOf<Value>
}

extension VecEachOf: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(
      rowid: Int(decoder: &decoder),
      value: Value(decoder: &decoder)
    )
  }
}

extension Vec {
  /// A select statement that iterates over the elements of a vector expression using SQLite Vec's
  /// `vec_each` virtual table.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 3]
  /// let query = Vec.each(vector)
  ///   .order { $0.rowid }
  ///   .select { ($0.rowid, $0.value) }
  /// // SELECT "vec_each"."rowid", "vec_each"."value"
  /// // FROM "vec_each"
  /// // WHERE ("vec_each"."vector" = ?)
  /// // ORDER BY "vec_each"."rowid"
  /// ```
  ///
  /// - Parameter expression: The vector expression to iterate over.
  /// - Returns: A select statement over the vector's indexed elements.
  public static func each<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> SelectOf<VecEach> where V.Encoding == [Float].VectorBytesRepresentation {
    expression.vecEach()
  }
}

extension QueryExpression
where QueryValue: VectorBytesRepresentable, QueryValue.Encoding == [Float].VectorBytesRepresentation
{
  /// A select statement that iterates over the elements of this vector expression using SQLite
  /// Vec's `vec_each` virtual table.
  ///
  /// The statement constrains the virtual table's hidden `vector` column and can be filtered,
  /// ordered, aggregated, and selected from like any other select statement:
  ///
  /// ```swift
  /// let query =
  ///   Embedding
  ///   .where {
  ///     $0.embedding.vecEach()
  ///       .where { $0.value.lt(Float(0)) }
  ///       .exists()
  ///   }
  ///   .select(\.label)
  /// // SELECT "Embeddings"."label"
  /// // FROM "Embeddings"
  /// // WHERE (EXISTS (SELECT "vec_each"."rowid", "vec_each"."value" FROM "vec_each" WHERE
  /// //   ("vec_each"."vector" = "Embeddings"."embedding") AND (("vec_each"."value") < (?))))
  /// ```
  ///
  /// - Returns: A select statement over the vector's indexed elements.
  public func vecEach() -> SelectOf<VecEach> {
    vecEachStatement(vector: self.queryFragment)
  }
}

extension Vec {
  /// Iterates over the logical bits of a packed-bit vector using `vec_each`.
  /// Within each byte, SQLiteVec reports the most significant bit first.
  /// Each element's `value` is an integer `0` or `1`, decoded as a `Bool`.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let query = Vec.each(vector).select { ($0.rowid, $0.value) }
  /// // SELECT "vec_each"."rowid", "vec_each"."value"
  /// // FROM "vec_each"
  /// // WHERE ("vec_each"."vector" = vec_bit(?))
  /// ```
  public static func each<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> SelectOf<VecEachOf<Bool>> where V.Encoding == [Bool].PackedBitsRepresentation {
    expression.vecEach()
  }
}

extension QueryExpression
where QueryValue: VectorBytesRepresentable, QueryValue.Encoding == [Bool].PackedBitsRepresentation {
  /// Iterates over a packed-bit vector, applying SQLiteVec's binary subtype.
  /// Within each byte, SQLiteVec's `vec_each` reports the most significant bit first.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let query = vector.vecEach().select { ($0.rowid, $0.value) }
  /// // SELECT "vec_each"."rowid", "vec_each"."value"
  /// // FROM "vec_each"
  /// // WHERE ("vec_each"."vector" = vec_bit(?))
  /// ```
  public func vecEach() -> SelectOf<VecEachOf<Bool>> {
    vecEachStatement(vector: "vec_bit(\(self))")
  }
}

extension Vec {
  /// Iterates over signed Int8 components using SQLiteVec's `vec_each`.
  /// Each element's `value` is an integer, decoded as an `Int8`.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let query = Vec.each(vector).select { ($0.rowid, $0.value) }
  /// // SELECT "vec_each"."rowid", "vec_each"."value"
  /// // FROM "vec_each"
  /// // WHERE ("vec_each"."vector" = vec_int8(?))
  /// ```
  public static func each<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> SelectOf<VecEachOf<Int8>> where V.Encoding == [Int8].Int8BytesRepresentation {
    expression.vecEach()
  }
}

extension QueryExpression
where QueryValue: VectorBytesRepresentable, QueryValue.Encoding == [Int8].Int8BytesRepresentation {
  /// Iterates over signed Int8 components, applying SQLiteVec's required subtype.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let query = vector.vecEach().select { ($0.rowid, $0.value) }
  /// // SELECT "vec_each"."rowid", "vec_each"."value"
  /// // FROM "vec_each"
  /// // WHERE ("vec_each"."vector" = vec_int8(?))
  /// ```
  public func vecEach() -> SelectOf<VecEachOf<Int8>> {
    vecEachStatement(vector: "vec_int8(\(self))")
  }
}

// MARK: - Helpers

private func vecEachStatement<Value>(vector: QueryFragment) -> SelectOf<VecEachOf<Value>>
where Value: QueryBindable & QueryDecodable & Hashable & Sendable, Value.QueryOutput == Value {
  func statement() -> SelectOf<VecEachOf<Value>> {
    VecEachOf<Value>.where { _ in
      SQLQueryExpression("\(VecEachOf<Value>.self).\(quote: "vector") = \(vector)")
    }
    .asSelect()
  }
  #if DEBUG
    return $isBuildingVecEachStatement.withValue(true) { statement() }
  #else
    return statement()
  #endif
}

#if DEBUG
  @TaskLocal private var isBuildingVecEachStatement = false

  private func uncheckedUnscoped<TableType: Table>(_ table: TableType.Type) -> Where<TableType> {
    table.unscoped
  }
#endif
