import StructuredQueriesCore

// MARK: - Vec0

/// A table backed by a sqlite-vec vec0 virtual table.
///
/// Vec0 tracks the metadata vec0 needs for columns that store embeddings and
/// surfaces helpers such as `.distance`, `.k`, and `.match`, so you write
/// similarity queries with structured SQL instead of touching raw byte blobs.
///
/// First, create a virtual table using the `vec0` module:
/// ```sql
/// CREATE VIRTUAL TABLE "Embeddings" USING vec0(embedding FLOAT[3], label TEXT);
/// ```
///
/// Then, define your table using the `@Table` attribute:
/// ```swift
/// @Table("Embeddings")
/// struct Embedding: Vec0 {
///   @Column(as: [Float].VectorBytesRepresentation.self)
///   var embedding: [Float]
///
///   var label: String
/// }
/// ```
public protocol Vec0: Table {}

// MARK: - Column Helpers

extension TableDefinition where QueryValue: Vec0 {
  /// The distance value produced by a vec0 `match` query.
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
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query =
  ///   Embedding
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance.asc() }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH ?))
  /// // ORDER BY "Embeddings"."distance" ASC
  /// // LIMIT ?
  /// ```
  public var distance: some QueryExpression<Double> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."distance"
      """
    )
  }

  /// The number of nearest neighbors requested by a vec0 `match` query.
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
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query =
  ///   Embedding
  ///   .where { $0.embedding.match(queryVector) && $0.k.eq(5) }
  ///   .select { ($0.label, $0.k) }
  /// // SELECT "Embeddings"."label", "Embeddings"."k"
  /// // FROM "Embeddings"
  /// // WHERE ((("Embeddings"."embedding" MATCH ?)) AND (("Embeddings"."k") = (?)))
  /// ```
  public var k: some QueryExpression<Int> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."k"
      """
    )
  }
}

// MARK: - Match

extension TableColumnExpression
where Root: Vec0, Value: VectorBytesRepresentable, Value.Encoding: SQLiteVecVectorEncoding {
  /// Matches a bound or computed vector with this vec0 column's encoding.
  /// The query requires a limit or `k` constraint.
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
  ///   .where { $0.embedding.match(queryVector) }
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
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
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
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_bit(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  public func match<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Bool>
  where
    V.Encoding == Value.Encoding,
    Value.Dimensions == V.Dimensions
  {
    Vec.match(self, to: vector)
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
  ///   .where { $0.embedding.match(queryVector) }
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
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
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
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_bit(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public func match<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Bool>
  where
    V.Encoding == Value.Encoding,
    Value.Dimensions == Void
  {
    Vec.match(self, to: vector)
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
  ///   .where { $0.embedding.match(queryVector) }
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
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
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
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
  /// // SELECT "Embeddings"."label", "Embeddings"."distance"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_bit(?)))
  /// // ORDER BY "Embeddings"."distance"
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public func match<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Bool>
  where
    V.Encoding == Value.Encoding,
    V.Dimensions == Void
  {
    Vec.match(self, to: vector)
  }
}

// MARK: - Scalar Expressions

extension QueryExpression
where
  QueryValue: VectorBytesRepresentable & QueryBindable,
  QueryValue.Encoding: SQLiteVecVectorEncoding
{
  /// Returns the L2 distance to a bound or computed vector with matching dimensions.
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
  ///   ($0.label, $0.embedding.distanceL2(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2("Embeddings"."embedding", ?)
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
  ///   ($0.label, $0.embedding.distanceL2(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(self, to: vector)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceL2(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2("Embeddings"."embedding", ?)
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
  ///   ($0.label, $0.embedding.distanceL2(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(self, to: vector)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceL2(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2("Embeddings"."embedding", ?)
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
  ///   ($0.label, $0.embedding.distanceL2(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l2(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(self, to: vector)
  }

  /// Returns the L1 distance to a bound or computed vector with matching dimensions.
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
  ///   ($0.label, $0.embedding.distanceL1(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l1("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(self, to: vector)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceL1(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l1("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(self, to: vector)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceL1(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_l1("Embeddings"."embedding", ?)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Returns the Cosine distance to a bound or computed vector with matching dimensions.
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
  ///   ($0.label, $0.embedding.distanceCosine(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", ?)
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
  ///   ($0.label, $0.embedding.distanceCosine(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(self, to: vector)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceCosine(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", ?)
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
  ///   ($0.label, $0.embedding.distanceCosine(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(self, to: vector)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceCosine(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine("Embeddings"."embedding", ?)
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
  ///   ($0.label, $0.embedding.distanceCosine(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_cosine(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(self, to: vector)
  }

  /// Returns the number of logical components.
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
  ///   ($0.label, $0.embedding.length())
  /// }
  /// // SELECT "Embeddings"."label", vec_length("Embeddings"."embedding")
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
  ///   ($0.label, $0.embedding.length())
  /// }
  /// // SELECT "Embeddings"."label", vec_length(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.length())
  /// }
  /// // SELECT "Embeddings"."label", vec_length(vec_bit("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public func length() -> some QueryExpression<Int> {
    Vec.length(self)
  }

  /// Returns SQLiteVec's vector type string.
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
  ///   ($0.label, $0.embedding.type())
  /// }
  /// // SELECT "Embeddings"."label", vec_type("Embeddings"."embedding")
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
  ///   ($0.label, $0.embedding.type())
  /// }
  /// // SELECT "Embeddings"."label", vec_type(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.type())
  /// }
  /// // SELECT "Embeddings"."label", vec_type(vec_bit("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public func type() -> some QueryExpression<String> {
    Vec.type(self)
  }

  /// Returns the vector components as JSON.
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
  ///   ($0.label, $0.embedding.toJSON())
  /// }
  /// // SELECT "Embeddings"."label", vec_to_json("Embeddings"."embedding")
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
  ///   ($0.label, $0.embedding.toJSON())
  /// }
  /// // SELECT "Embeddings"."label", vec_to_json(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.toJSON())
  /// }
  /// // SELECT "Embeddings"."label", vec_to_json(vec_bit("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public func toJSON() -> some QueryExpression<String> {
    Vec.toJSON(self)
  }

  /// Adds a bound or computed vector, preserving the result's dimensions.
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
  ///   ($0.label, $0.embedding.add(queryVector))
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
  ///   ($0.label, $0.embedding.add(queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(self, vector, as: QueryValue.self)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.add(queryVector))
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
  ///   ($0.label, $0.embedding.add(queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<V>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(self, vector, as: V.self)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.add(queryVector))
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
  ///   ($0.label, $0.embedding.add(queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_add(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(self, vector, as: QueryValue.self)
  }

  /// Subtracts a bound or computed vector, preserving the result's dimensions.
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
  ///   ($0.label, $0.embedding.sub(queryVector))
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
  ///   ($0.label, $0.embedding.sub(queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(self, vector, as: QueryValue.self)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.sub(queryVector))
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
  ///   ($0.label, $0.embedding.sub(queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<V>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(self, vector, as: V.self)
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.sub(queryVector))
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
  ///   ($0.label, $0.embedding.sub(queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_sub(vec_int8("Embeddings"."embedding"), vec_int8(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(self, vector, as: QueryValue.self)
  }

  /// Slices components from the inclusive start to the exclusive end.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 1, end: 3))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(self, start: start, end: end)
  }

  /// Slices components from the inclusive start to the exclusive end.
  /// Decodes with a matching representation, validating any fixed dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 1, end: 3, as: EmbeddingVector<2>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
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
  ///   ($0.label, $0.embedding.slice(
  ///     start: 1,
  ///     end: 3,
  ///     as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.slice(
  ///     start: 0,
  ///     end: 8,
  ///     as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    start: Int,
    end: Int,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, start: start, end: end, as: result)
  }

  /// Slices components using a half-open range.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(1..<3))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(self, range: range)
  }

  /// Slices components using a half-open range.
  /// Decodes with a matching representation, validating any fixed dimensions.
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
  ///   ($0.label, $0.embedding.slice(1..<3, as: EmbeddingVector<2>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
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
  ///   ($0.label, $0.embedding.slice(1..<3, as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.slice(0..<8, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    _ range: Range<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, range: range, as: result)
  }

  /// Slices components using a closed range.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(1...2))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Float].VectorBytesRepresentation
  >
  where
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(self, range: range)
  }

  /// Slices components using a closed range.
  /// Decodes with a matching representation, validating any fixed dimensions.
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
  ///   ($0.label, $0.embedding.slice(1...2, as: EmbeddingVector<2>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
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
  ///   ($0.label, $0.embedding.slice(1...2, as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.slice(0...7, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    _ range: ClosedRange<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, range: range, as: result)
  }

  /// Slices components using a start index and component count.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 1, length: 2))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<
    [Float].VectorBytesRepresentation
  >
  where
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(self, start: start, length: length)
  }

  /// Slices components using a start index and component count.
  /// Decodes with a matching representation, validating any fixed dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 1, length: 2, as: EmbeddingVector<2>.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice("Embeddings"."embedding", 1, 3)
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
  ///   ($0.label, $0.embedding.slice(
  ///     start: 1,
  ///     length: 2,
  ///     as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.slice(
  ///     start: 0,
  ///     length: 8,
  ///     as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  ///   ))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    start: Int,
    length: Int,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, start: start, length: length, as: result)
  }

  /// Normalizes the vector, preserving its dimensions.
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
  ///   ($0.label, $0.embedding.normalize())
  /// }
  /// // SELECT "Embeddings"."label", vec_normalize("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public func normalize() -> some QueryExpression<QueryValue>
  where
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.normalize(self, as: QueryValue.self)
  }

  /// Marks the vector with SQLiteVec's Float32 subtype.
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
  ///   ($0.label, $0.embedding.f32())
  /// }
  /// // SELECT "Embeddings"."label", vec_f32("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public func f32() -> some QueryExpression<QueryValue>
  where
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.f32(self, as: QueryValue.self)
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
  ///   ($0.label, $0.embedding.quantizeInt8())
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// // The result retains eight logical dimensions.
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public func quantizeInt8<let count: Int>() -> some QueryExpression<
    FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation
  >
  where
    QueryValue.Dimensions == VectorDimensions<count>,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(self, as: FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation.self)
  }

  /// Quantizes Float32 components in [-1, 1] to signed Int8 codes. SQLiteVec clamps outliers.
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
  ///   ($0.label, $0.embedding.quantizeInt8())
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  public func quantizeInt8() -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(self)
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
  ///   ($0.label, $0.embedding.quantizeInt8(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  public func quantizeInt8<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecInt8Encoding,
    QueryValue.Dimensions == T.Dimensions,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(self, as: result)
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
  ///     $0.embedding.quantizeInt8(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  ///   )
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func quantizeInt8<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecInt8Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(self, as: result)
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
  ///   ($0.label, $0.embedding.quantizeInt8(as: [Int8].Int8BytesRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_int8("Embeddings"."embedding", 'unit')
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func quantizeInt8<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecInt8Encoding,
    T.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(self, as: result)
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
  ///   ($0.label, $0.embedding.quantizeBinary())
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
  ///   ($0.label, $0.embedding.quantizeBinary())
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// // The result retains eight logical dimensions.
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public func quantizeBinary<let count: Int>() -> some QueryExpression<
    BinaryEmbeddingVector<count>.PackedBitsRepresentation
  >
  where
    QueryValue.Dimensions == VectorDimensions<count>,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(self, as: BinaryEmbeddingVector<count>.PackedBitsRepresentation.self)
  }
  /// Quantizes components by sign into packed bits. Dimensions must be divisible by eight.
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
  ///   ($0.label, $0.embedding.quantizeBinary())
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
  ///   ($0.label, $0.embedding.quantizeBinary())
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public func quantizeBinary() -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(self)
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
  ///   ($0.label, $0.embedding.quantizeBinary(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
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
  ///   ($0.label, $0.embedding.quantizeBinary(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Dimensions == T.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(self, as: result)
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
  ///     $0.embedding.quantizeBinary(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
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
  ///     $0.embedding.quantizeBinary(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  ///   )
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(self, as: result)
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
  ///   ($0.label, $0.embedding.quantizeBinary(as: [Bool].PackedBitsRepresentation.self))
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
  ///   ($0.label, $0.embedding.quantizeBinary(as: [Bool].PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_quantize_binary(vec_int8("Embeddings"."embedding"))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(self, as: result)
  }

  /// Returns the L1 distance to a bound or computed vector with matching dimensions.
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
  ///   ($0.label, $0.embedding.distanceL1(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", CAST(vec_distance_l1(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?)) AS REAL)
  /// // FROM "Embeddings"
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(self, to: vector)
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
  ///   ($0.label, $0.embedding.distanceL1(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", CAST(vec_distance_l1(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?)) AS REAL)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(self, to: vector)
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
  ///   ($0.label, $0.embedding.distanceL1(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", CAST(vec_distance_l1(vec_int8("Embeddings"."embedding"),
  /// //   vec_int8(?)) AS REAL)
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Slices components from the inclusive start to the exclusive end.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 1, end: 3))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(self, start: start, end: end)
  }

  /// Slices components using a half-open range.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(1..<3))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(self, range: range)
  }

  /// Slices components using a closed range.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(1...2))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Int8].Int8BytesRepresentation
  >
  where
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(self, range: range)
  }

  /// Slices components using a start index and component count.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 1, length: 2))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_int8("Embeddings"."embedding"), 1, 3)
  /// // FROM "Embeddings"
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(self, start: start, length: length)
  }

  /// Marks the vector with SQLiteVec's signed Int8 subtype.
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
  ///   ($0.label, $0.embedding.int8())
  /// }
  /// // SELECT "Embeddings"."label", vec_int8("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public func int8() -> some QueryExpression<QueryValue>
  where
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.int8(self, as: QueryValue.self)
  }

  /// Returns the Hamming distance to a bound or computed vector with matching dimensions.
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceHamming(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_hamming(vec_bit("Embeddings"."embedding"),
  /// //   vec_bit(?))
  /// // FROM "Embeddings"
  /// ```
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(self, to: vector)
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceHamming(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_hamming(vec_bit("Embeddings"."embedding"),
  /// //   vec_bit(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(self, to: vector)
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
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
  /// let query = Embedding.select {
  ///   ($0.label, $0.embedding.distanceHamming(to: queryVector))
  /// }
  /// // SELECT "Embeddings"."label", vec_distance_hamming(vec_bit("Embeddings"."embedding"),
  /// //   vec_bit(?))
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(self, to: vector)
  }

  /// Slices components from the inclusive start to the exclusive end. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 0, end: 8))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(self, start: start, end: end)
  }

  /// Slices components using a half-open range. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(0..<8))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(self, range: range)
  }

  /// Slices components using a closed range. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(0...7))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Bool].PackedBitsRepresentation
  >
  where
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(self, range: range)
  }

  /// Slices components using a start index and component count. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
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
  ///   ($0.label, $0.embedding.slice(start: 0, length: 8))
  /// }
  /// // SELECT "Embeddings"."label", vec_slice(vec_bit("Embeddings"."embedding"), 0, 8)
  /// // FROM "Embeddings"
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<
    [Bool].PackedBitsRepresentation
  >
  where
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(self, start: start, length: length)
  }

  /// Marks the blob bytes with SQLiteVec's binary subtype.
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
  ///   ($0.label, $0.embedding.bit())
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public func bit() -> some QueryExpression<QueryValue>
  where
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(self, as: QueryValue.self)
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
  ///   ($0.label, $0.embedding.bit(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Dimensions == T.Dimensions,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(self, as: result)
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
  ///   ($0.label, $0.embedding.bit(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(self, as: result)
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
  ///   ($0.label, $0.embedding.bit(as: [Bool].PackedBitsRepresentation.self))
  /// }
  /// // SELECT "Embeddings"."label", vec_bit("Embeddings"."embedding")
  /// // FROM "Embeddings"
  /// ```
  @_disfavoredOverload
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(self, as: result)
  }

}
