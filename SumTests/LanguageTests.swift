import XCTest
@testable import Sum

final class LanguageTests: XCTestCase {

    // MARK: - Language Model

    func testLanguageEnumCases() {
        XCTAssertEqual(Language.allCases.count, 2)
        XCTAssertEqual(Language.english.rawValue, "en")
        XCTAssertEqual(Language.spanish.rawValue, "es")
    }

    func testLanguageDisplayNames() {
        XCTAssertEqual(Language.english.displayName, "English")
        XCTAssertEqual(Language.spanish.displayName, "Español")
    }

    // MARK: - English Keywords

    func testEnglishKeywordsHaveExpectedStructure() {
        let kw = Language.parserKeywords(for: .english)
        XCTAssertFalse(kw.operatorWords.isEmpty)
        XCTAssertFalse(kw.keywords.isEmpty)
        XCTAssertFalse(kw.dividedBy.isEmpty)
        XCTAssertEqual(kw.durationWords.days, "days")
        XCTAssertEqual(kw.durationWords.hours, "hours")
    }

    func testEnglishOperatorWords() {
        let kw = Language.parserKeywords(for: .english)
        XCTAssertEqual(kw.operatorWords["plus"], .add)
        XCTAssertEqual(kw.operatorWords["minus"], .subtract)
        XCTAssertEqual(kw.operatorWords["times"], .multiply)
        XCTAssertEqual(kw.operatorWords["mod"], .modulo)
    }

    func testEnglishKeywordsMapping() {
        let kw = Language.parserKeywords(for: .english)
        XCTAssertEqual(kw.keywords["split"], .split)
        XCTAssertEqual(kw.keywords["tip"], .tip)
        XCTAssertEqual(kw.keywords["tax"], .tax)
        XCTAssertEqual(kw.keywords["pi"], .pi)
        XCTAssertEqual(kw.keywords["speedoflight"], .speedoflight)
    }

    // MARK: - Spanish Keywords (Merged)

    func testSpanishKeywordsIncludeEnglish() {
        let kw = Language.parserKeywords(for: .spanish)
        // English operator words still present
        XCTAssertEqual(kw.operatorWords["plus"], .add)
        // English keywords still present
        XCTAssertEqual(kw.keywords["split"], .split)
        XCTAssertEqual(kw.keywords["pi"], .pi)
    }

    func testSpanishOperatorWords() {
        let kw = Language.parserKeywords(for: .spanish)
        XCTAssertEqual(kw.operatorWords["más"], .add)
        XCTAssertEqual(kw.operatorWords["mas"], .add)
        XCTAssertEqual(kw.operatorWords["menos"], .subtract)
        XCTAssertEqual(kw.operatorWords["por"], .multiply)
    }

    func testSpanishKeywordsMapping() {
        let kw = Language.parserKeywords(for: .spanish)
        XCTAssertEqual(kw.keywords["hoy"], .today)
        XCTAssertEqual(kw.keywords["ahora"], .now)
        XCTAssertEqual(kw.keywords["propina"], .tip)
        XCTAssertEqual(kw.keywords["impuesto"], .tax)
        XCTAssertEqual(kw.keywords["dividir"], .split)
        XCTAssertEqual(kw.keywords["personas"], .people)
        XCTAssertEqual(kw.keywords["partes"], .ways)
    }

    func testSpanishUnitNames() {
        let kw = Language.parserKeywords(for: .spanish)
        XCTAssertEqual(kw.unitNames["kilómetros"], .kilometer)
        XCTAssertEqual(kw.unitNames["kilometros"], .kilometer)
        XCTAssertEqual(kw.unitNames["kilogramos"], .kilogram)
        XCTAssertEqual(kw.unitNames["libras"], .pound)
        XCTAssertEqual(kw.unitNames["pulgadas"], .inch)
        XCTAssertEqual(kw.unitNames["millas"], .mile)
        XCTAssertEqual(kw.unitNames["litros"], .liter)
    }

    func testSpanishDurationWords() {
        let kw = Language.parserKeywords(for: .spanish)
        XCTAssertEqual(kw.durationWords.days, "días")
        XCTAssertEqual(kw.durationWords.hours, "horas")
        XCTAssertEqual(kw.durationWords.minutes, "minutos")
        XCTAssertEqual(kw.durationWords.seconds, "segundos")
    }

    func testSpanishErrorMessages() {
        let kw = Language.parserKeywords(for: .spanish)
        XCTAssertEqual(kw.errorMessages["divisionByZero"], "÷ por 0")
        XCTAssertEqual(kw.errorMessages["invalidExpression"], "inválido")
        XCTAssertEqual(kw.errorMessages["incompatibleUnits"], "unidades incompatibles")
    }

    // MARK: - Parser Integration (Spanish)

    func testSpanishAddition() {
        let parser = NumiParser()
        parser.parserKeywords = Language.parserKeywords(for: .spanish)
        let results = parser.evaluateAll("5 más 3")
        XCTAssertEqual(results.first?.value?.number, 8)
    }

    func testSpanishSubtraction() {
        let parser = NumiParser()
        parser.parserKeywords = Language.parserKeywords(for: .spanish)
        let results = parser.evaluateAll("10 menos 4")
        XCTAssertEqual(results.first?.value?.number, 6)
    }

    func testSpanishMultiplication() {
        let parser = NumiParser()
        parser.parserKeywords = Language.parserKeywords(for: .spanish)
        let results = parser.evaluateAll("3 por 4")
        XCTAssertEqual(results.first?.value?.number, 12)
    }

    func testSpanishUnitConversion() {
        let parser = NumiParser()
        parser.parserKeywords = Language.parserKeywords(for: .spanish)
        let results = parser.evaluateAll("5 kilogramos en libras")
        XCTAssertNotNil(results.first?.value)
        XCTAssertEqual(results.first?.value?.unit, .pound)
        XCTAssertEqual(results.first?.value?.number ?? 0, 11.0231, accuracy: 0.01)
    }

    func testEnglishStillWorksInSpanishMode() {
        let parser = NumiParser()
        parser.parserKeywords = Language.parserKeywords(for: .spanish)
        let results = parser.evaluateAll("5 plus 3")
        XCTAssertEqual(results.first?.value?.number, 8)
    }

    func testSpanishErrorMessage() {
        let parser = NumiParser()
        parser.parserKeywords = Language.parserKeywords(for: .spanish)
        let results = parser.evaluateAll("10 / 0")
        XCTAssertEqual(results.first?.error, "÷ por 0")
    }

    // MARK: - Duration Formatting

    func testDurationFormattingSpanish() {
        let config = FormattingConfig(
            useThousandsSeparator: true,
            decimalPrecision: .auto,
            durationWords: .spanish
        )
        // 7200 seconds = 2 hours (between 3600 and 86400)
        let value = NumiValue(7200, unit: .time)
        let formatted = value.formatted(with: config)
        XCTAssertTrue(formatted.contains("horas"), "Expected Spanish duration word 'horas' in: \(formatted)")
    }

    func testDurationFormattingEnglish() {
        let config = FormattingConfig(
            useThousandsSeparator: true,
            decimalPrecision: .auto,
            durationWords: .english
        )
        let value = NumiValue(7200, unit: .time)
        let formatted = value.formatted(with: config)
        XCTAssertTrue(formatted.contains("hours"), "Expected English duration word 'hours' in: \(formatted)")
    }
}
