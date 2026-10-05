import StructuredQueriesCore

extension Array where Element == Bool {
  /// Packed bits without metadata. Binding requires dimensions divisible by eight.
  public struct PackedBitsRepresentation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Bool
    public typealias Encoding = [Bool].PackedBitsRepresentation
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Bool]

    public init(queryOutput: [Bool]) {
      self.queryOutput = queryOutput
    }

    public var vectorBytes: [UInt8] { encodePackedBitsVector(self.queryOutput) }

    public init(vectorBytes: [UInt8]) throws {
      self.init(queryOutput: decodePackedBitsVector(vectorBytes))
    }
  }
}

extension Array.PackedBitsRepresentation: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Bool...) {
    self.init(queryOutput: elements)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Bool {
    /// Packed bits without metadata. Binding requires dimensions divisible by eight.
    public struct PackedBitsRepresentation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Bool
      public typealias Encoding = [Bool].PackedBitsRepresentation
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Bool>

      public init(queryOutput: FixedEmbeddingVector<count, Bool>) {
        self.queryOutput = queryOutput
      }

      public var vectorBytes: [UInt8] {
        [Bool].PackedBitsRepresentation(queryOutput: Array(self.queryOutput)).vectorBytes
      }

      public init(vectorBytes: [UInt8]) throws {
        let elements = try [Bool].PackedBitsRepresentation(vectorBytes: vectorBytes).queryOutput
        try self.init(queryOutput: FixedEmbeddingVector<count, Bool>(validating: elements))
      }
    }
  }

#endif

/// Packed bits without format metadata, suitable for SQLiteVec binary vectors.
///
/// Bit zero is the least significant bit of the first byte. Binding requires a dimension count
/// divisible by eight; the format cannot preserve a partial byte's dimension count.
private func encodePackedBitsVector(_ elements: [Bool]) -> [UInt8] {
  precondition(
    elements.count.isMultiple(of: 8),
    "Packed bit vectors require a multiple of 8 dimensions"
  )
  return stride(from: 0, to: elements.count, by: 8)
    .map { offset in
      (0..<8).reduce(UInt8.zero) { $0 | (elements[offset + $1] ? UInt8(1) << $1 : 0) }
    }
}

private func decodePackedBitsVector(_ bytes: [UInt8]) -> [Bool] {
  bytes.flatMap { byte in (0..<8).map { byte & (UInt8(1) << $0) != 0 } }
}
