// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShikiTokenSDK",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ShikiTokenSDK",
            targets: ["ShikiTokenSDK"]
        )
    ],
    targets: [
        .target(
            name: "ShikiTokenSDK"
        ),
        .testTarget(
            name: "ShikiTokenSDKTests",
            dependencies: ["ShikiTokenSDK"]
        )
    ]
)
