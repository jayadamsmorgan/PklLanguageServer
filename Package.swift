// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PklLanguageServer",
    dependencies: [
        // LSP
        .package(url: "https://github.com/ChimeHQ/LanguageServer", branch: "main"),
        // Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
    ],

    targets: [
        .executableTarget(
            name: "PklLanguageServer",
            dependencies: [
                .product(name: "LanguageServer", package: "LanguageServer"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
    ]

)
