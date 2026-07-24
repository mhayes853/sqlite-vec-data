// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "sqlite-vec-data",
  platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9)],
  products: [
    .library(name: "SQLiteVecData", targets: ["SQLiteVecData"]),
    .library(name: "SQLiteVecDataTestSupport", targets: ["SQLiteVecDataTestSupport"])
  ],
  traits: [
    .default(enabledTraits: ["NEON"]),
    .trait(name: "NEON", description: "Enable NEON vector implementations on ARM.")
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-structured-queries",
      from: "0.31.1",
      traits: ["StructuredQueriesTagged"]
    ),
    .package(
      url: "https://github.com/pointfreeco/sqlite-data",
      from: "1.6.1",
      traits: ["SQLiteDataTagged"]
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
        .define("SQLITE_VEC_ENABLE_NEON", to: "1", .when(traits: ["NEON"]))
      ]
    ),
    .target(
      name: "StructuredQueriesSQLiteVecCore",
      dependencies: [
        .product(name: "StructuredQueriesSQLiteCore", package: "swift-structured-queries")
      ]
    ),
    .target(
      name: "SQLiteVecData",
      dependencies: [
        "CSQLiteVec",
        "StructuredQueriesSQLiteVecCore",
        .product(name: "SQLiteData", package: "sqlite-data")
      ]
    ),
    .target(
      name: "SQLiteVecDataTestSupport",
      dependencies: [
        "SQLiteVecData"
      ]
    ),
    .testTarget(
      name: "SQLiteVecDataTests",
      dependencies: [
        "SQLiteVecData",
        "SQLiteVecDataTestSupport",
        .product(name: "StructuredQueriesTestSupport", package: "swift-structured-queries"),
        .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay")
      ]
    )
  ]
)
