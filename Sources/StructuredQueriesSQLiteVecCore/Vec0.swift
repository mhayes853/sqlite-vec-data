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
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query =
  ///   Embedding
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance.asc() }
  ///   .limit(5)
  ///   .select { ($0.label, $0.distance) }
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
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query =
  ///   Embedding
  ///   .where { $0.embedding.match(queryVector) && $0.k.eq(5) }
  ///   .select { ($0.label, $0.k) }
  /// ```
  public var k: some QueryExpression<Int> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."k"
      """
    )
  }
}

// MARK: - Float32 Match

extension TableColumnExpression
where
  Root: Vec0, Value: VectorBytesRepresentable, Value.Encoding == [Float].VectorBytesRepresentation
{
  /// Matches a bound or computed Float32 query against this vec0 column.
  /// The query requires a limit or `k` constraint.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding float[8]);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let query = Embedding.where { $0.embedding.match(vector) }.limit(5)
  /// ```
  public func match<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Bool> where V.Encoding == Value.Encoding {
    Vec.match(self, to: vector)
  }
}

// MARK: - Int8 Match

extension TableColumnExpression
where Root: Vec0, Value: VectorBytesRepresentable, Value.Encoding == [Int8].Int8BytesRepresentation
{
  /// Matches a bound or computed Int8 query against this vec0 column.
  /// The query requires a limit or `k` constraint.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8]);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  /// }
  ///
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let query = Embedding.where { $0.embedding.match(vector) }.limit(5)
  /// ```
  public func match<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Bool> where V.Encoding == Value.Encoding {
    Vec.match(self, to: vector)
  }
}

// MARK: - Binary Match

extension TableColumnExpression
where Root: Vec0, Value: VectorBytesRepresentable, Value.Encoding == [Bool].PackedBitsRepresentation
{
  /// Matches a bound or computed Binary query against this vec0 column.
  /// The query requires a limit or `k` constraint.
  ///
  /// ```swift
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding bit[16]);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Bool].PackedBitsRepresentation.self)
  ///   var embedding: [Bool]
  /// }
  ///
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let query = Embedding.where { $0.embedding.match(vector) }.limit(5)
  /// ```
  public func match<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Bool> where V.Encoding == Value.Encoding {
    Vec.match(self, to: vector)
  }
}

// MARK: - Float32 Expressions

extension QueryExpression
where
  QueryValue: VectorBytesRepresentable & QueryBindable,
  QueryValue.Encoding == [Float].VectorBytesRepresentation
{
  /// Returns the L2 distance to a bound or computed vector with matching dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.distanceL2(to: vector)
  /// ```
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == QueryValue.Encoding {
    Vec.distanceL2(self, to: vector)
  }

  /// Returns the L1 distance to a bound or computed vector with matching dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.distanceL1(to: vector)
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == QueryValue.Encoding {
    Vec.distanceL1(self, to: vector)
  }

  /// Returns the Cosine distance to a bound or computed vector with matching dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.distanceCosine(to: vector)
  /// ```
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == QueryValue.Encoding {
    Vec.distanceCosine(self, to: vector)
  }

  /// Returns the number of logical components.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.length()
  /// // vec_length(?)
  /// ```
  public func length() -> some QueryExpression<Int> {
    Vec.length(self)
  }

  /// Returns SQLiteVec's vector type string.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.type()
  /// // vec_type(?)
  /// ```
  public func type() -> some QueryExpression<String> {
    Vec.type(self)
  }

  /// Returns the vector components as JSON.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.toJSON()
  /// // vec_to_json(?)
  /// ```
  public func toJSON() -> some QueryExpression<String> {
    Vec.toJSON(self)
  }

  /// Adds a bound or computed vector, preserving the result's dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.add(vector)
  /// ```
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue> where V.Encoding == QueryValue.Encoding {
    Vec.add(self, vector, as: QueryValue.self)
  }

  /// Subtracts a bound or computed vector, preserving the result's dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.sub(vector)
  /// ```
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue> where V.Encoding == QueryValue.Encoding {
    Vec.sub(self, vector, as: QueryValue.self)
  }

  /// Slices components from the inclusive start to the exclusive end.
  /// Returns a variable-size representation because slicing changes dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(start: 1, end: 3)
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Float].VectorBytesRepresentation>
  {
    Vec.slice(self, start: start, end: end)
  }

  /// Slices components from the inclusive start to the exclusive end.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(start: 1, end: 3, as: EmbeddingVector<2>.self)
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
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(1..<3)
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Float].VectorBytesRepresentation>
  {
    Vec.slice(self, range: range)
  }

  /// Slices components using a half-open range.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(1..<3, as: EmbeddingVector<2>.self)
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
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(1...2)
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Float].VectorBytesRepresentation
  > {
    Vec.slice(self, range: range)
  }

  /// Slices components using a closed range.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(1...2, as: EmbeddingVector<2>.self)
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
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(start: 1, length: 2)
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<
    [Float].VectorBytesRepresentation
  > {
    Vec.slice(self, start: start, length: length)
  }

  /// Slices components using a start index and component count.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.slice(start: 1, length: 2, as: EmbeddingVector<2>.self)
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
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.normalize()
  /// // vec_normalize(?)
  /// ```
  public func normalize() -> some QueryExpression<QueryValue> {
    Vec.normalize(self, as: QueryValue.self)
  }

  /// Marks the vector with SQLiteVec's Float32 subtype.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.f32()
  /// // vec_f32(?)
  /// ```
  public func f32() -> some QueryExpression<QueryValue> {
    Vec.f32(self, as: QueryValue.self)
  }

  /// Marks the blob bytes with SQLiteVec's binary subtype.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.bit()
  /// // vec_bit(?)
  /// ```
  public func bit() -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.bit(self)
  }

  /// Marks the blob bytes with SQLiteVec's binary subtype.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.bit(as: [Bool].PackedBitsRepresentation.self)
  /// // vec_bit(?)
  /// ```
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].PackedBitsRepresentation {
    Vec.bit(self, as: result)
  }

  /// Quantizes Float32 components in [-1, 1] to signed Int8 codes. SQLiteVec clamps outliers.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.quantizeInt8()
  /// // vec_quantize_int8(?, 'unit')
  /// ```
  public func quantizeInt8() -> some QueryExpression<[Int8].Int8BytesRepresentation> {
    Vec.quantizeInt8(self)
  }

  /// Quantizes Float32 components in [-1, 1] to signed Int8 codes. SQLiteVec clamps outliers.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.quantizeInt8(as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  /// // vec_quantize_int8(?, 'unit')
  /// ```
  public func quantizeInt8<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Int8].Int8BytesRepresentation {
    Vec.quantizeInt8(self, as: result)
  }

  /// Quantizes components by sign into packed bits. Dimensions must be divisible by eight.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.quantizeBinary()
  /// // vec_quantize_binary(?)
  /// ```
  public func quantizeBinary() -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.quantizeBinary(self)
  }

  /// Quantizes components by sign into packed bits. Dimensions must be divisible by eight.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Float].VectorBytesRepresentation = [0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8]
  /// let expression = vector.quantizeBinary(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  /// // vec_quantize_binary(?)
  /// ```
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].PackedBitsRepresentation {
    Vec.quantizeBinary(self, as: result)
  }
}

// MARK: - Int8 Expressions

extension QueryExpression
where
  QueryValue: VectorBytesRepresentable & QueryBindable,
  QueryValue.Encoding == [Int8].Int8BytesRepresentation
{
  /// Returns the L2 distance to a bound or computed vector with matching dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.distanceL2(to: vector)
  /// ```
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == QueryValue.Encoding {
    Vec.distanceL2(self, to: vector)
  }

  /// Returns the L1 distance to a bound or computed vector with matching dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.distanceL1(to: vector)
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == QueryValue.Encoding {
    Vec.distanceL1(self, to: vector)
  }

  /// Returns the Cosine distance to a bound or computed vector with matching dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.distanceCosine(to: vector)
  /// ```
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == QueryValue.Encoding {
    Vec.distanceCosine(self, to: vector)
  }

  /// Returns the number of logical components.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.length()
  /// // vec_length(vec_int8(?))
  /// ```
  public func length() -> some QueryExpression<Int> {
    Vec.length(self)
  }

  /// Returns SQLiteVec's vector type string.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.type()
  /// // vec_type(vec_int8(?))
  /// ```
  public func type() -> some QueryExpression<String> {
    Vec.type(self)
  }

  /// Returns the vector components as JSON.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.toJSON()
  /// // vec_to_json(vec_int8(?))
  /// ```
  public func toJSON() -> some QueryExpression<String> {
    Vec.toJSON(self)
  }

  /// Adds a bound or computed vector, preserving the result's dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.add(vector)
  /// ```
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue> where V.Encoding == QueryValue.Encoding {
    Vec.add(self, vector, as: QueryValue.self)
  }

  /// Subtracts a bound or computed vector, preserving the result's dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.sub(vector)
  /// ```
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue> where V.Encoding == QueryValue.Encoding {
    Vec.sub(self, vector, as: QueryValue.self)
  }

  /// Slices components from the inclusive start to the exclusive end.
  /// Returns a variable-size representation because slicing changes dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(start: 1, end: 3)
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Int8].Int8BytesRepresentation> {
    Vec.slice(self, start: start, end: end)
  }

  /// Slices components from the inclusive start to the exclusive end.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(
  ///   start: 1,
  ///   end: 3,
  ///   as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  /// )
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(1..<3)
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Int8].Int8BytesRepresentation> {
    Vec.slice(self, range: range)
  }

  /// Slices components using a half-open range.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(1..<3, as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(1...2)
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Int8].Int8BytesRepresentation
  > {
    Vec.slice(self, range: range)
  }

  /// Slices components using a closed range.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(1...2, as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(start: 1, length: 2)
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  {
    Vec.slice(self, start: start, length: length)
  }

  /// Slices components using a start index and component count.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.slice(
  ///   start: 1,
  ///   length: 2,
  ///   as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  /// )
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    start: Int,
    length: Int,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, start: start, length: length, as: result)
  }

  /// Marks the vector with SQLiteVec's signed Int8 subtype.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.int8()
  /// // vec_int8(?)
  /// ```
  public func int8() -> some QueryExpression<QueryValue> {
    Vec.int8(self, as: QueryValue.self)
  }

  /// Quantizes components by sign into packed bits. Dimensions must be divisible by eight.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.quantizeBinary()
  /// // vec_quantize_binary(vec_int8(?))
  /// ```
  public func quantizeBinary() -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.quantizeBinary(self)
  }

  /// Quantizes components by sign into packed bits. Dimensions must be divisible by eight.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = vector.quantizeBinary(as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  /// // vec_quantize_binary(vec_int8(?))
  /// ```
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].PackedBitsRepresentation {
    Vec.quantizeBinary(self, as: result)
  }
}

// MARK: - Binary Expressions

extension QueryExpression
where
  QueryValue: VectorBytesRepresentable & QueryBindable,
  QueryValue.Encoding == [Bool].PackedBitsRepresentation
{
  /// Returns the Hamming distance to a bound or computed vector with matching dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.distanceHamming(to: vector)
  /// ```
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == QueryValue.Encoding {
    Vec.distanceHamming(self, to: vector)
  }

  /// Returns the number of logical components.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.length()
  /// // vec_length(vec_bit(?))
  /// ```
  public func length() -> some QueryExpression<Int> {
    Vec.length(self)
  }

  /// Returns SQLiteVec's vector type string.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.type()
  /// // vec_type(vec_bit(?))
  /// ```
  public func type() -> some QueryExpression<String> {
    Vec.type(self)
  }

  /// Returns the vector components as JSON.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.toJSON()
  /// // vec_to_json(vec_bit(?))
  /// ```
  public func toJSON() -> some QueryExpression<String> {
    Vec.toJSON(self)
  }

  /// Slices components from the inclusive start to the exclusive end. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(start: 0, end: 8)
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.slice(self, start: start, end: end)
  }

  /// Slices components from the inclusive start to the exclusive end. Binary slice boundaries must be divisible by eight.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(
  ///   start: 0,
  ///   end: 8,
  ///   as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  /// )
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    start: Int,
    end: Int,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, start: start, end: end, as: result)
  }

  /// Slices components using a half-open range. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(0..<8)
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.slice(self, range: range)
  }

  /// Slices components using a half-open range. Binary slice boundaries must be divisible by eight.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(0..<8, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    _ range: Range<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, range: range, as: result)
  }

  /// Slices components using a closed range. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(0...7)
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Bool].PackedBitsRepresentation
  > {
    Vec.slice(self, range: range)
  }

  /// Slices components using a closed range. Binary slice boundaries must be divisible by eight.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(0...7, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    _ range: ClosedRange<Int>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, range: range, as: result)
  }

  /// Slices components using a start index and component count. Binary slice boundaries must be divisible by eight.
  /// Returns a variable-size representation because slicing changes dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(start: 0, length: 8)
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<
    [Bool].PackedBitsRepresentation
  > {
    Vec.slice(self, start: start, length: length)
  }

  /// Slices components using a start index and component count. Binary slice boundaries must be divisible by eight.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.slice(
  ///   start: 0,
  ///   length: 8,
  ///   as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  /// )
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    start: Int,
    length: Int,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == QueryValue.Encoding {
    Vec.slice(self, start: start, length: length, as: result)
  }

  /// Marks the blob bytes with SQLiteVec's binary subtype.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.bit()
  /// // vec_bit(?)
  /// ```
  public func bit() -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.bit(self)
  }

  /// Marks the blob bytes with SQLiteVec's binary subtype.
  /// Decodes with a matching representation, validating any fixed dimensions.
  ///
  /// ```swift
  /// let vector = try [Bool].PackedBitsRepresentation(vectorBytes: [0x85, 0x02])
  /// let expression = vector.bit(as: BinaryEmbeddingVector<16>.PackedBitsRepresentation.self)
  /// // vec_bit(?)
  /// ```
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].PackedBitsRepresentation {
    Vec.bit(self, as: result)
  }
}
