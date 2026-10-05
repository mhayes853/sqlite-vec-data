import StructuredQueriesCore
import StructuredQueriesVectorCore

/// Turso's sparse float32 vector: nonzero values and indices, plus the full dimension count.
///
/// Use this format for mostly-zero embeddings, such as lexical or bag-of-words vectors.
/// Binding and decoding retain sparse components without allocating a dense array. Equality
/// and hashing compare dimensions, indices, and stored value bit patterns, including NaNs.
public struct SparseFloat32Vector: Hashable, Sendable, QueryBindable, VectorBytesRepresentable {
  public typealias QueryOutput = Self
  public typealias Scalar = Float
  public typealias Encoding = SparseFloat32Vector
  public typealias VectorBytesRepresentation = Self

  public let dimensions: Int
  public let indices: [UInt32]
  public let values: [Float]

  /// Compresses a dense vector, omitting both positive and negative zeros.
  public init(compressing values: [Float]) throws {
    guard UInt32(exactly: values.count) != nil else {
      throw TursoVectorError.invalidSparseComponents
    }
    let entries = values.enumerated().filter { $0.element != 0 }
    try self.init(
      dimensions: values.count,
      indices: entries.map { UInt32($0.offset) },
      values: entries.map(\.element)
    )
  }

  /// Creates a vector from sorted, unique, in-range indices and matching values.
  /// Explicit zeros and all float32 bit patterns are preserved.
  public init(dimensions: Int, indices: [UInt32], values: [Float]) throws {
    guard let dimensions32 = UInt32(exactly: dimensions), indices.count == values.count,
      indices.allSatisfy({ $0 < dimensions32 }),
      zip(indices, indices.dropFirst()).allSatisfy({ $0 < $1 })
    else { throw TursoVectorError.invalidSparseComponents }
    self.dimensions = dimensions
    self.indices = indices
    self.values = values
  }

  /// Allocates a dense array, filling omitted dimensions with positive zero.
  public func denseValues() -> [Float] {
    var values = Array(repeating: Float.zero, count: self.dimensions)
    for (index, value) in zip(self.indices, self.values) {
      values[Int(index)] = value
    }
    return values
  }

  // Layout: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/vector_types.rs
  // Serialization: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
  public var vectorBytes: [UInt8] {
    Float.encodeVector(self.values) + self.indices.flatMap { sparseWordBytes($0) }
      + sparseWordBytes(UInt32(self.dimensions)) + [9]
  }

  public init(vectorBytes bytes: [UInt8]) throws {
    guard bytes.count >= 5, (bytes.count - 5).isMultiple(of: 8), bytes.last == 9 else {
      throw VectorDecodingError.invalidBytes
    }
    let entries = (bytes.count - 5) / 8
    let words = try decodeSparseWords(
      Array(bytes[(entries * 4)..<bytes.count - 1])
    )
    let values = try Float.decodeVector(Array(bytes.prefix(entries * 4)))
    do {
      try self.init(
        dimensions: Int(words[entries]),
        indices: Array(words.prefix(entries)),
        values: values
      )
    } catch {
      throw VectorDecodingError.invalidBytes
    }
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.dimensions == rhs.dimensions && lhs.indices == rhs.indices
      && lhs.values.map(\.bitPattern) == rhs.values.map(\.bitPattern)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.dimensions)
    hasher.combine(self.indices)
    hasher.combine(self.values.map(\.bitPattern))
  }
}

private func sparseWordBytes(_ bits: UInt32) -> [UInt8] {
  (0..<4).map { UInt8(truncatingIfNeeded: bits >> ($0 * 8)) }
}

private func decodeSparseWords(_ bytes: [UInt8]) throws -> [UInt32] {
  guard bytes.count.isMultiple(of: 4) else { throw VectorDecodingError.invalidBytes }
  return stride(from: 0, to: bytes.count, by: 4)
    .map { offset in
      (0..<4).reduce(UInt32.zero) { $0 | (UInt32(bytes[offset + $1]) << ($1 * 8)) }
    }
}
