/// A type identifying a fixed logical component count across vector formats and strategies.
///
/// Used as a vector's `Dimensions` associated type; no storage is allocated for this marker.
///
/// ```swift
/// func dotProduct<L: Collection & VectorBytesRepresentable, R: Collection & VectorBytesRepresentable>(
///   _ left: L, _ right: R
/// ) -> Float where L.Element == Float, R.Element == Float, L.Dimensions == R.Dimensions {
///   precondition(left.count == right.count)
///   return zip(left, right).reduce(0) { $0 + $1.0 * $1.1 }
/// }
/// let score = dotProduct(EmbeddingVector<3>([1, 0, 0]), EmbeddingVector<3>([0.5, 1, 0])) // 0.5
/// ```
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
public struct VectorDimensions<let count: Int>: Hashable, Sendable {}
