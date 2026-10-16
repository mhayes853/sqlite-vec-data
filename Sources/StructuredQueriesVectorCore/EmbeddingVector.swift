import StructuredQueriesCore

// MARK: - EmbeddingVector

/// A fixed-size vector of scalar values with collection, Hashable, and Codable support.
///
/// Prefer the precision aliases `EmbeddingVector` and `EmbeddingVector64`.
/// Use `BinaryEmbeddingVector` for packed logical bits. Floating-point equality compares elements
/// using Swift's scalar equality: signed zeros are equal, and NaNs are unequal.
///
/// ```swift
/// let embedding = EmbeddingVector<3>([0.1, 0.2, 0.3])
/// let components = Array(embedding) // Pass to an API that accepts a scalar array.
/// ```
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
public struct FixedEmbeddingVector<let count: Int, Scalar: Hashable & Codable & Sendable>:
  Sendable
{
  /// The underlying fixed-size storage for the vector.
  ///
  /// ```swift
  /// var embedding = EmbeddingVector<3>([1, 2, 3])
  /// embedding.array[1] = 0
  /// let components = Array(embedding) // [1, 0, 3]
  /// ```
  public var array: [count of Scalar]

  /// Creates a vector from a fixed-size array of scalars.
  ///
  /// - Parameter array: The vector elements.
  ///
  /// ```swift
  /// let components: InlineArray<3, Float> = [0.1, 0.2, 0.3]
  /// let embedding = EmbeddingVector<3>(components)
  /// let dimensions: Int = embedding.count // 3
  /// ```
  public init(_ array: [count of Scalar]) {
    self.array = array
  }

  /// Creates a vector by generating each element with a closure.
  ///
  /// - Parameter body: A closure that returns the element at the given index.
  /// - Throws: Rethrows any error thrown by `body`.
  ///
  /// ```swift
  /// let components: [Float] = [1, -2, 3]
  /// let embedding = EmbeddingVector<3> { components[$0] / 3 }
  /// let scaled = Array(embedding) // [1/3, -2/3, 1]
  /// ```
  public init<E: Error>(_ body: (Int) throws(E) -> Scalar) throws(E) {
    try self.init([count of Scalar](body))
  }

  /// Creates a vector by providing the first element and a generator for the rest.
  ///
  /// - Parameters:
  ///   - first: The first element.
  ///   - next: A closure that returns the next element given the previous one.
  /// - Throws: Rethrows any error thrown by `next`.
  ///
  /// ```swift
  /// let weights = EmbeddingVector<4>(first: 1) { $0 / 2 }
  /// let components = Array(weights) // [1, 0.5, 0.25, 0.125]
  /// ```
  public init<E: Error>(first: Scalar, next: (Scalar) throws(E) -> Scalar) throws(E) {
    try self.init([count of Scalar](first: first, next: next))
  }

  /// Creates a vector by initializing its storage with a span.
  ///
  /// - Parameter initializer: A closure that writes elements into the span.
  /// - Throws: Rethrows any error thrown by `initializer`.
  ///
  /// ```swift
  /// let components: [Float] = [0.1, 0.2, 0.3]
  /// let embedding = EmbeddingVector<3>(initializingWith: { span in
  ///   for component in components { span.append(component) }
  /// })
  /// let dimensions: Int = embedding.count // 3
  /// ```
  public init<E: Error>(
    initializingWith initializer: (inout OutputSpan<Scalar>) throws(E) -> Void
  ) throws(E) {
    try self.init([count of Scalar](initializingWith: initializer))
  }

  /// Creates a vector by repeating a value.
  ///
  /// - Parameter value: The value to repeat.
  ///
  /// ```swift
  /// var embedding = EmbeddingVector<3>(repeating: 0)
  /// embedding[1] = 1
  /// let components = Array(embedding) // [0, 1, 0]
  /// ```
  public init(repeating value: Scalar) {
    self.init([count of Scalar](repeating: value))
  }
}

// MARK: - Equatable

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension FixedEmbeddingVector: Equatable {
  /// Compares the vector components for equality.
  ///
  /// ```swift
  /// let left = EmbeddingVector<3>([-0.0, 1, 2])
  /// let right = EmbeddingVector<3>([0.0, 1, 2])
  /// let equal = left == right // true: floating-point equality treats signed zeros equally.
  /// ```
  public static func == (lhs: Self, rhs: Self) -> Bool {
    (0..<Self.count).allSatisfy { lhs.array[$0] == rhs.array[$0] }
  }
}

// MARK: - Hashable

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension FixedEmbeddingVector: Hashable {
  /// Hashes the vector components.
  ///
  /// ```swift
  /// let embeddings = [EmbeddingVector<3>([1, 0, 0]), EmbeddingVector<3>([1, 0, 0])]
  /// let unique = Set(embeddings)
  /// let uniqueCount = unique.count // 1
  /// ```
  public func hash(into hasher: inout Hasher) {
    hasher.combine(Self.count)
    for element in self {
      hasher.combine(element)
    }
  }
}

// MARK: - Encodable

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension FixedEmbeddingVector: Encodable {
  /// Encodes the logical vector components.
  ///
  /// ```swift
  /// import Foundation
  ///
  /// let embedding = EmbeddingVector<3>([1, 0, 0])
  /// let json = try JSONEncoder().encode(embedding)
  /// let payload = String(decoding: json, as: UTF8.self) // "[1,0,0]"
  /// ```
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    for element in self {
      try container.encode(element)
    }
  }
}

// MARK: - Decodable

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension FixedEmbeddingVector: Decodable {
  /// Decodes logical components, validating the fixed dimension count.
  ///
  /// ```swift
  /// import Foundation
  ///
  /// let payload = Data("[1,0,0]".utf8)
  /// let embedding = try JSONDecoder().decode(EmbeddingVector<3>.self, from: payload)
  /// let components = Array(embedding) // [1, 0, 0]; a different component count throws.
  /// ```
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
  /// A description of the vector and its logical components.
  ///
  /// ```swift
  /// let embedding = EmbeddingVector<3>([1, 0, 0])
  /// print(embedding.description) // EmbeddingVector<3>([1.0, 0.0, 0.0])
  /// let codes = FixedEmbeddingVector<3, Int8>([1, 0, -1])
  /// print(codes.description) // FixedEmbeddingVector<3, Int8>([1, 0, -1])
  /// ```
  public var description: String {
    let name =
      switch Scalar.self {
      case is Float.Type: "EmbeddingVector<\(Self.count)>"
      case is Double.Type: "EmbeddingVector64<\(Self.count)>"
      default: "FixedEmbeddingVector<\(Self.count), \(Scalar.self)>"
      }
    return "\(name)(\(Array(self)))"
  }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension FixedEmbeddingVector: CustomDebugStringConvertible {
  /// A description of the vector and its logical components.
  ///
  /// ```swift
  /// let embedding = EmbeddingVector64<3>([1, 0, 0])
  /// print(embedding.debugDescription) // EmbeddingVector64<3>([1.0, 0.0, 0.0])
  /// ```
  public var debugDescription: String {
    self.description
  }
}

// MARK: - MutableCollection

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension FixedEmbeddingVector: MutableCollection {
  public typealias Element = Scalar
  public typealias Index = Int

  /// A logical component, accessed or updated by index.
  ///
  /// ```swift
  /// var embedding = EmbeddingVector<3>([1, 2, 3])
  /// embedding[0] = 0
  /// let components = Array(embedding) // [0, 2, 3]
  /// ```
  public subscript(position: Index) -> Element {
    _read {
      yield self.array[position]
    }
    _modify {
      yield &self.array[position]
    }
  }

  /// The index of the first logical component.
  ///
  /// ```swift
  /// var embedding = EmbeddingVector<3>([1, 2, 3])
  /// embedding[embedding.startIndex] = 0
  /// let components = Array(embedding) // [0, 2, 3]
  /// ```
  public var startIndex: Int {
    self.array.startIndex
  }

  /// The index one past the last logical component.
  ///
  /// ```swift
  /// let embedding = EmbeddingVector<3>([1, 2, 3])
  /// let lastComponent = embedding[embedding.index(before: embedding.endIndex)] // 3
  /// ```
  public var endIndex: Int {
    self.array.endIndex
  }

  /// Returns the following logical index.
  ///
  /// ```swift
  /// let embedding = EmbeddingVector<3>([1, 2, 3])
  /// let secondComponent = embedding[embedding.index(after: embedding.startIndex)] // 2
  /// ```
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
}
// MARK: - Precision Aliases

/// A fixed-size Float32 embedding vector with direct raw BLOB query binding.
///
/// ```swift
/// let embedding = EmbeddingVector<3>([1, 2, 3])
/// let lastComponent = embedding[embedding.index(before: embedding.endIndex)] // 3
/// ```
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
public typealias EmbeddingVector<let count: Int> = FixedEmbeddingVector<count, Float>

/// A fixed-size float64 embedding vector.
///
/// ```swift
/// let vector = EmbeddingVector64<3>([1, 2, 3])
/// let bytes = EmbeddingVector64<3>.VectorBytesRepresentation(queryOutput: vector)
/// let payload = bytes.vectorBytes // 24 raw bytes.
/// ```
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
public typealias EmbeddingVector64<let count: Int> = FixedEmbeddingVector<count, Double>

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension FixedEmbeddingVector {
  /// Creates a fixed-size vector from an array, validating its element count.
  /// Throws `VectorDecodingError.dimensionMismatch` when the counts differ.
  ///
  /// ```swift
  /// let components: [Float] = [0.1, 0.2, 0.3]
  /// let embedding = try EmbeddingVector<3>(validating: components)
  /// // An array with a different count throws VectorDecodingError.dimensionMismatch.
  /// ```
  public init(validating vectorElements: [Scalar]) throws {
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
  public typealias Dimensions = VectorDimensions<count>
  public typealias Encoding = [Scalar].VectorBytesRepresentation

  /// The serialized blob, including any metadata required by this encoding.
  ///
  /// ```swift
  /// let embedding = EmbeddingVector<1536>(repeating: 0)
  /// let payload = embedding.vectorBytes
  /// let byteCount = payload.count // 6144 bytes: 1536 Float32 components.
  /// ```
  public var vectorBytes: [UInt8] { Scalar.encodeVector(Array(self)) }

  /// Decodes a vector blob, validating its encoding and dimensions.
  ///
  /// ```swift
  /// let cachedBytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
  /// let embedding = try EmbeddingVector<3>(vectorBytes: cachedBytes)
  /// let components = Array(embedding) // [1, 0, 0]; a different component count throws.
  /// ```
  public init(vectorBytes: [UInt8]) throws {
    try self.init(validating: Scalar.decodeVector(vectorBytes))
  }

  /// The scalar's default blob representation with fixed-dimension validation.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: EmbeddingVector64<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector64<3>
  /// }
  ///
  /// let components: EmbeddingVector64<3> = EmbeddingVector64<3>([0.1, 0.2, 0.3])
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, components)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public struct VectorBytesRepresentation:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias Scalar = Element
    public typealias Dimensions = VectorDimensions<count>
    public typealias Encoding = [Element].VectorBytesRepresentation
    public typealias VectorBytesRepresentation = Self
    /// The logical vector value bound to or decoded from a query.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = Double.encodeVector([1, 0, 0])
    /// let decoded = try EmbeddingVector64<3>.VectorBytesRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [1, 0, 0]
    /// ```
    public var queryOutput: FixedEmbeddingVector<count, Element>

    /// Wraps the logical vector value for blob storage and query binding.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: EmbeddingVector64<3>.VectorBytesRepresentation.self)
    ///   var embedding: EmbeddingVector64<3>
    /// }
    ///
    /// let vector = EmbeddingVector64<3>
    ///   .VectorBytesRepresentation(queryOutput: EmbeddingVector64<3>([1, 2, 3]))
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, vector)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public init(queryOutput: FixedEmbeddingVector<count, Element>) {
      self.queryOutput = queryOutput
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = EmbeddingVector64<3>
    ///   .VectorBytesRepresentation(queryOutput: EmbeddingVector64<3>([1, 2, 3]))
    /// let vectorBytes = vector.vectorBytes
    /// // 24 raw bytes for three Float64 components.
    /// ```
    public var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = Double.encodeVector([1, 0, 0])
    /// let decoded = try EmbeddingVector64<3>.VectorBytesRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [1, 0, 0]
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      try self.init(queryOutput: FixedEmbeddingVector<count, Element>(vectorBytes: vectorBytes))
    }
  }
}
