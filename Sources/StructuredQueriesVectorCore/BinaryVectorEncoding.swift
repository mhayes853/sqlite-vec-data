/// A binary vector byte layout, independent of a database's framing requirements.
///
/// Refine this protocol to promise a specific layout. Scalar identity alone does not make
/// two binary encodings interchangeable; query helpers also check encoding and dimensions.
///
/// ```swift
/// // Decode a cached payload using the binary format selected by the caller.
/// func decodeCachedBinary<E: BinaryVectorEncoding>(
///   _ payload: [UInt8], as encoding: E.Type
/// ) throws -> E {
///   try E(vectorBytes: payload)
/// }
/// ```
public protocol BinaryVectorEncoding: VectorBytesRepresentable where Scalar == Bool {}
