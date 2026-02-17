import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var showNotesList = false

    // Green-on-black theme colors
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.05)
    private let textGreen = Color(red: 0.0, green: 0.9, blue: 0.3)
    private let resultGreen = Color(red: 0.0, green: 1.0, blue: 0.4)
    private let dimGreen = Color(red: 0.0, green: 0.5, blue: 0.2)
    private let barBg = Color(red: 0.08, green: 0.08, blue: 0.08)

    private let uiTextGreen = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
    private let uiResultGreen = UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1)
    private let uiBgColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
    private let uiVarBlue = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NumiTextEditor(
                    text: $viewModel.text,
                    results: viewModel.results,
                    resultColor: uiResultGreen,
                    textColor: uiTextGreen,
                    variableColor: uiVarBlue,
                    backgroundColor: uiBgColor,
                    font: .monospacedSystemFont(ofSize: 17, weight: .regular)
                )

                if let total = viewModel.grandTotal {
                    grandTotalBar(total)
                }
            }
            .background(bgColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(bgColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    noteTitle
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.addNote() }) {
                            Label("New Note", systemImage: "plus")
                        }
                        Button(action: { showNotesList = true }) {
                            Label("All Notes", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(dimGreen)
                    }
                }
            }
            .sheet(isPresented: $showNotesList) {
                NotesListView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Grand Total

    private func grandTotalBar(_ total: NumiValue) -> some View {
        HStack {
            Text("Total")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(dimGreen)
            Spacer()
            Text(total.formatted)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundColor(resultGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            barBg
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(dimGreen.opacity(0.3))
                        .frame(height: 0.5)
                }
        )
    }

    // MARK: - Note Title

    private var noteTitle: some View {
        Button(action: { showNotesList = true }) {
            HStack(spacing: 4) {
                Text(viewModel.currentNote?.title ?? "Calculator")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(textGreen)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(dimGreen)
            }
        }
    }
}

#Preview {
    CalculatorView()
}
