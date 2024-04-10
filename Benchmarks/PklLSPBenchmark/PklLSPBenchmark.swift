import Benchmark
import Foundation
import Logging
import pkl_lsp
import SwiftTreeSitter
import TreeSitterPkl

let benchmarks = {
    do {
        let parser = Parser()
        try parser.setLanguage(tree_sitter_pkl())
        let pklBaseStdlib = Resources.stdlib["base.pkl"]!
        Benchmark("Tree-sitter parsing") { benchmark in
            for _ in benchmark.scaledIterations {
                blackHole(_ = parser.parse(pklBaseStdlib))
            }
        }

        Benchmark("Abstract syntax tree constructing without dependencies") { benchmark in
            for _ in benchmark.scaledIterations {
                let astParser = TreeSitterParser(logger: Logger(label: "testLogger"), maxImportDepth: 0)
                await blackHole(astParser.parse(document: Document(uri: "stdlib:base.pkl", version: 0, text: pklBaseStdlib)))
            }
        }

        Benchmark("Abstract syntax tree construct with dependencies (maxImportDepth = 30)") { benchmark in
            for _ in benchmark.scaledIterations {
                let astParser = TreeSitterParser(logger: Logger(label: "testLogger"), maxImportDepth: 30)
                await blackHole(astParser.parse(document: Document(uri: "stdlib:base.pkl", version: 0, text: pklBaseStdlib)))
            }
        }
    } catch {
        print("Error benchmarking: \(error)")
    }
}
