import StructuredQueriesCore

extension Vec {
  /// Marks a signed-byte blob with SQLiteVec's Int8 subtype.
  ///
  /// This reinterprets bytes, rather than numerically converting Float32 components. Use
  /// `quantizeInt8` for Float32 quantization. Blob subtypes do not survive storage or binding,
  /// so this helper is also needed when inserting into vec0 Int8 columns.
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Int8].Int8BytesRepresentation, T.Encoding == V.Encoding {
    SQLQueryExpression("vec_int8(\(expression))")
  }

  /// Marks a signed-byte blob with SQLiteVec's Int8 subtype.
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
  public static func int8<T: VectorBytesRepresentable & QueryBindable>(
    _ json: some QueryExpression<String>,
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_int8(\(json))")
  }

  /// Parses a JSON array of integers in [-128, 127] as a signed Int8 vector.
  public static func int8(
    _ json: some QueryExpression<String>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation> {
    Self.int8(json, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Matches a bound or computed Int8 query against a vec0 Int8 vector column.
  ///
  /// The left expression must refer to a vec0 vector column. A limit or `k` constraint is
  /// required, as with Float32 and binary matches.
  public static func match<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Bool>
  where V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression("(\(expression) MATCH vec_int8(\(vector)))")
  }

  /// Returns the L1 distance between signed Int8 vectors with matching dimensions.
  /// SQLiteVec's Int8 subtype is applied to both expressions. SQLiteVec computes Int8 L1
  /// distances as integers, so the result is cast to `REAL` to match the other distances.
  public static func distanceL1<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression(
      "CAST(vec_distance_l1(vec_int8(\(expression)), vec_int8(\(vector))) AS REAL)"
    )
  }

  /// Returns the L2 distance between signed Int8 vectors with matching dimensions.
  /// SQLiteVec's Int8 subtype is applied to both expressions.
  public static func distanceL2<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression("vec_distance_l2(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Returns the cosine distance between signed Int8 vectors with matching dimensions.
  /// SQLiteVec's Int8 subtype is applied to both expressions.
  public static func distanceCosine<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    to vector: some QueryExpression<W>
  ) -> some QueryExpression<Double>
  where V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression("vec_distance_cosine(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Returns the number of Int8 components.
  public static func length<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<Int> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_length(vec_int8(\(expression)))")
  }

  /// Returns the SQLiteVec type string (`int8`).
  public static func type<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_type(vec_int8(\(expression)))")
  }

  /// Returns the signed Int8 components as JSON.
  public static func toJSON<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Int8].Int8BytesRepresentation {
    SQLQueryExpression("vec_to_json(vec_int8(\(expression)))")
  }

  /// Adds signed Int8 components, returning signed bytes with SQLiteVec's arithmetic semantics.
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
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding, T.Encoding == V.Encoding
  {
    SQLQueryExpression("vec_add(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Adds signed Int8 components, returning a signed-byte array representation.
  public static func add<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding {
    Self.add(expression, vector, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Subtracts signed Int8 components, returning signed bytes with SQLiteVec's arithmetic semantics.
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
    V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding, T.Encoding == V.Encoding
  {
    SQLQueryExpression("vec_sub(vec_int8(\(expression)), vec_int8(\(vector)))")
  }

  /// Subtracts signed Int8 components, returning a signed-byte array representation.
  public static func sub<V: VectorBytesRepresentable, W: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    _ vector: some QueryExpression<W>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation, W.Encoding == V.Encoding {
    Self.sub(expression, vector, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Slices signed Int8 components, with an inclusive start and exclusive end.
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
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, start: start, end: end, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Slices signed Int8 components using a half-open range.
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
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: Range<Int>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, range: range, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Slices signed Int8 components using a closed range.
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
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, range: range, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Slices signed Int8 components using a start index and component count.
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
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.slice(expression, start: start, length: length, as: [Int8].Int8BytesRepresentation.self)
  }

  /// Quantizes signed Int8 components by sign into packed bits. Dimensions must be divisible by eight.
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
  public static func quantizeBinary<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Int8].Int8BytesRepresentation {
    Self.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  }
}
