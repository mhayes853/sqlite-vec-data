import StructuredQueriesCore

extension Vec {
  /// Marks a signed-byte blob with SQLiteVec's Int8 subtype.
  ///
  /// This reinterprets bytes, rather than numerically converting Float32 components. Use
  /// `quantizeInt8` for Float32 quantization. Blob subtypes do not survive storage or binding,
  /// so this helper is also needed when inserting into vec0 Int8 columns.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.int8(vector, as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self)
  /// // vec_int8(?)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.int8(vector)
  /// // vec_int8(?)
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
  /// let expression = Vec.int8(
  ///   "[1,-2,3]",
  ///   as: FixedEmbeddingVector<3, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_int8(?)
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
  /// let expression = Vec.int8("[1,-2,3]")
  /// // vec_int8(?)
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
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8]);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  /// }
  ///
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let query = Embedding.where { Vec.match($0.embedding, to: vector) }.limit(5)
  /// // SELECT "Embeddings"."embedding"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
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
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8]);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  /// }
  ///
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let query = Embedding.where { Vec.match($0.embedding, to: vector) }.limit(5)
  /// // SELECT "Embeddings"."embedding"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
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
  /// // CREATE VIRTUAL TABLE Embeddings USING vec0(embedding int8[8]);
  /// @Table("Embeddings")
  /// struct Embedding: Vec0 {
  ///   @Column(as: [Int8].Int8BytesRepresentation.self)
  ///   var embedding: [Int8]
  /// }
  ///
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let query = Embedding.where { Vec.match($0.embedding, to: vector) }.limit(5)
  /// // SELECT "Embeddings"."embedding"
  /// // FROM "Embeddings"
  /// // WHERE (("Embeddings"."embedding" MATCH vec_int8(?)))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceL1(vector, to: vector)
  /// // CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceL1(vector, to: vector)
  /// // CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceL1(vector, to: vector)
  /// // CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceL2(vector, to: vector)
  /// // vec_distance_l2(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceL2(vector, to: vector)
  /// // vec_distance_l2(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceL2(vector, to: vector)
  /// // vec_distance_l2(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceCosine(vector, to: vector)
  /// // vec_distance_cosine(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceCosine(vector, to: vector)
  /// // vec_distance_cosine(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.distanceCosine(vector, to: vector)
  /// // vec_distance_cosine(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.length(vector)
  /// // vec_length(vec_int8(?))
  /// ```
  public static func length<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<Int> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_length(vec_int8(\(expression)))")
  }

  /// Returns the SQLiteVec type string (`int8`).
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.type(vector)
  /// // vec_type(vec_int8(?))
  /// ```
  public static func type<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_type(vec_int8(\(expression)))")
  }

  /// Returns the signed Int8 components as JSON.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.toJSON(vector)
  /// // vec_to_json(vec_int8(?))
  /// ```
  public static func toJSON<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_to_json(vec_int8(\(expression)))")
  }

  /// Adds signed Int8 components, returning signed bytes with SQLiteVec's arithmetic semantics.
  ///
  /// ```swift
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.add(
  ///   vector,
  ///   vector,
  ///   as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_add(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.add(
  ///   vector,
  ///   vector,
  ///   as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_add(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.add(
  ///   vector,
  ///   vector,
  ///   as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_add(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.add(vector, vector)
  /// // vec_add(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.add(vector, vector)
  /// // vec_add(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.add(vector, vector)
  /// // vec_add(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.sub(
  ///   vector,
  ///   vector,
  ///   as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_sub(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.sub(
  ///   vector,
  ///   vector,
  ///   as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_sub(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.sub(
  ///   vector,
  ///   vector,
  ///   as: FixedEmbeddingVector<8, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_sub(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.sub(vector, vector)
  /// // vec_sub(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.sub(vector, vector)
  /// // vec_sub(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.sub(vector, vector)
  /// // vec_sub(vec_int8(?), vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(
  ///   vector,
  ///   start: 1,
  ///   end: 3,
  ///   as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(vector, start: 1, end: 3)
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(
  ///   vector,
  ///   range: 1..<3,
  ///   as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(vector, range: 1..<3)
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(
  ///   vector,
  ///   range: 1...2,
  ///   as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(vector, range: 1...2)
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(
  ///   vector,
  ///   start: 1,
  ///   length: 2,
  ///   as: FixedEmbeddingVector<2, Int8>.Int8BytesRepresentation.self
  /// )
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.slice(vector, start: 1, length: 2)
  /// // vec_slice(vec_int8(?), 1, 3)
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.quantizeBinary(
  ///   vector,
  ///   as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self
  /// )
  /// // vec_quantize_binary(vec_int8(?))
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
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 3, -4, 5, -6, 7, -8]
  /// let expression = Vec.quantizeBinary(vector)
  /// // vec_quantize_binary(vec_int8(?))
  /// ```
  public static func quantizeBinary<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  }
}
