/// An invalid vector blob or an unexpected number of dimensions.
///
/// Include an `@unknown default` when switching over this error to handle future cases.
///
/// ```swift
/// do {
///   _ = try EmbeddingVector<3>(validating: [1, 2])
/// } catch VectorDecodingError.dimensionMismatch(let expected, let actual) {
///   print("Expected \(expected) components, received \(actual).")
/// }
/// ```
@nonexhaustive
public enum VectorDecodingError: Error, Hashable, Sendable {
  /// The blob does not match the expected encoding.
  ///
  /// `reason` is a diagnostic explanation, such as a length or metadata mismatch, and may change as
  /// validation becomes more detailed. Match the case rather than the reason.
  ///
  /// ```swift
  /// do {
  ///   _ = try Float.decodeVector([0xff])
  /// } catch VectorDecodingError.invalidBytes(let reason) {
  ///   print(reason) // Expected a multiple of 4 bytes for Float components, found 1.
  /// }
  /// ```
  case invalidBytes(reason: String)
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
