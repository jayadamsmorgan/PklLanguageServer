// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PklLanguageServer",
    products: [
        .library(name: "pkl-lsp", targets: ["pkl-lsp"]),
        .executable(name: "pkl-lsp-server", targets: ["pkl-lsp-server"]),
    ],
    dependencies: [
        // LSP
        .package(url: "https://github.com/ChimeHQ/LanguageServer", branch: "main"),
        // Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
        // Arg parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        // Puppy logging
        .package(url: "https://github.com/sushichop/Puppy", from: "0.7.0"),
        // UniSocket
        .package(url: "https://github.com/koliyo/swift-unisocket", branch: "master"),
        // Concurrency Semaphores
        .package(url: "https://github.com/groue/Semaphore", from: "0.0.8"),
    ],

    targets: [
        .target(
            name: "pkl-lsp",
            dependencies: [
                .product(name: "LanguageServer", package: "LanguageServer"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Puppy", package: "Puppy"),
                .product(name: "UniSocket", package: "swift-unisocket"),
                .product(name: "Semaphore", package: "Semaphore"),
            ],
            path: "Sources/pkl-lsp"
        ),
        .executableTarget(
            name: "pkl-lsp-server",
            dependencies: [
                "pkl-lsp",
                .product(name: "LanguageServer", package: "LanguageServer"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Puppy", package: "Puppy"),
                .product(name: "UniSocket", package: "swift-unisocket"),
            ],
            path: "Sources/pkl-lsp-server"
        ),
    ]

)
