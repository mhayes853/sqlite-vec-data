import StructuredQueriesCore
import StructuredQueriesVectorCore

extension Array where Element == Bool {
  /// Turso binary storage, preserving exact dimensions through format metadata.
  public struct TursoBytesRepresentation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Bool
    public typealias Format = VectorFormat.TursoBits
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Bool]

    public init(queryOutput: [Bool]) {
      self.queryOutput = queryOutput
    }

    public var queryBinding: QueryBinding {
      .blob(encodeTursoBitsVector(self.queryOutput))
    }

    public init(decoder: inout some QueryDecoder) throws {
      try self.init(queryOutput: decodeTursoBitsVector([UInt8](decoder: &decoder)))
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
  extension FixedEmbeddingVector where Scalar == Bool {
    /// Turso binary storage, preserving exact dimensions through format metadata.
    public struct TursoBytesRepresentation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Bool
      public typealias Format = VectorFormat.TursoBits
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Bool>

      public init(queryOutput: FixedEmbeddingVector<count, Bool>) {
        self.queryOutput = queryOutput
      }

      public var queryBinding: QueryBinding {
        [Bool].TursoBytesRepresentation(queryOutput: Array(self.queryOutput)).queryBinding
      }

      public init(decoder: inout some QueryDecoder) throws {
        let elements = try [Bool].TursoBytesRepresentation(decoder: &decoder).queryOutput
        try self.init(queryOutput: FixedEmbeddingVector<count, Bool>(vectorElements: elements))
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
  let padding = byteCount.isMultiple(of: 2) ? 1 : 0
  let trailingBits = (byteCount + padding + 1) * 8 - elements.count
  return payload + Array(repeating: 0, count: padding) + [UInt8(trailingBits), 3]
}

private func decodeTursoBitsVector(_ bytes: [UInt8]) throws -> [Bool] {
  guard bytes.count >= 3, bytes.count % 2 == 1, bytes.last == 3 else {
    throw VectorDecodingError.invalidBytes
  }
  let trailingBits = Int(bytes[bytes.count - 2])
  // The metadata byte contributes eight omitted bits; padding contributes at most eight more.
  guard (8...23).contains(trailingBits) else { throw VectorDecodingError.invalidBytes }
  let dimensions = (bytes.count - 1) * 8 - trailingBits
  guard dimensions >= 0 else { throw VectorDecodingError.invalidBytes }
  return (0..<dimensions).map { bytes[$0 / 8] & (UInt8(1) << ($0 % 8)) != 0 }
}
