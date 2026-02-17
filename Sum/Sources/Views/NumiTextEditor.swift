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
    private let placeholderLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private lazy var copiedToast: UILabel = {
        let label = UILabel()
        label.text = "Copied"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        label.backgroundColor = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private func setup() {
        backgroundColor = .clear

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        // Shake to undo support
        textView.allowsEditingTextAttributes = false
        // Use the default typing attributes so new text is green
        textView.typingAttributes = [
            .font: editorFont,
            .foregroundColor: defaultTextColor,
        ]
        textView.inputAccessoryView = buildKeyboardToolbar()
        addSubview(textView)

        resultsOverlay.translatesAutoresizingMaskIntoConstraints = false
        resultsOverlay.isUserInteractionEnabled = true
        resultsOverlay.backgroundColor = .clear
        resultsOverlay.onResultTapped = { [weak self] text in
            self?.copyResult(text)
        }
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

        // Toast for copy feedback
        addSubview(copiedToast)
        NSLayoutConstraint.activate([
            copiedToast.centerXAnchor.constraint(equalTo: centerXAnchor),
            copiedToast.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            copiedToast.widthAnchor.constraint(equalToConstant: 72),
            copiedToast.heightAnchor.constraint(equalToConstant: 28),
        ])

        // Placeholder for empty state
        placeholderLabel.numberOfLines = 0
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.isUserInteractionEnabled = false
        let placeholderLines = [
            "128 + 256",
            "width = 1920",
            "height = 1080",
            "width * height",
            "",
            "5 kg in pounds",
            "$100 in EUR",
            "20% of 580",
            "",
            "sum",
        ]
        let placeholderText = placeholderLines.joined(separator: "\n")
        let dimColor = UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 0.4)
        placeholderLabel.attributedText = NSAttributedString(
            string: placeholderText,
            attributes: [
                .font: editorFont,
                .foregroundColor: dimColor,
            ]
        )
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )
    }

    @objc private func textDidChange() {
        updatePlaceholderVisibility()
        updateResultsLayout()
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textView.text ?? "").isEmpty
    }

    // MARK: - Keyboard Toolbar

    private func buildKeyboardToolbar() -> UIView {
        let toolbarHeight: CGFloat = 40
        let toolbar = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: toolbarHeight))
        toolbar.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)

        // Top border
        let border = UIView()
        border.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 0.3)
        border.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(border)
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: toolbar.topAnchor),
            border.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        let items: [(String, String)] = [
            ("+", "+"), ("−", "-"), ("×", "*"), ("÷", "/"),
            ("^", "^"), ("(", "("), (")", ")"), ("=", " = "),
            ("%", "%"), ("$", "$"), ("in", " in "),
        ]

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 1),
            scrollView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])

        let buttonColor = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
        let buttonBg = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)

        for (label, insert) in items {
            let button = UIButton(type: .system)
            button.setTitle(label, for: .normal)
            button.titleLabel?.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
            button.setTitleColor(buttonColor, for: .normal)
            button.backgroundColor = buttonBg
            button.layer.cornerRadius = 6
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
            if #available(iOS 15.0, *) {
                var config = UIButton.Configuration.plain()
                config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
                config.baseForegroundColor = buttonColor
                config.background.backgroundColor = buttonBg
                config.background.cornerRadius = 6
                button.configuration = config
            } else {
                button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
            }

            // Store insert text in accessibilityIdentifier (lightweight tag approach)
            button.accessibilityIdentifier = insert
            button.addTarget(self, action: #selector(toolbarButtonTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }

        // Dismiss keyboard button at the end
        let dismissButton = UIButton(type: .system)
        dismissButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        dismissButton.tintColor = UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 1)
        dismissButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        dismissButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        stack.addArrangedSubview(dismissButton)

        return toolbar
    }

    @objc private func toolbarButtonTapped(_ sender: UIButton) {
        guard let insert = sender.accessibilityIdentifier else { return }
        textView.insertText(insert)
    }

    @objc private func dismissKeyboard() {
        textView.resignFirstResponder()
    }

    // MARK: - Copy to Clipboard

    private func copyResult(_ text: String) {
        // Strip currency symbols and unit suffixes for a clean numeric copy
        UIPasteboard.general.string = text
        showCopiedToast()
    }

    private func showCopiedToast() {
        copiedToast.alpha = 0
        copiedToast.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.15) {
            self.copiedToast.alpha = 1
            self.copiedToast.transform = .identity
        }
        UIView.animate(withDuration: 0.2, delay: 0.8, options: []) {
            self.copiedToast.alpha = 0
        }
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
        updatePlaceholderVisibility()
        updateRightInset()
        updateResultsLayout()
    }

    /// Re-applies highlighting without replacing text (preserves cursor and undo stack)
    func applyHighlighting(results: [LineResult]) {
        let storage = textView.textStorage
        let fullRange = NSRange(location: 0, length: storage.length)
        guard fullRange.length > 0 else { return }

        // Group edits to avoid multiple layout passes
        storage.beginEditing()

        // Reset to default styling
        storage.addAttributes([
            .font: editorFont,
            .foregroundColor: defaultTextColor,
        ], range: fullRange)

        // Apply variable highlighting
        let text = textView.text ?? ""
        let lines = text.components(separatedBy: "\n")
        var charOffset = 0

        for (lineIndex, line) in lines.enumerated() {
            let lineUtf16Count = line.utf16.count

            if lineIndex < results.count,
               let varName = results[lineIndex].assignmentVariable {
                if let range = line.range(of: varName) {
                    let nsRange = NSRange(range, in: line)
                    let adjustedRange = NSRange(location: charOffset + nsRange.location, length: nsRange.length)
                    if adjustedRange.location + adjustedRange.length <= storage.length {
                        storage.addAttribute(.foregroundColor, value: variableColor, range: adjustedRange)
                    }
                }
            }

            charOffset += lineUtf16Count + 1 // +1 for newline
        }

        storage.endEditing()

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
        var resultEntries: [ResultsOverlayView.Entry] = []

        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer

        let lines = textView.text.components(separatedBy: "\n")
        var charIndex = 0

        for (lineIndex, line) in lines.enumerated() {
            let lineRange = NSRange(location: charIndex, length: line.utf16.count)
            charIndex += line.utf16.count + 1

            guard lineIndex < currentResults.count else { continue }
            let result = currentResults[lineIndex]

            // Determine display text: value result or error
            let displayText: String?
            let isError: Bool
            if let value = result.value {
                displayText = value.formatted
                isError = false
            } else if let error = result.error {
                displayText = error
                isError = true
            } else {
                continue // empty line, no display
            }

            guard let text = displayText else { continue }

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

            resultEntries.append(ResultsOverlayView.Entry(lineRect: lineRect, text: text, isError: isError))
        }

        resultsOverlay.entries = resultEntries
        resultsOverlay.resultColor = resultColor
        resultsOverlay.resultsFont = resultsFont
        resultsOverlay.setNeedsDisplay()
    }
}

/// Draws result labels aligned to the right of each line, with tap-to-copy support
class ResultsOverlayView: UIView {
    struct Entry {
        let lineRect: CGRect
        let text: String
        let isError: Bool
    }

    var entries: [Entry] = []
    var resultColor: UIColor = .green
    var errorColor: UIColor = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 0.6)
    var resultsFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .medium)

    /// Callback when a result is tapped — passes the result text
    var onResultTapped: ((String) -> Void)?

    // Flash feedback state
    private var flashIndex: Int?
    private var flashTimer: Timer?

    override func draw(_ rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        for (i, entry) in entries.enumerated() {
            let isFlashing = flashIndex == i
            let baseColor = entry.isError ? errorColor : resultColor
            let color = isFlashing ? UIColor.white : baseColor
            let font = entry.isError
                ? UIFont.monospacedSystemFont(ofSize: resultsFont.pointSize - 2, weight: .regular)
                : resultsFont
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
            ]

            let resultSize = (entry.text as NSString).size(withAttributes: attrs)
            let x = bounds.width - resultSize.width - 16
            let y = entry.lineRect.origin.y + (entry.lineRect.height - resultSize.height) / 2
            let drawRect = CGRect(x: x, y: y, width: resultSize.width, height: resultSize.height)

            (entry.text as NSString).draw(in: drawRect, withAttributes: attrs)
        }
    }

    // MARK: - Tap handling

    /// Returns the draw rect for a given entry index, or nil
    private func drawRect(for index: Int) -> CGRect? {
        guard index < entries.count else { return nil }
        let entry = entries[index]
        let attrs: [NSAttributedString.Key: Any] = [.font: resultsFont]
        let resultSize = (entry.text as NSString).size(withAttributes: attrs)
        let x = bounds.width - resultSize.width - 16
        let y = entry.lineRect.origin.y + (entry.lineRect.height - resultSize.height) / 2
        return CGRect(x: x, y: y, width: resultSize.width, height: resultSize.height)
    }

    /// Find which result entry (if any) contains the given point, with generous tap target
    private func entryIndex(at point: CGPoint) -> Int? {
        let tapPadding: CGFloat = 12
        for (i, _) in entries.enumerated() {
            guard var rect = drawRect(for: i) else { continue }
            rect = rect.insetBy(dx: -tapPadding, dy: -tapPadding)
            if rect.contains(point) {
                return i
            }
        }
        return nil
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Only intercept taps on result labels; pass everything else through to text view
        if entryIndex(at: point) != nil {
            return self
        }
        return nil
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if let index = entryIndex(at: point) {
            let entry = entries[index]
            guard !entry.isError else { return } // don't copy error text
            onResultTapped?(entry.text)
            flashResult(at: index)
        }
    }

    private func flashResult(at index: Int) {
        flashTimer?.invalidate()
        flashIndex = index
        setNeedsDisplay()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            self?.flashIndex = nil
            self?.setNeedsDisplay()
        }
    }
}
