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
    let distance = missing.whenPresent { Vec.distanceL2($0, to: invalid) }
    let sum = missing.whenPresent { Vec.add(invalid, $0) }
    let difference = present.whenPresent(missing) { Vec.sub($0, $1) }
    let normalized = present.whenPresent { $0.normalize() }
    let count = missing.whenPresent { $0.length() }
    let format = missing.whenPresent { $0.type() }
    let json = missing.whenPresent { $0.toJSON() }
    let prefix = present.whenPresent { $0.slice(0..<1) }
    let query = #sql(
      "SELECT \(distance), \(sum), \(difference), \(normalized), \(count), \(format), \(json), \(prefix)",
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
      let stored = NullableStoredVector.select { $0.embedding.whenPresent { Vec.length($0) } }
      expectNoDifference(try stored.fetchAll(db), [nil, 2])
      let ranked =
        NullableStoredVector
        .where { $0.embedding.whenPresent(present) { Vec.distanceL2($0, to: $1) }.isNot(nil) }
        .select { $0.embedding.whenPresent(present) { Vec.distanceL2($0, to: $1) } }
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
      let malformed = #sql(
        "SELECT \(present.whenPresent { Vec.distanceL2($0, to: invalid) })",
        as: Double?.self
      )
      #expect(throws: DatabaseError.self) { try malformed.fetchOne(db) }
      let wrongCount: [Float].VectorBytesRepresentation? = [1]
      let mismatch = #sql(
        "SELECT \(present.whenPresent(wrongCount) { Vec.add($0, $1) })",
        as: [Float].VectorBytesRepresentation?.self
      )
      #expect(throws: DatabaseError.self) { try mismatch.fetchOne(db) }
    }
  }

  @Test
  func `Nullable Constructors And Int8 Subtypes Compose`() throws {
    let json: String? = "[3,4,0,0,0,0,0,0]"
    let missingJSON: String? = nil
    let vector = json.whenPresent { Vec.f32($0) }
    let bits = vector.whenPresent { Vec.bit(Vec.quantizeBinary($0)) }
    let codes: [Int8].Int8BytesRepresentation? = [3, 4, 0, 0, 0, 0, 0, 0]
    let floatDistance = vector.whenPresent(vector) { Vec.distanceL2($0, to: $1) }
    let intDistance = codes.whenPresent(codes) { Vec.distanceL1($0, to: $1) }
    let bitDistance = bits.whenPresent(bits) { Vec.distanceHamming($0, to: $1) }
    let missingFloats = missingJSON.whenPresent { Vec.f32($0) }
    let missingCodes = missingJSON.whenPresent { Vec.int8($0) }
    let taggedCodes = codes.whenPresent { Vec.int8($0) }
    let query = #sql(
      "SELECT \(floatDistance), \(intDistance), \(bitDistance), \(missingFloats), \(missingCodes), \(taggedCodes)",
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
  func `Generic Scalar Guards Handle Missing Inputs And Nullable Results`() throws {
    let numerator = SQLQueryExpression<Int?>("numerator")
    let denominator = SQLQueryExpression<Int?>("denominator")
    let doubled = numerator.whenPresent { SQLQueryExpression<Int>("(\($0) * 2)") }
    let sum = numerator.whenPresent(denominator) { SQLQueryExpression<Int>("(\($0) + \($1))") }
    let ratio = numerator.whenPresent(denominator) {
      SQLQueryExpression<Double?>("(CAST(\($0) AS REAL) / nullif(\($1), 0))")
    }
    let reciprocal = denominator.whenPresent {
      SQLQueryExpression<Double?>("(1.0 / nullif(\($0), 0))")
    }
    let query = #sql(
      "SELECT \(doubled), \(sum), \(ratio), \(reciprocal) FROM ratios ORDER BY rowid",
      as: (Int?, Int?, Double?, Double?).self
    )
    try self.database.write { db in
      try db.execute(sql: "CREATE TABLE ratios (numerator INTEGER, denominator INTEGER)")
      try db.execute(sql: "INSERT INTO ratios VALUES (8,2), (8,0), (8,NULL), (NULL,2), (NULL,NULL)")
      let rows = try query.fetchAll(db)
      expectNoDifference(rows.map(\.0), [16, 16, 16, nil, nil])
      expectNoDifference(rows.map(\.1), [10, 8, nil, nil, nil])
      expectNoDifference(rows.map(\.2), [4, nil, nil, nil, nil])
      expectNoDifference(rows.map(\.3), [0.5, nil, nil, 0.5, nil])
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
