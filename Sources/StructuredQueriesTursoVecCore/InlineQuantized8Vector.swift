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
  /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0, 127.5, 255]))
  /// let reconstructed = vector.decodedValues() // [0, 128, 255]: the middle component loses 0.5.
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
    /// let vector = try InlineQuantized8Vector<3>(codes: [10, 20, 30], scale: 2, shift: 1)
    /// let reconstructed = (0..<3).map { Float(vector.codes[$0]) * vector.scale + vector.shift } // [21, 41, 61]
    /// ```
    public let codes: [count of UInt8]
    /// The multiplier applied to every code when reconstructing components.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(codes: [10, 20, 30], scale: 2, shift: 1)
    /// let reconstructed = (0..<3).map { Float(vector.codes[$0]) * vector.scale + vector.shift } // [21, 41, 61]
    /// ```
    public let scale: Float
    /// The offset added after multiplying each code by `scale`.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(codes: [10, 20, 30], scale: 2, shift: 1)
    /// let reconstructed = (0..<3).map { Float(vector.codes[$0]) * vector.scale + vector.shift } // [21, 41, 61]
    /// ```
    public let shift: Float

    /// The number of logical vector components.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0, 127.5, 255]))
    /// let dimensions = vector.dimensions // 3 logical components
    /// let payloadBytes = vector.vectorBytes.count // 15 bytes, including padding and quantization parameters.
    /// ```
    public var dimensions: Int { Self.count }

    /// Quantizes finite components using Turso's min/max affine quantization.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0, 127.5, 255]))
    /// let reconstructed = vector.decodedValues() // [0, 128, 255]: quantization is lossy.
    /// ```
    public init(quantizing values: EmbeddingVector<count>) throws {
      try self.init(validating: Quantized8Vector(quantizing: Array(values)))
    }

    /// Preserves existing unsigned codes and validates their affine parameters.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(codes: [10, 20, 30], scale: 2, shift: 1)
    /// let reconstructed = vector.decodedValues() // [21, 41, 61]; the supplied codes are preserved.
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
    /// let vector = try InlineQuantized8Vector<3>(codes: [10, 20, 30], scale: 2, shift: 1)
    /// let reconstructed = vector.decodedValues() // [21, 41, 61]; returns an inline Float32 vector.
    /// ```
    public func decodedValues() -> EmbeddingVector<count> {
      EmbeddingVector<count> { Float(self.codes[$0]) * self.scale + self.shift }
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0, 127.5, 255]))
    /// let payload = vector.vectorBytes
    /// let formatTag = payload.last // 4: Turso's affine UInt8 format, including scale and shift.
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
    /// // Three codes padded to four bytes, Float32 scale and shift, then format metadata.
    /// let storedBytes: [UInt8] = [10, 20, 30, 0] + Float.encodeVector([2, 1]) + [0, 1, 4]
    /// let vector = try InlineQuantized8Vector<3>(vectorBytes: storedBytes)
    /// let reconstructed = vector.decodedValues() // [21, 41, 61]
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      try self.init(validating: Quantized8Vector(vectorBytes: vectorBytes))
    }

    /// Compares the vector components for equality.
    ///
    /// ```swift
    /// let left = try InlineQuantized8Vector<3>(codes: [0, 0, 0], scale: 1, shift: -0.0)
    /// let right = try InlineQuantized8Vector<3>(codes: [0, 0, 0], scale: 1, shift: 0.0)
    /// let equal = left == right // false: encoded parameter bit patterns differ.
    /// ```
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.scale.bitPattern == rhs.scale.bitPattern && lhs.shift.bitPattern == rhs.shift.bitPattern
        && (0..<Self.count).allSatisfy { lhs.codes[$0] == rhs.codes[$0] }
    }

    /// Hashes the vector components.
    ///
    /// ```swift
    /// let generated = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0, 128, 255]))
    /// let supplied = try InlineQuantized8Vector<3>(codes: [0, 128, 255], scale: 1, shift: 0)
    /// let uniqueCount = Set([generated, supplied]).count // 1: identical encoded components.
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
    /// let supplied = try Quantized8Vector(codes: [10, 20, 30], scale: 2, shift: 1)
    /// let inline = try InlineQuantized8Vector<3>(validating: supplied)
    /// let reconstructed = inline.decodedValues() // [21, 41, 61]; no requantization.
    /// // A different code count throws VectorDecodingError.dimensionMismatch.
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
