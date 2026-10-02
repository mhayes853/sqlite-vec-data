import StructuredQueriesCore

/// A type that can be represented as vector bytes for queries.
public protocol VectorBytesRepresentable {
  /// The query representation for the vector bytes.
  associatedtype VectorBytesRepresentation: QueryBindable & QueryDecodable & QueryRepresentable
}

extension Array: VectorBytesRepresentable where Element: VectorScalar {}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray: VectorBytesRepresentable where Element: VectorScalar {}
#endif
