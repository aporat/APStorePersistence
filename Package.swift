// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "APStorePersistence",
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
        .tvOS(.v13),
        .watchOS(.v6)
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
    swiftLanguageModes: [.v6]
)
