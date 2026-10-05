import StructuredQueriesCore

/// A vector value or query representation with a known scalar type and byte layout.
public protocol VectorBytesRepresentable {
  /// The vector's numeric or logical scalar type.
  associatedtype Scalar
  /// The canonical representation identifying the byte layout, independent of dimensions.
  /// For example, both dense float32 arrays and inline vectors use
  /// `[Float].VectorBytesRepresentation`.
  associatedtype Encoding: QueryBindable
  /// The query representation for this value, preserving any fixed-dimension constraint.
  associatedtype VectorBytesRepresentation: QueryBindable & QueryRepresentable

  /// The serialized vector, including any metadata required by its encoding.
  var vectorBytes: [UInt8] { get }

  /// Decodes vector bytes, validating the encoding and any fixed dimension count.
  init(vectorBytes: [UInt8]) throws
}

extension VectorBytesRepresentable where Self: QueryBindable {
  public var queryBinding: QueryBinding { .blob(self.vectorBytes) }

  public init(decoder: inout some QueryDecoder) throws {
    try self.init(vectorBytes: [UInt8](decoder: &decoder))
  }
}

extension Array: VectorBytesRepresentable where Element: VectorScalar {
  public typealias Scalar = Element
  public typealias Encoding = VectorBytesRepresentation

  public var vectorBytes: [UInt8] { Element.encodeVector(self) }

  public init(vectorBytes: [UInt8]) throws {
    self = try Element.decodeVector(vectorBytes)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray: VectorBytesRepresentable where Element: VectorScalar {
    public typealias Scalar = Element
    public typealias Encoding = [Element].VectorBytesRepresentation

    public var vectorBytes: [UInt8] {
      Element.encodeVector((0..<Self.count).map { self[$0] })
    }

    public init(vectorBytes: [UInt8]) throws {
      let elements = try Element.decodeVector(vectorBytes)
      guard elements.count == Self.count else {
        throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: elements.count)
      }
      self.init { elements[$0] }
    }
  }
#endif
