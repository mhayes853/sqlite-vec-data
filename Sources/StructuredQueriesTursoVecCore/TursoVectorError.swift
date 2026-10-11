/// Invalid components supplied when constructing a Turso vector.
///
/// Match ``code`` when handling an error. The diagnostic ``reason`` may change as validation
/// becomes more detailed. When switching over a code, include a default branch for future codes.
///
/// ```swift
/// do {
///   _ = try Quantized8Vector(quantizing: [.infinity])
/// } catch let error as TursoVectorError {
///   switch error.code {
///   case .invalidQuantization: print(error.reason)
///   default: throw error
///   }
/// }
/// ```
public struct TursoVectorError: Error, Hashable, Sendable, CustomStringConvertible {
  /// The category of validation failure.
  ///
  /// ```swift
  /// do {
  ///   _ = try Quantized8Vector(quantizing: [.infinity])
  /// } catch let error as TursoVectorError {
  ///   switch error.code {
  ///   case .invalidQuantization: print(error.reason)
  ///   default: throw error
  ///   }
  /// }
  /// ```
  public let code: Code

  /// A diagnostic explanation of the validation failure.
  ///
  /// ```swift
  /// let error = TursoVectorError(code: .invalidQuantization, reason: "Scale must be nonnegative.")
  /// print(error.reason)
  /// ```
  public let reason: String

  /// Creates a validation error with a stable code and diagnostic reason.
  ///
  /// ```swift
  /// let error = TursoVectorError(code: .invalidQuantization, reason: "Scale must be nonnegative.")
  /// ```
  public init(code: Code, reason: String) {
    self.code = code
    self.reason = reason
  }

  /// The diagnostic explanation of the validation failure.
  ///
  /// ```swift
  /// let error = TursoVectorError(code: .invalidQuantization, reason: "Scale must be nonnegative.")
  /// print(error.description)
  /// ```
  public var description: String { self.reason }

  /// An extensible error code. Unknown raw values are preserved rather than rejected.
  ///
  /// ```swift
  /// let code = TursoVectorError.Code(rawValue: "invalidQuantization")
  /// print(code.rawValue)
  /// ```
  public struct Code: RawRepresentable, Hashable, Sendable {
    /// The stable string identifying this error category.
    ///
    /// ```swift
    /// let code = TursoVectorError.Code(rawValue: "invalidQuantization")
    /// print(code.rawValue)
    /// ```
    public let rawValue: String

    /// Creates a code, preserving unknown raw values.
    ///
    /// ```swift
    /// let code = TursoVectorError.Code(rawValue: "invalidQuantization")
    /// print(code.rawValue)
    /// ```
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Quantization requires finite input values, a finite nonnegative scale, a finite shift,
    /// and finite reconstructed values.
    ///
    /// ```swift
    /// do {
    ///   _ = try Quantized8Vector(codes: [0], scale: -1, shift: 0)
    /// } catch let error as TursoVectorError {
    ///   if error.code == .invalidQuantization { print(error.reason) }
    /// }
    /// ```
    public static let invalidQuantization = Code(rawValue: "invalidQuantization")

    /// Sparse dimensions must fit in UInt32. Indices and values must have matching lengths,
    /// and indices must be strictly increasing and less than the dimension count.
    ///
    /// ```swift
    /// do {
    ///   _ = try SparseFloat32Vector(dimensions: 3, indices: [3], values: [1])
    /// } catch let error as TursoVectorError {
    ///   if error.code == .invalidSparseComponents { print(error.reason) }
    /// }
    /// ```
    public static let invalidSparseComponents = Code(rawValue: "invalidSparseComponents")
  }
}
