import XCTest
@testable import Sum

// MARK: - Factorial Edge Cases

final class FactorialEdgeCaseTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testFactorialZero() {
        let results = parser.evaluateAll("fact(0)")
        XCTAssertEqual(results[0].value?.number, 1)
    }

    func testFactorialNegative() {
        let results = parser.evaluateAll("fact(-5)")
        XCTAssertNil(results[0].value)
    }

    func testFactorialTooLarge() {
        let results = parser.evaluateAll("fact(171)")
        XCTAssertNil(results[0].value)
    }

    func testFactorialNonInteger() {
        let results = parser.evaluateAll("fact(5.5)")
        XCTAssertNil(results[0].value)
    }
}

// MARK: - Modulo Edge Cases

final class ModuloEdgeCaseTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testModuloByZero() {
        let results = parser.evaluateAll("10 mod 0")
        // Modulo by zero should produce nil or error, not crash
        XCTAssertTrue(results[0].value == nil || results[0].error != nil)
    }
}

// MARK: - NoteStorage Corruption Tests

final class NoteStorageCorruptionTests: XCTestCase {
    private var storage: NoteStorage!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.sum.test.corruption")!
        testDefaults.removePersistentDomain(forName: "com.sum.test.corruption")
        storage = NoteStorage(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.sum.test.corruption")
        super.tearDown()
    }

    func testCorruptedNotesReturnsDefault() {
        // Write garbage JSON to the notes key
        testDefaults.set(Data("not valid json".utf8), forKey: "org.sum.notes")
        let loaded = storage.loadNotes()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Calculator")
    }

    func testCorruptedNotesBackedUp() {
        let garbage = Data("corrupted data".utf8)
        testDefaults.set(garbage, forKey: "org.sum.notes")
        _ = storage.loadNotes()
        // Should have backed up the corrupted data
        let backup = testDefaults.data(forKey: "org.sum.notes.backup")
        XCTAssertNotNil(backup)
        XCTAssertEqual(backup, garbage)
    }
}

// MARK: - Tokenizer Consistency Tests

final class TokenizerConsistencyTests: XCTestCase {
    private let tokenizer = Tokenizer()

    func testTokenizeAndRangesConsistency() {
        // For representative inputs, token count from tokenize()
        // should match range count from tokenizeWithRanges()
        let inputs = [
            "5 + 3",
            "100 km in miles",
            "sqrt(144)",
            "x = 42",
            "20% of 580",
            "$100 in EUR",
            "0xFF + 0b1010",
            "speedoflight in km/h",
            "// comment",
            "10 * 2 # inline",
        ]
        for input in inputs {
            let tokens = tokenizer.tokenize(input)
            let ranges = tokenizer.tokenizeWithRanges(input)
            XCTAssertEqual(tokens.count, ranges.count,
                           "Mismatch for '\(input)': \(tokens.count) tokens vs \(ranges.count) ranges")
        }
    }

    func testCompoundUnitHighlightRange() {
        let ranges = tokenizer.tokenizeWithRanges("100 km/h")
        let units = ranges.filter { $0.kind == .unit }
        XCTAssertEqual(units.count, 1, "Expected single compound unit range")
        // "km/h" starts at position 4, length 4
        XCTAssertEqual(units[0].range.location, 4)
        XCTAssertEqual(units[0].range.length, 4)
    }

    func testAllSingleWordUnitsAccessible() {
        // Every entry in singleWordUnitMap should be findable through tokenize(),
        // except words that are also keywords/functions/operators (those take priority)
        let keywordsAndFunctions: Set<String> = [
            "in", "as", "to", "of", "on", "off", "e", "m", "j", "l",
            "not", "mod", "sum", "total", "average", "avg",
        ]
        for (word, expectedUnit) in Tokenizer.singleWordUnitMap {
            if keywordsAndFunctions.contains(word) { continue }
            let tokens = tokenizer.tokenize(word)
            let unitTokens = tokens.compactMap { token -> NumiUnit? in
                if case .unit(let u) = token { return u }
                return nil
            }
            XCTAssertTrue(unitTokens.contains(expectedUnit),
                          "Unit '\(word)' -> \(expectedUnit) not found in tokens: \(tokens)")
        }
    }
}

// MARK: - Word Prefix Edge Cases

final class WordPrefixTests: XCTestCase {

    func testWordPrefixWithEmoji() {
        // Cursor after emoji should return nil (no crash)
        let text = "hello 🎉"
        let offset = (text as NSString).length
        let result = NumiTextEditorView.wordPrefix(in: text, cursorUTF16Offset: offset)
        // Emoji is not a letter/number, so backward walk stops at emoji boundary
        // Should not crash, may or may not return nil depending on what precedes
        // The key assertion is that it doesn't crash
        _ = result // no crash = pass
    }

    func testWordPrefixAtStart() {
        let result = NumiTextEditorView.wordPrefix(in: "hello", cursorUTF16Offset: 0)
        XCTAssertNil(result, "Cursor at start should return nil")
    }

    func testWordPrefixSingleChar() {
        let result = NumiTextEditorView.wordPrefix(in: "a", cursorUTF16Offset: 1)
        XCTAssertNil(result, "Single char prefix should return nil (minimum 2 chars)")
    }

    func testWordPrefixValidPrefix() {
        let result = NumiTextEditorView.wordPrefix(in: "sqrt", cursorUTF16Offset: 4)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.prefix, "sqrt")
    }
}
