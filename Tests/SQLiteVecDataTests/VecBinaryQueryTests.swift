import CustomDump
import SQLiteVecData
import SQLiteVecDataTestSupport
import Testing

@Suite
struct `Vec Binary Query tests` {
  private let database: DatabaseQueue

  init() async throws {
    var configuration = Configuration()
    try configuration.prepareSQLiteVec()
    self.database = try DatabaseQueue(configuration: configuration)
    try await self.database.write { db in
      try #sql(
        "CREATE VIRTUAL TABLE VecBinaryEmbeddings USING vec0(embedding bit[16], label text)",
        as: Void.self
      )
      .execute(db)
      let near = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
      let exact = try [Bool].PackedBitsRepresentation(vectorBytes: [0x05, 0x01])
      try VecBinaryEmbedding.insert {
        ($0.embedding, $0.label)
      } values: {
        (Vec.bit(near), "near")
        (Vec.bit(exact), "exact")
      }
      .execute(db)
    }
  }

  @Test
  func `Binary Match And Scalar Hamming Agree`() async throws {
    let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x05, 0x01])
    let match =
      VecBinaryEmbedding
      .where { $0.embedding.match(Vec.slice(vector, range: 0..<16)) }
      .order { $0.distance }
      .limit(2)
      .select { ($0.label, $0.distance) }
    let freeformMatch =
      VecBinaryEmbedding
      .where { Vec.match($0.embedding, to: vector) }
      .order { $0.distance }
      .limit(2)
      .select { ($0.label, $0.distance) }
    let preparedMatch = match.query.prepare { "?\($0)" }
    expectNoDifference(
      preparedMatch.sql,
      """
      SELECT "VecBinaryEmbeddings"."label", "VecBinaryEmbeddings"."distance"
      FROM "VecBinaryEmbeddings"
      WHERE (("VecBinaryEmbeddings"."embedding" MATCH vec_bit(vec_slice(vec_bit(?1), 0, 16))))
      ORDER BY "VecBinaryEmbeddings"."distance"
      LIMIT ?2
      """
    )
    let scalar =
      VecBinaryEmbedding
      .order { $0.embedding.distanceHamming(to: vector) }
      .select { ($0.label, $0.embedding.distanceHamming(to: vector)) }
    let prepared = scalar.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT "VecBinaryEmbeddings"."label", vec_distance_hamming(vec_bit("VecBinaryEmbeddings"."embedding"), vec_bit(?1))
      FROM "VecBinaryEmbeddings"
      ORDER BY vec_distance_hamming(vec_bit("VecBinaryEmbeddings"."embedding"), vec_bit(?2))
      """
    )
    try await self.database.read { db in
      let matchRows = try match.fetchAll(db)
      let freeformRows = try freeformMatch.fetchAll(db)
      let scalarRows = try scalar.fetchAll(db)
      expectNoDifference(matchRows.map(\.0), ["exact", "near"])
      expectNoDifference(matchRows.map(\.1), [0, 3])
      expectNoDifference(freeformRows.map(\.0), matchRows.map(\.0))
      expectNoDifference(freeformRows.map(\.1), matchRows.map(\.1))
      expectNoDifference(scalarRows.map(\.0), matchRows.map(\.0))
      expectNoDifference(scalarRows.map(\.1), matchRows.map(\.1))
    }
  }

  @Test
  func `Binary Inspection And Slicing Preserve The Encoding`() async throws {
    let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
    let query = #sql(
      """
      SELECT \(Vec.length(vector)), \(Vec.type(vector)), \(Vec.toJSON(vector)),
        \(Vec.slice(vector, range: 8..<16))
      """,
      as: (Int, String, String, [Bool].PackedBitsRepresentation).self
    )
    try await self.database.read { db in
      let result = try #require(try query.fetchOne(db))
      expectNoDifference(result.0, 16)
      expectNoDifference(result.1, "bit")
      expectNoDifference(result.2, "[1,0,1,0,0,0,0,1,0,1,0,0,0,0,0,0]")
      expectNoDifference(result.3, [false, true, false, false, false, false, false, false])
      // SQLiteVec rejects slicing through a byte, rather than silently losing logical bits.
      #expect(throws: Error.self) {
        try #sql(
          "SELECT \(Vec.slice(vector, range: 1..<8))",
          as: [Bool].PackedBitsRepresentation.self
        )
        .fetchOne(db)
      }
    }
  }

  @Test
  func `Binary Scalar Results Use Their Declared Storage Classes`() async throws {
    // GRDB widens INTEGER results to Double, so check the storage class SQLite reports.
    let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
    let other = try [Bool].PackedBitsRepresentation(vectorBytes: [0x05, 0x01])
    let query = #sql(
      """
      SELECT typeof(\(Vec.distanceHamming(vector, to: other))), typeof(\(Vec.length(vector)))
      """,
      as: (String, String).self
    )
    let columnQuery =
      VecBinaryEmbedding
      .where { $0.label.eq("near") }
      .select {
        (
          #sql("typeof(\($0.embedding.distanceHamming(to: other)))", as: String.self),
          #sql("typeof(\($0.embedding.length()))", as: String.self)
        )
      }
    let eachTypes = Vec.each(vector).select { #sql("typeof(\($0.value))", as: String.self) }
    try await self.database.read { db in
      let result = try #require(try query.fetchOne(db))
      expectNoDifference(result.0, "real")
      expectNoDifference(result.1, "integer")
      let columnResult = try #require(try columnQuery.fetchOne(db))
      expectNoDifference(columnResult.0, "real")
      expectNoDifference(columnResult.1, "integer")
      expectNoDifference(Set(try eachTypes.fetchAll(db)), ["integer"])
    }
  }

  @Test
  func `Binary Iteration Uses SQLiteVec Bit Order`() async throws {
    let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85])
    let query = Vec.each(vector).order { $0.rowid }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(prepared.bindings, [.blob([0x85])])
    try await self.database.read { db in
      let rows = try query.fetchAll(db)
      expectNoDifference(rows.map(\.rowid), Array(0..<8))
      // vec_each visits bits most significant first; packed storage indexes least significant first.
      expectNoDifference(rows.map(\.value), [true, false, false, false, false, true, false, true])
    }
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Quantized Binary Expressions Compose With Fixed Packed Results`() async throws {
      let dense = EmbeddingVector<8>([1, -1, 1, 0, -1, -1, -1, 1])
      let binary = BinaryEmbeddingVector<8>
        .PackedBitsRepresentation(
          queryOutput: BinaryEmbeddingVector<8>(quantizing: dense)
        )
      let sliced = Vec.slice(
        Vec.quantizeBinary(dense),
        range: 0...7,
        as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
      )
      let distance = Vec.distanceHamming(sliced, to: binary)
      let prepared = distance.queryFragment.prepare { "?\($0)" }
      expectNoDifference(
        prepared.sql,
        "vec_distance_hamming(vec_bit(vec_slice(vec_bit(vec_quantize_binary(?1)), 0, 8)), vec_bit(?2))"
      )
      let distanceQuery = #sql("SELECT \(distance)", as: Double.self)
      let sliceQuery = #sql(
        "SELECT \(sliced)",
        as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
      )
      try await self.database.read { db in
        expectNoDifference(try distanceQuery.fetchOne(db), 0)
        expectNoDifference(try sliceQuery.fetchOne(db), binary.queryOutput)
      }
    }
  #endif
}

@Table("VecBinaryEmbeddings")
private struct VecBinaryEmbedding: Vec0 {
  @Column(as: [Bool].PackedBitsRepresentation.self)
  var embedding: [Bool]
  var label: String
}
