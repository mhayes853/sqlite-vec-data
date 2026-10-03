/// An invalid vector blob or an unexpected number of dimensions.
public enum VectorDecodingError: Error, Hashable, Sendable {
  case invalidBytes
  case dimensionMismatch(expected: Int, actual: Int)
}
