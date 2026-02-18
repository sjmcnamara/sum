import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared

    /// Common currencies for the default currency picker
    private let currencyOptions = [
        "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF",
        "CNY", "INR", "KRW", "BRL", "MXN", "SGD", "HKD",
    ]

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Theme
                Section {
                    HStack {
                        Label(L10n.string("settings.theme"), systemImage: "paintpalette")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                            .lineLimit(1)
                            .layoutPriority(1)
                        Spacer()
                        Picker("", selection: $settings.theme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(NumiTheme.dimGreen)
                        .fixedSize()
                    }
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text(L10n.string("settings.theme"))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }

                // MARK: - Language
                Section {
                    HStack {
                        Label(L10n.string("settings.language"), systemImage: "globe")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                            .lineLimit(1)
                            .layoutPriority(1)
                        Spacer()
                        Picker("", selection: $settings.language) {
                            ForEach(Language.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(NumiTheme.dimGreen)
                        .fixedSize()
                    }
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text(L10n.string("settings.language"))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }

                // MARK: - Formatting
                Section {
                    Toggle(isOn: $settings.useThousandsSeparator) {
                        Label(L10n.string("settings.thousandsSeparator"), systemImage: "number")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .tint(NumiTheme.textGreen)
                    .listRowBackground(NumiTheme.background)

                    HStack {
                        Label(L10n.string("settings.decimalPlaces"), systemImage: "textformat.123")
                            .font(.system(.caption, design: .monospaced))
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

                    HStack {
                        Label(L10n.string("settings.defaultCurrency"), systemImage: "dollarsign.circle")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                            .lineLimit(1)
                            .layoutPriority(1)
                        Spacer()
                        Picker("", selection: $settings.defaultCurrency) {
                            ForEach(currencyOptions, id: \.self) { code in
                                Text(code).tag(code)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(NumiTheme.dimGreen)
                        .fixedSize()
                    }
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text(L10n.string("settings.formatting"))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }

                // MARK: - Editor
                Section {
                    Toggle(isOn: $settings.showLineNumbers) {
                        Label(L10n.string("settings.lineNumbers"), systemImage: "list.number")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .tint(NumiTheme.textGreen)
                    .listRowBackground(NumiTheme.background)

                    Toggle(isOn: $settings.syntaxHighlightingEnabled) {
                        Label(L10n.string("settings.syntaxColors"), systemImage: "paintbrush")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .tint(NumiTheme.textGreen)
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text(L10n.string("settings.editor"))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }

                // MARK: - Info
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label(L10n.string("settings.about"), systemImage: "info.circle")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .listRowBackground(NumiTheme.background)

                    NavigationLink {
                        LicenseView()
                    } label: {
                        Label(L10n.string("settings.license"), systemImage: "doc.text")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(NumiTheme.textGreen)
                    }
                    .listRowBackground(NumiTheme.background)
                } header: {
                    Text(L10n.string("settings.info"))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NumiTheme.background)
            .navigationTitle(L10n.string("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NumiTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string("settings.done")) { dismiss() }
                        .foregroundColor(NumiTheme.textGreen)
                }
            }
        }
        .background(NumiTheme.background.ignoresSafeArea())
        .preferredColorScheme(settings.theme.isDark ? .dark : .light)
    }
}

#Preview {
    SettingsView()
}
