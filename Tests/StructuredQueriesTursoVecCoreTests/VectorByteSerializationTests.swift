import CustomDump
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `Vector Byte Serialization tests` {
  @Test
  func `Serializes Dense Values Without A Query Decoder`() throws {
    // https://docs.turso.tech/guides/vector-search#vector-types
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    let floatBytes: [UInt8] = [0, 0, 128, 63, 0, 0, 0, 192]
    let doubleBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 192, 2]
    expectNoDifference([Float(1), -2].vectorBytes, floatBytes)
    expectNoDifference([Double(1), -2].vectorBytes, doubleBytes)
    expectNoDifference(try [Float](vectorBytes: floatBytes), [1, -2])
    expectNoDifference(try [Double](vectorBytes: doubleBytes), [1, -2])
    expectNoDifference(
      try [Float].VectorBytesRepresentation(vectorBytes: floatBytes).queryOutput,
      [1, -2]
    )
    expectNoDifference(
      try [Double].VectorBytesRepresentation(vectorBytes: doubleBytes).queryOutput,
      [1, -2]
    )
    expectNoDifference(Float.encodeVector([1, -2]), floatBytes)
    expectNoDifference(try Double.decodeVector(doubleBytes), [1, -2])
    #expect(throws: VectorDecodingError.invalidBytes) {
      _ = try [Float](vectorBytes: [1, 2])
    }
    #expect(throws: VectorDecodingError.invalidBytes) {
      _ = try [Double].VectorBytesRepresentation(vectorBytes: Array(doubleBytes.dropLast()))
    }
  }

  @Test
  func `Preserves Encoded Components Through The Public Byte API`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    let quantizedBytes: [UInt8] = [10, 20, 0, 0, 0, 0, 0, 64, 0, 0, 128, 63, 0, 2, 4]
    let sparseBytes: [UInt8] = [
      0, 0, 0, 128, 35, 1, 128, 127,
      0, 0, 0, 0, 2, 0, 0, 0,
      3, 0, 0, 0, 9
    ]
    let quantized = try Quantized8Vector(vectorBytes: quantizedBytes)
    let sparse = try SparseFloat32Vector(vectorBytes: sparseBytes)
    expectNoDifference(quantized.codes, [10, 20])
    expectNoDifference(quantized.scale, 2)
    expectNoDifference(quantized.shift, 1)
    expectNoDifference(quantized.vectorBytes, quantizedBytes)
    expectNoDifference(quantized.queryBinding, .blob(quantizedBytes))
    expectNoDifference(sparse.indices, [0, 2])
    expectNoDifference(sparse.values.map(\.bitPattern), [0x8000_0000, 0x7f80_0123])
    expectNoDifference(sparse.vectorBytes, sparseBytes)
    expectNoDifference(sparse.queryBinding, .blob(sparseBytes))
    #expect(throws: VectorDecodingError.invalidBytes) {
      _ = try Quantized8Vector(vectorBytes: [4])
    }
    #expect(throws: VectorDecodingError.invalidBytes) {
      _ = try SparseFloat32Vector(vectorBytes: [9])
    }
  }

  @Test
  func `Retains The Distinct Binary Layouts`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    // https://github.com/asg017/sqlite-vec/blob/v0.1.9/sqlite-vec.c
    let packed = try [Bool].PackedBitsRepresentation(vectorBytes: [133])
    let turso = try [Bool].TursoBytesRepresentation(vectorBytes: [133, 1, 0, 23, 3])
    expectNoDifference(packed.queryOutput, [true, false, true, false, false, false, false, true])
    expectNoDifference(turso.queryOutput, packed.queryOutput + [true])
    expectNoDifference(packed.vectorBytes, [133])
    expectNoDifference(turso.vectorBytes, [133, 1, 0, 23, 3])
    #expect(throws: VectorDecodingError.invalidBytes) {
      _ = try [Bool].TursoBytesRepresentation(vectorBytes: [133])
    }
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Validates Array Construction Across Scalar Types`() throws {
      expectNoDifference(try EmbeddingVector<2>(validating: [1, 2]), EmbeddingVector<2>([1, 2]))
      expectNoDifference(try EmbeddingVector64<2>(validating: [1, 2]), EmbeddingVector64<2>([1, 2]))
      expectNoDifference(
        try BinaryEmbeddingVector<2>(validating: [true, false]),
        BinaryEmbeddingVector<2>([true, false])
      )
      expectNoDifference(try EmbeddingVector<0>(validating: []), EmbeddingVector<0>(repeating: 0))
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 2, actual: 1)) {
        _ = try EmbeddingVector<2>(validating: [1])
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 2, actual: 3)) {
        _ = try BinaryEmbeddingVector<2>(validating: [true, false, true])
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Validates Fixed Dimensions Through The Public Byte API`() throws {
      // https://docs.turso.tech/guides/vector-search#vector-types
      let floats = [Float(1), -2].vectorBytes
      let doubles = [Double(1), -2].vectorBytes
      let quantizedBytes: [UInt8] = [10, 20, 0, 0, 0, 0, 0, 64, 0, 0, 128, 63, 0, 2, 4]
      let sparseBytes: [UInt8] = [0, 0, 0, 64, 1, 0, 0, 0, 2, 0, 0, 0, 9]
      let inline = try [2 of Float](vectorBytes: floats)
      expectNoDifference([inline[0], inline[1]], [1, -2])
      expectNoDifference(inline.vectorBytes, floats)
      expectNoDifference(
        try [2 of Float].VectorBytesRepresentation(vectorBytes: floats).vectorBytes,
        floats
      )
      expectNoDifference(try EmbeddingVector<2>(vectorBytes: floats), EmbeddingVector<2>([1, -2]))
      expectNoDifference(try EmbeddingVector64<2>(vectorBytes: doubles).vectorBytes, doubles)
      expectNoDifference(
        try EmbeddingVector64<2>.VectorBytesRepresentation(vectorBytes: doubles).vectorBytes,
        doubles
      )
      expectNoDifference(
        try InlineQuantized8Vector<2>(vectorBytes: quantizedBytes).vectorBytes,
        quantizedBytes
      )
      expectNoDifference(
        try SizedSparseFloat32Vector<2>(vectorBytes: sparseBytes).vectorBytes,
        sparseBytes
      )
      expectNoDifference(
        try BinaryEmbeddingVector<8>.PackedBitsRepresentation(vectorBytes: [133]).vectorBytes,
        [133]
      )
      expectNoDifference(
        try BinaryEmbeddingVector<9>.TursoBytesRepresentation(vectorBytes: [133, 1, 0, 23, 3])
          .vectorBytes,
        [133, 1, 0, 23, 3]
      )
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 3, actual: 2)) {
        _ = try [3 of Float](vectorBytes: floats)
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 3, actual: 2)) {
        _ = try EmbeddingVector<3>.VectorBytesRepresentation(vectorBytes: floats)
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 3, actual: 2)) {
        _ = try InlineQuantized8Vector<3>(vectorBytes: quantizedBytes)
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 3, actual: 2)) {
        _ = try SizedSparseFloat32Vector<3>(vectorBytes: sparseBytes)
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 7, actual: 8)) {
        _ = try BinaryEmbeddingVector<7>.PackedBitsRepresentation(vectorBytes: [133])
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 8, actual: 9)) {
        _ = try BinaryEmbeddingVector<8>.TursoBytesRepresentation(vectorBytes: [133, 1, 0, 23, 3])
      }
    }
  #endif
}
