// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SoundcraftUI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SoundcraftUI", targets: ["SoundcraftUI"]),
    ],
    targets: [
        .target(
            name: "SoundcraftUI",
            path: "Sources/SoundcraftUI"
        ),
        .testTarget(
            name: "SoundcraftUITests",
            dependencies: ["SoundcraftUI"],
            path: "Tests/SoundcraftUITests"
        ),
    ]
)
