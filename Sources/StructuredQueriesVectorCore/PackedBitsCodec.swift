/// Packed bits without format metadata, suitable for SQLiteVec binary vectors.
///
/// Bit zero is the least significant bit of the first byte. Binding requires a dimension count
/// divisible by eight; the format cannot preserve a partial byte's dimension count.
enum PackedBitsVectorCodec {
  static func encode(_ elements: [Bool]) -> [UInt8] {
    precondition(
      elements.count.isMultiple(of: 8),
      "Packed bit vectors require a multiple of 8 dimensions"
    )
    return stride(from: 0, to: elements.count, by: 8)
      .map { offset in
        (0..<8).reduce(UInt8.zero) { $0 | (elements[offset + $1] ? UInt8(1) << $1 : 0) }
      }
  }

  static func decode(_ bytes: [UInt8]) -> [Bool] {
    bytes.flatMap { byte in (0..<8).map { byte & (UInt8(1) << $0) != 0 } }
  }
}
