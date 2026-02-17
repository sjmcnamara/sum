import SwiftUI
import UIKit

/// A UITextView wrapper that provides line-by-line text editing with results overlay
/// and syntax highlighting (variable assignments in blue)
struct NumiTextEditor: UIViewRepresentable {
    @Binding var text: String
    var results: [LineResult]
    var resultColor: UIColor
    var textColor: UIColor
    var variableColor: UIColor
    var backgroundColor: UIColor
    var font: UIFont

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> NumiTextEditorView {
        let view = NumiTextEditorView()
        view.textView.delegate = context.coordinator
        view.editorFont = font
        view.defaultTextColor = textColor
        view.variableColor = variableColor
        view.textView.backgroundColor = backgroundColor
        view.textView.tintColor = resultColor // cursor color
        view.textView.autocorrectionType = .no
        view.textView.autocapitalizationType = .none
        view.textView.spellCheckingType = .no
        view.textView.smartDashesType = .no
        view.textView.smartQuotesType = .no
        view.textView.keyboardType = .asciiCapable
        view.textView.keyboardAppearance = .dark
        view.resultColor = resultColor
        view.resultsFont = font
        view.setText(text, results: results)
        return view
    }

    func updateUIView(_ uiView: NumiTextEditorView, context: Context) {
        uiView.defaultTextColor = textColor
        uiView.variableColor = variableColor
        uiView.textView.backgroundColor = backgroundColor
        uiView.resultColor = resultColor

        // Only update text if it actually changed (avoid cursor jumping)
        let currentPlain = uiView.textView.text ?? ""
        if currentPlain != text {
            uiView.setText(text, results: results)
        } else {
            uiView.applyHighlighting(results: results)
            uiView.updateResults(results)
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: NumiTextEditor
        var isUpdating = false

        init(_ parent: NumiTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            parent.text = textView.text
        }
    }
}

/// Custom UIView that combines a UITextView with a results overlay
class NumiTextEditorView: UIView {
    let textView = UITextView()
    private let resultsOverlay = ResultsOverlayView()
    var resultColor: UIColor = .green
    var resultsFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .regular)
    var editorFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .regular)
    var defaultTextColor: UIColor = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
    var variableColor: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)

    private var currentResults: [LineResult] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        // Use the default typing attributes so new text is green
        textView.typingAttributes = [
            .font: editorFont,
            .foregroundColor: defaultTextColor,
        ]
        addSubview(textView)

        resultsOverlay.translatesAutoresizingMaskIntoConstraints = false
        resultsOverlay.isUserInteractionEnabled = false
        resultsOverlay.backgroundColor = .clear
        addSubview(resultsOverlay)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),

            resultsOverlay.topAnchor.constraint(equalTo: topAnchor),
            resultsOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            resultsOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            resultsOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )
    }

    @objc private func textDidChange() {
        updateResultsLayout()
    }

    /// Sets text with full attributed string rebuild
    func setText(_ text: String, results: [LineResult]) {
        let attributed = buildAttributedString(text: text, results: results)
        let selectedRange = textView.selectedRange
        textView.attributedText = attributed
        // Restore cursor position
        if selectedRange.location <= (textView.text?.utf16.count ?? 0) {
            textView.selectedRange = selectedRange
        }
        // Ensure typing attributes stay correct for new input
        textView.typingAttributes = [
            .font: editorFont,
            .foregroundColor: defaultTextColor,
        ]
        currentResults = results
        updateRightInset()
        updateResultsLayout()
    }

    /// Re-applies highlighting without replacing text (preserves cursor)
    func applyHighlighting(results: [LineResult]) {
        let text = textView.text ?? ""
        let selectedRange = textView.selectedRange
        let attributed = buildAttributedString(text: text, results: results)
        textView.attributedText = attributed
        if selectedRange.location <= (textView.text?.utf16.count ?? 0) {
            textView.selectedRange = selectedRange
        }
        textView.typingAttributes = [
            .font: editorFont,
            .foregroundColor: defaultTextColor,
        ]
    }

    /// Builds a syntax-highlighted attributed string
    private func buildAttributedString(text: String, results: [LineResult]) -> NSAttributedString {
        let fullString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: editorFont,
                .foregroundColor: defaultTextColor,
            ]
        )

        let lines = text.components(separatedBy: "\n")
        var charOffset = 0

        for (lineIndex, line) in lines.enumerated() {
            let lineUtf16Count = line.utf16.count

            // Check if this line has a variable assignment
            if lineIndex < results.count,
               let varName = results[lineIndex].assignmentVariable {
                // Find the variable name in the line
                if let range = line.range(of: varName) {
                    let nsRange = NSRange(range, in: line)
                    let adjustedRange = NSRange(location: charOffset + nsRange.location, length: nsRange.length)
                    if adjustedRange.location + adjustedRange.length <= fullString.length {
                        fullString.addAttribute(.foregroundColor, value: variableColor, range: adjustedRange)
                    }
                }
            }

            charOffset += lineUtf16Count + 1 // +1 for newline
        }

        return fullString
    }

    func updateResults(_ results: [LineResult]) {
        currentResults = results
        updateRightInset()
        updateResultsLayout()
    }

    private func updateRightInset() {
        let maxResultWidth = currentResults.compactMap { $0.value?.formatted }
            .map { resultWidth($0) }
            .max() ?? 0
        let rightInset = maxResultWidth > 0 ? maxResultWidth + 24 : 12
        textView.textContainerInset.right = rightInset
    }

    private func resultWidth(_ text: String) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: resultsFont]
        let size = (text as NSString).size(withAttributes: attrs)
        return ceil(size.width)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateResultsLayout()
    }

    private func updateResultsLayout() {
        var resultEntries: [(CGRect, String)] = []

        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer

        let lines = textView.text.components(separatedBy: "\n")
        var charIndex = 0

        for (lineIndex, line) in lines.enumerated() {
            let lineRange = NSRange(location: charIndex, length: line.utf16.count)
            charIndex += line.utf16.count + 1

            guard lineIndex < currentResults.count,
                  let value = currentResults[lineIndex].value else {
                continue
            }

            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

            if lineRect.height == 0 {
                if lineRange.location < textView.textStorage.length {
                    let glyphIdx = layoutManager.glyphIndexForCharacter(at: lineRange.location)
                    lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIdx, effectiveRange: nil)
                } else {
                    let lineHeight = resultsFont.lineHeight
                    lineRect = CGRect(x: 0, y: lineRect.maxY, width: bounds.width, height: lineHeight)
                }
            }

            lineRect.origin.x += textView.textContainerInset.left
            lineRect.origin.y += textView.textContainerInset.top
            lineRect.origin.y -= textView.contentOffset.y

            resultEntries.append((lineRect, value.formatted))
        }

        resultsOverlay.entries = resultEntries
        resultsOverlay.resultColor = resultColor
        resultsOverlay.resultsFont = resultsFont
        resultsOverlay.setNeedsDisplay()
    }
}

/// Draws result labels aligned to the right of each line
class ResultsOverlayView: UIView {
    var entries: [(CGRect, String)] = []
    var resultColor: UIColor = .green
    var resultsFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .medium)

    override func draw(_ rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attrs: [NSAttributedString.Key: Any] = [
            .font: resultsFont,
            .foregroundColor: resultColor,
            .paragraphStyle: paragraphStyle,
        ]

        for (lineRect, text) in entries {
            let resultSize = (text as NSString).size(withAttributes: attrs)
            let x = bounds.width - resultSize.width - 16
            let y = lineRect.origin.y + (lineRect.height - resultSize.height) / 2
            let drawRect = CGRect(x: x, y: y, width: resultSize.width, height: resultSize.height)

            (text as NSString).draw(in: drawRect, withAttributes: attrs)
        }
    }
}
