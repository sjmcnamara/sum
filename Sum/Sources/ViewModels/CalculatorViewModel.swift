import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class CalculatorViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var results: [LineResult] = []
    @Published var notes: [Note] = []
    @Published var currentNoteIndex: Int = 0
    @Published var isLoadingRates: Bool = false

    // Formatting & display settings
    @Published var formattingConfig: FormattingConfig = .default
    @Published var tokenRanges: [[TokenRange]] = []
    @Published var showLineNumbers: Bool = false
    @Published var syntaxHighlightingEnabled: Bool = true

    private let parser = NumiParser()
    private var tokenizer = Tokenizer()
    private let storage = NoteStorage.shared
    private let settings = AppSettings.shared
    private var isLoaded = false
    private var previousResultSignature: String = ""
    private let hapticGenerator = UISelectionFeedbackGenerator()
    private var cancellables = Set<AnyCancellable>()

    var currentNote: Note? {
        notes.indices.contains(currentNoteIndex) ? notes[currentNoteIndex] : nil
    }

    init() {
        loadNotes()

        // Subscribe to settings changes
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.syncSettings()
                    self?.recalculate()
                }
            }
            .store(in: &cancellables)

        // Debounce text changes to avoid redundant parsing during fast typing
        $text
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self, self.isLoaded else { return }
                self.recalculate()
            }
            .store(in: &cancellables)

        syncSettings()

        isLoaded = true
        recalculate()
        Task { await loadCurrencyRates() }
    }

    /// Pull current values from AppSettings
    private func syncSettings() {
        formattingConfig = settings.formattingConfig
        showLineNumbers = settings.showLineNumbers
        syntaxHighlightingEnabled = settings.syntaxHighlightingEnabled

        // Update parser and tokenizer with language-aware keyword tables
        let keywords = Language.parserKeywords(for: settings.language)
        parser.parserKeywords = keywords
        tokenizer.parserKeywords = keywords
    }

    // MARK: - Calculation

    func recalculate() {
        results = parser.evaluateAll(text)

        // Compute token ranges per line for syntax highlighting
        let lines = text.components(separatedBy: "\n")
        tokenRanges = lines.map { tokenizer.tokenizeWithRanges($0) }

        // Subtle haptic when results actually change
        let config = formattingConfig
        let signature = results.compactMap { $0.value?.formatted(with: config) }.joined(separator: "|")
        if signature != previousResultSignature && !previousResultSignature.isEmpty {
            hapticGenerator.selectionChanged()
        }
        previousResultSignature = signature

        // Auto-save
        saveCurrentNote()
    }

    // MARK: - Currency

    func loadCurrencyRates() async {
        isLoadingRates = true
        let rates = await CurrencyService.shared.getRates()
        parser.setCurrencyRates(rates)
        isLoadingRates = false
        recalculate()
    }

    // MARK: - Notes

    func loadNotes() {
        notes = storage.loadNotes()
        if notes.isEmpty {
            notes = [Note(title: L10n.string("calculator.defaultTitle"), content: "")]
        }
        let savedIndex = storage.loadCurrentNoteIndex()
        if notes.indices.contains(savedIndex) {
            currentNoteIndex = savedIndex
        }
        text = notes[currentNoteIndex].content
    }

    func saveCurrentNote() {
        guard isLoaded, notes.indices.contains(currentNoteIndex) else { return }
        notes[currentNoteIndex].content = text
        notes[currentNoteIndex].updatedAt = Date()
        storage.saveNotes(notes)
        storage.saveCurrentNoteIndex(currentNoteIndex)
    }

    func switchNote(to index: Int) {
        guard notes.indices.contains(index) else { return }
        saveCurrentNote()
        currentNoteIndex = index
        text = notes[index].content
        storage.saveCurrentNoteIndex(index)
    }

    func addNote() {
        saveCurrentNote()
        let note = Note(title: "Note \(notes.count + 1)", content: "")
        notes.append(note)
        currentNoteIndex = notes.count - 1
        text = ""
        storage.saveNotes(notes)
        storage.saveCurrentNoteIndex(currentNoteIndex)
    }

    func deleteNote(at index: Int) {
        guard notes.count > 1 else { return } // keep at least one
        notes.remove(at: index)
        if currentNoteIndex >= notes.count {
            currentNoteIndex = notes.count - 1
        }
        text = notes[currentNoteIndex].content
        storage.saveNotes(notes)
        storage.saveCurrentNoteIndex(currentNoteIndex)
    }

    func renameNote(at index: Int, to name: String) {
        guard notes.indices.contains(index) else { return }
        notes[index].title = name
        storage.saveNotes(notes)
    }

    // MARK: - Grand Total

    var grandTotal: NumiValue? {
        let values = results.compactMap { $0.value }
        guard values.count > 1 else { return nil }
        let sum = values.reduce(0.0) { $0 + $1.number }
        return NumiValue(sum, unit: values.last?.unit)
    }
}
