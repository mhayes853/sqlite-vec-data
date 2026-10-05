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
/// CREATE VIRTUAL TABLE "Embeddings" USING vec0(embedding FLOAT[1536]);
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
  /// let query = Embedding
  ///   .where { $0.embedding.match(queryVector) }
  ///   .order { $0.distance.asc() }
  ///   .select { ($0.label, $0.distance) }
  /// ```
  public var distance: some QueryExpression<Double> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."distance"
      """
    )
  }

  /// The `k` rank produced by a vec0 `match` query.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding
  ///   .where { $0.embedding.match(queryVector) }
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

// MARK: - Match

extension TableColumnExpression where Root: Vec0, Value: VectorBytesRepresentable {
  /// Matches a query vector against a vec0 column.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding
  ///   .where { $0.embedding.match(queryVector) }
  ///   .select { $0.label }
  /// ```
  ///
  /// - Parameter vector: The query vector to match.
  /// - Returns: A boolean query expression for filtering.
  public func match(
    _ vector: some VectorBytesRepresentable & QueryBindable
  ) -> some QueryExpression<Bool> {
    SQLQueryExpression(
      """
      (\(Root.self).\(quote: name) MATCH \(vector))
      """
    )
  }
}

// MARK: - Column Expression Helpers

extension TableColumnExpression
where Root: Vec0, Value: VectorBytesRepresentable {
  /// Returns the L2 distance between this column and a query vector.
  /// This calls sqlite-vec's `vec_distance_l2` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   $0.embedding.distanceL2(to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameter vector: The query vector to compare.
  /// - Returns: A query expression for the L2 distance.
  public func distanceL2(
    to vector: some VectorBytesRepresentable & QueryBindable
  ) -> some QueryExpression<Double> {
    Vec.distanceL2(self, to: vector)
  }

  /// Returns the L1 distance between this column and a query vector.
  /// This calls sqlite-vec's `vec_distance_l1` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   $0.embedding.distanceL1(to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameter vector: The query vector to compare.
  /// - Returns: A query expression for the L1 distance.
  public func distanceL1(
    to vector: some VectorBytesRepresentable & QueryBindable
  ) -> some QueryExpression<Double> {
    Vec.distanceL1(self, to: vector)
  }

  /// Returns the cosine distance between this column and a query vector.
  /// This calls sqlite-vec's `vec_distance_cosine` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   $0.embedding.distanceCosine(to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameter vector: The query vector to compare.
  /// - Returns: A query expression for the cosine distance.
  public func distanceCosine(
    to vector: some VectorBytesRepresentable & QueryBindable
  ) -> some QueryExpression<Double> {
    Vec.distanceCosine(self, to: vector)
  }

  /// Returns the Hamming distance between this column and a query vector.
  /// This calls sqlite-vec's `vec_distance_hamming` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   $0.embedding.distanceHamming(to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameter vector: The query vector to compare.
  /// - Returns: A query expression for the Hamming distance.
  public func distanceHamming(
    to vector: some VectorBytesRepresentable & QueryBindable
  ) -> some QueryExpression<Double> {
    Vec.distanceHamming(self, to: vector)
  }

  /// Returns the length of the vector stored in this column.
  /// This calls sqlite-vec's `vec_length` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.length()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the vector length.
  public func length() -> some QueryExpression<Double> {
    Vec.length(self)
  }

  /// Returns the sqlite-vec type string for this column.
  /// This calls sqlite-vec's `vec_type` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.type()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the type string.
  public func type() -> some QueryExpression<String> {
    Vec.type(self)
  }

  /// Returns the JSON representation of the vector stored in this column.
  /// This calls sqlite-vec's `vec_to_json` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.toJSON()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the JSON string.
  public func toJSON() -> some QueryExpression<String> {
    Vec.toJSON(self)
  }

  /// Adds a query vector to this column.
  /// This calls sqlite-vec's `vec_add` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   $0.embedding.add(queryVector)
  /// }
  /// ```
  ///
  /// - Parameter vector: The query vector to add.
  /// - Returns: A query expression for the summed vector.
  public func add(
    _ vector: some VectorBytesRepresentable & QueryBindable
  ) -> some QueryExpression<Value> {
    Vec.add(self, vector, as: Value.self)
  }

  /// Subtracts a query vector from this column.
  /// This calls sqlite-vec's `vec_sub` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   $0.embedding.sub(queryVector)
  /// }
  /// ```
  ///
  /// - Parameter vector: The query vector to subtract.
  /// - Returns: A query expression for the difference vector.
  public func sub(
    _ vector: some VectorBytesRepresentable & QueryBindable
  ) -> some QueryExpression<Value> {
    Vec.sub(self, vector, as: Value.self)
  }

  /// Extracts a slice of the vector stored in this column using a start index and exclusive end index.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.slice(start: 0, end: 3)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - start: The start index.
  ///   - end: The exclusive end index.
  /// - Returns: A query expression for the sliced vector.
  public func slice(
    start: Int,
    end: Int
  ) -> some QueryExpression<Value> {
    Vec.slice(self, start: start, end: end, as: Value.self)
  }

  /// Extracts a slice of the vector stored in this column using a half-open range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.slice(0..<3)
  /// }
  /// ```
  ///
  /// - Parameter range: The half-open range to extract.
  /// - Returns: A query expression for the sliced vector.
  public func slice(
    _ range: Range<Int>
  ) -> some QueryExpression<Value> {
    Vec.slice(self, range: range, as: Value.self)
  }

  /// Extracts a slice of the vector stored in this column using a closed range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.slice(0...2)
  /// }
  /// ```
  ///
  /// - Parameter range: The closed range to extract.
  /// - Returns: A query expression for the sliced vector.
  public func slice(
    _ range: ClosedRange<Int>
  ) -> some QueryExpression<Value> {
    Vec.slice(self, range: range, as: Value.self)
  }

  /// Extracts a slice of the vector stored in this column using a start index and length.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.slice(start: 0, length: 3)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - start: The start index.
  ///   - length: The number of elements to extract.
  /// - Returns: A query expression for the sliced vector.
  public func slice(
    start: Int,
    length: Int
  ) -> some QueryExpression<Value> {
    self.slice(start..<start + length)
  }

  /// Normalizes the vector stored in this column.
  /// This calls sqlite-vec's `vec_normalize` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.normalize()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the normalized vector.
  public func normalize() -> some QueryExpression<Value> {
    Vec.normalize(self, as: Value.self)
  }

  /// Converts the vector stored in this column to an f32 representation.
  /// This calls sqlite-vec's `vec_f32` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.f32()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the f32 vector.
  public func f32() -> some QueryExpression<Value> {
    Vec.f32(self, as: Value.self)
  }

  /// Converts the vector stored in this column to a bit representation.
  /// This calls sqlite-vec's `vec_bit` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.bit()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the bit vector.
  public func bit() -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.bit(self)
  }

  /// Returns logical bits using a matching packed-bit representation.
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].PackedBitsRepresentation {
    Vec.bit(self, as: result)
  }

  /// Converts the vector stored in this column to an int8 representation.
  /// This calls sqlite-vec's `vec_int8` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.int8()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the int8 vector.
  public func int8() -> some QueryExpression<Value> {
    Vec.int8(self, as: Value.self)
  }

  /// Quantizes the vector stored in this column to int8.
  /// This calls sqlite-vec's `vec_quantize_int8` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.quantizeInt8(scale: 1.0)
  /// }
  /// ```
  ///
  /// - Parameter scale: The scale value passed to sqlite-vec.
  /// - Returns: A query expression for the quantized vector.
  public func quantizeInt8(scale: Double) -> some QueryExpression<Value> {
    Vec.quantizeInt8(
      self,
      scale: scale,
      as: Value.self
    )
  }

  /// Quantizes the vector stored in this column to a binary representation.
  /// This calls sqlite-vec's `vec_quantize_binary` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   $0.embedding.quantizeBinary()
  /// }
  /// ```
  ///
  /// - Returns: A query expression for the quantized vector.
  public func quantizeBinary() -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.quantizeBinary(self)
  }

  /// Returns logical bits using a matching packed-bit representation.
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].PackedBitsRepresentation {
    Vec.quantizeBinary(self, as: result)
  }
}
