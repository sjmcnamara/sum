import Foundation

// MARK: - Core Value Type

/// Represents a computed value with an optional unit
struct NumiValue: Equatable {
    let number: Double
    let unit: NumiUnit?

    init(_ number: Double, unit: NumiUnit? = nil) {
        self.number = number
        self.unit = unit
    }

    /// Formats with default settings (backward compatible)
    var formatted: String {
        formatted(with: .default)
    }

    /// Formats with the given configuration
    func formatted(with config: FormattingConfig) -> String {
        if let unit = unit {
            switch unit {
            case .currency(let code):
                return formatCurrency(number, code: code, config: config)
            case .percent:
                return "\(formatNumber(number, config: config))%"
            case .date:
                let date = Date(timeIntervalSince1970: number)
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)
            case .time:
                return formatDuration(number, config: config)
            case .hex:
                return "0x\(String(Int(number), radix: 16, uppercase: true))"
            case .binary:
                return "0b\(String(Int(number), radix: 2))"
            case .octal:
                return "0o\(String(Int(number), radix: 8))"
            case .scientific:
                return formatScientific(number, config: config)
            default:
                return "\(formatNumber(number, config: config)) \(unit.symbol)"
            }
        }
        return formatNumber(number, config: config)
    }

    private func formatNumber(_ n: Double, config: FormattingConfig = .default) -> String {
        let isFixed = config.decimalPrecision != .auto
        let maxDecimals = isFixed ? config.decimalPrecision.rawValue : 6
        let minDecimals = isFixed ? config.decimalPrecision.rawValue : 0

        if !isFixed && n == n.rounded() && abs(n) < 1e15 {
            let intVal = Int(n)
            let s = String(intVal)
            return config.useThousandsSeparator ? addThousandsSeparator(s) : s
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maxDecimals
        formatter.minimumFractionDigits = minDecimals
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = config.useThousandsSeparator
        return formatter.string(from: NSNumber(value: n)) ?? String(n)
    }

    private func addThousandsSeparator(_ s: String) -> String {
        let isNeg = s.hasPrefix("-")
        let digits = isNeg ? String(s.dropFirst()) : s
        var result = ""
        for (i, ch) in digits.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { result = "," + result }
            result = String(ch) + result
        }
        return isNeg ? "-" + result : result
    }

    private static let cryptoSymbols: [String: String] = [
        "BTC": "₿", "ETH": "Ξ", "SOL": "SOL ", "BNB": "BNB ",
        "XRP": "XRP ", "ADA": "ADA ", "DOGE": "DOGE ", "DOT": "DOT ",
        "AVAX": "AVAX ", "MATIC": "MATIC ", "LINK": "LINK ",
        "UNI": "UNI ", "LTC": "LTC ", "ATOM": "ATOM ", "XLM": "XLM ",
        "ALGO": "ALGO ", "NEAR": "NEAR ", "FTM": "FTM ",
        "AAVE": "AAVE ", "ARB": "ARB ", "OP": "OP ",
        "APT": "APT ", "SUI": "SUI ", "SEI": "SEI ",
        "SHIB": "SHIB ", "PEPE": "PEPE ",
        "USDT": "USDT ", "USDC": "USDC ", "DAI": "DAI ",
        "SATS": "sats ",
    ]

    private static let fiatSymbols: [String: String] = [
        "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥",
        "CAD": "CA$", "AUD": "A$", "CHF": "CHF ",
        "CNY": "¥", "KRW": "₩", "RUB": "₽",
    ]

    private static let cryptoCodes: Set<String> = [
        "BTC", "ETH", "SOL", "BNB", "XRP", "ADA",
        "DOGE", "DOT", "AVAX", "MATIC", "LINK", "UNI",
        "LTC", "ATOM", "XLM", "ALGO", "NEAR", "FTM",
        "AAVE", "ARB", "OP", "APT", "SUI", "SEI",
        "SHIB", "PEPE", "USDT", "USDC", "DAI", "SATS",
    ]

    private func formatCurrency(_ n: Double, code: String, config: FormattingConfig = .default) -> String {
        let isCrypto = Self.cryptoCodes.contains(code)
        let isFixed = config.decimalPrecision != .auto

        if isCrypto {
            let sym = Self.cryptoSymbols[code] ?? "\(code) "
            let autoDecimals = cryptoDecimals(for: code, value: n)
            let decimals = isFixed ? config.decimalPrecision.rawValue : autoDecimals
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = decimals
            formatter.minimumFractionDigits = isFixed ? decimals : min(2, autoDecimals)
            formatter.usesGroupingSeparator = config.useThousandsSeparator
            let numStr = formatter.string(from: NSNumber(value: n)) ?? String(n)
            if code == "BTC" || code == "ETH" {
                return "\(sym)\(numStr)"
            }
            return "\(numStr) \(code)"
        }

        // Fiat formatting
        let sym = Self.fiatSymbols[code] ?? "\(code) "
        let fiatDecimals = isFixed ? config.decimalPrecision.rawValue : 2
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fiatDecimals
        formatter.minimumFractionDigits = fiatDecimals
        formatter.usesGroupingSeparator = config.useThousandsSeparator
        let numStr = formatter.string(from: NSNumber(value: n)) ?? String(format: "%.2f", n)
        return "\(sym)\(numStr)"
    }

    /// Determines appropriate decimal places for a crypto value
    private func cryptoDecimals(for code: String, value: Double) -> Int {
        switch code {
        case "BTC":
            return 8 // satoshi precision
        case "ETH":
            return 6
        case "SHIB", "PEPE":
            return abs(value) < 1 ? 10 : 2
        case "SATS":
            return 0 // whole satoshis
        case "USDT", "USDC", "DAI":
            return 2 // stablecoins
        default:
            if abs(value) < 0.01 { return 8 }
            if abs(value) < 1 { return 6 }
            if abs(value) < 100 { return 4 }
            return 2
        }
    }

    private func formatDuration(_ seconds: Double, config: FormattingConfig = .default) -> String {
        let totalSeconds = abs(seconds)
        let words = config.durationWords
        if totalSeconds >= 86400 {
            let days = totalSeconds / 86400
            return "\(formatNumber(days, config: config)) \(words.days)"
        } else if totalSeconds >= 3600 {
            let hours = totalSeconds / 3600
            return "\(formatNumber(hours, config: config)) \(words.hours)"
        } else if totalSeconds >= 60 {
            let mins = totalSeconds / 60
            return "\(formatNumber(mins, config: config)) \(words.minutes)"
        }
        return "\(formatNumber(totalSeconds, config: config)) \(words.seconds)"
    }

    private func formatScientific(_ n: Double, config: FormattingConfig = .default) -> String {
        let isFixed = config.decimalPrecision != .auto
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.maximumFractionDigits = isFixed ? config.decimalPrecision.rawValue : 6
        return formatter.string(from: NSNumber(value: n)) ?? String(n)
    }
}

// MARK: - Unit System

enum NumiUnit: Equatable {
    // Length
    case meter, kilometer, centimeter, millimeter, micrometer, nanometer
    case inch, foot, yard, mile, nauticalMile

    // Weight
    case gram, kilogram, milligram, tonne, pound, ounce, stone, carat

    // Temperature
    case celsius, fahrenheit, kelvin

    // Area
    case squareMeter, squareKilometer, squareFoot, squareInch, squareYard, squareMile
    case hectare, acre

    // Volume
    case cubicMeter, liter, milliliter, gallon, quart, pint, cup, tablespoon, teaspoon
    case cubicFoot, cubicInch

    // Time
    case second, minute, hour, day, week, month, year
    case millisecond

    // Data
    case bit, byte
    case kilobyte, megabyte, gigabyte, terabyte
    case kibibyte, mebibyte, gibibyte, tebibyte
    case kilobit, megabit, gigabit

    // Angle
    case radian, degree

    // Speed
    case metersPerSecond, kilometersPerHour, milesPerHour, knot, feetPerSecond

    // Pressure
    case pascal, kilopascal, bar, atmosphere, psi, mmHg, torr

    // Energy
    case joule, kilojoule, calorie, kilocalorie, wattHour, kilowattHour, btu, electronvolt

    // CSS
    case pixel, point, em

    // Currency
    case currency(String)

    // Percentage
    case percent

    // Special display
    case date, time, hex, binary, octal, scientific

    var symbol: String {
        switch self {
        case .meter: return "m"
        case .kilometer: return "km"
        case .centimeter: return "cm"
        case .millimeter: return "mm"
        case .micrometer: return "µm"
        case .nanometer: return "nm"
        case .inch: return "in"
        case .foot: return "ft"
        case .yard: return "yd"
        case .mile: return "mi"
        case .nauticalMile: return "nmi"
        case .gram: return "g"
        case .kilogram: return "kg"
        case .milligram: return "mg"
        case .tonne: return "t"
        case .pound: return "lb"
        case .ounce: return "oz"
        case .stone: return "st"
        case .carat: return "ct"
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        case .kelvin: return "K"
        case .squareMeter: return "m²"
        case .squareKilometer: return "km²"
        case .squareFoot: return "ft²"
        case .squareInch: return "in²"
        case .squareYard: return "yd²"
        case .squareMile: return "mi²"
        case .hectare: return "ha"
        case .acre: return "ac"
        case .cubicMeter: return "m³"
        case .liter: return "L"
        case .milliliter: return "mL"
        case .gallon: return "gal"
        case .quart: return "qt"
        case .pint: return "pt"
        case .cup: return "cup"
        case .tablespoon: return "tbsp"
        case .teaspoon: return "tsp"
        case .cubicFoot: return "ft³"
        case .cubicInch: return "in³"
        case .second: return "s"
        case .minute: return "min"
        case .hour: return "hr"
        case .day: return "days"
        case .week: return "weeks"
        case .month: return "months"
        case .year: return "years"
        case .millisecond: return "ms"
        case .bit: return "b"
        case .byte: return "B"
        case .kilobyte: return "KB"
        case .megabyte: return "MB"
        case .gigabyte: return "GB"
        case .terabyte: return "TB"
        case .kibibyte: return "KiB"
        case .mebibyte: return "MiB"
        case .gibibyte: return "GiB"
        case .tebibyte: return "TiB"
        case .kilobit: return "Kb"
        case .megabit: return "Mb"
        case .gigabit: return "Gb"
        case .radian: return "rad"
        case .degree: return "°"
        case .metersPerSecond: return "m/s"
        case .kilometersPerHour: return "km/h"
        case .milesPerHour: return "mph"
        case .knot: return "kn"
        case .feetPerSecond: return "ft/s"
        case .pascal: return "Pa"
        case .kilopascal: return "kPa"
        case .bar: return "bar"
        case .atmosphere: return "atm"
        case .psi: return "psi"
        case .mmHg: return "mmHg"
        case .torr: return "Torr"
        case .joule: return "J"
        case .kilojoule: return "kJ"
        case .calorie: return "cal"
        case .kilocalorie: return "kcal"
        case .wattHour: return "Wh"
        case .kilowattHour: return "kWh"
        case .btu: return "BTU"
        case .electronvolt: return "eV"
        case .pixel: return "px"
        case .point: return "pt"
        case .em: return "em"
        case .currency(let code): return code
        case .percent: return "%"
        case .date, .time, .hex, .binary, .octal, .scientific: return ""
        }
    }

    /// The base unit category for conversion
    var category: UnitCategory? {
        switch self {
        case .meter, .kilometer, .centimeter, .millimeter, .micrometer, .nanometer,
             .inch, .foot, .yard, .mile, .nauticalMile:
            return .length
        case .gram, .kilogram, .milligram, .tonne, .pound, .ounce, .stone, .carat:
            return .weight
        case .celsius, .fahrenheit, .kelvin:
            return .temperature
        case .squareMeter, .squareKilometer, .squareFoot, .squareInch,
             .squareYard, .squareMile, .hectare, .acre:
            return .area
        case .cubicMeter, .liter, .milliliter, .gallon, .quart, .pint,
             .cup, .tablespoon, .teaspoon, .cubicFoot, .cubicInch:
            return .volume
        case .second, .minute, .hour, .day, .week, .month, .year, .millisecond:
            return .time
        case .bit, .byte, .kilobyte, .megabyte, .gigabyte, .terabyte,
             .kibibyte, .mebibyte, .gibibyte, .tebibyte,
             .kilobit, .megabit, .gigabit:
            return .data
        case .radian, .degree:
            return .angle
        case .metersPerSecond, .kilometersPerHour, .milesPerHour, .knot, .feetPerSecond:
            return .speed
        case .pascal, .kilopascal, .bar, .atmosphere, .psi, .mmHg, .torr:
            return .pressure
        case .joule, .kilojoule, .calorie, .kilocalorie, .wattHour, .kilowattHour, .btu, .electronvolt:
            return .energy
        case .pixel, .point, .em:
            return .css
        case .currency:
            return .currency
        default:
            return nil
        }
    }

    /// Conversion ratio to base unit (meters for length, grams for weight, etc.)
    var toBaseRatio: Double {
        switch self {
        // Length -> meters
        case .meter: return 1
        case .kilometer: return 1000
        case .centimeter: return 0.01
        case .millimeter: return 0.001
        case .micrometer: return 1e-6
        case .nanometer: return 1e-9
        case .inch: return 0.0254
        case .foot: return 0.3048
        case .yard: return 0.9144
        case .mile: return 1609.344
        case .nauticalMile: return 1852

        // Weight -> grams
        case .gram: return 1
        case .kilogram: return 1000
        case .milligram: return 0.001
        case .tonne: return 1_000_000
        case .pound: return 453.592
        case .ounce: return 28.3495
        case .stone: return 6350.29
        case .carat: return 0.2

        // Area -> square meters
        case .squareMeter: return 1
        case .squareKilometer: return 1_000_000
        case .squareFoot: return 0.092903
        case .squareInch: return 0.00064516
        case .squareYard: return 0.836127
        case .squareMile: return 2_589_988
        case .hectare: return 10_000
        case .acre: return 4046.86

        // Volume -> cubic meters
        case .cubicMeter: return 1
        case .liter: return 0.001
        case .milliliter: return 0.000001
        case .gallon: return 0.00378541
        case .quart: return 0.000946353
        case .pint: return 0.000473176
        case .cup: return 0.000236588
        case .tablespoon: return 1.4787e-5
        case .teaspoon: return 4.9289e-6
        case .cubicFoot: return 0.0283168
        case .cubicInch: return 1.6387e-5

        // Time -> seconds
        case .second: return 1
        case .millisecond: return 0.001
        case .minute: return 60
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .month: return 2_628_000 // 365/12 days
        case .year: return 31_536_000 // 365 days

        // Data -> bits
        case .bit: return 1
        case .byte: return 8
        case .kilobyte: return 8_000
        case .megabyte: return 8_000_000
        case .gigabyte: return 8_000_000_000
        case .terabyte: return 8_000_000_000_000
        case .kibibyte: return 8_192
        case .mebibyte: return 8_388_608
        case .gibibyte: return 8_589_934_592
        case .tebibyte: return 8_796_093_022_208
        case .kilobit: return 1_000
        case .megabit: return 1_000_000
        case .gigabit: return 1_000_000_000

        // Angle -> radians
        case .radian: return 1
        case .degree: return .pi / 180

        // Speed -> meters per second
        case .metersPerSecond: return 1
        case .kilometersPerHour: return 1.0 / 3.6
        case .milesPerHour: return 0.44704
        case .knot: return 0.514444
        case .feetPerSecond: return 0.3048

        // Pressure -> pascals
        case .pascal: return 1
        case .kilopascal: return 1000
        case .bar: return 100_000
        case .atmosphere: return 101_325
        case .psi: return 6894.76
        case .mmHg: return 133.322
        case .torr: return 133.322

        // Energy -> joules
        case .joule: return 1
        case .kilojoule: return 1000
        case .calorie: return 4.184
        case .kilocalorie: return 4184
        case .wattHour: return 3600
        case .kilowattHour: return 3_600_000
        case .btu: return 1055.06
        case .electronvolt: return 1.602176634e-19

        // CSS -> pixels (default 96 ppi)
        case .pixel: return 1
        case .point: return 96.0 / 72.0
        case .em: return 16

        // Temperature and currency are handled specially
        case .celsius, .fahrenheit, .kelvin: return 1
        case .currency: return 1
        default: return 1
        }
    }
}

enum UnitCategory {
    case length, weight, temperature, area, volume, time, data, angle, speed, pressure, energy, css, currency
}

// MARK: - Token Types

enum Token: Equatable {
    case number(Double)
    case unit(NumiUnit)
    case op(Operator)
    case leftParen
    case rightParen
    case variable(String)
    case function(String)
    case keyword(Keyword)
    case comma
    case word(String) // unrecognized word, ignored

    static func == (lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.number(let a), .number(let b)): return a == b
        case (.unit(let a), .unit(let b)): return a == b
        case (.op(let a), .op(let b)): return a == b
        case (.leftParen, .leftParen): return true
        case (.rightParen, .rightParen): return true
        case (.variable(let a), .variable(let b)): return a == b
        case (.function(let a), .function(let b)): return a == b
        case (.keyword(let a), .keyword(let b)): return a == b
        case (.comma, .comma): return true
        case (.word(let a), .word(let b)): return a == b
        default: return false
        }
    }
}

enum Operator: String, Equatable {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case power = "^"
    case modulo = "mod"
    case bitwiseAnd = "&"
    case bitwiseOr = "|"
    case bitwiseXor = "xor"
    case bitwiseNot = "~"
    case shiftLeft = "<<"
    case shiftRight = ">>"
    case assign = "="

    var precedence: Int {
        switch self {
        case .assign: return 0
        case .bitwiseOr: return 1
        case .bitwiseXor: return 2
        case .bitwiseAnd: return 3
        case .shiftLeft, .shiftRight: return 4
        case .add, .subtract: return 5
        case .multiply, .divide, .modulo: return 6
        case .power, .bitwiseNot: return 7
        }
    }
}

enum Keyword: String, Equatable {
    case `in` = "in"
    case into = "into"
    case `as` = "as"
    case to = "to"
    case of = "of"
    case on = "on"
    case off = "off"
    case aPercent = "a %"
    case what = "what"
    case `is` = "is"
    case today = "today"
    case now = "now"
    case prev = "prev"
    case sum = "sum"
    case total = "total"
    case average = "average"
    case avg = "avg"
    case pi = "pi"
    case e = "e"
    // Scientific & mathematical constants
    case speedoflight = "speedoflight"
    case gravity = "gravity"
    case avogadro = "avogadro"
    case planck = "planck"
    case boltzmann = "boltzmann"
    case echarge = "echarge"
    case phi = "phi"
    case tau = "tau"
    // Natural language
    case split = "split"
    case between = "between"
    case among = "among"
    case ways = "ways"
    case people = "people"
    case tip = "tip"
    case tax = "tax"
}

// MARK: - Line Result

struct LineResult: Identifiable {
    let id: Int // line index
    let input: String
    let value: NumiValue?
    let error: String?
    let assignmentVariable: String? // variable name if this line is "var = expr"

    var hasResult: Bool { value != nil }
}

// MARK: - Note

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "Untitled", content: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
