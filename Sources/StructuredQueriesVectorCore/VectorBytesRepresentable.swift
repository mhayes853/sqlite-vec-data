import StructuredQueriesCore

/// A vector value or query representation with a known scalar type and byte layout.
///
/// ```swift
/// func copy<V: VectorBytesRepresentable>(_ vector: V) throws -> V {
///   try V(vectorBytes: vector.vectorBytes)
/// }
/// let restored = try copy([Float(1), 2, 3])
/// ```
public protocol VectorBytesRepresentable {
  /// The vector's numeric or logical scalar type.
  associatedtype Scalar
  /// The canonical representation identifying the byte layout, independent of dimensions.
  /// For example, both dense float32 arrays and inline vectors use
  /// `[Float].VectorBytesRepresentation`.
  associatedtype Encoding: QueryBindable
  /// The query representation for this value, preserving any fixed-dimension constraint.
  associatedtype VectorBytesRepresentation: QueryBindable

  /// The serialized vector, including any metadata required by its encoding.
  ///
  /// ```swift
  /// let bytes = [Float(1), 2, 3].vectorBytes
  /// ```
  var vectorBytes: [UInt8] { get }

  /// Decodes vector bytes, validating the encoding and any fixed dimension count.
  ///
  /// ```swift
  /// let bytes = [Float(1), 2, 3].vectorBytes
  /// let vector = try [Float](vectorBytes: bytes)
  /// ```
  init(vectorBytes: [UInt8]) throws
}

extension VectorBytesRepresentable where Self: QueryBindable {
  /// Binds the encoded vector as a SQLite blob.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
  /// let binding = vector.queryBinding  // A SQLite blob binding.
  /// ```
  public var queryBinding: QueryBinding { .blob(self.vectorBytes) }

  /// Decodes a vector from a query's blob column.
  ///
  /// ```swift
  /// func read<V: VectorBytesRepresentable & QueryBindable>(
  ///   _ type: V.Type,
  ///   decoder: inout some QueryDecoder
  /// ) throws -> V {
  ///   try V(decoder: &decoder)
  /// }
  /// ```
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(vectorBytes: [UInt8](decoder: &decoder))
  }
}

extension Array: VectorBytesRepresentable where Element: VectorScalar {
  public typealias Scalar = Element
  public typealias Encoding = VectorBytesRepresentation

  /// The serialized blob, including any metadata required by this encoding.
  ///
  /// ```swift
  /// let values: [Float] = [1, 2, 3]
  /// let bytes = values.vectorBytes
  /// ```
  public var vectorBytes: [UInt8] { Element.encodeVector(self) }

  /// Decodes a vector blob, validating its encoding and dimensions.
  ///
  /// ```swift
  /// let values: [Float] = [1, 2, 3]
  /// let restored = try [Float](vectorBytes: values.vectorBytes)
  /// ```
  public init(vectorBytes: [UInt8]) throws {
    self = try Element.decodeVector(vectorBytes)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray: VectorBytesRepresentable where Element: VectorScalar {
    public typealias Scalar = Element
    public typealias Encoding = [Element].VectorBytesRepresentation

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let values: InlineArray<3, Float> = [1, 2, 3]
    /// let bytes = values.vectorBytes
    /// ```
    public var vectorBytes: [UInt8] {
      Element.encodeVector((0..<Self.count).map { self[$0] })
    }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let values: InlineArray<3, Float> = [1, 2, 3]
    /// let restored = try InlineArray<3, Float>(vectorBytes: values.vectorBytes)
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      let elements = try Element.decodeVector(vectorBytes)
      guard elements.count == Self.count else {
        throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: elements.count)
      }
      self.init { elements[$0] }
    }
  }
#endif
