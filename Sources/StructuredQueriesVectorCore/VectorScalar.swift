/// A floating-point scalar whose complete bit pattern can be serialized.
///
/// Float16, Float, and Double use raw little-endian payloads. Serialization preserves IEEE
/// bit patterns and does not add metadata or imply support for database vector operations.
/// `Float16` is IEEE binary16, not BF16. Framework tensor dtypes are not scalar conformances.
///
/// ```swift
/// let values: [Float] = [1, -0.0]
/// let bytes = Float.encodeVector(values)
/// let restored = try Float.decodeVector(bytes)
/// let bits = restored.map(\.bitPattern) // [0x3f800000, 0x80000000], preserving signed zero.
/// ```
public protocol VectorScalar: BinaryFloatingPoint, Codable, Sendable {
  /// The unsigned integer containing this scalar's complete bit pattern.
  associatedtype BitPattern: FixedWidthInteger & UnsignedInteger

  /// This scalar's complete bit pattern, including its sign and any NaN payload.
  ///
  /// ```swift
  /// let scalar = Float(bitPattern: 0x7fc0_1234)
  /// let bits = scalar.bitPattern // 0x7fc01234: retains the NaN payload.
  /// ```
  var bitPattern: BitPattern { get }

  /// Creates a scalar without changing its bit pattern.
  ///
  /// ```swift
  /// let scalar = Float(bitPattern: 0x8000_0000)
  /// let isNegativeZero = scalar == 0 && scalar.sign == .minus // true
  /// ```
  init(bitPattern: BitPattern)
}

extension VectorScalar {
  /// Encodes complete scalar bit patterns in little-endian order.
  ///
  /// ```swift
  /// let bytes = Float16.encodeVector([1, -0.0])
  /// // [0x00, 0x3c, 0x00, 0x80]: two little-endian binary16 components.
  /// ```
  public static func encodeVector(_ values: [Self]) -> [UInt8] {
    let size = (Self.BitPattern.bitWidth + 7) / 8
    return values.flatMap { value in
      (0..<size)
        .map { UInt8(truncatingIfNeeded: value.bitPattern >> ($0 * 8)) }
    }
  }

  /// Decodes raw little-endian components, requiring a complete bit pattern for each value.
  ///
  /// ```swift
  /// let cachedBytes: [UInt8] = [0x00, 0x3c, 0x00, 0x80]
  /// let values = try Float16.decodeVector(cachedBytes)
  /// let bits = values.map(\.bitPattern) // [0x3c00, 0x8000]
  /// ```
  public static func decodeVector(_ bytes: [UInt8]) throws -> [Self] {
    let size = (Self.BitPattern.bitWidth + 7) / 8
    guard bytes.count.isMultiple(of: size) else { throw VectorDecodingError.invalidBytes }
    return stride(from: 0, to: bytes.count, by: size)
      .map { offset in
        let bits = (0..<size)
          .reduce(Self.BitPattern.zero) {
            $0 | (Self.BitPattern(bytes[offset + $1]) << ($1 * 8))
          }
        return Self(bitPattern: bits)
      }
  }
}

extension Float16: VectorScalar {}
extension Float: VectorScalar {}
extension Double: VectorScalar {}
