import StructuredQueriesCore
import StructuredQueriesVectorCore

/// A Turso Float32 BLOB strategy backed by a raw floating-point representation.
///
/// Writes raw Float32 payloads and also accepts the optional Float32 type byte when decoding.
/// Use the `.TursoFloat32BytesRepresentation` aliases on arrays, inline arrays, and fixed-size vectors.
///
/// ```swift
/// @Table("documents")
/// struct Document {
///   var id: Int
///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
///   var embedding: [Float]
/// }
///
/// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
/// let insert = Document.insert { ($0.id, $0.embedding) } values: {
///   (1, vector)
/// }
/// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
/// ```
public struct TursoFloat32BytesRepresentation<Representation>:
  Hashable, Sendable, QueryBindable, VectorBytesRepresentable
where
  Representation: VectorBytesRepresentable & QueryBindable & Hashable & Sendable,
  Representation.Scalar == Float, Representation.Encoding == [Float].VectorBytesRepresentation
{
  public typealias Scalar = Float
  public typealias Dimensions = Representation.Dimensions
  public typealias QueryOutput = Representation.QueryOutput
  public typealias Encoding = [Float].VectorBytesRepresentation
  public typealias VectorBytesRepresentation = Self

  private var representation: Representation

  /// The logical components represented by this BLOB strategy.
  ///
  /// ```swift
  /// let storedBytes: [UInt8] = Float.encodeVector([1, 0, 0])
  /// let decoded = try [Float].TursoFloat32BytesRepresentation(vectorBytes: storedBytes)
  /// let components = Array(decoded.queryOutput) // [1, 0, 0]
  /// ```
  public var queryOutput: QueryOutput {
    get { self.representation.queryOutput }
    set { self.representation = Representation(queryOutput: newValue) }
  }

  /// Wraps logical components for Turso binding and decoding.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let vector = [Float].TursoFloat32BytesRepresentation(queryOutput: [1, 2, 3])
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, vector)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public init(queryOutput: QueryOutput) {
    self.representation = Representation(queryOutput: queryOutput)
  }

  /// The encoded Turso BLOB, including the format metadata this precision requires.
  ///
  /// ```swift
  /// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
  /// let bytes = vector.vectorBytes
  /// // 12 raw bytes for three Float32 components.
  /// ```
  public var vectorBytes: [UInt8] { self.representation.vectorBytes }

  /// Validates the Turso format and delegates payload and dimension validation to the raw strategy.
  ///
  /// ```swift
  /// let storedBytes: [UInt8] = Float.encodeVector([1, 0, 0]) + [1]
  /// let decoded = try [Float].TursoFloat32BytesRepresentation(vectorBytes: storedBytes)
  /// let components = Array(decoded.queryOutput) // [1, 0, 0]
  /// // The strategy validates format metadata before exposing logical components.
  /// ```
  public init(vectorBytes: [UInt8]) throws {
    let payload =
      vectorBytes.count % 4 == 1 && vectorBytes.last == 1
      ? Array(vectorBytes.dropLast()) : vectorBytes
    try self.init(queryOutput: Representation(vectorBytes: payload).queryOutput)
  }
}

extension TursoFloat32BytesRepresentation: ExpressibleByArrayLiteral
where Representation == [Float].VectorBytesRepresentation {
  /// Creates a Turso floating-point BLOB representation from an array literal.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, vector)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public init(arrayLiteral elements: Float...) {
    self.init(queryOutput: elements)
  }
}

extension Array where Element == Float {
  /// The Turso Float32 BLOB strategy for a scalar array.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let components: [Float] = [0.1, 0.2, 0.3]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, components)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public typealias TursoFloat32BytesRepresentation = StructuredQueriesTursoVecCore
    .TursoFloat32BytesRepresentation<VectorBytesRepresentation>
}

/// A Turso Float64 BLOB strategy backed by a raw floating-point representation.
///
/// Writes and validates Turso's trailing Float64 type byte.
/// Use the `.TursoFloat64BytesRepresentation` aliases on arrays, inline arrays, and fixed-size vectors.
///
/// ```swift
/// @Table("documents")
/// struct Document {
///   var id: Int
///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
///   var embedding: [Double]
/// }
///
/// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
/// let insert = Document.insert { ($0.id, $0.embedding) } values: {
///   (1, vector)
/// }
/// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
/// ```
public struct TursoFloat64BytesRepresentation<Representation>:
  Hashable, Sendable, QueryBindable, VectorBytesRepresentable
where
  Representation: VectorBytesRepresentable & QueryBindable & Hashable & Sendable,
  Representation.Scalar == Double, Representation.Encoding == [Double].VectorBytesRepresentation
{
  public typealias Scalar = Double
  public typealias Dimensions = Representation.Dimensions
  public typealias QueryOutput = Representation.QueryOutput
  public typealias Encoding = StructuredQueriesTursoVecCore.TursoFloat64BytesRepresentation<
    [Double].VectorBytesRepresentation
  >
  public typealias VectorBytesRepresentation = Self

  private var representation: Representation

  /// The logical components represented by this BLOB strategy.
  ///
  /// ```swift
  /// let storedBytes: [UInt8] = Double.encodeVector([1, 0, 0]) + [2]
  /// let decoded = try [Double].TursoFloat64BytesRepresentation(vectorBytes: storedBytes)
  /// let components = Array(decoded.queryOutput) // [1, 0, 0]
  /// ```
  public var queryOutput: QueryOutput {
    get { self.representation.queryOutput }
    set { self.representation = Representation(queryOutput: newValue) }
  }

  /// Wraps logical components for Turso binding and decoding.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
  ///   var embedding: [Double]
  /// }
  ///
  /// let vector = [Double].TursoFloat64BytesRepresentation(queryOutput: [1, 2, 3])
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, vector)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public init(queryOutput: QueryOutput) {
    self.representation = Representation(queryOutput: queryOutput)
  }

  /// The encoded Turso BLOB, including the format metadata this precision requires.
  ///
  /// ```swift
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
  /// let bytes = vector.vectorBytes
  /// // 25 bytes: three Float64 components and the required type byte.
  /// ```
  public var vectorBytes: [UInt8] { self.representation.vectorBytes + [2] }

  /// Validates the Turso format and delegates payload and dimension validation to the raw strategy.
  ///
  /// ```swift
  /// let storedBytes: [UInt8] = Double.encodeVector([1, 0, 0]) + [2]
  /// let decoded = try [Double].TursoFloat64BytesRepresentation(vectorBytes: storedBytes)
  /// let components = Array(decoded.queryOutput) // [1, 0, 0]
  /// // The strategy validates format metadata before exposing logical components.
  /// ```
  public init(vectorBytes: [UInt8]) throws {
    guard vectorBytes.last == 2 else { throw VectorDecodingError.invalidBytes }
    let payload = Array(vectorBytes.dropLast())
    try self.init(queryOutput: Representation(vectorBytes: payload).queryOutput)
  }
}

extension TursoFloat64BytesRepresentation: ExpressibleByArrayLiteral
where Representation == [Double].VectorBytesRepresentation {
  /// Creates a Turso floating-point BLOB representation from an array literal.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
  ///   var embedding: [Double]
  /// }
  ///
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, vector)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public init(arrayLiteral elements: Double...) {
    self.init(queryOutput: elements)
  }
}

extension Array where Element == Double {
  /// The Turso Float64 BLOB strategy for a scalar array.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
  ///   var embedding: [Double]
  /// }
  ///
  /// let components: [Double] = [0.1, 0.2, 0.3]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, components)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public typealias TursoFloat64BytesRepresentation = StructuredQueriesTursoVecCore
    .TursoFloat64BytesRepresentation<VectorBytesRepresentation>
}

#if swift(>=6.2)

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray where Element == Float {
    /// The Turso Float32 strategy with fixed-dimension validation.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: InlineArray<3, Float>.TursoFloat32BytesRepresentation.self)
    ///   var embedding: InlineArray<3, Float>
    /// }
    ///
    /// let components: InlineArray<3, Float> = [0.1, 0.2, 0.3]
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, components)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public typealias TursoFloat32BytesRepresentation = StructuredQueriesTursoVecCore
      .TursoFloat32BytesRepresentation<
        VectorBytesRepresentation
      >
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Float {
    /// The Turso Float32 strategy with fixed-dimension validation.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
    ///   var embedding: EmbeddingVector<3>
    /// }
    ///
    /// let components: EmbeddingVector<3> = EmbeddingVector<3>([0.1, 0.2, 0.3])
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, components)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public typealias TursoFloat32BytesRepresentation = StructuredQueriesTursoVecCore
      .TursoFloat32BytesRepresentation<
        VectorBytesRepresentation
      >
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray where Element == Double {
    /// The Turso Float64 strategy with fixed-dimension validation.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: InlineArray<3, Double>.TursoFloat64BytesRepresentation.self)
    ///   var embedding: InlineArray<3, Double>
    /// }
    ///
    /// let components: InlineArray<3, Double> = [0.1, 0.2, 0.3]
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, components)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public typealias TursoFloat64BytesRepresentation = StructuredQueriesTursoVecCore
      .TursoFloat64BytesRepresentation<
        VectorBytesRepresentation
      >
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Double {
    /// The Turso Float64 strategy with fixed-dimension validation.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
    ///   var embedding: EmbeddingVector64<3>
    /// }
    ///
    /// let components: EmbeddingVector64<3> = EmbeddingVector64<3>([0.1, 0.2, 0.3])
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, components)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public typealias TursoFloat64BytesRepresentation = StructuredQueriesTursoVecCore
      .TursoFloat64BytesRepresentation<
        VectorBytesRepresentation
      >
  }
#endif
