import StructuredQueriesCore
import StructuredQueriesVectorCore

#if swift(>=6.2)
  /// A Turso sparse float32 vector with a fixed logical dimension count.
  ///
  /// Indices and values use arrays because the number of stored entries can vary. `count`
  /// constrains the full vector size, rather than the size of its sparse storage.
  /// Equality and hashing compare stored component bit patterns.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct SizedSparseFloat32Vector<let count: Int>:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias QueryOutput = Self
    public typealias Scalar = Float
    public typealias Encoding = SparseFloat32Vector
    public typealias VectorBytesRepresentation = Self

    private let vector: SparseFloat32Vector

    public var dimensions: Int { Self.count }
    public var indices: [UInt32] { self.vector.indices }
    public var values: [Float] { self.vector.values }

    public init(compressing values: EmbeddingVector<count>) throws {
      try self.init(SparseFloat32Vector(compressing: Array(values)))
    }

    public init(indices: [UInt32], values: [Float]) throws {
      try self.init(SparseFloat32Vector(dimensions: Self.count, indices: indices, values: values))
    }

    /// Allocates an inline dense vector, filling omitted dimensions with positive zero.
    public func denseValues() -> EmbeddingVector<count> {
      var values = EmbeddingVector<count>(repeating: 0)
      for (index, value) in zip(self.indices, self.values) {
        values[Int(index)] = value
      }
      return values
    }

    public var vectorBytes: [UInt8] { self.vector.vectorBytes }

    public init(vectorBytes: [UInt8]) throws {
      try self.init(SparseFloat32Vector(vectorBytes: vectorBytes))
    }

    private init(_ vector: SparseFloat32Vector) throws {
      guard vector.dimensions == Self.count else {
        throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: vector.dimensions)
      }
      self.vector = vector
    }
  }
#endif
