import StructuredQueriesCore
import StructuredQueriesVectorCore

#if swift(>=6.2)
  /// A Turso quantized vector whose unsigned byte codes are stored inline.
  ///
  /// `count` fixes the number of codes. Scale and shift apply to every code, as in
  /// `Quantized8Vector`; this is affine quantization, not IEEE FP8 or signed int8.
  /// Equality and hashing compare codes and parameter bit patterns.
  ///
  /// ```swift
  /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
  /// let dense = vector.decodedValues()
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct InlineQuantized8Vector<let count: Int>:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias QueryOutput = Self
    public typealias Scalar = Float
    public typealias Dimensions = VectorDimensions<count>
    public typealias Encoding = Quantized8Vector
    public typealias VectorBytesRepresentation = Self

    /// The unsigned byte codes used by affine quantization.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let codes = vector.codes
    /// ```
    public let codes: [count of UInt8]
    /// The multiplier applied to every code when reconstructing components.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let scale = vector.scale
    /// ```
    public let scale: Float
    /// The offset added after multiplying each code by `scale`.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let shift = vector.shift
    /// ```
    public let shift: Float

    /// The number of logical vector components.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let dimensions = vector.dimensions
    /// ```
    public var dimensions: Int { Self.count }

    /// Quantizes finite components using Turso's min/max affine quantization.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// ```
    public init(quantizing values: EmbeddingVector<count>) throws {
      try self.init(validating: Quantized8Vector(quantizing: Array(values)))
    }

    /// Preserves existing unsigned codes and validates their affine parameters.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(codes: [0, 128, 255], scale: 0.01, shift: -1)
    /// let dense = vector.decodedValues()  // Float(code) * scale + shift.
    /// ```
    public init(codes: [count of UInt8], scale: Float, shift: Float) throws {
      try self.init(
        validating: Quantized8Vector(
          codes: (0..<Self.count).map { codes[$0] },
          scale: scale,
          shift: shift
        )
      )
    }

    /// Decodes components, validating byte length and encoding metadata.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let values = vector.decodedValues()
    /// ```
    public func decodedValues() -> EmbeddingVector<count> {
      EmbeddingVector<count> { Float(self.codes[$0]) * self.scale + self.shift }
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let vectorBytes = vector.vectorBytes
    /// ```
    public var vectorBytes: [UInt8] {
      encodeQuantized8Vector(
        codes: (0..<Self.count).map { self.codes[$0] },
        scale: self.scale,
        shift: self.shift
      )
    }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let restored = try InlineQuantized8Vector<3>(vectorBytes: vector.vectorBytes)
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      try self.init(validating: Quantized8Vector(vectorBytes: vectorBytes))
    }

    /// Compares the vector components for equality.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let equal = vector == vector
    /// ```
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.scale.bitPattern == rhs.scale.bitPattern && lhs.shift.bitPattern == rhs.shift.bitPattern
        && (0..<Self.count).allSatisfy { lhs.codes[$0] == rhs.codes[$0] }
    }

    /// Hashes the vector components.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([1, 2, 3]))
    /// let vectors = Set([vector])
    /// ```
    public func hash(into hasher: inout Hasher) {
      hasher.combine(Self.count)
      for index in 0..<Self.count {
        hasher.combine(self.codes[index])
      }
      hasher.combine(self.scale.bitPattern)
      hasher.combine(self.shift.bitPattern)
    }

    /// Preserves the encoded components of an existing vector, validating its dimensions.
    /// Throws `VectorDecodingError.dimensionMismatch` when the dimension counts differ.
    ///
    /// ```swift
    /// let dynamic = try Quantized8Vector(quantizing: [1, 2, 3])
    /// let sized = try InlineQuantized8Vector<3>(validating: dynamic)
    /// // Encoded components are preserved without quantizing or compressing again.
    /// ```
    public init(validating vector: Quantized8Vector) throws {
      guard vector.dimensions == Self.count else {
        throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: vector.dimensions)
      }
      self.codes = [count of UInt8] { vector.codes[$0] }
      self.scale = vector.scale
      self.shift = vector.shift
    }
  }
#endif
