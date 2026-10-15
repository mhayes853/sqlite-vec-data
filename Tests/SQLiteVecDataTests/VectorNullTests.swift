import CustomDump
import SQLiteVecData
import Testing

@Suite
struct `Vector NULL tests` {
  private let database: DatabaseQueue

  init() throws {
    var configuration = Configuration()
    configuration.prepareSQLiteVecExtension()
    self.database = try DatabaseQueue(configuration: configuration)
  }

  @Test
  func `Undefined Floating Distances Decode As NULL`() throws {
    // SQLite's result_double maps NaN to NULL; zero-norm cosine also explicitly returns NULL.
    // https://github.com/asg017/sqlite-vec/blob/e9f598abfa0c06b328d8fe5da9c3760cce74be10/sqlite-vec.c
    let zero: [Float].VectorBytesRepresentation = [0, 0]
    let nan: [Float].VectorBytesRepresentation = [.nan, 1]
    let codes: [Int8].Int8BytesRepresentation = [0, 0]
    let query = #sql(
      "SELECT \(Vec.distanceCosine(zero, to: zero)), \(Vec.distanceL1(nan, to: zero)), \(Vec.distanceL2(nan, to: zero)), \(Vec.distanceCosine(codes, to: codes)), \(Vec.distanceL2(codes, to: codes)), \(Vec.distanceL1(codes, to: codes)), \(Vec.distanceCosine(zero, to: zero).ifnull(2))",
      as: (Double?, Double?, Double?, Double?, Double, Double, Double).self
    )
    // Ensure integer distances retain their nonnullable static type, not merely SQL storage class.
    requireNonnullableDistance(Vec.distanceL1(codes, to: codes))
    requireNonnullableDistance(Vec.distanceL2(codes, to: codes))
    try self.database.read { db in
      let row = try #require(try query.fetchOne(db))
      expectNoDifference(row.0, nil)
      expectNoDifference(row.1, nil)
      expectNoDifference(row.2, nil)
      expectNoDifference(row.3, nil)
      expectNoDifference(row.4, 0)
      expectNoDifference(row.5, 0)
      expectNoDifference(row.6, 2)
    }
  }

  @Test
  func `Optional Inputs Short Circuit Native Functions And Preserve Errors`() throws {
    let missing: [Float].VectorBytesRepresentation? = nil
    let present: [Float].VectorBytesRepresentation? = [3, 4]
    let invalid = SQLQueryExpression<[Float].VectorBytesRepresentation>("x'01'")
    let query = #sql(
      "SELECT \(Vec.distanceL2(missing, to: invalid)), \(Vec.add(invalid, missing)), \(Vec.sub(missing, present)), \(present.normalize()), \(missing.length()), \(missing.type()), \(missing.toJSON()), \(present.slice(0..<1))",
      as: (
        Double?, [Float].VectorBytesRepresentation?, [Float].VectorBytesRepresentation?,
        [Float].VectorBytesRepresentation?, Int?, String?, String?,
        [Float].VectorBytesRepresentation?
      )
      .self
    )
    try self.database.write { db in
      try db.execute(sql: "CREATE TABLE nullable_vectors (embedding BLOB)")
      try db.execute(sql: "INSERT INTO nullable_vectors VALUES (NULL), (vec_f32('[3,4]'))")
      let stored = NullableStoredVector.select { Vec.length($0.embedding) }
      expectNoDifference(try stored.fetchAll(db), [nil, 2])
      let ranked =
        NullableStoredVector
        .where { Vec.distanceL2($0.embedding, to: present).isNot(nil) }
        .select { Vec.distanceL2($0.embedding, to: present) }
      expectNoDifference(try ranked.fetchAll(db), [0])
      let row = try #require(try query.fetchOne(db))
      expectNoDifference(row.0, nil)
      expectNoDifference(row.1, nil)
      expectNoDifference(row.2, nil)
      let normalized = try #require(row.3)
      expectNoDifference(normalized, [0.6, 0.8])
      expectNoDifference(row.4, nil)
      expectNoDifference(row.5, nil)
      expectNoDifference(row.6, nil)
      expectNoDifference(row.7, [3])
      let malformed = #sql("SELECT \(Vec.distanceL2(present, to: invalid))", as: Double?.self)
      #expect(throws: DatabaseError.self) { try malformed.fetchOne(db) }
      let wrongCount: [Float].VectorBytesRepresentation? = [1]
      let mismatch = #sql(
        "SELECT \(Vec.add(present, wrongCount))",
        as: [Float].VectorBytesRepresentation?.self
      )
      #expect(throws: DatabaseError.self) { try mismatch.fetchOne(db) }
    }
  }

  @Test
  func `Nullable Constructors And Int8 Subtypes Compose`() throws {
    let json: String? = "[3,4,0,0,0,0,0,0]"
    let missingJSON: String? = nil
    let vector = Vec.f32(json)
    let bits = Vec.bit(Vec.quantizeBinary(vector))
    let codes: [Int8].Int8BytesRepresentation? = [3, 4, 0, 0, 0, 0, 0, 0]
    let query = #sql(
      "SELECT \(Vec.distanceL2(vector, to: vector)), \(Vec.distanceL1(codes, to: codes)), \(Vec.distanceHamming(bits, to: bits)), \(Vec.f32(missingJSON)), \(Vec.int8(missingJSON)), \(Vec.int8(codes))",
      as: (
        Double?, Double?, Double?, [Float].VectorBytesRepresentation?,
        [Int8].Int8BytesRepresentation?, [Int8].Int8BytesRepresentation?
      )
      .self
    )
    try self.database.read { db in
      let row = try #require(try query.fetchOne(db))
      expectNoDifference(row.0, 0)
      expectNoDifference(row.1, 0)
      expectNoDifference(row.2, 0)
      expectNoDifference(row.3, nil)
      expectNoDifference(row.4, nil)
      expectNoDifference(row.5, codes?.queryOutput)
    }
  }

  @Test
  func `Hidden Columns And Float Iteration Preserve Missing Results`() throws {
    // vec0Column emits NULL for k and for distance outside KNN. vec_each emits NaN via result_double.
    // https://github.com/asg017/sqlite-vec/blob/e9f598abfa0c06b328d8fe5da9c3760cce74be10/sqlite-vec.c
    let vector: [Float].VectorBytesRepresentation = [1, 0, 0]
    let scan = NullEmbedding.select { ($0.k, $0.distance) }
    let nearest =
      NullEmbedding
      .where { $0.embedding.match(vector) && $0.k.eq(1) }
      .select { ($0.k, $0.distance) }
    let components: [Float].VectorBytesRepresentation = [1, .nan, -2]
    let iteration = Vec.each(components).order { $0.rowid }.select { ($0.rowid, $0.value) }
    try self.database.write { db in
      try db.execute(sql: "CREATE VIRTUAL TABLE null_embeddings USING vec0(embedding float[3])")
      try db.execute(sql: "INSERT INTO null_embeddings(embedding) VALUES ('[1,0,0]')")
      let scanned = try #require(try scan.fetchOne(db))
      expectNoDifference(scanned.0, nil)
      expectNoDifference(scanned.1, nil)
      let matched = try #require(try nearest.fetchOne(db))
      expectNoDifference(matched.0, nil)
      expectNoDifference(matched.1, 0)
      let rows = try iteration.fetchAll(db)
      expectNoDifference(rows.map(\.0), [0, 1, 2])
      expectNoDifference(rows.map(\.1), [1, nil, -2])
    }
  }

  @Test
  func `Optional Representations Distinguish NULL From Corrupt Bytes And NaN`() throws {
    let nan: [Float].VectorBytesRepresentation? = [.nan, 1]
    let missing: [Float].VectorBytesRepresentation? = nil
    let query = #sql(
      "SELECT \(nan), \(missing)",
      as: ([Float].VectorBytesRepresentation?, [Float].VectorBytesRepresentation?).self
    )
    let corrupt = #sql("SELECT x'01'", as: [Float].VectorBytesRepresentation?.self)
    try self.database.read { db in
      let row = try #require(try query.fetchOne(db))
      let value = try #require(row.0)
      expectNoDifference(value[0].isNaN, true)
      expectNoDifference(value.vectorBytes, nan?.vectorBytes)
      expectNoDifference(row.1, nil)
      #expect(throws: VectorDecodingError.invalidBytes) { try corrupt.fetchOne(db) }
    }
  }
}

private func requireNonnullableDistance(_ expression: some QueryExpression<Double>) {}

@Table("null_embeddings")
private struct NullEmbedding: Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

@Table("nullable_vectors")
private struct NullableStoredVector {
  @Column(as: [Float].VectorBytesRepresentation?.self)
  var embedding: [Float]?
}
