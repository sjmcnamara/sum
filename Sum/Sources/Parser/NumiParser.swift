import Foundation
import os

/// The main expression parser and evaluator
class NumiParser {
    private var tokenizer = Tokenizer()
    private var variables: [String: NumiValue] = [:]
    private var previousResults: [NumiValue?] = []
    private var emSize: Double = 16 // default em in pixels
    private var ppi: Double = 96 // default pixels per inch

    /// Currency exchange rates relative to USD. Must only be set from @MainActor context.
    private(set) var currencyRates: [String: Double] = [:]

    func setCurrencyRates(_ rates: [String: Double]) {
        currencyRates = rates
    }

    /// Language-aware keyword tables — propagated to the tokenizer automatically
    var parserKeywords: ParserKeywords? {
        didSet { tokenizer.parserKeywords = parserKeywords }
    }

    // MARK: - Public API

    /// Parse and evaluate all lines, returning results for each
    func evaluateAll(_ text: String) -> [LineResult] {
        let lines = text.components(separatedBy: "\n")
        variables = [:]
        previousResults = []
        var results: [LineResult] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                results.append(LineResult(id: index, input: line, value: nil, error: nil, assignmentVariable: nil))
                previousResults.append(nil)
                continue
            }

            do {
                let (value, assignVar) = try evaluateLineWithMeta(trimmed, lineIndex: index, allResults: results)
                results.append(LineResult(id: index, input: line, value: value, error: nil, assignmentVariable: assignVar))
                previousResults.append(value)
            } catch {
                let errorMsg = describeError(error)
                NumiLogger.parser.debug("Line \(index): \(errorMsg) for: \(trimmed)")
                results.append(LineResult(id: index, input: line, value: nil, error: errorMsg, assignmentVariable: nil))
                previousResults.append(nil)
            }
        }

        return results
    }

    // MARK: - Line Evaluation

    /// Returns (value, assignmentVariableName?)
    private func evaluateLineWithMeta(_ line: String, lineIndex: Int, allResults: [LineResult]) throws -> (NumiValue?, String?) {
        let tokens = tokenizer.tokenize(line)
        if tokens.isEmpty { return (nil, nil) }

        // Handle variable assignment: varName = expression
        if tokens.count >= 3,
           case .variable(let name) = tokens[0],
           case .op(.assign) = tokens[1] {
            let exprTokens = Array(tokens.dropFirst(2))
            let value = try evaluate(exprTokens, lineIndex: lineIndex, allResults: allResults)
            if let v = value {
                variables[name] = v
            }
            return (value, name)
        }

        // Handle em/ppi assignment: em = 20px, ppi = 326
        if tokens.count >= 3,
           case .unit(let u) = tokens[0],
           case .op(.assign) = tokens[1] {
            if u == .em {
                let exprTokens = Array(tokens.dropFirst(2))
                if let v = try evaluate(exprTokens, lineIndex: lineIndex, allResults: allResults) {
                    emSize = v.number
                }
                return (nil, nil)
            }
        }

        let value = try evaluate(tokens, lineIndex: lineIndex, allResults: allResults)
        return (value, nil)
    }

    // MARK: - Core Evaluation

    private func evaluate(_ tokens: [Token], lineIndex: Int, allResults: [LineResult]) throws -> NumiValue? {
        // Strip leading noise words ("what", "is", "whats") for natural language queries
        let effectiveTokens = stripLeadingNoise(tokens)
        guard !effectiveTokens.isEmpty else { return nil }

        var pos = 0

        func peek() -> Token? {
            pos < effectiveTokens.count ? effectiveTokens[pos] : nil
        }

        func advance() -> Token? {
            guard pos < effectiveTokens.count else { return nil }
            let t = effectiveTokens[pos]
            pos += 1
            return t
        }

        // Check for split pattern: "$200 split 4 ways", "20% tip on $85 split 3 ways"
        if let result = try trySplitPattern(effectiveTokens, lineIndex: lineIndex, allResults: allResults) {
            return result
        }

        // Check for percentage pattern: "X% of/on/off Y"
        if let result = tryPercentagePattern(effectiveTokens, lineIndex: lineIndex, allResults: allResults) {
            return result
        }

        let result = try parseExpression(&pos, tokens: effectiveTokens, lineIndex: lineIndex, allResults: allResults)

        // Check for unit conversion: "... in unit" or "... to unit"
        if pos < effectiveTokens.count {
            if case .keyword(let kw) = effectiveTokens[pos], [.in, .into, .as, .to].contains(kw) {
                pos += 1
                if pos < effectiveTokens.count {
                    // Display format keywords (sci, hex, binary, etc.) — also localized
                    if case .variable(let name) = effectiveTokens[pos] {
                        let formatWords = parserKeywords?.displayFormatWords ?? [
                            "sci": .scientific, "hex": .hex,
                            "binary": .binary, "bin": .binary,
                            "octal": .octal, "oct": .octal,
                        ]
                        if let displayUnit = formatWords[name.lowercased()], let r = result {
                            return NumiValue(r.number, unit: displayUnit)
                        }
                    }

                    if case .unit(let targetUnit) = effectiveTokens[pos] {
                        if let r = result {
                            return try convertUnit(r, to: targetUnit)
                        }
                    }
                }
            }
        }

        return result
    }

    // MARK: - Expression Parsing (Precedence Climbing)

    private func parseExpression(
        _ pos: inout Int,
        tokens: [Token],
        lineIndex: Int,
        allResults: [LineResult],
        minPrec: Int = 0
    ) throws -> NumiValue? {
        var left = try parseUnary(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)

        while pos < tokens.count {
            guard case .op(let op) = tokens[pos], op != .assign, op != .bitwiseNot, op.precedence >= minPrec else {
                break
            }
            pos += 1
            let right = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults, minPrec: op.precedence + 1)

            left = try applyOperator(op, left: left, right: right)
        }

        // Handle implicit unit after expression: "5 km", "100 USD"
        if pos < tokens.count, let left = left, left.unit == nil {
            if case .unit(let u) = tokens[pos] {
                pos += 1
                // Check for percentage operations: "$10 + 20%", "$10 - 40%"
                // This is handled in applyOperator when right has .percent unit
                return NumiValue(left.number, unit: u)
            }
        }

        return left
    }

    // MARK: - Unary

    private func parseUnary(
        _ pos: inout Int,
        tokens: [Token],
        lineIndex: Int,
        allResults: [LineResult]
    ) throws -> NumiValue? {
        guard pos < tokens.count else { return nil }

        // Unary minus
        if case .op(.subtract) = tokens[pos] {
            pos += 1
            let val = try parsePrimary(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
            if let v = val {
                return NumiValue(-v.number, unit: v.unit)
            }
            return nil
        }

        // Bitwise NOT
        if case .op(.bitwiseNot) = tokens[pos] {
            pos += 1
            let val = try parsePrimary(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
            if let v = val {
                return NumiValue(Double(~Int(v.number)), unit: v.unit)
            }
            return nil
        }

        // Unary plus
        if case .op(.add) = tokens[pos] {
            pos += 1
        }

        return try parsePrimary(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
    }

    // MARK: - Primary

    private func parsePrimary(
        _ pos: inout Int,
        tokens: [Token],
        lineIndex: Int,
        allResults: [LineResult]
    ) throws -> NumiValue? {
        guard pos < tokens.count else { return nil }

        let token = tokens[pos]

        switch token {
        case .number(let n):
            pos += 1
            // Check for unit immediately after number
            if pos < tokens.count, case .unit(let u) = tokens[pos] {
                pos += 1

                // Percentage with operator: "10% of 200"
                if u == .percent {
                    // Skip noise words "tip"/"tax" after percentage
                    if pos < tokens.count, case .keyword(let nkw) = tokens[pos],
                       nkw == .tip || nkw == .tax {
                        pos += 1
                    }
                    if pos < tokens.count, case .keyword(let kw) = tokens[pos] {
                        switch kw {
                        case .of:
                            pos += 1
                            let val = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
                            if let v = val {
                                return NumiValue(v.number * n / 100, unit: v.unit)
                            }
                        case .on:
                            pos += 1
                            // Check for "what is"
                            if pos < tokens.count, case .keyword(.what) = tokens[pos] {
                                pos += 1
                                if pos < tokens.count, case .keyword(.is) = tokens[pos] { pos += 1 }
                                let val = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
                                if let v = val {
                                    // X% on what is Y => Y / (1 + X/100)
                                    return NumiValue(v.number / (1 + n / 100), unit: v.unit)
                                }
                            }
                            let val = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
                            if let v = val {
                                return NumiValue(v.number + v.number * n / 100, unit: v.unit)
                            }
                        case .off:
                            pos += 1
                            if pos < tokens.count, case .keyword(.what) = tokens[pos] {
                                pos += 1
                                if pos < tokens.count, case .keyword(.is) = tokens[pos] { pos += 1 }
                                let val = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
                                if let v = val {
                                    // X% off what is Y => Y / (1 - X/100)
                                    return NumiValue(v.number / (1 - n / 100), unit: v.unit)
                                }
                            }
                            let val = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
                            if let v = val {
                                return NumiValue(v.number - v.number * n / 100, unit: v.unit)
                            }
                        default: break
                        }
                    }
                    return NumiValue(n, unit: .percent)
                }

                return NumiValue(n, unit: u)
            }
            return NumiValue(n)

        case .unit(let u):
            pos += 1
            // Currency prefix like $100
            if case .currency = u {
                if pos < tokens.count, case .number(let n) = tokens[pos] {
                    pos += 1
                    return NumiValue(n, unit: u)
                }
            }
            // Unit used as conversion target or standalone
            return nil

        case .leftParen:
            pos += 1
            let val = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
            if pos < tokens.count, case .rightParen = tokens[pos] {
                pos += 1
            }
            return val

        case .function(let name):
            pos += 1
            // Expect parenthesis or direct argument
            var arg: NumiValue?
            if pos < tokens.count, case .leftParen = tokens[pos] {
                pos += 1
                arg = try parseExpression(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
                if pos < tokens.count, case .rightParen = tokens[pos] {
                    pos += 1
                }
            } else {
                arg = try parsePrimary(&pos, tokens: tokens, lineIndex: lineIndex, allResults: allResults)
            }
            return applyFunction(name, arg: arg)

        case .keyword(let kw):
            pos += 1
            switch kw {
            case .pi:
                return NumiValue(.pi)
            case .e:
                return NumiValue(M_E)
            case .tau:
                return NumiValue(.pi * 2)
            case .phi:
                return NumiValue(1.6180339887498948)
            case .speedoflight:
                return NumiValue(299_792_458, unit: .metersPerSecond)
            case .gravity:
                return NumiValue(6.67430e-11)
            case .avogadro:
                return NumiValue(6.02214076e23)
            case .planck:
                return NumiValue(6.62607015e-34)
            case .boltzmann:
                return NumiValue(1.380649e-23)
            case .echarge:
                return NumiValue(1.602176634e-19)
            case .today:
                let cal = Calendar.current
                let start = cal.startOfDay(for: Date())
                return NumiValue(start.timeIntervalSince1970, unit: .date)
            case .now:
                return NumiValue(Date().timeIntervalSince1970, unit: .date)
            case .prev:
                if lineIndex > 0, let prev = previousResults[safe: lineIndex - 1] {
                    return prev
                }
                return nil
            case .sum, .total:
                return computeAggregate(allResults, lineIndex: lineIndex, mode: .sum)
            case .average, .avg:
                return computeAggregate(allResults, lineIndex: lineIndex, mode: .average)
            default:
                return nil
            }

        case .variable(let name):
            pos += 1
            if let val = variables[name] {
                return val
            }
            // Unknown variable — skip
            return nil

        case .word:
            pos += 1
            return nil

        default:
            pos += 1
            return nil
        }
    }

    // MARK: - Percentage Patterns

    private func tryPercentagePattern(_ tokens: [Token], lineIndex: Int, allResults: [LineResult]) -> NumiValue? {
        // Pattern: "$50 as a % of $100"
        // Find "as" followed by "%" and "of"
        for i in 0..<tokens.count {
            if case .keyword(.as) = tokens[i] {
                // Look for % followed by "of" or "on" or "off"
                var j = i + 1
                // skip "a"
                if j < tokens.count, case .variable(let w) = tokens[j], w.lowercased() == "a" {
                    j += 1
                }
                if j < tokens.count, case .unit(.percent) = tokens[j] {
                    j += 1
                    if j < tokens.count, case .keyword(let kw) = tokens[j], [.of, .on, .off].contains(kw) {
                        let mode = kw
                        j += 1
                        // Parse left side (before "as")
                        var pos1 = 0
                        let leftTokens = Array(tokens[0..<i])
                        let rightTokens = Array(tokens[j...])
                        guard let left = try? parseExpression(&pos1, tokens: leftTokens, lineIndex: lineIndex, allResults: allResults, minPrec: 0) else { continue }
                        var pos2 = 0
                        guard let right = try? parseExpression(&pos2, tokens: rightTokens, lineIndex: lineIndex, allResults: allResults, minPrec: 0) else { continue }

                        switch mode {
                        case .of:
                            // $50 as a % of $100 = 50%
                            return NumiValue(left.number / right.number * 100, unit: .percent)
                        case .on:
                            // $70 as a % on $20 = 250%
                            return NumiValue((left.number / right.number - 1) * 100, unit: .percent)
                        case .off:
                            // $20 as a % off $70 ≈ 71.43%
                            return NumiValue((1 - left.number / right.number) * 100, unit: .percent)
                        default: break
                        }
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Split Pattern

    /// Matches patterns like "$200 split 4 ways", "split $120 between 4 people",
    /// "20% tip on $85 split 3 ways", "what's $200 split 4 ways"
    private func trySplitPattern(_ tokens: [Token], lineIndex: Int, allResults: [LineResult]) throws -> NumiValue? {
        // Find the position of .keyword(.split)
        var splitPos: Int?
        for i in 0..<tokens.count {
            if case .keyword(.split) = tokens[i] {
                splitPos = i
                break
            }
        }
        guard let sp = splitPos else { return nil }

        // Extract the value part and the divisor
        var valueTokens: [Token]
        var divisorTokens: [Token]

        if sp == 0 {
            // "split $120 between 4 people" or "split $120 4 ways"
            let afterSplit = Array(tokens[(sp + 1)...])
            let stripped = stripLeadingNoise(afterSplit)
            // Find the divisor: look for between/among, or the last number
            let (valToks, divToks) = splitValueAndDivisor(stripped)
            valueTokens = valToks
            divisorTokens = divToks
        } else {
            // "$200 split 4 ways" or "20% tip on $85 split 3 ways"
            valueTokens = stripLeadingNoise(Array(tokens[0..<sp]))
            let afterSplit = Array(tokens[(sp + 1)...])
            // Skip optional "between"/"among" after split
            divisorTokens = skipBetweenAmong(afterSplit)
        }

        // Strip trailing noise (ways, people)
        divisorTokens = stripTrailingNoise(divisorTokens)

        guard !valueTokens.isEmpty, !divisorTokens.isEmpty else { return nil }

        // Parse the divisor
        var dPos = 0
        let divisor = try parseExpression(&dPos, tokens: divisorTokens, lineIndex: lineIndex, allResults: allResults)
        guard let d = divisor, d.number != 0 else {
            if let d = divisor, d.number == 0 {
                throw NumiError.divisionByZero
            }
            return nil
        }

        // Parse the value expression (may contain tip/tax patterns)
        let value = try evaluate(valueTokens, lineIndex: lineIndex, allResults: allResults)
        guard let v = value else { return nil }

        return NumiValue(v.number / d.number, unit: v.unit)
    }

    /// Strips leading noise words: "what", "is", single-letter variable "s" (from "what's")
    private func stripLeadingNoise(_ tokens: [Token]) -> [Token] {
        let noiseWords = parserKeywords?.leadingNoiseWords ?? ["what", "is"]
        let noiseVars = parserKeywords?.leadingNoiseVariables ?? ["s", "whats"]
        var i = 0
        while i < tokens.count {
            switch tokens[i] {
            case .keyword(let kw) where noiseWords.contains(kw.rawValue):
                i += 1
            case .variable(let v) where noiseVars.contains(v.lowercased()):
                i += 1
            default:
                return Array(tokens[i...])
            }
        }
        return []
    }

    /// For "split VALUE between N people" pattern: splits after between/among keyword
    private func splitValueAndDivisor(_ tokens: [Token]) -> ([Token], [Token]) {
        for i in 0..<tokens.count {
            if case .keyword(let kw) = tokens[i], kw == .between || kw == .among {
                let valuePart = Array(tokens[0..<i])
                let divisorPart = Array(tokens[(i + 1)...])
                return (valuePart, stripTrailingNoise(divisorPart))
            }
        }
        // No between/among: last number is the divisor, rest is value
        // e.g., "split $120 4 ways" → value=$120, divisor=4
        // Find the last number token
        for i in stride(from: tokens.count - 1, through: 0, by: -1) {
            if case .number = tokens[i] {
                let valuePart = Array(tokens[0..<i])
                let divisorPart = [tokens[i]]
                return (valuePart, divisorPart)
            }
        }
        return (tokens, [])
    }

    /// Skips optional "between"/"among" at the start of tokens
    private func skipBetweenAmong(_ tokens: [Token]) -> [Token] {
        guard let first = tokens.first else { return tokens }
        if case .keyword(let kw) = first, kw == .between || kw == .among {
            return Array(tokens.dropFirst())
        }
        return tokens
    }

    /// Strips trailing noise: "ways", "people" (and localized equivalents)
    private func stripTrailingNoise(_ tokens: [Token]) -> [Token] {
        let noiseKeywords = parserKeywords?.trailingNoiseKeywords ?? [.ways, .people]
        var result = tokens
        while let last = result.last {
            if case .keyword(let kw) = last, noiseKeywords.contains(kw) {
                result.removeLast()
            } else {
                break
            }
        }
        return result
    }

    // MARK: - Apply Operator

    private func applyOperator(_ op: Operator, left: NumiValue?, right: NumiValue?) throws -> NumiValue? {
        guard let l = left, let r = right else {
            return left ?? right
        }

        // Percentage arithmetic: "$10 + 20%" means "$10 + 20% of $10"
        if r.unit == .percent && op == .add {
            let amount = l.number * r.number / 100
            return NumiValue(l.number + amount, unit: l.unit)
        }
        if r.unit == .percent && op == .subtract {
            let amount = l.number * r.number / 100
            return NumiValue(l.number - amount, unit: l.unit)
        }

        // Currency arithmetic: convert to same currency
        if case .currency(let lCode) = l.unit, case .currency(let rCode) = r.unit, lCode != rCode {
            let converted = convertCurrency(r.number, from: rCode, to: lCode)
            let rConverted = NumiValue(converted, unit: l.unit)
            return try applyOperator(op, left: l, right: rConverted)
        }

        // Same unit arithmetic
        let resultUnit = l.unit ?? r.unit

        switch op {
        case .add:
            // If both have units in the same category, convert right to left's unit
            if let lu = l.unit, let ru = r.unit, lu != ru,
               let lCat = lu.category, let rCat = ru.category, lCat == rCat {
                let rInBase = r.number * ru.toBaseRatio
                let rInLeft = rInBase / lu.toBaseRatio
                return NumiValue(l.number + rInLeft, unit: lu)
            }
            return NumiValue(l.number + r.number, unit: resultUnit)

        case .subtract:
            if let lu = l.unit, let ru = r.unit, lu != ru,
               let lCat = lu.category, let rCat = ru.category, lCat == rCat {
                let rInBase = r.number * ru.toBaseRatio
                let rInLeft = rInBase / lu.toBaseRatio
                return NumiValue(l.number - rInLeft, unit: lu)
            }
            return NumiValue(l.number - r.number, unit: resultUnit)

        case .multiply:
            return NumiValue(l.number * r.number, unit: resultUnit)

        case .divide:
            guard r.number != 0 else { throw NumiError.divisionByZero }
            return NumiValue(l.number / r.number, unit: l.unit)

        case .power:
            return NumiValue(pow(l.number, r.number), unit: l.unit)

        case .modulo:
            guard r.number != 0 else { throw NumiError.divisionByZero }
            return NumiValue(l.number.truncatingRemainder(dividingBy: r.number), unit: l.unit)

        case .bitwiseAnd:
            return NumiValue(Double(Int(l.number) & Int(r.number)), unit: resultUnit)
        case .bitwiseOr:
            return NumiValue(Double(Int(l.number) | Int(r.number)), unit: resultUnit)
        case .bitwiseXor:
            return NumiValue(Double(Int(l.number) ^ Int(r.number)), unit: resultUnit)
        case .shiftLeft:
            return NumiValue(Double(Int(l.number) << Int(r.number)), unit: l.unit)
        case .shiftRight:
            return NumiValue(Double(Int(l.number) >> Int(r.number)), unit: l.unit)

        case .assign:
            return r

        case .bitwiseNot:
            // Unary — handled in parseUnary(), should not reach here
            return l
        }
    }

    // MARK: - Unit Conversion

    private func convertUnit(_ value: NumiValue, to target: NumiUnit) throws -> NumiValue {
        guard let sourceUnit = value.unit else {
            // No source unit, just apply target
            return NumiValue(value.number, unit: target)
        }

        // Temperature special handling
        if sourceUnit.category == .temperature && target.category == .temperature {
            return NumiValue(convertTemperature(value.number, from: sourceUnit, to: target), unit: target)
        }

        // Currency conversion
        if case .currency(let fromCode) = sourceUnit, case .currency(let toCode) = target {
            let converted = convertCurrency(value.number, from: fromCode, to: toCode)
            return NumiValue(converted, unit: target)
        }

        // General unit conversion via base unit
        guard let srcCat = sourceUnit.category, let tgtCat = target.category, srcCat == tgtCat else {
            throw NumiError.incompatibleUnits(from: sourceUnit.symbol, to: target.symbol)
        }

        // CSS units need special handling for em
        if srcCat == .css {
            let srcPx = value.number * cssToPixels(sourceUnit)
            let result = srcPx / cssToPixels(target)
            return NumiValue(result, unit: target)
        }

        let inBase = value.number * sourceUnit.toBaseRatio
        let result = inBase / target.toBaseRatio
        return NumiValue(result, unit: target)
    }

    private func cssToPixels(_ unit: NumiUnit) -> Double {
        switch unit {
        case .pixel: return 1
        case .point: return ppi / 72.0
        case .em: return emSize
        default: return 1
        }
    }

    private func convertTemperature(_ value: Double, from: NumiUnit, to: NumiUnit) -> Double {
        // Convert to Celsius first
        var celsius: Double
        switch from {
        case .celsius: celsius = value
        case .fahrenheit: celsius = (value - 32) * 5.0 / 9.0
        case .kelvin: celsius = value - 273.15
        default: celsius = value
        }

        // Convert from Celsius to target
        switch to {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9.0 / 5.0 + 32
        case .kelvin: return celsius + 273.15
        default: return celsius
        }
    }

    private func convertCurrency(_ amount: Double, from: String, to: String) -> Double {
        // Handle SATS (satoshis): 1 BTC = 100,000,000 SATS
        let effectiveFrom = from
        let effectiveTo = to
        var effectiveAmount = amount

        if from == "SATS" {
            // Convert sats to BTC first, then convert BTC to target
            effectiveAmount = amount / 100_000_000
            if to == "BTC" { return effectiveAmount }
            guard let btcRate = currencyRates["BTC"], let toRate = currencyRates[effectiveTo] else {
                return amount
            }
            let inUSD = effectiveAmount / btcRate
            return inUSD * toRate
        }

        if to == "SATS" {
            // Convert source to BTC, then BTC to sats
            if from == "BTC" { return amount * 100_000_000 }
            guard let fromRate = currencyRates[effectiveFrom], let btcRate = currencyRates["BTC"] else {
                return amount
            }
            let inUSD = amount / fromRate
            let inBTC = inUSD * btcRate
            return inBTC * 100_000_000
        }

        guard let fromRate = currencyRates[effectiveFrom], let toRate = currencyRates[effectiveTo] else {
            return amount
        }
        // Both rates are relative to USD
        let inUSD = effectiveAmount / fromRate
        return inUSD * toRate
    }

    // MARK: - Functions

    private func applyFunction(_ name: String, arg: NumiValue?) -> NumiValue? {
        guard let a = arg else { return nil }
        let n = a.number

        switch name {
        case "sqrt": return NumiValue(sqrt(n))
        case "cbrt": return NumiValue(cbrt(n))
        case "abs": return NumiValue(abs(n), unit: a.unit)
        case "log": return NumiValue(log10(n))
        case "log10": return NumiValue(log10(n))
        case "log2": return NumiValue(log2(n))
        case "ln": return NumiValue(log(n))
        case "sin": return NumiValue(sin(n))
        case "cos": return NumiValue(cos(n))
        case "tan": return NumiValue(tan(n))
        case "asin", "arcsin": return NumiValue(asin(n))
        case "acos", "arccos": return NumiValue(acos(n))
        case "atan", "arctan": return NumiValue(atan(n))
        case "sinh": return NumiValue(sinh(n))
        case "cosh": return NumiValue(cosh(n))
        case "tanh": return NumiValue(tanh(n))
        case "round": return NumiValue(n.rounded(), unit: a.unit)
        case "ceil": return NumiValue(ceil(n), unit: a.unit)
        case "floor": return NumiValue(floor(n), unit: a.unit)
        case "fact":
            if n >= 0 && n <= 170 && n == n.rounded() {
                return NumiValue(factorial(Int(n)))
            }
            return nil
        case "fromunix":
            return NumiValue(n, unit: .date)
        default:
            return nil
        }
    }

    private func factorial(_ n: Int) -> Double {
        guard n >= 0 else { return 1 } // defense in depth
        if n <= 1 { return 1 }
        return Double(n) * factorial(n - 1)
    }

    // MARK: - Aggregates

    private enum AggregateMode { case sum, average }

    private func computeAggregate(_ results: [LineResult], lineIndex: Int, mode: AggregateMode) -> NumiValue? {
        var values: [Double] = []
        var unit: NumiUnit?

        // Go backwards from current line until empty line
        var i = lineIndex - 1
        while i >= 0 {
            let result = results[i]
            if result.input.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }
            if let v = result.value {
                values.append(v.number)
                if unit == nil { unit = v.unit }
            }
            i -= 1
        }

        guard !values.isEmpty else { return nil }

        switch mode {
        case .sum:
            return NumiValue(values.reduce(0, +), unit: unit)
        case .average:
            return NumiValue(values.reduce(0, +) / Double(values.count), unit: unit)
        }
    }
}

// MARK: - Errors

enum NumiError: Error {
    case divisionByZero
    case invalidExpression(detail: String? = nil)
    case incompatibleUnits(from: String, to: String)
    case unknownIdentifier(name: String)
}

extension NumiParser {
    /// Converts a caught error into a short user-facing message
    func describeError(_ error: Error) -> String {
        let messages = parserKeywords?.errorMessages
        if let numiError = error as? NumiError {
            switch numiError {
            case .divisionByZero:
                return messages?["divisionByZero"] ?? "÷ by 0"
            case .invalidExpression(let detail):
                if let detail { return detail }
                return messages?["invalidExpression"] ?? "invalid"
            case .incompatibleUnits(let from, let to):
                return "\(from) \u{2260} \(to)"
            case .unknownIdentifier(let name):
                let prefix = messages?["unknownPrefix"] ?? "unknown"
                return "\(prefix): \(name)"
            }
        }
        return messages?["genericError"] ?? "error"
    }
}

// MARK: - Safe Array Access

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
