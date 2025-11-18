import CustomDump
import Foundation
import SQLiteVecData
import Testing

#if swift(>=6.2)
  @Suite("EmbeddingVector tests")
  struct EmbeddingVectorTests {
    @Test(
      "Equatable",
      arguments: [
        (EmbeddingVector([1, 2, 3, 4]), EmbeddingVector([1, 2, 3, 4]), true),
        (EmbeddingVector([1, 2, 3, 4]), EmbeddingVector([1, 2, 3, 2]), false),
        (EmbeddingVector<4>(repeating: 1), EmbeddingVector([1, 1, 1, 1]), true)
      ]
    )
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func equatable(lhs: EmbeddingVector<4>, rhs: EmbeddingVector<4>, isEqual: Bool) {
      expectNoDifference(lhs == rhs, isEqual)
    }

    @Test(
      "Hashable",
      arguments: [
        (EmbeddingVector([1, 2, 3, 4]), EmbeddingVector([1, 2, 3, 4]), true),
        (EmbeddingVector([1, 2, 3, 4]), EmbeddingVector([1, 2, 3, 2]), false),
        (EmbeddingVector<4>(repeating: 1), EmbeddingVector([1, 1, 1, 1]), true)
      ]
    )
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func hashable(lhs: EmbeddingVector<4>, rhs: EmbeddingVector<4>, isEqual: Bool) {
      expectNoDifference(lhs.hashValue == rhs.hashValue, isEqual)
      expectNoDifference(Array(lhs).hashValue, lhs.hashValue)
      expectNoDifference(Array(rhs).hashValue, rhs.hashValue)
    }

    @Test("Encodes To Array")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func encodesToArray() throws {
      let vector = EmbeddingVector([1, 2, 3, 4])
      let data = try JSONEncoder().encode(vector)
      expectNoDifference(String(decoding: data, as: UTF8.self), "[1,2,3,4]")
    }

    @Test("Encode Then Decode")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func encodeThenDecode() throws {
      let vector = EmbeddingVector([1, 2, 3, 4])
      let data = try JSONEncoder().encode(vector)
      let decoded = try JSONDecoder().decode(EmbeddingVector<4>.self, from: data)
      expectNoDifference(vector, decoded)
    }

    @Test("Fails To Decode When Count Of Elements Is Incorrect")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func failsToDecodeWhenCountOfElementsIsIncorrect() throws {
      let data1 = try JSONEncoder().encode(EmbeddingVector([1, 2, 3]))
      let data2 = try JSONEncoder().encode(EmbeddingVector([1, 2, 3, 4, 5]))
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(EmbeddingVector<4>.self, from: data1)
      }
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(EmbeddingVector<4>.self, from: data2)
      }
    }

    @Test(
      "CustomStringConvertible",
      arguments: [
        (EmbeddingVector([1, 2, 3, 4]), "EmbeddingVector<4>([1.0, 2.0, 3.0, 4.0])"),
        (EmbeddingVector([1.1, 2.2, 3.3, 4.4]), "EmbeddingVector<4>([1.1, 2.2, 3.3, 4.4])"),
        (EmbeddingVector(repeating: 3.4), "EmbeddingVector<4>([3.4, 3.4, 3.4, 3.4])")
      ]
    )
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func customStringConvertible(vec: EmbeddingVector<4>, string: String) {
      expectNoDifference(vec.description, string)
      expectNoDifference(vec.debugDescription, string)
    }
  }
#endif
