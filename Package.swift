// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "sqlite-vec-data",
  platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9)],
  products: [
    .library(name: "SQLiteVecData", targets: ["SQLiteVecData"]),
    .library(name: "CSQLiteVec", targets: ["CSQLiteVec"]),
    .library(name: "StructuredQueriesSQLiteVecCore", targets: ["StructuredQueriesSQLiteVecCore"]),
    .library(name: "StructuredQueriesTursoVecCore", targets: ["StructuredQueriesTursoVecCore"]),
    .library(name: "StructuredQueriesVectorCore", targets: ["StructuredQueriesVectorCore"]),
    .library(name: "SQLiteVecDataTestSupport", targets: ["SQLiteVecDataTestSupport"])
  ],
  traits: [
    .default(enabledTraits: ["SQLiteVecNEON", "SQLiteVecStaticAPI"]),
    .trait(
      name: "SQLiteVecNEON",
      description: "Enable sqlite-vec NEON vector implementations on ARM."
    ),
    .trait(
      name: "SQLiteVecAVX",
      description: "Enable sqlite-vec AVX vector implementations on AVX-capable x86 processors."
    ),
    .trait(
      name: "SQLiteVecStaticAPI",
      description: """
        Compile sqlite-vec against the linked SQLite's functions instead of the API table SQLite \
        passes to extensions. Required for per-connection setup on non-Apple platforms.
        """
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-structured-queries",
      from: "0.35.0",
      traits: ["Tagged"]
    ),
    .package(
      url: "https://github.com/pointfreeco/sqlite-data",
      from: "1.9.0",
      traits: ["Tagged"]
    ),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.4.3")
  ],
  targets: [
    .target(
      name: "CSQLiteVec",
      // sqlite-vec.c is included in sqlite-vec-arch.c, which adds architecture checks
      // we cannot declare here.
      exclude: ["sqlite-vec.c"],
      cSettings: [
        // Use SQLite's static extension API for per-connection initialization. Without it,
        // sqlite-vec only uses the API table passed to its entry point, so it works with SQLite
        // builds that do not export every `sqlite3_*` function.
        .define("SQLITE_CORE", .when(traits: ["SQLiteVecStaticAPI"])),
        .define("SQLITE_VEC_ENABLE_NEON", to: "1", .when(traits: ["SQLiteVecNEON"])),
        .define("SQLITE_VEC_ENABLE_AVX", to: "1", .when(traits: ["SQLiteVecAVX"]))
      ]
    ),
    .target(
      name: "StructuredQueriesVectorCore",
      dependencies: [
        .product(name: "StructuredQueriesCore", package: "swift-structured-queries")
      ]
    ),
    .target(
      name: "StructuredQueriesSQLiteVecCore",
      dependencies: [
        "StructuredQueriesVectorCore",
        .product(name: "StructuredQueriesSQLiteCore", package: "swift-structured-queries")
      ]
    ),
    .target(
      name: "StructuredQueriesTursoVecCore",
      dependencies: [
        "StructuredQueriesVectorCore",
        .product(name: "StructuredQueriesSQLiteCore", package: "swift-structured-queries")
      ]
    ),
    .target(
      name: "SQLiteVecData",
      dependencies: [
        "CSQLiteVec",
        "StructuredQueriesSQLiteVecCore",
        .product(name: "SQLiteData", package: "sqlite-data")
      ],
      swiftSettings: [
        .define("SQLITE_VEC_STATIC_API", .when(traits: ["SQLiteVecStaticAPI"]))
      ]
    ),
    .target(
      name: "SQLiteVecDataTestSupport",
      dependencies: [
        "SQLiteVecData"
      ]
    ),
    .testTarget(
      name: "StructuredQueriesTursoVecCoreTests",
      dependencies: [
        "StructuredQueriesTursoVecCore",
        "StructuredQueriesSQLiteVecCore",
        .product(name: "StructuredQueriesSQLite", package: "swift-structured-queries"),
        .product(name: "StructuredQueriesTestSupport", package: "swift-structured-queries")
      ]
    ),
    .testTarget(
      name: "SQLiteVecDataTests",
      dependencies: [
        "SQLiteVecData",
        "SQLiteVecDataTestSupport",
        .product(name: "StructuredQueriesTestSupport", package: "swift-structured-queries"),
        .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay")
      ],
      swiftSettings: [
        .define("SQLITE_VEC_AVX_ENABLED", .when(traits: ["SQLiteVecAVX"]))
      ]
    )
  ]
)
