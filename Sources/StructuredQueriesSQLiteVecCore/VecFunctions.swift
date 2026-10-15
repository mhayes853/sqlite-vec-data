import StructuredQueriesCore

/// A namespace for SQLiteVec SQL functions.
///
/// Helpers accept float32, signed Int8, or raw packed-bit encodings according to the operation.
/// Turso's float64, quantized, sparse, and metadata-bearing binary encodings are not supported.
/// Int8 and packed-bit scalar operations apply `vec_int8` and `vec_bit` so SQLiteVec interprets
/// bound blobs correctly.
///
/// ```swift
/// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
/// @Table("Embeddings")
/// struct Embedding: Vec0 {
///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
///   var embedding: EmbeddingVector<8>
///   var label: String
/// }
///
/// let dimensions = Embedding.select { ($0.label, Vec.length($0.embedding)) }
/// // SELECT "Embeddings"."label", vec_length("Embeddings"."embedding")
/// // FROM "Embeddings"
/// ```
/// Float32 distances and cosine may yield SQL NULL for undefined numerical results. Int8 L1/L2
/// and Hamming are nonnullable. Nullable scalar-function inputs propagate NULL through a CASE
/// expression; malformed vectors and dimension mismatches still produce errors.
/// Use `.isNot(nil)` to filter scores, or `.ifnull(...)` with a deliberate fallback.
public enum Vec {
  /// Matches a query vector expression against a vec0 column with the same encoding.
  ///
  /// The left expression must refer to a vec0 vector column. SQLiteVec enforces the KNN query's
  /// limit or `k` constraint. The query vector can be a bound value or a computed expression.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH ?))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<16>.PackedBitsRepresentation(queryOutput: BinaryEmbeddingVector<16>(repeating: false))
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_bit(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
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
    V.Encoding: SQLiteVecVectorEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "(\(expression) MATCH \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH ?))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Bool].PackedBitsRepresentation.self)
  ///   var embedding: [Bool]
  ///   var label: String
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<16>.PackedBitsRepresentation(queryOutput: BinaryEmbeddingVector<16>(repeating: false))
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_bit(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
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
    V.Encoding: SQLiteVecVectorEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression(
      "(\(expression) MATCH \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 8))
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH ?))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Bool].PackedBitsRepresentation(queryOutput: [Bool](repeating: false, count: 16))
  /// let neighbors = Embedding
  ///   .where { Vec.match($0.embedding, to: queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_bit(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
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
    V.Encoding: SQLiteVecVectorEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression(
      "(\(expression) MATCH \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Returns the L2 distance between a vector expression and a bound or computed vector expression.
  /// This calls sqlite-vec's `vec_distance_l2` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.distanceL2($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_l2("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the L2 distance.
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
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_distance_l2(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.distanceL2($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_l2("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_l2(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 3))
  /// let query = Embedding.select {
  ///   Vec.distanceL2($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_l2("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_l2(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Returns the L1 distance between a vector expression and a bound or computed vector expression.
  /// This calls sqlite-vec's `vec_distance_l1` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.distanceL1($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_l1("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the L1 distance.
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression("vec_distance_l1(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.distanceL1($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_l1("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_distance_l1(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 3))
  /// let query = Embedding.select {
  ///   Vec.distanceL1($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_l1("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression("vec_distance_l1(\(expression), \(vector))")
  }

  /// Returns the cosine distance between a vector expression and a bound or computed vector expression.
  /// This calls sqlite-vec's `vec_distance_cosine` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.distanceCosine($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_cosine("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the cosine distance.
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
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_distance_cosine(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.distanceCosine($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_cosine("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_cosine(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 3))
  /// let query = Embedding.select {
  ///   Vec.distanceCosine($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_cosine("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_cosine(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Returns the Hamming distance between a vector expression and a bound or computed vector expression.
  /// This calls sqlite-vec's `vec_distance_hamming` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE BinaryEmbeddings USING vec0(embedding bit[8], label text);
  /// @Table("BinaryEmbeddings")
  /// struct BinaryEmbedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<8>.PackedBitsRepresentation(queryOutput: BinaryEmbeddingVector<8>(repeating: false))
  /// let query = BinaryEmbedding.select {
  ///   Vec.distanceHamming($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_hamming(vec_bit("BinaryEmbeddings"."embedding"), vec_bit(?))
  /// // FROM "BinaryEmbeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the Hamming distance.
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_distance_hamming(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE BinaryEmbeddings USING vec0(embedding bit[8], label text);
  /// @Table("BinaryEmbeddings")
  /// struct BinaryEmbedding: Vec0 {
  ///   @Column(as: [Bool].PackedBitsRepresentation.self)
  ///   var embedding: [Bool]
  ///   var label: String
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<8>.PackedBitsRepresentation(queryOutput: BinaryEmbeddingVector<8>(repeating: false))
  /// let query = BinaryEmbedding.select {
  ///   Vec.distanceHamming($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_hamming(vec_bit("BinaryEmbeddings"."embedding"), vec_bit(?))
  /// // FROM "BinaryEmbeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_hamming(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE BinaryEmbeddings USING vec0(embedding bit[8], label text);
  /// @Table("BinaryEmbeddings")
  /// struct BinaryEmbedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Bool].PackedBitsRepresentation(queryOutput: [Bool](repeating: false, count: 8))
  /// let query = BinaryEmbedding.select {
  ///   Vec.distanceHamming($0.embedding, to: queryVector)
  /// }
  /// // SELECT vec_distance_hamming(vec_bit("BinaryEmbeddings"."embedding"), vec_bit(?))
  /// // FROM "BinaryEmbeddings"
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_hamming(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Returns the length of a vector expression.
  /// This calls sqlite-vec's `vec_length` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.length($0.embedding)
  /// }
  /// // SELECT vec_length("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameter expression: The vector expression to measure.
  /// - Returns: A query expression for the vector length.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.length($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_length(vec_bit("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
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
  ) -> some QueryExpression<Int> where V.Encoding: SQLiteVecVectorEncoding {
    SQLQueryExpression("vec_length(\(V.Encoding.sqliteVecExpression(expression.queryFragment)))")
  }

  /// Returns the sqlite-vec type string for a vector expression.
  /// This calls sqlite-vec's `vec_type` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.type($0.embedding)
  /// }
  /// // SELECT vec_type("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameter expression: The vector expression to inspect.
  /// - Returns: A query expression for the type string.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.type($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_type(vec_bit("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
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
  ) -> some QueryExpression<String> where V.Encoding: SQLiteVecVectorEncoding {
    SQLQueryExpression("vec_type(\(V.Encoding.sqliteVecExpression(expression.queryFragment)))")
  }

  /// Returns a JSON string for a vector expression.
  /// This calls sqlite-vec's `vec_to_json` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.toJSON($0.embedding)
  /// }
  /// // SELECT vec_to_json("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameter expression: The vector expression to serialize.
  /// - Returns: A query expression for the JSON string.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.toJSON($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_to_json(vec_bit("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
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
  ) -> some QueryExpression<String> where V.Encoding: SQLiteVecVectorEncoding {
    SQLQueryExpression("vec_to_json(\(V.Encoding.sqliteVecExpression(expression.queryFragment)))")
  }

  /// Preserves compatible operand and result dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    SQLQueryExpression(
      "vec_add(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_add(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    SQLQueryExpression(
      "vec_add(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  /// let queryVector = FixedEmbeddingVector<8, Int8>
  ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: [Int8].Int8BytesRepresentation.self))
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_add(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   (
  ///     $0.label,
  ///     Vec.add(
  ///       $0.embedding,
  ///       queryVector,
  ///       as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///     )
  ///   )
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_add(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  /// let queryVector = FixedEmbeddingVector<8, Int8>
  ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: [Int8].Int8BytesRepresentation.self))
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_add(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  ///   ($0.label, Vec.add($0.embedding, queryVector, as: [Int8].Int8BytesRepresentation.self))
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_add(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Adds matching numerical vectors while preserving known dimensions.
  /// This calls sqlite-vec's `vec_add` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.add($0.embedding, queryVector)
  /// }
  /// // SELECT vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to add to.
  ///   - vector: The query vector to add.
  /// - Returns: A query expression for the summed vector.
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    Self.add(expression, vector, as: V.self)
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.add($0.embedding, queryVector)
  /// }
  /// // SELECT vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    Self.add(expression, vector, as: W.self)
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 3))
  /// let query = Embedding.select {
  ///   Vec.add($0.embedding, queryVector)
  /// }
  /// // SELECT vec_add("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    Self.add(expression, vector, as: V.self)
  }

  /// Preserves compatible operand and result dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    SQLQueryExpression(
      "vec_sub(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_sub(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    SQLQueryExpression(
      "vec_sub(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  /// let queryVector = FixedEmbeddingVector<8, Int8>
  ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: [Int8].Int8BytesRepresentation.self))
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_sub(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  /// let queryVector = [Int8].Int8BytesRepresentation(queryOutput: [Int8](repeating: 2, count: 8))
  /// let query = Embedding.select {
  ///   (
  ///     $0.label,
  ///     Vec.sub(
  ///       $0.embedding,
  ///       queryVector,
  ///       as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///     )
  ///   )
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_sub(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<8>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  /// let queryVector = FixedEmbeddingVector<8, Int8>
  ///   .Int8BytesRepresentation(queryOutput: FixedEmbeddingVector<8, Int8>(repeating: 2))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: [Int8].Int8BytesRepresentation.self))
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_sub(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Checks every known operand and result count; runtime-sized values are validated by SQLiteVec.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 8))
  /// let query = Embedding.select {
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
  ///   ($0.label, Vec.sub($0.embedding, queryVector, as: [Int8].Int8BytesRepresentation.self))
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_sub(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Subtracts matching numerical vectors while preserving known dimensions.
  /// This calls sqlite-vec's `vec_sub` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.sub($0.embedding, queryVector)
  /// }
  /// // SELECT vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to subtract from.
  ///   - vector: The query vector to subtract.
  /// - Returns: A query expression for the difference vector.
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    Self.sub(expression, vector, as: V.self)
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>(repeating: 0.25)
  /// let query = Embedding.select {
  ///   Vec.sub($0.embedding, queryVector)
  /// }
  /// // SELECT vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    Self.sub(expression, vector, as: W.self)
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [Float](repeating: 0.25, count: 3))
  /// let query = Embedding.select {
  ///   Vec.sub($0.embedding, queryVector)
  /// }
  /// // SELECT vec_sub("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
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
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    Self.sub(expression, vector, as: V.self)
  }

  /// Extracts a slice from a vector expression using a start index and exclusive end index.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, end: 2, as: EmbeddingVector<2>.self)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - start: The start index.
  ///   - end: The exclusive end index.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     start: 0,
  ///     end: 8,
  ///     as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
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
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: end))"
    )
  }

  /// Extracts a slice from a vector expression using a start index and exclusive end index.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, end: 2)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - start: The start index.
  ///   - end: The exclusive end index.
  /// - Returns: A query expression for the sliced vector.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding: SQLiteVecFloat32Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: end))"
    )
  }

  /// Extracts a slice from a vector expression using a half-open range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0..<2, as: EmbeddingVector<2>.self)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - range: The half-open range to extract.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     range: 0..<8,
  ///     as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
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
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound))"
    )
  }

  /// Extracts a slice from a vector expression using a half-open range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0..<2)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - range: The half-open range to extract.
  /// - Returns: A query expression for the sliced vector.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: Range<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding: SQLiteVecFloat32Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound))"
    )
  }

  /// Extracts a slice from a vector expression using a closed range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0...1, as: EmbeddingVector<2>.self)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - range: The closed range to extract.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     range: 0...7,
  ///     as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
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
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound + 1))"
    )
  }

  /// Extracts a slice from a vector expression using a closed range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0...1)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - range: The closed range to extract.
  /// - Returns: A query expression for the sliced vector.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding: SQLiteVecFloat32Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound + 1))"
    )
  }

  /// Extracts a slice from a vector expression using a start index and length.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, length: 2, as: EmbeddingVector<2>.self)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - start: The start index.
  ///   - length: The number of elements to extract.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice(
  ///     $0.embedding,
  ///     start: 0,
  ///     length: 8,
  ///     as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
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
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: start + length))"
    )
  }

  /// Extracts a slice from a vector expression using a start index and length.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, length: 2)
  /// }
  /// // SELECT vec_slice("Embeddings"."embedding", 0, 2)
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - start: The start index.
  ///   - length: The number of elements to extract.
  /// - Returns: A query expression for the sliced vector.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding: SQLiteVecFloat32Encoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: start + length))"
    )
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.normalize($0.embedding, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_normalize("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public static func normalize<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vec_normalize(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.normalize($0.embedding, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_normalize("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func normalize<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_normalize(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.normalize($0.embedding, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_normalize("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func normalize<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vec_normalize(\(expression))")
  }

  /// Normalizes a vector expression and returns the result as a float vector.
  /// This calls sqlite-vec's `vec_normalize` function.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.normalize($0.embedding)
  /// }
  /// // SELECT vec_normalize("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameter expression: The vector expression to normalize.
  /// - Returns: A query expression for the normalized vector.
  public static func normalize<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<V>
  where
    V.Encoding: SQLiteVecFloat32Encoding
  {
    Self.normalize(expression, as: V.self)
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.f32($0.embedding, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_f32("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public static func f32<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vec_f32(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.f32($0.embedding, as: EmbeddingVector<8>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_f32("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func f32<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_f32(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.f32($0.embedding, as: [Float].VectorBytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_f32("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func f32<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vec_f32(\(expression))")
  }

  /// Preserves the source vector type and its dimension count while attaching the SQLiteVec subtype.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<3>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   Vec.f32($0.embedding)
  /// }
  /// // SELECT vec_f32("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameter expression: The vector expression to convert.
  /// - Returns: A query expression for the converted vector.
  public static func f32<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<V>
  where V.Encoding: SQLiteVecFloat32Encoding {
    Self.f32(expression, as: V.self)
  }

  /// Preserves a computed source's dimensions through its query representation.
  ///
  /// ```swift
  /// func tagged<V: VectorBytesRepresentable>(
  ///   _ expression: some QueryExpression<V>
  /// ) -> some QueryExpression<V.VectorBytesRepresentation>
  /// where V.Encoding: SQLiteVecFloat32Encoding {
  ///   Vec.f32(expression)
  /// }
  /// let source: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let expression = tagged(source)
  /// // vec_f32(?)
  /// ```
  @_disfavoredOverload
  public static func f32<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<V.VectorBytesRepresentation>
  where V.Encoding: SQLiteVecFloat32Encoding {
    Self.f32(expression, as: V.VectorBytesRepresentation.self)
  }

  /// Parses a JSON array of numbers as a Float32 vector.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let insert = Embedding.insert { ($0.embedding, $0.label) } values: {
  ///   (Vec.f32("[0.1, 0.2, 0.3]"), "Introduction to databases")
  /// }
  /// // INSERT INTO "Embeddings" ("embedding", "label") VALUES (vec_f32(?), ?)
  /// ```
  public static func f32(
    _ json: some QueryExpression<String>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    Self.f32(json, as: [Float].VectorBytesRepresentation.self)
  }

  /// Parses JSON as Float32, validating the requested dimensions when decoding.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[3], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   var embedding: EmbeddingVector<3>
  ///   var label: String
  /// }
  ///
  /// let insert = Embedding.insert { ($0.embedding, $0.label) } values: {
  ///   (Vec.f32("[0.1, 0.2, 0.3]", as: EmbeddingVector<3>.self), "Introduction to databases")
  /// }
  /// // INSERT INTO "Embeddings" ("embedding", "label") VALUES (vec_f32(?), ?)
  /// ```
  public static func f32<T: VectorBytesRepresentable & QueryBindable>(
    _ json: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding: SQLiteVecFloat32Encoding {
    SQLQueryExpression("vec_f32(\(json))")
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeInt8(
  ///     $0.embedding,
  ///     as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  public static func quantizeInt8<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vec_quantize_int8(\(expression), 'unit')")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   (
  ///     $0.label,
  ///     Vec.quantizeInt8($0.embedding, as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   )
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func quantizeInt8<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_quantize_int8(\(expression), 'unit')")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeInt8($0.embedding, as: [Int8].Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func quantizeInt8<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecFloat32Encoding, T.Encoding: SQLiteVecInt8Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vec_quantize_int8(\(expression), 'unit')")
  }
  /// Converts a fixed-size vector while preserving its logical dimension count.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeInt8($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// // The result retains eight logical dimensions.
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func quantizeInt8<let count: Int, V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == VectorDimensions<count>
  {
    Self.quantizeInt8(
      expression,
      as: FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation.self
    )
  }
  /// Quantizes Float32 components in [-1, 1] to signed Int8 codes, clamping out-of-range values.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select { $0.embedding.quantizeInt8() }
  /// // SELECT vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  /// The result contains codes, not reconstructed Float32 components. SQLiteVec supports only
  /// the `unit` quantization mode; this helper does not normalize the input.
  public static func quantizeInt8<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == Void
  {
    Self.quantizeInt8(expression, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeBinary(
  ///     $0.embedding, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
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
  where
    V.Encoding: SQLiteVecNumericEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression(
      "vec_quantize_binary(\(V.Encoding.sqliteVecExpression(expression.queryFragment)))"
    )
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   (
  ///     $0.label,
  ///     Vec.quantizeBinary($0.embedding, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   )
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
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
  ///   (
  ///     $0.label,
  ///     Vec.quantizeBinary($0.embedding, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   )
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func quantizeBinary<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecNumericEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_quantize_binary(\(V.Encoding.sqliteVecExpression(expression.queryFragment)))"
    )
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeBinary($0.embedding, as: [Bool].PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
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
  ///   ($0.label, Vec.quantizeBinary($0.embedding, as: [Bool].PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func quantizeBinary<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecNumericEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_quantize_binary(\(V.Encoding.sqliteVecExpression(expression.queryFragment)))"
    )
  }
  /// Converts a fixed-size vector while preserving its logical dimension count.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeBinary($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// // The result retains eight logical dimensions.
  /// ```
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
  /// // The result retains eight logical dimensions.
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func quantizeBinary<let count: Int, V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<BinaryEmbeddingVector<count>.PackedBitsRepresentation>
  where
    V.Encoding: SQLiteVecNumericEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    Self.quantizeBinary(
      expression,
      as: BinaryEmbeddingVector<count>.PackedBitsRepresentation.self
    )
  }
  /// Quantizes a vector expression to a binary representation and returns logical bits.
  /// This calls sqlite-vec's `vec_quantize_binary` function. Dimensions must be divisible by eight.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.quantizeBinary($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  ///
  /// - Parameter expression: The vector expression to quantize.
  /// - Returns: A query expression for the quantized vector.
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
  ///   ($0.label, Vec.quantizeBinary($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public static func quantizeBinary<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where
    V.Encoding: SQLiteVecNumericEncoding,
    V.Dimensions == Void
  {
    Self.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  }
  // MARK: - Packed Bits

  /// Slices packed bits. The start and end indices must be divisible by eight.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, start: 0, end: 8))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding: SQLiteVecBinaryEncoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: end))"
    )
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, range: 0..<8))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: Range<Int>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding: SQLiteVecBinaryEncoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound))"
    )
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, range: 0...7))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding: SQLiteVecBinaryEncoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: range.lowerBound), \(raw: range.upperBound + 1))"
    )
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.slice($0.embedding, start: 0, length: 8))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding: SQLiteVecBinaryEncoding {
    SQLQueryExpression(
      "vec_slice(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(raw: start), \(raw: start + length))"
    )
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.bit($0.embedding, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecBinaryEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vec_bit(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Bool].PackedBitsRepresentation.self)
  ///   var embedding: [Bool]
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.bit($0.embedding, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecBinaryEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vec_bit(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[8], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<8>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.bit($0.embedding, as: [Bool].PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: SQLiteVecBinaryEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vec_bit(\(expression))")
  }

  /// Preserves the source vector type and its dimension count while attaching the SQLiteVec subtype.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16], label text);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<16>
  ///   var label: String
  /// }
  ///
  /// let query = Embedding.select {
  ///   ($0.label, Vec.bit($0.embedding))
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public static func bit<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<V>
  where V.Encoding: SQLiteVecBinaryEncoding {
    Self.bit(expression, as: V.self)
  }

  /// Preserves a computed source's dimensions through its query representation.
  ///
  /// ```swift
  /// func tagged<V: VectorBytesRepresentable>(
  ///   _ expression: some QueryExpression<V>
  /// ) -> some QueryExpression<V.VectorBytesRepresentation>
  /// where V.Encoding: SQLiteVecBinaryEncoding {
  ///   Vec.bit(expression)
  /// }
  /// let source: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
  /// let expression = tagged(source)
  /// // vec_bit(?)
  /// ```
  @_disfavoredOverload
  public static func bit<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<V.VectorBytesRepresentation>
  where V.Encoding: SQLiteVecBinaryEncoding {
    Self.bit(expression, as: V.VectorBytesRepresentation.self)
  }
}

// MARK: - Signed Int8 L2

extension Vec {
  /// Returns the nonnullable L2 distance between signed Int8 vectors.
  ///
  /// ```swift
  /// let left: [Int8].Int8BytesRepresentation = [3, 4]
  /// let right: [Int8].Int8BytesRepresentation = [0, 0]
  /// let distance = Vec.distanceL2(left, to: right)
  /// // vec_distance_l2(vec_int8(?), vec_int8(?))
  /// ```
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    SQLQueryExpression(
      "vec_distance_l2(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Returns the nonnullable L2 distance between signed Int8 vectors.
  ///
  /// ```swift
  /// let left: [Int8].Int8BytesRepresentation = [3, 4]
  /// let right: [Int8].Int8BytesRepresentation = [0, 0]
  /// let distance = Vec.distanceL2(left, to: right)
  /// // vec_distance_l2(vec_int8(?), vec_int8(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_l2(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }

  /// Returns the nonnullable L2 distance between signed Int8 vectors.
  ///
  /// ```swift
  /// let left: [Int8].Int8BytesRepresentation = [3, 4]
  /// let right: [Int8].Int8BytesRepresentation = [0, 0]
  /// let distance = Vec.distanceL2(left, to: right)
  /// // vec_distance_l2(vec_int8(?), vec_int8(?))
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    SQLQueryExpression(
      "vec_distance_l2(\(V.Encoding.sqliteVecExpression(expression.queryFragment)), \(V.Encoding.sqliteVecExpression(vector.queryFragment)))"
    )
  }
}
