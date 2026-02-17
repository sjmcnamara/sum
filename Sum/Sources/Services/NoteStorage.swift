import Foundation

/// Persists notes to UserDefaults (lightweight, no CoreData needed)
class NoteStorage {
    static let shared = NoteStorage()

    private let notesKey = "org.sum.notes"
    private let indexKey = "org.sum.currentNoteIndex"
    private let defaults = UserDefaults.standard

    func loadNotes() -> [Note] {
        guard let data = defaults.data(forKey: notesKey),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            // Return a default note on first launch
            return [Note(title: "Calculator", content: "")]
        }
        return notes
    }

    func saveNotes(_ notes: [Note]) {
        if let data = try? JSONEncoder().encode(notes) {
            defaults.set(data, forKey: notesKey)
        }
    }

    func loadCurrentNoteIndex() -> Int {
        return defaults.integer(forKey: indexKey)
    }

    func saveCurrentNoteIndex(_ index: Int) {
        defaults.set(index, forKey: indexKey)
    }
}
