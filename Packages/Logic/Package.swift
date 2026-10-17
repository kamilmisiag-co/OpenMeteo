// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Logic",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Logic", targets: ["Logic"]),
        .library(name: "LogicMocks", targets: ["LogicMocks"]),
    ],
    dependencies: [
        .package(path: "../Utils"),
    ],
    targets: [
        .target(
            name: "Logic",
            dependencies: [
                .product(name: "Utils", package: "Utils"),
            ],
        ),
        .target(
            name: "LogicMocks",
            dependencies: ["Logic"],
        ),
        .testTarget(
            name: "LogicTests",
            dependencies: [
                "Logic",
                "LogicMocks",
                .product(name: "Utils", package: "Utils"),
            ],
        ),
    ]
)
