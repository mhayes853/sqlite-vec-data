import CustomDump
import StructuredQueriesSQLite
import StructuredQueriesSQLiteVecCore
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `LibSQLVec Query tests` {
  @Test
  func `Inserts A Documented Float32 Vector`() {
    // https://docs.turso.tech/features/ai-and-embeddings#vectors-usage
    // The Napoleon row in "Generate and insert embeddings".
    let embedding = LibSQLVec.vector32("[0.800, 0.579, 0.481, 0.229]")
    let query = Movie.insert {
      ($0.title, $0.year, $0.embedding)
    } values: {
      ("Napoleon", 2023, embedding)
    }
    let prepared = query.query.prepare { "?\($0)" }

    expectNoDifference(
      prepared.sql,
      """
      INSERT INTO "movies"
      ("title", "year", "embedding")
      VALUES
      (?1, ?2, vector32(?3))
      """
    )
    expectNoDifference(
      prepared.bindings,
      [.text("Napoleon"), .int(2023), .text("[0.800, 0.579, 0.481, 0.229]")]
    )
  }

  @Test
  func `Extracts Vectors And Orders By Cosine Distance`() {
    // https://docs.turso.tech/features/ai-and-embeddings#vectors-usage
    // "Perform a vector similarity search", ordered by the distance expression rather than an alias.
    let vector = LibSQLVec.vector32("[0.064, 0.777, 0.661, 0.687]")
    let query =
      Movie
      .order { LibSQLVec.distanceCosine($0.embedding, to: vector).asc() }
      .select {
        (
          $0.title, LibSQLVec.extract($0.embedding),
          LibSQLVec.distanceCosine($0.embedding, to: vector)
        )
      }
    let prepared = query.query.prepare { "?\($0)" }

    expectNoDifference(
      prepared.sql,
      """
      SELECT "movies"."title", vector_extract("movies"."embedding"), vector_distance_cos("movies"."embedding", vector32(?1))
      FROM "movies"
      ORDER BY vector_distance_cos("movies"."embedding", vector32(?2)) ASC
      """
    )
    expectNoDifference(
      prepared.bindings,
      [.text("[0.064, 0.777, 0.661, 0.687]"), .text("[0.064, 0.777, 0.661, 0.687]")]
    )
  }

  @Test
  func `Computes Documented Distances From JSON And Columns`() {
    // https://docs.turso.tech/features/ai-and-embeddings#functions
    // https://docs.turso.tech/features/ai-and-embeddings#understanding-distance-results
    let cosine = LibSQLVec.distanceCosine(
      LibSQLVec.vector32("[1000]"),
      to: LibSQLVec.vector32("[1000]")
    )
    let prepared = cosine.queryFragment.prepare { "?\($0)" }
    expectNoDifference(prepared.sql, "vector_distance_cos(vector32(?1), vector32(?2))")
    expectNoDifference(prepared.bindings, [.text("[1000]"), .text("[1000]")])

    let distance = Movie.select {
      LibSQLVec.distanceL2($0.embedding, to: LibSQLVec.vector32("[0.064, 0.777, 0.661, 0.687]"))
    }
    expectNoDifference(
      distance.query.prepare { "?\($0)" }.sql,
      """
      SELECT vector_distance_l2("movies"."embedding", vector32(?1))
      FROM "movies"
      """
    )

    let columns = Movie.select { LibSQLVec.distanceL2($0.embedding, to: $0.embedding) }
    expectNoDifference(
      columns.query.prepare { "?\($0)" }.sql,
      """
      SELECT vector_distance_l2("movies"."embedding", "movies"."embedding")
      FROM "movies"
      """
    )
  }

  @Test
  func `Converts Each Documented Vector Format`() {
    // https://docs.turso.tech/features/ai-and-embeddings#functions
    // Conversion variants from the functions table, using the insertion example's vector.
    let json = "[0.800, 0.579, 0.481, 0.229]"
    let expressions = [
      LibSQLVec.vector(json).queryFragment,
      LibSQLVec.vector32(json).queryFragment,
      LibSQLVec.vector64(json).queryFragment,
      LibSQLVec.vector16(json).queryFragment,
      LibSQLVec.vectorb16(json).queryFragment,
      LibSQLVec.vector8(json).queryFragment,
      LibSQLVec.vector1bit(json).queryFragment
    ]
    expectNoDifference(
      expressions.map { $0.prepare { "?\($0)" }.sql },
      [
        "vector(?1)", "vector32(?1)", "vector64(?1)", "vector16(?1)", "vectorb16(?1)",
        "vector8(?1)", "vector1bit(?1)"
      ]
    )
    expectNoDifference(
      expressions.map { $0.prepare { "?\($0)" }.bindings },
      Array(repeating: [QueryBinding.text(json)], count: expressions.count)
    )
  }

  @Test
  func `Converts Compressed Vectors To Float32`() {
    // https://docs.turso.tech/features/ai-and-embeddings#functions
    // Conversion functions accept both JSON strings and encoded blobs.
    let expression = LibSQLVec.extract(
      LibSQLVec.vector32(LibSQLVec.vector8("[0.800, 0.579, 0.481, 0.229]"))
    )
    let prepared = expression.queryFragment.prepare { "?\($0)" }
    expectNoDifference(prepared.sql, "vector_extract(vector32(vector8(?1)))")
    expectNoDifference(prepared.bindings, [.text("[0.800, 0.579, 0.481, 0.229]")])
  }

  @Test
  func `Inserts Vectors Into Columns With Matching Format Representations`() {
    // https://docs.turso.tech/features/ai-and-embeddings#functions
    // Apply the insertion example to columns using each documented non-float32 encoding.
    let json = "[0.800, 0.579, 0.481, 0.229]"
    let query = EncodedMovie.insert {
      ($0.float64, $0.float16, $0.bfloat16, $0.float8, $0.bit)
    } values: {
      (
        LibSQLVec.vector64(json), LibSQLVec.vector16(json), LibSQLVec.vectorb16(json),
        LibSQLVec.vector8(json), LibSQLVec.vector1bit(json)
      )
    }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      INSERT INTO "encoded_movies"
      ("float64", "float16", "bfloat16", "float8", "bit")
      VALUES
      (vector64(?1), vector16(?2), vectorb16(?3), vector8(?4), vector1bit(?5))
      """
    )
    expectNoDifference(prepared.bindings, Array(repeating: QueryBinding.text(json), count: 5))
  }

  @Test
  func `Compares Matching Encodings With Numeric Bindings`() {
    // https://docs.turso.tech/features/ai-and-embeddings#functions
    // Apply the documented distance functions to the numeric precision representations.
    let double: [Double].VectorBytesRepresentation = [1, 2]
    let bfloat: [Float].BFloat16Representation = [1, 2]
    let float8: [Float].Float8Representation = [1, 2]
    let binary: [Bool].TursoBytesRepresentation = [true, false]
    let query = EncodedMovie.select {
      (
        LibSQLVec.distanceL2($0.float64, to: double),
        LibSQLVec.distanceCosine($0.bfloat16, to: bfloat),
        LibSQLVec.distanceL2($0.float8, to: float8), LibSQLVec.distanceCosine($0.bit, to: binary)
      )
    }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT vector_distance_l2("encoded_movies"."float64", ?1), vector_distance_cos("encoded_movies"."bfloat16", ?2), vector_distance_l2("encoded_movies"."float8", ?3), vector_distance_cos("encoded_movies"."bit", ?4)
      FROM "encoded_movies"
      """
    )
    expectNoDifference(
      prepared.bindings,
      [double.queryBinding, bfloat.queryBinding, float8.queryBinding, binary.queryBinding]
    )
  }

  @Test
  func `Extracts Binary Vectors And Creates A LibSQL Binary Index`() {
    // https://docs.turso.tech/features/ai-and-embeddings#functions
    // https://docs.turso.tech/features/ai-and-embeddings#vector-index
    let query = EncodedMovie.select {
      (
        LibSQLVec.extract($0.bit),
        LibSQLVec.distanceCosine($0.bit, to: LibSQLVec.vector1bit("[1,-1,1,-1]"))
      )
    }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT vector_extract("encoded_movies"."bit"), vector_distance_cos("encoded_movies"."bit", vector1bit(?1))
      FROM "encoded_movies"
      """
    )
    expectNoDifference(prepared.bindings, [.text("[1,-1,1,-1]")])
    let marker = LibSQLVec.index(EncodedMovie.columns.bit)
    expectNoDifference(marker.queryFragment.prepare { "?\($0)" }.sql, "libsql_vector_idx(\"bit\")")
    let vector: [Bool].TursoBytesRepresentation = [true, false, true, false]
    expectNoDifference(
      LibSQLVec.distanceCosine(LibSQLVec.vector1bit("[1,-1,1,-1]"), to: vector).queryFragment
        .prepare { "?\($0)" }.sql,
      "vector_distance_cos(vector1bit(?1), ?2)"
    )
  }

  @Test
  func `Creates A Documented Vector Index`() {
    // https://docs.turso.tech/features/ai-and-embeddings#vector-index
    let expression = LibSQLVec.index(Movie.columns.embedding)
    let query = #sql("CREATE INDEX movies_idx ON movies (\(expression))", as: Void.self)
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      "CREATE INDEX movies_idx ON movies (libsql_vector_idx(\"embedding\"))"
    )
    expectNoDifference(prepared.bindings, [])
  }

  @Test
  func `Creates A Documented Index With Settings`() {
    // https://docs.turso.tech/features/ai-and-embeddings#settings
    let expression = LibSQLVec.index(
      Movie.columns.embedding,
      settings: ["metric=l2", "compress_neighbors=float8"]
    )
    let query = #sql("CREATE INDEX movies_idx ON movies (\(expression))", as: Void.self)
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      "CREATE INDEX movies_idx ON movies (libsql_vector_idx(\"embedding\", 'metric=l2', 'compress_neighbors=float8'))"
    )
    expectNoDifference(prepared.bindings, [])
  }

  @Test
  func `Escapes Index Settings As SQL Literals`() {
    // https://docs.turso.tech/features/ai-and-embeddings#settings
    // Extend the documented variadic settings example with an adversarial string.
    let expression = LibSQLVec.index(
      Movie.columns.embedding,
      settings: ["metric=l2'); DROP TABLE movies;--"]
    )
    expectNoDifference(
      expression.queryFragment.prepare { "?\($0)" }.sql,
      "libsql_vector_idx(\"embedding\", 'metric=l2''); DROP TABLE movies;--')"
    )
  }

  @Test
  func `Joins The Documented Top K Table Function`() {
    // https://docs.turso.tech/features/ai-and-embeddings#index-usage
    // "Query the indexed table".
    let neighbors = LibSQLVec.topK(
      index: "movies_idx",
      vector: LibSQLVec.vector32("[0.064, 0.777, 0.661, 0.687]"),
      k: 3
    )
    let query = #sql(
      """
      SELECT title, year
      FROM \(neighbors.tableFragment)
      JOIN movies ON movies.rowid = id
      WHERE year >= 2020
      """,
      as: (String, Int).self
    )
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT title, year
      FROM vector_top_k(?1, vector32(?2), ?3)
      JOIN movies ON movies.rowid = id
      WHERE year >= 2020
      """
    )
    expectNoDifference(
      prepared.bindings,
      [.text("movies_idx"), .text("[0.064, 0.777, 0.661, 0.687]"), .int(3)]
    )
  }

  @Test
  func `Filters With A Structured Top K Subquery`() {
    // https://docs.turso.tech/features/ai-and-embeddings#index-usage
    // Equivalent to the documented join, using an IN subquery to select the returned row IDs.
    let neighbors = LibSQLVec.topK(
      index: "movies_idx",
      vector: LibSQLVec.vector32("[0.064, 0.777, 0.661, 0.687]"),
      k: 3
    )
    let query =
      Movie
      .where { $0.rowid.in(neighbors) && $0.year.gte(2020) }
      .select { ($0.title, $0.year) }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT "movies"."title", "movies"."year"
      FROM "movies"
      WHERE ((("movies"."rowid") IN ((SELECT "id" FROM vector_top_k(?1, vector32(?2), ?3)))) AND (("movies"."year") >= (?4)))
      """
    )
    expectNoDifference(
      prepared.bindings,
      [.text("movies_idx"), .text("[0.064, 0.777, 0.661, 0.687]"), .int(3), .int(2020)]
    )
  }

  @Test
  func `Binds Top K Arguments And Supports Text Primary Keys`() {
    // https://docs.turso.tech/features/ai-and-embeddings#query
    // The index can return a single primary key for WITHOUT ROWID tables. Its output is named
    // "id" even though the indexed table uses "catalog_key".
    let indexName = "movies_idx'); DROP TABLE movies;--"
    let neighbors = LibSQLVec.topK(index: indexName, vector: "[1,2,3,4]", k: 3, as: String.self)
    let query = TextMovie.where { $0.catalogKey.in(neighbors) }.select(\.catalogKey)
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT "text_movies"."catalog_key"
      FROM "text_movies"
      WHERE (("text_movies"."catalog_key") IN ((SELECT "id" FROM vector_top_k(?1, ?2, ?3))))
      """
    )
    expectNoDifference(prepared.bindings, [.text(indexName), .text("[1,2,3,4]"), .int(3)])
  }

  @Test
  func `Shares Float Bytes With SQLiteVec Bindings`() {
    // https://docs.turso.tech/features/ai-and-embeddings#types
    // F32_BLOB stores four bytes per dimension with no format metadata.
    let vector: [Float].VectorBytesRepresentation = [1, 2, 3, 4]
    let turso = Movie.select { LibSQLVec.distanceCosine($0.embedding, to: vector) }
    let sqliteVec = SQLiteEmbedding.select { $0.embedding.distanceCosine(to: vector) }
    let tursoPrepared = turso.query.prepare { "?\($0)" }
    let sqlitePrepared = sqliteVec.query.prepare { "?\($0)" }
    expectNoDifference(
      tursoPrepared.sql,
      """
      SELECT vector_distance_cos("movies"."embedding", ?1)
      FROM "movies"
      """
    )
    expectNoDifference(
      sqlitePrepared.sql,
      """
      SELECT vec_distance_cosine("sqlite_embeddings"."embedding", ?1)
      FROM "sqlite_embeddings"
      """
    )
    expectNoDifference(tursoPrepared.bindings, sqlitePrepared.bindings)
    expectNoDifference(tursoPrepared.bindings, [vector.queryBinding])
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Inserts Each Precision Into Fixed Size Vector Columns`() {
      // https://docs.turso.tech/features/ai-and-embeddings#functions
      let json = "[0.800, 0.579, 0.481, 0.229]"
      let query = FixedMovie.insert {
        ($0.float32, $0.float64, $0.float16, $0.bfloat16, $0.float8, $0.bit)
      } values: {
        (
          LibSQLVec.vector32(json, as: EmbeddingVector<4>.self),
          LibSQLVec.vector64(json, as: EmbeddingVector64<4>.VectorBytesRepresentation.self),
          LibSQLVec.vector16(json, as: EmbeddingVector16<4>.VectorBytesRepresentation.self),
          LibSQLVec.vectorb16(json, as: EmbeddingVector<4>.BFloat16Representation.self),
          LibSQLVec.vector8(json, as: EmbeddingVector<4>.Float8Representation.self),
          LibSQLVec.vector1bit(json, as: BinaryEmbeddingVector<4>.TursoBytesRepresentation.self)
        )
      }
      let prepared = query.query.prepare { "?\($0)" }
      expectNoDifference(
        prepared.sql,
        """
        INSERT INTO "fixed_movies"
        ("float32", "float64", "float16", "bfloat16", "float8", "bit")
        VALUES
        (vector32(?1), vector64(?2), vector16(?3), vectorb16(?4), vector8(?5), vector1bit(?6))
        """
      )
      expectNoDifference(prepared.bindings, Array(repeating: QueryBinding.text(json), count: 6))
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Uses Shared Fixed Size Vector Representations`() {
      // https://docs.turso.tech/features/ai-and-embeddings#types
      // F32_BLOB uses the shared little-endian float32 byte representation.
      let vector = EmbeddingVector<4>([1, 2, 3, 4])
      let inlineVector = [4 of Float].VectorBytesRepresentation(queryOutput: [1, 2, 3, 4])
      let expression = LibSQLVec.vector32(vector, as: EmbeddingVector<4>.self)
      let prepared = expression.queryFragment.prepare { "?\($0)" }
      expectNoDifference(prepared.sql, "vector32(?1)")
      expectNoDifference(prepared.bindings, [inlineVector.queryBinding])
    }
  #endif
}

@Table("movies")
private struct Movie: Hashable, Sendable {
  var title: String
  var year: Int
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

@Table("text_movies")
private struct TextMovie: Hashable, Sendable {
  @Column("catalog_key", primaryKey: true)
  var catalogKey: String
}

@Table("encoded_movies")
private struct EncodedMovie: Hashable, Sendable {
  @Column(as: [Double].VectorBytesRepresentation.self)
  var float64: [Double]
  @Column(as: [Float16].VectorBytesRepresentation.self)
  var float16: [Float16]
  @Column(as: [Float].BFloat16Representation.self)
  var bfloat16: [Float]
  @Column(as: [Float].Float8Representation.self)
  var float8: [Float]
  @Column(as: [Bool].TursoBytesRepresentation.self)
  var bit: [Bool]
}

@Table("sqlite_embeddings")
private struct SQLiteEmbedding: Hashable, Sendable, Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

#if swift(>=6.2)
  @Table("fixed_movies")
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  private struct FixedMovie: Hashable, Sendable {
    var float32: EmbeddingVector<4>
    @Column(as: EmbeddingVector64<4>.VectorBytesRepresentation.self)
    var float64: EmbeddingVector64<4>
    @Column(as: EmbeddingVector16<4>.VectorBytesRepresentation.self)
    var float16: EmbeddingVector16<4>
    @Column(as: EmbeddingVector<4>.BFloat16Representation.self)
    var bfloat16: EmbeddingVector<4>
    @Column(as: EmbeddingVector<4>.Float8Representation.self)
    var float8: EmbeddingVector<4>
    @Column(as: BinaryEmbeddingVector<4>.TursoBytesRepresentation.self)
    var bit: BinaryEmbeddingVector<4>
  }
#endif
