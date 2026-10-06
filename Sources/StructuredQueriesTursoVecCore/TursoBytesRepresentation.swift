import StructuredQueriesCore
import StructuredQueriesVectorCore

extension Array where Element == Bool {
  /// Turso binary storage, preserving exact dimensions through format metadata.
  public struct TursoBytesRepresentation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Bool
    public typealias Encoding = [Bool].TursoBytesRepresentation
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Bool]

    public init(queryOutput: [Bool]) {
      self.queryOutput = queryOutput
    }

    public var vectorBytes: [UInt8] { encodeTursoBitsVector(self.queryOutput) }

    public init(vectorBytes: [UInt8]) throws {
      try self.init(queryOutput: decodeTursoBitsVector(vectorBytes))
    }
  }
}

extension Array.TursoBytesRepresentation: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Bool...) {
    self.init(queryOutput: elements)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension BinaryEmbeddingVector {
    /// Turso binary storage, preserving exact dimensions through format metadata.
    public struct TursoBytesRepresentation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Bool
      public typealias Encoding = [Bool].TursoBytesRepresentation
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: BinaryEmbeddingVector<count>

      public init(queryOutput: BinaryEmbeddingVector<count>) {
        self.queryOutput = queryOutput
      }

      public var vectorBytes: [UInt8] {
        encodeTursoBitsPayload(
          self.queryOutput.packedBytes,
          dimensions: self.queryOutput.dimensions
        )
      }

      public init(vectorBytes: [UInt8]) throws {
        let payload = try decodeTursoBitsPayload(vectorBytes)
        guard payload.dimensions == BinaryEmbeddingVector<count>.count else {
          throw VectorDecodingError.dimensionMismatch(
            expected: BinaryEmbeddingVector<count>.count,
            actual: payload.dimensions
          )
        }
        try self.init(queryOutput: BinaryEmbeddingVector<count>(packedBytes: payload.bytes))
      }
    }
  }

#endif

/// Turso's packed binary vector format, including padding and dimension metadata.
///
/// True corresponds to a positive component (represented by +1 when extracted), and false to
/// a nonpositive component (represented by -1). Unlike SQLiteVec's packed bits, this encoding
/// preserves dimension counts that are not multiples of eight.
private func encodeTursoBitsVector(_ elements: [Bool]) -> [UInt8] {
  let byteCount = (elements.count + 7) / 8
  let payload = (0..<byteCount)
    .map { byteIndex in
      (0..<8)
        .reduce(UInt8.zero) { bits, bit in
          let index = byteIndex * 8 + bit
          return bits | (index < elements.count && elements[index] ? UInt8(1) << bit : 0)
        }
    }
  return encodeTursoBitsPayload(payload, dimensions: elements.count)
}

private func encodeTursoBitsPayload(_ payload: [UInt8], dimensions: Int) -> [UInt8] {
  let padding = payload.count.isMultiple(of: 2) ? 1 : 0
  let trailingBits = (payload.count + padding + 1) * 8 - dimensions
  return payload + Array(repeating: 0, count: padding) + [UInt8(trailingBits), 3]
}

private func decodeTursoBitsVector(_ bytes: [UInt8]) throws -> [Bool] {
  let payload = try decodeTursoBitsPayload(bytes)
  return (0..<payload.dimensions).map { payload.bytes[$0 / 8] & (UInt8(1) << ($0 % 8)) != 0 }
}

private func decodeTursoBitsPayload(_ bytes: [UInt8]) throws -> (bytes: [UInt8], dimensions: Int) {
  guard bytes.count >= 3, bytes.count % 2 == 1, bytes.last == 3 else {
    throw VectorDecodingError.invalidBytes
  }
  let trailingBits = Int(bytes[bytes.count - 2])
  // The metadata byte contributes eight omitted bits; padding contributes at most eight more.
  guard (8...23).contains(trailingBits) else { throw VectorDecodingError.invalidBytes }
  let dimensions = (bytes.count - 1) * 8 - trailingBits
  guard dimensions >= 0 else { throw VectorDecodingError.invalidBytes }
  return (Array(bytes.prefix(dimensions / 8 + (dimensions % 8 == 0 ? 0 : 1))), dimensions)
}
