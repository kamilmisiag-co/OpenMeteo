// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "NetworkingMocks", targets: ["NetworkingMocks"]),
    ],
    dependencies: [
        .package(path: "../Utils"),
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [
                .product(name: "Utils", package: "Utils"),
            ],
        ),
        .target(
            name: "NetworkingMocks",
            dependencies: ["Networking"],
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: [
                "Networking",
                "NetworkingMocks",
                .product(name: "Utils", package: "Utils"),
                .product(name: "UtilsMocks", package: "Utils"),
            ],
        ),
    ]
)
