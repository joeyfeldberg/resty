// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Resty",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Resty", targets: ["Resty"]),
        .executable(name: "RestyControlsExtension", targets: ["RestyControlsExtension"]),
    ],
    targets: [
        .target(
            name: "RestyShared",
            path: "Sources/RestyShared"
        ),
        .executableTarget(
            name: "Resty",
            dependencies: ["RestyShared"],
            path: "Sources/Resty",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "RestyControlsExtension",
            dependencies: ["RestyShared"],
            path: "Sources/RestyControlsExtension"
        ),
        .testTarget(
            name: "RestyTests",
            dependencies: ["Resty", "RestyShared"],
            path: "Tests/RestyTests"
        ),
    ]
)
