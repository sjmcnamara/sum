import Foundation

/// Category of a suggestion, used for sort priority
enum SuggestionCategory: Int, Comparable {
    case function = 0
    case keyword = 1
    case unit = 2
    case currency = 3
    case variable = 4

    static func < (lhs: SuggestionCategory, rhs: SuggestionCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A single autocomplete suggestion
struct Suggestion: Equatable {
    let text: String
    let category: SuggestionCategory
}

/// Aggregates all known completions and performs prefix matching
struct SuggestionEngine {
    private var completions: [Suggestion] = []
    private var variableCompletions: [Suggestion] = []

    init() {
        buildCompletions()
    }

    /// Returns suggestions matching the given prefix, sorted by priority then length
    func suggest(prefix: String, limit: Int = 8) -> [Suggestion] {
        guard !prefix.isEmpty else { return [] }
        let lower = prefix.lowercased()
        let all = completions + variableCompletions
        var matches = all.filter { $0.text.lowercased().hasPrefix(lower) && $0.text != prefix }

        // Sort: exact prefix first, then by category priority, then shorter first
        matches.sort { a, b in
            if a.category != b.category { return a.category < b.category }
            return a.text.count < b.text.count
        }

        // Deduplicate by text (keep first, which has higher priority category)
        var seen = Set<String>()
        matches = matches.filter { s in
            let key = s.text.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        return Array(matches.prefix(limit))
    }

    /// Updates the set of user-defined variable names for completion
    mutating func updateVariables(_ names: [String]) {
        variableCompletions = names.map { Suggestion(text: $0, category: .variable) }
    }

    // MARK: - Build Completions

    private mutating func buildCompletions() {
        // Functions
        for name in Tokenizer.functionNames {
            completions.append(Suggestion(text: name, category: .function))
        }

        // Useful keywords
        let keywords = ["pi", "e", "tau", "phi", "sum", "total", "average", "avg",
                         "today", "now", "prev", "split", "between", "among",
                         "ways", "people", "tip", "tax",
                         "speedoflight", "lightspeed", "gravity", "avogadro",
                         "planck", "boltzmann", "echarge"]
        for kw in keywords {
            completions.append(Suggestion(text: kw, category: .keyword))
        }

        // Units from unitMap (use the first/canonical name for each unit)
        var seenUnits = Set<String>()
        for (name, _) in Tokenizer.unitMap {
            let lower = name.lowercased()
            // Skip very short abbreviations (1-2 chars) — they clutter suggestions
            guard lower.count >= 3 else { continue }
            guard !seenUnits.contains(lower) else { continue }
            seenUnits.insert(lower)
            completions.append(Suggestion(text: lower, category: .unit))
        }

        // Currency codes
        for code in Tokenizer.currencyCodes {
            completions.append(Suggestion(text: code, category: .currency))
        }

        // Crypto names (longer names, not tickers)
        for (name, _) in Tokenizer.cryptoNames where name.count >= 3 {
            if !Tokenizer.currencyCodes.contains(name.uppercased()) {
                completions.append(Suggestion(text: name, category: .currency))
            }
        }
    }
}
