import StructuredQueriesVectorCore

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension FixedEmbeddingVector where Scalar == Float {
    /// Applies Turso's unsigned affine quantization while retaining inline code storage.
    public func quantized8() throws -> InlineQuantized8Vector<count> {
      try InlineQuantized8Vector<count>(quantizing: self)
    }

    /// Compresses exact zeros while retaining the logical dimension count.
    public func sparseFloat32() throws -> SizedSparseFloat32Vector<count> {
      try SizedSparseFloat32Vector<count>(compressing: self)
    }
  }
#endif
