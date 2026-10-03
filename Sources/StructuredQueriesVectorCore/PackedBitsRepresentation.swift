import StructuredQueriesCore

extension Array where Element == Bool {
  /// Packed bits without metadata. Binding requires dimensions divisible by eight.
  public struct PackedBitsRepresentation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Bool
    public typealias Format = VectorFormat.PackedBits
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Bool]

    public init(queryOutput: [Bool]) {
      self.queryOutput = queryOutput
    }

    public var queryBinding: QueryBinding {
      .blob(PackedBitsVectorCodec.encode(self.queryOutput))
    }

    public init(decoder: inout some QueryDecoder) throws {
      try self.init(queryOutput: PackedBitsVectorCodec.decode([UInt8](decoder: &decoder)))
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
      public typealias Format = VectorFormat.PackedBits
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Bool>

      public init(queryOutput: FixedEmbeddingVector<count, Bool>) {
        self.queryOutput = queryOutput
      }

      public var queryBinding: QueryBinding {
        [Bool].PackedBitsRepresentation(queryOutput: Array(self.queryOutput)).queryBinding
      }

      public init(decoder: inout some QueryDecoder) throws {
        let elements = try [Bool].PackedBitsRepresentation(decoder: &decoder).queryOutput
        try self.init(queryOutput: FixedEmbeddingVector<count, Bool>(vectorElements: elements))
      }
    }
  }

#endif
