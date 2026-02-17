import SwiftUI

struct NotesListView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingNoteId: UUID?
    @State private var editingName: String = ""

    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.05)
    private let textGreen = Color(red: 0.0, green: 0.9, blue: 0.3)
    private let dimGreen = Color(red: 0.0, green: 0.5, blue: 0.2)
    private let resultGreen = Color(red: 0.0, green: 1.0, blue: 0.4)

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(viewModel.notes.enumerated()), id: \.element.id) { index, note in
                    noteRow(note: note, index: index)
                        .listRowBackground(bgColor)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteNote(at: index)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(bgColor)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(bgColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(textGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.addNote()
                        dismiss()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(textGreen)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func noteRow(note: Note, index: Int) -> some View {
        Button {
            viewModel.switchNote(to: index)
            dismiss()
        } label: {
            HStack {
                if editingNoteId == note.id {
                    TextField("Note name", text: $editingName, onCommit: {
                        viewModel.renameNote(at: index, to: editingName)
                        editingNoteId = nil
                    })
                    .textFieldStyle(.plain)
                    .foregroundColor(textGreen)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textGreen)
                        Text(formattedDate(note.updatedAt))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(dimGreen)
                    }
                }

                Spacer()

                if index == viewModel.currentNoteIndex {
                    Image(systemName: "checkmark")
                        .foregroundColor(resultGreen)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .contextMenu {
            Button {
                editingName = note.title
                editingNoteId = note.id
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            if viewModel.notes.count > 1 {
                Button(role: .destructive) {
                    viewModel.deleteNote(at: index)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
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
