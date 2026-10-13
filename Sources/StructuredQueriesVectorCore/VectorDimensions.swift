#if swift(>=6.2)
  /// A type identifying a fixed logical component count across vector formats and strategies.
  ///
  /// Used as a vector's `Dimensions` associated type; no storage is allocated for this marker.
  ///
  /// ```swift
  /// typealias ThreeDimensions = VectorDimensions<3>
  /// let dimensions = ThreeDimensions.self
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct VectorDimensions<let count: Int>: Hashable, Sendable {}
#endif
