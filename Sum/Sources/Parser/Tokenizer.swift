import Foundation

/// Tokenizes a line of text into tokens for the parser
struct Tokenizer {

    // MARK: - Unit Lookup

    static let unitMap: [(String, NumiUnit)] = [
        // Length
        ("kilometers", .kilometer), ("kilometer", .kilometer), ("km", .kilometer),
        ("meters", .meter), ("meter", .meter), ("m", .meter),
        ("centimeters", .centimeter), ("centimeter", .centimeter), ("cm", .centimeter),
        ("millimeters", .millimeter), ("millimeter", .millimeter), ("mm", .millimeter),
        ("micrometers", .micrometer), ("micrometer", .micrometer), ("µm", .micrometer), ("um", .micrometer),
        ("nanometers", .nanometer), ("nanometer", .nanometer), ("nm", .nanometer),
        ("inches", .inch), ("inch", .inch), ("in", .inch),
        ("feet", .foot), ("foot", .foot), ("ft", .foot),
        ("yards", .yard), ("yard", .yard), ("yd", .yard),
        ("miles", .mile), ("mile", .mile), ("mi", .mile),
        ("nautical miles", .nauticalMile), ("nautical mile", .nauticalMile), ("nmi", .nauticalMile),

        // Weight
        ("kilograms", .kilogram), ("kilogram", .kilogram), ("kg", .kilogram),
        ("grams", .gram), ("gram", .gram), ("g", .gram),
        ("milligrams", .milligram), ("milligram", .milligram), ("mg", .milligram),
        ("tonnes", .tonne), ("tonne", .tonne), ("metric tons", .tonne), ("metric ton", .tonne),
        ("pounds", .pound), ("pound", .pound), ("lbs", .pound), ("lb", .pound),
        ("ounces", .ounce), ("ounce", .ounce), ("oz", .ounce),
        ("stones", .stone), ("stone", .stone), ("st", .stone),
        ("carats", .carat), ("carat", .carat), ("ct", .carat),

        // Temperature
        ("celsius", .celsius), ("°c", .celsius), ("°C", .celsius),
        ("fahrenheit", .fahrenheit), ("°f", .fahrenheit), ("°F", .fahrenheit),
        ("kelvin", .kelvin),

        // Area
        ("square meters", .squareMeter), ("sq m", .squareMeter), ("m²", .squareMeter), ("m2", .squareMeter),
        ("square kilometers", .squareKilometer), ("sq km", .squareKilometer), ("km²", .squareKilometer), ("km2", .squareKilometer),
        ("square feet", .squareFoot), ("sq ft", .squareFoot), ("ft²", .squareFoot), ("ft2", .squareFoot),
        ("square inches", .squareInch), ("sq in", .squareInch), ("in²", .squareInch), ("in2", .squareInch),
        ("square yards", .squareYard), ("sq yd", .squareYard), ("yd²", .squareYard),
        ("square miles", .squareMile), ("sq mi", .squareMile), ("mi²", .squareMile),
        ("hectares", .hectare), ("hectare", .hectare), ("ha", .hectare),
        ("acres", .acre), ("acre", .acre), ("ac", .acre),

        // Volume
        ("cubic meters", .cubicMeter), ("cu m", .cubicMeter), ("m³", .cubicMeter), ("m3", .cubicMeter), ("cbm", .cubicMeter),
        ("liters", .liter), ("liter", .liter), ("litres", .liter), ("litre", .liter), ("l", .liter),
        ("milliliters", .milliliter), ("milliliter", .milliliter), ("ml", .milliliter),
        ("gallons", .gallon), ("gallon", .gallon), ("gal", .gallon),
        ("quarts", .quart), ("quart", .quart), ("qt", .quart),
        ("pints", .pint), ("pint", .pint),
        ("cups", .cup), ("cup", .cup),
        ("tablespoons", .tablespoon), ("tablespoon", .tablespoon), ("tbsp", .tablespoon), ("table spoon", .tablespoon),
        ("teaspoons", .teaspoon), ("teaspoon", .teaspoon), ("tsp", .teaspoon), ("tea spoon", .teaspoon),
        ("cubic feet", .cubicFoot), ("cu ft", .cubicFoot), ("ft³", .cubicFoot),
        ("cubic inches", .cubicInch), ("cu in", .cubicInch), ("in³", .cubicInch),

        // Time
        ("years", .year), ("year", .year), ("yr", .year),
        ("months", .month), ("month", .month),
        ("weeks", .week), ("week", .week),
        ("days", .day), ("day", .day),
        ("hours", .hour), ("hour", .hour), ("hrs", .hour), ("hr", .hour),
        ("minutes", .minute), ("minute", .minute), ("mins", .minute), ("min", .minute),
        ("seconds", .second), ("second", .second), ("secs", .second), ("sec", .second),
        ("milliseconds", .millisecond), ("millisecond", .millisecond), ("ms", .millisecond),

        // Data
        ("terabytes", .terabyte), ("terabyte", .terabyte), ("TB", .terabyte),
        ("tebibytes", .tebibyte), ("tebibyte", .tebibyte), ("TiB", .tebibyte),
        ("gigabytes", .gigabyte), ("gigabyte", .gigabyte), ("GB", .gigabyte),
        ("gibibytes", .gibibyte), ("gibibyte", .gibibyte), ("GiB", .gibibyte),
        ("megabytes", .megabyte), ("megabyte", .megabyte), ("MB", .megabyte),
        ("mebibytes", .mebibyte), ("mebibyte", .mebibyte), ("MiB", .mebibyte),
        ("kilobytes", .kilobyte), ("kilobyte", .kilobyte), ("KB", .kilobyte),
        ("kibibytes", .kibibyte), ("kibibyte", .kibibyte), ("KiB", .kibibyte),
        ("gigabits", .gigabit), ("gigabit", .gigabit), ("Gb", .gigabit), ("Gbit", .gigabit),
        ("megabits", .megabit), ("megabit", .megabit), ("Mb", .megabit), ("Mbit", .megabit),
        ("kilobits", .kilobit), ("kilobit", .kilobit), ("Kb", .kilobit), ("Kbit", .kilobit),
        ("bytes", .byte), ("byte", .byte),
        ("bits", .bit), ("bit", .bit),

        // Angle
        ("radians", .radian), ("radian", .radian), ("rad", .radian),
        ("degrees", .degree), ("degree", .degree), ("deg", .degree), ("°", .degree),

        // CSS
        ("pixels", .pixel), ("pixel", .pixel), ("px", .pixel),
        ("points", .point), ("pt", .point),
        ("em", .em),
    ]

    static let functionNames: Set<String> = [
        "sqrt", "cbrt", "abs", "log", "ln", "log2", "log10",
        "sin", "cos", "tan", "asin", "acos", "atan",
        "arcsin", "arccos", "arctan",
        "sinh", "cosh", "tanh",
        "round", "ceil", "floor", "fact",
        "fromunix",
    ]

    static let currencyCodes: Set<String> = [
        // Fiat
        "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY",
        "KRW", "RUB", "INR", "BRL", "MXN", "ZAR", "SEK", "NOK",
        "DKK", "NZD", "SGD", "HKD", "TRY", "PLN", "THB", "IDR",
        "HUF", "CZK", "ILS", "CLP", "PHP", "AED", "COP", "SAR",
        "MYR", "RON", "TWD", "ARS", "NGN", "UAH", "VND", "PKR",
        "EGP", "BDT", "QAR", "KWD", "BHD", "OMR",
        // Crypto
        "BTC", "ETH", "SOL", "BNB", "XRP", "ADA",
        "DOGE", "DOT", "AVAX", "MATIC", "LINK", "UNI",
        "LTC", "ATOM", "XLM", "ALGO", "NEAR", "FTM",
        "AAVE", "ARB", "OP", "APT", "SUI", "SEI",
        "SHIB", "PEPE", "USDT", "USDC", "DAI", "SATS",
    ]

    static let currencySymbols: [String: String] = [
        "$": "USD", "€": "EUR", "£": "GBP", "¥": "JPY",
        "₩": "KRW", "₽": "RUB", "₹": "INR", "R$": "BRL",
        "₿": "BTC", "Ξ": "ETH",
    ]

    /// Maps lowercase crypto names to tickers
    static let cryptoNames: [String: String] = [
        "bitcoin": "BTC", "btc": "BTC",
        "ethereum": "ETH", "ether": "ETH", "eth": "ETH",
        "solana": "SOL", "sol": "SOL",
        "binance": "BNB", "bnb": "BNB",
        "ripple": "XRP", "xrp": "XRP",
        "cardano": "ADA", "ada": "ADA",
        "dogecoin": "DOGE", "doge": "DOGE",
        "polkadot": "DOT", "dot": "DOT",
        "avalanche": "AVAX", "avax": "AVAX",
        "polygon": "MATIC", "matic": "MATIC",
        "chainlink": "LINK", "link": "LINK",
        "uniswap": "UNI", "uni": "UNI",
        "litecoin": "LTC", "ltc": "LTC",
        "cosmos": "ATOM", "atom": "ATOM",
        "stellar": "XLM", "xlm": "XLM",
        "algorand": "ALGO", "algo": "ALGO",
        "near": "NEAR",
        "fantom": "FTM", "ftm": "FTM",
        "aave": "AAVE",
        "arbitrum": "ARB", "arb": "ARB",
        "optimism": "OP",
        "aptos": "APT", "apt": "APT",
        "sui": "SUI",
        "sei": "SEI",
        "shiba": "SHIB", "shib": "SHIB",
        "pepe": "PEPE",
        "tether": "USDT", "usdt": "USDT",
        "usdc": "USDC",
        "dai": "DAI",
        "sats": "SATS", "satoshi": "SATS", "satoshis": "SATS",
    ]

    // MARK: - Tokenize

    func tokenize(_ input: String) -> [Token] {
        var tokens: [Token] = []
        var i = input.startIndex

        while i < input.endIndex {
            let ch = input[i]

            // Skip whitespace
            if ch.isWhitespace {
                i = input.index(after: i)
                continue
            }

            // Currency symbol prefix ($100, €50, ₿1.5, Ξ10, etc.)
            if let currencyCode = Self.currencySymbols[String(ch)] {
                let next = input.index(after: i)
                if next < input.endIndex && (input[next].isNumber || input[next] == ".") {
                    tokens.append(.unit(.currency(currencyCode)))
                    i = next
                    continue
                }
                // Standalone symbol (e.g. "in ₿", "to ETH")
                if currencyCode == "BTC" || currencyCode == "ETH" {
                    tokens.append(.unit(.currency(currencyCode)))
                    i = input.index(after: i)
                    continue
                }
            }

            // R$ (Brazilian Real)
            if ch == "R" {
                let next = input.index(after: i)
                if next < input.endIndex && input[next] == "$" {
                    let afterSymbol = input.index(after: next)
                    if afterSymbol < input.endIndex && (input[afterSymbol].isNumber || input[afterSymbol] == ".") {
                        tokens.append(.unit(.currency("BRL")))
                        i = afterSymbol
                        continue
                    }
                }
            }

            // Numbers (including hex, binary, octal)
            if ch.isNumber || (ch == "." && i < input.endIndex) {
                let (num, endIdx, numUnit) = parseNumber(input, from: i)
                if let n = num {
                    tokens.append(.number(n))
                    if let u = numUnit {
                        tokens.append(.unit(u))
                    }
                    i = endIdx
                    continue
                }
            }

            // Operators
            if let opResult = parseOperator(input, from: i) {
                tokens.append(.op(opResult.0))
                i = opResult.1
                continue
            }

            // Parentheses
            if ch == "(" {
                tokens.append(.leftParen)
                i = input.index(after: i)
                continue
            }
            if ch == ")" {
                tokens.append(.rightParen)
                i = input.index(after: i)
                continue
            }

            // Comma
            if ch == "," {
                // Check if it's a thousands separator (digit,digit pattern)
                if !tokens.isEmpty, case .number = tokens.last {
                    let next = input.index(after: i)
                    if next < input.endIndex && input[next].isNumber {
                        // Likely thousands separator, skip it
                        i = next
                        continue
                    }
                }
                tokens.append(.comma)
                i = input.index(after: i)
                continue
            }

            // Degree symbol
            if ch == "°" {
                let next = input.index(after: i)
                if next < input.endIndex {
                    let nextCh = input[next].lowercased()
                    if nextCh == "c" {
                        tokens.append(.unit(.celsius))
                        i = input.index(after: next)
                        continue
                    } else if nextCh == "f" {
                        tokens.append(.unit(.fahrenheit))
                        i = input.index(after: next)
                        continue
                    }
                }
                tokens.append(.unit(.degree))
                i = input.index(after: i)
                continue
            }

            // Percent sign
            if ch == "%" {
                tokens.append(.unit(.percent))
                i = input.index(after: i)
                continue
            }

            // Words (identifiers, keywords, units, functions)
            if ch.isLetter || ch == "_" {
                let (token, endIdx) = parseWord(input, from: i)
                tokens.append(token)
                i = endIdx
                continue
            }

            // Skip unrecognized characters
            i = input.index(after: i)
        }

        return tokens
    }

    // MARK: - Number Parsing

    private func parseNumber(_ input: String, from start: String.Index) -> (Double?, String.Index, NumiUnit?) {
        var i = start

        // Check for hex, binary, octal prefix
        if input[i] == "0" {
            let next = input.index(after: i)
            if next < input.endIndex {
                let prefix = input[next]
                if prefix == "x" || prefix == "X" {
                    return parseHex(input, from: input.index(after: next))
                }
                if prefix == "b" || prefix == "B" {
                    // Distinguish from 0b... (binary) vs "0 bytes"
                    let afterB = input.index(after: next)
                    if afterB < input.endIndex && (input[afterB] == "0" || input[afterB] == "1") {
                        return parseBinary(input, from: afterB)
                    }
                }
                if prefix == "o" || prefix == "O" {
                    return parseOctal(input, from: input.index(after: next))
                }
            }
        }

        // Regular decimal number
        var numStr = ""
        while i < input.endIndex && (input[i].isNumber || input[i] == ".") {
            numStr.append(input[i])
            i = input.index(after: i)
        }

        // Scientific notation (1.5e10, 2E-3)
        if i < input.endIndex && (input[i] == "e" || input[i] == "E") {
            let next = input.index(after: i)
            if next < input.endIndex && (input[next].isNumber || input[next] == "-" || input[next] == "+") {
                numStr.append("e")
                i = next
                if input[i] == "-" || input[i] == "+" {
                    numStr.append(input[i])
                    i = input.index(after: i)
                }
                while i < input.endIndex && input[i].isNumber {
                    numStr.append(input[i])
                    i = input.index(after: i)
                }
            }
        }

        guard let value = Double(numStr) else {
            return (nil, start, nil)
        }
        return (value, i, nil)
    }

    private func parseHex(_ input: String, from start: String.Index) -> (Double?, String.Index, NumiUnit?) {
        var i = start
        var hexStr = ""
        while i < input.endIndex && input[i].isHexDigit {
            hexStr.append(input[i])
            i = input.index(after: i)
        }
        guard let value = UInt64(hexStr, radix: 16) else {
            return (nil, start, nil)
        }
        return (Double(value), i, .hex)
    }

    private func parseBinary(_ input: String, from start: String.Index) -> (Double?, String.Index, NumiUnit?) {
        var i = start
        var binStr = ""
        while i < input.endIndex && (input[i] == "0" || input[i] == "1") {
            binStr.append(input[i])
            i = input.index(after: i)
        }
        guard let value = UInt64(binStr, radix: 2) else {
            return (nil, start, nil)
        }
        return (Double(value), i, .binary)
    }

    private func parseOctal(_ input: String, from start: String.Index) -> (Double?, String.Index, NumiUnit?) {
        var i = start
        var octStr = ""
        while i < input.endIndex && input[i] >= "0" && input[i] <= "7" {
            octStr.append(input[i])
            i = input.index(after: i)
        }
        guard let value = UInt64(octStr, radix: 8) else {
            return (nil, start, nil)
        }
        return (Double(value), i, .octal)
    }

    // MARK: - Operator Parsing

    private func parseOperator(_ input: String, from start: String.Index) -> (Operator, String.Index)? {
        let ch = input[start]
        let next = input.index(after: start)

        switch ch {
        case "+": return (.add, next)
        case "-": return (.subtract, next)
        case "*":
            if next < input.endIndex && input[next] == "*" {
                return (.power, input.index(after: next))
            }
            return (.multiply, next)
        case "/": return (.divide, next)
        case "^": return (.power, next)
        case "&": return (.bitwiseAnd, next)
        case "|": return (.bitwiseOr, next)
        case "=": return (.assign, next)
        case "<":
            if next < input.endIndex && input[next] == "<" {
                return (.shiftLeft, input.index(after: next))
            }
            return nil
        case ">":
            if next < input.endIndex && input[next] == ">" {
                return (.shiftRight, input.index(after: next))
            }
            return nil
        default: return nil
        }
    }

    // MARK: - Word Parsing

    private func parseWord(_ input: String, from start: String.Index) -> (Token, String.Index) {
        var i = start
        var word = ""
        while i < input.endIndex && (input[i].isLetter || input[i].isNumber || input[i] == "_") {
            word.append(input[i])
            i = input.index(after: i)
        }

        let lower = word.lowercased()

        // Keywords
        switch lower {
        case "in", "into": return (.keyword(.in), i)
        case "as": return (.keyword(.as), i)
        case "to": return (.keyword(.to), i)
        case "of": return (.keyword(.of), i)
        case "on": return (.keyword(.on), i)
        case "off": return (.keyword(.off), i)
        case "what": return (.keyword(.what), i)
        case "is": return (.keyword(.is), i)
        case "today": return (.keyword(.today), i)
        case "now": return (.keyword(.now), i)
        case "prev", "previous": return (.keyword(.prev), i)
        case "sum": return (.keyword(.sum), i)
        case "total": return (.keyword(.total), i)
        case "average": return (.keyword(.average), i)
        case "avg": return (.keyword(.avg), i)
        case "pi": return (.keyword(.pi), i)
        case "e": return (.keyword(.e), i)
        default: break
        }

        // Word operators
        switch lower {
        case "plus": return (.op(.add), i)
        case "minus": return (.op(.subtract), i)
        case "times": return (.op(.multiply), i)
        case "divided":
            // Check for "divided by"
            let remaining = String(input[i...]).trimmingCharacters(in: .whitespaces)
            if remaining.lowercased().hasPrefix("by") {
                var j = i
                while j < input.endIndex && input[j].isWhitespace { j = input.index(after: j) }
                // skip "by"
                if j < input.endIndex && input[j].lowercased() == "b" {
                    j = input.index(after: j)
                    if j < input.endIndex && input[j].lowercased() == "y" {
                        j = input.index(after: j)
                        return (.op(.divide), j)
                    }
                }
            }
            return (.word(word), i)
        case "mod": return (.op(.modulo), i)
        case "xor": return (.op(.bitwiseXor), i)
        default: break
        }

        // Functions
        if Self.functionNames.contains(lower) {
            return (.function(lower), i)
        }

        // Multi-word unit check: try to match longer unit strings
        let remaining = String(input[start...]).lowercased()
        for (phrase, unit) in Self.unitMap {
            let phraseLower = phrase.lowercased()
            if remaining.hasPrefix(phraseLower) {
                let afterPhrase = input.index(start, offsetBy: phrase.count)
                // Make sure the match ends at a word boundary
                if afterPhrase >= input.endIndex || !input[afterPhrase].isLetter {
                    return (.unit(unit), afterPhrase)
                }
            }
        }

        // Currency codes (case-sensitive for 3-letter codes)
        if Self.currencyCodes.contains(word) {
            return (.unit(.currency(word)), i)
        }

        // Crypto names (check before fiat currency names since some overlap)
        if let cryptoTicker = Self.cryptoNames[lower] {
            if cryptoTicker == "SATS" {
                // Satoshis: 1 sat = 0.00000001 BTC, treated as a special currency unit
                return (.unit(.currency("SATS")), i)
            }
            return (.unit(.currency(cryptoTicker)), i)
        }

        // Currency names
        switch lower {
        case "dollar", "dollars": return (.unit(.currency("USD")), i)
        case "euro", "euros": return (.unit(.currency("EUR")), i)
        case "pound", "pounds":
            // "pound" could be weight or currency - check context
            // Default to weight; currency will be handled if preceded by a number and followed by conversion
            return (.unit(.pound), i)
        case "yen": return (.unit(.currency("JPY")), i)
        default: break
        }

        // Single-letter unit shortcuts (case-sensitive)
        switch word {
        case "K": return (.unit(.kelvin), i)
        case "C": return (.unit(.celsius), i)
        case "F": return (.unit(.fahrenheit), i)
        default: break
        }

        // If nothing else matched, treat as a variable reference
        return (.variable(word), i)
    }
}
