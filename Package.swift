// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LML",
    platforms: [.macOS(.v14)],
    targets: [
        // All logic lives here — importable by both the app and test runner.
        .target(
            name: "LMLCore",
            path: "Sources/LMLCore"
        ),
        // The actual menu bar app. Thin shell: just @main + AppDelegate.
        .executableTarget(
            name: "LML",
            dependencies: ["LMLCore"],
            path: "Sources/LML"
        ),
        // Standalone test runner that works without Xcode / XCTest.
        .executableTarget(
            name: "LMLTestRunner",
            dependencies: ["LMLCore"],
            path: "Tests/LMLTests"
        ),
    ]
)
