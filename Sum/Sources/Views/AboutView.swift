import SwiftUI

struct AboutView: View {
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.05)
    private let textGreen = Color(red: 0.0, green: 0.9, blue: 0.3)
    private let resultGreen = Color(red: 0.0, green: 1.0, blue: 0.4)
    private let dimGreen = Color(red: 0.0, green: 0.5, blue: 0.2)

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("\u{03A3}")
                    .font(.system(size: 72, weight: .thin, design: .monospaced))
                    .foregroundColor(resultGreen)

                Text("Sum")
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundColor(textGreen)

                Text("v\(version) (\(build))")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(dimGreen)

                Spacer()

                Text("A natural language calculator")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(dimGreen.opacity(0.7))
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(bgColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
    .preferredColorScheme(.dark)
}
