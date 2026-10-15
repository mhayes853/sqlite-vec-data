import StructuredQueriesCore

extension Vec {
  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL2(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL2(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL2(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL2(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL2(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL2(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL2(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL2(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL2(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL2(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL1(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL1(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL1(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL1(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL1(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL1(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL1(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL1(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL1(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceCosine(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceCosine(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceCosine(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceCosine(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceCosine(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceCosine(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceCosine(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceCosine(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceCosine(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceCosine(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceHamming(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceHamming(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceHamming(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceHamming(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceHamming(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceHamming(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceHamming(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceHamming(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.distanceHamming(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable
  >(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceHamming(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.length(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_length(?) END
  /// ```
  public static func length<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<Int?> where V.Encoding: SQLiteVecVectorEncoding {
    let value = Self.length(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<Int?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.type(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_type(?) END
  /// ```
  public static func type<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<String?> where V.Encoding: SQLiteVecVectorEncoding {
    let value = Self.type(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<String?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.toJSON(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_to_json(?) END
  /// ```
  public static func toJSON<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<String?> where V.Encoding: SQLiteVecVectorEncoding {
    let value = Self.toJSON(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<String?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector)
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<W?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector)
    return SQLQueryExpression<W?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<W?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<W?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<W?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<W?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.add(SQLQueryExpression<V>(expression.queryFragment), vector)
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.add(expression, SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.add(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func add<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.add(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions, T.Dimensions == V.Dimensions
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == W.Dimensions
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == V.Dimensions
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    T.Dimensions == Void, V.Dimensions == W.Dimensions
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, W.Dimensions == Void
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    V.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector, as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    T.Encoding == V.Encoding,
    W.Dimensions == Void, T.Dimensions == Void
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment),
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector)
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<W?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector)
    return SQLQueryExpression<W?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<W?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<W?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<W?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<W?>(
      sqliteVecNullGuard(
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
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.sub(SQLQueryExpression<V>(expression.queryFragment), vector)
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.sub(expression, SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.sub(expression, vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public static func sub<V: VectorBytesRepresentable & QueryBindable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    _ vector: some QueryExpression<W?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecNumericEncoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.sub(
      SQLQueryExpression<V>(expression.queryFragment),
      SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, start: 0, end: 4, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    start: Int,
    end: Int,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      start: start,
      end: end,
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, start: 0, end: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where V.Encoding: SQLiteVecFloat32Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), start: start, end: end)
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, range: 0..<4, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    range: Range<Int>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      range: range,
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, range: 0..<4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    range: Range<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where V.Encoding: SQLiteVecFloat32Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), range: range)
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, range: 0...3, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    range: ClosedRange<Int>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      range: range,
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, range: 0...3)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where V.Encoding: SQLiteVecFloat32Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), range: range)
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, start: 0, length: 4, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    start: Int,
    length: Int,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecVectorEncoding, T.Encoding == V.Encoding
  {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      start: start,
      length: length,
      as: result
    )
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, start: 0, length: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where V.Encoding: SQLiteVecFloat32Encoding {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      start: start,
      length: length
    )
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.normalize(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_normalize(?) END
  /// ```
  public static func normalize<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.normalize(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.normalize(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_normalize(?) END
  /// ```
  @_disfavoredOverload
  public static func normalize<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == Void
  {
    let value = Self.normalize(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.normalize(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_normalize(?) END
  /// ```
  @_disfavoredOverload
  public static func normalize<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    T.Dimensions == Void
  {
    let value = Self.normalize(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.normalize(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_normalize(?) END
  /// ```
  public static func normalize<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding: SQLiteVecFloat32Encoding
  {
    let value = Self.normalize(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.f32(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  public static func f32<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.f32(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.f32(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  @_disfavoredOverload
  public static func f32<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == Void
  {
    let value = Self.f32(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.f32(expression, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  @_disfavoredOverload
  public static func f32<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    T.Encoding: SQLiteVecFloat32Encoding,
    T.Dimensions == Void
  {
    let value = Self.f32(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.f32(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  public static func f32<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where V.Encoding: SQLiteVecFloat32Encoding {
    let value = Self.f32(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.f32(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  @_disfavoredOverload
  public static func f32<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<V.VectorBytesRepresentation?>
  where V.Encoding: SQLiteVecFloat32Encoding {
    let value = Self.f32(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<V.VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let json: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = Vec.f32(json)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  public static func f32(
    _ json: some QueryExpression<String?>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation?> {
    let value = Self.f32(SQLQueryExpression<String>(json.queryFragment))
    return SQLQueryExpression<[Float].VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [json.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let json: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = Vec.f32(json, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  public static func f32<T: VectorBytesRepresentable & QueryBindable>(
    _ json: some QueryExpression<String?>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding: SQLiteVecFloat32Encoding {
    let value = Self.f32(SQLQueryExpression<String>(json.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [json.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeInt8(expression, as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  public static func quantizeInt8<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.quantizeInt8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeInt8(expression, as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  @_disfavoredOverload
  public static func quantizeInt8<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == Void
  {
    let value = Self.quantizeInt8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeInt8(expression, as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  @_disfavoredOverload
  public static func quantizeInt8<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecFloat32Encoding, T.Encoding: SQLiteVecInt8Encoding,
    T.Dimensions == Void
  {
    let value = Self.quantizeInt8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeInt8(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func quantizeInt8<let count: Int, V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.quantizeInt8(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeInt8(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  public static func quantizeInt8<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where
    V.Encoding: SQLiteVecFloat32Encoding,
    V.Dimensions == Void
  {
    let value = Self.quantizeInt8(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<[Int8].Int8BytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  public static func quantizeBinary<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.quantizeBinary(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  @_disfavoredOverload
  public static func quantizeBinary<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == Void
  {
    let value = Self.quantizeBinary(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  @_disfavoredOverload
  public static func quantizeBinary<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecNumericEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void
  {
    let value = Self.quantizeBinary(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeBinary(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public static func quantizeBinary<let count: Int, V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<BinaryEmbeddingVector<count>.PackedBitsRepresentation?>
  where
    V.Encoding: SQLiteVecNumericEncoding,
    V.Dimensions == VectorDimensions<count>
  {
    let value = Self.quantizeBinary(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<BinaryEmbeddingVector<count>.PackedBitsRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.quantizeBinary(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  public static func quantizeBinary<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where
    V.Encoding: SQLiteVecNumericEncoding,
    V.Dimensions == Void
  {
    let value = Self.quantizeBinary(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<[Bool].PackedBitsRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.slice(expression, start: 0, end: 8)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where V.Encoding: SQLiteVecBinaryEncoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), start: start, end: end)
    return SQLQueryExpression<[Bool].PackedBitsRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.slice(expression, range: 0..<8)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    range: Range<Int>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where V.Encoding: SQLiteVecBinaryEncoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), range: range)
    return SQLQueryExpression<[Bool].PackedBitsRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.slice(expression, range: 0...7)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where V.Encoding: SQLiteVecBinaryEncoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), range: range)
    return SQLQueryExpression<[Bool].PackedBitsRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.slice(expression, start: 0, length: 8)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where V.Encoding: SQLiteVecBinaryEncoding {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      start: start,
      length: length
    )
    return SQLQueryExpression<[Bool].PackedBitsRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.bit(expression, as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.bit(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.bit(expression, as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  @_disfavoredOverload
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    V.Dimensions == Void
  {
    let value = Self.bit(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.bit(expression, as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  @_disfavoredOverload
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecBinaryEncoding, T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void
  {
    let value = Self.bit(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.bit(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  public static func bit<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where V.Encoding: SQLiteVecBinaryEncoding {
    let value = Self.bit(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = Vec.bit(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  @_disfavoredOverload
  public static func bit<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<V.VectorBytesRepresentation?>
  where V.Encoding: SQLiteVecBinaryEncoding {
    let value = Self.bit(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<V.VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.int8(expression, as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecInt8Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == T.Dimensions
  {
    let value = Self.int8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.int8(expression, as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  @_disfavoredOverload
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecInt8Encoding, T.Encoding: SQLiteVecInt8Encoding,
    V.Dimensions == Void
  {
    let value = Self.int8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.int8(expression, as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  @_disfavoredOverload
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>,
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    V.Encoding: SQLiteVecInt8Encoding, T.Encoding: SQLiteVecInt8Encoding,
    T.Dimensions == Void
  {
    let value = Self.int8(SQLQueryExpression<V>(expression.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.int8(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  public static func int8<V: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where V.Encoding: SQLiteVecInt8Encoding {
    let value = Self.int8(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<V?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.int8(expression)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  @_disfavoredOverload
  public static func int8<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>
  ) -> some QueryExpression<V.VectorBytesRepresentation?>
  where V.Encoding: SQLiteVecInt8Encoding {
    let value = Self.int8(SQLQueryExpression<V>(expression.queryFragment))
    return SQLQueryExpression<V.VectorBytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let json: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = Vec.int8(json, as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  public static func int8<T: VectorBytesRepresentable & QueryBindable>(
    _ json: some QueryExpression<String?>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding: SQLiteVecInt8Encoding {
    let value = Self.int8(SQLQueryExpression<String>(json.queryFragment), as: result)
    return SQLQueryExpression<T?>(
      sqliteVecNullGuard(value.queryFragment, checking: [json.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let json: String? = "[1,-2,0,4,0,0,1,0]"
  /// let result = Vec.int8(json)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  public static func int8(
    _ json: some QueryExpression<String?>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation?> {
    let value = Self.int8(SQLQueryExpression<String>(json.queryFragment))
    return SQLQueryExpression<[Int8].Int8BytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [json.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL1(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL1(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == W.Dimensions
  {
    let value = Self.distanceL1(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL1(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL1(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    V.Dimensions == Void
  {
    let value = Self.distanceL1(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL1(SQLQueryExpression<V>(expression.queryFragment), to: vector)
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL1(expression, to: SQLQueryExpression<W>(vector.queryFragment))
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(value.queryFragment, checking: [vector.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.distanceL1(expression, to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    to vector: some QueryExpression<W?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding: SQLiteVecInt8Encoding, W.Encoding == V.Encoding,
    W.Dimensions == Void
  {
    let value = Self.distanceL1(
      SQLQueryExpression<V>(expression.queryFragment),
      to: SQLQueryExpression<W>(vector.queryFragment)
    )
    return SQLQueryExpression<Double?>(
      sqliteVecNullGuard(
        value.queryFragment,
        checking: [expression.queryFragment, vector.queryFragment]
      )
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, start: 0, end: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where V.Encoding: SQLiteVecInt8Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), start: start, end: end)
    return SQLQueryExpression<[Int8].Int8BytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, range: 0..<4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    range: Range<Int>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where V.Encoding: SQLiteVecInt8Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), range: range)
    return SQLQueryExpression<[Int8].Int8BytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, range: 0...3)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where V.Encoding: SQLiteVecInt8Encoding {
    let value = Self.slice(SQLQueryExpression<V>(expression.queryFragment), range: range)
    return SQLQueryExpression<[Int8].Int8BytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let expression: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = Vec.slice(expression, start: 0, length: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V?>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where V.Encoding: SQLiteVecInt8Encoding {
    let value = Self.slice(
      SQLQueryExpression<V>(expression.queryFragment),
      start: start,
      length: length
    )
    return SQLQueryExpression<[Int8].Int8BytesRepresentation?>(
      sqliteVecNullGuard(value.queryFragment, checking: [expression.queryFragment])
    )
  }
}

private func sqliteVecNullGuard(_ expression: QueryFragment, checking values: [QueryFragment])
  -> QueryFragment
{
  let missing = values.map { "(\($0)) IS NULL" as QueryFragment }.joined(separator: " OR ")
  return "CASE WHEN \(missing) THEN NULL ELSE \(expression) END"
}

extension QueryExpression
where
  QueryValue: VectorBytesRepresentable & QueryBindable,
  QueryValue.Encoding: SQLiteVecVectorEncoding
{
  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(self, vector, as: QueryValue.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(self, vector, as: V.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue?>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(self, vector, as: QueryValue.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(self, vector, as: QueryValue.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(self, vector, as: V.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue?>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(self, vector, as: QueryValue.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == V.Dimensions,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    QueryValue.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(self, to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Encoding,
    V.Dimensions == Void,
    QueryValue.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(self, to: vector)
  }
}

extension QueryExpression
where
  QueryValue: _OptionalProtocol,
  QueryValue.Wrapped: VectorBytesRepresentable & QueryBindable,
  QueryValue.Wrapped.Encoding: SQLiteVecVectorEncoding
{
  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL2(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l2(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceL2(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_l1(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceCosine(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_cosine(?, ?) END
  /// ```
  @_disfavoredOverload
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.distanceCosine(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.length()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_length(?) END
  /// ```
  public func length() -> some QueryExpression<Int?> {
    Vec.length(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment))
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.type()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_type(?) END
  /// ```
  public func type() -> some QueryExpression<String?> {
    Vec.type(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment))
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.toJSON()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_to_json(?) END
  /// ```
  public func toJSON() -> some QueryExpression<String?> {
    Vec.toJSON(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment))
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<V?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), vector, as: V.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), vector, as: V.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.add(vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_add(?, ?) END
  /// ```
  @_disfavoredOverload
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.add(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<V?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), vector, as: V.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable & QueryBindable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<V?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), vector, as: V.self)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.sub(vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_sub(?, ?) END
  /// ```
  @_disfavoredOverload
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V?>
  ) -> some QueryExpression<QueryValue.Wrapped?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.sub(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      vector,
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(start: 0, end: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<
    [Float].VectorBytesRepresentation?
  >
  where
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), start: start, end: end)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(start: 0, end: 4, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    start: Int,
    end: Int,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding == QueryValue.Wrapped.Encoding {
    Vec.slice(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      start: start,
      end: end,
      as: result
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(0..<4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Float].VectorBytesRepresentation?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(0..<4, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    _ range: Range<Int>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding == QueryValue.Wrapped.Encoding {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range, as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(0...3)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Float].VectorBytesRepresentation?
  >
  where
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(0...3, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    _ range: ClosedRange<Int>,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding == QueryValue.Wrapped.Encoding {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range, as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(start: 0, length: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<
    [Float].VectorBytesRepresentation?
  >
  where
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.slice(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      start: start,
      length: length
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(start: 0, length: 4, as: [Float].VectorBytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(?, 0, 4) END
  /// ```
  public func slice<T: VectorBytesRepresentable & QueryBindable>(
    start: Int,
    length: Int,
    as result: T.Type
  ) -> some QueryExpression<T?> where T.Encoding == QueryValue.Wrapped.Encoding {
    Vec.slice(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      start: start,
      length: length,
      as: result
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.normalize()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_normalize(?) END
  /// ```
  public func normalize() -> some QueryExpression<QueryValue.Wrapped?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.normalize(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.f32()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_f32(?) END
  /// ```
  public func f32() -> some QueryExpression<QueryValue.Wrapped?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.f32(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeInt8()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public func quantizeInt8<let count: Int>() -> some QueryExpression<
    FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation?
  >
  where
    QueryValue.Wrapped.Dimensions == VectorDimensions<count>,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      as: FixedEmbeddingVector<count, Int8>.Int8BytesRepresentation.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeInt8()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  public func quantizeInt8() -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment))
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeInt8(as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  public func quantizeInt8<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecInt8Encoding,
    QueryValue.Wrapped.Dimensions == T.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeInt8(as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  @_disfavoredOverload
  public func quantizeInt8<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecInt8Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeInt8(as: [Int8].Int8BytesRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_int8(?, 'unit') END
  /// ```
  @_disfavoredOverload
  public func quantizeInt8<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecInt8Encoding,
    T.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecFloat32Encoding
  {
    Vec.quantizeInt8(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeBinary()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  public func quantizeBinary<let count: Int>() -> some QueryExpression<
    BinaryEmbeddingVector<count>.PackedBitsRepresentation?
  >
  where
    QueryValue.Wrapped.Dimensions == VectorDimensions<count>,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      as: BinaryEmbeddingVector<count>.PackedBitsRepresentation.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeBinary()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  public func quantizeBinary() -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment))
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeBinary(as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Wrapped.Dimensions == T.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeBinary(as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  @_disfavoredOverload
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Float].VectorBytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.quantizeBinary(as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_quantize_binary(?) END
  /// ```
  @_disfavoredOverload
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecNumericEncoding
  {
    Vec.quantizeBinary(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let vector: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.distanceL1(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE CAST(vec_distance_l1(vec_int8(?), vec_int8(?)) AS REAL) END
  /// ```
  @_disfavoredOverload
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.distanceL1(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(start: 0, end: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), start: start, end: end)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(0..<4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Int8].Int8BytesRepresentation?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(0...3)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Int8].Int8BytesRepresentation?
  >
  where
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.slice(start: 0, length: 4)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_int8(?), 0, 4) END
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<
    [Int8].Int8BytesRepresentation?
  >
  where
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.slice(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      start: start,
      length: length
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Int8].Int8BytesRepresentation? = [1, -2, 0, 4, 0, 0, 1, 0]
  /// let result = source.int8()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_int8(?) END
  /// ```
  public func int8() -> some QueryExpression<QueryValue.Wrapped?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecInt8Encoding
  {
    Vec.int8(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == V.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let vector: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.distanceHamming(to: vector)
  /// // CASE WHEN (?) IS NULL OR (?) IS NULL THEN NULL ELSE vec_distance_hamming(vec_bit(?), vec_bit(?)) END
  /// ```
  @_disfavoredOverload
  public func distanceHamming<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V?>
  ) -> some QueryExpression<Double?>
  where
    V.Encoding == QueryValue.Wrapped.Encoding,
    V.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.distanceHamming(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), to: vector)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.slice(start: 0, end: 8)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public func slice(start: Int, end: Int) -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), start: start, end: end)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.slice(0..<8)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Bool].PackedBitsRepresentation?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.slice(0...7)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Bool].PackedBitsRepresentation?
  >
  where
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), range: range)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.slice(start: 0, length: 8)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_slice(vec_bit(?), 0, 8) END
  /// ```
  public func slice(start: Int, length: Int) -> some QueryExpression<
    [Bool].PackedBitsRepresentation?
  >
  where
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.slice(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      start: start,
      length: length
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.bit()
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  public func bit() -> some QueryExpression<QueryValue.Wrapped?>
  where
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(
      SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment),
      as: QueryValue.Wrapped.self
    )
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.bit(as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Wrapped.Dimensions == T.Dimensions,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.bit(as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  @_disfavoredOverload
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    QueryValue.Wrapped.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }

  /// Propagates a missing vector as SQL NULL while retaining format and dimension checks.
  ///
  /// ```swift
  /// let source: [Bool].PackedBitsRepresentation? = [true, false, true, false, false, false, true, false]
  /// let result = source.bit(as: [Bool].PackedBitsRepresentation.self)
  /// // CASE WHEN (?) IS NULL THEN NULL ELSE vec_bit(?) END
  /// ```
  @_disfavoredOverload
  public func bit<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T?>
  where
    T.Encoding: SQLiteVecBinaryEncoding,
    T.Dimensions == Void,
    QueryValue.Wrapped.Encoding: SQLiteVecBinaryEncoding
  {
    Vec.bit(SQLQueryExpression<QueryValue.Wrapped?>(self.queryFragment), as: result)
  }
}
