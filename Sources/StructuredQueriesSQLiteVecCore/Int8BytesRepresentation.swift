import StructuredQueriesCore

extension Array where Element == Int8 {
  /// Raw signed bytes for SQLiteVec Int8 columns, with one byte per component.
  ///
  /// Use `Vec.int8` when inserting or passing a bound blob to SQLiteVec functions so that the
  /// expression carries SQLiteVec's Int8 subtype. This format has no scale, shift, or type metadata
  /// and differs from Turso's `Quantized8Vector`.
  public struct Int8BytesRepresentation:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias Scalar = Int8
    public typealias Encoding = Self
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Int8]

    public init(queryOutput: [Int8]) {
      self.queryOutput = queryOutput
    }

    public var vectorBytes: [UInt8] { self.queryOutput.map(UInt8.init(bitPattern:)) }

    public init(vectorBytes: [UInt8]) throws {
      self.init(queryOutput: vectorBytes.map(Int8.init(bitPattern:)))
    }
  }
}

extension Array.Int8BytesRepresentation: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Int8...) {
    self.init(queryOutput: elements)
  }
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Int8 {
    /// Raw signed bytes for SQLiteVec Int8 columns, validating fixed dimensions when decoding.
    public struct Int8BytesRepresentation:
      Hashable, Sendable, QueryBindable, VectorBytesRepresentable
    {
      public typealias Scalar = Int8
      public typealias Encoding = [Int8].Int8BytesRepresentation
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: FixedEmbeddingVector<count, Int8>

      public init(queryOutput: FixedEmbeddingVector<count, Int8>) {
        self.queryOutput = queryOutput
      }

      public var vectorBytes: [UInt8] { self.queryOutput.map(UInt8.init(bitPattern:)) }

      public init(vectorBytes: [UInt8]) throws {
        try self.init(
          queryOutput: FixedEmbeddingVector<count, Int8>(
            validating: vectorBytes.map(Int8.init(bitPattern:))
          )
        )
      }
    }
  }
#endif
