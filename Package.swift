// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dave",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Dave",
            targets: ["Dave"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Dave",
            dependencies: [],
            path: "Sources/Dave"
        ),
    ]
)
