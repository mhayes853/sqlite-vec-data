import StructuredQueriesCore

#if canImport(Darwin)
  import Darwin
#elseif canImport(Android)
  import Android
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(WinSDK)
  import WinSDK
#elseif canImport(WASILibc)
  import WASILibc
#endif

#if swift(>=6.2)
  // MARK: - EmbeddingVector

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct EmbeddingVector<let count: Int>: Sendable {
    public var array: [count of Float]

    public init(_ array: [count of Float]) {
      self.array = array
    }

    public init<E: Error>(_ body: (Int) throws(E) -> Float) throws(E) {
      self.array = try [count of Float](body)
    }

    public init<E: Error>(first: Float, next: (Float) throws(E) -> Float) throws(E) {
      self.array = try [count of Float](first: first, next: next)
    }

    public init<E: Error>(
      initializingWith initializer: (inout OutputSpan<Float>) throws(E) -> Void
    ) throws(E) {
      self.array = try [count of Float](initializingWith: initializer)
    }

    public init(repeating value: Float) {
      self.array = [count of Float](repeating: value)
    }
  }

  // MARK: - Equatable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.array.span.withUnsafeBytes { lhsPtr in
        rhs.array.span.withUnsafeBytes { rhsPtr in
          let size = Self.count * MemoryLayout<Float>.stride
          return lhsPtr.baseAddress == rhsPtr.baseAddress
            || memcmp(lhsPtr.baseAddress, rhsPtr.baseAddress, size) == 0
        }
      }
    }
  }

  // MARK: - Hashable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: Hashable {
    public func hash(into hasher: inout Hasher) {
      hasher.combine(Self.count)
      for i in 0..<Self.count {
        hasher.combine(self.array[i])
      }
    }
  }

  // MARK: - Encodable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: Encodable {
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.unkeyedContainer()
      for element in self {
        try container.encode(element)
      }
    }
  }

  // MARK: - Decodable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: Decodable {
    public init(from decoder: any Decoder) throws {
      var container = try decoder.unkeyedContainer()
      guard let count = container.count else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected count")
        )
      }
      if Self.count > count {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription:
              "Decoded contains too few elements. (Expected \(Self.count), got \(count))"
          )
        )
      }
      if Self.count < count {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription:
              "Decoded contains too many elements. (Expected \(Self.count), got \(count))"
          )
        )
      }
      self.array = try [count of Float] { span in
        while !container.isAtEnd {
          span.append(try container.decode(Float.self))
        }
      }
    }
  }

  // MARK: - CustomStringConvertible

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: CustomStringConvertible {
    public var description: String {
      "EmbeddingVector<\(Self.count)>(\(Array(self)))"
    }
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: CustomDebugStringConvertible {
    public var debugDescription: String {
      self.description
    }
  }

  // MARK: - MutableCollection

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: MutableCollection {
    public typealias Element = Float
    public typealias Index = Int

    public subscript(position: Index) -> Element {
      _read {
        yield self.array[position]
      }
      _modify {
        yield &self.array[position]
      }
    }

    public var startIndex: Int {
      self.array.startIndex
    }

    public var endIndex: Int {
      self.array.endIndex
    }

    public func index(after i: Int) -> Int {
      self.array.index(after: i)
    }
  }

  // MARK: - RandomAccessCollection

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: RandomAccessCollection {
  }

  // MARK: - QueryBindable

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension EmbeddingVector: QueryBindable, QueryDecodable, QueryRepresentable {
    public var queryBinding: QueryBinding {
      [count of Float].VectorBytesRepresentation(queryOutput: self.array).queryBinding
    }

    public init(decoder: inout some QueryDecoder) throws {
      guard let bytes = try decoder.decode([count of Float].VectorBytesRepresentation.self) else {
        throw QueryDecodingError.missingRequiredColumn
      }
      self.init(bytes)
    }
  }
#endif
