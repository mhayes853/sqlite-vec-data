import StructuredQueriesCore

extension TursoVec {
  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceHamming(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceHamming(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceHamming(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceHamming(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceHamming(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceHamming(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceHamming(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceHamming(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].TursoBytesRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = TursoVec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoBinaryEncoding, R.Encoding == L.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceHamming(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector32(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32(?) END
  /// ```
  public static func vector32(
    _ expression: some QueryExpression<String?>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?> {
    let value = Self.vector32(SQLQueryExpression<String>(expression.queryFragment))
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32(?) END
  /// ```
  public static func vector32<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String?>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding: TursoFloat32Encoding {
    let value = Self.vector32(SQLQueryExpression<String>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func vector32<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<EmbeddingVector<count>?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.vector32(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<EmbeddingVector<count>?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32(?) END
  /// ```
  public static func vector32<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    let value = Self.vector32(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32(?) END
  /// ```
  public static func vector32<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.vector32(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32(?) END
  /// ```
  @_disfavoredOverload
  public static func vector32<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat32Encoding,
    V.Dimensions == Void
  {
    let value = Self.vector32(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32(?) END
  /// ```
  @_disfavoredOverload
  public static func vector32<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat32Encoding,
    T.Dimensions == Void
  {
    let value = Self.vector32(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector64(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector64(?) END
  /// ```
  public static func vector64(
    _ expression: some QueryExpression<String?>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation?> {
    let value = Self.vector64(SQLQueryExpression<String>(expression.queryFragment))
    return SQLQueryExpression<[Double].TursoFloat64BytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector64(?) END
  /// ```
  public static func vector64<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String?>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding: TursoFloat64Encoding {
    let value = Self.vector64(SQLQueryExpression<String>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector64(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector64(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func vector64<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<EmbeddingVector64<count>.TursoFloat64BytesRepresentation?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.vector64(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<EmbeddingVector64<count>.TursoFloat64BytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector64(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector64(?) END
  /// ```
  public static func vector64<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    let value = Self.vector64(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<[Double].TursoFloat64BytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector64(?) END
  /// ```
  public static func vector64<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat64Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.vector64(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector64(?) END
  /// ```
  @_disfavoredOverload
  public static func vector64<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat64Encoding,
    V.Dimensions == Void
  {
    let value = Self.vector64(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector64(expression, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector64(?) END
  /// ```
  @_disfavoredOverload
  public static func vector64<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoFloat64Encoding,
    T.Dimensions == Void
  {
    let value = Self.vector64(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector8(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector8(?) END
  /// ```
  public static func vector8(
    _ expression: some QueryExpression<String?>
  ) -> some QueryExpression<Quantized8Vector?> {
    let value = Self.vector8(SQLQueryExpression<String>(expression.queryFragment))
    return SQLQueryExpression<Quantized8Vector?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector8(expression, as: Quantized8Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector8(?) END
  /// ```
  public static func vector8<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String?>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding: TursoQuantized8Encoding {
    let value = Self.vector8(SQLQueryExpression<String>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector8(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector8(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func vector8<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<InlineQuantized8Vector<count>?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.vector8(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<InlineQuantized8Vector<count>?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector8(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector8(?) END
  /// ```
  public static func vector8<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<Quantized8Vector?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    let value = Self.vector8(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<Quantized8Vector?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector8(expression, as: Quantized8Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector8(?) END
  /// ```
  public static func vector8<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoQuantized8Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.vector8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector8(expression, as: Quantized8Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector8(?) END
  /// ```
  @_disfavoredOverload
  public static func vector8<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoQuantized8Encoding,
    V.Dimensions == Void
  {
    let value = Self.vector8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector8(expression, as: Quantized8Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector8(?) END
  /// ```
  @_disfavoredOverload
  public static func vector8<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoQuantized8Encoding,
    T.Dimensions == Void
  {
    let value = Self.vector8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector1bit(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector1bit(?) END
  /// ```
  public static func vector1bit(
    _ expression: some QueryExpression<String?>
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation?> {
    let value = Self.vector1bit(SQLQueryExpression<String>(expression.queryFragment))
    return SQLQueryExpression<[Bool].TursoBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector1bit(?) END
  /// ```
  public static func vector1bit<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String?>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding: TursoBinaryEncoding {
    let value = Self.vector1bit(SQLQueryExpression<String>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector1bit(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector1bit(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func vector1bit<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<BinaryEmbeddingVector<count>.TursoBytesRepresentation?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.vector1bit(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<BinaryEmbeddingVector<count>.TursoBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector1bit(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector1bit(?) END
  /// ```
  public static func vector1bit<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<[Bool].TursoBytesRepresentation?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    let value = Self.vector1bit(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<[Bool].TursoBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector1bit(?) END
  /// ```
  public static func vector1bit<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoBinaryEncoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.vector1bit(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector1bit(?) END
  /// ```
  @_disfavoredOverload
  public static func vector1bit<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoBinaryEncoding,
    V.Dimensions == Void
  {
    let value = Self.vector1bit(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector1bit(expression, as: [Bool].TursoBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector1bit(?) END
  /// ```
  @_disfavoredOverload
  public static func vector1bit<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoBinaryEncoding,
    T.Dimensions == Void
  {
    let value = Self.vector1bit(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector32Sparse(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32_sparse(?) END
  /// ```
  public static func vector32Sparse(
    _ expression: some QueryExpression<String?>
  ) -> some QueryExpression<SparseFloat32Vector?> {
    let value = Self.vector32Sparse(SQLQueryExpression<String>(expression.queryFragment))
    return SQLQueryExpression<SparseFloat32Vector?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector32Sparse(expression, as: SparseFloat32Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32_sparse(?) END
  /// ```
  public static func vector32Sparse<T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<String?>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding: TursoSparseFloat32Encoding {
    let value = Self.vector32Sparse(
      SQLQueryExpression<String>(expression.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32Sparse(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32_sparse(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func vector32Sparse<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<SizedSparseFloat32Vector<count>?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.vector32Sparse(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<SizedSparseFloat32Vector<count>?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32Sparse(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32_sparse(?) END
  /// ```
  public static func vector32Sparse<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<SparseFloat32Vector?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    let value = Self.vector32Sparse(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<SparseFloat32Vector?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32Sparse(expression, as: SparseFloat32Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32_sparse(?) END
  /// ```
  public static func vector32Sparse<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoSparseFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.vector32Sparse(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32Sparse(expression, as: SparseFloat32Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32_sparse(?) END
  /// ```
  @_disfavoredOverload
  public static func vector32Sparse<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoSparseFloat32Encoding,
    V.Dimensions == Void
  {
    let value = Self.vector32Sparse(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector32Sparse(expression, as: SparseFloat32Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector32_sparse(?) END
  /// ```
  @_disfavoredOverload
  public static func vector32Sparse<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: TursoVectorEncoding, T.Encoding: TursoSparseFloat32Encoding,
    T.Dimensions == Void
  {
    let value = Self.vector32Sparse(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = TursoVec.vector(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector(?) END
  /// ```
  public static func vector(
    _ expression: some QueryExpression<String?>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?> {
    let value = Self.vector(SQLQueryExpression<String>(expression.queryFragment))
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func vector<let count: Int, V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<EmbeddingVector<count>?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.vector(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<EmbeddingVector<count>?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.vector(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector(?) END
  /// ```
  public static func vector<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where
    V.Encoding: TursoVectorEncoding,
    V.Dimensions == Void
  {
    let value = Self.vector(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.extract(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_extract(?) END
  /// ```
  public static func extract<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<String?> where V.Encoding: TursoVectorEncoding {
    let value = Self.extract(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<String?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceCosine(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceCosine(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceCosine(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceCosine(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceCosine(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceCosine(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceCosine(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceCosine(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_cos(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceCosine(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceL2(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceL2(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceL2(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceL2(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceL2(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceL2(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceL2(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceL2(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoNumericVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceL2(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceDot(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceDot(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceDot(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceDot(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceDot(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceDot(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceDot(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceDot(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceDot(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_dot(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceDot<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceDot(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceJaccard(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceJaccard(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == R.Dimensions
  {
    let value = Self.distanceJaccard(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceJaccard(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceJaccard(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    L.Dimensions == Void
  {
    let value = Self.distanceJaccard(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceJaccard(SQLQueryExpression<L>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceJaccard(expression, to: SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.distanceJaccard(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_distance_jaccard(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceJaccard<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    to vector: some QueryExpression<R?>
  ) -> some QueryExpression<Double?>
  where
    L.Encoding: TursoVectorEncoding, L.Encoding == R.Encoding,
    R.Dimensions == Void
  {
    let value = Self.distanceJaccard(
      SQLQueryExpression<L>(expression.queryFragment),
      to: SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding {
    let value = Self.concat(SQLQueryExpression<L>(expression.queryFragment), vector)
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R?>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding {
    let value = Self.concat(expression, SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R?>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding {
    let value = Self.concat(
      SQLQueryExpression<L>(expression.queryFragment),
      SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    let value = Self.concat(SQLQueryExpression<L>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    let value = Self.concat(expression, SQLQueryExpression<R>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    L.Encoding: TursoFloat32Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    let value = Self.concat(
      SQLQueryExpression<L>(expression.queryFragment),
      SQLQueryExpression<R>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation?>
  where L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding {
    let value = Self.concat(SQLQueryExpression<L>(expression.queryFragment), vector)
    return SQLQueryExpression<[Double].TursoFloat64BytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R?>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation?>
  where L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding {
    let value = Self.concat(expression, SQLQueryExpression<R>(vector.queryFragment))
    return SQLQueryExpression<[Double].TursoFloat64BytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R?>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation?>
  where L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding {
    let value = Self.concat(
      SQLQueryExpression<L>(expression.queryFragment),
      SQLQueryExpression<R>(vector.queryFragment)
    )
    return SQLQueryExpression<[Double].TursoFloat64BytesRepresentation?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Double].TursoFloat64BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    let value = Self.concat(SQLQueryExpression<L>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L>,
    _ vector: some QueryExpression<R?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    let value = Self.concat(expression, SQLQueryExpression<R>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.concat(expression, vector, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vector_concat(?, ?) END
  /// ```
  public static func concat<
    L: VectorBytesRepresentable & QueryBindable,
    R: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<L?>,
    _ vector: some QueryExpression<R?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    L.Encoding: TursoFloat64Encoding, L.Encoding == R.Encoding,
    T.Encoding == L.Encoding
  {
    let value = Self.concat(
      SQLQueryExpression<L>(expression.queryFragment),
      SQLQueryExpression<R>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.slice(expression, from: 0, to: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_slice(?, ?, ?) END
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where V.Encoding: TursoFloat32Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), from: start, to: end)
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.slice(expression, from: 0, to: 4, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_slice(?, ?, ?) END
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where V.Encoding: TursoFloat32Encoding, T.Encoding == V.Encoding {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      from: start,
      to: end,
      as: result
    )
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.slice(expression, from: 0, to: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_slice(?, ?, ?) END
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<[Double].TursoFloat64BytesRepresentation?>
  where V.Encoding: TursoFloat64Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), from: start, to: end)
    return SQLQueryExpression<[Double].TursoFloat64BytesRepresentation?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Double].TursoFloat64BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = TursoVec.slice(expression, from: 0, to: 4, as: [Double].TursoFloat64BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_slice(?, ?, ?) END
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where V.Encoding: TursoFloat64Encoding, T.Encoding == V.Encoding {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      from: start,
      to: end,
      as: result
    )
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: SparseFloat32Vector? = try SparseFloat32Vector(compressing: [1, -2, 0, 4, 0, 0, 1, 0])
  /// let result = TursoVec.slice(expression, from: 0, to: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_slice(?, ?, ?) END
  /// ```
  public static func slice<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>
  ) -> some QueryExpression<SparseFloat32Vector?>
  where V.Encoding: TursoSparseFloat32Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), from: start, to: end)
    return SQLQueryExpression<SparseFloat32Vector?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: SparseFloat32Vector? = try SparseFloat32Vector(compressing: [1, -2, 0, 4, 0, 0, 1, 0])
  /// let result = TursoVec.slice(expression, from: 0, to: 4, as: SparseFloat32Vector.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vector_slice(?, ?, ?) END
  /// ```
  public static func slice<
    V: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    from start: some QueryExpression<Int>,
    to end: some QueryExpression<Int>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where V.Encoding: TursoSparseFloat32Encoding, T.Encoding == V.Encoding {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      from: start,
      to: end,
      as: result
    )
    return SQLQueryExpression<T?>(
      tursoVectorNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }
}

private func tursoVectorNullGuard(_ expression: QueryFragment, checking values: [QueryFragment])
  -> QueryFragment
{
  let missing = values.map { "(\($0)) IS NULL" as QueryFragment }.joined(separator: " OR ")
  return "CASE WHEN \(missing) THEN NULL ELSE \(expression) END"
}
