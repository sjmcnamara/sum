import SwiftUI

struct AboutView: View {

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.4.1"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ZStack {
            NumiTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("\u{03A3}")
                    .font(.system(size: 72, weight: .thin, design: .monospaced))
                    .foregroundColor(NumiTheme.resultGreen)

                Text("Sum")
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundColor(NumiTheme.textGreen)

                Text("v\(version) (\(build))")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(NumiTheme.dimGreen)

                Spacer()

                Text("A natural language calculator")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(NumiTheme.dimGreen.opacity(0.7))
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NumiTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
    .preferredColorScheme(.dark)
}
