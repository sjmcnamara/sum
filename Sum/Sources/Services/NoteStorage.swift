import Foundation
import os

/// Persists notes to UserDefaults (lightweight, no CoreData needed)
class NoteStorage {
    static let shared = NoteStorage()

    private let notesKey = "org.sum.notes"
    private let indexKey = "org.sum.currentNoteIndex"
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadNotes() -> [Note] {
        guard let data = defaults.data(forKey: notesKey) else {
            NumiLogger.storage.info("No saved notes found, returning default")
            return [Note(title: "Calculator", content: "")]
        }
        do {
            let notes = try JSONDecoder().decode([Note].self, from: data)
            NumiLogger.storage.debug("Loaded \(notes.count) notes")
            return notes
        } catch {
            NumiLogger.storage.error("Failed to decode notes: \(error.localizedDescription)")
            // Back up corrupted data for diagnosis
            let backupKey = notesKey + ".backup"
            if defaults.data(forKey: backupKey) == nil {
                defaults.set(data, forKey: backupKey)
                NumiLogger.storage.warning("Backed up corrupted notes data to \(backupKey)")
            }
            return [Note(title: "Calculator", content: "")]
        }
    }

    func saveNotes(_ notes: [Note]) {
        do {
            let data = try JSONEncoder().encode(notes)
            defaults.set(data, forKey: notesKey)
        } catch {
            NumiLogger.storage.error("Failed to encode notes: \(error.localizedDescription)")
        }
    }

    func loadCurrentNoteIndex() -> Int {
        return defaults.integer(forKey: indexKey)
    }

    func saveCurrentNoteIndex(_ index: Int) {
        defaults.set(index, forKey: indexKey)
    }
}
