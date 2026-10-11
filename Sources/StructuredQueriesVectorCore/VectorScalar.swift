/// A floating-point scalar with a default vector byte layout.
///
/// Float16 uses raw little-endian binary16 bytes. Float uses raw little-endian float32 bytes.
/// Double uses Turso's tagged float64 bytes. Float16 serialization does not imply database support.
/// Default codecs serialize integer bit patterns in little-endian order. Conforming scalar types
/// can override the codecs to validate or add format metadata.
///
/// ```swift
/// let bytes = Float.encodeVector([1, 2, 3])
/// let values = try Float.decodeVector(bytes)
/// // [1, 2, 3]
/// ```
public protocol VectorScalar: BinaryFloatingPoint, Codable, Sendable {
  /// The unsigned integer containing this scalar's complete bit pattern.
  associatedtype BitPattern: FixedWidthInteger & UnsignedInteger

  /// This scalar's complete bit pattern, including its sign and any NaN payload.
  ///
  /// ```swift
  /// let bits = Float(1).bitPattern  // 0x3f800000.
  /// ```
  var bitPattern: BitPattern { get }

  /// Creates a scalar without changing its bit pattern.
  ///
  /// ```swift
  /// let scalar = Float(bitPattern: 0x3f80_0000)  // 1.
  /// ```
  init(bitPattern: BitPattern)

  /// Encodes a vector using this scalar's default byte layout.
  ///
  /// ```swift
  /// let bytes = Float.encodeVector([1, 2, 3])
  /// ```
  static func encodeVector(_ values: [Self]) -> [UInt8]

  /// Decodes a vector, validating byte lengths and any format metadata.
  ///
  /// ```swift
  /// let values = try Float.decodeVector(Float.encodeVector([1, 2, 3]))
  /// ```
  static func decodeVector(_ bytes: [UInt8]) throws -> [Self]
}

extension VectorScalar {
  /// Encodes components in the scalar's default vector byte layout.
  ///
  /// ```swift
  /// let bytes = Float16.encodeVector([1, 2, 3])
  /// ```
  public static func encodeVector(_ values: [Self]) -> [UInt8] {
    encodeVectorPayload(values)
  }

  /// Decodes components, validating byte length and encoding metadata.
  ///
  /// ```swift
  /// let bytes = Float16.encodeVector([1, 2, 3])
  /// let values = try Float16.decodeVector(bytes)
  /// ```
  public static func decodeVector(_ bytes: [UInt8]) throws -> [Self] {
    try decodeVectorPayload(bytes, as: Self.self)
  }
}

extension Float16: VectorScalar {}

extension Float: VectorScalar {
  /// Decodes components, validating byte length and encoding metadata.
  ///
  /// ```swift
  /// let bytes = Float.encodeVector([1, 2, 3])
  /// let values = try Float.decodeVector(bytes)
  /// ```
  public static func decodeVector(_ bytes: [UInt8]) throws -> [Self] {
    // Turso also accepts an optional float32 type byte.
    let payload = bytes.count % 4 == 1 && bytes.last == 1 ? Array(bytes.dropLast()) : bytes
    return try decodeVectorPayload(payload, as: Self.self)
  }
}

extension Double: VectorScalar {
  /// Encodes components in the scalar's default vector byte layout.
  ///
  /// ```swift
  /// let bytes = Double.encodeVector([1, 2, 3])
  /// ```
  public static func encodeVector(_ values: [Self]) -> [UInt8] {
    encodeVectorPayload(values) + [2]
  }

  /// Decodes components, validating byte length and encoding metadata.
  ///
  /// ```swift
  /// let bytes = Double.encodeVector([1, 2, 3])
  /// let values = try Double.decodeVector(bytes)
  /// ```
  public static func decodeVector(_ bytes: [UInt8]) throws -> [Self] {
    guard bytes.last == 2 else { throw VectorDecodingError.invalidBytes }
    return try decodeVectorPayload(Array(bytes.dropLast()), as: Self.self)
  }
}

private func encodeVectorPayload<Scalar: VectorScalar>(_ values: [Scalar]) -> [UInt8] {
  let size = (Scalar.BitPattern.bitWidth + 7) / 8
  return values.flatMap { value in
    (0..<size)
      .map { UInt8(truncatingIfNeeded: value.bitPattern >> ($0 * 8)) }
  }
}

private func decodeVectorPayload<Scalar: VectorScalar>(
  _ bytes: [UInt8],
  as type: Scalar.Type
) throws -> [Scalar] {
  let size = (Scalar.BitPattern.bitWidth + 7) / 8
  guard bytes.count.isMultiple(of: size) else { throw VectorDecodingError.invalidBytes }
  return stride(from: 0, to: bytes.count, by: size)
    .map { offset in
      let bits = (0..<size)
        .reduce(Scalar.BitPattern.zero) {
          $0 | (Scalar.BitPattern(bytes[offset + $1]) << ($1 * 8))
        }
      return Scalar(bitPattern: bits)
    }
}
