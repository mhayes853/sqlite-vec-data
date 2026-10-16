import StructuredQueriesCore

extension Vec {

  /// Preserves matching input and result dimensions.
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
  ///   ($0.label, Vec.int8($0.embedding, as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_int8("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecInt8Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vec_int8(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
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
  /// let query = Embedding.select {
  ///   ($0.label, Vec.int8($0.embedding, as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_int8("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecInt8Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_int8(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
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
  ///   ($0.label, Vec.int8($0.embedding, as: [Int8].Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_int8("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecInt8Encoding, T.Encoding: SQLiteVecInt8Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vec_int8(\(expression))")
  }

  /// Preserves the source vector type and its dimension count while attaching the SQLiteVec subtype.
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
  public static func int8<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<V>
  where V.Encoding: SQLiteVecInt8Encoding {
    Self.int8(expression, as: V.self)
  }

  /// Preserves a computed source's dimensions through its query representation.
  ///
  /// ```swift
  /// func tagged<V: VectorBytesRepresentable>(
  ///   _ expression: some QueryExpression<V>
  /// ) -> some QueryExpression<V.VectorBytesRepresentation>
  /// where V.Encoding: SQLiteVecInt8Encoding {
  ///   Vec.int8(expression)
  /// }
  /// let source: [Int8].Int8BytesRepresentation = [1, -2, 3]
  /// let expression = tagged(source)
  /// // vec_int8(?)
  /// ```
  @_disfavoredOverload
  public static func int8<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<V.VectorBytesRepresentation>
  where V.Encoding: SQLiteVecInt8Encoding {
    Self.int8(expression, as: V.VectorBytesRepresentation.self)
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
  ) -> some QueryExpression<T> where T.Encoding: SQLiteVecInt8Encoding {
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
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
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
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
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
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression(
      "CAST(vec_distance_l1(vec_int8(\(expression)), vec_int8(\(vector))) AS REAL)"
    )
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
  where V.Encoding: SQLiteVecInt8Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: end))"
    )
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
  where V.Encoding: SQLiteVecInt8Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound))"
    )
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
  where V.Encoding: SQLiteVecInt8Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound + 1))"
    )
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
  where V.Encoding: SQLiteVecInt8Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: start + length))"
    )
  }

}
