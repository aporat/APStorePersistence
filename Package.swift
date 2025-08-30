// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "APStorePersistence",
    platforms: [
        .iOS(.v16),
        .tvOS(.v12),
        .watchOS("6.2"),
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
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0")
    ],
    targets: [
        .target(
            name: "APStorePersistence",
            dependencies: [
                "SwiftyStoreKit",
                "KeychainAccess"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "APStorePersistenceTests",
            dependencies: ["APStorePersistence"],
            path: "Tests"
        )
    ],
    swiftLanguageModes: [.v5, .v6]
)
