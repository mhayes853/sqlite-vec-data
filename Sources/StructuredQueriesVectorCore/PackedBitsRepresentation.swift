/// Packed bits without format metadata, suitable for SQLiteVec binary vectors.
///
/// Bit zero is the least significant bit of the first byte. Binding requires a dimension count
/// divisible by eight; the format cannot preserve a partial byte's dimension count.
public enum PackedBitsVectorEncoding: VectorEncoding {
  public static func encode(_ elements: [Bool]) -> [UInt8] {
    precondition(
      elements.count.isMultiple(of: 8),
      "Packed bit vectors require a multiple of 8 dimensions"
    )
    return stride(from: 0, to: elements.count, by: 8)
      .map { offset in
        (0..<8).reduce(UInt8.zero) { $0 | (elements[offset + $1] ? UInt8(1) << $1 : 0) }
      }
  }

  public static func decode(_ bytes: [UInt8]) -> [Bool] {
    bytes.flatMap { byte in (0..<8).map { byte & (UInt8(1) << $0) != 0 } }
  }
}

extension Array where Element == Bool {
  public typealias PackedBitsRepresentation = VectorQueryRepresentation<
    Self, PackedBitsVectorEncoding
  >
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Bool {
    public typealias PackedBitsRepresentation = VectorQueryRepresentation<
      Self, PackedBitsVectorEncoding
    >
  }
#endif
