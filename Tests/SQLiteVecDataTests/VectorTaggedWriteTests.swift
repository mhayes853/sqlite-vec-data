import CustomDump
import SQLiteVecData
import Testing

@Suite
struct `Tagged Vector Write tests` {
  private let database: DatabaseQueue

  init() async throws {
    var configuration = Configuration()
    configuration.prepareSQLiteVecExtension()
    self.database = try DatabaseQueue(configuration: configuration)
    try await self.database.write { db in
      try #sql(
        """
        CREATE VIRTUAL TABLE TaggedInt8Embeddings
        USING vec0(id integer primary key, embedding int8[4], label text)
        """,
        as: Void.self
      )
      .execute(db)
      try #sql(
        """
        CREATE VIRTUAL TABLE TaggedBitEmbeddings
        USING vec0(id integer primary key, embedding bit[8], label text)
        """,
        as: Void.self
      )
      .execute(db)
      try #sql(
        "CREATE TABLE OptionalInt8Vectors (id INTEGER PRIMARY KEY, embedding BLOB)",
        as: Void.self
      )
      .execute(db)
    }
  }

  @Test
  func `Bound Int8 Vectors Render With The Int8 Subtype`() {
    let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, 4]
    expectNoDifference(vector.queryFragment.prepare { _ in "?" }.sql, "vec_int8(?)")
    expectNoDifference(
      Vec.distanceL2(vector, to: vector).queryFragment.prepare { _ in "?" }.sql,
      "vec_distance_l2(vec_int8(?), vec_int8(?))"
    )
  }

  @Test
  func `Int8 Records Drafts And Values Write To Vec0`() async throws {
    expectNoDifference(
      Self.int8RecordInsert.query.prepare { _ in "?" }.sql,
      """
      INSERT INTO "TaggedInt8Embeddings"
      ("id", "embedding", "label")
      VALUES
      (?, vec_int8(?), ?)
      """
    )
    try await self.database.write { db in
      try Self.int8RecordInsert.execute(db)
      try TaggedInt8Embedding.insert {
        TaggedInt8Embedding.Draft(id: 2, embedding: [-128, 0, 0, 127], label: "draft")
      }
      .execute(db)
      try TaggedInt8Embedding.insert {
        ($0.id, $0.embedding, $0.label)
      } values: {
        (3, Self.int8Codes, "values")
      }
      .execute(db)
    }
    let rows = try await self.database.read { db in
      try TaggedInt8Embedding.order(by: \.id).fetchAll(db)
    }
    expectNoDifference(
      rows,
      [
        TaggedInt8Embedding(id: 1, embedding: [1, -2, 3, 4], label: "record"),
        TaggedInt8Embedding(id: 2, embedding: [-128, 0, 0, 127], label: "draft"),
        TaggedInt8Embedding(id: 3, embedding: [5, 6, 7, 8], label: "values")
      ]
    )
  }

  @Test
  func `Packed Bit Records Drafts And Values Write To Vec0`() async throws {
    expectNoDifference(
      Self.bitRecordInsert.query.prepare { _ in "?" }.sql,
      """
      INSERT INTO "TaggedBitEmbeddings"
      ("id", "embedding", "label")
      VALUES
      (?, vec_bit(?), ?)
      """
    )
    try await self.database.write { db in
      try Self.bitRecordInsert.execute(db)
      try TaggedBitEmbedding.insert {
        TaggedBitEmbedding.Draft(id: 2, embedding: Self.bits.reversed(), label: "draft")
      }
      .execute(db)
      try TaggedBitEmbedding.insert {
        ($0.id, $0.embedding, $0.label)
      } values: {
        (3, [Bool](repeating: true, count: 8), "values")
      }
      .execute(db)
    }
    let rows = try await self.database.read { db in
      try TaggedBitEmbedding.order(by: \.id).fetchAll(db)
    }
    expectNoDifference(
      rows,
      [
        TaggedBitEmbedding(id: 1, embedding: Self.bits, label: "record"),
        TaggedBitEmbedding(id: 2, embedding: Self.bits.reversed(), label: "draft"),
        TaggedBitEmbedding(id: 3, embedding: [Bool](repeating: true, count: 8), label: "values")
      ]
    )
  }

  @Test
  func `Updates Render Tagged Vectors That Vec0 Cannot Yet Accept`() async throws {
    let update = TaggedInt8Embedding.find(1).update { $0.embedding = #bind([4, 3, 2, 1]) }
    expectNoDifference(
      update.query.prepare { _ in "?" }.sql,
      """
      UPDATE "TaggedInt8Embeddings"
      SET "embedding" = vec_int8(?)
      WHERE (("TaggedInt8Embeddings"."id") IN ((?)))
      """
    )
    // SQLite drops subtypes before vec0 receives updated values, so sqlite-vec reads Int8 and bit
    // updates as Float32: https://github.com/asg017/sqlite-vec/issues/53
    try await self.database.write { db in
      try Self.int8RecordInsert.execute(db)
      #expect(throws: DatabaseError.self) {
        try TaggedInt8Embedding.find(1).update { $0.embedding = #bind([4, 3, 2, 1]) }.execute(db)
      }
    }
  }

  @Test
  func `Missing Optional Int8 Vectors Bind NULL Without A Subtype Call`() async throws {
    expectNoDifference(
      Self.optionalInsert.query.prepare { _ in "?" }.sql,
      """
      INSERT INTO "OptionalInt8Vectors"
      ("id", "embedding")
      VALUES
      (?, NULL), (?, vec_int8(?))
      """
    )
    try await self.database.write { db in
      try Self.optionalInsert.execute(db)
    }
    let rows = try await self.database.read { db in
      try OptionalInt8Vector.order(by: \.id).fetchAll(db)
    }
    expectNoDifference(
      rows,
      [OptionalInt8Vector(id: 1, embedding: nil), OptionalInt8Vector(id: 2, embedding: [1, 2])]
    )
  }

  @Test
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  func `Fixed Size Records Write To Vec0`() async throws {
    let int8Row = FixedTaggedInt8Embedding(
      id: 1,
      embedding: FixedEmbeddingVector([1, 2, 3, 4]),
      label: "a"
    )
    let bitRow = FixedTaggedBitEmbedding(
      id: 1,
      embedding: BinaryEmbeddingVector(repeating: true),
      label: "b"
    )
    try await self.database.write { db in
      try FixedTaggedInt8Embedding.insert { int8Row }.execute(db)
      try FixedTaggedBitEmbedding.insert { bitRow }.execute(db)
    }
    let fetchedInt8Row = try await self.database.read { db in
      try FixedTaggedInt8Embedding.find(1).fetchOne(db)
    }
    let fetchedBitRow = try await self.database.read { db in
      try FixedTaggedBitEmbedding.find(1).fetchOne(db)
    }
    expectNoDifference(fetchedInt8Row, int8Row)
    expectNoDifference(fetchedBitRow, bitRow)
  }

  private static let int8Codes: [Int8] = [5, 6, 7, 8]
  private static let bits: [Bool] = [true, false, true, false, false, false, false, true]

  private static var int8RecordInsert: Insert<TaggedInt8Embedding, ()> {
    TaggedInt8Embedding.insert {
      TaggedInt8Embedding(id: 1, embedding: [1, -2, 3, 4], label: "record")
    }
  }

  private static var bitRecordInsert: Insert<TaggedBitEmbedding, ()> {
    TaggedBitEmbedding.insert { TaggedBitEmbedding(id: 1, embedding: Self.bits, label: "record") }
  }

  private static var optionalInsert: Insert<OptionalInt8Vector, ()> {
    OptionalInt8Vector.insert {
      OptionalInt8Vector(id: 1, embedding: nil)
      OptionalInt8Vector(id: 2, embedding: [1, 2])
    }
  }
}

@Table("TaggedInt8Embeddings")
private struct TaggedInt8Embedding: Hashable, Sendable, Vec0 {
  let id: Int
  @Column(as: [Int8].Int8BytesRepresentation.self)
  var embedding: [Int8]
  var label: String
}

@Table("TaggedBitEmbeddings")
private struct TaggedBitEmbedding: Hashable, Sendable, Vec0 {
  let id: Int
  @Column(as: [Bool].PackedBitsRepresentation.self)
  var embedding: [Bool]
  var label: String
}

@Table("OptionalInt8Vectors")
private struct OptionalInt8Vector: Hashable, Sendable {
  let id: Int
  @Column(as: [Int8].Int8BytesRepresentation?.self)
  var embedding: [Int8]?
}

@Table("TaggedInt8Embeddings")
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private struct FixedTaggedInt8Embedding: Hashable, Sendable, Vec0 {
  let id: Int
  @Column(as: FixedEmbeddingVector<4, Int8>.Int8BytesRepresentation.self)
  var embedding: FixedEmbeddingVector<4, Int8>
  var label: String
}

@Table("TaggedBitEmbeddings")
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private struct FixedTaggedBitEmbedding: Hashable, Sendable, Vec0 {
  let id: Int
  @Column(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  var embedding: BinaryEmbeddingVector<8>
  var label: String
}
