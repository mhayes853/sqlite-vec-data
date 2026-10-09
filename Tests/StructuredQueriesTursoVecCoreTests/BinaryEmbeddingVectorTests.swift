import CustomDump
import Foundation
import StructuredQueriesTursoVecCore
import Testing

#if swift(>=6.2)
  @Suite
  struct `BinaryEmbeddingVector tests` {
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Generates Bits From Each Preceding Bit Including Empty And Singleton Vectors`() {
      // https://github.com/swiftlang/swift/blob/swift-6.3-RELEASE/stdlib/public/core/InlineArray.swift#L309
      var precedingBits = [Bool]()
      let vector = BinaryEmbeddingVector<9>(first: true) {
        precedingBits.append($0)
        return !$0
      }
      expectNoDifference(precedingBits, [true, false, true, false, true, false, true, false])
      expectNoDifference(vector.packedBytes, [85, 1])
      expectNoDifference(Array(vector), [true, false, true, false, true, false, true, false, true])

      var calls = 0
      let empty = BinaryEmbeddingVector<0>(first: true) {
        calls += 1
        return !$0
      }
      let single = BinaryEmbeddingVector<1>(first: true) {
        calls += 1
        return !$0
      }
      expectNoDifference(empty.packedBytes, [])
      expectNoDifference(single.packedBytes, [1])
      expectNoDifference(calls, 0)
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Stops Generation Immediately When Next Throws`() {
      var calls = 0
      #expect(throws: GeneratorError.stopped) {
        _ = try BinaryEmbeddingVector<9>(first: true) {
          calls += 1
          if calls == 3 {
            throw GeneratorError.stopped
          }
          return !$0
        }
      }
      expectNoDifference(calls, 3)
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Packs Bits Across Byte Boundaries`() {
      var vector = BinaryEmbeddingVector<17>(repeating: false)
      for index in [0, 7, 8, 16] {
        vector[index] = true
      }
      expectNoDifference(vector.packedBytes, [129, 1, 1])
      expectNoDifference(vector.nonzeroBitCount, 4)
      expectNoDifference(Array(vector), (0..<17).map { [0, 7, 8, 16].contains($0) })

      var copy = vector
      copy[7] = false
      copy[9] = true
      expectNoDifference(copy.packedBytes, [1, 3, 1])
      expectNoDifference(vector.packedBytes, [129, 1, 1])
      expectNoDifference(vector.hammingDistance(to: copy), 2)
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Normalizes Unused Bits For Equality Hashing And Distance`() throws {
      let vector = try BinaryEmbeddingVector<9>(packedBytes: [133, 255])
      let canonical = try BinaryEmbeddingVector<9>(packedBytes: [133, 1])
      expectNoDifference(vector.packedBytes, [133, 1])
      expectNoDifference(vector, canonical)
      expectNoDifference(vector.hashValue, canonical.hashValue)
      expectNoDifference(vector.nonzeroBitCount, 4)
      expectNoDifference(vector.hammingDistance(to: canonical), 0)
      expectNoDifference(Array(vector), [true, false, true, false, false, false, false, true, true])
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Masks Repeated Bits At Boundary Dimensions`() {
      expectNoDifference(BinaryEmbeddingVector<0>(repeating: true).packedBytes, [])
      expectNoDifference(BinaryEmbeddingVector<8>(repeating: true).packedBytes, [255])
      expectNoDifference(BinaryEmbeddingVector<9>(repeating: true).packedBytes, [255, 1])
      let embedding = BinaryEmbeddingVector<1_536>(repeating: true)
      expectNoDifference(
        embedding.hammingDistance(to: BinaryEmbeddingVector<1_536>(repeating: false)),
        1_536
      )
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Rejects Incorrect Logical And Packed Lengths`() throws {
      #expect(throws: VectorDecodingError.invalidBytes) {
        _ = try BinaryEmbeddingVector<9>(packedBytes: [1])
      }
      #expect(throws: VectorDecodingError.invalidBytes) {
        _ = try BinaryEmbeddingVector<9>(packedBytes: [1, 2, 3])
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 9, actual: 1)) {
        _ = try BinaryEmbeddingVector<9>(validating: [true])
      }
      let vector = try BinaryEmbeddingVector<9>(validating: Array(repeating: true, count: 9))
      expectNoDifference(vector.packedBytes, [255, 1])
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Uses Turso Positive Sign Quantization`() {
      // https://docs.turso.tech/guides/vector-search#binary-vectors
      // Conversion rule: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/convert.rs
      let values = EmbeddingVector<8>([1, -1, 0, -0.0, .infinity, -.infinity, .nan, 2])
      let vector = BinaryEmbeddingVector<8>(quantizing: values)
      expectNoDifference(vector.packedBytes, [145])
      expectNoDifference(Array(vector), [true, false, false, false, true, false, false, true])
      expectNoDifference(vector.nonzeroBitCount, 3)
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Codable Uses Logical Booleans`() throws {
      let vector = try BinaryEmbeddingVector<9>(packedBytes: [133, 1])
      let encoded = try JSONEncoder().encode(vector)
      expectNoDifference(
        String(decoding: encoded, as: UTF8.self),
        "[true,false,true,false,false,false,false,true,true]"
      )
      expectNoDifference(
        try JSONDecoder().decode(BinaryEmbeddingVector<9>.self, from: encoded),
        vector
      )
      #expect(throws: DecodingError.self) {
        _ = try JSONDecoder().decode(BinaryEmbeddingVector<8>.self, from: encoded)
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Adapters Preserve Packed Payloads And Dimension Metadata`() throws {
      // https://docs.turso.tech/guides/vector-search#binary-vectors
      // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
      // SQLiteVec bit order: https://github.com/asg017/sqlite-vec/blob/v0.1.9/sqlite-vec.c
      let vector = try BinaryEmbeddingVector<9>(packedBytes: [133, 1])
      let turso = BinaryEmbeddingVector<9>.TursoBytesRepresentation(queryOutput: vector)
      expectNoDifference(turso.vectorBytes, [133, 1, 0, 23, 3])
      let decoded = try BinaryEmbeddingVector<9>
        .TursoBytesRepresentation(
          vectorBytes: [133, 255, 0, 23, 3]
        )
      expectNoDifference(decoded.queryOutput, vector)
      expectNoDifference(decoded.vectorBytes, [133, 1, 0, 23, 3])
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 8, actual: 9)) {
        _ = try BinaryEmbeddingVector<8>.TursoBytesRepresentation(vectorBytes: turso.vectorBytes)
      }

      let packed = try BinaryEmbeddingVector<16>.PackedBitsRepresentation(vectorBytes: [133, 129])
      expectNoDifference(packed.queryOutput.packedBytes, [133, 129])
      expectNoDifference(packed.queryBinding, .blob([133, 129]))
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 9, actual: 16)) {
        _ = try BinaryEmbeddingVector<9>.PackedBitsRepresentation(vectorBytes: [133, 1])
      }
      let empty = BinaryEmbeddingVector<0>
        .TursoBytesRepresentation(queryOutput: BinaryEmbeddingVector<0>(repeating: false))
      expectNoDifference(empty.vectorBytes, [0, 16, 3])
      expectNoDifference(
        try BinaryEmbeddingVector<0>.TursoBytesRepresentation(vectorBytes: empty.vectorBytes),
        empty
      )
    }
  }

  private enum GeneratorError: Error, Hashable, Sendable {
    case stopped
  }

#endif
