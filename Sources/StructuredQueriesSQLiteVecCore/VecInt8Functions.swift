import StructuredQueriesCore

extension Vec {
  /// Marks a signed-byte blob with SQLiteVec's Int8 subtype.
  ///
  /// This reinterprets bytes, rather than numerically converting Float32 components. Use
  /// `quantizeInt8` for Float32 quantization. Blob subtypes do not survive storage or binding,
  /// so this helper is also needed when inserting into vec0 Int8 columns.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let insert = Embedding.insert { ($0.embedding, $0.label) } values: {
  ///   (Vec.int8(vector, as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self), "Signed embedding")
  /// }
  /// // INSERT INTO "Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)
  /// ```
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Int8].Int8BytesRepresentation, T.Encoding == V.Encoding {
    SQLQueryExpression("vec_int8(\(expression))")
  }

  /// Marks a signed-byte blob with SQLiteVec's Int8 subtype.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let insert = Embedding.insert { ($0.embedding, $0.label) } values: {
  ///   (Vec.int8(vector), "Signed embedding")
  /// }
  /// // INSERT INTO "Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)
  /// ```
  public static func int8<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.int8(expression, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Parses a JSON array of integers in [-128, 127] as a signed Int8 vector.
  ///
  /// SQLiteVec rejects noninteger and out-of-range elements. The result representation may
  /// additionally validate fixed dimensions when decoding.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<3, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<3, Int8>
  ///   var label: String
  /// }
  ///
  /// let insert = Embedding.insert { ($0.embedding, $0.label) } values: {
  ///   (Vec.int8(
  ///     "[1,-2,3]",
  ///     as: FixedEmbeddingVector<3, Int8>.Int8BytesRepresentation.self
  ///   ), "Signed embedding")
  /// }
  /// // INSERT INTO "Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)
  /// ```
  public static func int8<T: VectorBytesRepresentable & QueryBindable>(
    _ json: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_int8(\(json))")
  }

  /// Parses a JSON array of integers in [-128, 127] as a signed Int8 vector.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let insert = Embedding.insert { ($0.embedding, $0.label) } values: {
  ///   (Vec.int8("[1,-2,3]"), "Signed embedding")
  /// }
  /// // INSERT INTO "Embeddings" ("embedding", "label") VALUES (vec_int8(?), ?)
  /// ```
  public static func int8(
    _ json: some QueryExpression<String>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation> {
    Self.int8(json, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Matches a bound or computed Int8 query against a vec0 Int8 vector column.
  ///
  /// The left expression must refer to a vec0 vector column. A limit or `k` constraint is
  /// required, as with Float32 and binary matches.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  public static func match<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Bool>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression("(\(expression) MATCH vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func match<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Bool>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("(\(expression) MATCH vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func match<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Bool>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression("(\(expression) MATCH vec_int8(\(vector)))")
  }

  /// Returns the L1 distance between signed Int8 vectors with matching dimensions.
  /// SQLiteVec's Int8 subtype is applied to both expressions. SQLiteVec computes Int8 L1
  /// distances as integers, so the result is cast to `REAL` to match the other distances.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceL1($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", CAST(vec_distance_l1(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?)) AS REAL)
  /// // FROM "Embeddings"
  /// ```
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "CAST(vec_distance_l1(vec_int8(\(expression)), vec_int8(\(vector))) AS REAL)"
    )
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceL1($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", CAST(vec_distance_l1(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?)) AS REAL)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression(
      "CAST(vec_distance_l1(vec_int8(\(expression)), vec_int8(\(vector))) AS REAL)"
    )
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceL1($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", CAST(vec_distance_l1(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?)) AS REAL)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression(
      "CAST(vec_distance_l1(vec_int8(\(expression)), vec_int8(\(vector))) AS REAL)"
    )
  }

  /// Returns the L2 distance between signed Int8 vectors with matching dimensions.
  /// SQLiteVec's Int8 subtype is applied to both expressions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceL2($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public static func distanceL2<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression("vec_distance_l2(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceL2($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceL2<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_distance_l2(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceL2($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceL2<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression("vec_distance_l2(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Returns the cosine distance between signed Int8 vectors with matching dimensions.
  /// SQLiteVec's Int8 subtype is applied to both expressions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceCosine($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public static func distanceCosine<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression("vec_distance_cosine(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceCosine($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_distance_cosine(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.distanceCosine($0.embedding, to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression("vec_distance_cosine(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Returns the number of Int8 components.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.length($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_length(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public static func length<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<Int> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_length(vec_int8(\(expression)))")
  }

  /// Returns the SQLiteVec type string (`int8`).
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.type($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_type(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public static func type<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_type(vec_int8(\(expression)))")
  }

  /// Returns the signed Int8 components as JSON.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.toJSON($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_to_json(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public static func toJSON<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_to_json(vec_int8(\(expression)))")
  }

  /// Adds signed Int8 components, returning signed bytes with SQLiteVec's arithmetic semantics.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add(
  ///     $0.embedding,
  ///     queryVector,
  ///     as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression("vec_add(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add(
  ///     $0.embedding,
  ///     queryVector,
  ///     as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_add(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add(
  ///     $0.embedding,
  ///     queryVector,
  ///     as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression("vec_add(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Adds signed Int8 components, returning a signed-byte array representation.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    Self.add(expression, vector, as: V.self)
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<W>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    Self.add(expression, vector, as: W.self)
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    Self.add(expression, vector, as: V.self)
  }

  /// Subtracts signed Int8 components, returning signed bytes with SQLiteVec's arithmetic semantics.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub(
  ///     $0.embedding,
  ///     queryVector,
  ///     as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression("vec_sub(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub(
  ///     $0.embedding,
  ///     queryVector,
  ///     as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_sub(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub(
  ///     $0.embedding,
  ///     queryVector,
  ///     as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression("vec_sub(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Subtracts signed Int8 components, returning a signed-byte array representation.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    Self.sub(expression, vector, as: V.self)
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  ///   var label: String
  /// }
  ///
  /// let queryVector = FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<W>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    Self.sub(expression, vector, as: W.self)
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V>
  where
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    Self.sub(expression, vector, as: V.self)
  }

  /// Slices signed Int8 components, with an inclusive start and exclusive end.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     start: 1,
  ///     end: 3,
  ///     as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    start: Int,
    end: Int,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Int8].Int8BytesRepresentation, T.Encoding == V.Encoding {
    SQLQueryExpression("vec_slice(vec_int8(\(expression)), \(raw: start), \(raw: end))")
  }

  /// Slices signed Int8 components, with an inclusive start and exclusive end.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, start: 1, end: 3))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, start: start, end: end, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Slices signed Int8 components using a half-open range.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     range: 1..<3,
  ///     as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    range: Range<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Int8].Int8BytesRepresentation, T.Encoding == V.Encoding {
    Self.slice(expression, start: range.lowerBound, end: range.upperBound, as: result)
  }

  /// Slices signed Int8 components using a half-open range.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, range: 1..<3))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: Range<Int>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, range: range, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Slices signed Int8 components using a closed range.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     range: 1...2,
  ///     as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Int8].Int8BytesRepresentation, T.Encoding == V.Encoding {
    Self.slice(expression, start: range.lowerBound, end: range.upperBound + 1, as: result)
  }

  /// Slices signed Int8 components using a closed range.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, range: 1...2))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, range: range, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Slices signed Int8 components using a start index and component count.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     start: 1,
  ///     length: 2,
  ///     as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    start: Int,
    length: Int,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Int8].Int8BytesRepresentation, T.Encoding == V.Encoding {
    Self.slice(expression, start: start, end: start + length, as: result)
  }

  /// Slices signed Int8 components using a start index and component count.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, start: 1, length: 2))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, start: start, length: length, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Quantizes signed Int8 components by sign into packed bits. Dimensions must be divisible by eight.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeBinary(
  ///     $0.embedding,
  ///     as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public static func quantizeBinary<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Int8].Int8BytesRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    SQLQueryExpression("vec_quantize_binary(vec_int8(\(expression)))")
  }

  /// Quantizes signed Int8 components by sign into packed bits. Dimensions must be divisible by eight.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   var embedding: FixedEmbeddingVector<8, Int8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeBinary($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public static func quantizeBinary<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  }
}
