import CustomDump
import SQLiteVecData
import Testing

@Suite("FloatArrayVectorBytesRepresentation tests")
struct FloatArrayVectorBytesRepresentationTests {
  private let database = try! DatabaseQueue()

  init() throws {
    try self.database.write { db in
      try db.loadSQLiteVecExtension()
      try #sql(
        """
        CREATE VIRTUAL TABLE TestEmbeddings USING vec0(
          embeddings float[8]
        );
        """,
        as: Void.self
      )
      .execute(db)
    }
  }

  #if swift(>=6.2)
    @Test("Converts Inline Array To And From Bytes")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func convertInlineArrayToAndFromBytes() async throws {
      try await self.database.write { db in
        let record = TestInlineEmbeddingRecord(embeddings: [1, 2, 3, 4, 5, 6, 7, 8])
        let insertedRecord = try TestInlineEmbeddingRecord.insert { record }
          .returning { $0 }
          .fetchOne(db)
        expectElementsAreEqual(record.embeddings, try #require(insertedRecord).embeddings)
      }
    }

    @Test("Throws Error When Bytes Are Too Large For Inline Array")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func throwsErrorWhenBytesAreTooLargeForInlineArray() async throws {
      try await self.database.write { db in
        let record = TestInlineEmbeddingRecord(embeddings: [1, 2, 3, 4, 5, 6, 7, 8])
        try TestInlineEmbeddingRecord.insert { record }.execute(db)
        #expect(throws: Error.self) {
          try #sql(
            "SELECT embeddings FROM TestEmbeddings",
            as: [4 of Float].VectorBytesRepresentation.self
          )
          .fetchOne(db)
        }
      }
    }

    @Test("Throws Error When Bytes Are Too Short For Inline Array")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func throwsErrorWhenBytesAreTooShortForInlineArray() async throws {
      try await self.database.write { db in
        let record = TestInlineEmbeddingRecord(embeddings: [1, 2, 3, 4, 5, 6, 7, 8])
        try TestInlineEmbeddingRecord.insert { record }.execute(db)
        #expect(throws: Error.self) {
          try #sql(
            "SELECT embeddings FROM TestEmbeddings",
            as: [16 of Float].VectorBytesRepresentation.self
          )
          .fetchOne(db)
        }
      }
    }

    @Test("Converts Embedding Vector To And From Bytes")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func convertEmbeddingVectorToAndFromBytes() async throws {
      try await self.database.write { db in
        let record = TestEmbeddingVectorRecord(
          embeddings: EmbeddingVector([1, 2, 3, 4, 5, 6, 7, 8])
        )
        let insertedRecord = try TestEmbeddingVectorRecord.insert { record }
          .returning { $0 }
          .fetchOne(db)
        expectNoDifference(record, insertedRecord)
      }
    }

    @Test("Throws Error When Bytes Are Too Large For Embedding Vector")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func throwsErrorWhenBytesAreTooLargeForEmbeddingVector() async throws {
      try await self.database.write { db in
        let record = TestEmbeddingVectorRecord(
          embeddings: EmbeddingVector([1, 2, 3, 4, 5, 6, 7, 8])
        )
        try TestEmbeddingVectorRecord.insert { record }.execute(db)
        #expect(throws: Error.self) {
          try #sql(
            "SELECT embeddings FROM TestEmbeddings",
            as: EmbeddingVector<4>.self
          )
          .fetchOne(db)
        }
      }
    }

    @Test("Throws Error When Bytes Are Too Short For Embedding Vector")
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func throwsErrorWhenBytesAreTooShortForEmbeddingVector() async throws {
      try await self.database.write { db in
        let record = TestEmbeddingVectorRecord(
          embeddings: EmbeddingVector([1, 2, 3, 4, 5, 6, 7, 8])
        )
        try TestEmbeddingVectorRecord.insert { record }.execute(db)
        #expect(throws: Error.self) {
          try #sql(
            "SELECT embeddings FROM TestEmbeddings",
            as: EmbeddingVector<16>.self
          )
          .fetchOne(db)
        }
      }
    }
  #endif

  @Test("Converts Float Array To And From Bytes")
  func convertFloatArrayToAndFromBytes() async throws {
    try await self.database.write { db in
      let record = TestEmbeddingRecord(embeddings: [1, 2, 3, 4, 5, 6, 7, 8])
      let insertedRecord = try TestEmbeddingRecord.insert { record }
        .returning { $0 }
        .fetchOne(db)
      expectNoDifference(record, insertedRecord)
    }
  }
}

@Table("TestEmbeddings")
private struct TestEmbeddingRecord: Hashable, Sendable, Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embeddings: [Float]
}

#if swift(>=6.2)
  @Table("TestEmbeddings")
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  private struct TestInlineEmbeddingRecord: Vec0 {
    @Column(as: [8 of Float].VectorBytesRepresentation.self)
    var embeddings: [8 of Float]
  }

  @Table("TestEmbeddings")
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  private struct TestEmbeddingVectorRecord: Hashable, Vec0 {
    var embeddings: EmbeddingVector<8>
  }
#endif
