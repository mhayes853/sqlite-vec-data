import StructuredQueriesCore

/// Vector SQL functions for Turso Database (the Rust engine).
///
/// These helpers follow the [vector documentation](https://docs.turso.tech/sql-reference/functions/vector).
/// Convert JSON explicitly before distance comparisons, using the same format on both sides.
/// The database checks dimensions and value-dependent restrictions.
public enum TursoVec {
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

  /// Converts JSON or a supported vector blob to a quantized float8 vector with `vector8`.
  public static func vector8(
    _ expression: some QueryExpression
  ) -> some QueryExpression<Quantized8Vector> {
    Self.vector8(expression, as: Quantized8Vector.self)
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

  /// Converts JSON or a supported vector blob to a sparse float32 vector with `vector32_sparse`.
  public static func vector32Sparse(
    _ expression: some QueryExpression
  ) -> some QueryExpression<SparseFloat32Vector> {
    Self.vector32Sparse(expression, as: SparseFloat32Vector.self)
  }

  /// Converts a vector with `vector32_sparse`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  public static func vector32Sparse<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Format == VectorFormat.SparseFloat32 {
    SQLQueryExpression("vector32_sparse(\(expression))")
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

  /// Returns cosine distance (`1 - cosine similarity`) between matching vectors.
  /// The database requires equal dimensions. Both operands must use the sparse float32 format.
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where L.Format == VectorFormat.SparseFloat32, L.Format == R.Format {
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

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the sparse float32 format.
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where L.Format == VectorFormat.SparseFloat32, L.Format == R.Format {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns the negative dot product between matching vectors; lower values are closer.
  /// The database requires equal dimensions. Both operands must use the 32-bit floating-point format.
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float32, L.Format == R.Format {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Returns the negative dot product between matching vectors; lower values are closer.
  /// The database requires equal dimensions. Both operands must use the 64-bit floating-point format.
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float64, L.Format == R.Format {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Returns the negative dot product between matching vectors; lower values are closer.
  /// The database requires equal dimensions. Both operands must use the quantized float8 format.
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float8, L.Format == R.Format {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Returns the negative dot product of the binary vectors interpreted as +1/-1.
  /// The database requires equal dimensions. Both operands must use the binary format.
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.TursoBits, L.Format == R.Format {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Returns the negative dot product between matching vectors; lower values are closer.
  /// The database requires equal dimensions. Both operands must use the sparse float32 format.
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where L.Format == VectorFormat.SparseFloat32, L.Format == R.Format {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Returns weighted Jaccard distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 32-bit floating-point format.
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float32, L.Format == R.Format {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Returns weighted Jaccard distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 64-bit floating-point format.
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float64, L.Format == R.Format {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Returns weighted Jaccard distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the quantized float8 format.
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.Float8, L.Format == R.Format {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Returns binary Jaccard distance (`1 - intersection / union`) over set bits.
  /// The database requires equal dimensions. Both operands must use the binary format.
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double> where L.Format == VectorFormat.TursoBits, L.Format == R.Format {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Returns weighted Jaccard distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the sparse float32 format.
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where L.Format == VectorFormat.SparseFloat32, L.Format == R.Format {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Returns an array representation so the output dimension count can change.
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where L.Format == VectorFormat.Float32, L.Format == R.Format {
    Self.concat(expression, vector, as: [Float].VectorBytesRepresentation.self)
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where L.Format == VectorFormat.Float32, L.Format == R.Format, T.Format == L.Format {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Returns an array representation so the output dimension count can change.
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Double].VectorBytesRepresentation>
  where L.Format == VectorFormat.Float64, L.Format == R.Format {
    Self.concat(expression, vector, as: [Double].VectorBytesRepresentation.self)
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where L.Format == VectorFormat.Float64, L.Format == R.Format, T.Format == L.Format {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Format == VectorFormat.Float32 {
    Self.slice(expression, from: start, to: end, as: [Float].VectorBytesRepresentation.self)
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where V.Format == VectorFormat.Float32, T.Format == V.Format {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Double].VectorBytesRepresentation>
  where V.Format == VectorFormat.Float64 {
    Self.slice(expression, from: start, to: end, as: [Double].VectorBytesRepresentation.self)
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where V.Format == VectorFormat.Float64, T.Format == V.Format {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<SparseFloat32Vector>
  where V.Format == VectorFormat.SparseFloat32 {
    Self.slice(expression, from: start, to: end, as: SparseFloat32Vector.self)
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where V.Format == VectorFormat.SparseFloat32, T.Format == V.Format {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }
}
