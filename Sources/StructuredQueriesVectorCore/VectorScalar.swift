/// A floating-point scalar with a default vector byte layout.
///
/// Float and Double select the float32 and float64 formats, respectively.
public protocol VectorScalar: BinaryFloatingPoint, Hashable, Codable, Sendable {
  associatedtype Format
}

extension Float: VectorScalar {
  public typealias Format = VectorFormat.Float32
}

extension Double: VectorScalar {
  public typealias Format = VectorFormat.Float64
}
