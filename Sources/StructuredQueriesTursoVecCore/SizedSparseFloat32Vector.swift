import StructuredQueriesCore
import StructuredQueriesVectorCore

#if swift(>=6.2)
  /// A Turso sparse float32 vector with a fixed logical dimension count.
  ///
  /// Indices and values use arrays because the number of stored entries can vary. `count`
  /// constrains the full vector size, rather than the size of its sparse storage.
  /// Equality and hashing compare stored component bit patterns.
  ///
  /// ```swift
  /// let vector = try SizedSparseFloat32Vector<6>(compressing: EmbeddingVector<6>([0, 0, 1.5, 0, 0, 2.5]))
  /// let dense = vector.denseValues() // [0, 0, 1.5, 0, 0, 2.5]; omitted components become zero.
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct SizedSparseFloat32Vector<let count: Int>:
    Hashable, Sendable, QueryBindable, VectorBytesRepresentable
  {
    public typealias QueryOutput = Self
    public typealias Scalar = Float
    public typealias Dimensions = VectorDimensions<count>
    public typealias Encoding = SparseFloat32Vector
    public typealias VectorBytesRepresentation = Self

    private let vector: SparseFloat32Vector

    /// The number of logical vector components.
    ///
    /// ```swift
    /// let vector = try SizedSparseFloat32Vector<6>(indices: [2, 5], values: [1.5, 2.5])
    /// let logicalCount = vector.dimensions // 6
    /// let storedCount = vector.values.count // 2: the other four components are omitted.
    /// ```
    public var dimensions: Int { Self.count }
    /// The ascending, zero-based positions of the stored sparse components.
    ///
    /// ```swift
    /// let vector = try SizedSparseFloat32Vector<6>(indices: [2, 5], values: [1.5, 2.5])
    /// let nonzeroEntries = Array(zip(vector.indices, vector.values)) // [(2, 1.5), (5, 2.5)]
    /// ```
    public var indices: [UInt32] { self.vector.indices }
    /// The stored sparse values, in the same order as `indices`.
    ///
    /// ```swift
    /// let vector = try SizedSparseFloat32Vector<6>(indices: [2, 5], values: [1.5, 2.5])
    /// let nonzeroEntries = Array(zip(vector.indices, vector.values)) // [(2, 1.5), (5, 2.5)]
    /// ```
    public var values: [Float] { self.vector.values }

    /// Drops zero components while preserving the logical dimension count.
    ///
    /// ```swift
    /// let vector = try SizedSparseFloat32Vector<6>(compressing: EmbeddingVector<6>([0, 0, 1.5, 0, 0, 2.5]))
    /// let dense = vector.denseValues() // [0, 0, 1.5, 0, 0, 2.5]; omitted components become zero.
    /// ```
    public init(compressing values: EmbeddingVector<count>) throws {
      try self.init(validating: SparseFloat32Vector(compressing: Array(values)))
    }

    /// Creates a sparse vector from ascending indices and matching values.
    ///
    /// ```swift
    /// let vector = try SizedSparseFloat32Vector<6>(indices: [2, 5], values: [1.5, 2.5])
    /// let dense = vector.denseValues() // [0, 0, 1.5, 0, 0, 2.5]; omitted components become zero.
    /// ```
    public init(indices: [UInt32], values: [Float]) throws {
      try self.init(
        validating: SparseFloat32Vector(dimensions: Self.count, indices: indices, values: values)
      )
    }

    /// Allocates an inline dense vector, filling omitted dimensions with positive zero.
    ///
    /// ```swift
    /// let vector = try SizedSparseFloat32Vector<6>(indices: [2, 5], values: [1.5, 2.5])
    /// let dense = vector.denseValues() // [0, 0, 1.5, 0, 0, 2.5]; omitted components become zero.
    /// ```
    public func denseValues() -> EmbeddingVector<count> {
      var values = EmbeddingVector<count>(repeating: 0)
      for (index, value) in zip(self.indices, self.values) {
        values[Int(index)] = value
      }
      return values
    }

    /// The serialized blob, including any metadata required by this encoding.
    ///
    /// ```swift
    /// let vector = try SizedSparseFloat32Vector<6>(indices: [2, 5], values: [1.5, 2.5])
    /// let byteCount = vector.vectorBytes.count // 21: two entries plus dimensions and the type byte.
    /// ```
    public var vectorBytes: [UInt8] { self.vector.vectorBytes }

    /// Decodes a vector blob, validating its encoding and dimensions.
    ///
    /// ```swift
    /// // Values, UInt32 indices, UInt32 logical dimensions, and sparse type byte.
    /// let storedBytes = Float.encodeVector([1.5, 2.5]) + [2, 0, 0, 0, 5, 0, 0, 0, 6, 0, 0, 0, 9]
    /// let vector = try SizedSparseFloat32Vector<6>(vectorBytes: storedBytes)
    /// let entries = Array(zip(vector.indices, vector.values)) // [(2, 1.5), (5, 2.5)]
    /// ```
    public init(vectorBytes: [UInt8]) throws {
      try self.init(validating: SparseFloat32Vector(vectorBytes: vectorBytes))
    }

    /// Preserves the encoded components of an existing vector, validating its dimensions.
    /// Throws `VectorDecodingError.dimensionMismatch` when the dimension counts differ.
    ///
    /// ```swift
    /// let supplied = try SparseFloat32Vector(dimensions: 6, indices: [2, 5], values: [1.5, 2.5])
    /// let sized = try SizedSparseFloat32Vector<6>(validating: supplied)
    /// let storedCount = sized.values.count // 2: conversion preserves the sparse entries.
    /// // A different logical dimension count throws VectorDecodingError.dimensionMismatch.
    /// ```
    public init(validating vector: SparseFloat32Vector) throws {
      guard vector.dimensions == Self.count else {
        throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: vector.dimensions)
      }
      self.vector = vector
    }
  }
#endif
