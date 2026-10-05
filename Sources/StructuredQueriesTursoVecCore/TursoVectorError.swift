/// Invalid components supplied when constructing a Turso vector.
public enum TursoVectorError: Error, Hashable, Sendable {
  /// Quantization requires finite input values, a finite nonnegative scale, a finite shift,
  /// and finite reconstructed values.
  case invalidQuantization

  /// Sparse dimensions must fit in UInt32. Indices and values must have matching lengths,
  /// and indices must be strictly increasing and less than the dimension count.
  case invalidSparseComponents
}
