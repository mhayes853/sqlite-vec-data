#if swift(>=6.2)
  /// A fixed-dimension vector of logical bits backed by packed byte storage.
  ///
  /// The first element occupies the least significant bit of the first byte. Unused trailing
  /// bits are always zero. Database encodings are selected through explicit representations.
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public struct BinaryEmbeddingVector<let count: Int>:
    Hashable, Sendable, RandomAccessCollection, MutableCollection, Codable,
    CustomStringConvertible, CustomDebugStringConvertible
  {
    public typealias Element = Bool
    public typealias Index = Int

    @usableFromInline
    internal var storage: [UInt8]

    /// Raw packed bits, without database format metadata.
    public var packedBytes: [UInt8] { self.storage }
    public var dimensions: Int { Self.count }
    public var startIndex: Int { 0 }
    public var endIndex: Int { Self.count }

    /// The number of true components.
    public var nonzeroBitCount: Int {
      self.storage.reduce(0) { $0 + $1.nonzeroBitCount }
    }

    public init(_ values: [count of Bool]) {
      self.init { values[$0] }
    }

    public init(repeating value: Bool) {
      precondition(Self.count >= 0, "Binary vector dimensions must be nonnegative")
      self.storage = Array(repeating: value ? UInt8.max : 0, count: Self.byteCount)
      self.clearUnusedBits()
    }

    /// Creates a vector by generating its logical components.
    public init<E: Error>(_ body: (Int) throws(E) -> Bool) throws(E) {
      self.init(repeating: false)
      for index in 0..<Self.count {
        self[index] = try body(index)
      }
    }

    /// Creates a vector from a first bit and a generator that receives each preceding bit.
    ///
    /// For example, `BinaryEmbeddingVector<4>(first: true) { !$0 }` creates alternating bits.
    /// The generator runs `count - 1` times for a nonempty vector. For zero dimensions, this
    /// creates an empty vector, ignores `first`, and never calls `next`, matching `InlineArray`.
    /// Any error thrown by `next` is propagated immediately.
    public init<E: Error>(first: Bool, next: (Bool) throws(E) -> Bool) throws(E) {
      self.init(repeating: false)
      if Self.count > 0 {
        self[0] = first
        for index in 1..<Self.count {
          self[index] = try next(self[index - 1])
        }
      }
    }

    public init<E: Error>(
      initializingWith initializer: (inout OutputSpan<Bool>) throws(E) -> Void
    ) throws(E) {
      try self.init([count of Bool](initializingWith: initializer))
    }

    /// Validates the logical element count before packing an array.
    public init(validating values: [Bool]) throws {
      guard values.count == Self.count else {
        throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: values.count)
      }
      self.init { values[$0] }
    }

    /// Validates the packed byte count and clears unused high bits in the final byte.
    public init(packedBytes: [UInt8]) throws {
      guard Self.count >= 0, packedBytes.count == Self.byteCount else {
        throw VectorDecodingError.invalidBytes
      }
      self.storage = packedBytes
      self.clearUnusedBits()
    }

    /// Applies zero-threshold binary quantization using `value > 0`, following Turso's sign rule.
    ///
    /// Positive values, including positive infinity, become true. Zeros, negative values,
    /// and NaNs become false. This discards all magnitude information without normalizing or
    /// centering the input. Retrieval quality depends on the embedding model.
    /// See [binary embedding quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization).
    public init(quantizing values: EmbeddingVector<count>) {
      self.init { values[$0] > 0 }
    }

    public subscript(position: Int) -> Bool {
      get {
        precondition((0..<Self.count).contains(position), "Binary vector index out of bounds")
        return self.storage[position / 8] & (UInt8(1) << (position % 8)) != 0
      }
      set {
        precondition((0..<Self.count).contains(position), "Binary vector index out of bounds")
        let mask = UInt8(1) << (position % 8)
        if newValue {
          self.storage[position / 8] |= mask
        } else {
          self.storage[position / 8] &= ~mask
        }
      }
    }

    public func index(after index: Int) -> Int { index + 1 }
    public func index(before index: Int) -> Int { index - 1 }

    /// Counts differing logical bits without unpacking either vector.
    @inlinable
    public func hammingDistance(to other: Self) -> Int {
      zip(self.storage, other.storage).reduce(0) { $0 + ($1.0 ^ $1.1).nonzeroBitCount }
    }

    /// Encodes a boolean array, preserving the logical representation in JSON and other encoders.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.unkeyedContainer()
      for bit in self {
        try container.encode(bit)
      }
    }

    public init(from decoder: any Decoder) throws {
      let values = try [Bool](from: decoder)
      guard values.count == Self.count else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Expected \(Self.count) binary components, got \(values.count)"
          )
        )
      }
      try self.init(validating: values)
    }

    public var description: String { "BinaryEmbeddingVector<\(Self.count)>(\(Array(self)))" }
    public var debugDescription: String { self.description }

    private static var byteCount: Int { Self.count / 8 + (Self.count % 8 == 0 ? 0 : 1) }

    private mutating func clearUnusedBits() {
      let remainder = Self.count % 8
      if remainder != 0, !self.storage.isEmpty {
        self.storage[self.storage.count - 1] &= (UInt8(1) << remainder) - 1
      }
    }
  }
#endif
