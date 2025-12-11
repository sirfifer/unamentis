// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VoiceLearn",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "VoiceLearn",
            targets: ["VoiceLearn"]
        ),
    ],
    dependencies: [
        // LiveKit Swift SDK for WebRTC transport
        .package(url: "https://github.com/livekit/client-sdk-swift.git", from: "2.0.0"),
        
        // Swift Log for structured logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        
        // Swift Collections for efficient data structures
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
    ],
    targets: [
        // Main library target
        .target(
            name: "VoiceLearn",
            dependencies: [
                .product(name: "LiveKit", package: "client-sdk-swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "VoiceLearn"
        ),
        
        // Unit tests
        .testTarget(
            name: "VoiceLearnTests",
            dependencies: ["VoiceLearn"],
            path: "VoiceLearnTests"
        ),
    ]
)
