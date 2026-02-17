import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared

    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.05)
    private let textGreen = Color(red: 0.0, green: 0.9, blue: 0.3)
    private let dimGreen = Color(red: 0.0, green: 0.5, blue: 0.2)

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Formatting
                Section {
                    Toggle(isOn: $settings.useThousandsSeparator) {
                        Label("Thousands Separator", systemImage: "number")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textGreen)
                    }
                    .tint(textGreen)
                    .listRowBackground(bgColor)

                    HStack {
                        Label("Decimal Places", systemImage: "textformat.123")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textGreen)
                            .lineLimit(1)
                            .layoutPriority(1)
                        Spacer()
                        Picker("", selection: $settings.decimalPrecision) {
                            ForEach(DecimalPrecision.allCases, id: \.self) { precision in
                                Text(precision.label)
                                    .tag(precision)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(dimGreen)
                        .fixedSize()
                    }
                    .listRowBackground(bgColor)
                } header: {
                    Text("Formatting")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(dimGreen)
                }

                // MARK: - Editor
                Section {
                    Toggle(isOn: $settings.showLineNumbers) {
                        Label("Line Numbers", systemImage: "list.number")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textGreen)
                    }
                    .tint(textGreen)
                    .listRowBackground(bgColor)

                    Toggle(isOn: $settings.syntaxHighlightingEnabled) {
                        Label("Syntax Colors", systemImage: "paintbrush")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textGreen)
                    }
                    .tint(textGreen)
                    .listRowBackground(bgColor)
                } header: {
                    Text("Editor")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(dimGreen)
                }

                // MARK: - Info
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textGreen)
                    }
                    .listRowBackground(bgColor)

                    NavigationLink {
                        LicenseView()
                    } label: {
                        Label("License", systemImage: "doc.text")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(textGreen)
                    }
                    .listRowBackground(bgColor)
                } header: {
                    Text("Info")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(dimGreen)
                }
            }
            .scrollContentBackground(.hidden)
            .background(bgColor)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(bgColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(textGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
}
