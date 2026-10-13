import StructuredQueriesVectorCore

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Float {
    /// Applies Turso's unsigned affine quantization while retaining inline code storage.
    ///
    /// ```swift
    /// let embedding = EmbeddingVector<3>([0, 127.5, 255])
    /// let quantized = try embedding.quantized8()
    /// let reconstructed = quantized.decodedValues() // [0, 128, 255]: quantization is lossy.
    /// ```
    public func quantized8() throws -> InlineQuantized8Vector<count> {
      try InlineQuantized8Vector<count>(quantizing: self)
    }

    /// Compresses exact zeros while retaining the logical dimension count.
    ///
    /// ```swift
    /// let embedding = EmbeddingVector<6>([0, 0, 1.5, 0, 0, 2.5])
    /// let sparse = try embedding.sparseFloat32()
    /// let entries = Array(zip(sparse.indices, sparse.values)) // [(2, 1.5), (5, 2.5)]
    /// ```
    public func sparseFloat32() throws -> SizedSparseFloat32Vector<count> {
      try SizedSparseFloat32Vector<count>(compressing: self)
    }
  }
#endif
