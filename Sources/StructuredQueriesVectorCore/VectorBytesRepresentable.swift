import StructuredQueriesCore

/// A vector value or query representation with a known scalar type and byte layout.
///
/// ```swift
/// // A cached Float32 payload containing [1, 0, 0].
/// let cachedBytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
/// let embedding = try EmbeddingVector<3>(vectorBytes: cachedBytes)
/// let components = Array(embedding) // [1, 0, 0]
/// ```
public protocol VectorBytesRepresentable {
  /// The vector's numeric or logical scalar type.
  associatedtype Scalar
  /// The type identifying a known logical component count, independently of the byte format.
  /// `Void` leaves dimensions to runtime validation. Fixed representations use `VectorDimensions<N>`.
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
  associatedtype Dimensions = Void
  /// The canonical representation identifying the byte layout, independent of dimensions.
  /// For example, both dense float32 arrays and inline vectors use
  /// `[Float].VectorBytesRepresentation`. Its logical scalar must match this value's scalar;
  /// its dimensions are independent of this value's dimensions.
  associatedtype Encoding: VectorBytesRepresentable & QueryBindable
  where Encoding.Scalar == Scalar
  /// The query representation for this value, preserving its scalar, byte layout, and dimensions.
  /// Use it with `@Column(as:)` to store and bind logical vector values as BLOBs.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let embedding: [Float] = [0.1, 0.2, 0.3]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  associatedtype VectorBytesRepresentation: VectorBytesRepresentable & QueryBindable
  where
    VectorBytesRepresentation.Scalar == Scalar,
    VectorBytesRepresentation.Encoding == Encoding,
    VectorBytesRepresentation.Dimensions == Dimensions

  /// The serialized vector, including any metadata required by its encoding.
  ///
  /// ```swift
  /// let bytes = [Float(1), 2, 3].vectorBytes
  /// let payloadSize = bytes.count // 12 bytes for three Float32 components.
  /// ```
  var vectorBytes: [UInt8] { get }

  /// Decodes vector bytes, validating the encoding and any fixed dimension count.
  ///
  /// ```swift
  /// let cachedBytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
  /// let embedding = try [Float](vectorBytes: cachedBytes)
  /// let components = Array(embedding) // [1, 0, 0]
  /// ```
  init(vectorBytes: [UInt8]) throws
}

extension VectorBytesRepresentable where Self: QueryBindable {
  /// Binds the encoded vector as a SQLite blob.
  ///
  /// ```swift
  /// let embedding: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let statement: QueryFragment = "SELECT \(embedding.queryBinding)"
  /// let prepared = statement.prepare { "?\($0)" }
  /// // SELECT ?1
  /// // Pass prepared.sql and prepared.bindings (one Float32 BLOB) to your database driver.
  /// ```
  public var queryBinding: QueryBinding { .blob(self.vectorBytes) }

  /// Decodes a vector from a query's blob column.
  ///
  /// ```swift
  /// struct CachedEmbedding: Hashable, Sendable, QueryBindable, VectorBytesRepresentable {
  ///   typealias Scalar = Float
  ///   typealias Dimensions = Void
  ///   typealias Encoding = [Float].VectorBytesRepresentation
  ///   typealias VectorBytesRepresentation = Self
  ///
  ///   var queryOutput: [Float]
  ///   init(queryOutput: [Float]) { self.queryOutput = queryOutput }
  ///   var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }
  ///   init(vectorBytes: [UInt8]) throws {
  ///     try self.init(queryOutput: [Float](vectorBytes: vectorBytes))
  ///   }
  ///   // Query decoding uses init(vectorBytes:) to validate a returned BLOB.
  /// }
  /// let embedding = CachedEmbedding(queryOutput: [0.1, 0.2, 0.3])
  /// let binding = embedding.queryBinding // A 12-byte Float32 BLOB.
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
  /// let payloadSize = bytes.count // 12 bytes for three Float32 components.
  /// ```
  public var vectorBytes: [UInt8] { Element.encodeVector(self) }

  /// Decodes a vector blob, validating its encoding and dimensions.
  ///
  /// ```swift
  /// let cachedBytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
  /// let embedding = try [Float](vectorBytes: cachedBytes)
  /// let components = Array(embedding) // [1, 0, 0]
  /// ```
  public init(vectorBytes: [UInt8]) throws {
    self = try Element.decodeVector(vectorBytes)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray: VectorBytesRepresentable where Element: VectorScalar {
    public typealias Scalar = Element
    public typealias Dimensions = VectorDimensions<count>
    public typealias Encoding = [Element].VectorBytesRepresentation

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let values: InlineArray<3, Float> = [1, 2, 3]
    /// let bytes = values.vectorBytes
    /// let payloadSize = bytes.count // 12 bytes for three Float32 components.
    /// ```
    public var vectorBytes: [UInt8] {
      Element.encodeVector((0..<Self.count).map { self[$0] })
    }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let cachedBytes: [UInt8] = [0, 0, 0x80, 0x3f, 0, 0, 0, 0, 0, 0, 0, 0]
    /// let embedding = try InlineArray<3, Float>(vectorBytes: cachedBytes)
    /// let components = (0..<3).map { embedding[$0] } // [1, 0, 0]
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
