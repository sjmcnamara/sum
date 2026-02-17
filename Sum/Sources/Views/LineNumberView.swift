import UIKit

/// Draws faint line numbers in the left gutter of the editor
class LineNumberView: UIView {

    struct LineInfo {
        let rect: CGRect
        let number: Int
    }

    var lines: [LineInfo] = []
    var font: UIFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    var textColor: UIColor = NumiTheme.uiLineNumber

    override func draw(_ rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        for info in lines {
            let numberStr = "\(info.number)"
            let size = (numberStr as NSString).size(withAttributes: attrs)
            let y = info.rect.origin.y + (info.rect.height - size.height) / 2
            let drawRect = CGRect(x: 2, y: y, width: bounds.width - 6, height: size.height)
            (numberStr as NSString).draw(in: drawRect, withAttributes: attrs)
        }
    }
}
