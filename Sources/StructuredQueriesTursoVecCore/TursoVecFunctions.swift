import StructuredQueriesCore

/// A namespace for Turso/libSQL's native vector SQL functions.
///
/// These helpers generate SQL for the functions documented in Turso's
/// [AI & Embeddings guide](https://docs.turso.tech/features/ai-and-embeddings). They require a
/// database engine with native vector support.
public enum TursoVec {
  /// Converts a JSON or vector blob expression to a 32-bit float vector.
  /// This calls Turso's `vector32` function.
  ///
  /// ```swift
  /// let query = Movie.select {
  ///   TursoVec.vector32("[0.800, 0.579, 0.481, 0.229]")
  /// }
  /// ```
  ///
  /// - Parameter expression: A JSON array string or an encoded vector blob.
  /// - Returns: A query expression decoded as an array of floats.
  public static func vector32(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    Self.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Converts a JSON or vector blob expression to a 32-bit float vector in the requested Swift
  /// representation. This calls Turso's `vector32` function.
  ///
  /// ```swift
  /// let query = Movie.select {
  ///   TursoVec.vector32($0.embedding, as: EmbeddingVector<4>.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A JSON array string or an encoded vector blob.
  ///   - result: A representation that decodes little-endian, 32-bit float bytes.
  /// - Returns: A query expression for the converted vector.
  public static func vector32<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float32 {
    SQLQueryExpression("vector32(\(expression))")
  }

  /// Converts a JSON or vector blob expression to a 32-bit float vector using Turso's `vector`
  /// alias for `vector32`.
  ///
  /// - Parameter expression: A JSON array string or an encoded vector blob.
  /// - Returns: A query expression decoded as an array of floats.
  public static func vector(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    SQLQueryExpression("vector(\(expression))")
  }

  /// Converts a JSON or vector blob expression to a 64-bit vector with `vector64`.
  ///
  /// - Parameter expression: A JSON array string or an encoded vector blob.
  /// - Returns: A query expression decoded as an array of doubles.
  public static func vector64(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Double].VectorBytesRepresentation> {
    Self.vector64(expression, as: [Double].VectorBytesRepresentation.self)
  }

  /// Converts a vector with `vector64`, using a matching array or fixed-size representation.
  /// The representation validates the blob's format and the fixed-size vector's dimensions.
  public static func vector64<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float64 {
    SQLQueryExpression("vector64(\(expression))")
  }

  /// Converts a JSON or vector blob expression to a half-precision vector with `vector16`.
  ///
  /// - Parameter expression: A JSON array string or an encoded vector blob.
  /// - Returns: A query expression decoded as an array of half-precision floats.
  public static func vector16(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float16].VectorBytesRepresentation> {
    Self.vector16(expression, as: [Float16].VectorBytesRepresentation.self)
  }

  /// Converts a vector with `vector16`, using a matching array or fixed-size representation.
  /// The representation validates the blob's format and the fixed-size vector's dimensions.
  public static func vector16<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float16 {
    SQLQueryExpression("vector16(\(expression))")
  }

  /// Converts a JSON or vector blob expression to a bfloat16 vector with `vectorb16`.
  ///
  /// - Parameter expression: A JSON array string or an encoded vector blob.
  /// - Returns: A query expression decoded as an array of floats.
  public static func vectorb16(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].BFloat16Representation> {
    Self.vectorb16(expression, as: [Float].BFloat16Representation.self)
  }

  /// Converts a vector with `vectorb16`, using a matching array or fixed-size representation.
  /// The representation validates the blob's format and the fixed-size vector's dimensions.
  public static func vectorb16<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.BFloat16 {
    SQLQueryExpression("vectorb16(\(expression))")
  }

  /// Converts a JSON or vector blob expression to a quantized 8-bit vector with `vector8`.
  ///
  /// - Parameter expression: A JSON array string or an encoded vector blob.
  /// - Returns: A query expression decoded as an array of reconstructed floats.
  public static func vector8(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].Float8Representation> {
    Self.vector8(expression, as: [Float].Float8Representation.self)
  }

  /// Converts a vector with `vector8`, using a matching array or fixed-size representation.
  /// The representation validates the blob's format and the fixed-size vector's dimensions.
  public static func vector8<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float8 {
    SQLQueryExpression("vector8(\(expression))")
  }

  /// Converts a JSON or vector blob expression to a binary vector with `vector1bit`.
  ///
  /// - Parameter expression: A JSON array string or an encoded vector blob.
  /// - Returns: A query expression decoded as an array of logical bits.
  public static func vector1bit(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation> {
    Self.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  }

  /// Converts a vector with `vector1bit`, using a matching array or fixed-size representation.
  /// The representation validates the blob's format and the fixed-size vector's dimensions.
  public static func vector1bit<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.TursoBits {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  /// Extracts a vector's JSON array string with `vector_extract`.
  ///
  /// ```swift
  /// let query = Movie.select { TursoVec.extract($0.embedding) }
  /// ```
  ///
  /// - Parameter expression: A vector expression to serialize.
  /// - Returns: A query expression for the JSON array string.
  public static func extract(
    _ expression: some QueryExpression
  ) -> some QueryExpression<String> {
    SQLQueryExpression("vector_extract(\(expression))")
  }

  /// Returns cosine distance with `vector_distance_cos`.
  ///
  /// Both vectors must have the same type and dimensionality. Smaller distances indicate more
  /// similar vectors; cosine distance is `1 - cosine similarity`.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.064, 0.777, 0.661, 0.687]
  /// let query = Movie.select {
  ///   TursoVec.distanceCosine($0.embedding, to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: A JSON, blob, or converted vector expression to compare.
  /// - Returns: A query expression for the cosine distance.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where L.Format == R.Format, L.Scalar: BinaryFloatingPoint {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns distance between Turso binary vectors with matching dimensions.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where L.Format == R.Format, L.Format == VectorFormat.TursoBits {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Compares JSON vectors. Their dimensions and format are checked by the database.
  public static func distanceCosine(
    _ expression: some QueryExpression<String>,
    to vector: some QueryExpression<String>
  ) -> some QueryExpression<Double> {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Compares an encoded vector with JSON. The database checks type and dimensionality.
  public static func distanceCosine<L: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<String>
  ) -> some QueryExpression<Double> where L.Scalar: BinaryFloatingPoint {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Compares JSON with an encoded vector. The database checks type and dimensionality.
  public static func distanceCosine<L: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    to vector: some QueryExpression<L>
  ) -> some QueryExpression<Double> where L.Scalar: BinaryFloatingPoint {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Compares Turso binary storage with JSON, with database format and dimension checks.
  public static func distanceCosine<L: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<String>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.TursoBits {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Compares JSON with Turso binary storage, with database format and dimension checks.
  public static func distanceCosine<L: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    to vector: some QueryExpression<L>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.TursoBits {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns Euclidean distance with `vector_distance_l2`.
  ///
  /// Both vectors must have the same type and dimensionality. Turso/libSQL does not support L2
  /// distance for 1-bit vectors.
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: A JSON, blob, or converted vector expression to compare.
  /// - Returns: A query expression for the L2 distance.
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where L.Format == R.Format, L.Scalar: BinaryFloatingPoint {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Compares JSON vectors. Their dimensions and format are checked by the database.
  public static func distanceL2(
    _ expression: some QueryExpression<String>,
    to vector: some QueryExpression<String>
  ) -> some QueryExpression<Double> {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Compares an encoded vector with JSON. The database checks type and dimensionality.
  public static func distanceL2<L: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<String>
  ) -> some QueryExpression<Double> where L.Scalar: BinaryFloatingPoint {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Compares JSON with an encoded vector. The database checks type and dimensionality.
  public static func distanceL2<L: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    to vector: some QueryExpression<L>
  ) -> some QueryExpression<Double> where L.Scalar: BinaryFloatingPoint {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Marks a vector column for a Turso/libSQL vector index with `libsql_vector_idx`.
  ///
  /// This expression is only valid inside `CREATE INDEX` statements.
  ///
  /// ```swift
  /// let index = TursoVec.index(Movie.columns.embedding, settings: ["metric=l2"])
  /// let query = #sql("CREATE INDEX movies_idx ON movies (\(index))", as: Void.self)
  /// ```
  ///
  /// - Parameters:
  ///   - column: The vector column to index.
  ///   - settings: Optional `key=value` strings, such as `metric=l2` or
  ///     `compress_neighbors=float8`. Values are escaped as SQL string literals because index
  ///     definitions cannot contain bound parameters.
  /// - Returns: A marker expression for a vector index.
  public static func index<Column: TableColumnExpression>(
    _ column: Column,
    settings: [String] = []
  ) -> some QueryExpression<Void>
  where
    Column.Value: VectorBytesRepresentable & QueryBindable,
    Column.Value.Scalar: BinaryFloatingPoint
  {
    vectorIndex(columnName: column.name, settings: settings)
  }

  /// Marks a Turso binary column for an index. SQLiteVec packed bits use a different layout.
  public static func index<Column: TableColumnExpression>(
    _ column: Column,
    settings: [String] = []
  ) -> some QueryExpression<Void>
  where
    Column.Value: VectorBytesRepresentable & QueryBindable,
    Column.Value.Format == VectorFormat.TursoBits
  {
    vectorIndex(columnName: column.name, settings: settings)
  }
}

private func vectorIndex(columnName: String, settings: [String]) -> some QueryExpression<Void> {
  let column = QueryFragment(quote: columnName)
  let arguments = ([column] + settings.map { QueryFragment(quote: $0, delimiter: .text) })
    .joined(separator: ", ")
  return SQLQueryExpression("libsql_vector_idx(\(arguments))")
}
