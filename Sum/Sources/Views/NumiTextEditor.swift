import SwiftUI
import UIKit

/// A UITextView wrapper that provides line-by-line text editing with results overlay
/// and syntax highlighting (variable assignments in blue, keywords, functions)
struct NumiTextEditor: UIViewRepresentable {
    @Binding var text: String
    var results: [LineResult]
    var tokenRanges: [[TokenRange]]
    var showLineNumbers: Bool
    var syntaxHighlightingEnabled: Bool
    var formattingConfig: FormattingConfig
    var resultColor: UIColor
    var textColor: UIColor
    var variableColor: UIColor
    var keywordColor: UIColor
    var functionColor: UIColor
    var commentColor: UIColor
    var backgroundColor: UIColor
    var font: UIFont

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> NumiTextEditorView {
        let view = NumiTextEditorView()
        view.textView.delegate = context.coordinator
        context.coordinator.editorView = view
        view.editorFont = font
        view.defaultTextColor = textColor
        view.variableColor = variableColor
        view.keywordColor = keywordColor
        view.functionColor = functionColor
        view.commentColor = commentColor
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
        view.formattingConfig = formattingConfig
        view.setShowLineNumbers(showLineNumbers)
        view.setText(text, results: results, tokenRanges: tokenRanges,
                     syntaxHighlightingEnabled: syntaxHighlightingEnabled)
        return view
    }

    func updateUIView(_ uiView: NumiTextEditorView, context: Context) {
        uiView.defaultTextColor = textColor
        uiView.variableColor = variableColor
        uiView.keywordColor = keywordColor
        uiView.functionColor = functionColor
        uiView.commentColor = commentColor
        uiView.textView.backgroundColor = backgroundColor
        uiView.resultColor = resultColor
        uiView.formattingConfig = formattingConfig
        uiView.setShowLineNumbers(showLineNumbers)

        // Keep suggestion engine's variable list up to date
        let variableNames = results.compactMap { $0.assignmentVariable }
        uiView.updateVariableNames(variableNames)

        // Only update text if it actually changed (avoid cursor jumping)
        let currentPlain = uiView.textView.text ?? ""
        if currentPlain != text {
            uiView.setText(text, results: results, tokenRanges: tokenRanges,
                           syntaxHighlightingEnabled: syntaxHighlightingEnabled)
        } else {
            uiView.applyHighlighting(results: results, tokenRanges: tokenRanges,
                                     syntaxHighlightingEnabled: syntaxHighlightingEnabled)
            uiView.updateResults(results)
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: NumiTextEditor
        var isUpdating = false
        weak var editorView: NumiTextEditorView?

        init(_ parent: NumiTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            parent.text = textView.text
            editorView?.updateSuggestionsForCursor()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isUpdating else { return }
            editorView?.updateSuggestionsForCursor()
        }
    }
}

/// Custom UIView that combines a UITextView with a results overlay
class NumiTextEditorView: UIView {
    let textView = UITextView()
    private let resultsOverlay = ResultsOverlayView()
    private let lineNumberView = LineNumberView()
    var resultColor: UIColor = .green
    var resultsFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .regular)
    var editorFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .regular)
    var defaultTextColor: UIColor = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
    var variableColor: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)
    var keywordColor: UIColor = UIColor(red: 0.0, green: 0.7, blue: 0.5, alpha: 1)
    var functionColor: UIColor = UIColor(red: 0.3, green: 0.8, blue: 0.8, alpha: 1)
    var commentColor: UIColor = UIColor(white: 0.35, alpha: 0.8)
    var formattingConfig: FormattingConfig = .default

    // Suggestion engine for autocomplete
    private var suggestionEngine = SuggestionEngine()
    private var operatorScrollView: UIScrollView!
    private var suggestionScrollView: UIScrollView!
    private var suggestionStack: UIStackView!

    private static let gutterWidth: CGFloat = 32
    private var isLineNumbersVisible = false
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

        // Line number gutter (hidden by default)
        lineNumberView.translatesAutoresizingMaskIntoConstraints = false
        lineNumberView.backgroundColor = .clear
        lineNumberView.isHidden = true
        addSubview(lineNumberView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),

            resultsOverlay.topAnchor.constraint(equalTo: topAnchor),
            resultsOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            resultsOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            resultsOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),

            lineNumberView.topAnchor.constraint(equalTo: topAnchor),
            lineNumberView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineNumberView.widthAnchor.constraint(equalToConstant: Self.gutterWidth),
            lineNumberView.bottomAnchor.constraint(equalTo: bottomAnchor),
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

    // MARK: - Line Numbers

    func setShowLineNumbers(_ show: Bool) {
        guard show != isLineNumbersVisible else { return }
        isLineNumbersVisible = show
        lineNumberView.isHidden = !show

        var insets = textView.textContainerInset
        insets.left = show ? Self.gutterWidth : 12
        textView.textContainerInset = insets

        // Also shift the placeholder
        placeholderLabel.constraints.forEach { c in
            if c.firstAttribute == .leading {
                c.constant = show ? Self.gutterWidth + 4 : 12
            }
        }

        updateResultsLayout()
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

        // --- Operator scroll view (default) ---
        let opScroll = UIScrollView()
        opScroll.showsHorizontalScrollIndicator = false
        opScroll.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(opScroll)
        NSLayoutConstraint.activate([
            opScroll.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 1),
            opScroll.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            opScroll.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            opScroll.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
        ])
        operatorScrollView = opScroll

        let items: [(String, String)] = [
            ("+", "+"), ("−", "-"), ("×", "*"), ("÷", "/"),
            ("^", "^"), ("(", "("), (")", ")"), ("=", " = "),
            ("%", "%"), ("$", "$"), ("in", " in "),
        ]

        let opStack = UIStackView()
        opStack.axis = .horizontal
        opStack.spacing = 2
        opStack.translatesAutoresizingMaskIntoConstraints = false
        opScroll.addSubview(opStack)
        NSLayoutConstraint.activate([
            opStack.topAnchor.constraint(equalTo: opScroll.topAnchor),
            opStack.leadingAnchor.constraint(equalTo: opScroll.leadingAnchor, constant: 4),
            opStack.trailingAnchor.constraint(equalTo: opScroll.trailingAnchor, constant: -4),
            opStack.bottomAnchor.constraint(equalTo: opScroll.bottomAnchor),
            opStack.heightAnchor.constraint(equalTo: opScroll.heightAnchor),
        ])

        let buttonColor = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
        let buttonBg = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)

        for (label, insert) in items {
            let button = makeToolbarButton(label: label, insertText: insert,
                                           color: buttonColor, bg: buttonBg,
                                           action: #selector(toolbarButtonTapped(_:)))
            opStack.addArrangedSubview(button)
        }

        // Dismiss keyboard button at the end of operator bar
        let dismissButton = UIButton(type: .system)
        dismissButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        dismissButton.tintColor = UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 1)
        dismissButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        dismissButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        opStack.addArrangedSubview(dismissButton)

        // --- Suggestion scroll view (hidden by default) ---
        let sugScroll = UIScrollView()
        sugScroll.showsHorizontalScrollIndicator = false
        sugScroll.translatesAutoresizingMaskIntoConstraints = false
        sugScroll.isHidden = true
        toolbar.addSubview(sugScroll)
        NSLayoutConstraint.activate([
            sugScroll.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 1),
            sugScroll.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            sugScroll.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            sugScroll.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
        ])
        suggestionScrollView = sugScroll

        let sugStack = UIStackView()
        sugStack.axis = .horizontal
        sugStack.spacing = 2
        sugStack.translatesAutoresizingMaskIntoConstraints = false
        sugScroll.addSubview(sugStack)
        NSLayoutConstraint.activate([
            sugStack.topAnchor.constraint(equalTo: sugScroll.topAnchor),
            sugStack.leadingAnchor.constraint(equalTo: sugScroll.leadingAnchor, constant: 4),
            sugStack.trailingAnchor.constraint(equalTo: sugScroll.trailingAnchor, constant: -4),
            sugStack.bottomAnchor.constraint(equalTo: sugScroll.bottomAnchor),
            sugStack.heightAnchor.constraint(equalTo: sugScroll.heightAnchor),
        ])
        suggestionStack = sugStack

        return toolbar
    }

    private func makeToolbarButton(label: String, insertText: String,
                                    color: UIColor, bg: UIColor,
                                    action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(label, for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(color, for: .normal)
        button.backgroundColor = bg
        button.layer.cornerRadius = 6
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            config.baseForegroundColor = color
            config.background.backgroundColor = bg
            config.background.cornerRadius = 6
            button.configuration = config
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        }
        button.accessibilityIdentifier = insertText
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func toolbarButtonTapped(_ sender: UIButton) {
        guard let insert = sender.accessibilityIdentifier else { return }
        textView.insertText(insert)
    }

    @objc private func dismissKeyboard() {
        textView.resignFirstResponder()
    }

    // MARK: - Suggestions

    /// Updates toolbar to show suggestion chips, or reverts to operator bar
    func updateSuggestions(_ suggestions: [Suggestion]) {
        if suggestions.isEmpty {
            // Show operator bar
            operatorScrollView.isHidden = false
            suggestionScrollView.isHidden = true
            return
        }

        // Show suggestion bar
        operatorScrollView.isHidden = true
        suggestionScrollView.isHidden = false

        // Rebuild chips
        suggestionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let chipColor = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
        let chipBg = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)

        for suggestion in suggestions {
            let button = makeToolbarButton(label: suggestion.text, insertText: suggestion.text,
                                            color: chipColor, bg: chipBg,
                                            action: #selector(suggestionChipTapped(_:)))
            suggestionStack.addArrangedSubview(button)
        }

        // Dismiss button at end of suggestion bar too
        let dismissButton = UIButton(type: .system)
        dismissButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        dismissButton.tintColor = UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 1)
        dismissButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        dismissButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        suggestionStack.addArrangedSubview(dismissButton)

        suggestionScrollView.contentOffset = .zero
    }

    @objc private func suggestionChipTapped(_ sender: UIButton) {
        guard let completion = sender.accessibilityIdentifier else { return }
        completeSuggestion(completion)
    }

    /// Replaces the partial word at cursor with the full suggestion + trailing space
    func completeSuggestion(_ text: String) {
        guard let wordInfo = currentWordPrefix(in: textView) else {
            textView.insertText(text + " ")
            return
        }
        // Replace the partial word range with the completion
        if let start = textView.position(from: textView.beginningOfDocument, offset: wordInfo.range.location),
           let end = textView.position(from: start, offset: wordInfo.range.length),
           let range = textView.textRange(from: start, to: end) {
            textView.replace(range, withText: text + " ")
        }
    }

    /// Extracts the partial word prefix at the current cursor position
    func currentWordPrefix(in tv: UITextView) -> (prefix: String, range: NSRange)? {
        guard let selectedRange = tv.selectedTextRange,
              selectedRange.isEmpty else { return nil }
        let cursorOffset = tv.offset(from: tv.beginningOfDocument, to: selectedRange.start)
        let text = tv.text ?? ""
        let utf16 = text.utf16
        guard cursorOffset > 0 && cursorOffset <= utf16.count else { return nil }

        // Walk backward from cursor to find start of word
        var startOffset = cursorOffset
        while startOffset > 0 {
            let idx = utf16.index(utf16.startIndex, offsetBy: startOffset - 1)
            let char = Character(UnicodeScalar(utf16[idx])!)
            if char.isLetter || char.isNumber || char == "_" {
                startOffset -= 1
            } else {
                break
            }
        }

        guard startOffset < cursorOffset else { return nil }

        let range = NSRange(location: startOffset, length: cursorOffset - startOffset)
        let nsText = text as NSString
        let word = nsText.substring(with: range)

        // Only suggest if it's at least 2 chars
        guard word.count >= 2 else { return nil }

        return (prefix: word, range: range)
    }

    /// Queries suggestion engine for the word at cursor and updates toolbar
    func updateSuggestionsForCursor() {
        guard let wordInfo = currentWordPrefix(in: textView) else {
            updateSuggestions([])
            return
        }
        let suggestions = suggestionEngine.suggest(prefix: wordInfo.prefix)
        updateSuggestions(suggestions)
    }

    /// Updates the variable names available for suggestion
    func updateVariableNames(_ names: [String]) {
        suggestionEngine.updateVariables(names)
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
    func setText(_ text: String, results: [LineResult],
                 tokenRanges: [[TokenRange]] = [], syntaxHighlightingEnabled: Bool = true) {
        let attributed = buildAttributedString(text: text, results: results,
                                               tokenRanges: tokenRanges,
                                               syntaxHighlightingEnabled: syntaxHighlightingEnabled)
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
    func applyHighlighting(results: [LineResult],
                           tokenRanges: [[TokenRange]] = [],
                           syntaxHighlightingEnabled: Bool = true) {
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

        let text = textView.text ?? ""
        let lines = text.components(separatedBy: "\n")
        var charOffset = 0

        for (lineIndex, line) in lines.enumerated() {
            let lineUtf16Count = line.utf16.count

            // Apply token-based syntax highlighting
            if syntaxHighlightingEnabled, lineIndex < tokenRanges.count {
                for tokenRange in tokenRanges[lineIndex] {
                    guard let color = colorForHighlightKind(tokenRange.kind) else { continue }
                    let adjustedRange = NSRange(location: charOffset + tokenRange.range.location,
                                                length: tokenRange.range.length)
                    if adjustedRange.location + adjustedRange.length <= storage.length {
                        storage.addAttribute(.foregroundColor, value: color, range: adjustedRange)
                    }
                }
            }

            // Variable assignment highlighting takes precedence
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

    /// Returns the color for a given token highlight kind, or nil for default text color
    private func colorForHighlightKind(_ kind: TokenHighlightKind) -> UIColor? {
        switch kind {
        case .keyword: return keywordColor
        case .function: return functionColor
        case .variable: return variableColor
        case .comment: return commentColor
        case .number, .op, .unit, .plain: return nil  // use default text color
        }
    }

    /// Builds a syntax-highlighted attributed string
    private func buildAttributedString(text: String, results: [LineResult],
                                       tokenRanges: [[TokenRange]] = [],
                                       syntaxHighlightingEnabled: Bool = true) -> NSAttributedString {
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

            // Apply token-based syntax highlighting
            if syntaxHighlightingEnabled, lineIndex < tokenRanges.count {
                for tokenRange in tokenRanges[lineIndex] {
                    guard let color = colorForHighlightKind(tokenRange.kind) else { continue }
                    let adjustedRange = NSRange(location: charOffset + tokenRange.range.location,
                                                length: tokenRange.range.length)
                    if adjustedRange.location + adjustedRange.length <= fullString.length {
                        fullString.addAttribute(.foregroundColor, value: color, range: adjustedRange)
                    }
                }
            }

            // Variable assignment highlighting takes precedence
            if lineIndex < results.count,
               let varName = results[lineIndex].assignmentVariable {
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
        let config = formattingConfig
        let maxResultWidth = currentResults.compactMap { $0.value?.formatted(with: config) }
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
        var lineInfos: [LineNumberView.LineInfo] = []

        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer

        let lines = textView.text.components(separatedBy: "\n")
        var charIndex = 0

        for (lineIndex, line) in lines.enumerated() {
            let lineRange = NSRange(location: charIndex, length: line.utf16.count)
            charIndex += line.utf16.count + 1

            // Compute line rect for both results and line numbers
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

            // Line numbers
            lineInfos.append(LineNumberView.LineInfo(rect: lineRect, number: lineIndex + 1))

            // Results
            guard lineIndex < currentResults.count else { continue }
            let result = currentResults[lineIndex]

            let displayText: String?
            let isError: Bool
            if let value = result.value {
                displayText = value.formatted(with: formattingConfig)
                isError = false
            } else if let error = result.error {
                displayText = error
                isError = true
            } else {
                continue
            }

            guard let text = displayText else { continue }
            resultEntries.append(ResultsOverlayView.Entry(lineRect: lineRect, text: text, isError: isError))
        }

        resultsOverlay.entries = resultEntries
        resultsOverlay.resultColor = resultColor
        resultsOverlay.resultsFont = resultsFont
        resultsOverlay.setNeedsDisplay()

        // Update line number gutter
        if isLineNumbersVisible {
            lineNumberView.lines = lineInfos
            lineNumberView.font = .monospacedSystemFont(ofSize: editorFont.pointSize - 4, weight: .regular)
            lineNumberView.setNeedsDisplay()
        }
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
