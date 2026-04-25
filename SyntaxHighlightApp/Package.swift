// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SyntaxHighlightApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../ShikiTokenSDK")
    ],
    targets: [
        .executableTarget(
            name: "SyntaxHighlightApp",
            dependencies: ["ShikiTokenSDK"],
            path: "Sources"
        )
    ]
)
