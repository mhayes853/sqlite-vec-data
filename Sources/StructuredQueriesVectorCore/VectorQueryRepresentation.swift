import StructuredQueriesCore

/// The elements of a vector, independent of its database encoding.
public protocol VectorValue {
  associatedtype VectorElement: Hashable
  var vectorElements: [VectorElement] { get }
  init(vectorElements: [VectorElement]) throws
}

/// A binary encoding for vector elements.
public protocol VectorEncoding: Sendable {
  associatedtype Element: Hashable & Sendable
  static func encode(_ elements: [Element]) -> [UInt8]
  static func decode(_ bytes: [UInt8]) throws -> [Element]
}

/// An encoding that supports Euclidean distance in Turso.
public protocol L2VectorEncoding: VectorEncoding {}

/// A query value whose vector encoding is known at compile time.
public protocol EncodedVector: VectorBytesRepresentable, QueryBindable {
  associatedtype Encoding: VectorEncoding
}

/// A numeric or logical vector represented by a specific binary encoding in queries.
///
/// Prefer the named representations on arrays and fixed-size vectors, such as
/// `[Float].VectorBytesRepresentation` and `[Bool].PackedBitsRepresentation`.
public struct VectorQueryRepresentation<Value: VectorValue, Encoding: VectorEncoding>:
  QueryBindable, QueryDecodable, QueryRepresentable, EncodedVector
where Value.VectorElement == Encoding.Element {
  public typealias VectorBytesRepresentation = Self
  public var queryOutput: Value

  public init(queryOutput: Value) {
    self.queryOutput = queryOutput
  }

  public var queryBinding: QueryBinding {
    .blob(Encoding.encode(self.queryOutput.vectorElements))
  }

  public init(decoder: inout some QueryDecoder) throws {
    try self.init(
      queryOutput: Value(vectorElements: Encoding.decode([UInt8](decoder: &decoder)))
    )
  }
}

extension VectorQueryRepresentation: Sendable where Value: Sendable {}

extension VectorQueryRepresentation: Equatable where Value: Equatable {}
extension VectorQueryRepresentation: Hashable where Value: Hashable {}

extension VectorQueryRepresentation: ExpressibleByArrayLiteral where Value == [Encoding.Element] {
  public init(arrayLiteral elements: Encoding.Element...) {
    self.init(queryOutput: elements)
  }
}

/// An invalid vector blob or an unexpected number of dimensions.
public enum VectorDecodingError: Error, Hashable, Sendable {
  case invalidBytes
  case dimensionMismatch(expected: Int, actual: Int)
}

extension Array: VectorValue where Element: Hashable {
  public var vectorElements: [Element] { self }

  public init(vectorElements: [Element]) {
    self = vectorElements
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray: VectorValue where Element: Hashable {
    public var vectorElements: [Element] {
      (0..<Self.count).map { self[$0] }
    }

    public init(vectorElements: [Element]) throws {
      guard vectorElements.count == Self.count else {
        throw VectorDecodingError.dimensionMismatch(
          expected: Self.count,
          actual: vectorElements.count
        )
      }
      self.init { vectorElements[$0] }
    }
  }
#endif
