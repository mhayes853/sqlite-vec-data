import StructuredQueriesCore

// MARK: - Array

extension Array where Element: VectorScalar {
  /// The scalar's default vector blob representation.
  ///
  /// Float uses raw float32 bytes, shared with SQLiteVec on little-endian platforms.
  /// Double uses Turso's tagged float64 format.
  public struct VectorBytesRepresentation:
    Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
  {
    public typealias Scalar = Element
    public typealias Format = Element.Format
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Element]

    public init(queryOutput: [Element]) {
      self.queryOutput = queryOutput
    }

    public var queryBinding: QueryBinding {
      .blob(encodeVector(self.queryOutput))
    }

    public init(decoder: inout some QueryDecoder) throws {
      try self.init(queryOutput: decodeVector([UInt8](decoder: &decoder), as: Element.self))
    }
  }
}

extension Array.VectorBytesRepresentation: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Element...) {
    self.init(queryOutput: elements)
  }
}

// MARK: - InlineArray

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray where Element: VectorScalar {
    /// The scalar's default blob representation with fixed-dimension validation.
    public struct VectorBytesRepresentation:
      Hashable, Sendable, QueryBindable, QueryRepresentable, VectorBytesRepresentable
    {
      public typealias Scalar = Element
      public typealias Format = Element.Format
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: InlineArray<count, Element>

      public init(queryOutput: InlineArray<count, Element>) {
        self.queryOutput = queryOutput
      }

      public var queryBinding: QueryBinding {
        .blob(encodeVector((0..<InlineArray<count, Element>.count).map { self.queryOutput[$0] }))
      }

      public init(decoder: inout some QueryDecoder) throws {
        let elements = try decodeVector([UInt8](decoder: &decoder), as: Element.self)
        guard elements.count == InlineArray<count, Element>.count else {
          throw VectorDecodingError.dimensionMismatch(
            expected: InlineArray<count, Element>.count,
            actual: elements.count
          )
        }
        self.init(queryOutput: InlineArray<count, Element> { elements[$0] })
      }

      public static func == (lhs: Self, rhs: Self) -> Bool {
        (0..<InlineArray<count, Element>.count)
          .allSatisfy { lhs.queryOutput[$0] == rhs.queryOutput[$0] }
      }

      public func hash(into hasher: inout Hasher) {
        hasher.combine(InlineArray<count, Element>.count)
        // swift-format-ignore: ReplaceForEachWithForLoop
        (0..<InlineArray<count, Element>.count).forEach { hasher.combine(self.queryOutput[$0]) }
      }
    }
  }
#endif

/// Little-endian IEEE float32 values, without metadata.
package func encodeFloat32Vector(_ elements: [Float]) -> [UInt8] {
  elements.flatMap { littleEndianVectorBytes($0.bitPattern) }
}

package func decodeFloat32Vector(_ bytes: [UInt8]) throws -> [Float] {
  // Turso also accepts an optional float32 type byte.
  let payload = bytes.count % 4 == 1 && bytes.last == 1 ? Array(bytes.dropLast()) : bytes
  return try decodeVectorWords(payload, as: UInt32.self).map { Float(bitPattern: $0) }
}

/// Little-endian IEEE float64 values followed by Turso's float64 type byte.
private func encodeFloat64Vector(_ elements: [Double]) -> [UInt8] {
  elements.flatMap { littleEndianVectorBytes($0.bitPattern) } + [2]
}

private func decodeFloat64Vector(_ bytes: [UInt8]) throws -> [Double] {
  guard bytes.last == 2 else { throw VectorDecodingError.invalidBytes }
  return try decodeVectorWords(Array(bytes.dropLast()), as: UInt64.self)
    .map { Double(bitPattern: $0) }
}

func encodeVector<Scalar: VectorScalar>(_ elements: [Scalar]) -> [UInt8] {
  switch Scalar.Format.self {
  case is VectorFormat.Float32.Type:
    encodeFloat32Vector(elements as? [Float] ?? elements.map { Float($0) })
  case is VectorFormat.Float64.Type:
    encodeFloat64Vector(elements as? [Double] ?? elements.map { Double($0) })
  default:
    preconditionFailure("Unsupported default vector scalar format")
  }
}

func decodeVector<Scalar: VectorScalar>(_ bytes: [UInt8], as scalar: Scalar.Type) throws -> [Scalar]
{
  switch Scalar.Format.self {
  case is VectorFormat.Float32.Type:
    try convertVectorScalars(decodeFloat32Vector(bytes), to: scalar)
  case is VectorFormat.Float64.Type:
    try convertVectorScalars(decodeFloat64Vector(bytes), to: scalar)
  default:
    throw VectorDecodingError.invalidBytes
  }
}

private func convertVectorScalars<Source: BinaryFloatingPoint, Destination: VectorScalar>(
  _ elements: [Source],
  to scalar: Destination.Type
) -> [Destination] {
  // Preserve IEEE bit patterns when no precision conversion is needed.
  elements as? [Destination] ?? elements.map { Destination($0) }
}
