import StructuredQueriesCore
import StructuredQueriesVectorCore

/// A canonical vector byte encoding supported by Turso Database.
///
/// Conformance promises Turso-compatible bytes. Raw Float64, Float16, SQLiteVec Int8, and
/// SQLiteVec packed-bit encodings do not conform. Custom conformances must supply the layout
/// and framing required by the engine; conformance does not perform conversion.
///
/// ```swift
/// func vectorJSON<V: VectorBytesRepresentable & QueryBindable>(
///   _ vector: some QueryExpression<V>
/// ) -> some QueryExpression<String> where V.Encoding: TursoVectorEncoding {
///   TursoVec.extract(vector)
/// }
/// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
/// let expression = vectorJSON(vector)
/// // vector_extract(?)
/// ```
public protocol TursoVectorEncoding: VectorBytesRepresentable, QueryBindable {}

/// A Turso encoding supporting numerical distances, including L2.
///
/// Dense Float32/Float64, affine quantized UInt8, and sparse Float32 encodings conform.
/// Binary encodings do not support L2.
///
/// ```swift
/// func numericDistance<L: VectorBytesRepresentable & QueryBindable,
///   R: VectorBytesRepresentable & QueryBindable>(
///   _ left: some QueryExpression<L>, to right: some QueryExpression<R>
/// ) -> some QueryExpression<Double?>
/// where L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
///   L.Dimensions == R.Dimensions {
///   TursoVec.distanceL2(left, to: right)
/// }
/// let left: [Float].VectorBytesRepresentation = [3, 4, 0]
/// let right: [Float].VectorBytesRepresentation = [0, 0, 0]
/// let distance = numericDistance(left, to: right)
/// // vector_distance_l2(?, ?)
/// ```
public protocol TursoNumericVectorEncoding: TursoVectorEncoding where Scalar: BinaryFloatingPoint {}

/// Turso-compatible dense Float32 bytes, including shared raw Float32 payloads.
///
/// ```swift
/// func convert<T: VectorBytesRepresentable & QueryBindable>(
///   _ json: some QueryExpression<String>, as result: T.Type
/// ) -> some QueryExpression<T> where T.Encoding: TursoFloat32Encoding {
///   TursoVec.vector32(json, as: result)
/// }
/// let converted = convert("[1,2,3]", as: EmbeddingVector<3>.self)
/// // vector32(?)
/// ```
public protocol TursoFloat32Encoding: TursoNumericVectorEncoding where Scalar == Float {}

/// Turso's tagged dense Float64 byte layout.
///
/// ```swift
/// func convert<T: VectorBytesRepresentable & QueryBindable>(
///   _ json: some QueryExpression<String>, as result: T.Type
/// ) -> some QueryExpression<T> where T.Encoding: TursoFloat64Encoding {
///   TursoVec.vector64(json, as: result)
/// }
/// let converted = convert("[1,2,3]", as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
/// // vector64(?)
/// ```
public protocol TursoFloat64Encoding: TursoNumericVectorEncoding where Scalar == Double {}

/// Turso's affine UInt8 codes with scale, shift, and format metadata.
///
/// ```swift
/// func convert<T: VectorBytesRepresentable & QueryBindable>(
///   _ json: some QueryExpression<String>, as result: T.Type
/// ) -> some QueryExpression<T> where T.Encoding: TursoQuantized8Encoding {
///   TursoVec.vector8(json, as: result)
/// }
/// let converted = convert("[1,2,3]", as: InlineQuantized8Vector<3>.self)
/// // vector8(?)
/// ```
public protocol TursoQuantized8Encoding: TursoNumericVectorEncoding where Scalar == Float {}

/// Turso's sparse Float32 dimensions, indices, values, and format metadata.
///
/// ```swift
/// func convert<T: VectorBytesRepresentable & QueryBindable>(
///   _ json: some QueryExpression<String>, as result: T.Type
/// ) -> some QueryExpression<T> where T.Encoding: TursoSparseFloat32Encoding {
///   TursoVec.vector32Sparse(json, as: result)
/// }
/// let converted = convert("[0,2,0]", as: SizedSparseFloat32Vector<3>.self)
/// // vector32_sparse(?)
/// ```
public protocol TursoSparseFloat32Encoding: TursoNumericVectorEncoding where Scalar == Float {}

/// Turso's packed binary payload with logical dimensions and format metadata.
///
/// ```swift
/// func convert<T: VectorBytesRepresentable & QueryBindable>(
///   _ json: some QueryExpression<String>, as result: T.Type
/// ) -> some QueryExpression<T> where T.Encoding: TursoBinaryEncoding {
///   TursoVec.vector1bit(json, as: result)
/// }
/// let converted = convert("[1,0,1]", as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
/// // vector1bit(?)
/// ```
public protocol TursoBinaryEncoding: TursoVectorEncoding, BinaryVectorEncoding {}

extension Array.VectorBytesRepresentation:
  TursoVectorEncoding, TursoNumericVectorEncoding, TursoFloat32Encoding
where Element == Float {}

extension TursoFloat64BytesRepresentation:
  TursoVectorEncoding, TursoNumericVectorEncoding, TursoFloat64Encoding
where Representation == [Double].VectorBytesRepresentation {}

extension Array.TursoBytesRepresentation: TursoBinaryEncoding {}

extension Quantized8Vector: TursoQuantized8Encoding {}

extension SparseFloat32Vector: TursoSparseFloat32Encoding {}
