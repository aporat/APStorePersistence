// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "APStorePersistence",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4),
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "APStorePersistence",
            targets: ["APStorePersistence"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/bizz84/SwiftyStoreKit.git", from: "0.16.4"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", branch: "master")

    ],
    targets: [
        .target(
            name: "APStorePersistence",
            dependencies: [
                "SwiftyStoreKit",
                "KeychainAccess"
            ]
        )
    ]
)
