// MARK: - Array

extension Array where Element: VectorScalar {
  /// The scalar's default vector blob representation.
  ///
  /// Float uses raw float32 bytes, shared with SQLiteVec on little-endian platforms. Double and
  /// Float16 use Turso's tagged float64 and float16 formats, respectively.
  public typealias VectorBytesRepresentation = VectorQueryRepresentation<
    Self, Element.BytesEncoding
  >
}

// MARK: - InlineArray

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray where Element: VectorScalar {
    public typealias VectorBytesRepresentation = VectorQueryRepresentation<
      Self, Element.BytesEncoding
    >
  }
#endif
