// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "WaveMixer",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "WaveMixer",
            targets: ["WaveMixer"]
        )
    ],
    targets: [
        .target(
            name: "WaveMixer",
            dependencies: [],
            path: "Sources/WaveMixer"
        )
    ]
)
