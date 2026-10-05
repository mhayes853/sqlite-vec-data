package func littleEndianVectorBytes<T: FixedWidthInteger & UnsignedInteger>(_ bits: T) -> [UInt8] {
  (0..<MemoryLayout<T>.size).map { UInt8(truncatingIfNeeded: bits >> ($0 * 8)) }
}

package func decodeVectorWords<T: FixedWidthInteger & UnsignedInteger>(
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
