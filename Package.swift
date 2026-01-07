// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnaMentis",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        // macOS support disabled - this is an iOS-only app
        // .macOS(.v14)
    ],
    products: [
        .library(
            name: "UnaMentis",
            targets: ["UnaMentis"]
        ),
    ],
    dependencies: [
        // LiveKit Swift SDK for WebRTC transport
        .package(url: "https://github.com/livekit/client-sdk-swift.git", from: "2.0.0"),

        // Swift Log for structured logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),

        // Swift Collections for efficient data structures
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),

        // llama.cpp for on-device LLM inference (GLM-ASR decoder)
        // NOTE: Disabled for SPM builds due to API compatibility issues
        // NOTE: Re-enabled in Xcode project via XCFramework
        // .package(url: "https://github.com/StanfordBDHG/llama.cpp.git", from: "0.3.3"),
    ],
    targets: [
        // Main library target
        .target(
            name: "UnaMentis",
            dependencies: [
                .product(name: "LiveKit", package: "client-sdk-swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
                // .product(name: "llama", package: "llama.cpp"),  // Disabled for SPM builds
            ],
            path: "UnaMentis",
            resources: [
                // Core Data model for persistence
                .copy("UnaMentis.xcdatamodeld")
            ],
            swiftSettings: [
                // Enable C++ interop for llama.cpp (disabled in SPM builds)
                .interoperabilityMode(.Cxx),
                // Define LLAMA_AVAILABLE flag for conditional compilation (disabled in SPM builds)
                // .define("LLAMA_AVAILABLE"),
            ]
        ),

        // Unit tests
        .testTarget(
            name: "UnaMentisTests",
            dependencies: ["UnaMentis"],
            path: "UnaMentisTests"
        ),
    ]
)
