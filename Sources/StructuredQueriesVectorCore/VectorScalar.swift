/// A floating-point scalar whose complete bit pattern can be serialized.
///
/// Float16, Float, and Double use raw little-endian payloads. Serialization preserves IEEE
/// bit patterns and does not add metadata or imply support for database vector operations.
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
}

extension VectorScalar {
  /// Encodes complete scalar bit patterns in little-endian order.
  ///
  /// ```swift
  /// let bytes = Float16.encodeVector([1, 2, 3])
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
  /// let bytes = Float16.encodeVector([1, 2, 3])
  /// let values = try Float16.decodeVector(bytes)
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
