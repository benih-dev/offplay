// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OffPlay",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "OffPlayCore", targets: ["OffPlayCore"]),
        .executable(name: "OffPlayContentBuilder", targets: ["OffPlayContentBuilder"])
    ],
    targets: [
        .target(name: "OffPlayCore", resources: [.process("Resources")]),
        .executableTarget(name: "OffPlayContentBuilder", dependencies: ["OffPlayCore"], path: "Tools/ContentBuilder"),
        .testTarget(name: "OffPlayCoreTests", dependencies: ["OffPlayCore"])
    ]
)
