import StructuredQueriesCore
import StructuredQueriesVectorCore

extension Array where Element == Float {
  /// Turso's sparse float32 storage, exposed as a dense array of Float values in Swift.
  ///
  /// Binding stores only nonzero values and their indices. Decoding fills omitted dimensions with
  /// zero. Signed zeros become positive zero. This format is unsupported by libSQL and SQLiteVec.
  public struct SparseRepresentation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Float
    public typealias Format = VectorFormat.SparseFloat32
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Float]

    public init(queryOutput: [Float]) {
      self.queryOutput = queryOutput
    }

    public var queryBinding: QueryBinding {
      .blob(SparseFloat32VectorCodec.encode(self.queryOutput))
    }

    public init(decoder: inout some QueryDecoder) throws {
      try self.init(queryOutput: SparseFloat32VectorCodec.decode([UInt8](decoder: &decoder)))
    }
  }
}

extension Array.SparseRepresentation: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Float...) {
    self.init(queryOutput: elements)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Float {
    /// Turso's sparse float32 storage with fixed-dimension validation.
    ///
    /// Swift values remain dense. Binding omits zero values; decoding reconstructs positive zeros.
    public struct SparseRepresentation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Float
      public typealias Format = VectorFormat.SparseFloat32
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Float>

      public init(queryOutput: FixedEmbeddingVector<count, Float>) {
        self.queryOutput = queryOutput
      }

      public var queryBinding: QueryBinding {
        [Float].SparseRepresentation(queryOutput: Array(self.queryOutput)).queryBinding
      }

      public init(decoder: inout some QueryDecoder) throws {
        let elements = try [Float].SparseRepresentation(decoder: &decoder).queryOutput
        try self.init(queryOutput: FixedEmbeddingVector<count, Float>(vectorElements: elements))
      }
    }
  }
#endif
