// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OpenMeteoAPI",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "OpenMeteoAPI", targets: ["OpenMeteoAPI"]),
    ],
    dependencies: [
        .package(path: "../Utils"),
        .package(path: "../Networking"),
        .package(path: "../Logic"),
    ],
    targets: [
        .target(
            name: "OpenMeteoAPI",
            dependencies: [
                .product(name: "Networking", package: "Networking"),
                .product(name: "Logic", package: "Logic"),
                .product(name: "Utils", package: "Utils"),
            ],
        ),
        .testTarget(
            name: "OpenMeteoAPITests",
            dependencies: [
                "OpenMeteoAPI",
                .product(name: "Networking", package: "Networking"),
                .product(name: "NetworkingMocks", package: "Networking"),
                .product(name: "Logic", package: "Logic"),
                .product(name: "LogicMocks", package: "Logic"),
                .product(name: "Utils", package: "Utils"),
                .product(name: "UtilsMocks", package: "Utils"),
            ],
            resources: [.copy("Fixtures")],
        ),
    ]
)
