// Include the build script's output to test the private feature probe and SQL
// dispatch together. The generated directory must precede the source directory.
#include "sqlite-vec.c"

#include <stdio.h>

#ifndef SQLITE_VEC_ENABLE_AVX
#error This test must include the AVX implementation.
#endif

static void require_sqlite(sqlite3 *database, int actual, int expected) {
  if (actual != expected) {
    fprintf(stderr, "SQLite error %d: %s\n", actual, sqlite3_errmsg(database));
    exit(1);
  }
}

int main(int argc, char **argv) {
  if (argc != 2 ||
      (strcmp(argv[1], "avx") != 0 && strcmp(argv[1], "scalar") != 0)) {
    fprintf(stderr, "usage: %s avx|scalar\n", argv[0]);
    return 1;
  }
  int expected_avx = strcmp(argv[1], "avx") == 0;
  if (sqlite_vec_cpu_supports_avx() != expected_avx) {
    fprintf(stderr, "CPU detection did not match expected %s dispatch\n",
            argv[1]);
    return 1;
  }

  sqlite3 *database = NULL;
  require_sqlite(database, sqlite3_open(":memory:", &database), SQLITE_OK);
  require_sqlite(database, sqlite3_vec_init(database, NULL, NULL), SQLITE_OK);
  float left[33], right[33];
  for (int index = 0; index < 33; index++) {
    left[index] = index % 7 - 3;
    right[index] = index % 5 - 2;
  }
  // Multiples of 16 enter the AVX kernel when supported; adjacent counts stay
  // scalar.
  const int counts[] = {16, 17, 32, 33};
  for (int index = 0; index < 4; index++) {
    int count = counts[index];
    sqlite3_stmt *statement = NULL;
    require_sqlite(database,
                   sqlite3_prepare_v2(database,
                                      "SELECT vec_distance_l2(?1, ?2)", -1,
                                      &statement, NULL),
                   SQLITE_OK);
    require_sqlite(database,
                   sqlite3_bind_blob(statement, 1, left, count * sizeof(float),
                                     SQLITE_STATIC),
                   SQLITE_OK);
    require_sqlite(database,
                   sqlite3_bind_blob(statement, 2, right, count * sizeof(float),
                                     SQLITE_STATIC),
                   SQLITE_OK);
    require_sqlite(database, sqlite3_step(statement), SQLITE_ROW);
    double squared_distance = 0;
    for (int component = 0; component < count; component++) {
      double difference = left[component] - right[component];
      squared_distance += difference * difference;
    }
    if (fabs(sqlite3_column_double(statement, 0) - sqrt(squared_distance)) >
        0.00001) {
      fprintf(stderr, "Incorrect %s L2 distance for %d dimensions\n", argv[1],
              count);
      return 1;
    }
    require_sqlite(database, sqlite3_finalize(statement), SQLITE_OK);
  }
  require_sqlite(database, sqlite3_close(database), SQLITE_OK);
  printf("%s CPU detection and SQL distance dispatch passed\n", argv[1]);
  return 0;
}
