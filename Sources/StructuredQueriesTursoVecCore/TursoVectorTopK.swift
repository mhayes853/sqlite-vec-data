import StructuredQueriesCore

/// A query for the primary keys returned by Turso's `vector_top_k` table-valued function.
///
/// Use ``TursoVec/topK(index:vector:k:)`` to build a query. ``tableFragment`` exposes the
/// table-valued function for joins in SQL, and ``query`` selects its `id` column for structured
/// `IN` subqueries. The function returns identifiers, rather than distances.
///
/// The `id` column belongs to `vector_top_k`, not the indexed table. It contains the indexed
/// row's row ID, or its primary key for a table without row IDs. The base table's primary key
/// can have any name.
public struct TursoVectorTopK<PrimaryKey: QueryRepresentable>:
  Hashable, Sendable, PartialSelectStatement
{
  public typealias QueryValue = PrimaryKey
  public typealias From = Never

  /// The table-valued function, including safely bound index, vector, and neighbor count arguments.
  public let tableFragment: QueryFragment

  /// A select statement for the identifiers returned by the vector search.
  ///
  /// Selects the table-valued function's `id` output column. The indexed table does not need
  /// an `id` column.
  public var query: QueryFragment {
    "SELECT \(quote: "id") FROM \(self.tableFragment)"
  }

  public var queryFragment: QueryFragment {
    self.query
  }

  fileprivate init(tableFragment: QueryFragment) {
    self.tableFragment = tableFragment
  }
}

extension TursoVec {
  /// Searches a vector index for `k` approximate nearest neighbors with `vector_top_k`.
  ///
  /// ```swift
  /// let neighbors = TursoVec.topK(
  ///   index: "movies_idx",
  ///   vector: TursoVec.vector32("[0.064, 0.777, 0.661, 0.687]"),
  ///   k: 3
  /// )
  /// let query = Movie
  ///   .where { $0.rowid.in(neighbors) && $0.year.gte(2020) }
  ///   .select { ($0.title, $0.year) }
  /// ```
  ///
  /// A filter on the base table is applied after finding the `k` neighbors, so fewer than `k`
  /// rows may survive. An `IN` subquery does not preserve the index's result order. Use a distance
  /// expression in `order` when ordering is required.
  ///
  /// - Parameters:
  ///   - index: The name of an existing vector index.
  ///   - vector: A query vector of the same type and dimensionality as the index's column.
  ///   - k: The positive number of approximate neighbors to request.
  /// - Returns: A query for integer row IDs or primary keys.
  public static func topK(
    index: String,
    vector: some QueryExpression,
    k: some QueryExpression<Int>
  ) -> TursoVectorTopK<Int> {
    Self.topK(index: index, vector: vector, k: k, as: Int.self)
  }

  /// Searches a vector index whose base table uses the requested primary key representation.
  ///
  /// This calls Turso's `vector_top_k` function. The index must belong to a table with a row ID
  /// or a single primary key; composite primary keys without a row ID are unsupported.
  ///
  /// - Parameters:
  ///   - index: The name of an existing vector index.
  ///   - vector: A query vector of the same type and dimensionality as the index's column.
  ///   - k: The positive number of approximate neighbors to request.
  ///   - primaryKey: The query representation of the base table's primary key.
  /// - Returns: A query for primary keys in the requested representation.
  public static func topK<PrimaryKey: QueryRepresentable>(
    index: String,
    vector: some QueryExpression,
    k: some QueryExpression<Int>,
    as primaryKey: PrimaryKey.Type
  ) -> TursoVectorTopK<PrimaryKey> {
    TursoVectorTopK(tableFragment: "vector_top_k(\(bind: index), \(vector), \(k))")
  }
}
