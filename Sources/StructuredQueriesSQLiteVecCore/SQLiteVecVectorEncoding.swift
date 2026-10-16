import StructuredQueriesCore
import StructuredQueriesVectorCore

/// A vector byte layout supported by SQLiteVec.
///
/// Conformance promises a compatible layout and the SQL subtype needed to interpret it.
/// It does not convert arbitrary bytes into a supported vector format.
///
/// ```swift
/// func inspect<V: VectorBytesRepresentable>(
///   _ vector: some QueryExpression<V>
/// ) -> some QueryExpression<Int> where V.Encoding: SQLiteVecVectorEncoding {
///   Vec.length(vector)
/// }
/// let codes: [Int8].Int8BytesRepresentation = [1, -2, 3]
/// let dimensions = inspect(codes)
/// // vec_length(vec_int8(?))
/// ```
public protocol SQLiteVecVectorEncoding: VectorBytesRepresentable, QueryBindable {
  /// Attaches the encoding's SQLiteVec subtype to a vector expression.
  /// Ordinary queries use `Vec` helpers; custom encodings use this fragment hook.
  ///
  /// ```swift
  /// let codes: [Int8].Int8BytesRepresentation = [1, -2, 3]
  /// let fragment = [Int8].Int8BytesRepresentation.sqliteVecExpression(codes.queryFragment)
  /// // vec_int8(?)
  /// ```
  static func sqliteVecExpression(_ expression: QueryFragment) -> QueryFragment
}

/// A SQLiteVec encoding supporting numerical distances, arithmetic, and binary quantization.
///
/// ```swift
/// func numericDistance<L: VectorBytesRepresentable, R: VectorBytesRepresentable>(
///   _ left: some QueryExpression<L>, to right: some QueryExpression<R>
/// ) -> some QueryExpression<Double?>
/// where L.Encoding: SQLiteVecNumericEncoding, L.Encoding == R.Encoding,
///   L.Dimensions == R.Dimensions {
///   Vec.distanceL2(left, to: right)
/// }
/// let left: [Int8].Int8BytesRepresentation = [3, 4, 0]
/// let right: [Int8].Int8BytesRepresentation = [0, 0, 0]
/// let distance = numericDistance(left, to: right)
/// // vec_distance_l2(vec_int8(?), vec_int8(?))
/// ```
public protocol SQLiteVecNumericEncoding: SQLiteVecVectorEncoding where Scalar: SignedNumeric {}

/// SQLiteVec's raw little-endian Float32 byte layout.
///
/// ```swift
/// func tagged<V: VectorBytesRepresentable & QueryBindable>(
///   _ vector: some QueryExpression<V>
/// ) -> some QueryExpression<V> where V.Encoding: SQLiteVecFloat32Encoding {
///   Vec.f32(vector)
/// }
/// let vector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
/// let expression = tagged(vector)
/// // vec_f32(?)
/// ```
public protocol SQLiteVecFloat32Encoding: SQLiteVecNumericEncoding where Scalar == Float {}

/// SQLiteVec's signed Int8 byte layout.
///
/// ```swift
/// func tagged<V: VectorBytesRepresentable & QueryBindable>(
///   _ vector: some QueryExpression<V>
/// ) -> some QueryExpression<V> where V.Encoding: SQLiteVecInt8Encoding {
///   Vec.int8(vector)
/// }
/// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3]
/// let expression = tagged(vector)
/// // vec_int8(?)
/// ```
public protocol SQLiteVecInt8Encoding: SQLiteVecNumericEncoding where Scalar == Int8 {}

/// SQLiteVec's raw packed-bit layout, with eight logical components per byte.
///
/// Values must validate byte-aligned dimensions. Metadata-bearing binary layouts do not conform.
///
/// ```swift
/// func tagged<V: VectorBytesRepresentable & QueryBindable>(
///   _ vector: some QueryExpression<V>
/// ) -> some QueryExpression<V> where V.Encoding: SQLiteVecBinaryEncoding {
///   Vec.bit(vector)
/// }
/// let vector = BinaryEmbeddingVector<8>.PackedBitsRepresentation(
///   queryOutput: BinaryEmbeddingVector<8>([true, false, true, false, false, false, false, true])
/// )
/// let expression = tagged(vector)
/// // vec_bit(?)
/// ```
public protocol SQLiteVecBinaryEncoding: SQLiteVecVectorEncoding, BinaryVectorEncoding {}

extension SQLiteVecFloat32Encoding {
  /// Uses the Float32 expression without adding a subtype wrapper.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let fragment = [Float].VectorBytesRepresentation.sqliteVecExpression(vector.queryFragment)
  /// // ?
  /// ```
  public static func sqliteVecExpression(_ expression: QueryFragment) -> QueryFragment {
    expression
  }
}

extension SQLiteVecInt8Encoding {
  /// Attaches this format's SQLiteVec subtype.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3]
  /// let fragment = [Int8].Int8BytesRepresentation.sqliteVecExpression(vector.queryFragment)
  /// // vec_int8(?)
  /// ```
  public static func sqliteVecExpression(_ expression: QueryFragment) -> QueryFragment {
    "vec_int8(\(expression))"
  }
}

extension SQLiteVecBinaryEncoding {
  /// Attaches this format's SQLiteVec subtype.
  ///
  /// ```swift
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
  /// let fragment = [Bool].PackedBitsRepresentation.sqliteVecExpression(vector.queryFragment)
  /// // vec_bit(?)
  /// ```
  public static func sqliteVecExpression(_ expression: QueryFragment) -> QueryFragment {
    "vec_bit(\(expression))"
  }
}

extension Array.VectorBytesRepresentation:
  SQLiteVecVectorEncoding, SQLiteVecNumericEncoding, SQLiteVecFloat32Encoding
where Element == Float {}

extension Array.Int8BytesRepresentation: SQLiteVecInt8Encoding {}

extension Array.PackedBitsRepresentation: SQLiteVecBinaryEncoding {}
