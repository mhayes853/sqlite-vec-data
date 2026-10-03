import StructuredQueriesCore

/// A vector value or query representation with a known scalar type and byte layout.
public protocol VectorBytesRepresentable {
  /// The vector's numeric or logical scalar type.
  associatedtype Scalar
  /// The type identity of the byte layout, such as `VectorFormat.Float32`.
  associatedtype Format
  /// The query representation for the vector bytes.
  associatedtype VectorBytesRepresentation: QueryBindable & QueryRepresentable
}

extension Array: VectorBytesRepresentable where Element: VectorScalar {
  public typealias Scalar = Element
  public typealias Format = Element.Format
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray: VectorBytesRepresentable where Element: VectorScalar {
    public typealias Scalar = Element
    public typealias Format = Element.Format
  }
#endif
