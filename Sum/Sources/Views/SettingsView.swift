import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared


    var body: some View {
        NavigationStack {
            List {
                // MARK: - Formatting
                Section {
                    Toggle(isOn: $settings.useThousandsSeparator) {
                        Label("Thousands Separator", systemImage: "number")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .tint(NumiTheme.textGreen)
                    .listRowBackground(NumiTheme.background)

                    HStack {
                        Label("Decimal Places", systemImage: "textformat.123")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
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
                        .tint(NumiTheme.dimGreen)
                        .fixedSize()
                    }
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text("Formatting")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }

                // MARK: - Editor
                Section {
                    Toggle(isOn: $settings.showLineNumbers) {
                        Label("Line Numbers", systemImage: "list.number")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .tint(NumiTheme.textGreen)
                    .listRowBackground(NumiTheme.background)

                    Toggle(isOn: $settings.syntaxHighlightingEnabled) {
                        Label("Syntax Colors", systemImage: "paintbrush")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .tint(NumiTheme.textGreen)
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text("Editor")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }

                // MARK: - Info
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .listRowBackground(NumiTheme.background)

                    NavigationLink {
                        LicenseView()
                    } label: {
                        Label("License", systemImage: "doc.text")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text("Info")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NumiTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NumiTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(NumiTheme.textGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
}
