import StructuredQueriesCore
import StructuredQueriesVectorCore

/// A Turso Float32 BLOB strategy backed by a raw floating-point representation.
///
/// Writes raw Float32 payloads and also accepts the optional Float32 type byte when decoding.
/// Use the `.TursoFloat32BytesRepresentation` aliases on arrays, inline arrays, and fixed-size vectors.
///
/// ```swift
/// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
/// let expression = TursoVec.distanceL2(vector, to: vector)
/// // vector_distance_l2(?, ?)
/// ```
public struct TursoFloat32BytesRepresentation<Representation>:
  Hashable, Sendable, QueryBindable, VectorBytesRepresentable
where
  Representation: VectorBytesRepresentable & QueryBindable & Hashable & Sendable,
  Representation.Scalar == Float, Representation.Encoding == [Float].VectorBytesRepresentation
{
  public typealias Scalar = Float
  public typealias QueryOutput = Representation.QueryOutput
  public typealias Encoding = [Float].VectorBytesRepresentation
  public typealias VectorBytesRepresentation = Self

  private var representation: Representation

  /// The logical components represented by this BLOB strategy.
  ///
  /// ```swift
  /// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
  /// let values = vector.queryOutput
  /// ```
  public var queryOutput: QueryOutput {
    get { self.representation.queryOutput }
    set { self.representation = Representation(queryOutput: newValue) }
  }

  /// Wraps logical components for Turso binding and decoding.
  ///
  /// ```swift
  /// let vector = [Float].TursoFloat32BytesRepresentation(queryOutput: [1, 2, 3])
  /// ```
  public init(queryOutput: QueryOutput) {
    self.representation = Representation(queryOutput: queryOutput)
  }

  /// The encoded Turso BLOB, including the format metadata this precision requires.
  ///
  /// ```swift
  /// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
  /// let bytes = vector.vectorBytes
  /// ```
  public var vectorBytes: [UInt8] { self.representation.vectorBytes }

  /// Validates the Turso format and delegates payload and dimension validation to the raw strategy.
  ///
  /// ```swift
  /// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
  /// let restored = try [Float].TursoFloat32BytesRepresentation(vectorBytes: vector.vectorBytes)
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
  /// let vector: [Float].TursoFloat32BytesRepresentation = [1, 2, 3]
  /// ```
  public init(arrayLiteral elements: Float...) {
    self.init(queryOutput: elements)
  }
}

extension Array where Element == Float {
  /// The Turso Float32 BLOB strategy for a scalar array.
  ///
  /// ```swift
  /// @Table
  /// struct Document {
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
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
/// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
/// let expression = TursoVec.distanceL2(vector, to: vector)
/// // vector_distance_l2(?, ?)
/// ```
public struct TursoFloat64BytesRepresentation<Representation>:
  Hashable, Sendable, QueryBindable, VectorBytesRepresentable
where
  Representation: VectorBytesRepresentable & QueryBindable & Hashable & Sendable,
  Representation.Scalar == Double, Representation.Encoding == [Double].VectorBytesRepresentation
{
  public typealias Scalar = Double
  public typealias QueryOutput = Representation.QueryOutput
  public typealias Encoding = StructuredQueriesTursoVecCore.TursoFloat64BytesRepresentation<
    [Double].VectorBytesRepresentation
  >
  public typealias VectorBytesRepresentation = Self

  private var representation: Representation

  /// The logical components represented by this BLOB strategy.
  ///
  /// ```swift
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
  /// let values = vector.queryOutput
  /// ```
  public var queryOutput: QueryOutput {
    get { self.representation.queryOutput }
    set { self.representation = Representation(queryOutput: newValue) }
  }

  /// Wraps logical components for Turso binding and decoding.
  ///
  /// ```swift
  /// let vector = [Double].TursoFloat64BytesRepresentation(queryOutput: [1, 2, 3])
  /// ```
  public init(queryOutput: QueryOutput) {
    self.representation = Representation(queryOutput: queryOutput)
  }

  /// The encoded Turso BLOB, including the format metadata this precision requires.
  ///
  /// ```swift
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
  /// let bytes = vector.vectorBytes
  /// ```
  public var vectorBytes: [UInt8] { self.representation.vectorBytes + [2] }

  /// Validates the Turso format and delegates payload and dimension validation to the raw strategy.
  ///
  /// ```swift
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
  /// let restored = try [Double].TursoFloat64BytesRepresentation(vectorBytes: vector.vectorBytes)
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
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, 2, 3]
  /// ```
  public init(arrayLiteral elements: Double...) {
    self.init(queryOutput: elements)
  }
}

extension Array where Element == Double {
  /// The Turso Float64 BLOB strategy for a scalar array.
  ///
  /// ```swift
  /// @Table
  /// struct Document {
  ///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
  ///   var embedding: [Double]
  /// }
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
    /// @Table
    /// struct Document {
    ///   @Column(as: InlineArray<3, Float>.TursoFloat32BytesRepresentation.self)
    ///   var embedding: InlineArray<3, Float>
    /// }
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
    /// @Table
    /// struct Document {
    ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
    ///   var embedding: EmbeddingVector<3>
    /// }
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
    /// @Table
    /// struct Document {
    ///   @Column(as: InlineArray<3, Double>.TursoFloat64BytesRepresentation.self)
    ///   var embedding: InlineArray<3, Double>
    /// }
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
    /// @Table
    /// struct Document {
    ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
    ///   var embedding: EmbeddingVector64<3>
    /// }
    /// ```
    public typealias TursoFloat64BytesRepresentation = StructuredQueriesTursoVecCore
      .TursoFloat64BytesRepresentation<
        VectorBytesRepresentation
      >
  }
#endif
