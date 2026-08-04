import StructuredQueriesCore

/// A table representation for `vec_each`.
///
/// ```swift
/// let query = Embedding
///   .join(Embedding.columns.embedding.vecEach()) { _, _ in true }
///   .select { embedding, element in
///     (embedding.label, element.rowid, element.value)
///   }
/// ```
///
/// Do not use static table entry points directly because `vec_each` requires its hidden `vector`
/// column to be constrained:
///
/// ```swift
/// // ❌ Invalid: No vector was provided to SQLite Vec.
/// let query = VecEach.all
/// ```
///
/// In debug builds, using this invalid entry point triggers a precondition failure.
public struct VecEach: Hashable, Sendable, Table {
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
          VecEach cannot be queried through static table entry points because vec_each requires \
          its hidden vector column. Use vecEach() or Vec.each(_:) instead.
          """
        )
      }
      return uncheckedUnscoped(Self.self)
    }
  #endif

  /// The zero-based index of the current vector element.
  public let rowid: Int

  /// The current vector element.
  public let value: Float

  public struct TableColumns: Sendable, TableDefinition {
    public typealias QueryValue = VecEach

    public static var allColumns: [any TableColumnExpression] {
      [TableColumns().rowid, TableColumns().value]
    }

    public static var writableColumns: [any WritableTableColumnExpression] { [] }

    /// The zero-based index of the current vector element.
    public var rowid: GeneratedColumn<VecEach, Int> {
      GeneratedColumn("rowid", keyPath: \VecEach.rowid)
    }

    /// The current vector element.
    public var value: GeneratedColumn<VecEach, Float> {
      GeneratedColumn("value", keyPath: \VecEach.value)
    }
  }

  public struct Selection: TableExpression {
    public typealias QueryValue = VecEach

    public var allColumns: [any QueryExpression]

    public init(allColumns: [any QueryExpression]) {
      self.allColumns = allColumns
    }
  }
}

extension VecEach: QueryRepresentable {
  public typealias QueryOutput = VecEach
}

extension VecEach: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(
      rowid: Int(decoder: &decoder),
      value: Float(decoder: &decoder)
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
  /// ```
  ///
  /// - Parameter expression: The vector expression to iterate over.
  /// - Returns: A select statement over the vector's indexed elements.
  public static func each(
    _ expression: some QueryExpression<some VectorBytesRepresentable>
  ) -> SelectOf<VecEach> {
    expression.vecEach()
  }
}

extension QueryExpression where QueryValue: VectorBytesRepresentable {
  /// A select statement that iterates over the elements of this vector expression using SQLite
  /// Vec's `vec_each` virtual table.
  ///
  /// The statement constrains the virtual table's hidden `vector` column and can be filtered,
  /// ordered, aggregated, and selected from like any other select statement:
  ///
  /// ```swift
  /// let query = Embedding
  ///   .where {
  ///     $0.embedding.vecEach()
  ///       .where { $0.value.lt(Float(0)) }
  ///       .exists()
  ///   }
  ///   .select(\.label)
  /// ```
  ///
  /// - Returns: A select statement over the vector's indexed elements.
  public func vecEach() -> SelectOf<VecEach> {
    #if DEBUG
      $isBuildingVecEachStatement.withValue(true) {
        self.makeVecEachStatement()
      }
    #else
      self.makeVecEachStatement()
    #endif
  }

  private func makeVecEachStatement() -> SelectOf<VecEach> {
    VecEach.where { _ in
      SQLQueryExpression("\(VecEach.self).\(quote: "vector") = \(self)")
    }
    .asSelect()
  }
}

// MARK: - Helpers

#if DEBUG
  @TaskLocal private var isBuildingVecEachStatement = false

  private func uncheckedUnscoped<TableType: Table>(_ table: TableType.Type) -> Where<TableType> {
    table.unscoped
  }
#endif
