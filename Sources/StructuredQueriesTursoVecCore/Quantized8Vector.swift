import StructuredQueriesCore
import StructuredQueriesVectorCore

/// Turso's unsigned 8-bit affine quantization, preserving codes, scale, and shift.
///
/// This is neither IEEE FP8 nor SQLiteVec's signed int8 format. Each code reconstructs as
/// `Float(code) * scale + shift`. Quantization is lossy and happens only when explicitly requested.
/// Equality and hashing compare codes and the bit patterns of scale and shift.
///
/// ```swift
/// let vector = try Quantized8Vector(quantizing: [0, 127.5, 255])
/// let reconstructed = vector.decodedValues() // [0, 128, 255]: the middle component loses 0.5.
/// ```
public struct Quantized8Vector: Hashable, Sendable, QueryBindable, VectorBytesRepresentable {
  public typealias QueryOutput = Self
  public typealias Scalar = Float
  public typealias Dimensions = Void
  public typealias Encoding = Quantized8Vector
  public typealias VectorBytesRepresentation = Self

  /// The unsigned byte codes used by affine quantization.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(codes: [10, 20, 30], scale: 2, shift: 1)
  /// let reconstructed = vector.codes.map { Float($0) * vector.scale + vector.shift } // [21, 41, 61]
  /// ```
  public let codes: [UInt8]
  /// The multiplier applied to every code when reconstructing components.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(codes: [10, 20, 30], scale: 2, shift: 1)
  /// let reconstructed = vector.codes.map { Float($0) * vector.scale + vector.shift } // [21, 41, 61]
  /// ```
  public let scale: Float
  /// The offset added after multiplying each code by `scale`.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(codes: [10, 20, 30], scale: 2, shift: 1)
  /// let reconstructed = vector.codes.map { Float($0) * vector.scale + vector.shift } // [21, 41, 61]
  /// ```
  public let shift: Float

  /// The number of logical vector components.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(quantizing: [0, 127.5, 255])
  /// let dimensions = vector.dimensions // 3 logical components
  /// let payloadBytes = vector.vectorBytes.count // 15 bytes, including padding and quantization parameters.
  /// ```
  public var dimensions: Int { self.codes.count }

  /// Quantizes finite values using Turso's min/max scale, shift, and rounding rule.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(quantizing: [0, 127.5, 255])
  /// let reconstructed = vector.decodedValues() // [0, 128, 255]: quantization is lossy.
  /// ```
  public init(quantizing values: [Float]) throws {
    guard values.allSatisfy(\.isFinite) else {
      throw TursoVectorError(
        code: .invalidQuantization,
        reason: "Quantization input values must be finite."
      )
    }
    let shift = values.min() ?? 0
    let scale = ((values.max() ?? 0) - shift) / 255
    guard scale.isFinite else {
      throw TursoVectorError(
        code: .invalidQuantization,
        reason: "The input range must produce a finite quantization scale."
      )
    }
    let codes = values.map { value in
      scale == 0
        ? UInt8.zero
        : UInt8(Swift.max(0, Swift.min(255, ((value - shift) / scale + 0.5).rounded(.towardZero))))
    }
    try self.init(codes: codes, scale: scale, shift: shift)
  }

  /// Creates a vector from already quantized components without changing them.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(codes: [10, 20, 30], scale: 2, shift: 1)
  /// let reconstructed = vector.decodedValues() // [21, 41, 61]; the supplied codes are preserved.
  /// ```
  public init(codes: [UInt8], scale: Float, shift: Float) throws {
    guard scale.isFinite, scale >= 0, shift.isFinite,
      codes.allSatisfy({ (Float($0) * scale + shift).isFinite })
    else {
      throw TursoVectorError(
        code: .invalidQuantization,
        reason:
          "Scale must be finite and nonnegative; shift and reconstructed values must be finite."
      )
    }
    self.codes = codes
    self.scale = scale
    self.shift = shift
  }

  /// Reconstructs dense float32 values from the stored codes and parameters.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(codes: [10, 20, 30], scale: 2, shift: 1)
  /// let reconstructed = vector.decodedValues() // [21, 41, 61]; allocates a dense Float array.
  /// ```
  public func decodedValues() -> [Float] {
    self.codes.map { Float($0) * self.scale + self.shift }
  }

  /// The serialized blob, including any metadata required by this encoding.
  ///
  /// ```swift
  /// let vector = try Quantized8Vector(quantizing: [0, 127.5, 255])
  /// let payload = vector.vectorBytes
  /// let formatTag = payload.last // 4: Turso's affine UInt8 format, including scale and shift.
  /// ```
  public var vectorBytes: [UInt8] {
    encodeQuantized8Vector(codes: self.codes, scale: self.scale, shift: self.shift)
  }

  /// Compares the vector components for equality.
  ///
  /// ```swift
  /// let left = try Quantized8Vector(codes: [0, 0, 0], scale: 1, shift: -0.0)
  /// let right = try Quantized8Vector(codes: [0, 0, 0], scale: 1, shift: 0.0)
  /// let equal = left == right // false: encoded parameter bit patterns differ.
  /// ```
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.codes == rhs.codes && lhs.scale.bitPattern == rhs.scale.bitPattern
      && lhs.shift.bitPattern == rhs.shift.bitPattern
  }

  /// Hashes the vector components.
  ///
  /// ```swift
  /// let generated = try Quantized8Vector(quantizing: [0, 128, 255])
  /// let supplied = try Quantized8Vector(codes: [0, 128, 255], scale: 1, shift: 0)
  /// let uniqueCount = Set([generated, supplied]).count // 1: identical encoded components.
  /// ```
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.codes)
    hasher.combine(self.scale.bitPattern)
    hasher.combine(self.shift.bitPattern)
  }

  /// Decodes a quantized blob, validating its metadata and parameters.
  ///
  /// ```swift
  /// // Three codes padded to four bytes, Float32 scale and shift, then format metadata.
  /// let storedBytes: [UInt8] = [10, 20, 30, 0] + Float.encodeVector([2, 1]) + [0, 1, 4]
  /// let vector = try Quantized8Vector(vectorBytes: storedBytes)
  /// let reconstructed = vector.decodedValues() // [21, 41, 61]
  /// ```
  public init(vectorBytes bytes: [UInt8]) throws {
    guard bytes.count >= 11, bytes.count % 4 == 3, bytes.last == 4 else {
      throw VectorDecodingError.invalidBytes
    }
    let alignedCount = bytes.count - 11
    let padding = Int(bytes[bytes.count - 2])
    guard padding <= 3, padding <= alignedCount else { throw VectorDecodingError.invalidBytes }
    let parameters = try Float.decodeVector(Array(bytes[alignedCount..<(alignedCount + 8)]))
    do {
      try self.init(
        codes: Array(bytes.prefix(alignedCount - padding)),
        scale: parameters[0],
        shift: parameters[1]
      )
    } catch {
      throw VectorDecodingError.invalidBytes
    }
  }
}

// Layout: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
// Conversion: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/convert.rs
func encodeQuantized8Vector(codes: [UInt8], scale: Float, shift: Float) -> [UInt8] {
  let padding = (4 - codes.count % 4) % 4
  return codes + Array(repeating: 0, count: padding)
    + Float.encodeVector([scale, shift]) + [0, UInt8(padding), 4]
}
