/// A fixed-dimension vector of logical bits backed by packed byte storage.
///
/// The first element occupies the least significant bit of the first byte. Unused trailing
/// bits are always zero. Database encodings are selected through explicit representations.
///
/// ```swift
/// let dense = EmbeddingVector<8>([1, -1, 0, 2, -3, 4, 0, 5])
/// let embedding = BinaryEmbeddingVector<8>(quantizing: dense)
/// let payload = embedding.packedBytes // [0xa9]: eight signs in one byte.
/// ```
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
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<9>(repeating: true)
  /// let payload = embedding.packedBytes // [0xff, 0x01]: unused high bits are cleared.
  /// ```
  public var packedBytes: [UInt8] { self.storage }
  /// The number of logical vector components.
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<1536>(repeating: false)
  /// let dimensions = embedding.dimensions // 1536 logical bits
  /// let byteCount = embedding.packedBytes.count // 192 storage bytes
  /// ```
  public var dimensions: Int { Self.count }
  /// The index of the first logical component.
  ///
  /// ```swift
  /// var embedding = BinaryEmbeddingVector<3>([true, false, true])
  /// embedding[embedding.startIndex] = false
  /// let payload = embedding.packedBytes // [0x04]
  /// ```
  public var startIndex: Int { 0 }
  /// The index one past the last logical component.
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<3>([true, false, true])
  /// let lastBit = embedding[embedding.index(before: embedding.endIndex)] // true
  /// ```
  public var endIndex: Int { Self.count }

  /// The number of true components.
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<8>([true, false, true, false, false, false, false, true])
  /// let activeFraction = Float(embedding.nonzeroBitCount) / Float(embedding.dimensions) // 0.375
  /// ```
  public var nonzeroBitCount: Int {
    self.storage.reduce(0) { $0 + $1.nonzeroBitCount }
  }

  /// Packs the logical components of an inline array.
  ///
  /// ```swift
  /// let components: InlineArray<3, Bool> = [true, false, true]
  /// let embedding = BinaryEmbeddingVector<3>(components)
  /// let payload = embedding.packedBytes // [0x05]
  /// ```
  public init(_ values: [count of Bool]) {
    self.init { values[$0] }
  }

  /// Creates a vector by repeating a logical component.
  ///
  /// ```swift
  /// var embedding = BinaryEmbeddingVector<8>(repeating: false)
  /// embedding[7] = true
  /// let payload = embedding.packedBytes // [0x80]
  /// ```
  public init(repeating value: Bool) {
    precondition(Self.count >= 0, "Binary vector dimensions must be nonnegative")
    self.storage = Array(repeating: value ? UInt8.max : 0, count: Self.byteCount)
    self.clearUnusedBits()
  }

  /// Creates a vector by generating its logical components.
  ///
  /// ```swift
  /// let activations: [Float] = [-0.8, 0, 0.6]
  /// let embedding = BinaryEmbeddingVector<3> { activations[$0] > 0 }
  /// let components = Array(embedding) // [false, false, true]
  /// ```
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
  ///
  /// ```swift
  /// let mask = BinaryEmbeddingVector<8>(first: true) { !$0 }
  /// let payload = mask.packedBytes // [0x55]: alternating active bits.
  /// ```
  public init<E: Error>(first: Bool, next: (Bool) throws(E) -> Bool) throws(E) {
    self.init(repeating: false)
    if Self.count > 0 {
      self[0] = first
      for index in 1..<Self.count {
        self[index] = try next(self[index - 1])
      }
    }
  }

  /// Initializes the fixed-size logical components through an output span.
  ///
  /// ```swift
  /// let components = [true, false, true]
  /// let embedding = BinaryEmbeddingVector<3>(initializingWith: { span in
  ///   for component in components { span.append(component) }
  /// })
  /// let payload = embedding.packedBytes // [0x05]
  /// ```
  public init<E: Error>(
    initializingWith initializer: (inout OutputSpan<Bool>) throws(E) -> Void
  ) throws(E) {
    try self.init([count of Bool](initializingWith: initializer))
  }

  /// Validates the logical element count before packing an array.
  ///
  /// ```swift
  /// let components = [true, false, true]
  /// let embedding = try BinaryEmbeddingVector<3>(validating: components)
  /// // A different component count throws VectorDecodingError.dimensionMismatch.
  /// ```
  public init(validating values: [Bool]) throws {
    guard values.count == Self.count else {
      throw VectorDecodingError.dimensionMismatch(expected: Self.count, actual: values.count)
    }
    self.init { values[$0] }
  }

  /// Validates the packed byte count and clears unused high bits in the final byte.
  ///
  /// ```swift
  /// let vector = try BinaryEmbeddingVector<3>(packedBytes: [0x05])
  /// // Logical components: [true, false, true].
  /// ```
  public init(packedBytes: [UInt8]) throws {
    guard Self.count >= 0, packedBytes.count == Self.byteCount else {
      throw VectorDecodingError.invalidBytes
    }
    self.storage = packedBytes
    self.clearUnusedBits()
  }

  /// Applies zero-threshold binary quantization using `value > 0`.
  ///
  /// Positive values, including positive infinity, become true. Zeros, negative values,
  /// and NaNs become false. This discards all magnitude information without normalizing or
  /// centering the input. Retrieval quality depends on the embedding model.
  /// See [binary embedding quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization).
  ///
  /// ```swift
  /// let vector = BinaryEmbeddingVector<3>(quantizing: EmbeddingVector<3>([-1, 0, 1]))
  /// // Logical components: [false, false, true].
  /// ```
  public init(quantizing values: EmbeddingVector<count>) {
    self.init { values[$0] > 0 }
  }

  /// A logical component, accessed or updated by index.
  ///
  /// ```swift
  /// var embedding = BinaryEmbeddingVector<8>(repeating: false)
  /// embedding[0] = true
  /// embedding[7] = true
  /// let payload = embedding.packedBytes // [0x81]
  /// ```
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

  /// Returns the following logical index.
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<3>([true, false, true])
  /// let secondBit = embedding[embedding.index(after: embedding.startIndex)] // false
  /// ```
  public func index(after index: Int) -> Int { index + 1 }
  /// Returns the preceding logical index.
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<3>([true, false, true])
  /// let lastBit = embedding[embedding.index(before: embedding.endIndex)] // true
  /// ```
  public func index(before index: Int) -> Int { index - 1 }

  /// Counts differing logical bits without unpacking either vector.
  ///
  /// ```swift
  /// let query = BinaryEmbeddingVector<3>([true, false, true])
  /// let candidate = BinaryEmbeddingVector<3>([true, true, false])
  /// let isNear = query.hammingDistance(to: candidate) <= 1 // false: two bits differ.
  /// ```
  @inlinable
  public func hammingDistance(to other: Self) -> Int {
    zip(self.storage, other.storage).reduce(0) { $0 + ($1.0 ^ $1.1).nonzeroBitCount }
  }

  /// Encodes a boolean array, preserving the logical representation in JSON and other encoders.
  ///
  /// ```swift
  /// import Foundation
  ///
  /// let embedding = BinaryEmbeddingVector<3>([true, false, true])
  /// let json = try JSONEncoder().encode(embedding)
  /// let payload = String(decoding: json, as: UTF8.self) // "[true,false,true]"
  /// ```
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    for bit in self {
      try container.encode(bit)
    }
  }

  /// Decodes logical components, validating the fixed dimension count.
  ///
  /// ```swift
  /// import Foundation
  ///
  /// let payload = Data("[true,false,true]".utf8)
  /// let embedding = try JSONDecoder().decode(BinaryEmbeddingVector<3>.self, from: payload)
  /// let packed = embedding.packedBytes // [0x05]; a different component count throws.
  /// ```
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

  /// A description of the vector and its logical components.
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<3>([true, false, true])
  /// print(embedding.description) // BinaryEmbeddingVector<3>([true, false, true])
  /// ```
  public var description: String { "BinaryEmbeddingVector<\(Self.count)>(\(Array(self)))" }
  /// A description of the vector and its logical components.
  ///
  /// ```swift
  /// let embedding = BinaryEmbeddingVector<3>([true, false, true])
  /// print(embedding.debugDescription) // BinaryEmbeddingVector<3>([true, false, true])
  /// ```
  public var debugDescription: String { self.description }

  private static var byteCount: Int { Self.count / 8 + (Self.count % 8 == 0 ? 0 : 1) }

  private mutating func clearUnusedBits() {
    let remainder = Self.count % 8
    if remainder != 0, !self.storage.isEmpty {
      self.storage[self.storage.count - 1] &= (UInt8(1) << remainder) - 1
    }
  }
}
