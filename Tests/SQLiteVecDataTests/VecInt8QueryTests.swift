import CustomDump
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite(.sqliteVecAutoExtension)
struct `Vec Int8 Query tests` {
  private let database: DatabaseQueue
  private static let vector: [Int8].Int8BytesRepresentation = [-128, -64, 0, 1, 2, 3, 4, 127]

  init() async throws {
    self.database = try DatabaseQueue()
    try await self.database.write { db in
      #if canImport(Darwin)
        try db.loadSQLiteVecExtension()
      #endif
      try #sql(
        "CREATE VIRTUAL TABLE VecInt8Embeddings USING vec0(embedding int8[8], label text)",
        as: Void.self
      )
      .execute(db)
      let near: [Int8].Int8BytesRepresentation = [-127, -64, 0, 1, 2, 3, 4, 127]
      try VecInt8Embedding.insert {
        ($0.embedding, $0.label)
      } values: {
        (Vec.int8(near), "near")
        (Vec.int8(Self.vector), "exact")
      }
      .execute(db)
    }
  }

  @Test
  func `Unit Quantization Produces Signed Codes And Clamps Components`() async throws {
    // The bundled implementation defines the unit mapping and Float32 rounding:
    // https://github.com/mhayes853/sqlite-vec-data/blob/f980c99e337ff7c3aff250558d038ee2b149f47e/Sources/CSQLiteVec/sqlite-vec.c#L1434-L1478
    let floats: [Float].VectorBytesRepresentation = [-2, -1, -0.5, 0, 0.5, 1, 2, .nan]
    let quantized = Vec.quantizeInt8(floats)
    let prepared = quantized.queryFragment.prepare { "?\($0)" }
    expectNoDifference(prepared.sql, "vec_quantize_int8(?1, 'unit')")
    let query = #sql(
      "SELECT \(quantized), \(Vec.toJSON(quantized))",
      as: ([Int8].Int8BytesRepresentation, String).self
    )
    try await self.database.read { db in
      let result = try #require(try query.fetchOne(db))
      expectNoDifference(result.0, [-128, -128, -64, 0, 63, 126, 127, 127])
      expectNoDifference(result.1, "[-128,-128,-64,0,63,126,127,127]")
    }
  }

  @Test
  func `Stored Int8 Vectors Match Bound And Computed Queries`() async throws {
    let vector = Self.vector
    let match =
      VecInt8Embedding
      .where { $0.embedding.match(Vec.slice(vector, range: 0..<8)) }
      .order { $0.distance }
      .limit(2)
      .select { ($0.label, $0.embedding, $0.distance) }
    let scalar =
      VecInt8Embedding
      .order { $0.embedding.distanceL2(to: vector) }
      .select {
        (
          $0.embedding.distanceL2(to: vector), $0.embedding.distanceL1(to: vector),
          $0.embedding.distanceCosine(to: vector)
        )
      }
    try await self.database.read { db in
      let rows = try match.fetchAll(db)
      let scalarRows = try scalar.fetchAll(db)
      expectNoDifference(rows.map(\.0), ["exact", "near"])
      expectNoDifference(rows.first?.1, vector.queryOutput)
      expectNoDifference(rows.map(\.2), [0, 1])
      expectNoDifference(scalarRows.map(\.0), rows.map(\.2))
      expectNoDifference(scalarRows.map(\.1), [0, 1])
      #expect(abs(scalarRows[0].2) < 0.000001)
      #expect(scalarRows[1].2 > scalarRows[0].2)
    }
  }

  @Test
  func `Int8 Operations Preserve The Encoding`() async throws {
    let vector = Self.vector
    let offset: [Int8].Int8BytesRepresentation = [1, 1, -1, 2, 3, 4, 5, -1]
    let query =
      VecInt8Embedding
      .where { $0.label.eq("exact") }
      .select {
        (
          $0.embedding.length(), $0.embedding.type(), $0.embedding.toJSON(),
          $0.embedding.add(offset), Vec.sub($0.embedding.add(offset), offset),
          $0.embedding.slice(1...3),
          $0.embedding.quantizeBinary()
        )
      }
    let each =
      VecInt8Embedding
      .join(VecInt8Embedding.columns.embedding.vecEach()) { _, _ in true }
      .where { embedding, _ in embedding.label.eq("exact") }
      .order { _, element in element.rowid }
      .select { _, element in element.value }
    try await self.database.read { db in
      let result = try #require(try query.fetchOne(db))
      expectNoDifference(result.0, 8)
      expectNoDifference(result.1, "int8")
      expectNoDifference(result.2, "[-128,-64,0,1,2,3,4,127]")
      expectNoDifference(result.3, [-127, -63, -1, 3, 5, 7, 9, 126])
      expectNoDifference(result.4, vector.queryOutput)
      expectNoDifference(result.5, [-64, 0, 1])
      expectNoDifference(result.6, [false, false, false, true, true, true, true, true])
      expectNoDifference(try each.fetchAll(db), vector.queryOutput.map(Float.init))
    }
  }

  @Test
  func `JSON And Raw Bytes Decode As Int8 Rather Than Float32`() async throws {
    // https://alexgarcia.xyz/sqlite-vec/api-reference.html#vec_int8
    // A three-byte payload is valid: each signed component occupies exactly one byte.
    let vector = try [Int8].Int8BytesRepresentation(vectorBytes: [0x80, 0, 0x7f])
    let query = #sql(
      "SELECT \(Vec.int8("[-128, 0, 127]")), \(Vec.int8(vector))",
      as: ([Int8].Int8BytesRepresentation, [Int8].Int8BytesRepresentation).self
    )
    expectNoDifference(vector.vectorBytes, [0x80, 0, 0x7f])
    try await self.database.read { db in
      let result = try #require(try query.fetchOne(db))
      expectNoDifference(result.0, [-128, 0, 127])
      expectNoDifference(result.1, [-128, 0, 127])
      for json in ["[128]", "[1.5]"] {
        #expect(throws: Error.self) {
          try #sql("SELECT \(Vec.int8(json))", as: [Int8].Int8BytesRepresentation.self)
            .fetchOne(db)
        }
      }
    }
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Fixed Int8 Strategies Validate Quantized And Sliced Dimensions`() async throws {
      let floats = EmbeddingVector<4>([-1, 0, 0.5, 2])
      let quantized = Vec.quantizeInt8(
        floats,
        as: FixedEmbeddingVector<4, Int8>.Int8BytesRepresentation.self
      )
      let query = #sql(
        "SELECT \(quantized)",
        as: FixedEmbeddingVector<4, Int8>.Int8BytesRepresentation.self
      )
      let slice = Vec.slice(
        quantized,
        range: 1..<3,
        as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
      )
      let sliceQuery = #sql(
        "SELECT \(slice)",
        as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
      )
      let wrongDimensionQuery = #sql(
        "SELECT \(slice)",
        as: FixedEmbeddingVector<3, Int8>.Int8BytesRepresentation.self
      )
      try await self.database.write { db in
        let result = try #require(try query.fetchOne(db))
        expectNoDifference(result, FixedEmbeddingVector<4, Int8>([-128, 0, 63, 127]))
        expectNoDifference(
          try sliceQuery.fetchOne(db),
          FixedEmbeddingVector<2, Int8>([0, 63])
        )
        #expect(throws: VectorDecodingError.dimensionMismatch(expected: 3, actual: 2)) {
          try wrongDimensionQuery.fetchOne(db)
        }
        let record = FixedInt8Embedding(
          embedding: try FixedEmbeddingVector<8, Int8>(validating: Self.vector.queryOutput),
          label: "fixed"
        )
        let binding = FixedEmbeddingVector<8, Int8>
          .Int8BytesRepresentation(
            queryOutput: record.embedding
          )
        try FixedInt8Embedding.insert {
          ($0.embedding, $0.label)
        } values: {
          (
            Vec.int8(binding, as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self),
            record.label
          )
        }
        .execute(db)
        expectNoDifference(
          try FixedInt8Embedding.where { $0.label.eq("fixed") }.fetchOne(db),
          record
        )
      }
    }
  #endif
}

@Table("VecInt8Embeddings")
private struct VecInt8Embedding: Vec0 {
  @Column(as: [Int8].Int8BytesRepresentation.self)
  var embedding: [Int8]
  var label: String
}

#if swift(>=6.2)
  @Table("VecInt8Embeddings")
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  private struct FixedInt8Embedding: Hashable, Sendable, Vec0 {
    @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
    var embedding: FixedEmbeddingVector<8, Int8>
    var label: String
  }
#endif
