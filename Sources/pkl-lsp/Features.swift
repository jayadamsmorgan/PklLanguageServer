import ArgumentParser
import Foundation

public enum FeatureType: String, ExpressibleByArgument, Decodable {
    case completion
    case rename
    case documentSymbols
    case semanticTokens
    case definition
    case diagnostics
}

public class Feature: Decodable {
    let type: FeatureType

    let isExperimental: Bool
    var isEnabled: Bool

    public init(type: FeatureType, isExperimental: Bool, isEnabled: Bool) {
        self.type = type
        self.isExperimental = isExperimental
        self.isEnabled = isEnabled
    }
}

public let completionFeature = Feature(type: .completion, isExperimental: false, isEnabled: true)
public let renameFeature = Feature(type: .rename, isExperimental: true, isEnabled: false)
public let documentSymbolsFeature = Feature(type: .documentSymbols, isExperimental: false, isEnabled: true)
public let semanticTokensFeature = Feature(type: .semanticTokens, isExperimental: true, isEnabled: false)
public let definitionFeature = Feature(type: .definition, isExperimental: false, isEnabled: true)
public let diagnosticsFeature = Feature(type: .diagnostics, isExperimental: true, isEnabled: false)

public let features: [Feature] = [completionFeature, renameFeature, documentSymbolsFeature, semanticTokensFeature, definitionFeature, diagnosticsFeature]
