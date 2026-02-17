import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var showNotesList = false
    @State private var showSettings = false
    @State private var showCopiedTotal = false


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NumiTextEditor(
                    text: $viewModel.text,
                    results: viewModel.results,
                    tokenRanges: viewModel.tokenRanges,
                    showLineNumbers: viewModel.showLineNumbers,
                    syntaxHighlightingEnabled: viewModel.syntaxHighlightingEnabled,
                    formattingConfig: viewModel.formattingConfig,
                    resultColor: NumiTheme.uiResultGreen,
                    textColor: NumiTheme.uiTextGreen,
                    variableColor: NumiTheme.uiVariableBlue,
                    keywordColor: NumiTheme.uiKeyword,
                    functionColor: NumiTheme.uiFunction,
                    commentColor: NumiTheme.uiComment,
                    backgroundColor: NumiTheme.uiBackground,
                    font: .monospacedSystemFont(ofSize: 17, weight: .regular)
                )

                if let total = viewModel.grandTotal {
                    grandTotalBar(total)
                }
            }
            .background(NumiTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NumiTheme.background, for: .navigationBar)
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
                        Divider()
                        Button(action: { showSettings = true }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(NumiTheme.dimGreen)
                    }
                }
            }
            .sheet(isPresented: $showNotesList) {
                NotesListView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Grand Total

    private func grandTotalBar(_ total: NumiValue) -> some View {
        HStack {
            Text("Total")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(NumiTheme.dimGreen)
            Spacer()
            Text(showCopiedTotal ? "Copied" : total.formatted(with: viewModel.formattingConfig))
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundColor(showCopiedTotal ? NumiTheme.textGreen : NumiTheme.resultGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            NumiTheme.barBackground
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(NumiTheme.dimGreen.opacity(0.3))
                        .frame(height: 0.5)
                }
        )
        .onTapGesture {
            UIPasteboard.general.string = total.formatted(with: viewModel.formattingConfig)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeIn(duration: 0.1)) { showCopiedTotal = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.2)) { showCopiedTotal = false }
            }
        }
    }

    // MARK: - Note Title

    private var noteTitle: some View {
        Button(action: { showNotesList = true }) {
            HStack(spacing: 4) {
                Text(viewModel.currentNote?.title ?? "Calculator")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(NumiTheme.textGreen)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(NumiTheme.dimGreen)
            }
        }
    }
}

#Preview {
    CalculatorView()
}
