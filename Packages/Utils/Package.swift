// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Utils",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Utils", targets: ["Utils"]),
        .library(name: "UtilsMocks", targets: ["UtilsMocks"]),
    ],
    targets: [
        .target(name: "Utils"),
        .target(name: "UtilsMocks", dependencies: ["Utils"]),
        .testTarget(name: "UtilsTests", dependencies: ["Utils", "UtilsMocks"]),
    ]
)
