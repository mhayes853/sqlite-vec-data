import StructuredQueriesCore

extension TableColumnExpression
where Root: Vec0, Value: VectorBytesRepresentable, Value.Encoding == [Int8].Int8BytesRepresentation
{
  /// Matches a bound or computed query against this vec0 Int8 column.
  public func match<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Bool> where V.Encoding == Value.Encoding {
    Vec.match(self, to: vector)
  }

  /// Marks this signed-byte column with SQLiteVec's Int8 subtype.
  public func int8() -> some QueryExpression<Value> {
    Vec.int8(self, as: Value.self)
  }

  /// Returns the L1 distance to a signed Int8 query with matching dimensions.
  public func distanceL1<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == Value.Encoding {
    Vec.distanceL1(self, to: vector)
  }

  /// Returns the L2 distance to a signed Int8 query with matching dimensions.
  public func distanceL2<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == Value.Encoding {
    Vec.distanceL2(self, to: vector)
  }

  /// Returns the cosine distance to a signed Int8 query with matching dimensions.
  public func distanceCosine<V: VectorBytesRepresentable>(
    to vector: some QueryExpression<V>
  ) -> some QueryExpression<Double> where V.Encoding == Value.Encoding {
    Vec.distanceCosine(self, to: vector)
  }

  /// Returns the number of signed Int8 components.
  public func length() -> some QueryExpression<Double> {
    Vec.length(self)
  }

  /// Returns the SQLiteVec type string.
  public func type() -> some QueryExpression<String> {
    Vec.type(self)
  }

  /// Returns the signed Int8 components as JSON.
  public func toJSON() -> some QueryExpression<String> {
    Vec.toJSON(self)
  }

  /// Adds a signed Int8 query with matching dimensions.
  public func add<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Value> where V.Encoding == Value.Encoding {
    Vec.add(self, vector, as: Value.self)
  }

  /// Subtracts a signed Int8 query with matching dimensions.
  public func sub<V: VectorBytesRepresentable>(
    _ vector: some QueryExpression<V>
  ) -> some QueryExpression<Value> where V.Encoding == Value.Encoding {
    Vec.sub(self, vector, as: Value.self)
  }

  /// Slices signed Int8 components using an inclusive start and exclusive end.
  public func slice(start: Int, end: Int) -> some QueryExpression<[Int8].Int8BytesRepresentation> {
    Vec.slice(self, start: start, end: end)
  }

  /// Slices signed Int8 components using a half-open range.
  public func slice(_ range: Range<Int>) -> some QueryExpression<[Int8].Int8BytesRepresentation> {
    Vec.slice(self, range: range)
  }

  /// Slices signed Int8 components using a closed range.
  public func slice(_ range: ClosedRange<Int>) -> some QueryExpression<
    [Int8].Int8BytesRepresentation
  > {
    Vec.slice(self, range: range)
  }

  /// Slices signed Int8 components using a start index and component count.
  public func slice(start: Int, length: Int) -> some QueryExpression<[Int8].Int8BytesRepresentation>
  {
    Vec.slice(self, start: start, length: length)
  }

  /// Quantizes signed Int8 components by sign into packed bits. Dimensions must be divisible by eight.
  public func quantizeBinary() -> some QueryExpression<[Bool].PackedBitsRepresentation> {
    Vec.quantizeBinary(self)
  }

  /// Quantizes signed Int8 components into a matching packed-bit representation.
  public func quantizeBinary<T: VectorBytesRepresentable & QueryBindable>(
    as result: T.Type
  ) -> some QueryExpression<T> where T.Encoding == [Bool].PackedBitsRepresentation {
    Vec.quantizeBinary(self, as: result)
  }
}
