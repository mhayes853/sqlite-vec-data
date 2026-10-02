import StructuredQueriesCore

/// A table with Turso/libSQL native vector columns.
///
/// Conform to this protocol to use column helpers such as `distanceCosine(to:)`, `distanceL2(to:)`,
/// and `toJSON()`. Tables without this conformance can use the ``TursoVec`` namespace directly.
///
/// First, create a table with a native vector column:
///
/// ```sql
/// CREATE TABLE movies (title TEXT, year INT, embedding F32_BLOB(4));
/// ```
///
/// Then, define your table using the `@Table` attribute:
///
/// ```swift
/// @Table("movies")
/// struct Movie: TursoVectorTable {
///   var title: String
///   var year: Int
///   @Column(as: [Float].VectorBytesRepresentation.self)
///   var embedding: [Float]
/// }
/// ```
public protocol TursoVectorTable: Table {}

extension TableColumnExpression
where Root: TursoVectorTable, Value: EncodedVector, Value.Encoding: TursoVectorEncoding {
  /// Returns cosine distance from this column to a vector with the same encoding.
  /// The database also checks that the dimensions match.
  public func distanceCosine<V: EncodedVector>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where Value.Encoding == V.Encoding {
    TursoVec.distanceCosine(self, to: vector)
  }

  /// Returns cosine distance from this column to JSON, with database format and dimension checks.
  public func distanceCosine(
    to vector: some QueryExpression<String>
  ) -> some QueryExpression<Double> {
    TursoVec.distanceCosine(self, to: vector)
  }

  /// Extracts this column's vector as a JSON array string with `vector_extract`.
  public func toJSON() -> some QueryExpression<String> {
    TursoVec.extract(self)
  }
}

extension TableColumnExpression
where
  Root: TursoVectorTable, Value: EncodedVector,
  Value.Encoding: TursoVectorEncoding & L2VectorEncoding
{
  /// Returns Euclidean distance from this column to a vector with the same encoding.
  /// Binary vector representations do not offer this operation.
  public func distanceL2<V: EncodedVector>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where Value.Encoding == V.Encoding {
    TursoVec.distanceL2(self, to: vector)
  }

  /// Returns Euclidean distance from this column to JSON, with database format and dimension checks.
  public func distanceL2(
    to vector: some QueryExpression<String>
  ) -> some QueryExpression<Double> {
    TursoVec.distanceL2(self, to: vector)
  }
}
