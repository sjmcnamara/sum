import SwiftUI

struct NotesListView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingNoteId: UUID?
    @State private var editingName: String = ""
    @State private var searchText: String = ""


    /// Notes filtered by search text (matches title or content)
    private var filteredNotes: [(index: Int, note: Note)] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            return viewModel.notes.enumerated().map { ($0.offset, $0.element) }
        }
        return viewModel.notes.enumerated().compactMap { index, note in
            if note.title.lowercased().contains(query) ||
               note.content.lowercased().contains(query) {
                return (index, note)
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredNotes, id: \.note.id) { index, note in
                    noteRow(note: note, index: index)
                        .listRowBackground(NumiTheme.background)
                }
                .onDelete(perform: viewModel.notes.count > 1 ? { indexSet in
                    // Map filtered indices back to model indices
                    let filtered = filteredNotes
                    for offset in indexSet {
                        let modelIndex = filtered[offset].index
                        viewModel.deleteNote(at: modelIndex)
                    }
                } : nil)
            }
            .searchable(text: $searchText, prompt: L10n.string("notes.searchPrompt"))
            .scrollContentBackground(.hidden)
            .background(NumiTheme.background)
            .navigationTitle(L10n.string("notes.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NumiTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string("notes.done")) { dismiss() }
                        .foregroundColor(NumiTheme.textGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.addNote()
                        dismiss()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(NumiTheme.textGreen)
                    }
                }
            }
        }
        .preferredColorScheme(AppSettings.shared.theme.isDark ? .dark : .light)
    }

    private func noteRow(note: Note, index: Int) -> some View {
        Button {
            viewModel.switchNote(to: index)
            dismiss()
        } label: {
            HStack {
                if editingNoteId == note.id {
                    TextField(L10n.string("notes.noteName"), text: $editingName, onCommit: {
                        viewModel.renameNote(at: index, to: editingName)
                        editingNoteId = nil
                    })
                    .textFieldStyle(.plain)
                    .foregroundColor(NumiTheme.textGreen)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                        if let preview = contentPreview(note) {
                            Text(preview)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(NumiTheme.dimGreen.opacity(0.8))
                                .lineLimit(1)
                        }
                        Text(formattedDate(note.updatedAt))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(NumiTheme.dimGreen.opacity(0.5))
                    }
                }

                Spacer()

                if index == viewModel.currentNoteIndex {
                    Image(systemName: "checkmark")
                        .foregroundColor(NumiTheme.resultGreen)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .contextMenu {
            Button {
                editingName = note.title
                editingNoteId = note.id
            } label: {
                Label(L10n.string("notes.rename"), systemImage: "pencil")
            }

            if viewModel.notes.count > 1 {
                Button(role: .destructive) {
                    viewModel.deleteNote(at: index)
                } label: {
                    Label(L10n.string("notes.delete"), systemImage: "trash")
                }
            }
        }
    }

    private func contentPreview(_ note: Note) -> String? {
        let firstLine = note.content
            .components(separatedBy: "\n")
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        guard let line = firstLine, !line.isEmpty else { return nil }
        return String(line.prefix(40))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotesListView(viewModel: CalculatorViewModel())
}
