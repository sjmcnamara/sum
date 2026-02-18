import SwiftUI

/// First-launch overlay with tappable example expressions
struct OnboardingOverlayView: View {
    var onTryExample: (String) -> Void
    var onDismiss: () -> Void

    private let examples: [(expression: String, label: String)] = [
        ("128 + 256", "onboarding.basicMath"),
        ("5 kg in pounds", "onboarding.unitConversion"),
        ("20% of 580", "onboarding.percentages"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Title
                Text("Sum")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(NumiTheme.resultGreen)

                Text(L10n.string("onboarding.subtitle"))
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundColor(NumiTheme.dimGreen)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 8)

                // Example cards
                VStack(spacing: 12) {
                    ForEach(examples, id: \.expression) { example in
                        exampleCard(expression: example.expression,
                                    label: L10n.string(example.label))
                    }
                }
                .padding(.horizontal, 32)

                Text(L10n.string("onboarding.tryIt"))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(NumiTheme.dimGreen.opacity(0.7))

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Text(L10n.string("onboarding.dismiss"))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(NumiTheme.textGreen)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(NumiTheme.dimGreen.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.bottom, 40)
            }
        }
        .transition(.opacity)
    }

    private func exampleCard(expression: String, label: String) -> some View {
        Button {
            onTryExample(expression)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expression)
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundColor(NumiTheme.textGreen)
                    Text(label)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(NumiTheme.dimGreen.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(NumiTheme.dimGreen.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(NumiTheme.barBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(NumiTheme.dimGreen.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
