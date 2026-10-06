import StructuredQueriesCore

/// A namespace for SQLiteVec SQL functions.
///
/// Helpers accept float32 or raw packed-bit encodings according to the operation. Turso's float64,
/// quantized, sparse, and metadata-bearing binary encodings are not supported. Packed-bit scalar
/// operations apply `vec_bit` so SQLiteVec interprets bound blobs as binary vectors.
public enum Vec {
  /// Returns the L2 distance between a vector expression and a query vector.
  /// This calls sqlite-vec's `vec_distance_l2` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   Vec.distanceL2($0.embedding, to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the L2 distance.
  public static func distanceL2<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    to vector: W
  ) -> some QueryExpression<Double>
  where V.Encoding == [Float].VectorBytesRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression("vec_distance_l2(\(expression), \(bind: vector))")
  }

  /// Returns the L1 distance between a vector expression and a query vector.
  /// This calls sqlite-vec's `vec_distance_l1` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   Vec.distanceL1($0.embedding, to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the L1 distance.
  public static func distanceL1<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    to vector: W
  ) -> some QueryExpression<Double>
  where V.Encoding == [Float].VectorBytesRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression("vec_distance_l1(\(expression), \(bind: vector))")
  }

  /// Returns the cosine distance between a vector expression and a query vector.
  /// This calls sqlite-vec's `vec_distance_cosine` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   Vec.distanceCosine($0.embedding, to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the cosine distance.
  public static func distanceCosine<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    to vector: W
  ) -> some QueryExpression<Double>
  where V.Encoding == [Float].VectorBytesRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression("vec_distance_cosine(\(expression), \(bind: vector))")
  }

  /// Returns the Hamming distance between a vector expression and a query vector.
  /// This calls sqlite-vec's `vec_distance_hamming` function.
  ///
  /// ```swift
  /// let queryVector: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
  /// let query = BinaryEmbedding.select {
  ///   Vec.distanceHamming($0.embedding, to: queryVector)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to compare.
  ///   - vector: The query vector to compare.
  /// - Returns: A query expression for the Hamming distance.
  public static func distanceHamming<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    to vector: W
  ) -> some QueryExpression<Double>
  where V.Encoding == [Bool].PackedBitsRepresentation, W.Encoding == V.Encoding {
    SQLQueryExpression("vec_distance_hamming(vec_bit(\(expression)), vec_bit(\(bind: vector)))")
  }

  /// Returns the length of a vector expression.
  /// This calls sqlite-vec's `vec_length` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.length($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to measure.
  /// - Returns: A query expression for the vector length.
  public static func length<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == [Float].VectorBytesRepresentation {
    SQLQueryExpression("vec_length(\(expression))")
  }

  /// Returns the sqlite-vec type string for a vector expression.
  /// This calls sqlite-vec's `vec_type` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.type($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to inspect.
  /// - Returns: A query expression for the type string.
  public static func type<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Float].VectorBytesRepresentation {
    SQLQueryExpression("vec_type(\(expression))")
  }

  /// Returns a JSON string for a vector expression.
  /// This calls sqlite-vec's `vec_to_json` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.toJSON($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to serialize.
  /// - Returns: A query expression for the JSON string.
  public static func toJSON<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Float].VectorBytesRepresentation {
    SQLQueryExpression("vec_to_json(\(expression))")
  }

  /// Adds a query vector to an expression and returns the result in the requested representation.
  /// This calls sqlite-vec's `vec_add` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   Vec.add($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to add to.
  ///   - vector: The query vector to add.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the summed vector.
  public static func add<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: W,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == [Float].VectorBytesRepresentation
  {
    SQLQueryExpression("vec_add(\(expression), \(bind: vector))")
  }

  /// Adds a query vector to an expression and returns the result as a float vector.
  /// This calls sqlite-vec's `vec_add` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   Vec.add($0.embedding, queryVector)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to add to.
  ///   - vector: The query vector to add.
  /// - Returns: A query expression for the summed vector.
  public static func add<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    _ vector: W
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation, W.Encoding == V.Encoding {
    Self.add(expression, vector, as: [Float].VectorBytesRepresentation.self)
  }

  /// Subtracts a query vector from an expression and returns the result in the requested representation.
  /// This calls sqlite-vec's `vec_sub` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   Vec.sub($0.embedding, queryVector, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to subtract from.
  ///   - vector: The query vector to subtract.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the difference vector.
  public static func sub<
    V: VectorBytesRepresentable,
    W: VectorBytesRepresentable & QueryBindable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    _ vector: W,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, W.Encoding == V.Encoding,
    T.Encoding == [Float].VectorBytesRepresentation
  {
    SQLQueryExpression("vec_sub(\(expression), \(bind: vector))")
  }

  /// Subtracts a query vector from an expression and returns the result as a float vector.
  /// This calls sqlite-vec's `vec_sub` function.
  ///
  /// ```swift
  /// let queryVector: [Float].VectorBytesRepresentation = [0.1, 0.2, 0.3]
  /// let query = Embedding.select {
  ///   Vec.sub($0.embedding, queryVector)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to subtract from.
  ///   - vector: The query vector to subtract.
  /// - Returns: A query expression for the difference vector.
  public static func sub<V: VectorBytesRepresentable, W: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    _ vector: W
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation, W.Encoding == V.Encoding {
    Self.sub(expression, vector, as: [Float].VectorBytesRepresentation.self)
  }

  /// Extracts a slice from a vector expression using a start index and exclusive end index.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, end: 3, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - start: The start index.
  ///   - end: The exclusive end index.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
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
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    SQLQueryExpression("vec_slice(\(expression), \(raw: start), \(raw: end))")
  }

  /// Extracts a slice from a vector expression using a start index and exclusive end index.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, end: 3)
  /// }
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
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.slice(
      expression,
      start: start,
      end: end,
      as: [Float].VectorBytesRepresentation.self
    )
  }

  /// Extracts a slice from a vector expression using a half-open range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0..<3, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - range: The half-open range to extract.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    range: Range<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    Self.slice(expression, start: range.lowerBound, end: range.upperBound, as: result)
  }

  /// Extracts a slice from a vector expression using a half-open range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0..<3)
  /// }
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
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.slice(expression, range: range, as: [Float].VectorBytesRepresentation.self)
  }

  /// Extracts a slice from a vector expression using a closed range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0...2, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - range: The closed range to extract.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    Self.slice(expression, start: range.lowerBound, end: range.upperBound + 1, as: result)
  }

  /// Extracts a slice from a vector expression using a closed range.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, range: 0...2)
  /// }
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
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.slice(expression, range: range, as: [Float].VectorBytesRepresentation.self)
  }

  /// Extracts a slice from a vector expression using a start index and length.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, length: 3, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to slice.
  ///   - start: The start index.
  ///   - length: The number of elements to extract.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the sliced vector.
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
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    Self.slice(expression, range: start..<(start + length), as: result)
  }

  /// Extracts a slice from a vector expression using a start index and length.
  /// This calls sqlite-vec's `vec_slice` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.slice($0.embedding, start: 0, length: 3)
  /// }
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
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.slice(expression, range: start..<(start + length))
  }

  /// Normalizes a vector expression and returns the result in the requested representation.
  /// This calls sqlite-vec's `vec_normalize` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.normalize($0.embedding, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to normalize.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the normalized vector.
  public static func normalize<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    SQLQueryExpression("vec_normalize(\(expression))")
  }

  /// Normalizes a vector expression and returns the result as a float vector.
  /// This calls sqlite-vec's `vec_normalize` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.normalize($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to normalize.
  /// - Returns: A query expression for the normalized vector.
  public static func normalize<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.normalize(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Converts a vector expression to an f32 representation and returns the result in the requested type.
  /// This calls sqlite-vec's `vec_f32` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.f32($0.embedding, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to convert.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the converted vector.
  public static func f32<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    SQLQueryExpression("vec_f32(\(expression))")
  }

  /// Converts a vector expression to an f32 representation and returns the result as a float vector.
  /// This calls sqlite-vec's `vec_f32` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.f32($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to convert.
  /// - Returns: A query expression for the converted vector.
  public static func f32<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.f32(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Converts a vector expression to a bit representation and returns the result in the requested type.
  /// This calls sqlite-vec's `vec_bit` function, reinterpreting the blob's bytes as bits.
  /// Use `quantizeBinary` to quantize numeric components by sign instead.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.bit($0.embedding, as: [Bool].PackedBitsRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to convert.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the converted vector.
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    SQLQueryExpression("vec_bit(\(expression))")
  }

  /// Converts a vector expression to a bit representation and returns logical bits.
  /// This calls sqlite-vec's `vec_bit` function, reinterpreting the blob's bytes as bits.
  /// Use `quantizeBinary` to quantize numeric components by sign instead.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.bit($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to convert.
  /// - Returns: A query expression for the converted vector.
  public static func bit<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.bit(expression, as: [Bool].PackedBitsRepresentation.self)
  }

  /// Converts a vector expression to an int8 representation and returns the result in the requested type.
  /// This calls sqlite-vec's `vec_int8` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.int8($0.embedding, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to convert.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the converted vector.
  public static func int8<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    SQLQueryExpression("vec_int8(\(expression))")
  }

  /// Converts a vector expression to an int8 representation and returns the result as a float vector.
  /// This calls sqlite-vec's `vec_int8` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.int8($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to convert.
  /// - Returns: A query expression for the converted vector.
  public static func int8<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.int8(expression, as: [Float].VectorBytesRepresentation.self)
  }

  /// Quantizes a vector expression to int8 and returns the result in the requested representation.
  /// This calls sqlite-vec's `vec_quantize_int8` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.quantizeInt8($0.embedding, scale: 1.0, as: [Float].VectorBytesRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to quantize.
  ///   - scale: The scale value passed to sqlite-vec.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the quantized vector.
  public static func quantizeInt8<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    scale: Double,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Float].VectorBytesRepresentation
  {
    SQLQueryExpression("vec_quantize_int8(\(expression), \(raw: scale))")
  }

  /// Quantizes a vector expression to int8 and returns the result as a float vector.
  /// This calls sqlite-vec's `vec_quantize_int8` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.quantizeInt8($0.embedding, scale: 1.0)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to quantize.
  ///   - scale: The scale value passed to sqlite-vec.
  /// - Returns: A query expression for the quantized vector.
  public static func quantizeInt8<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    scale: Double
  ) -> some QueryExpression<[Float].VectorBytesRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.quantizeInt8(
      expression,
      scale: scale,
      as: [Float].VectorBytesRepresentation.self
    )
  }

  /// Quantizes a vector expression to a binary representation and returns the result in the requested type.
  /// This calls sqlite-vec's `vec_quantize_binary` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.quantizeBinary($0.embedding, as: [Bool].PackedBitsRepresentation.self)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - expression: The vector expression to quantize.
  ///   - result: The result representation type.
  /// - Returns: A query expression for the quantized vector.
  public static func quantizeBinary<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where
    V.Encoding == [Float].VectorBytesRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    SQLQueryExpression("vec_quantize_binary(\(expression))")
  }

  /// Quantizes a vector expression to a binary representation and returns logical bits.
  /// This calls sqlite-vec's `vec_quantize_binary` function.
  ///
  /// ```swift
  /// let query = Embedding.select {
  ///   Vec.quantizeBinary($0.embedding)
  /// }
  /// ```
  ///
  /// - Parameter expression: The vector expression to quantize.
  /// - Returns: A query expression for the quantized vector.
  public static func quantizeBinary<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Float].VectorBytesRepresentation {
    Self.quantizeBinary(expression, as: [Bool].PackedBitsRepresentation.self)
  }

  // MARK: - Packed Bits

  /// Returns the dimension count of a packed-bit vector.
  public static func length<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == [Bool].PackedBitsRepresentation {
    SQLQueryExpression("vec_length(vec_bit(\(expression)))")
  }

  /// Returns the SQLiteVec type of a packed-bit vector.
  public static func type<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Bool].PackedBitsRepresentation {
    SQLQueryExpression("vec_type(vec_bit(\(expression)))")
  }

  /// Returns the JSON elements of a packed-bit vector.
  public static func toJSON<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<String> where V.Encoding == [Bool].PackedBitsRepresentation {
    SQLQueryExpression("vec_to_json(vec_bit(\(expression)))")
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    start: Int,
    end: Int,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Bool].PackedBitsRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    SQLQueryExpression("vec_slice(vec_bit(\(expression)), \(raw: start), \(raw: end))")
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    end: Int
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Bool].PackedBitsRepresentation {
    Self.slice(
      expression,
      start: start,
      end: end,
      as: [Bool].PackedBitsRepresentation.self
    )
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    range: Range<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Bool].PackedBitsRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    Self.slice(expression, start: range.lowerBound, end: range.upperBound, as: result)
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: Range<Int>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Bool].PackedBitsRepresentation {
    Self.slice(expression, range: range, as: [Bool].PackedBitsRepresentation.self)
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Bool].PackedBitsRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    Self.slice(expression, start: range.lowerBound, end: range.upperBound + 1, as: result)
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    range: ClosedRange<Int>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Bool].PackedBitsRepresentation {
    Self.slice(expression, range: range, as: [Bool].PackedBitsRepresentation.self)
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<
    V: VectorBytesRepresentable,
    T: VectorBytesRepresentable & QueryBindable
  >(
    _ expression: some QueryExpression<V>,
    start: Int,
    length: Int,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Bool].PackedBitsRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    Self.slice(expression, range: start..<(start + length), as: result)
  }

  /// Slices packed bits. The start and end indices must be divisible by eight.
  public static func slice<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>,
    start: Int,
    length: Int
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Bool].PackedBitsRepresentation {
    Self.slice(expression, range: start..<(start + length))
  }

  /// Marks a packed-bit blob with SQLiteVec's binary subtype.
  public static func bit<V: VectorBytesRepresentable, T: VectorBytesRepresentable & QueryBindable>(
    _ expression: some QueryExpression<V>,
    as result: T.Type
  ) -> some QueryExpression<T>
  where V.Encoding == [Bool].PackedBitsRepresentation, T.Encoding == [Bool].PackedBitsRepresentation
  {
    SQLQueryExpression("vec_bit(\(expression))")
  }

  /// Marks a packed-bit blob with SQLiteVec's binary subtype.
  public static func bit<V: VectorBytesRepresentable>(
    _ expression: some QueryExpression<V>
  ) -> some QueryExpression<[Bool].PackedBitsRepresentation>
  where V.Encoding == [Bool].PackedBitsRepresentation {
    Self.bit(expression, as: [Bool].PackedBitsRepresentation.self)
  }
}
