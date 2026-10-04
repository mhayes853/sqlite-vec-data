/// Type identities for vector byte layouts, used to match query representations.
///
/// These markers carry no serialization behavior. Use the named representations on arrays and
/// fixed-size vectors to bind and decode values.
public enum VectorFormat {
  /// Raw little-endian float32 bytes, with an optional type byte when decoding.
  public enum Float32: Hashable, Sendable {}
  /// Little-endian float64 bytes with Turso's type metadata.
  public enum Float64: Hashable, Sendable {}
  /// Little-endian IEEE half-precision bytes with libSQL's type metadata.
  public enum Float16: Hashable, Sendable {}
  /// Truncated bfloat16 bytes with libSQL's type metadata.
  public enum BFloat16: Hashable, Sendable {}
  /// Turso's quantized unsigned-byte values with scale and shift metadata.
  public enum Float8: Hashable, Sendable {}
  /// Packed bits without metadata, suitable for SQLiteVec binary vectors.
  public enum PackedBits: Hashable, Sendable {}
  /// Packed bits with Turso's padding and dimension metadata.
  public enum TursoBits: Hashable, Sendable {}
  /// Turso sparse float32 values, indices, and dimension metadata.
  public enum SparseFloat32: Hashable, Sendable {}
}
