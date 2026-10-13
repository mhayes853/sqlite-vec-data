import StructuredQueriesCore

extension Array where Element == Int8 {
  /// Raw signed bytes for SQLiteVec Int8 columns, with one byte per component.
  ///
  /// Use `Vec.int8` when inserting or passing a bound blob to SQLiteVec functions so that the
  /// expression carries SQLiteVec's Int8 subtype. This format has no scale, shift, or type metadata
  /// and differs from Turso's `Quantized8Vector`.
  ///
  /// ```swift
  /// @Table
  /// struct Document {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  /// }
  /// ```
  public struct Int8BytesRepresentation:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias Scalar = Int8
    public typealias Dimensions = Void
    public typealias Encoding = Self
    public typealias VectorBytesRepresentation = Self
    /// The logical vector value bound to or decoded from a query.
    ///
    /// ```swift
    /// let vector = [Int8].Int8BytesRepresentation(queryOutput: [1, -2, 3])
    /// let queryOutput = vector.queryOutput
    /// ```
    public var queryOutput: [Int8]

    /// Wraps the logical vector value for blob storage and query binding.
    ///
    /// ```swift
    /// let vector = [Int8].Int8BytesRepresentation(queryOutput: [1, -2, 3])
    /// ```
    public init(queryOutput: [Int8]) {
      self.queryOutput = queryOutput
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = [Int8].Int8BytesRepresentation(queryOutput: [1, -2, 3])
    /// let vectorBytes = vector.vectorBytes
    /// ```
    public var vectorBytes: [UInt8] { self.queryOutput.map(UInt8.init(bitPattern:)) }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let vector = [Int8].Int8BytesRepresentation(queryOutput: [1, -2, 3])
    /// let restored = try [Int8].Int8BytesRepresentation(vectorBytes: vector.vectorBytes)
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      self.init(queryOutput: vectorBytes.map(Int8.init(bitPattern:)))
    }
  }
}

extension Array.Int8BytesRepresentation: ExpressibleByArrayLiteral {
  /// Creates a vector representation from an array literal.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3]
  /// ```
  public init(arrayLiteral elements: Int8...) {
    self.init(queryOutput: elements)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Int8 {
    /// Raw signed bytes for SQLiteVec Int8 columns, validating fixed dimensions when decoding.
    ///
    /// ```swift
    /// @Table
    /// struct Document {
    ///   @Column(as: FixedEmbeddingVector<3, Int8>.Int8BytesRepresentation.self)
    ///   var embedding: FixedEmbeddingVector<3, Int8>
    /// }
    /// ```
    public struct Int8BytesRepresentation:
      Hashable, Sendable, QueryBindable, VectorBytesRepresentable
    {
      public typealias Scalar = Int8
      public typealias Dimensions = VectorDimensions<count>
      public typealias Encoding = [Int8].Int8BytesRepresentation
      public typealias VectorBytesRepresentation = Self
      /// The logical vector value bound to or decoded from a query.
      ///
      /// ```swift
      /// let vector = FixedEmbeddingVector<3, Int8>
      ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<3, Int8>([1, -2, 3]))
      /// let queryOutput = vector.queryOutput
      /// ```
      public var queryOutput: FixedEmbeddingVector<count, Int8>

      /// Wraps the logical vector value for blob storage and query binding.
      ///
      /// ```swift
      /// let vector = FixedEmbeddingVector<3, Int8>
      ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<3, Int8>([1, -2, 3]))
      /// ```
      public init(queryOutput: FixedEmbeddingVector<count, Int8>) {
        self.queryOutput = queryOutput
      }

      /// The serialized blob, including any metadata required by this encoding.
      ///
      /// ```swift
      /// let vector = FixedEmbeddingVector<3, Int8>
      ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<3, Int8>([1, -2, 3]))
      /// let vectorBytes = vector.vectorBytes
      /// ```
      public var vectorBytes: [UInt8] { self.queryOutput.map(UInt8.init(bitPattern:)) }

      /// Decodes a vector blob, validating its encoding and dimensions.
      ///
      /// ```swift
      /// let vector = FixedEmbeddingVector<3, Int8>
      ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<3, Int8>([1, -2, 3]))
      /// let restored = try FixedEmbeddingVector<3, Int8>
      ///   .Int8BytesRepresentation(vectorBytes: vector.vectorBytes)
      /// ```
      public init(vectorBytes: [UInt8]) throws {
        try self.init(
          queryOutput: FixedEmbeddingVector<count, Int8>(
            validating: vectorBytes.map(Int8.init(bitPattern:))
          )
        )
      }
    }
  }
#endif
