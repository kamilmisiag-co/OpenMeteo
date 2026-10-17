// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "NetworkingStubs", targets: ["NetworkingStubs"]),
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
            name: "NetworkingStubs",
            dependencies: ["Networking"],
        ),
        .target(
            name: "NetworkingMocks",
            dependencies: ["Networking"],
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: [
                "Networking",
                "NetworkingStubs",
                "NetworkingMocks",
                .product(name: "Utils", package: "Utils"),
            ],
        ),
    ]
)
