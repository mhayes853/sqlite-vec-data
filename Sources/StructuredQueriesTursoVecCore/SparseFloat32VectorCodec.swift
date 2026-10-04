import StructuredQueriesVectorCore

// Layout: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/vector_types.rs
// Serialization: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
enum SparseFloat32VectorCodec {
  static func encode(_ elements: [Float]) -> [UInt8] {
    precondition(UInt32(exactly: elements.count) != nil, "Sparse dimensions must fit in UInt32")
    let entries = elements.enumerated().filter { $0.element != 0 }
    return Float32VectorCodec.encode(entries.map(\.element))
      + entries.flatMap { sparseWordBytes(UInt32($0.offset)) }
      + sparseWordBytes(UInt32(elements.count)) + [9]
  }

  static func decode(_ bytes: [UInt8]) throws -> [Float] {
    guard bytes.count >= 5, (bytes.count - 5).isMultiple(of: 8), bytes.last == 9 else {
      throw VectorDecodingError.invalidBytes
    }
    let entries = (bytes.count - 5) / 8
    let dimensions = Int(decodeSparseWord(bytes[(bytes.count - 5)..<(bytes.count - 1)]))
    let indices = (0..<entries)
      .map { entry in
        let offset = (entries + entry) * 4
        return Int(decodeSparseWord(bytes[offset..<(offset + 4)]))
      }
    guard indices.allSatisfy({ $0 < dimensions }),
      zip(indices, indices.dropFirst()).allSatisfy({ $0 < $1 })
    else {
      throw VectorDecodingError.invalidBytes
    }
    let values = try Float32VectorCodec.decode(Array(bytes.prefix(entries * 4)))
    var elements = Array(repeating: Float.zero, count: dimensions)
    // swift-format-ignore: ReplaceForEachWithForLoop
    zip(indices, values).forEach { elements[$0] = $1 }
    return elements
  }
}

private func sparseWordBytes(_ bits: UInt32) -> [UInt8] {
  (0..<4).map { UInt8(truncatingIfNeeded: bits >> ($0 * 8)) }
}

private func decodeSparseWord(_ bytes: ArraySlice<UInt8>) -> UInt32 {
  bytes.enumerated().reduce(UInt32.zero) { $0 | (UInt32($1.element) << ($1.offset * 8)) }
}
