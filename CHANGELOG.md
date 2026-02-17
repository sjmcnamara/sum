# Changelog

## [Sum 1.2.0](https://github.com/sjmcnamara/sum/releases/tag/v1.2.0) (2026-02-17)

- Formatting & display enhancements
  - Thousands separator toggle (Settings → Formatting)
  - Decimal precision control: Auto, 2, 4, or 6 decimal places
  - Optional line numbers in the editor gutter
  - Syntax highlighting for keywords (teal-green) and functions (cyan)
  - All formatting settings persist via UserDefaults
  - Settings panel reorganized into Formatting, Editor, and Info sections
  - Results overlay and grand total use user-configured formatting
  - New types: `FormattingConfig`, `AppSettings`, `TokenRange`, `LineNumberView`
  - Fix: currency codes now case-insensitive (`usd`, `eur`, `btc` all work)
  - Fix: "Decimal Places" label no longer wraps in Settings
  - 26 new tests (119 total, passing on both Xcode 16.1 and 26.2)

## [Sum 1.1.0](https://github.com/sjmcnamara/sum/releases/tag/v1.1.0) (2026-02-17)

- Polish & Usability 
 - Add settings menu, about page, and license view 
 - Tap any result to copy to clipboard (white flash + toast + haptic)
 - Grand total bar also tappable to copy
 - Shake to undo preserved via textStorage highlighting
 - Subtle haptic feedback when result values change
 - Empty state placeholder with example expressions
 - Error indicators: parser surfaces errors (÷ by 0, bad units) in dim red
 - Keyboard toolbar with quick-access operators (+ − × ÷ ^ ( ) = % $ in)
 - Search notes by title and content, with content preview
 - Added 20 new tests (93 total, passing on both Xcode 16.1 and 26.2)

## [Sum 1.0.0](https://github.com/sjmcnamara/sum/releases/tag/v1.0.0) (2026-02-17)

- Initial release — natural language calculator for iOS
