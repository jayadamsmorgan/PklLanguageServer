// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PklLanguageServer",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "pkl-lsp", targets: ["pkl-lsp"]),
        .executable(name: "pkl-lsp-server", targets: ["pkl-lsp-server"]),
    ],
    dependencies: [
        // LSP
        .package(url: "https://github.com/jayadamsmorgan/LanguageServer", revision: "main"),
        // Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
        // Arg parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        // UniSocket
        .package(url: "https://github.com/koliyo/swift-unisocket", branch: "master"),
        // Concurrency Semaphores
        .package(url: "https://github.com/groue/Semaphore", from: "0.0.8"),
        // Swift Tree Sitter Library
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.8.0"),
        // Pkl Tree Sitter
        .package(url: "https://github.com/apple/tree-sitter-pkl", revision: "main"),

        // Benchmarking
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.22.4")),
    ],

    targets: [
        .target(
            name: "pkl-lsp",
            dependencies: [
                .product(name: "LanguageServer", package: "LanguageServer"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "UniSocket", package: "swift-unisocket"),
                .product(name: "Semaphore", package: "Semaphore"),
                .product(name: "SwiftTreeSitterLayer", package: "SwiftTreeSitter"),
                .product(name: "TreeSitterPkl", package: "tree-sitter-pkl"),
            ],
            path: "Sources/pkl-lsp",
            swiftSettings: [
                .enableExperimentalFeature("SwiftConcurrency"),
            ]
        ),
        .executableTarget(
            name: "pkl-lsp-server",
            dependencies: [
                "pkl-lsp",
                .product(name: "LanguageServer", package: "LanguageServer"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "UniSocket", package: "swift-unisocket"),
            ],
            path: "Sources/pkl-lsp-server",
            swiftSettings: [
                .enableExperimentalFeature("SwiftConcurrency"),
            ]
        ),
        .testTarget(
            name: "PklLSPTests",
            dependencies: [
                "pkl-lsp",
            ],
            swiftSettings: [
                .enableExperimentalFeature("SwiftConcurrency"),
            ]
        ),
        // Benchmark of PklLSPBenchmark
        .executableTarget(
            name: "PklLSPBenchmark",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                "pkl-lsp",
                .product(name: "SwiftTreeSitterLayer", package: "SwiftTreeSitter"),
                .product(name: "TreeSitterPkl", package: "tree-sitter-pkl"),
            ],
            path: "Benchmarks/PklLSPBenchmark",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
