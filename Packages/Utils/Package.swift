// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Utils",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Utils", targets: ["Utils"]),
    ],
    targets: [
        .target(name: "Utils"),
        .testTarget(name: "UtilsTests", dependencies: ["Utils"]),
    ]
)
