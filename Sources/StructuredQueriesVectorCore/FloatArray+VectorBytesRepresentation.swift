import StructuredQueriesCore

// MARK: - Array

extension Array where Element: VectorScalar {
  /// The scalar's default vector blob representation.
  ///
  /// Float uses raw float32 bytes, shared with SQLiteVec on little-endian platforms. Double and
  /// Float16 use Turso's tagged float64 and float16 formats, respectively.
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
