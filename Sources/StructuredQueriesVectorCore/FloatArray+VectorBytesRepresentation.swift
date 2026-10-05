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
    public typealias Encoding = [Element].VectorBytesRepresentation
    public typealias VectorBytesRepresentation = Self
    public var queryOutput: [Element]

    public init(queryOutput: [Element]) {
      self.queryOutput = queryOutput
    }

    public var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

    public init(vectorBytes: [UInt8]) throws {
      try self.init(queryOutput: [Element](vectorBytes: vectorBytes))
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
      public typealias Encoding = [Element].VectorBytesRepresentation
      public typealias VectorBytesRepresentation = Self
      public var queryOutput: InlineArray<count, Element>

      public init(queryOutput: InlineArray<count, Element>) {
        self.queryOutput = queryOutput
      }

      public var vectorBytes: [UInt8] { self.queryOutput.vectorBytes }

      public init(vectorBytes: [UInt8]) throws {
        try self.init(queryOutput: InlineArray<count, Element>(vectorBytes: vectorBytes))
      }

      public static func == (lhs: Self, rhs: Self) -> Bool {
        (0..<InlineArray<count, Element>.count)
          .allSatisfy { lhs.queryOutput[$0] == rhs.queryOutput[$0] }
      }

      public func hash(into hasher: inout Hasher) {
        hasher.combine(InlineArray<count, Element>.count)
        for index in 0..<InlineArray<count, Element>.count {
          hasher.combine(self.queryOutput[index])
        }
      }
    }
  }
#endif
