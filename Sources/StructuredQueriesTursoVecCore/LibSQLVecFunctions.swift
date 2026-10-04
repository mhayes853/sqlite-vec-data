import StructuredQueriesCore

/// Vector SQL functions for libSQL, including Turso Cloud databases running libSQL.
///
/// These helpers follow the [vector documentation](https://docs.turso.tech/features/ai-and-embeddings).
/// Convert JSON explicitly before distance comparisons, using the same format on both sides.
/// The database checks dimensions and value-dependent restrictions.
public enum LibSQLVec {
  /// Converts JSON or a supported vector blob to a 32-bit floating-point vector with `vector32`.
  public static func vector32(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    Self.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Converts a vector with `vector32`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  public static func vector32<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float32 {
    SQLQueryExpression("vector32(\(expression))")
  }

  /// Converts JSON or a supported vector blob to a 64-bit floating-point vector with `vector64`.
  public static func vector64(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Double].VectorBytesRepresentation> {
    Self.vector64(expression, as: [Double].VectorBytesRepresentation.self)
  }

  /// Converts a vector with `vector64`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  public static func vector64<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float64 {
    SQLQueryExpression("vector64(\(expression))")
  }

  /// Converts JSON or a supported vector blob to a half-precision vector with `vector16`.
  public static func vector16(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float16].VectorBytesRepresentation> {
    Self.vector16(expression, as: [Float16].VectorBytesRepresentation.self)
  }

  /// Converts a vector with `vector16`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  public static func vector16<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float16 {
    SQLQueryExpression("vector16(\(expression))")
  }

  /// Converts JSON or a supported vector blob to a bfloat16 vector with `vectorb16`.
  public static func vectorb16(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].BFloat16Representation> {
    Self.vectorb16(expression, as: [Float].BFloat16Representation.self)
  }

  /// Converts a vector with `vectorb16`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  public static func vectorb16<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.BFloat16 {
    SQLQueryExpression("vectorb16(\(expression))")
  }

  /// Converts JSON or a supported vector blob to a quantized float8 vector with `vector8`.
  public static func vector8(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].Float8Representation> {
    Self.vector8(expression, as: [Float].Float8Representation.self)
  }

  /// Converts a vector with `vector8`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  public static func vector8<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.Float8 {
    SQLQueryExpression("vector8(\(expression))")
  }

  /// Converts JSON or a supported vector blob to a binary vector with `vector1bit`.
  public static func vector1bit(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation> {
    Self.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  }

  /// Converts a vector with `vector1bit`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  public static func vector1bit<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.TursoBits {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  /// Converts JSON or a supported vector blob to float32 using the `vector` alias.
  public static func vector(
    _ expression: some QueryExpression
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    SQLQueryExpression("vector(\(expression))")
  }

  /// Extracts a supported vector blob as a JSON array string with `vector_extract`.
  public static func extract(
    _ expression: some QueryExpression
  ) -> some QueryExpression<String> {
    SQLQueryExpression("vector_extract(\(expression))")
  }

  /// Returns cosine distance (`1 - cosine similarity`) between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 32-bit floating-point format.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float32, L.Format == R.Format {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns cosine distance (`1 - cosine similarity`) between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 64-bit floating-point format.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float64, L.Format == R.Format {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns cosine distance (`1 - cosine similarity`) between matching vectors.
  /// The database requires equal dimensions. Both operands must use the half-precision format.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float16, L.Format == R.Format {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns cosine distance (`1 - cosine similarity`) between matching vectors.
  /// The database requires equal dimensions. Both operands must use the bfloat16 format.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.BFloat16, L.Format == R.Format {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns cosine distance (`1 - cosine similarity`) between matching vectors.
  /// The database requires equal dimensions. Both operands must use the quantized float8 format.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float8, L.Format == R.Format {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns Hamming distance (the number of differing bits) with `vector_distance_cos`.
  /// The database requires equal dimensions. Both operands must use the binary format.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.TursoBits, L.Format == R.Format {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 32-bit floating-point format.
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float32, L.Format == R.Format {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 64-bit floating-point format.
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float64, L.Format == R.Format {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the half-precision format.
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float16, L.Format == R.Format {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the bfloat16 format.
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.BFloat16, L.Format == R.Format {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the quantized float8 format.
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float8, L.Format == R.Format {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Marks a 32-bit floating-point column for a libSQL DiskANN index with `libsql_vector_idx`.
  /// Use only inside `CREATE INDEX`. Settings are escaped SQL literals such as `metric=l2`.
  public static func index<Column: TableColumnExpression>(
    _ column: Column,
    settings: [String] = []
  ) -> some QueryExpression<Void>
  where
    Column.Value: VectorBytesRepresentable & QueryBindable,
    Column.Value.Format == VectorFormat.Float32
  {
    vectorIndex(columnName: column.name, settings: settings)
  }

  /// Marks a 64-bit floating-point column for a libSQL DiskANN index with `libsql_vector_idx`.
  /// Use only inside `CREATE INDEX`. Settings are escaped SQL literals such as `metric=l2`.
  public static func index<Column: TableColumnExpression>(
    _ column: Column,
    settings: [String] = []
  ) -> some QueryExpression<Void>
  where
    Column.Value: VectorBytesRepresentable & QueryBindable,
    Column.Value.Format == VectorFormat.Float64
  {
    vectorIndex(columnName: column.name, settings: settings)
  }

  /// Marks a half-precision column for a libSQL DiskANN index with `libsql_vector_idx`.
  /// Use only inside `CREATE INDEX`. Settings are escaped SQL literals such as `metric=l2`.
  public static func index<Column: TableColumnExpression>(
    _ column: Column,
    settings: [String] = []
  ) -> some QueryExpression<Void>
  where
    Column.Value: VectorBytesRepresentable & QueryBindable,
    Column.Value.Format == VectorFormat.Float16
  {
    vectorIndex(columnName: column.name, settings: settings)
  }

  /// Marks a bfloat16 column for a libSQL DiskANN index with `libsql_vector_idx`.
  /// Use only inside `CREATE INDEX`. Settings are escaped SQL literals such as `metric=l2`.
  public static func index<Column: TableColumnExpression>(
    _ column: Column,
    settings: [String] = []
  ) -> some QueryExpression<Void>
  where
    Column.Value: VectorBytesRepresentable & QueryBindable,
    Column.Value.Format == VectorFormat.BFloat16
  {
    vectorIndex(columnName: column.name, settings: settings)
  }

  /// Marks a quantized float8 column for a libSQL DiskANN index with `libsql_vector_idx`.
  /// Use only inside `CREATE INDEX`. Settings are escaped SQL literals such as `metric=l2`.
  public static func index<Column: TableColumnExpression>(
    _ column: Column,
    settings: [String] = []
  ) -> some QueryExpression<Void>
  where
    Column.Value: VectorBytesRepresentable & QueryBindable,
    Column.Value.Format == VectorFormat.Float8
  {
    vectorIndex(columnName: column.name, settings: settings)
  }

  /// Marks a binary column for a libSQL DiskANN index with `libsql_vector_idx`.
  /// Use only inside `CREATE INDEX`. Settings are escaped SQL literals such as `metric=l2`.
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
