import Foundation

// MARK: - Language Enum

/// Supported languages for parser keywords and UI strings
enum Language: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case spanish = "es"
    case portuguese = "pt"

    var id: String { rawValue }

    /// Native display name (not localized — always shows in the language itself)
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        }
    }
}

// MARK: - Parser Keywords

/// Duration display words for formatted output
struct DurationWords {
    let days: String
    let hours: String
    let minutes: String
    let seconds: String

    static let english = DurationWords(days: "days", hours: "hours", minutes: "minutes", seconds: "seconds")
    static let spanish = DurationWords(days: "días", hours: "horas", minutes: "minutos", seconds: "segundos")
    static let portuguese = DurationWords(days: "dias", hours: "horas", minutes: "minutos", seconds: "segundos")
}

/// All localizable lookup tables used by the Tokenizer and Parser
struct ParserKeywords {
    /// Word operators: "plus" → .add, "más" → .add
    let operatorWords: [String: Operator]

    /// Two-word divide operator: ("divided", "by") or ("dividido", "entre")
    let dividedBy: [(word: String, by: String)]

    /// Keywords: "split" → .split, "dividir" → .split
    let keywords: [String: Keyword]

    /// Localized full unit names (abbreviations stay universal): "kilómetros" → .kilometer
    let unitNames: [String: NumiUnit]

    /// Localized currency names: "dólar" → "USD"
    let currencyNames: [String: String]

    /// Leading noise words stripped before parsing: {"what", "is"} / {"qué", "es"}
    let leadingNoiseWords: Set<String>

    /// Leading noise matched as variables: {"s", "whats"} / {"qués"}
    let leadingNoiseVariables: Set<String>

    /// Trailing noise keywords stripped after parsing: {.ways, .people}
    let trailingNoiseKeywords: Set<Keyword>

    /// User-facing error messages keyed by error type
    let errorMessages: [String: String]

    /// Duration display words
    let durationWords: DurationWords

    /// Display format conversion words: "hex" → .hex, "binario" → .binary
    let displayFormatWords: [String: NumiUnit]

    /// Keywords for the suggestion engine
    let suggestionKeywords: [String]
}

// MARK: - Factory

extension Language {
    /// Builds merged keyword tables for the given language.
    /// English keywords are always included; localized keywords are added on top.
    static func parserKeywords(for language: Language) -> ParserKeywords {
        switch language {
        case .english:
            return englishKeywords()
        case .spanish:
            return mergedKeywords(base: englishKeywords(), overlay: spanishOverlay())
        case .portuguese:
            return mergedKeywords(base: englishKeywords(), overlay: portugueseOverlay())
        }
    }

    // MARK: - English Base

    private static func englishKeywords() -> ParserKeywords {
        ParserKeywords(
            operatorWords: [
                "plus": .add,
                "minus": .subtract,
                "times": .multiply,
                "mod": .modulo,
                "xor": .bitwiseXor,
                "not": .bitwiseNot,
            ],
            dividedBy: [("divided", "by")],
            keywords: [
                "in": .in, "into": .in,
                "as": .as, "to": .to,
                "of": .of, "on": .on, "off": .off,
                "what": .what, "is": .is,
                "today": .today, "now": .now,
                "prev": .prev, "previous": .prev,
                "sum": .sum, "total": .total,
                "average": .average, "avg": .avg,
                "pi": .pi, "e": .e,
                "speedoflight": .speedoflight, "lightspeed": .speedoflight,
                "gravity": .gravity,
                "avogadro": .avogadro, "na": .avogadro,
                "planck": .planck,
                "boltzmann": .boltzmann,
                "echarge": .echarge,
                "phi": .phi, "golden": .phi,
                "tau": .tau,
                "split": .split,
                "between": .between, "among": .among,
                "ways": .ways, "people": .people,
                "tip": .tip, "tax": .tax,
            ],
            unitNames: [:], // English unit names handled by Tokenizer's static unitMap
            currencyNames: [
                "dollar": "USD", "dollars": "USD",
                "euro": "EUR", "euros": "EUR",
                "yen": "JPY",
            ],
            leadingNoiseWords: ["what", "is"],
            leadingNoiseVariables: ["s", "whats"],
            trailingNoiseKeywords: [.ways, .people],
            errorMessages: [
                "divisionByZero": "÷ by 0",
                "invalidExpression": "invalid",
                "incompatibleUnits": "bad units",
                "genericError": "error",
            ],
            durationWords: .english,
            displayFormatWords: [
                "sci": .scientific,
                "hex": .hex,
                "binary": .binary, "bin": .binary,
                "octal": .octal, "oct": .octal,
            ],
            suggestionKeywords: [
                "pi", "e", "tau", "phi", "sum", "total", "average", "avg",
                "today", "now", "prev", "split", "between", "among",
                "ways", "people", "tip", "tax",
                "speedoflight", "lightspeed", "gravity", "avogadro",
                "planck", "boltzmann", "echarge",
            ]
        )
    }

    // MARK: - Spanish Overlay

    private static func spanishOverlay() -> ParserKeywords {
        ParserKeywords(
            operatorWords: [
                "más": .add, "mas": .add,
                "menos": .subtract,
                "por": .multiply,
            ],
            dividedBy: [("dividido", "entre"), ("dividido", "por")],
            keywords: [
                "en": .in, "como": .as, "a": .to,
                "de": .of, "sobre": .on,
                "qué": .what, "que": .what,
                "es": .is,
                "hoy": .today, "ahora": .now,
                "anterior": .prev, "previo": .prev,
                "suma": .sum,
                "promedio": .average,
                "dividir": .split, "repartir": .split,
                "entre": .between,
                "partes": .ways, "formas": .ways,
                "personas": .people,
                "propina": .tip, "impuesto": .tax,
            ],
            unitNames: [
                // Length
                "kilómetros": .kilometer, "kilometros": .kilometer, "kilómetro": .kilometer, "kilometro": .kilometer,
                "metros": .meter, "metro": .meter,
                "centímetros": .centimeter, "centimetros": .centimeter, "centímetro": .centimeter, "centimetro": .centimeter,
                "milímetros": .millimeter, "milimetros": .millimeter, "milímetro": .millimeter, "milimetro": .millimeter,
                "pulgadas": .inch, "pulgada": .inch,
                "pies": .foot, "pie": .foot,
                "yardas": .yard, "yarda": .yard,
                "millas": .mile, "milla": .mile,
                // Weight
                "kilogramos": .kilogram, "kilogramo": .kilogram, "kilos": .kilogram, "kilo": .kilogram,
                "gramos": .gram, "gramo": .gram,
                "miligramos": .milligram, "miligramo": .milligram,
                "toneladas": .tonne, "tonelada": .tonne,
                "libras": .pound, "libra": .pound,
                "onzas": .ounce, "onza": .ounce,
                // Temperature
                "grados": .degree,
                // Area
                "hectáreas": .hectare, "hectareas": .hectare, "hectárea": .hectare, "hectarea": .hectare,
                // Volume
                "litros": .liter, "litro": .liter,
                "mililitros": .milliliter, "mililitro": .milliliter,
                "galones": .gallon, "galón": .gallon, "galon": .gallon,
                "tazas": .cup, "taza": .cup,
                "cucharadas": .tablespoon, "cucharada": .tablespoon,
                "cucharaditas": .teaspoon, "cucharadita": .teaspoon,
                // Time
                "años": .year, "año": .year,
                "meses": .month, "mes": .month,
                "semanas": .week, "semana": .week,
                "días": .day, "dia": .day, "dias": .day, "día": .day,
                "horas": .hour, "hora": .hour,
                "minutos": .minute, "minuto": .minute,
                "segundos": .second, "segundo": .second,
                // Angle
                "radianes": .radian, "radián": .radian, "radian": .radian,
                // Speed
                "nudos": .knot, "nudo": .knot,
                // Energy
                "calorías": .calorie, "calorias": .calorie, "caloría": .calorie, "caloria": .calorie,
                "kilocalorías": .kilocalorie, "kilocalorias": .kilocalorie,
                // Pressure
                "atmósferas": .atmosphere, "atmosferas": .atmosphere, "atmósfera": .atmosphere, "atmosfera": .atmosphere,
                // Data
                "octetos": .byte, "octeto": .byte,
            ],
            currencyNames: [
                "dólar": "USD", "dolar": "USD", "dólares": "USD", "dolares": "USD",
                "euros": "EUR",
                "libra": "GBP", // currency context (weight handled by unitNames above)
            ],
            leadingNoiseWords: ["qué", "que", "es", "cuál", "cual", "cuánto", "cuanto"],
            leadingNoiseVariables: [],
            trailingNoiseKeywords: [.ways, .people], // .partes/.personas mapped to .ways/.people
            errorMessages: [
                "divisionByZero": "÷ por 0",
                "invalidExpression": "inválido",
                "incompatibleUnits": "unidades incompatibles",
                "genericError": "error",
            ],
            durationWords: .spanish,
            displayFormatWords: [
                "hexadecimal": .hex,
                "binario": .binary,
                "octal": .octal,
                "científica": .scientific, "cientifica": .scientific,
            ],
            suggestionKeywords: [
                "más", "menos", "por", "dividido",
                "suma", "promedio", "hoy", "ahora", "anterior",
                "dividir", "repartir", "entre",
                "partes", "personas", "propina", "impuesto",
                "kilómetros", "metros", "kilogramos", "gramos",
                "libras", "onzas", "pulgadas", "millas",
                "litros", "galones", "grados",
                "horas", "minutos", "segundos", "días",
                "dólar", "dólares", "euros",
            ]
        )
    }

    // MARK: - Portuguese Overlay

    private static func portugueseOverlay() -> ParserKeywords {
        ParserKeywords(
            operatorWords: [
                "mais": .add,
                "menos": .subtract,
                "vezes": .multiply,
            ],
            dividedBy: [("dividido", "por")],
            keywords: [
                "em": .in, "como": .as, "para": .to,
                "de": .of, "sobre": .on,
                "o que": .what, "qual": .what,
                "é": .is,
                "hoje": .today, "agora": .now,
                "anterior": .prev, "prévio": .prev, "previo": .prev,
                "soma": .sum,
                "média": .average, "media": .average,
                "dividir": .split, "repartir": .split,
                "entre": .between,
                "partes": .ways, "formas": .ways,
                "pessoas": .people,
                "gorjeta": .tip, "imposto": .tax,
            ],
            unitNames: [
                // Length
                "quilômetros": .kilometer, "quilometros": .kilometer, "quilômetro": .kilometer, "quilometro": .kilometer,
                "metros": .meter, "metro": .meter,
                "centímetros": .centimeter, "centimetros": .centimeter, "centímetro": .centimeter, "centimetro": .centimeter,
                "milímetros": .millimeter, "milimetros": .millimeter, "milímetro": .millimeter, "milimetro": .millimeter,
                "polegadas": .inch, "polegada": .inch,
                "pés": .foot, "pes": .foot, "pé": .foot, "pe": .foot,
                "jardas": .yard, "jarda": .yard,
                "milhas": .mile, "milha": .mile,
                // Weight
                "quilogramas": .kilogram, "quilograma": .kilogram, "quilos": .kilogram, "quilo": .kilogram,
                "gramas": .gram, "grama": .gram,
                "miligramas": .milligram, "miligrama": .milligram,
                "toneladas": .tonne, "tonelada": .tonne,
                "libras": .pound, "libra": .pound,
                "onças": .ounce, "oncas": .ounce, "onça": .ounce, "onca": .ounce,
                // Temperature
                "graus": .degree,
                // Area
                "hectares": .hectare, "hectare": .hectare,
                // Volume
                "litros": .liter, "litro": .liter,
                "mililitros": .milliliter, "mililitro": .milliliter,
                "galões": .gallon, "galoes": .gallon, "galão": .gallon, "galao": .gallon,
                "xícaras": .cup, "xicaras": .cup, "xícara": .cup, "xicara": .cup,
                "colheres": .tablespoon, "colher": .tablespoon,
                "colherinhas": .teaspoon, "colherinha": .teaspoon,
                // Time
                "anos": .year, "ano": .year,
                "meses": .month, "mês": .month, "mes": .month,
                "semanas": .week, "semana": .week,
                "dias": .day, "dia": .day,
                "horas": .hour, "hora": .hour,
                "minutos": .minute, "minuto": .minute,
                "segundos": .second, "segundo": .second,
                // Angle
                "radianos": .radian, "radiano": .radian,
                // Speed
                "nós": .knot, "nos": .knot,
                // Energy
                "calorias": .calorie, "caloria": .calorie,
                "quilocalorias": .kilocalorie, "quilocaloria": .kilocalorie,
                // Pressure
                "atmosferas": .atmosphere, "atmosfera": .atmosphere,
                // Data
                "octetos": .byte, "octeto": .byte,
            ],
            currencyNames: [
                "dólar": "USD", "dolar": "USD", "dólares": "USD", "dolares": "USD",
                "euros": "EUR",
                "real": "BRL", "reais": "BRL",
                "libra": "GBP",
            ],
            leadingNoiseWords: ["o que", "qual", "é", "quanto", "quão"],
            leadingNoiseVariables: [],
            trailingNoiseKeywords: [.ways, .people],
            errorMessages: [
                "divisionByZero": "÷ por 0",
                "invalidExpression": "inválido",
                "incompatibleUnits": "unidades incompatíveis",
                "genericError": "erro",
            ],
            durationWords: .portuguese,
            displayFormatWords: [
                "hexadecimal": .hex,
                "binário": .binary, "binario": .binary,
                "octal": .octal,
                "científica": .scientific, "cientifica": .scientific,
            ],
            suggestionKeywords: [
                "mais", "menos", "vezes", "dividido",
                "soma", "média", "hoje", "agora", "anterior",
                "dividir", "repartir", "entre",
                "partes", "pessoas", "gorjeta", "imposto",
                "quilômetros", "metros", "quilogramas", "gramas",
                "libras", "onças", "polegadas", "milhas",
                "litros", "galões", "graus",
                "horas", "minutos", "segundos", "dias",
                "dólar", "dólares", "euros", "real", "reais",
            ]
        )
    }

    // MARK: - Merge

    /// Merges overlay (localized) keywords on top of the base (English).
    /// Base entries are always present; overlay entries are added, overriding on conflict.
    private static func mergedKeywords(base: ParserKeywords, overlay: ParserKeywords) -> ParserKeywords {
        ParserKeywords(
            operatorWords: base.operatorWords.merging(overlay.operatorWords) { _, new in new },
            dividedBy: base.dividedBy + overlay.dividedBy,
            keywords: base.keywords.merging(overlay.keywords) { _, new in new },
            unitNames: base.unitNames.merging(overlay.unitNames) { _, new in new },
            currencyNames: base.currencyNames.merging(overlay.currencyNames) { _, new in new },
            leadingNoiseWords: base.leadingNoiseWords.union(overlay.leadingNoiseWords),
            leadingNoiseVariables: base.leadingNoiseVariables.union(overlay.leadingNoiseVariables),
            trailingNoiseKeywords: base.trailingNoiseKeywords.union(overlay.trailingNoiseKeywords),
            errorMessages: base.errorMessages.merging(overlay.errorMessages) { _, new in new },
            durationWords: overlay.durationWords,
            displayFormatWords: base.displayFormatWords.merging(overlay.displayFormatWords) { _, new in new },
            suggestionKeywords: base.suggestionKeywords + overlay.suggestionKeywords
        )
    }
}
