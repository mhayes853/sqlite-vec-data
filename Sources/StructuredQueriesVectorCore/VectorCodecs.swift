/// Little-endian IEEE float32 values, without metadata.
///
/// This is compatible with Turso BLOB columns and with SQLiteVec on little-endian platforms.
package enum Float32VectorCodec {
  package static func encode(_ elements: [Float]) -> [UInt8] {
    elements.flatMap { littleEndianBytes($0.bitPattern) }
  }

  package static func decode(_ bytes: [UInt8]) throws -> [Float] {
    // Turso also accepts an optional float32 type byte.
    let payload = bytes.count % 4 == 1 && bytes.last == 1 ? Array(bytes.dropLast()) : bytes
    return try decodeWords(payload, as: UInt32.self).map { Float(bitPattern: $0) }
  }
}

/// Little-endian IEEE float64 values followed by Turso's float64 type byte.
enum Float64VectorCodec {
  static func encode(_ elements: [Double]) -> [UInt8] {
    elements.flatMap { littleEndianBytes($0.bitPattern) } + [2]
  }

  static func decode(_ bytes: [UInt8]) throws -> [Double] {
    guard bytes.last == 2 else { throw VectorDecodingError.invalidBytes }
    return try decodeWords(Array(bytes.dropLast()), as: UInt64.self).map { Double(bitPattern: $0) }
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

func encodeVector<Scalar: VectorScalar>(_ elements: [Scalar]) -> [UInt8] {
  switch Scalar.Format.self {
  case is VectorFormat.Float32.Type:
    Float32VectorCodec.encode(elements as? [Float] ?? elements.map { Float($0) })
  case is VectorFormat.Float64.Type:
    Float64VectorCodec.encode(elements as? [Double] ?? elements.map { Double($0) })
  default:
    preconditionFailure("Unsupported default vector scalar format")
  }
}

func decodeVector<Scalar: VectorScalar>(_ bytes: [UInt8], as scalar: Scalar.Type) throws -> [Scalar]
{
  switch Scalar.Format.self {
  case is VectorFormat.Float32.Type:
    try convertVectorScalars(Float32VectorCodec.decode(bytes), to: scalar)
  case is VectorFormat.Float64.Type:
    try convertVectorScalars(Float64VectorCodec.decode(bytes), to: scalar)
  default:
    throw VectorDecodingError.invalidBytes
  }
}

private func convertVectorScalars<Source: BinaryFloatingPoint, Destination: VectorScalar>(
  _ elements: [Source],
  to scalar: Destination.Type
) -> [Destination] {
  // Preserve IEEE bit patterns when no precision conversion is needed.
  elements as? [Destination] ?? elements.map { Destination($0) }
}
