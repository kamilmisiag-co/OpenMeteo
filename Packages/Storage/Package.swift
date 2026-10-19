// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Storage",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Storage", targets: ["Storage"]),
    ],
    dependencies: [
        .package(path: "../Utils"),
        .package(path: "../Logic"),
    ],
    targets: [
        .target(
            name: "Storage",
            dependencies: [
                .product(name: "Logic", package: "Logic"),
                .product(name: "Utils", package: "Utils"),
            ],
        ),
        .testTarget(
            name: "StorageTests",
            dependencies: [
                "Storage",
                .product(name: "Logic", package: "Logic"),
                .product(name: "LogicMocks", package: "Logic"),
                .product(name: "Utils", package: "Utils"),
                .product(name: "UtilsMocks", package: "Utils"),
            ],
        ),
    ]
)
