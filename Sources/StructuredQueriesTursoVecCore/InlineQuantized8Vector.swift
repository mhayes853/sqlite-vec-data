import StructuredQueriesCore
import StructuredQueriesVectorCore

#if swift(>=6.2)
  /// A Turso quantized vector whose unsigned byte codes are stored inline.
  ///
  /// `count` fixes the number of codes. Scale and shift apply to every code, as in
  /// `Quantized8Vector`; this is affine quantization, not IEEE FP8 or signed int8.
  /// Equality and hashing compare codes and parameter bit patterns.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct InlineQuantized8Vector<let count: Int>:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias QueryOutput = Self
    public typealias Scalar = Float
    public typealias Encoding = Quantized8Vector
    public typealias VectorBytesRepresentation = Self

    public let codes: [count of UInt8]
    public let scale: Float
    public let shift: Float

    public var dimensions: Int { Self.count }

    public init(quantizing values: EmbeddingVector<count>) throws {
      try self.init(Quantized8Vector(quantizing: Array(values)))
    }

    public init(codes: [count of UInt8], scale: Float, shift: Float) throws {
      try self.init(
        Quantized8Vector(codes: (0..<Self.count).map { codes[$0] }, scale: scale, shift: shift)
      )
    }

    public func decodedValues() -> EmbeddingVector<count> {
      EmbeddingVector<count> { Float(self.codes[$0]) * self.scale + self.shift }
    }

    public var vectorBytes: [UInt8] {
      encodeQuantized8Vector(
        codes: (0..<Self.count).map { self.codes[$0] },
        scale: self.scale,
        shift: self.shift
      )
    }

    public init(vectorBytes: [UInt8]) throws {
      try self.init(Quantized8Vector(vectorBytes: vectorBytes))
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.scale.bitPattern == rhs.scale.bitPattern && lhs.shift.bitPattern == rhs.shift.bitPattern
        && (0..<Self.count).allSatisfy { lhs.codes[$0] == rhs.codes[$0] }
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(Self.count)
      for index in 0..<Self.count {
        hasher.combine(self.codes[index])
      }
      hasher.combine(self.scale.bitPattern)
      hasher.combine(self.shift.bitPattern)
    }

    private init(_ vector: Quantized8Vector) throws {
      guard vector.dimensions == Self.count else {
        throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: vector.dimensions)
      }
      self.codes = [count of UInt8] { vector.codes[$0] }
      self.scale = vector.scale
      self.shift = vector.shift
    }
  }
#endif
