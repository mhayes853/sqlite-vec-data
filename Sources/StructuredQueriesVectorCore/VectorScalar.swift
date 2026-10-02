/// A floating-point scalar with a default vector byte encoding.
public protocol VectorScalar: BinaryFloatingPoint, Hashable, Codable, Sendable {
  associatedtype BytesEncoding: L2VectorEncoding where BytesEncoding.Element == Self
}

extension Float: VectorScalar {
  public typealias BytesEncoding = Float32VectorEncoding
}

extension Double: VectorScalar {
  public typealias BytesEncoding = Float64VectorEncoding
}

extension Float16: VectorScalar {
  public typealias BytesEncoding = Float16VectorEncoding
}

/// Little-endian IEEE float32 values, without metadata.
///
/// This is compatible with Turso `F32_BLOB` and with SQLiteVec on little-endian platforms.
public enum Float32VectorEncoding: L2VectorEncoding {
  public static func encode(_ elements: [Float]) -> [UInt8] {
    elements.flatMap { littleEndianBytes($0.bitPattern) }
  }

  public static func decode(_ bytes: [UInt8]) throws -> [Float] {
    // Turso also accepts an optional float32 type byte.
    let payload = bytes.count % 4 == 1 && bytes.last == 1 ? Array(bytes.dropLast()) : bytes
    return try decodeWords(payload, as: UInt32.self).map { Float(bitPattern: $0) }
  }
}

/// Little-endian IEEE float64 values followed by Turso's float64 type byte.
public enum Float64VectorEncoding: L2VectorEncoding {
  public static func encode(_ elements: [Double]) -> [UInt8] {
    elements.flatMap { littleEndianBytes($0.bitPattern) } + [2]
  }

  public static func decode(_ bytes: [UInt8]) throws -> [Double] {
    guard bytes.last == 2 else { throw VectorDecodingError.invalidBytes }
    return try decodeWords(Array(bytes.dropLast()), as: UInt64.self).map { Double(bitPattern: $0) }
  }
}

/// Little-endian IEEE float16 values followed by Turso's float16 type byte.
public enum Float16VectorEncoding: L2VectorEncoding {
  public static func encode(_ elements: [Float16]) -> [UInt8] {
    elements.flatMap { littleEndianBytes($0.bitPattern) } + [5]
  }

  public static func decode(_ bytes: [UInt8]) throws -> [Float16] {
    guard bytes.last == 5 else { throw VectorDecodingError.invalidBytes }
    return try decodeWords(Array(bytes.dropLast()), as: UInt16.self).map { Float16(bitPattern: $0) }
  }
}

private func littleEndianBytes<T: FixedWidthInteger & UnsignedInteger>(_ bits: T) -> [UInt8] {
  (0..<MemoryLayout<T>.size).map { UInt8(truncatingIfNeeded: bits >> ($0 * 8)) }
}

private func decodeWords<T: FixedWidthInteger & UnsignedInteger>(
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
