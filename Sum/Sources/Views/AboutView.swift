import SwiftUI

struct CreditItem: Identifiable {
    enum Level { case dash, subDash }
    let id = UUID()
    let text: String
    let level: Level
}

struct AboutView: View {

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.6.0"
    }

    /// Parsed changelog entries for the scrolling credits
    private let credits: [(version: String, items: [CreditItem])] = Self.parseChangelog()

    // Easter egg state
    @State private var showCredits = false
    @State private var scrollPaused = false
    @State private var scrollOffset: CGFloat = 0
    @State private var creditsHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    @State private var scrollTimer: Timer?
    private let scrollSpeed: CGFloat = 30 // points per second
    private let timerInterval: TimeInterval = 1.0 / 60.0 // 60 fps

    var body: some View {
        ZStack {
            NumiTheme.background.ignoresSafeArea()

            VStack(spacing: 12) {
                if showCredits {
                    // Compact header when credits are visible
                    headerContent
                        .padding(.top, 16)

                    // Scrolling credits fill remaining space
                    creditsView
                        .transition(.opacity)
                } else {
                    // Centered layout (default)
                    Spacer()
                    headerContent
                    Spacer()

                    Text(L10n.string("about.subtitle"))
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen.opacity(0.7))
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(L10n.string("about.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NumiTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Shared header (icon + name + version)

    private var headerContent: some View {
        VStack(spacing: 12) {
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: showCredits ? 80 : 100, height: showCredits ? 80 : 100)
                .clipShape(RoundedRectangle(cornerRadius: showCredits ? 18 : 22, style: .continuous))
                .shadow(color: NumiTheme.resultGreen.opacity(0.3), radius: 12)
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showCredits.toggle()
                    }
                    if showCredits {
                        scrollOffset = 0
                        scrollPaused = false
                        // Delay to let layout settle before starting timer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            startTimer()
                        }
                    } else {
                        stopTimer()
                    }
                }

            Text("Sum")
                .font(.system(size: showCredits ? 20 : 24, weight: .semibold, design: .monospaced))
                .foregroundColor(NumiTheme.textGreen)

            Text("v\(version)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(NumiTheme.dimGreen)

            if showCredits {
                Text(L10n.string("about.subtitle"))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(NumiTheme.dimGreen.opacity(0.7))
            }
        }
    }

    // MARK: - Scrolling credits

    private var creditsView: some View {
        GeometryReader { geo in
            let height = geo.size.height
            ZStack {
                creditsContent
                    .offset(y: height - scrollOffset)
                    .onAppear {
                        containerHeight = height
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.clear, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    Rectangle().fill(Color.white)
                    LinearGradient(
                        colors: [.white, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                }
            )
        }
        .padding(.top, 8)
        .onTapGesture {
            guard showCredits else { return }
            scrollPaused.toggle()
            if scrollPaused {
                stopTimer()
            } else {
                startTimer()
            }
        }
    }

    private var creditsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(credits.enumerated()), id: \.offset) { _, entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.version)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(NumiTheme.resultGreen)

                    ForEach(entry.items) { item in
                        switch item.level {
                        case .dash:
                            Text(item.text)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(NumiTheme.dimGreen)
                                .padding(.top, 2)
                        case .subDash:
                            Text("  • \(item.text)")
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundColor(NumiTheme.dimGreen.opacity(0.7))
                        }
                    }
                }
            }

            // Padding at the bottom so it scrolls fully off
            Spacer().frame(height: 200)
        }
        .padding(.horizontal, 24)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: CreditsHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(CreditsHeightKey.self) { height in
            creditsHeight = height
        }
    }

    // MARK: - Timer-driven scrolling

    private func startTimer() {
        stopTimer()
        let step = scrollSpeed * CGFloat(timerInterval)
        scrollTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            let totalDistance = containerHeight + creditsHeight
            guard totalDistance > 0 else { return }
            scrollOffset += step
            if scrollOffset >= totalDistance {
                scrollOffset = 0 // loop
            }
        }
    }

    private func stopTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }

    // MARK: - Changelog parsing

    static func parseChangelog() -> [(version: String, items: [CreditItem])] {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return fallbackCredits()
        }
        return parseChangelogContent(content)
    }

    static func parseChangelogContent(_ content: String) -> [(version: String, items: [CreditItem])] {
        var results: [(version: String, items: [CreditItem])] = []
        var currentVersion: String?
        var currentItems: [CreditItem] = []

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Check raw line for indented sub-items first (space(s) + dash)
            let isIndented = line.hasPrefix("  - ") || line.hasPrefix(" - ")
            if trimmed.hasPrefix("## ") {
                if let ver = currentVersion {
                    results.append((ver, currentItems))
                }
                var title = String(trimmed.dropFirst(3))
                if title.hasPrefix("["), let closeBracket = title.firstIndex(of: "]") {
                    title = String(title[title.index(after: title.startIndex)..<closeBracket])
                }
                currentVersion = title
                currentItems = []
            } else if isIndented, trimmed.hasPrefix("- ") {
                currentItems.append(CreditItem(text: String(trimmed.dropFirst(2)), level: .subDash))
            } else if trimmed.hasPrefix("- ") {
                currentItems.append(CreditItem(text: String(trimmed.dropFirst(2)), level: .dash))
            }
        }
        if let ver = currentVersion {
            results.append((ver, currentItems))
        }
        return results
    }

    static func fallbackCredits() -> [(version: String, items: [CreditItem])] {
        [
            ("Sum 1.6.0", [CreditItem(text: "Polish & delight: onboarding, animations, better errors", level: .dash)]),
            ("Sum 1.5.1", [CreditItem(text: "Portuguese language support", level: .dash)]),
            ("Sum 1.5.0", [CreditItem(text: "Internationalization: Spanish language support", level: .dash)]),
            ("Sum 1.4.2", [CreditItem(text: "UI tweaks & polish", level: .dash)]),
            ("Sum 1.4.1", [CreditItem(text: "Crash fixes, performance, logging, refactoring", level: .dash)]),
            ("Sum 1.4.0", [CreditItem(text: "Natural language queries, smart suggestions", level: .dash)]),
            ("Sum 1.3.0", [CreditItem(text: "Power features: comments, constants, units", level: .dash)]),
            ("Sum 1.2.0", [CreditItem(text: "Formatting, syntax highlighting, line numbers", level: .dash)]),
            ("Sum 1.1.0", [CreditItem(text: "Settings, copy results, keyboard toolbar", level: .dash)]),
            ("Sum 1.0.0", [CreditItem(text: "Initial release", level: .dash)]),
        ]
    }
}

private struct CreditsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
    .preferredColorScheme(.dark)
}
