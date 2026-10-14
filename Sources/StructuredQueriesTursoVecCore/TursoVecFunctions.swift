import StructuredQueriesCore

/// Vector SQL functions for Turso Database (the Rust engine).
///
/// These helpers follow the [vector documentation](https://docs.turso.tech/sql-reference/functions/vector).
/// Convert JSON explicitly before distance comparisons, using the same format on both sides.
/// The database checks dimensions and value-dependent restrictions.
///
/// ```swift
/// @Table("documents")
/// struct Document {
///   var content: String
///   var embedding: EmbeddingVector<3>
/// }
/// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
/// let neighbors = Document
///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
///   .limit(5)
///   .select(\.content)
/// // SELECT "documents"."content"
/// // FROM "documents"
/// // ORDER BY vector_distance_cos("documents"."embedding", ?)
/// // LIMIT ?
/// ```
public enum TursoVec {
  /// Counts differing binary components with Turso's `vector_distance_cos` specialization.
  /// The database returns an integer-valued REAL and requires equal dimensions.
  /// See [Turso's limitations](https://docs.turso.tech/guides/vector-search#limitations).
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<3>
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<3>.TursoBytesRepresentation(queryOutput: BinaryEmbeddingVector<3>([true, false, true]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceHamming($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == R.Dimensions
  {
    Self.distanceCosine(expression, to: vector)
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: [Bool].TursoBytesRepresentation.self)
  ///   var embedding: [Bool]
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<3>.TursoBytesRepresentation(queryOutput: BinaryEmbeddingVector<3>([true, false, true]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceHamming($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == Void
  {
    Self.distanceCosine(expression, to: vector)
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<3>
  /// }
  ///
  /// let queryVector: [Bool].TursoBytesRepresentation = [true, false, true]
  /// let neighbors = Document
  ///   .order { TursoVec.distanceHamming($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    R.Dimensions == Void
  {
    Self.distanceCosine(expression, to: vector)
  }

  /// Converts JSON to a 32-bit floating-point vector with `vector32`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let embedding = TursoVec.vector32("[1,2,3]")
  /// // vector32(?)
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector32(?))
  /// ```
  public static func vector32(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    Self.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Converts JSON with `vector32`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let embedding = TursoVec.vector32("[1,2,3]", as: EmbeddingVector<3>.self)
  /// // vector32(?)
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector32(?))
  /// ```
  public static func vector32<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding: TursoFloat32Encoding {
    SQLQueryExpression("vector32(\(expression))")
  }

  #if swift(>=6.2)
    /// Converts a fixed-size vector while preserving its logical dimension count.
    ///
    /// ```swift
    /// let source = EmbeddingVector<8>([0.1, -0.2, 0, 0.4, 0, -0.6, 0, 0.8])
    /// let converted = TursoVec.vector32(source)
    /// // vector32(?)
    /// let components = TursoVec.extract(converted)
    /// // vector_extract(vector32(?))
    /// // The result retains eight logical dimensions for subsequent operations.
    /// ```
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public static func vector32<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
      _ expression: some QueryExpression<V>
    ) -> some QueryExpression<EmbeddingVector<count>>
    where
      V.Encoding: TursoVectorEncoding,
      V.Dimensions == VectorDimensions<count>
    {
      Self.vector32(expression, as: EmbeddingVector<count>.self)
    }
  #endif

  /// Converts a supported vector BLOB to a 32-bit floating-point vector with `vector32`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let source = TursoVec.vector64("[0.1, 0.2, 0.3]")
  /// // vector64(?)
  /// let embedding = TursoVec.vector32(source)
  /// // vector32(vector64(?))
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector32(vector64(?)))
  /// ```
  public static func vector32<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    Self.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector32($0.embedding, as: EmbeddingVector<8>.self)
  /// }
  /// // SELECT vector32("documents"."embedding")
  /// // FROM "documents"
  /// ```
  public static func vector32<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vector32(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector32($0.embedding, as: EmbeddingVector<8>.self)
  /// }
  /// // SELECT vector32("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector32<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat32Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vector32(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector32($0.embedding, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// // SELECT vector32("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector32<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat32Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vector32(\(expression))")
  }

  /// Converts JSON to a 64-bit floating-point vector with `vector64`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
  ///   var embedding: [Double]
  /// }
  ///
  /// let embedding = TursoVec.vector64("[1,2,3]")
  /// // vector64(?)
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector64(?))
  /// ```
  public static func vector64(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation> {
    Self.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  }

  /// Converts JSON with `vector64`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  ///   var embedding: EmbeddingVector64<3>
  /// }
  ///
  /// let embedding = TursoVec.vector64(
  ///   "[1,2,3]",
  ///   as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self
  /// )
  /// // vector64(?)
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector64(?))
  /// ```
  public static func vector64<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding: TursoFloat64Encoding {
    SQLQueryExpression("vector64(\(expression))")
  }

  #if swift(>=6.2)
    /// Converts a fixed-size vector while preserving its logical dimension count.
    ///
    /// ```swift
    /// let source = EmbeddingVector<8>([0.1, -0.2, 0, 0.4, 0, -0.6, 0, 0.8])
    /// let converted = TursoVec.vector64(source)
    /// // vector64(?)
    /// let components = TursoVec.extract(converted)
    /// // vector_extract(vector64(?))
    /// // The result retains eight logical dimensions for subsequent operations.
    /// ```
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public static func vector64<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
      _ expression: some QueryExpression<V>
    ) -> some QueryExpression<EmbeddingVector64<count>.TursoFloat64BytesRepresentation>
    where
      V.Encoding: TursoVectorEncoding,
      V.Dimensions == VectorDimensions<count>
    {
      Self.vector64(expression, as: EmbeddingVector64<count>.TursoFloat64BytesRepresentation.self)
    }
  #endif

  /// Converts a supported vector BLOB to a 64-bit floating-point vector with `vector64`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
  ///   var embedding: [Double]
  /// }
  ///
  /// let source = TursoVec.vector32("[1, 2, 3]")
  /// // vector32(?)
  /// let embedding = TursoVec.vector64(source)
  /// // vector64(vector32(?))
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector64(vector32(?)))
  /// ```
  public static func vector64<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    Self.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector64($0.embedding, as: EmbeddingVector64<8>.TursoFloat64BytesRepresentation.self)
  /// }
  /// // SELECT vector64("documents"."embedding")
  /// // FROM "documents"
  /// ```
  public static func vector64<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat64Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vector64(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector64($0.embedding, as: EmbeddingVector64<8>.TursoFloat64BytesRepresentation.self)
  /// }
  /// // SELECT vector64("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector64<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat64Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vector64(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector64($0.embedding, as: [Double].TursoFloat64BytesRepresentation.self)
  /// }
  /// // SELECT vector64("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector64<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat64Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vector64(\(expression))")
  }

  /// Converts JSON to an affine quantized UInt8 vector with `vector8`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: Quantized8Vector.self)
  ///   var embedding: Quantized8Vector
  /// }
  ///
  /// let embedding = TursoVec.vector8("[1,2,3]")
  /// // vector8(?)
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector8(?))
  /// ```
  public static func vector8(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<Quantized8Vector> {
    Self.vector8(expression, as: Quantized8Vector.self)
  }

  /// Converts JSON with `vector8`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: InlineQuantized8Vector<3>.self)
  ///   var embedding: InlineQuantized8Vector<3>
  /// }
  ///
  /// let embedding = TursoVec.vector8("[1,2,3]", as: InlineQuantized8Vector<3>.self)
  /// // vector8(?)
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector8(?))
  /// ```
  public static func vector8<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding: TursoQuantized8Encoding {
    SQLQueryExpression("vector8(\(expression))")
  }

  #if swift(>=6.2)
    /// Converts a fixed-size vector while preserving its logical dimension count.
    ///
    /// ```swift
    /// let source = EmbeddingVector<8>([0.1, -0.2, 0, 0.4, 0, -0.6, 0, 0.8])
    /// let converted = TursoVec.vector8(source)
    /// // vector8(?)
    /// let components = TursoVec.extract(converted)
    /// // vector_extract(vector8(?))
    /// // The result retains eight logical dimensions for subsequent operations.
    /// ```
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public static func vector8<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
      _ expression: some QueryExpression<V>
    ) -> some QueryExpression<InlineQuantized8Vector<count>>
    where
      V.Encoding: TursoVectorEncoding,
      V.Dimensions == VectorDimensions<count>
    {
      Self.vector8(expression, as: InlineQuantized8Vector<count>.self)
    }
  #endif

  /// Converts a supported vector BLOB to a quantized vector with `vector8`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: Quantized8Vector.self)
  ///   var embedding: Quantized8Vector
  /// }
  ///
  /// let source = TursoVec.vector32("[-0.75, 0, 0.5]")
  /// // vector32(?)
  /// let embedding = TursoVec.vector8(source)
  /// // vector8(vector32(?))
  /// // Quantized conversion discards precision; binary conversion keeps only positive signs.
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector8(vector32(?)))
  /// ```
  public static func vector8<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<Quantized8Vector>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    Self.vector8(expression, as: Quantized8Vector.self)
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector8($0.embedding, as: InlineQuantized8Vector<8>.self)
  /// }
  /// // SELECT vector8("documents"."embedding")
  /// // FROM "documents"
  /// ```
  public static func vector8<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoQuantized8Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vector8(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector8($0.embedding, as: InlineQuantized8Vector<8>.self)
  /// }
  /// // SELECT vector8("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector8<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoQuantized8Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vector8(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector8($0.embedding, as: Quantized8Vector.self)
  /// }
  /// // SELECT vector8("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector8<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoQuantized8Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vector8(\(expression))")
  }

  /// Converts JSON to a binary vector with `vector1bit`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Bool].TursoBytesRepresentation.self)
  ///   var embedding: [Bool]
  /// }
  ///
  /// let embedding = TursoVec.vector1bit("[-0.75,0,0.5]")
  /// // vector1bit(?)
  /// // Binary components become [false, false, true].
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector1bit(?))
  /// ```
  public static func vector1bit(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation> {
    Self.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  }

  /// Converts JSON with `vector1bit`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<3>
  /// }
  ///
  /// let embedding = TursoVec.vector1bit(
  ///   "[-0.75,0,0.5]",
  ///   as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self
  /// )
  /// // vector1bit(?)
  /// // Binary components become [false, false, true].
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector1bit(?))
  /// ```
  public static func vector1bit<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding: TursoBinaryEncoding {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  #if swift(>=6.2)
    /// Converts a fixed-size vector while preserving its logical dimension count.
    ///
    /// ```swift
    /// let source = EmbeddingVector<8>([0.1, -0.2, 0, 0.4, 0, -0.6, 0, 0.8])
    /// let converted = TursoVec.vector1bit(source)
    /// // vector1bit(?)
    /// let components = TursoVec.extract(converted)
    /// // vector_extract(vector1bit(?))
    /// // The result retains eight logical dimensions for subsequent operations.
    /// ```
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public static func vector1bit<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
      _ expression: some QueryExpression<V>
    ) -> some QueryExpression<BinaryEmbeddingVector<count>.TursoBytesRepresentation>
    where
      V.Encoding: TursoVectorEncoding,
      V.Dimensions == VectorDimensions<count>
    {
      Self.vector1bit(expression, as: BinaryEmbeddingVector<count>.TursoBytesRepresentation.self)
    }
  #endif

  /// Converts a supported vector BLOB to a binary vector with `vector1bit`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Bool].TursoBytesRepresentation.self)
  ///   var embedding: [Bool]
  /// }
  ///
  /// let source = TursoVec.vector32("[-0.75, 0, 0.5]")
  /// // vector32(?)
  /// let embedding = TursoVec.vector1bit(source)
  /// // vector1bit(vector32(?))
  /// // Binary components become [false, false, true].
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector1bit(vector32(?)))
  /// ```
  public static func vector1bit<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    Self.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector1bit($0.embedding, as: BinaryEmbeddingVector<8>.TursoBytesRepresentation.self)
  /// }
  /// // SELECT vector1bit("documents"."embedding")
  /// // FROM "documents"
  /// ```
  public static func vector1bit<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoBinaryEncoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector1bit($0.embedding, as: BinaryEmbeddingVector<8>.TursoBytesRepresentation.self)
  /// }
  /// // SELECT vector1bit("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector1bit<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoBinaryEncoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector1bit($0.embedding, as: [Bool].TursoBytesRepresentation.self)
  /// }
  /// // SELECT vector1bit("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector1bit<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoBinaryEncoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vector1bit(\(expression))")
  }

  /// Converts JSON to a sparse float32 vector with `vector32_sparse`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: SparseFloat32Vector.self)
  ///   var embedding: SparseFloat32Vector
  /// }
  ///
  /// let embedding = TursoVec.vector32Sparse("[0,0.5,0]")
  /// // vector32_sparse(?)
  /// // Only the component at index 1 is stored in the sparse result.
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector32_sparse(?))
  /// ```
  public static func vector32Sparse(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<SparseFloat32Vector> {
    Self.vector32Sparse(expression, as: SparseFloat32Vector.self)
  }

  /// Converts JSON with `vector32_sparse`, decoding into the requested matching representation.
  /// Fixed-size representations validate the decoded number of dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: SizedSparseFloat32Vector<3>.self)
  ///   var embedding: SizedSparseFloat32Vector<3>
  /// }
  ///
  /// let embedding = TursoVec.vector32Sparse("[0,0.5,0]", as: SizedSparseFloat32Vector<3>.self)
  /// // vector32_sparse(?)
  /// // Only the component at index 1 is stored in the sparse result.
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector32_sparse(?))
  /// ```
  public static func vector32Sparse<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding: TursoSparseFloat32Encoding {
    SQLQueryExpression("vector32_sparse(\(expression))")
  }

  #if swift(>=6.2)
    /// Converts a fixed-size vector while preserving its logical dimension count.
    ///
    /// ```swift
    /// let source = EmbeddingVector<8>([0.1, -0.2, 0, 0.4, 0, -0.6, 0, 0.8])
    /// let converted = TursoVec.vector32Sparse(source)
    /// // vector32_sparse(?)
    /// let components = TursoVec.extract(converted)
    /// // vector_extract(vector32_sparse(?))
    /// // The result retains eight logical dimensions for subsequent operations.
    /// ```
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public static func vector32Sparse<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
      _ expression: some QueryExpression<V>
    ) -> some QueryExpression<SizedSparseFloat32Vector<count>>
    where
      V.Encoding: TursoVectorEncoding,
      V.Dimensions == VectorDimensions<count>
    {
      Self.vector32Sparse(expression, as: SizedSparseFloat32Vector<count>.self)
    }
  #endif

  /// Converts a supported vector BLOB to a sparse Float32 vector with `vector32_sparse`.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: SparseFloat32Vector.self)
  ///   var embedding: SparseFloat32Vector
  /// }
  ///
  /// let source = TursoVec.vector32("[0, 0.5, 0]")
  /// // vector32(?)
  /// let embedding = TursoVec.vector32Sparse(source)
  /// // vector32_sparse(vector32(?))
  /// // Only the component at index 1 is stored in the sparse result.
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector32_sparse(vector32(?)))
  /// ```
  public static func vector32Sparse<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<SparseFloat32Vector>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    Self.vector32Sparse(expression, as: SparseFloat32Vector.self)
  }

  /// Preserves matching input and result dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector32Sparse($0.embedding, as: SizedSparseFloat32Vector<8>.self)
  /// }
  /// // SELECT vector32_sparse("documents"."embedding")
  /// // FROM "documents"
  /// ```
  public static func vector32Sparse<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoSparseFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    SQLQueryExpression("vector32_sparse(\(expression))")
  }

  /// Decodes a runtime-sized source with a checked result representation.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector32Sparse($0.embedding, as: SizedSparseFloat32Vector<8>.self)
  /// }
  /// // SELECT vector32_sparse("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector32Sparse<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoSparseFloat32Encoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vector32_sparse(\(expression))")
  }

  /// Returns a runtime-sized result from a known or runtime-sized source.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   @Column(as: EmbeddingVector<8>.VectorBytesRepresentation.self)
  ///   var embedding: EmbeddingVector<8>
  /// }
  /// let converted = Document.select {
  ///   TursoVec.vector32Sparse($0.embedding, as: SparseFloat32Vector.self)
  /// }
  /// // SELECT vector32_sparse("documents"."embedding")
  /// // FROM "documents"
  /// ```
  @_disfavoredOverload
  public static func vector32Sparse<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoSparseFloat32Encoding,
    T.Dimensions == Void
  {
    SQLQueryExpression("vector32_sparse(\(expression))")
  }

  /// Converts JSON to float32 using the `vector` alias.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let embedding = TursoVec.vector("[1,2,3]")
  /// // vector(?)
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector(?))
  /// ```
  public static func vector(
    _ expression: some QueryExpression<String>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation> {
    SQLQueryExpression("vector(\(expression))")
  }

  #if swift(>=6.2)
    /// Converts a fixed-size vector while preserving its logical dimension count.
    ///
    /// ```swift
    /// let source = EmbeddingVector<8>([0.1, -0.2, 0, 0.4, 0, -0.6, 0, 0.8])
    /// let converted = TursoVec.vector(source)
    /// // vector(?)
    /// let components = TursoVec.extract(converted)
    /// // vector_extract(vector(?))
    /// // The result retains eight logical dimensions for subsequent operations.
    /// ```
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public static func vector<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
      _ expression: some QueryExpression<V>
    ) -> some QueryExpression<EmbeddingVector<count>>
    where
      V.Encoding: TursoVectorEncoding,
      V.Dimensions == VectorDimensions<count>
    {
      SQLQueryExpression("vector(\(expression))")
    }
  #endif

  /// Converts a supported vector BLOB to Float32 using the `vector` alias.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var id: Int
  ///   @Column(as: [Float].VectorBytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let source = TursoVec.vector64("[1, 2, 3]")
  /// // vector64(?)
  /// let embedding = TursoVec.vector(source)
  /// // vector(vector64(?))
  /// let insert = Document.insert { ($0.id, $0.embedding) } values: {
  ///   (1, embedding)
  /// }
  /// // INSERT INTO "documents" ("id", "embedding") VALUES (?, vector(vector64(?)))
  /// ```
  public static func vector<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    SQLQueryExpression("vector(\(expression))")
  }

  /// Extracts a supported vector blob as a JSON array string with `vector_extract`.
  ///
  /// ```swift
  /// let expression = TursoVec.extract(TursoVec.vector32("[1,2,3]"))
  /// // vector_extract(vector32(?))
  /// ```
  public static func extract<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding: TursoVectorEncoding {
    SQLQueryExpression("vector_extract(\(expression))")
  }

  /// Returns cosine distance, including the binary Hamming specialization.
  /// Both operands must use the same supported Turso encoding.
  /// The database checks dimensions and value-dependent restrictions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  ///   var embedding: EmbeddingVector64<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(queryOutput: EmbeddingVector64<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: InlineQuantized8Vector<3>.self)
  ///   var embedding: InlineQuantized8Vector<3>
  /// }
  ///
  /// let queryVector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<3>
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<3>.TursoBytesRepresentation(queryOutput: BinaryEmbeddingVector<3>([true, false, true]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: SizedSparseFloat32Vector<3>.self)
  ///   var embedding: SizedSparseFloat32Vector<3>
  /// }
  ///
  /// let queryVector = try SizedSparseFloat32Vector<3>(indices: [1], values: [0.5])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceCosine($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_cos("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_cos(\(expression), \(vector))")
  }

  /// Returns Euclidean distance between matching vectors.
  /// Both operands must use the same supported numeric encoding and have equal dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  ///   var embedding: EmbeddingVector64<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(queryOutput: EmbeddingVector64<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: InlineQuantized8Vector<3>.self)
  ///   var embedding: InlineQuantized8Vector<3>
  /// }
  ///
  /// let queryVector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: SizedSparseFloat32Vector<3>.self)
  ///   var embedding: SizedSparseFloat32Vector<3>
  /// }
  ///
  /// let queryVector = try SizedSparseFloat32Vector<3>(indices: [1], values: [0.5])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: [Double].TursoFloat64BytesRepresentation.self)
  ///   var embedding: [Double]
  /// }
  ///
  /// let queryVector = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(queryOutput: EmbeddingVector64<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: Quantized8Vector.self)
  ///   var embedding: Quantized8Vector
  /// }
  ///
  /// let queryVector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: SparseFloat32Vector.self)
  ///   var embedding: SparseFloat32Vector
  /// }
  ///
  /// let queryVector = try SizedSparseFloat32Vector<3>(indices: [1], values: [0.5])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  ///   var embedding: EmbeddingVector64<3>
  /// }
  ///
  /// let queryVector: [Double].TursoFloat64BytesRepresentation = [0.2, 0.4, 0.6]
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: InlineQuantized8Vector<3>.self)
  ///   var embedding: InlineQuantized8Vector<3>
  /// }
  ///
  /// let queryVector = try Quantized8Vector(quantizing: [0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: SizedSparseFloat32Vector<3>.self)
  ///   var embedding: SizedSparseFloat32Vector<3>
  /// }
  ///
  /// let queryVector = try SparseFloat32Vector(dimensions: 3, indices: [1], values: [0.5])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceL2($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_l2("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_l2(\(expression), \(vector))")
  }

  /// Returns the negative dot product between matching vectors.
  /// Both operands must use the same supported Turso encoding.
  /// The database checks dimensions and value-dependent restrictions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceDot($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_dot("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  ///   var embedding: EmbeddingVector64<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(queryOutput: EmbeddingVector64<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceDot($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_dot("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: InlineQuantized8Vector<3>.self)
  ///   var embedding: InlineQuantized8Vector<3>
  /// }
  ///
  /// let queryVector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceDot($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_dot("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<3>
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<3>.TursoBytesRepresentation(queryOutput: BinaryEmbeddingVector<3>([true, false, true]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceDot($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_dot("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: SizedSparseFloat32Vector<3>.self)
  ///   var embedding: SizedSparseFloat32Vector<3>
  /// }
  ///
  /// let queryVector = try SizedSparseFloat32Vector<3>(indices: [1], values: [0.5])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceDot($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_dot("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceDot($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_dot("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceDot($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_dot("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_dot(\(expression), \(vector))")
  }

  /// Returns weighted numeric Jaccard distance or binary set Jaccard distance.
  /// Both operands must use the same supported Turso encoding.
  /// The database checks dimensions and value-dependent restrictions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceJaccard($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_jaccard("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector64<3>.TursoFloat64BytesRepresentation.self)
  ///   var embedding: EmbeddingVector64<3>
  /// }
  ///
  /// let queryVector = EmbeddingVector64<3>.TursoFloat64BytesRepresentation(queryOutput: EmbeddingVector64<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceJaccard($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_jaccard("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: InlineQuantized8Vector<3>.self)
  ///   var embedding: InlineQuantized8Vector<3>
  /// }
  ///
  /// let queryVector = try InlineQuantized8Vector<3>(quantizing: EmbeddingVector<3>([0.2, 0.4, 0.6]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceJaccard($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_jaccard("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: BinaryEmbeddingVector<3>.TursoBytesRepresentation.self)
  ///   var embedding: BinaryEmbeddingVector<3>
  /// }
  ///
  /// let queryVector = BinaryEmbeddingVector<3>.TursoBytesRepresentation(queryOutput: BinaryEmbeddingVector<3>([true, false, true]))
  /// let neighbors = Document
  ///   .order { TursoVec.distanceJaccard($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_jaccard("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: SizedSparseFloat32Vector<3>.self)
  ///   var embedding: SizedSparseFloat32Vector<3>
  /// }
  ///
  /// let queryVector = try SizedSparseFloat32Vector<3>(indices: [1], values: [0.5])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceJaccard($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_jaccard("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Allows a runtime-sized left operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: [Float].TursoFloat32BytesRepresentation.self)
  ///   var embedding: [Float]
  /// }
  ///
  /// let queryVector = EmbeddingVector<3>([0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceJaccard($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_jaccard("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Allows a runtime-sized right operand; the database checks matching dimensions.
  ///
  /// ```swift
  /// @Table("documents")
  /// struct Document {
  ///   var content: String
  ///   @Column(as: EmbeddingVector<3>.TursoFloat32BytesRepresentation.self)
  ///   var embedding: EmbeddingVector<3>
  /// }
  ///
  /// let queryVector = [Float].VectorBytesRepresentation(queryOutput: [0.2, 0.4, 0.6])
  /// let neighbors = Document
  ///   .order { TursoVec.distanceJaccard($0.embedding, to: queryVector) }
  ///   .limit(5)
  ///   .select(\.content)
  /// // SELECT "documents"."content"
  /// // FROM "documents"
  /// // ORDER BY vector_distance_jaccard("documents"."embedding", ?)
  /// // LIMIT ?
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    SQLQueryExpression("vector_distance_jaccard(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Returns an array representation so the output dimension count can change.
  ///
  /// ```swift
  /// let title = TursoVec.vector32("[0.1,0.2,0.3]")
  /// // vector32(?)
  /// let body = TursoVec.vector32("[0.4,0.5,0.6]")
  /// // vector32(?)
  /// let combined = TursoVec.concat(title, body)
  /// // vector_concat(vector32(?), vector32(?))
  /// // Combines the two three-component embeddings into six components.
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let title = TursoVec.vector32("[0.1,0.2,0.3]")
  /// // vector32(?)
  /// let body = TursoVec.vector32("[0.4,0.5,0.6]")
  /// // vector32(?)
  /// let combined = TursoVec.concat(title, body, as: EmbeddingVector<6>.self)
  /// // vector_concat(vector32(?), vector32(?))
  /// // Combines the two three-component embeddings into six components.
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Returns an array representation so the output dimension count can change.
  ///
  /// ```swift
  /// let title = TursoVec.vector64("[0.1,0.2,0.3]")
  /// // vector64(?)
  /// let body = TursoVec.vector64("[0.4,0.5,0.6]")
  /// // vector64(?)
  /// let combined = TursoVec.concat(title, body)
  /// // vector_concat(vector64(?), vector64(?))
  /// // Combines the two three-component embeddings into six components.
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation>
  where L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Concatenates two matching vectors; the result has the sum of their dimensions.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let title = TursoVec.vector64("[0.1,0.2,0.3]")
  /// // vector64(?)
  /// let body = TursoVec.vector64("[0.4,0.5,0.6]")
  /// // vector64(?)
  /// let combined = TursoVec.concat(title, body, as: EmbeddingVector64<6>.TursoFloat64BytesRepresentation.self)
  /// // vector_concat(vector64(?), vector64(?))
  /// // Combines the two three-component embeddings into six components.
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    SQLQueryExpression("vector_concat(\(expression), \(vector))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[0.1,0.2,0.3]")
  /// // vector32(?)
  /// let prefix = TursoVec.slice(vector, from: 0, to: 2)
  /// // vector_slice(vector32(?), ?, ?)
  /// // Retains the first two logical components.
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding: TursoFloat32Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32("[0.1,0.2,0.3]")
  /// // vector32(?)
  /// let prefix = TursoVec.slice(vector, from: 0, to: 2, as: EmbeddingVector<2>.self)
  /// // vector_slice(vector32(?), ?, ?)
  /// // Retains the first two logical components.
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoFloat32Encoding, T.Encoding == V.Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[0.1,0.2,0.3]")
  /// // vector64(?)
  /// let prefix = TursoVec.slice(vector, from: 0, to: 2)
  /// // vector_slice(vector64(?), ?, ?)
  /// // Retains the first two logical components.
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation>
  where V.Encoding: TursoFloat64Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector64("[0.1,0.2,0.3]")
  /// // vector64(?)
  /// let prefix = TursoVec.slice(
  ///   vector,
  ///   from: 0,
  ///   to: 2,
  ///   as: EmbeddingVector64<2>.TursoFloat64BytesRepresentation.self
  /// )
  /// // vector_slice(vector64(?), ?, ?)
  /// // Retains the first two logical components.
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoFloat64Encoding, T.Encoding == V.Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Returns a variable-size representation so the output dimension count can change.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[0.1,0.2,0.3]")
  /// // vector32_sparse(?)
  /// let prefix = TursoVec.slice(vector, from: 0, to: 2)
  /// // vector_slice(vector32_sparse(?), ?, ?)
  /// // Retains the first two logical components.
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<SparseFloat32Vector>
  where V.Encoding: TursoSparseFloat32Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }

  /// Extracts dimensions from the zero-based start index through the exclusive end index.
  /// Decodes with the requested matching representation, including fixed-dimension validation.
  ///
  /// ```swift
  /// let vector = TursoVec.vector32Sparse("[0.1,0.2,0.3]")
  /// // vector32_sparse(?)
  /// let prefix = TursoVec.slice(vector, from: 0, to: 2, as: SizedSparseFloat32Vector<2>.self)
  /// // vector_slice(vector32_sparse(?), ?, ?)
  /// // Retains the first two logical components.
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding: TursoSparseFloat32Encoding, T.Encoding == V.Encoding {
    SQLQueryExpression("vector_slice(\(expression), \(start), \(end))")
  }
}
