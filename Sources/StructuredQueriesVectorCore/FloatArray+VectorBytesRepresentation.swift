import StructuredQueriesCore

// MARK: - Array

extension Array where Element: VectorScalar {
  /// The scalar's default vector blob representation.
  ///
  /// Each component uses its complete little-endian bit pattern, without format metadata.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let components: [Float] = [0.1, 0.2, 0.3]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, components)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public struct VectorBytesRepresentation:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias Scalar = Element
    public typealias Dimensions = Void
    public typealias Encoding = [Element].VectorBytesRepresentation
    public typealias VectorBytesRepresentation = Self
    /// The logical vector value bound to or decoded from a query.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = Float.encodeVector([1, 0, 0])
    /// let decoded = try [Float].VectorBytesRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [1, 0, 0]
    /// ```
    public var queryOutput: [Element]

    /// Wraps the logical vector value for blob storage and query binding.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: [Float].VectorBytesRepresentation.self)
    ///   var embedding: [Float]
    /// }
    ///
    /// let vector = [Float].VectorBytesRepresentation(queryOutput: [1, 2, 3])
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, vector)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public init(queryOutput: [Element]) {
      self.queryOutput = queryOutput
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = [Float].VectorBytesRepresentation(queryOutput: [1, 2, 3])
    /// let vectorBytes = vector.vectorBytes
    /// // 12 raw bytes for three Float32 components.
    /// ```
    public var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = Float.encodeVector([1, 0, 0])
    /// let decoded = try [Float].VectorBytesRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [1, 0, 0]
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
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let vector: [Float].VectorBytesRepresentation = [1, 2, 3]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, vector)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
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
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: InlineArray<3, Float>.VectorBytesRepresentation.self)
    ///   var embedding: InlineArray<3, Float>
    /// }
    ///
    /// let components: InlineArray<3, Float> = [0.1, 0.2, 0.3]
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
      /// let storedBytes: [UInt8] = Float.encodeVector([1, 0, 0])
      /// let decoded = try InlineArray<3, Float>.VectorBytesRepresentation(vectorBytes: storedBytes)
      /// let components = (0..<3).map { decoded.queryOutput[$0] } // [1, 0, 0]
      /// ```
      public var queryOutput: InlineArray<count, Element>

      /// Wraps the logical vector value for blob storage and query binding.
      ///
      /// ```swift
      /// @Table("documents")
      /// struct Document {
      ///   var id: Int
      ///   @Column(as: InlineArray<3, Float>.VectorBytesRepresentation.self)
      ///   var embedding: InlineArray<3, Float>
      /// }
      ///
      /// let components: InlineArray<3, Float> = [1, 2, 3]
      /// let vector = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: components)
      /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
      ///   (1, vector)
      /// }
      /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
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
      /// // 12 raw bytes for three Float32 components.
      /// ```
      public var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

      /// Decodes a vector blob, validating its encoding and dimensions.
      ///
      /// ```swift
      /// let storedBytes: [UInt8] = Float.encodeVector([1, 0, 0])
      /// let decoded = try InlineArray<3, Float>.VectorBytesRepresentation(vectorBytes: storedBytes)
      /// let components = (0..<3).map { decoded.queryOutput[$0] } // [1, 0, 0]
      /// ```
      public init(vectorBytes: [UInt8]) throws {
        try self.init(queryOutput: InlineArray<count, Element>(vectorBytes: vectorBytes))
      }

      /// Compares the vector components for equality.
      ///
      /// ```swift
      /// let left = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: [-0.0, 1, 2])
      /// let right = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: [0.0, 1, 2])
      /// let equal = left == right // true: signed zeros compare equally.
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
      /// let duplicate = InlineArray<3, Float>.VectorBytesRepresentation(queryOutput: [1, 2, 3])
      /// let uniqueCount = Set([vector, duplicate]).count // 1
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
