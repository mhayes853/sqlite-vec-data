/// A floating-point scalar with a default vector byte layout.
///
/// Float uses raw little-endian float32 bytes. Double uses Turso's tagged float64 bytes.
/// Conforming scalar types provide their encoding and decoding behavior directly.
public protocol VectorScalar: BinaryFloatingPoint, Hashable, Codable, Sendable {
  /// Encodes a vector using this scalar's default byte layout.
  static func encodeVector(_ values: [Self]) -> [UInt8]

  /// Decodes a vector, validating byte lengths and any format metadata.
  static func decodeVector(_ bytes: [UInt8]) throws -> [Self]
}

extension Float: VectorScalar {
  public static func encodeVector(_ values: [Self]) -> [UInt8] {
    values.flatMap { littleEndianVectorBytes($0.bitPattern) }
  }

  public static func decodeVector(_ bytes: [UInt8]) throws -> [Self] {
    // Turso also accepts an optional float32 type byte.
    let payload = bytes.count % 4 == 1 && bytes.last == 1 ? Array(bytes.dropLast()) : bytes
    return try decodeVectorWords(payload, as: UInt32.self).map { Self(bitPattern: $0) }
  }
}

extension Double: VectorScalar {
  public static func encodeVector(_ values: [Self]) -> [UInt8] {
    values.flatMap { littleEndianVectorBytes($0.bitPattern) } + [2]
  }

  public static func decodeVector(_ bytes: [UInt8]) throws -> [Self] {
    guard bytes.last == 2 else { throw VectorDecodingError.invalidBytes }
    return try decodeVectorWords(Array(bytes.dropLast()), as: UInt64.self)
      .map { Self(bitPattern: $0) }
  }
}

private func littleEndianVectorBytes<T: FixedWidthInteger & UnsignedInteger>(_ bits: T) -> [UInt8] {
  (0..<MemoryLayout<T>.size).map { UInt8(truncatingIfNeeded: bits >> ($0 * 8)) }
}

private func decodeVectorWords<T: FixedWidthInteger & UnsignedInteger>(
  _ bytes: [UInt8],
  as type: T.Type
) throws -> [T] {
  let size = MemoryLayout<T>.size
  guard bytes.count.isMultiple(of: size) else { throw VectorDecodingError.invalidBytes }
  return stride(from: 0, to: bytes.count, by: size)
    .map { offset in
      (0..<size).reduce(T.zero) { $0 | (T(bytes[offset + $1]) << ($1 * 8)) }
    }
}
