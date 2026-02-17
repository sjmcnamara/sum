import Foundation

/// Highlight kind for syntax coloring in the editor
enum TokenHighlightKind: Equatable {
    case keyword    // in, to, as, of, pi, e, etc.
    case function   // sqrt, sin, cos, log, etc.
    case variable   // user-defined variables
    case number     // numeric literals (including hex/bin/oct)
    case op         // operators (+, -, *, /, =, etc.)
    case unit       // units (km, kg, USD, etc.)
    case comment    // comments (// or #)
    case plain      // whitespace, parens, commas, unrecognized
}

/// A token's highlight kind paired with its range in the source string
struct TokenRange: Equatable {
    let kind: TokenHighlightKind
    let range: NSRange
}

/// Tokenizes a line of text into tokens for the parser
struct Tokenizer {

    // MARK: - Unit Lookup

    static let unitMap: [(String, NumiUnit)] = [
        // Speed (before length to match "meters per second" before "meters")
        ("meters per second", .metersPerSecond), ("mps", .metersPerSecond),
        ("kilometers per hour", .kilometersPerHour), ("kph", .kilometersPerHour), ("kmh", .kilometersPerHour),
        ("miles per hour", .milesPerHour), ("mph", .milesPerHour),
        ("feet per second", .feetPerSecond), ("fps", .feetPerSecond),
        ("knots", .knot), ("knot", .knot), ("kn", .knot),

        // Pressure
        ("kilopascals", .kilopascal), ("kilopascal", .kilopascal), ("kpa", .kilopascal),
        ("pascals", .pascal), ("pascal", .pascal), ("pa", .pascal),
        ("atmospheres", .atmosphere), ("atmosphere", .atmosphere), ("atm", .atmosphere),
        ("bars", .bar), ("bar", .bar),
        ("psi", .psi),
        ("mmhg", .mmHg),
        ("torr", .torr),

        // Energy (longer entries first)
        ("kilocalories", .kilocalorie), ("kilocalorie", .kilocalorie), ("kcal", .kilocalorie),
        ("calories", .calorie), ("calorie", .calorie), ("cal", .calorie),
        ("kilojoules", .kilojoule), ("kilojoule", .kilojoule), ("kj", .kilojoule),
        ("joules", .joule), ("joule", .joule), ("j", .joule),
        ("kilowatt hours", .kilowattHour), ("kilowatt hour", .kilowattHour), ("kwh", .kilowattHour),
        ("watt hours", .wattHour), ("watt hour", .wattHour), ("wh", .wattHour),
        ("btus", .btu), ("btu", .btu),
        ("electronvolts", .electronvolt), ("electronvolt", .electronvolt), ("ev", .electronvolt),

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

    /// O(1) lookup for single-word units (no spaces in the phrase)
    static let singleWordUnitMap: [String: NumiUnit] = {
        var map: [String: NumiUnit] = [:]
        for (phrase, unit) in unitMap where !phrase.contains(" ") {
            let key = phrase.lowercased()
            if map[key] == nil { // first match wins (preserves unitMap ordering priority)
                map[key] = unit
            }
        }
        return map
    }()

    /// Multi-word units only (contain spaces), tried with prefix matching
    static let multiWordUnits: [(String, NumiUnit)] = {
        unitMap.filter { $0.0.contains(" ") }
    }()

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

    // MARK: - Internal Token with Position

    /// A token paired with its source range and highlight kind
    private struct LocatedToken {
        let token: Token
        let range: NSRange
        let highlightKind: TokenHighlightKind
    }

    // MARK: - Public API

    /// Returns just tokens for the parser (discards ranges)
    func tokenize(_ input: String) -> [Token] {
        tokenizeInternal(input).map { $0.token }
    }

    /// Returns highlight ranges for syntax coloring
    func tokenizeWithRanges(_ input: String) -> [TokenRange] {
        tokenizeInternal(input).map { TokenRange(kind: $0.highlightKind, range: $0.range) }
    }

    // MARK: - Unified Tokenization

    /// Single tokenization pass that produces tokens, ranges, and highlight kinds.
    /// Both `tokenize()` and `tokenizeWithRanges()` are thin wrappers around this.
    private func tokenizeInternal(_ input: String) -> [LocatedToken] {
        var located: [LocatedToken] = []
        var i = input.startIndex

        func nsRange(from start: String.Index, to end: String.Index) -> NSRange {
            let loc = input.distance(from: input.startIndex, to: start)
            let len = input.distance(from: start, to: end)
            return NSRange(location: loc, length: len)
        }

        func append(_ token: Token, _ kind: TokenHighlightKind, from start: String.Index, to end: String.Index) {
            located.append(LocatedToken(token: token, range: nsRange(from: start, to: end), highlightKind: kind))
        }

        while i < input.endIndex {
            let ch = input[i]

            // Comments: // or # stop tokenizing the rest of the line
            if ch == "#" {
                // Comment tokens aren't needed by parser but range is needed for highlighting
                located.append(LocatedToken(token: .word(""), range: nsRange(from: i, to: input.endIndex), highlightKind: .comment))
                break
            }
            if ch == "/" {
                let next = input.index(after: i)
                if next < input.endIndex && input[next] == "/" {
                    located.append(LocatedToken(token: .word(""), range: nsRange(from: i, to: input.endIndex), highlightKind: .comment))
                    break
                }

                // Compound speed units: km/h, m/s, miles/h, mi/h, ft/s
                if let last = located.last, case .unit(let u) = last.token, next < input.endIndex {
                    let suffix = input[next].lowercased()
                    var speedUnit: NumiUnit?
                    if suffix == "h" {
                        switch u {
                        case .kilometer: speedUnit = .kilometersPerHour
                        case .mile: speedUnit = .milesPerHour
                        default: break
                        }
                    } else if suffix == "s" {
                        switch u {
                        case .meter: speedUnit = .metersPerSecond
                        case .foot: speedUnit = .feetPerSecond
                        default: break
                        }
                    }
                    if let speed = speedUnit {
                        let afterSuffix = input.index(after: next)
                        if afterSuffix >= input.endIndex || !input[afterSuffix].isLetter {
                            // Replace previous unit token with compound speed unit, extending the range
                            let prevRange = located[located.count - 1].range
                            let extended = NSRange(location: prevRange.location, length: prevRange.length + 2)
                            located[located.count - 1] = LocatedToken(token: .unit(speed), range: extended, highlightKind: .unit)
                            i = afterSuffix
                            continue
                        }
                    }
                }
            }

            // Skip whitespace
            if ch.isWhitespace {
                i = input.index(after: i)
                continue
            }

            // Currency symbol prefix ($100, €50, ₿1.5, Ξ10, etc.)
            if let currencyCode = Self.currencySymbols[String(ch)] {
                let next = input.index(after: i)
                if next < input.endIndex && (input[next].isNumber || input[next] == ".") {
                    append(.unit(.currency(currencyCode)), .unit, from: i, to: next)
                    i = next
                    continue
                }
                if currencyCode == "BTC" || currencyCode == "ETH" {
                    append(.unit(.currency(currencyCode)), .unit, from: i, to: next)
                    i = next
                    continue
                }
            }

            // R$ (Brazilian Real)
            if ch == "R" {
                let next = input.index(after: i)
                if next < input.endIndex && input[next] == "$" {
                    let afterSymbol = input.index(after: next)
                    if afterSymbol < input.endIndex && (input[afterSymbol].isNumber || input[afterSymbol] == ".") {
                        append(.unit(.currency("BRL")), .unit, from: i, to: afterSymbol)
                        i = afterSymbol
                        continue
                    }
                }
            }

            // Numbers (including hex, binary, octal)
            if ch.isNumber || (ch == "." && i < input.endIndex) {
                let numStart = i
                let (num, endIdx, numUnit) = parseNumber(input, from: i)
                if let n = num {
                    append(.number(n), .number, from: numStart, to: endIdx)
                    if let u = numUnit {
                        // Display format units (hex/binary/octal) share the number range
                        append(.unit(u), .unit, from: numStart, to: endIdx)
                    }
                    i = endIdx
                    continue
                }
            }

            // Operators
            if let opResult = parseOperator(input, from: i) {
                let opStart = i
                i = opResult.1
                append(.op(opResult.0), .op, from: opStart, to: i)
                continue
            }

            // Parentheses
            if ch == "(" || ch == ")" {
                let token: Token = ch == "(" ? .leftParen : .rightParen
                let next = input.index(after: i)
                append(token, .plain, from: i, to: next)
                i = next
                continue
            }

            // Comma
            if ch == "," {
                if !located.isEmpty, case .number = located.last?.token {
                    let next = input.index(after: i)
                    if next < input.endIndex && input[next].isNumber {
                        i = next
                        continue
                    }
                }
                let next = input.index(after: i)
                append(.comma, .plain, from: i, to: next)
                i = next
                continue
            }

            // Degree symbol
            if ch == "°" {
                let next = input.index(after: i)
                if next < input.endIndex {
                    let nextCh = input[next].lowercased()
                    if nextCh == "c" {
                        let afterUnit = input.index(after: next)
                        append(.unit(.celsius), .unit, from: i, to: afterUnit)
                        i = afterUnit
                        continue
                    } else if nextCh == "f" {
                        let afterUnit = input.index(after: next)
                        append(.unit(.fahrenheit), .unit, from: i, to: afterUnit)
                        i = afterUnit
                        continue
                    }
                }
                append(.unit(.degree), .unit, from: i, to: next)
                i = next
                continue
            }

            // Percent sign
            if ch == "%" {
                let next = input.index(after: i)
                append(.unit(.percent), .unit, from: i, to: next)
                i = next
                continue
            }

            // Words (identifiers, keywords, units, functions)
            if ch.isLetter || ch == "_" {
                let wordStart = i
                let (token, endIdx) = parseWord(input, from: i)
                let kind: TokenHighlightKind
                switch token {
                case .keyword: kind = .keyword
                case .function: kind = .function
                case .variable: kind = .variable
                case .unit: kind = .unit
                case .op(let opVal) where opVal == .modulo || opVal == .bitwiseXor || opVal == .bitwiseNot:
                    kind = .keyword
                case .op: kind = .op
                case .word: kind = .plain
                default: kind = .plain
                }
                append(token, kind, from: wordStart, to: endIdx)
                i = endIdx
                continue
            }

            // Skip unrecognized characters
            i = input.index(after: i)
        }

        return located
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
        case "~": return (.bitwiseNot, next)
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
        case "speedoflight", "lightspeed": return (.keyword(.speedoflight), i)
        case "gravity": return (.keyword(.gravity), i)
        case "avogadro", "na": return (.keyword(.avogadro), i)
        case "planck": return (.keyword(.planck), i)
        case "boltzmann": return (.keyword(.boltzmann), i)
        case "echarge": return (.keyword(.echarge), i)
        case "phi", "golden": return (.keyword(.phi), i)
        case "tau": return (.keyword(.tau), i)
        // Natural language keywords
        case "split": return (.keyword(.split), i)
        case "between": return (.keyword(.between), i)
        case "among": return (.keyword(.among), i)
        case "ways": return (.keyword(.ways), i)
        case "people": return (.keyword(.people), i)
        case "tip": return (.keyword(.tip), i)
        case "tax": return (.keyword(.tax), i)
        default: break
        }

        // Word operators
        switch lower {
        case "plus": return (.op(.add), i)
        case "minus": return (.op(.subtract), i)
        case "times": return (.op(.multiply), i)
        case "divided":
            let remaining = String(input[i...]).trimmingCharacters(in: .whitespaces)
            if remaining.lowercased().hasPrefix("by") {
                var j = i
                while j < input.endIndex && input[j].isWhitespace { j = input.index(after: j) }
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
        case "not": return (.op(.bitwiseNot), i)
        default: break
        }

        // Functions
        if Self.functionNames.contains(lower) {
            return (.function(lower), i)
        }

        // Multi-word unit check (try longest match first)
        let remaining = String(input[start...]).lowercased()
        for (phrase, unit) in Self.multiWordUnits {
            let phraseLower = phrase.lowercased()
            if remaining.hasPrefix(phraseLower) {
                let afterPhrase = input.index(start, offsetBy: phrase.count)
                if afterPhrase >= input.endIndex || !input[afterPhrase].isLetter {
                    return (.unit(unit), afterPhrase)
                }
            }
        }

        // Single-word unit lookup (O(1) dictionary)
        if let unit = Self.singleWordUnitMap[lower] {
            return (.unit(unit), i)
        }

        // Currency codes (case-insensitive for 3-letter codes)
        let upper = word.uppercased()
        if Self.currencyCodes.contains(upper) {
            return (.unit(.currency(upper)), i)
        }

        // Crypto names
        if let cryptoTicker = Self.cryptoNames[lower] {
            if cryptoTicker == "SATS" {
                return (.unit(.currency("SATS")), i)
            }
            return (.unit(.currency(cryptoTicker)), i)
        }

        // Currency names
        switch lower {
        case "dollar", "dollars": return (.unit(.currency("USD")), i)
        case "euro", "euros": return (.unit(.currency("EUR")), i)
        case "pound", "pounds":
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
