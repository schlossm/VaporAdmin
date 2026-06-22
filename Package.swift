// swift-tools-version: 6.3

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "VaporAdmin",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "VaporAdmin",
            targets: ["VaporAdmin"]
        ),
    ],
    traits: [
        .trait(name: "Passage"),
        .trait(name: "PassageFluent", enabledTraits: ["Passage"]),
        .default(enabledTraits: ["PassageFluent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.52.2"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/vapor-community/passage.git", from: "0.5.0"),
        .package(url: "https://github.com/rozd/passage-fluent.git", from: "0.0.19"),
    ],
    targets: [
        .macro(
            name: "VaporAdminMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            swiftSettings: swiftSettings
        ),
        
        .target(
            name: "VaporAdmin",
            dependencies: [
                "VaporAdminMacros",
                .product(name: "Fluent", package: "fluent"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Passage", package: "passage", condition: .when(traits: ["Passage"])),
                .product(name: "PassageFluent", package: "passage-fluent", condition: .when(traits: ["PassageFluent"])),
            ],
            resources: [
                .copy("../../Resources/Views"),
                .copy("../../Public"),
            ],
            swiftSettings: swiftSettings),
        
        .testTarget(
                name: "VaporAdminTests",
                dependencies: [
                    .target(name: "VaporAdmin"),
                    .target(name: "VaporAdminMacros"),
                    .product(name: "VaporTesting", package: "vapor"),
                    .product(name: "XCTFluent", package: "fluent-kit"),
                    .product(name: "PassageOnlyForTest", package: "passage", condition: .when(traits: ["Passage"])),
                    .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
                ],
                swiftSettings: swiftSettings
            ),
    ],
)

var swiftSettings: [SwiftSetting] { [
    .enableExperimentalFeature("StrictConcurrency"),
    .enableUpcomingFeature("TypedThrows")
] }
