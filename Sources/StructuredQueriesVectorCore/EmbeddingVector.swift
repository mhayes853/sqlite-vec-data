import StructuredQueriesCore

#if swift(>=6.2)
  // MARK: - EmbeddingVector

  /// A fixed-size vector of scalar values with collection, Hashable, and Codable support.
  ///
  /// Prefer the precision aliases `EmbeddingVector`, `EmbeddingVector64`, `EmbeddingVector16`,
  /// and `BinaryEmbeddingVector`. Floating-point equality compares elements using Swift's scalar
  /// equality: signed zeros are equal, and NaNs are unequal.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct FixedEmbeddingVector<let count: Int, Scalar: Hashable & Codable & Sendable>:
    Sendable
  {
    /// The underlying fixed-size storage for the vector.
    public var array: [count of Scalar]

    /// Creates a vector from a fixed-size array of scalars.
    ///
    /// - Parameter array: The vector elements.
    public init(_ array: [count of Scalar]) {
      self.array = array
    }

    /// Creates a vector by generating each element with a closure.
    ///
    /// - Parameter body: A closure that returns the element at the given index.
    /// - Throws: Rethrows any error thrown by `body`.
    public init<E: Error>(_ body: (Int) throws(E) -> Scalar) throws(E) {
      try self.init([count of Scalar](body))
    }

    /// Creates a vector by providing the first element and a generator for the rest.
    ///
    /// - Parameters:
    ///   - first: The first element.
    ///   - next: A closure that returns the next element given the previous one.
    /// - Throws: Rethrows any error thrown by `next`.
    public init<E: Error>(first: Scalar, next: (Scalar) throws(E) -> Scalar) throws(E) {
      try self.init([count of Scalar](first: first, next: next))
    }

    /// Creates a vector by initializing its storage with a span.
    ///
    /// - Parameter initializer: A closure that writes elements into the span.
    /// - Throws: Rethrows any error thrown by `initializer`.
    public init<E: Error>(
      initializingWith initializer: (inout OutputSpan<Scalar>) throws(E) -> Void
    ) throws(E) {
      try self.init([count of Scalar](initializingWith: initializer))
    }

    /// Creates a vector by repeating a value.
    ///
    /// - Parameter value: The value to repeat.
    public init(repeating value: Scalar) {
      self.init([count of Scalar](repeating: value))
    }
  }

  // MARK: - Equatable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
      (0..<Self.count).allSatisfy { lhs.array[$0] == rhs.array[$0] }
    }
  }

  // MARK: - Hashable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: Hashable {
    public func hash(into hasher: inout Hasher) {
      hasher.combine(Self.count)
      // swift-format-ignore: ReplaceForEachWithForLoop
      (0..<Self.count).forEach { hasher.combine(self.array[$0]) }
    }
  }

  // MARK: - Encodable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: Encodable {
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.unkeyedContainer()
      // swift-format-ignore: ReplaceForEachWithForLoop
      try self.forEach { try container.encode($0) }
    }
  }

  // MARK: - Decodable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: Decodable {
    public init(from decoder: any Decoder) throws {
      var container = try decoder.unkeyedContainer()
      guard let count = container.count else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected count")
        )
      }
      if Self.count > count {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription:
              "Decoded contains too few elements. (Expected \(Self.count), got \(count))"
          )
        )
      }
      if Self.count < count {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription:
              "Decoded contains too many elements. (Expected \(Self.count), got \(count))"
          )
        )
      }
      try self.init { _ in try container.decode(Scalar.self) }
    }
  }

  // MARK: - CustomStringConvertible

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: CustomStringConvertible {
    public var description: String {
      let name =
        switch Scalar.self {
        case is Float.Type: "EmbeddingVector"
        case is Double.Type: "EmbeddingVector64"
        case is Float16.Type: "EmbeddingVector16"
        case is Bool.Type: "BinaryEmbeddingVector"
        default: "FixedEmbeddingVector"
        }
      return "\(name)<\(Self.count)>(\(Array(self)))"
    }
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: CustomDebugStringConvertible {
    public var debugDescription: String {
      self.description
    }
  }

  // MARK: - MutableCollection

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: MutableCollection {
    public typealias Element = Scalar
    public typealias Index = Int

    public subscript(position: Index) -> Element {
      _read {
        yield self.array[position]
      }
      _modify {
        yield &self.array[position]
      }
    }

    public var startIndex: Int {
      self.array.startIndex
    }

    public var endIndex: Int {
      self.array.endIndex
    }

    public func index(after i: Int) -> Int {
      self.array.index(after: i)
    }
  }

  // MARK: - RandomAccessCollection

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: RandomAccessCollection {
  }

  // MARK: - QueryBindable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: QueryBindable, QueryDecodable, QueryRepresentable,
    QueryExpression, _OptionalPromotable
  where Scalar == Float {
    public var queryBinding: QueryBinding {
      [count of Float].VectorBytesRepresentation(queryOutput: self.array).queryBinding
    }

    public init(decoder: inout some QueryDecoder) throws {
      guard let bytes = try decoder.decode([count of Float].VectorBytesRepresentation.self) else {
        throw QueryDecodingError.missingRequiredColumn
      }
      self.init(bytes)
    }
  }
  // MARK: - Precision Aliases

  /// A fixed-size float32 embedding vector. Its direct query binding remains compatible with SQLiteVec.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public typealias EmbeddingVector<let count: Int> = FixedEmbeddingVector<count, Float>

  /// A fixed-size float64 embedding vector.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public typealias EmbeddingVector64<let count: Int> = FixedEmbeddingVector<count, Double>

  /// A fixed-size IEEE half-precision embedding vector.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public typealias EmbeddingVector16<let count: Int> = FixedEmbeddingVector<count, Float16>

  /// A fixed-size vector of logical bits, independent of its database encoding.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public typealias BinaryEmbeddingVector<let count: Int> = FixedEmbeddingVector<count, Bool>

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector {
    package init(vectorElements: [Scalar]) throws {
      guard vectorElements.count == Self.count else {
        throw VectorDecodingError.dimensionMismatch(
          expected: Self.count,
          actual: vectorElements.count
        )
      }
      self.init { vectorElements[$0] }
    }
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector: VectorBytesRepresentable where Scalar: VectorScalar {
    public typealias Format = Scalar.Format

    /// The scalar's default blob representation with fixed-dimension validation.
    public struct VectorBytesRepresentation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Element
      public typealias Format = Element.Format
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Element>

      public init(queryOutput: FixedEmbeddingVector<count, Element>) {
        self.queryOutput = queryOutput
      }

      public var queryBinding: QueryBinding {
        [Element].VectorBytesRepresentation(queryOutput: Array(self.queryOutput)).queryBinding
      }

      public init(decoder: inout some QueryDecoder) throws {
        let elements = try [Element].VectorBytesRepresentation(decoder: &decoder).queryOutput
        try self.init(queryOutput: FixedEmbeddingVector<count, Element>(vectorElements: elements))
      }
    }
  }
#endif
