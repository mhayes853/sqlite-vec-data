import CustomDump
import SQLiteVecData
import Testing

@Suite
struct `Vector Query Safety tests` {
  private let database: DatabaseQueue

  init() throws {
    var configuration = Configuration()
    configuration.prepareSQLiteVecExtension()
    self.database = try DatabaseQueue(configuration: configuration)
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Subtype And Quantization Chains Retain Fixed Results`() async throws {
      // https://alexgarcia.xyz/sqlite-vec/api-reference.html#vec_quantize_binary-vector
      // https://github.com/mhayes853/sqlite-vec-data/blob/f980c99e337ff7c3aff250558d038ee2b149f47e/Sources/CSQLiteVec/sqlite-vec.c#L1434-L1478
      let source = EmbeddingVector<8>([1, -1, 0, 1, -1, 0, 1, -1])
      let floats = Vec.f32(source)
      let codes = Vec.int8(Vec.quantizeInt8(floats))
      let bits = Vec.bit(Vec.quantizeBinary(codes))
      requireEightDimensions(floats)
      requireEightDimensions(codes)
      requireEightDimensions(bits)
      let query = #sql(
        "SELECT \(floats), \(codes), \(bits)",
        as: (
          EmbeddingVector<8>,
          FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation,
          BinaryEmbeddingVector<8>.PackedBitsRepresentation
        )
        .self
      )
      try await self.database.read { db in
        let result = try #require(try query.fetchOne(db))
        expectNoDifference(result.0, source)
        expectNoDifference(
          result.1,
          FixedEmbeddingVector<8, Int8>([126, -128, 0, 126, -128, 0, 126, -128])
        )
        expectNoDifference(
          result.2,
          BinaryEmbeddingVector<8>([true, false, false, true, false, false, true, false])
        )
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Float32 JSON Preserves Fixed Dimensions Through Normalization And Arithmetic`()
      async throws
    {
      // https://alexgarcia.xyz/sqlite-vec/api-reference.html#vec_f32-vector
      let vector = Vec.f32("[3, 0, 0]", as: EmbeddingVector<3>.self)
      let expression = Vec.add(Vec.normalize(vector), Vec.f32("[0, 2, 0]"))
      requireThreeDimensions(expression)
      expectNoDifference(
        expression.queryFragment.prepare { "?\($0)" }.sql,
        "vec_add(vec_normalize(vec_f32(?1)), vec_f32(?2))"
      )
      let query = #sql(
        "SELECT \(expression)",
        as: EmbeddingVector<3>.VectorBytesRepresentation.self
      )
      try await self.database.read { db in
        expectNoDifference(try query.fetchOne(db), EmbeddingVector<3>([1, 2, 0]))
        let invalid = #sql(
          "SELECT \(Vec.f32("[1, 2, 3]", as: EmbeddingVector<4>.self))",
          as: EmbeddingVector<4>.self
        )
        #expect(throws: VectorDecodingError.dimensionMismatch(expected: 4, actual: 3)) {
          try invalid.fetchOne(db)
        }
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Packed Bit Validation Supports Rebinding And Rejects Partial Bytes`() async throws {
      // https://alexgarcia.xyz/sqlite-vec/api-reference.html#vec_bit-vector
      let components = [true, false, true, false, false, false, false, true]
      var variable = try [Bool].PackedBitsRepresentation(validating: components)
      variable.queryOutput = components + components
      let fixed = try BinaryEmbeddingVector<16>
        .PackedBitsRepresentation(
          validating: BinaryEmbeddingVector<16>(packedBytes: [0x85, 0x85])
        )
      expectNoDifference(variable.queryBinding, .blob([0x85, 0x85]))
      let query = #sql("SELECT \(Vec.distanceHamming(variable, to: fixed))", as: Double.self)
      try await self.database.read { db in
        expectNoDifference(try query.fetchOne(db), 0)
      }
      for count in [1, 7, 9] {
        #expect(throws: [Bool].PackedBitsRepresentation.InvalidDimensionsError(dimensions: count)) {
          try [Bool].PackedBitsRepresentation(validating: [Bool](repeating: true, count: count))
        }
      }
      #expect(throws: [Bool].PackedBitsRepresentation.InvalidDimensionsError(dimensions: 9)) {
        try BinaryEmbeddingVector<9>
          .PackedBitsRepresentation(
            validating: BinaryEmbeddingVector<9>(repeating: true)
          )
      }
    }
  #endif
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  private func requireThreeDimensions<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) where V.Dimensions == VectorDimensions<3> {}

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  private func requireEightDimensions<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) where V.Dimensions == VectorDimensions<8> {}
#endif
