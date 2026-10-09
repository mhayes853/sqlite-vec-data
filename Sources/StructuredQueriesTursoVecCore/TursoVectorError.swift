/// Invalid components supplied when constructing a Turso vector.
///
/// Match ``code`` when handling an error. The diagnostic ``reason`` may change as validation
/// becomes more detailed. When switching over a code, include a default branch for future codes.
public struct TursoVectorError: Error, Hashable, Sendable, CustomStringConvertible {
  /// The category of validation failure.
  public let code: Code

  /// A diagnostic explanation of the validation failure.
  public let reason: String

  public init(code: Code, reason: String) {
    self.code = code
    self.reason = reason
  }

  public var description: String { self.reason }

  /// An extensible error code. Unknown raw values are preserved rather than rejected.
  public struct Code: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Quantization requires finite input values, a finite nonnegative scale, a finite shift,
    /// and finite reconstructed values.
    public static let invalidQuantization = Code(rawValue: "invalidQuantization")

    /// Sparse dimensions must fit in UInt32. Indices and values must have matching lengths,
    /// and indices must be strictly increasing and less than the dimension count.
    public static let invalidSparseComponents = Code(rawValue: "invalidSparseComponents")
  }
}
