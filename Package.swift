// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APStorePersistence",
    platforms: [
        .iOS(.v16)
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
        ),
        .testTarget(
            name: "APStorePersistenceTests",
            dependencies: ["APStorePersistence"]
        )
    ]
)
