// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MurottalCentral",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MurottalCentralCore",
            targets: ["MurottalCentralCore"]
        ),
        .executable(
            name: "MurottalCentral",
            targets: ["MurottalCentralApp"]
        ),
    ],
    targets: [
        .target(
            name: "MurottalCentralCore",
            resources: [
                .copy("Resources/Fonts")
            ]
        ),
        .executableTarget(
            name: "MurottalCentralApp",
            dependencies: ["MurottalCentralCore"]
        ),
        .testTarget(
            name: "MurottalCentralCoreTests",
            dependencies: ["MurottalCentralCore"],
            resources: [.process("Fixtures")]
        ),
    ]
)
