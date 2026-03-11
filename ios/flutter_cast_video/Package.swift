// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_cast_video",
    platforms: [
        .iOS("15.0")  // Match your plugin's min iOS version
    ],
    products: [
        .library(name: "flutter-cast-video", targets: ["flutter_cast_video"])
    ],
    dependencies: [
        // .package(name: "FlutterFramework", path: "../FlutterFramework")
        // Google Cast SDK wrapper maintained by SRGSSR (Swiss Radio and Television)
        // This is a community-maintained wrapper that provides SPM support for the official Google Cast SDK.
        // Check https://github.com/SRGSSR/google-cast-sdk for the latest version tag and release notes.
        .package(url: "https://github.com/SRGSSR/google-cast-sdk.git", from: "4.8.3")
    ],
    targets: [
        .target(
            name: "flutter_cast_video",
            dependencies: [
                // .product(name: "FlutterFramework", package: "FlutterFramework")
                .product(name: "GoogleCast", package: "google-cast-sdk")
            ],
            exclude: [
                "FlutterVideoCastPlugin.m",
                "FlutterVideoCastPlugin.h"
            ],
            sources: [
                "AirPlayController.swift",
                "AirPlayFactory.swift",
                "ChromeCastController.swift",
                "ChromeCastFactory.swift",
                "SwiftFlutterVideoCastPlugin.swift"
            ]
        )
    ]
)