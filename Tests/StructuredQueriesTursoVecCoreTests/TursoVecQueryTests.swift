import CustomDump
import StructuredQueriesSQLite
import StructuredQueriesSQLiteVecCore
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `TursoVec Query tests` {
  @Test
  func `Inserts The Documented Float32 Embedding`() {
    // https://docs.turso.tech/sql-reference/functions/vector#vector32
    let query = Document.insert {
      ($0.id, $0.content, $0.embedding)
    } values: {
      (1, "Introduction to databases", TursoVec.vector32("[0.1, 0.3, 0.5, 0.7]"))
    }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      INSERT INTO "documents"
      ("id", "content", "embedding")
      VALUES
      (?1, ?2, vector32(?3))
      """
    )
    expectNoDifference(
      prepared.bindings,
      [.int(1), .text("Introduction to databases"), .text("[0.1, 0.3, 0.5, 0.7]")]
    )
  }

  @Test
  func `Creates Each Supported Turso Format`() {
    // https://docs.turso.tech/guides/vector-search#vector-types
    let json = "[0, 1, 0, 2]"
    let expressions = [
      TursoVec.vector(json).queryFragment,
      TursoVec.vector32(json).queryFragment,
      TursoVec.vector64(json).queryFragment,
      TursoVec.vector8(json).queryFragment,
      TursoVec.vector1bit(json).queryFragment,
      TursoVec.vector32Sparse(json).queryFragment
    ]
    expectNoDifference(
      expressions.map { $0.prepare { "?\($0)" }.sql },
      [
        "vector(?1)", "vector32(?1)", "vector64(?1)", "vector8(?1)", "vector1bit(?1)",
        "vector32_sparse(?1)"
      ]
    )
    expectNoDifference(
      expressions.map { $0.prepare { "?\($0)" }.bindings },
      Array(repeating: [QueryBinding.text(json)], count: expressions.count)
    )
  }

  @Test
  func `Computes The Documented Cosine And L2 Distances`() {
    // https://docs.turso.tech/sql-reference/functions/vector#vector-distance-cos
    // https://docs.turso.tech/sql-reference/functions/vector#vector-distance-l2
    let left = TursoVec.vector32("[1.0, 0.0, 0.0]")
    let right = TursoVec.vector32("[0.0, 1.0, 0.0]")
    let expressions = [
      TursoVec.distanceCosine(left, to: right).queryFragment,
      TursoVec.distanceL2(left, to: right).queryFragment
    ]
    expectNoDifference(
      expressions.map { $0.prepare { "?\($0)" }.sql },
      [
        "vector_distance_cos(vector32(?1), vector32(?2))",
        "vector_distance_l2(vector32(?1), vector32(?2))"
      ]
    )
    expectNoDifference(
      expressions.map { $0.prepare { "?\($0)" }.bindings },
      Array(repeating: [QueryBinding.text("[1.0, 0.0, 0.0]"), .text("[0.0, 1.0, 0.0]")], count: 2)
    )
  }

  @Test
  func `Orders Documents By The Documented Dot Distance`() {
    // https://docs.turso.tech/sql-reference/functions/vector#vector-distance-dot
    // Adapt the documented negative dot product example to a table query.
    let vector = TursoVec.vector32("[4.0, 5.0, 6.0]")
    let query =
      Document
      .order { TursoVec.distanceDot($0.embedding, to: vector).asc() }
      .limit(10)
      .select { ($0.content, TursoVec.distanceDot($0.embedding, to: vector)) }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT "documents"."content", vector_distance_dot("documents"."embedding", vector32(?1))
      FROM "documents"
      ORDER BY vector_distance_dot("documents"."embedding", vector32(?2)) ASC
      LIMIT ?3
      """
    )
    expectNoDifference(
      prepared.bindings,
      [.text("[4.0, 5.0, 6.0]"), .text("[4.0, 5.0, 6.0]"), .int(10)]
    )
  }

  @Test
  func `Compares Sparse Vectors With The Documented Jaccard Function`() {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/docs/manual.md#vector-search
    // The vector_distance_jaccard sparse-embedding example.
    let query = Formats.select {
      TursoVec.distanceJaccard($0.sparse, to: TursoVec.vector32Sparse("[0.0, 1.0, 0.0, 2.0]"))
    }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT vector_distance_jaccard("formats"."sparse", vector32_sparse(?1))
      FROM "formats"
      """
    )
    expectNoDifference(prepared.bindings, [.text("[0.0, 1.0, 0.0, 2.0]")])
  }

  @Test
  func `Compares Binary And Quantized Vectors Without JSON Overloads`() throws {
    // https://docs.turso.tech/sql-reference/functions/vector#distance-functions
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/distance_cos.rs#L40
    let bits: [Bool].TursoBytesRepresentation = [true, false]
    let quantized = try Quantized8Vector(quantizing: [1, 2])
    let doubles: [Double].VectorBytesRepresentation = [1, 2]
    let query = Formats.select {
      (
        TursoVec.distanceCosine($0.bits, to: bits),
        TursoVec.distanceJaccard($0.bits, to: bits),
        TursoVec.distanceDot($0.bits, to: bits),
        TursoVec.distanceL2($0.quantized, to: quantized),
        TursoVec.distanceCosine($0.doubles, to: TursoVec.vector64("[1,2]")),
        TursoVec.distanceDot($0.doubles, to: doubles)
      )
    }
    let prepared = query.query.prepare { "?\($0)" }
    expectNoDifference(
      prepared.sql,
      """
      SELECT vector_distance_cos("formats"."bits", ?1), vector_distance_jaccard("formats"."bits", ?2), vector_distance_dot("formats"."bits", ?3), vector_distance_l2("formats"."quantized", ?4), vector_distance_cos("formats"."doubles", vector64(?5)), vector_distance_dot("formats"."doubles", ?6)
      FROM "formats"
      """
    )
    expectNoDifference(
      prepared.bindings,
      [
        bits.queryBinding, bits.queryBinding, bits.queryBinding, quantized.queryBinding,
        .text("[1,2]"), doubles.queryBinding
      ]
    )
  }

  @Test
  func `Extracts The Documented Concatenation`() {
    // https://docs.turso.tech/sql-reference/functions/vector#vector-concat
    let expression = TursoVec.extract(
      TursoVec.concat(TursoVec.vector32("[1.0, 2.0]"), TursoVec.vector32("[3.0, 4.0]"))
    )
    let prepared = expression.queryFragment.prepare { "?\($0)" }
    expectNoDifference(prepared.sql, "vector_extract(vector_concat(vector32(?1), vector32(?2)))")
    expectNoDifference(prepared.bindings, [.text("[1.0, 2.0]"), .text("[3.0, 4.0]")])
  }

  @Test
  func `Extracts The Documented Slice`() {
    // https://docs.turso.tech/sql-reference/functions/vector#vector-slice
    let expression = TursoVec.extract(
      TursoVec.slice(TursoVec.vector32("[10.0, 20.0, 30.0, 40.0, 50.0]"), from: 1, to: 4)
    )
    let prepared = expression.queryFragment.prepare { "?\($0)" }
    expectNoDifference(prepared.sql, "vector_extract(vector_slice(vector32(?1), ?2, ?3))")
    expectNoDifference(
      prepared.bindings,
      [.text("[10.0, 20.0, 30.0, 40.0, 50.0]"), .int(1), .int(4)]
    )
  }

  @Test
  func `Preserves Double And Sparse Formats Through Utilities`() {
    // https://docs.turso.tech/sql-reference/functions/vector#utility-functions
    // Supported formats: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/slice.rs
    let double = TursoVec.slice(TursoVec.vector64("[1,2,3]"), from: 0, to: 2)
    let sparse = TursoVec.slice(TursoVec.vector32Sparse("[0,1,2,0]"), from: 1, to: 3)
    expectNoDifference(
      double.queryFragment.prepare { "?\($0)" }.sql,
      "vector_slice(vector64(?1), ?2, ?3)"
    )
    expectNoDifference(
      sparse.queryFragment.prepare { "?\($0)" }.sql,
      "vector_slice(vector32_sparse(?1), ?2, ?3)"
    )
  }

  @Test
  func `Shares Float Bytes With SQLiteVec Bindings`() {
    // https://docs.turso.tech/guides/vector-search#dense-vectors
    // Turso float32 stores four bytes per dimension with no format metadata.
    let vector: [Float].VectorBytesRepresentation = [1, 2, 3, 4]
    let turso = Document.select { TursoVec.distanceCosine($0.embedding, to: vector) }
    let sqliteVec = SQLiteEmbedding.select { $0.embedding.distanceCosine(to: vector) }
    let tursoPrepared = turso.query.prepare { "?\($0)" }
    let sqlitePrepared = sqliteVec.query.prepare { "?\($0)" }
    expectNoDifference(
      tursoPrepared.sql,
      """
      SELECT vector_distance_cos("documents"."embedding", ?1)
      FROM "documents"
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
    func `Uses Encoded Vector Values Directly In Columns`() throws {
      // https://docs.turso.tech/sql-reference/functions/vector#vector8
      // https://docs.turso.tech/sql-reference/functions/vector#vector32-sparse
      let quantized = try InlineQuantized8Vector<4>(codes: [1, 2, 3, 4], scale: 0.5, shift: 1)
      let sparse = try SizedSparseFloat32Vector<4>(indices: [1, 3], values: [2, 4])
      let query = SizedFormats.select {
        (
          TursoVec.distanceCosine($0.quantized, to: quantized),
          TursoVec.distanceL2($0.sparse, to: sparse),
          TursoVec.vector8("[1,2,3,4]", as: InlineQuantized8Vector<4>.self),
          TursoVec.slice($0.sparse, from: 1, to: 3, as: SizedSparseFloat32Vector<2>.self)
        )
      }
      let prepared = query.query.prepare { "?\($0)" }
      expectNoDifference(
        prepared.sql,
        """
        SELECT vector_distance_cos("sized_formats"."quantized", ?1), vector_distance_l2("sized_formats"."sparse", ?2), vector8(?3), vector_slice("sized_formats"."sparse", ?4, ?5)
        FROM "sized_formats"
        """
      )
      expectNoDifference(
        prepared.bindings,
        [quantized.queryBinding, sparse.queryBinding, .text("[1,2,3,4]"), .int(1), .int(3)]
      )
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Requests Fixed Dimensions After Concatenation And Slicing`() {
      // https://docs.turso.tech/sql-reference/functions/vector#utility-functions
      let left = EmbeddingVector<2>([1, 2])
      let right = EmbeddingVector<2>([3, 4])
      let joined = TursoVec.concat(left, right, as: EmbeddingVector<4>.self)
      let sliced = TursoVec.slice(joined, from: 1, to: 3, as: EmbeddingVector<2>.self)
      let prepared = sliced.queryFragment.prepare { "?\($0)" }
      expectNoDifference(prepared.sql, "vector_slice(vector_concat(?1, ?2), ?3, ?4)")
      expectNoDifference(
        prepared.bindings,
        [left.queryBinding, right.queryBinding, .int(1), .int(3)]
      )
      let sparse = TursoVec.vector32Sparse(
        "[0,1]",
        as: SizedSparseFloat32Vector<2>.self
      )
      expectNoDifference(sparse.queryFragment.prepare { "?\($0)" }.sql, "vector32_sparse(?1)")
    }
  #endif
}

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  @Table("sized_formats")
  private struct SizedFormats: Hashable, Sendable {
    var quantized: InlineQuantized8Vector<4>
    var sparse: SizedSparseFloat32Vector<4>
  }
#endif

@Table("documents")
private struct Document: Hashable, Sendable {
  var id: Int
  var content: String
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}

@Table("formats")
private struct Formats: Hashable, Sendable {
  @Column(as: [Double].VectorBytesRepresentation.self)
  var doubles: [Double]
  var quantized: Quantized8Vector
  @Column(as: [Bool].TursoBytesRepresentation.self)
  var bits: [Bool]
  var sparse: SparseFloat32Vector
}

@Table("sqlite_embeddings")
private struct SQLiteEmbedding: Hashable, Sendable, Vec0 {
  @Column(as: [Float].VectorBytesRepresentation.self)
  var embedding: [Float]
}
