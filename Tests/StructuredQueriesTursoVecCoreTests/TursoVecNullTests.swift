import CustomDump
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `TursoVec NULL tests` {
  @Test
  func `Nullable Distances Guard Each Missing Operand`() {
    // Native vector functions reject NULL inputs; CASE deliberately supplies NULL propagation.
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/mod.rs
    let left = SQLQueryExpression<[Float].VectorBytesRepresentation>("left_vector")
    let right = SQLQueryExpression<[Float].VectorBytesRepresentation>("right_vector")
    let optionalLeft = SQLQueryExpression<[Float].VectorBytesRepresentation?>("left_vector")
    let optionalRight = SQLQueryExpression<[Float].VectorBytesRepresentation?>("right_vector")
    let expressions = [
      optionalLeft.whenPresent { TursoVec.distanceCosine($0, to: right) }.queryFragment,
      optionalRight.whenPresent { TursoVec.distanceL2(left, to: $0) }.queryFragment,
      optionalLeft.whenPresent(optionalRight) { TursoVec.distanceDot($0, to: $1) }.queryFragment,
      optionalLeft.whenPresent(optionalRight) { TursoVec.distanceJaccard($0, to: $1) }.queryFragment
    ]
    expectNoDifference(
      expressions.map { $0.prepare { "?\($0)" }.sql },
      [
        "CASE WHEN (left_vector) IS NULL THEN NULL ELSE vector_distance_cos(left_vector, right_vector) END",
        "CASE WHEN (right_vector) IS NULL THEN NULL ELSE vector_distance_l2(left_vector, right_vector) END",
        "CASE WHEN (left_vector) IS NULL OR (right_vector) IS NULL THEN NULL ELSE vector_distance_dot(left_vector, right_vector) END",
        "CASE WHEN (left_vector) IS NULL OR (right_vector) IS NULL THEN NULL ELSE vector_distance_jaccard(left_vector, right_vector) END"
      ]
    )
    requireNullable(TursoVec.distanceCosine(left, to: right))
    requireNullable(TursoVec.distanceL2(left, to: right))
    requireNullable(TursoVec.distanceDot(left, to: right))
    requireNullable(TursoVec.distanceJaccard(left, to: right))
  }

  @Test
  func `Finite Encodings Retain Precise Distance Types`() throws {
    // Floating output is passed through Value::from_f64; validated quantized and binary
    // L2/dot/Hamming cannot produce NaN. Cosine/Jaccard can still have a zero denominator.
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/distance_dot.rs
    let codes = try Quantized8Vector(quantizing: [1, 2, 3])
    let bits: [Bool].TursoBytesRepresentation = [true, false, true]
    requireNonnullable(TursoVec.distanceL2(codes, to: codes))
    requireNonnullable(TursoVec.distanceDot(codes, to: codes))
    requireNonnullable(TursoVec.distanceDot(bits, to: bits))
    requireNonnullable(TursoVec.distanceHamming(bits, to: bits))
    requireNullable(TursoVec.distanceCosine(codes, to: codes))
    requireNullable(TursoVec.distanceJaccard(bits, to: bits))
    let missing: Quantized8Vector? = nil
    requireNullable(missing.whenPresent { TursoVec.distanceL2($0, to: codes) })
    requireNullable(missing.whenPresent { TursoVec.distanceDot(codes, to: $0) })
    expectNoDifference(
      missing.whenPresent { TursoVec.distanceL2($0, to: codes) }.queryFragment.prepare { "?\($0)" }
        .sql,
      "CASE WHEN (NULL) IS NULL THEN NULL ELSE vector_distance_l2(NULL, ?1) END"
    )
  }

  @Test
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  func `Nullable Conversion Chains Preserve Dimensions And Bindings`() {
    let values = EmbeddingVector<3>([1, 2, 3])
    let source: EmbeddingVector<3>? = values
    let converted = source.whenPresent { TursoVec.vector64($0) }
    requireThreeNullableDimensions(converted)
    let extracted = converted.whenPresent { TursoVec.extract($0) }.queryFragment
      .prepare { "?\($0)" }
    expectNoDifference(
      extracted.sql,
      "CASE WHEN (CASE WHEN (?1) IS NULL THEN NULL ELSE vector64(?2) END) IS NULL THEN NULL ELSE vector_extract(CASE WHEN (?3) IS NULL THEN NULL ELSE vector64(?4) END) END"
    )
    expectNoDifference(extracted.bindings, Array(repeating: values.queryBinding, count: 4))
    let column = SQLQueryExpression<[Double].TursoFloat64BytesRepresentation?>("embedding")
    expectNoDifference(
      column.whenPresent { TursoVec.slice($0, from: 0, to: 2) }.queryFragment.prepare { "?\($0)" }
        .sql,
      "CASE WHEN (embedding) IS NULL THEN NULL ELSE vector_slice(embedding, ?1, ?2) END"
    )
    expectNoDifference(
      column.whenPresent(column) { TursoVec.concat($0, $1) }.queryFragment.prepare { "?\($0)" }.sql,
      "CASE WHEN (embedding) IS NULL OR (embedding) IS NULL THEN NULL ELSE vector_concat(embedding, embedding) END"
    )
    let json = SQLQueryExpression<String?>("candidate_json")
    expectNoDifference(
      json.whenPresent { TursoVec.vector32Sparse($0) }.queryFragment.prepare { "?\($0)" }.sql,
      "CASE WHEN (candidate_json) IS NULL THEN NULL ELSE vector32_sparse(candidate_json) END"
    )
  }
}

private func requireNullable(_ expression: some QueryExpression<Double?>) {}
private func requireNonnullable(_ expression: some QueryExpression<Double>) {}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private func requireThreeNullableDimensions<V: VectorBytesRepresentable>(
  _ expression: some QueryExpression<V?>
) where V.Dimensions == VectorDimensions<3> {}
