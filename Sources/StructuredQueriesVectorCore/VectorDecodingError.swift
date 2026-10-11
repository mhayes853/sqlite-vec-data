/// An invalid vector blob or an unexpected number of dimensions.
///
/// ```swift
/// do {
///   _ = try EmbeddingVector<3>(validating: [1, 2])
/// } catch VectorDecodingError.dimensionMismatch(let expected, let actual) {
///   print("Expected \(expected) components, received \(actual).")
/// }
/// ```
public enum VectorDecodingError: Error, Hashable, Sendable {
  /// The blob does not match the expected encoding.
  ///
  /// ```swift
  /// do {
  ///   _ = try Float.decodeVector([0xff])
  /// } catch VectorDecodingError.invalidBytes {
  ///   print("The Float32 blob must contain complete components.")
  /// }
  /// ```
  case invalidBytes
  /// The decoded component count does not match the fixed dimension count.
  ///
  /// ```swift
  /// do {
  ///   _ = try EmbeddingVector<3>(validating: [1, 2])
  /// } catch VectorDecodingError.dimensionMismatch(let expected, let actual) {
  ///   print("Expected \(expected) components, received \(actual).")
  /// }
  /// ```
  case dimensionMismatch(expected: Int, actual: Int)
}
