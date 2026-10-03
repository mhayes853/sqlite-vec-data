/// A floating-point scalar with a default vector byte layout.
///
/// Float, Double, and Float16 select the float32, float64, and float16 formats, respectively.
public protocol VectorScalar: BinaryFloatingPoint, Hashable, Codable, Sendable {
  associatedtype Format
}

extension Float: VectorScalar {
  public typealias Format = VectorFormat.Float32
}

extension Double: VectorScalar {
  public typealias Format = VectorFormat.Float64
}

extension Float16: VectorScalar {
  public typealias Format = VectorFormat.Float16
}
