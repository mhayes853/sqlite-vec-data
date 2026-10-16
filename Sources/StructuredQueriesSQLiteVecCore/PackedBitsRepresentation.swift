import StructuredQueriesCore
import StructuredQueriesVectorCore

extension Array where Element == Bool {
  /// SQLiteVec binary BLOB storage without metadata. Dimensions must be divisible by eight.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Bool].PackedBitsRepresentation.self)
  ///   var embedding: [Bool]
  /// }
  ///
  /// let components: [Bool] = [true, false, true, false, false, false, false, true]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, components)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public struct PackedBitsRepresentation:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias Scalar = Bool
    public typealias Dimensions = Void
    public typealias Encoding = [Bool].PackedBitsRepresentation
    public typealias VectorBytesRepresentation = Self
    /// The logical vector value bound to or decoded from a query.
    /// Assignments require a dimension count divisible by eight.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = [0x85]
    /// let decoded = try [Bool].PackedBitsRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [true, false, true, false, false, false, false, true]
    /// ```
    public var queryOutput: [Bool] {
      get { self.elements }
      set {
        precondition(
          newValue.count.isMultiple(of: 8),
          "Packed bit vectors require a multiple of 8 dimensions"
        )
        self.elements = newValue
      }
    }

    private var elements: [Bool]

    /// Wraps logical components, preconditioning that dimensions are divisible by eight.
    /// Use `init(validating:)` for a recoverable validation error.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: [Bool].PackedBitsRepresentation.self)
    ///   var embedding: [Bool]
    /// }
    ///
    /// let vector = [Bool]
    ///   .PackedBitsRepresentation(queryOutput: [true, false, true, false, false, false, false, true])
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, vector)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public init(queryOutput: [Bool]) {
      precondition(
        queryOutput.count.isMultiple(of: 8),
        "Packed bit vectors require a multiple of 8 dimensions"
      )
      self.elements = queryOutput
    }

    /// Validates dynamic binary components before wrapping them for SQLiteVec.
    ///
    /// ```swift
    /// let components = [Bool](repeating: true, count: 16)
    /// let bits = try [Bool].PackedBitsRepresentation(validating: components)
    /// let payload = bits.vectorBytes // [0xff, 0xff]; partial bytes throw instead of trapping.
    /// ```
    public init(validating elements: [Bool]) throws {
      guard elements.count.isMultiple(of: 8) else {
        throw InvalidDimensionsError(dimensions: elements.count)
      }
      self.init(queryOutput: elements)
    }

    /// A binary component count that cannot be represented as complete bytes.
    ///
    /// ```swift
    /// do {
    ///   _ = try [Bool].PackedBitsRepresentation(validating: [Bool](repeating: true, count: 9))
    /// } catch let error as [Bool].PackedBitsRepresentation.InvalidDimensionsError {
    ///   print("Received \(error.dimensions) bits; SQLiteVec requires complete bytes.")
    /// }
    /// ```
    public struct InvalidDimensionsError: Error, Hashable, Sendable {
      /// The rejected logical dimension count.
      ///
      /// ```swift
      /// do {
      ///   _ = try [Bool].PackedBitsRepresentation(validating: [Bool](repeating: true, count: 9))
      /// } catch let error as [Bool].PackedBitsRepresentation.InvalidDimensionsError {
      ///   print("Received \(error.dimensions) bits; SQLiteVec requires complete bytes.")
      /// }
      /// ```
      public let dimensions: Int

      /// Records a component count that is not divisible by eight.
      ///
      /// ```swift
      /// func validateAlignment(_ components: [Bool]) throws {
      ///   guard components.count.isMultiple(of: 8) else {
      ///     throw [Bool].PackedBitsRepresentation.InvalidDimensionsError(dimensions: components.count)
      ///   }
      /// }
      /// try validateAlignment([Bool](repeating: false, count: 16))
      /// ```
      public init(dimensions: Int) {
        self.dimensions = dimensions
      }
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = [Bool]
    ///   .PackedBitsRepresentation(queryOutput: [true, false, true, false, false, false, false, true])
    /// let vectorBytes = vector.vectorBytes
    /// // [0x85]: eight logical bits in one byte.
    /// ```
    public var vectorBytes: [UInt8] { encodePackedBitsVector(self.queryOutput) }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = [0x85]
    /// let decoded = try [Bool].PackedBitsRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [true, false, true, false, false, false, false, true]
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      self.init(queryOutput: decodePackedBitsVector(vectorBytes))
    }
  }
}

extension Array.PackedBitsRepresentation: ExpressibleByArrayLiteral {
  /// Creates a vector representation from an array literal.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Bool].PackedBitsRepresentation.self)
  ///   var embedding: [Bool]
  /// }
  ///
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, vector)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public init(arrayLiteral elements: Bool...) {
    self.init(queryOutput: elements)
  }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension BinaryEmbeddingVector {
  /// SQLiteVec binary BLOB storage without metadata. Dimensions must be divisible by eight.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<8>
  /// }
  ///
  /// let components: BinaryEmbeddingVector<8> = BinaryEmbeddingVector<8>([true, false, true, false, false, false, false, true])
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, components)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
  /// ```
  public struct PackedBitsRepresentation:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias Scalar = Bool
    public typealias Dimensions = VectorDimensions<count>
    public typealias Encoding = [Bool].PackedBitsRepresentation
    public typealias VectorBytesRepresentation = Self
    /// The logical vector value bound to or decoded from a query.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = [0x85]
    /// let decoded = try BinaryEmbeddingVector<8>.PackedBitsRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [true, false, true, false, false, false, false, true]
    /// ```
    public var queryOutput: BinaryEmbeddingVector<count>

    /// Wraps logical components, preconditioning that dimensions are divisible by eight.
    /// Use `init(validating:)` for a recoverable validation error.
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///   var id: Int
    ///   @Column(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
    ///   var embedding: BinaryEmbeddingVector<8>
    /// }
    ///
    /// let vector = BinaryEmbeddingVector<8>
    ///   .PackedBitsRepresentation(
    ///     queryOutput: BinaryEmbeddingVector<8>([true, false, true, false, false, false, false, true])
    ///   )
    /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
    ///   (1, vector)
    /// }
    /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, ?)
    /// ```
    public init(queryOutput: BinaryEmbeddingVector<count>) {
      precondition(
        BinaryEmbeddingVector<count>.count.isMultiple(of: 8),
        "Packed bit vectors require a multiple of 8 dimensions"
      )
      self.queryOutput = queryOutput
    }

    /// Validates that the fixed logical components occupy complete bytes.
    ///
    /// ```swift
    /// let vector = BinaryEmbeddingVector<16>(repeating: true)
    /// let binding = try BinaryEmbeddingVector<16>.PackedBitsRepresentation(validating: vector)
    /// let payload = binding.vectorBytes // [0xff, 0xff]
    /// ```
    public init(validating vector: BinaryEmbeddingVector<count>) throws {
      guard BinaryEmbeddingVector<count>.count.isMultiple(of: 8) else {
        throw [Bool].PackedBitsRepresentation
          .InvalidDimensionsError(dimensions: BinaryEmbeddingVector<count>.count)
      }
      self.init(queryOutput: vector)
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = BinaryEmbeddingVector<8>
    ///   .PackedBitsRepresentation(
    ///     queryOutput: BinaryEmbeddingVector<8>([true, false, true, false, false, false, false, true])
    ///   )
    /// let vectorBytes = vector.vectorBytes
    /// // [0x85]: eight logical bits in one byte.
    /// ```
    public var vectorBytes: [UInt8] { self.queryOutput.packedBytes }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let storedBytes: [UInt8] = [0x85]
    /// let decoded = try BinaryEmbeddingVector<8>.PackedBitsRepresentation(vectorBytes: storedBytes)
    /// let components = Array(decoded.queryOutput) // [true, false, true, false, false, false, false, true]
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      let (dimensions, overflow) = vectorBytes.count.multipliedReportingOverflow(by: 8)
      guard !overflow else { throw VectorDecodingError.invalidBytes }
      guard dimensions == BinaryEmbeddingVector<count>.count else {
        throw VectorDecodingError.dimensionMismatch(
          expected: BinaryEmbeddingVector<count>.count,
          actual: dimensions
        )
      }
      try self.init(queryOutput: BinaryEmbeddingVector<count>(packedBytes: vectorBytes))
    }
  }
}

/// Packed bits without format metadata, suitable for SQLiteVec binary vectors.
///
/// Bit zero is the least significant bit of the first byte. Binding requires a dimension count
/// divisible by eight; the format cannot preserve a partial byte's dimension count.
private func encodePackedBitsVector(_ elements: [Bool]) -> [UInt8] {
  stride(from: 0, to: elements.count, by: 8)
    .map { offset in
      (0..<8).reduce(UInt8.zero) { $0 | (elements[offset + $1] ? UInt8(1) << $1 : 0) }
    }
}

private func decodePackedBitsVector(_ bytes: [UInt8]) -> [Bool] {
  bytes.withUnsafeBufferPointer { buffer in
    (0..<buffer.count * 8).map { buffer[$0 / 8] & (UInt8(1) << ($0 % 8)) != 0 }
  }
}
