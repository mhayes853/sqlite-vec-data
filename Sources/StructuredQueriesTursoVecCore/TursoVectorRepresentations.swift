import StructuredQueriesCore
import StructuredQueriesVectorCore

extension Array where Element == Float {
  /// libSQL bfloat16 storage, truncating Float values to the upper 16 bits when binding.
  /// Decoding reconstructs the stored values; this representation is lossy.
  /// The Rust-based Turso engine does not support bfloat16 blobs.
  public struct BFloat16Representation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Float
    public typealias Format = VectorFormat.BFloat16
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Float]

    public init(queryOutput: [Float]) {
      self.queryOutput = queryOutput
    }

    public var queryBinding: QueryBinding {
      .blob(BFloat16VectorCodec.encode(self.queryOutput))
    }

    public init(decoder: inout some QueryDecoder) throws {
      try self.init(queryOutput: BFloat16VectorCodec.decode([UInt8](decoder: &decoder)))
    }
  }
}

extension Array.BFloat16Representation: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Float...) {
    self.init(queryOutput: elements)
  }
}

extension Array where Element == Float {
  /// Turso quantized float8 storage. Binding requires finite values and a finite scale.
  /// This lossy format stores unsigned bytes with per-vector scale and shift metadata.
  public struct Float8Representation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Float
    public typealias Format = VectorFormat.Float8
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Float]

    public init(queryOutput: [Float]) {
      self.queryOutput = queryOutput
    }

    public var queryBinding: QueryBinding {
      .blob(Float8VectorCodec.encode(self.queryOutput))
    }

    public init(decoder: inout some QueryDecoder) throws {
      try self.init(queryOutput: Float8VectorCodec.decode([UInt8](decoder: &decoder)))
    }
  }
}

extension Array.Float8Representation: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Float...) {
    self.init(queryOutput: elements)
  }
}

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
      .blob(TursoBitsVectorCodec.encode(self.queryOutput))
    }

    public init(decoder: inout some QueryDecoder) throws {
      try self.init(queryOutput: TursoBitsVectorCodec.decode([UInt8](decoder: &decoder)))
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
  extension FixedEmbeddingVector where Scalar == Float {
    /// libSQL bfloat16 storage, truncating Float values to the upper 16 bits when binding.
    /// Decoding reconstructs the stored values; this representation is lossy.
    /// The Rust-based Turso engine does not support bfloat16 blobs.
    public struct BFloat16Representation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Float
      public typealias Format = VectorFormat.BFloat16
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Float>

      public init(queryOutput: FixedEmbeddingVector<count, Float>) {
        self.queryOutput = queryOutput
      }

      public var queryBinding: QueryBinding {
        [Float].BFloat16Representation(queryOutput: Array(self.queryOutput)).queryBinding
      }

      public init(decoder: inout some QueryDecoder) throws {
        let elements = try [Float].BFloat16Representation(decoder: &decoder).queryOutput
        try self.init(queryOutput: FixedEmbeddingVector<count, Float>(vectorElements: elements))
      }
    }
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Float {
    /// Turso quantized float8 storage. Binding requires finite values and a finite scale.
    /// This lossy format stores unsigned bytes with per-vector scale and shift metadata.
    public struct Float8Representation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Float
      public typealias Format = VectorFormat.Float8
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Float>

      public init(queryOutput: FixedEmbeddingVector<count, Float>) {
        self.queryOutput = queryOutput
      }

      public var queryBinding: QueryBinding {
        [Float].Float8Representation(queryOutput: Array(self.queryOutput)).queryBinding
      }

      public init(decoder: inout some QueryDecoder) throws {
        let elements = try [Float].Float8Representation(decoder: &decoder).queryOutput
        try self.init(queryOutput: FixedEmbeddingVector<count, Float>(vectorElements: elements))
      }
    }
  }

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
