// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Resty",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Resty", targets: ["Resty"]),
    ],
    targets: [
        .executableTarget(
            name: "Resty",
            path: "Sources/Resty"
        ),
        .testTarget(
            name: "RestyTests",
            dependencies: ["Resty"],
            path: "Tests/RestyTests"
        ),
    ]
)
