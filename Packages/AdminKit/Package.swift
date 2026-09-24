// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AdminKit",
    defaultLocalization: "en",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "AdminFeatures", targets: ["AdminFeatures"]),
    ],
    targets: [
        // Design tokens and bento components shared with the main Rentbutik app.
        .target(
            name: "DesignSystem",
            resources: [.process("Resources")]
        ),
        // Pure Swift: models, the AdminService contract, sample data. No UI.
        .target(name: "AdminDomain"),
        // Screens. Depends on the two above, never the other way round.
        .target(
            name: "AdminFeatures",
            dependencies: ["DesignSystem", "AdminDomain"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AdminDomainTests",
            dependencies: ["AdminDomain"]
        ),
    ]
)
