import Benchmark
import Foundation
import pkl_lsp
import SwiftTreeSitter
import TreeSitterPkl
import Logging

let benchmarks = {
    do {
        let parser = Parser()
        try parser.setLanguage(tree_sitter_pkl())
        let pklMathStdlib = Resources.stdlib["math.pkl"]!
        Benchmark("Tree-sitter parsing") { benchmark in
            for _ in benchmark.scaledIterations {
                blackHole(_ = parser.parse(pklMathStdlib))
            }
        }

        var astParser = TreeSitterParser(logger: Logger(label: "testLogger"), maxImportDepth: 0)
        Benchmark("Abstract syntax tree constructing without dependencies") { benchmark in
            for _ in benchmark.scaledIterations {
                blackHole(await astParser.parse(document: Document(uri: "stdlib:math.pkl", version: 0, text: pklMathStdlib)))
            }
        }

        astParser = TreeSitterParser(logger: Logger(label: "testLogger"), maxImportDepth: 30)
        Benchmark("Abstract syntax tree construct with dependencies (maxImportDepth = 30)") { benchmark in
            for _ in benchmark.scaledIterations {
                blackHole(await astParser.parse(document: Document(uri: "stdlib:math.pkl", version: 0, text: pklMathStdlib)))
            }
        }
    } catch {
        print("Error benchmarking: \(error)")
    }
}
