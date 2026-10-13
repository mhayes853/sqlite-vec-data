import StructuredQueriesCore

/// Vector SQL functions for Turso Database (the Rust engine).
///
/// These helpers follow the [vector documentation](https://docs.turso.tech/sql-reference/functions/vector).
/// Convert JSON explicitly before distance comparisons, using the same format on both sides.
/// The database checks dimensions and value-dependent restrictions.
///
/// ```swift
/// let distance = TursoVec.distanceCosine(
///   TursoVec.vector32("[1,2,3]"),
///   to: TursoVec.vector32("[3,2,1]")
/// )
/// // vector_distance_cos(vector32(?), vector32(?))
/// ```
public enum TursoVec {
  /// Counts differing binary components with Turso's `vector_distance_cos` specialization.
  /// The database returns an integer-valued REAL and requires equal dimensions.
  /// See [Turso's limitations](https://docs.turso.tech/guides/vector-search#limitations).
  ///
  /// ```swift
  /// let vector = TursoVec.vector1bit("[1,2,3]")
  /// // vector1bit(?)
  /// let expression = TursoVec.distanceHamming(vector, to: TursoVec.vector1bit("[3,2,1]"))
  /// // vector_distance_cos(vector1bit(?), vector1bit(?))
  /// ```
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Bool].TursoBytesRepresentation, R.Encoding == L.Encoding,
    L.Dimensions == R.Dimensions
  {
    Self.distanceCosine(expression, to: vector)
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector1bit("[1,2,3]")
  /// // vector1bit(?)
  /// let expression = TursoVec.distanceHamming(vector, to: TursoVec.vector1bit("[3,2,1]"))
  /// // vector_distance_cos(vector1bit(?), vector1bit(?))
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Bool].TursoBytesRepresentation, R.Encoding == L.Encoding,
    L.Dimensions == Void
  {
    Self.distanceCosine(expression, to: vector)
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector1bit("[1,2,3]")
  /// // vector1bit(?)
  /// let expression = TursoVec.distanceHamming(vector, to: TursoVec.vector1bit("[3,2,1]"))
  /// // vector_distance_cos(vector1bit(?), vector1bit(?))
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Bool].TursoBytesRepresentation, R.Encoding == L.Encoding,
    R.Dimensions == Void
  {
    Self.distanceCosine(expression, to: vector)
  }

  /// Converts JSON to a 32-bit floating-point vector with `vector32`.
  ///
  /// ```swift
  /// let expression = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// ```
  public static func vector32(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    Self.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Converts JSON with `vector32`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let expression = TursoVec.vector32("[1,2,3]", as: EmbeddingVector<3>.self)
  /// // vector32(?)
  /// ```
  public static func vector32<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Float].VectorBytesRepresentation {
    SQLQueryExpression("vector32(\(expression))")
  }

  /// Converts a supported vector BLOB to a 32-bit floating-point vector with `vector32`.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector32(source)
  /// // vector32(vector32(?))
  /// ```
  public static func vector32<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding: TursoVectorEncoding {
    Self.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Converts a supported vector BLOB, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector32(source, as: EmbeddingVector<3>.self)
  /// // vector32(vector32(?))
  /// ```
  public static func vector32<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoVectorEncoding, T.Encoding == [Float].VectorBytesRepresentation {
    SQLQueryExpression("vector32(\(expression))")
  }

  /// Converts JSON to a 64-bit floating-point vector with `vector64`.
  ///
  /// ```swift
  /// let expression = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// ```
  public static func vector64(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation> {
    Self.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  }

  /// Converts JSON with `vector64`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let expression = TursoVec.vector64(
  ///   "[1,2,3]",
  ///   as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self
  /// )
  /// // vector64(?)
  /// ```
  public static func vector64<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Double].TursoFloat64BytesRepresentation {
    SQLQueryExpression("vector64(\(expression))")
  }

  /// Converts a supported vector BLOB to a 64-bit floating-point vector with `vector64`.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector64(source)
  /// // vector64(vector32(?))
  /// ```
  public static func vector64<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation>
  where V.Encoding: TursoVectorEncoding {
    Self.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  }

  /// Converts a supported vector BLOB, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector64(source, as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  /// // vector64(vector32(?))
  /// ```
  public static func vector64<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoVectorEncoding, T.Encoding == [Double].TursoFloat64BytesRepresentation {
    SQLQueryExpression("vector64(\(expression))")
  }

  /// Converts JSON to a quantized float8 vector with `vector8`.
  ///
  /// ```swift
  /// let expression = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// ```
  public static func vector8(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<Quantized8Vector> {
    Self.vector8(expression, as: Quantized8Vector.self)
  }

  /// Converts JSON with `vector8`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let expression = TursoVec.vector8("[1,2,3]", as: InlineQuantized8Vector<3>.self)
  /// // vector8(?)
  /// ```
  public static func vector8<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == Quantized8Vector {
    SQLQueryExpression("vector8(\(expression))")
  }

  /// Converts a supported vector BLOB to a quantized vector with `vector8`.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector8(source)
  /// // vector8(vector32(?))
  /// ```
  public static func vector8<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<Quantized8Vector> where V.Encoding: TursoVectorEncoding {
    Self.vector8(expression, as: Quantized8Vector.self)
  }

  /// Converts a supported vector BLOB, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector8(source, as: InlineQuantized8Vector<3>.self)
  /// // vector8(vector32(?))
  /// ```
  public static func vector8<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoVectorEncoding, T.Encoding == Quantized8Vector {
    SQLQueryExpression("vector8(\(expression))")
  }

  /// Converts JSON to a binary vector with `vector1bit`.
  ///
  /// ```swift
  /// let expression = TursoVec.vector1bit("[1,2,3]")
  /// // vector1bit(?)
  /// ```
  public static func vector1bit(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation> {
    Self.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  }

  /// Converts JSON with `vector1bit`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let expression = TursoVec.vector1bit(
  ///   "[1,2,3]",
  ///   as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self
  /// )
  /// // vector1bit(?)
  /// ```
  public static func vector1bit<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].TursoBytesRepresentation {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  /// Converts a supported vector BLOB to a binary vector with `vector1bit`.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector1bit(source)
  /// // vector1bit(vector32(?))
  /// ```
  public static func vector1bit<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation> where V.Encoding: TursoVectorEncoding {
    Self.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  }

  /// Converts a supported vector BLOB, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector1bit(source, as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
  /// // vector1bit(vector32(?))
  /// ```
  public static func vector1bit<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoVectorEncoding, T.Encoding == [Bool].TursoBytesRepresentation {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  /// Converts JSON to a sparse float32 vector with `vector32_sparse`.
  ///
  /// ```swift
  /// let expression = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// ```
  public static func vector32Sparse(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<SparseFloat32Vector> {
    Self.vector32Sparse(expression, as: SparseFloat32Vector.self)
  }

  /// Converts JSON with `vector32_sparse`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let expression = TursoVec.vector32Sparse("[1,2,3]", as: SizedSparseFloat32Vector<3>.self)
  /// // vector32_sparse(?)
  /// ```
  public static func vector32Sparse<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == SparseFloat32Vector {
    SQLQueryExpression("vector32_sparse(\(expression))")
  }

  /// Converts a supported vector BLOB to a sparse Float32 vector with `vector32_sparse`.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector32Sparse(source)
  /// // vector32_sparse(vector32(?))
  /// ```
  public static func vector32Sparse<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<SparseFloat32Vector> where V.Encoding: TursoVectorEncoding {
    Self.vector32Sparse(expression, as: SparseFloat32Vector.self)
  }

  /// Converts a supported vector BLOB, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let expression = TursoVec.vector32Sparse(source, as: SizedSparseFloat32Vector<3>.self)
  /// // vector32_sparse(vector32(?))
  /// ```
  public static func vector32Sparse<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoVectorEncoding, T.Encoding == SparseFloat32Vector {
    SQLQueryExpression("vector32_sparse(\(expression))")
  }

  /// Converts JSON to float32 using the `vector` alias.
  ///
  /// ```swift
  /// let expression = TursoVec.vector("[1,2,3]")
  /// // vector(?)
  /// ```
  public static func vector(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    SQLQueryExpression("vector(\(expression))")
  }

  /// Converts a supported vector BLOB to Float32 using the `vector` alias.
  ///
  /// ```swift
  /// let source = TursoVec.vector64("[1, 2, 3]")
  /// // vector64(?)
  /// let expression = TursoVec.vector(source)
  /// // vector(vector64(?))
  /// ```
  public static func vector<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding: TursoVectorEncoding {
    SQLQueryExpression("vector(\(expression))")
  }

  /// Extracts a supported vector blob as a JSON array string with `vector_extract`.
  ///
  /// ```swift
  /// let expression = TursoVec.extract(TursoVec.vector32("[1,2,3]"))
  /// // vector_extract(vector32(?))
  /// ```
  public static func extract<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding: TursoVectorEncoding {
    SQLQueryExpression("vector_extract(\(expression))")
  }

  /// Returns cosine distance, including the binary Hamming specialization.
  /// Both operands must use the same supported Turso encoding.
  /// The database checks dimensions and value-dependent restrictions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceCosine(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_cos(vector32(?), vector32(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.distanceCosine(vector, to: TursoVec.vector64("[3,2,1]"))
  /// // vector_distance_cos(vector64(?), vector64(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// let expression = TursoVec.distanceCosine(vector, to: TursoVec.vector8("[3,2,1]"))
  /// // vector_distance_cos(vector8(?), vector8(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector1bit("[1,2,3]")
  /// // vector1bit(?)
  /// let expression = TursoVec.distanceCosine(vector, to: TursoVec.vector1bit("[3,2,1]"))
  /// // vector_distance_cos(vector1bit(?), vector1bit(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.distanceCosine(vector, to: TursoVec.vector32Sparse("[3,2,1]"))
  /// // vector_distance_cos(vector32_sparse(?), vector32_sparse(?))
  /// ```
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceCosine(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_cos(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceCosine(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_cos(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 32-bit floating-point format.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_l2(vector32(?), vector32(?))
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Float].VectorBytesRepresentation, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_l2(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Float].VectorBytesRepresentation, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_l2(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Float].VectorBytesRepresentation, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the 64-bit floating-point format.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector64("[3,2,1]"))
  /// // vector_distance_l2(vector64(?), vector64(?))
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Double].TursoFloat64BytesRepresentation, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector64("[3,2,1]"))
  /// // vector_distance_l2(vector64(?), vector64(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Double].TursoFloat64BytesRepresentation, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector64("[3,2,1]"))
  /// // vector_distance_l2(vector64(?), vector64(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == [Double].TursoFloat64BytesRepresentation, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the quantized float8 format.
  ///
  /// ```swift
  /// let vector = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector8("[3,2,1]"))
  /// // vector_distance_l2(vector8(?), vector8(?))
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == Quantized8Vector, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector8("[3,2,1]"))
  /// // vector_distance_l2(vector8(?), vector8(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == Quantized8Vector, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector8("[3,2,1]"))
  /// // vector_distance_l2(vector8(?), vector8(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == Quantized8Vector, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// The database requires equal dimensions. Both operands must use the sparse float32 format.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector32Sparse("[3,2,1]"))
  /// // vector_distance_l2(vector32_sparse(?), vector32_sparse(?))
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == SparseFloat32Vector, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector32Sparse("[3,2,1]"))
  /// // vector_distance_l2(vector32_sparse(?), vector32_sparse(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == SparseFloat32Vector, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.distanceL2(vector, to: TursoVec.vector32Sparse("[3,2,1]"))
  /// // vector_distance_l2(vector32_sparse(?), vector32_sparse(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding == SparseFloat32Vector, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns the negative dot product between matching vectors.
  /// Both operands must use the same supported Turso encoding.
  /// The database checks dimensions and value-dependent restrictions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceDot(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_dot(vector32(?), vector32(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.distanceDot(vector, to: TursoVec.vector64("[3,2,1]"))
  /// // vector_distance_dot(vector64(?), vector64(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// let expression = TursoVec.distanceDot(vector, to: TursoVec.vector8("[3,2,1]"))
  /// // vector_distance_dot(vector8(?), vector8(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector1bit("[1,2,3]")
  /// // vector1bit(?)
  /// let expression = TursoVec.distanceDot(vector, to: TursoVec.vector1bit("[3,2,1]"))
  /// // vector_distance_dot(vector1bit(?), vector1bit(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.distanceDot(vector, to: TursoVec.vector32Sparse("[3,2,1]"))
  /// // vector_distance_dot(vector32_sparse(?), vector32_sparse(?))
  /// ```
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceDot(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_dot(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceDot(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_dot(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Returns weighted numeric Jaccard distance or binary set Jaccard distance.
  /// Both operands must use the same supported Turso encoding.
  /// The database checks dimensions and value-dependent restrictions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceJaccard(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_jaccard(vector32(?), vector32(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.distanceJaccard(vector, to: TursoVec.vector64("[3,2,1]"))
  /// // vector_distance_jaccard(vector64(?), vector64(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// let expression = TursoVec.distanceJaccard(vector, to: TursoVec.vector8("[3,2,1]"))
  /// // vector_distance_jaccard(vector8(?), vector8(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector1bit("[1,2,3]")
  /// // vector1bit(?)
  /// let expression = TursoVec.distanceJaccard(vector, to: TursoVec.vector1bit("[3,2,1]"))
  /// // vector_distance_jaccard(vector1bit(?), vector1bit(?))
  /// ```
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.distanceJaccard(vector, to: TursoVec.vector32Sparse("[3,2,1]"))
  /// // vector_distance_jaccard(vector32_sparse(?), vector32_sparse(?))
  /// ```
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceJaccard(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_jaccard(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.distanceJaccard(vector, to: TursoVec.vector32("[3,2,1]"))
  /// // vector_distance_jaccard(vector32(?), vector32(?))
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Returns an array representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.concat(vector, vector)
  /// // vector_concat(vector32(?), vector32(?))
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where L.Encoding == [Float].VectorBytesRepresentation, L.Encoding == R.Encoding {
    Self.concat(expression, vector, as: [Float].VectorBytesRepresentation.self)
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.concat(vector, vector, as: EmbeddingVector<6>.self)
  /// // vector_concat(vector32(?), vector32(?))
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    L.Encoding == [Float].VectorBytesRepresentation, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Returns an array representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.concat(vector, vector)
  /// // vector_concat(vector64(?), vector64(?))
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation>
  where L.Encoding == [Double].TursoFloat64BytesRepresentation, L.Encoding == R.Encoding {
    Self.concat(expression, vector, as: [Double].TursoFloat64BytesRepresentation.self)
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.concat(
  ///   vector,
  ///   vector,
  ///   as: EmbeddingVector64<6>.TursoFloat64BytesRepresentation.self
  /// )
  /// // vector_concat(vector64(?), vector64(?))
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    L.Encoding == [Double].TursoFloat64BytesRepresentation, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.slice(vector, from: 0, to: 2)
  /// // vector_slice(vector32(?), ?, ?)
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.slice(expression, from: start, to: end, as: [Float].VectorBytesRepresentation.self)
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let expression = TursoVec.slice(vector, from: 0, to: 2, as: EmbeddingVector<2>.self)
  /// // vector_slice(vector32(?), ?, ?)
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == V.Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.slice(vector, from: 0, to: 2)
  /// // vector_slice(vector64(?), ?, ?)
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation>
  where V.Encoding == [Double].TursoFloat64BytesRepresentation {
    Self.slice(expression, from: start, to: end, as: [Double].TursoFloat64BytesRepresentation.self)
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let expression = TursoVec.slice(
  ///   vector,
  ///   from: 0,
  ///   to: 2,
  ///   as: EmbeddingVector64<2>.TursoFloat64BytesRepresentation.self
  /// )
  /// // vector_slice(vector64(?), ?, ?)
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Double].TursoFloat64BytesRepresentation, T.Encoding == V.Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.slice(vector, from: 0, to: 2)
  /// // vector_slice(vector32_sparse(?), ?, ?)
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<SparseFloat32Vector>
  where V.Encoding == SparseFloat32Vector {
    Self.slice(expression, from: start, to: end, as: SparseFloat32Vector.self)
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[1,2,3]")
  /// // vector32_sparse(?)
  /// let expression = TursoVec.slice(vector, from: 0, to: 2, as: SizedSparseFloat32Vector<2>.self)
  /// // vector_slice(vector32_sparse(?), ?, ?)
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where V.Encoding == SparseFloat32Vector, T.Encoding == V.Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }
}
