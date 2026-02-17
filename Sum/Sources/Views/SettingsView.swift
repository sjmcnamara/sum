import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.05)
    private let textGreen = Color(red: 0.0, green: 0.9, blue: 0.3)
    private let dimGreen = Color(red: 0.0, green: 0.5, blue: 0.2)

    var body: some View {
        NavigationStack {
            List {
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
