import StructuredQueriesCore

// MARK: - Array

extension Array where Element: VectorScalar {
  /// The scalar's default vector blob representation.
  ///
  /// Float uses raw float32 bytes, shared with SQLiteVec on little-endian platforms.
  /// Double uses Turso's tagged float64 format.
  ///
  /// ```swift
  /// @Table
  /// struct Document {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  /// ```
  public struct VectorBytesRepresentation:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias Scalar = Element
    public typealias Encoding = [Element].VectorBytesRepresentation
    public typealias VectorBytesRepresentation = Self
    /// The logical vector value bound to or decoded from a query.
    ///
    /// ```swift
    /// let vector = [Float].VectorBytesRepresentation(queryOutput: [1, 2, 3])
    /// let queryOutput = vector.queryOutput
    /// ```
    public var queryOutput: [Element]

    /// Wraps the logical vector value for blob storage and query binding.
    ///
    /// ```swift
    /// let vector = [Float].VectorBytesRepresentation(queryOutput: [1, 2, 3])
    /// ```
    public init(queryOutput: [Element]) {
      self.queryOutput = queryOutput
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = [Float].VectorBytesRepresentation(queryOutput: [1, 2, 3])
    /// let vectorBytes = vector.vectorBytes
    /// ```
    public var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let vector = [Float].VectorBytesRepresentation(queryOutput: [1, 2, 3])
    /// let restored = try [Float].VectorBytesRepresentation(vectorBytes: vector.vectorBytes)
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      try self.init(queryOutput: [Element](vectorBytes: vectorBytes))
    }
  }
}

extension Array.VectorBytesRepresentation: ExpressibleByArrayLiteral {
  /// Creates a vector representation from an array literal.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
  /// ```
  public init(arrayLiteral elements: Element...) {
    self.init(queryOutput: elements)
  }
}

// MARK: - InlineArray

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray where Element: VectorScalar {
    /// The scalar's default blob representation with fixed-dimension validation.
    ///
    /// ```swift
    /// @Table
    /// struct Document {
    ///   @Column(as: InlineArray<3, Float>.VectorBytesRepresentation.self)
    ///   var embedding: InlineArray<3, Float>
    /// }
    /// ```
    public struct VectorBytesRepresentation:
      Hashable, Sendable, QueryBindable, VectorBytesRepresentable
    {
      public typealias Scalar = Element
      public typealias Encoding = [Element].VectorBytesRepresentation
      public typealias VectorBytesRepresentation = Self
      /// The logical vector value bound to or decoded from a query.
      ///
      /// ```swift
      /// let components: InlineArray<3, Float> = [1, 2, 3]
      /// let vector = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: components)
      /// let queryOutput = vector.queryOutput
      /// ```
      public var queryOutput: InlineArray<count, Element>

      /// Wraps the logical vector value for blob storage and query binding.
      ///
      /// ```swift
      /// let components: InlineArray<3, Float> = [1, 2, 3]
      /// let vector = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: components)
      /// ```
      public init(queryOutput: InlineArray<count, Element>) {
        self.queryOutput = queryOutput
      }

      /// The serialized blob, including any metadata required by this encoding.
      ///
      /// ```swift
      /// let components: InlineArray<3, Float> = [1, 2, 3]
      /// let vector = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: components)
      /// let vectorBytes = vector.vectorBytes
      /// ```
      public var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

      /// Decodes a vector blob, validating its encoding and dimensions.
      ///
      /// ```swift
      /// let components: InlineArray<3, Float> = [1, 2, 3]
      /// let vector = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: components)
      /// let restored = try InlineArray<3, Float>.VectorBytesRepresentation(vectorBytes: vector.vectorBytes)
      /// ```
      public init(vectorBytes: [UInt8]) throws {
        try self.init(queryOutput: InlineArray<count, Element>(vectorBytes: vectorBytes))
      }

      /// Compares the vector components for equality.
      ///
      /// ```swift
      /// let components: InlineArray<3, Float> = [1, 2, 3]
      /// let vector = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: components)
      /// let equal = vector == vector
      /// ```
      public static func == (lhs: Self, rhs: Self) -> Bool {
        (0..<InlineArray<count, Element>.count)
          .allSatisfy { lhs.queryOutput[$0] == rhs.queryOutput[$0] }
      }

      /// Hashes the vector components.
      ///
      /// ```swift
      /// let components: InlineArray<3, Float> = [1, 2, 3]
      /// let vector = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: components)
      /// let vectors = Set([vector])
      /// ```
      public func hash(into hasher: inout Hasher) {
        hasher.combine(InlineArray<count, Element>.count)
        for index in 0..<InlineArray<count, Element>.count {
          hasher.combine(self.queryOutput[index])
        }
      }
    }
  }
#endif
