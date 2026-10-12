import StructuredQueriesCore
import StructuredQueriesVectorCore

/// A canonical vector byte encoding supported by Turso Database.
///
/// Constrain a vector's `Encoding` to this protocol when forwarding it to a Turso constructor
/// or extraction helper. Shared Float32, Turso Float64, binary, quantized, and sparse encodings
/// conform. Raw Float64, Float16, and packed-bit encodings do not.
///
/// ```swift
/// func vectorJSON<V: VectorBytesRepresentable & QueryBindable>(
///   _ vector: some QueryExpression<V>
/// ) -> some QueryExpression<String> where V.Encoding: TursoVectorEncoding {
///   TursoVec.extract(vector) // vector_extract(?)
/// }
/// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
/// let expression = vectorJSON(vector)
/// // vector_extract(?)
/// ```
///
/// Conformance promises compatible bytes; it does not convert or validate a custom encoding.
/// The database validates JSON contents, dimensions, and value-dependent conversion restrictions.
public protocol TursoVectorEncoding: QueryBindable {}

extension Array.VectorBytesRepresentation: TursoVectorEncoding where Element == Float {}

extension TursoFloat64BytesRepresentation: TursoVectorEncoding
where Representation == [Double].VectorBytesRepresentation {}

extension Array.TursoBytesRepresentation: TursoVectorEncoding {}

extension Quantized8Vector: TursoVectorEncoding {}

extension SparseFloat32Vector: TursoVectorEncoding {}
