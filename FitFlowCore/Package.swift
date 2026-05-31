// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FitFlowCore",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "FitFlowDomain", targets: ["FitFlowDomain"]),
        .library(name: "FitFlowData", targets: ["FitFlowData"]),
        .library(name: "FitFlowFeatures", targets: ["FitFlowFeatures"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            exact: "1.26.2"
        ),
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            exact: "0.65.0"
        ),
    ],
    targets: [
        .target(
            name: "FitFlowDomain",
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "FitFlowData",
            dependencies: ["FitFlowDomain"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "FitFlowFeatures",
            dependencies: [
                "FitFlowDomain",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .testTarget(
            name: "FitFlowDomainTests",
            dependencies: ["FitFlowDomain"]
        ),
        .testTarget(
            name: "FitFlowDataTests",
            dependencies: ["FitFlowData", "FitFlowDomain"]
        ),
        .testTarget(
            name: "FitFlowFeatureTests",
            dependencies: [
                "FitFlowFeatures",
                "FitFlowDomain",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ]
)
