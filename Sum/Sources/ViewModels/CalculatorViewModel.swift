import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class CalculatorViewModel: ObservableObject {
    @Published var text: String = "" {
        didSet {
            guard isLoaded else { return }
            recalculate()
        }
    }
    @Published var results: [LineResult] = []
    @Published var notes: [Note] = []
    @Published var currentNoteIndex: Int = 0
    @Published var isLoadingRates: Bool = false

    private let parser = NumiParser()
    private let storage = NoteStorage.shared
    private var isLoaded = false
    private var previousResultSignature: String = ""
    private let hapticGenerator = UISelectionFeedbackGenerator()

    var currentNote: Note? {
        notes.indices.contains(currentNoteIndex) ? notes[currentNoteIndex] : nil
    }

    init() {
        loadNotes()
        isLoaded = true
        recalculate()
        Task { await loadCurrencyRates() }
    }

    // MARK: - Calculation

    func recalculate() {
        results = parser.evaluateAll(text)

        // Subtle haptic when results actually change
        let signature = results.compactMap { $0.value?.formatted }.joined(separator: "|")
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
        parser.currencyRates = rates
        isLoadingRates = false
        recalculate()
    }

    // MARK: - Notes

    func loadNotes() {
        notes = storage.loadNotes()
        if notes.isEmpty {
            notes = [Note(title: "Calculator", content: "")]
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
