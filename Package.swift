// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "sqlite-vec-data",
  platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9)],
  products: [
    .library(name: "SQLiteVecData", targets: ["SQLiteVecData"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.25.1")
  ],
  targets: [
    .target(name: "CSQLiteVec"),
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
    .testTarget(name: "SQLiteVecDataTests", dependencies: ["SQLiteVecData"])
  ]
)
