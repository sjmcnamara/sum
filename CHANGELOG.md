# Changelog

## [Sum 1.5.0](https://github.com/sjmcnamara/sum/releases/tag/v1.5.0) (2026-02-18)

- Internationalization (i18n)
  - Language picker in Settings (English / Español)
  - All UI labels, buttons, and section headers localized via .strings resource files
  - Parser accepts localized keywords: `más`, `menos`, `por`, `dividido entre`
  - Localized unit names: `kilómetros`, `libras`, `pulgadas`, `litros`, etc.
  - Localized keywords: `propina`, `impuesto`, `dividir`, `personas`, `hoy`, `ahora`
  - Duration output in selected language (`días`, `horas`, `minutos`, `segundos`)
  - Localized error messages (`÷ por 0`, `inválido`, `unidades incompatibles`)
  - English keywords always work regardless of language setting
  - Autocomplete suggestions include localized keywords and unit names
- Infrastructure
  - `Language` enum with `ParserKeywords` merged lookup tables
  - `L10n` helper reads from user-chosen language bundle (independent from iOS locale)
  - `DurationWords` added to `FormattingConfig` for localized time formatting
  - `en.lproj` and `es.lproj` Localizable.strings (29 entries each)
- 19 new tests (205 total)

## [Sum 1.4.2](https://github.com/sjmcnamara/sum/releases/tag/v1.4.2) (2026-02-17)

- UI tweaks & polish
  - Settings: section headings now larger, individual setting labels smaller
  - New default currency selector in Settings (14 common currencies)
  - About view: app icon replaces sigma text, retro scrolling credits from CHANGELOG
  - App icon: new 3D metallic sigma design
- Infrastructure
  - `defaultCurrency` setting persisted via UserDefaults
  - `AppIconImage` asset for in-app icon display
  - CHANGELOG.md bundled as app resource for dynamic credits

## [Sum 1.4.1](https://github.com/sjmcnamara/sum/releases/tag/v1.4.1) (2026-02-17)

- Crash fixes
  - Fix UTF-16 force unwrap crash in word prefix extraction (emoji/surrogate pairs)
  - NoteStorage: corrupted JSON now returns default note instead of crash, backs up bad data
  - Factorial: defense in depth guard on negative input
- Performance
  - Debounce recalculate (50ms) to prevent redundant parsing during fast typing
  - Unit lookup: O(1) dictionary for single-word units (was O(120) linear scan)
- Logging
  - Added `os.Logger` infrastructure (parser, storage, currency categories)
  - Parser error logging, NoteStorage corruption logging, CurrencyService fetch logging
  - CurrencyService tracks fallback state for future UI indication
- Refactoring
  - Unified tokenizer: `tokenize()` and `tokenizeWithRanges()` share single `tokenizeInternal()` (~280 lines removed)
  - Extracted `NumiTheme` enum with shared color constants (eliminates ~20 duplicated declarations across 7 views)
  - Thread-safe currency rates via `setCurrencyRates(_:)` setter
  - Testable `wordPrefix(in:cursorUTF16Offset:)` static helper
- 14 new tests (186 total)
  - Factorial edge cases (zero, negative, too large, non-integer)
  - Modulo by zero, corrupted notes recovery, tokenizer consistency
  - Compound unit highlight range, word prefix with emoji

## [Sum 1.4.0](https://github.com/sjmcnamara/sum/releases/tag/v1.4.0) (2026-02-17)

- Natural language queries
  - Split bills: `€200 split 4 ways`, `split £120 between 4 people`, `$90 split among 3`
  - Tip/tax: `20% tip on $85`, `8% tax on £50` (tip/tax as noise words after %)
  - Compound: `15% tip on €90 split 3 ways` → €34.50
  - Noise stripping: `whats 20% tip on $85`, `what is €200 split 4 ways`
- Smart suggestions (autocomplete)
  - Toolbar chips appear as you type partial words (2+ chars)
  - Sources: functions, keywords, units, currencies, user-defined variables
  - Tap a chip to complete the word; operator toolbar returns when not typing
  - Case-insensitive prefix matching, sorted by category priority
- Bug fixes
  - `speedoflight` now carries m/s unit so conversions work (`speedoflight in km/h`)
  - Compound speed unit syntax: `km/h`, `m/s`, `miles/h`, `ft/s` now tokenized correctly
- 28 new tests (172 total, passing on both Xcode 16.1 and 26.2)

## [Sum 1.3.0](https://github.com/sjmcnamara/sum/releases/tag/v1.3.0) (2026-02-17)

- Power features
  - Comments: `// comment` and `# comment` (full-line and inline)
  - Bitwise NOT operator: `~0xFF` or `not 255`
  - Word operators (`mod`, `xor`, `not`) now highlighted as keywords
  - Constants library: `speedoflight`, `avogadro`, `planck`, `boltzmann`, `echarge`, `gravity`, `phi`, `tau` (with aliases `lightspeed`, `na`, `golden`)
  - Speed units: mph, kph, mps, knots, fps (with full names)
  - Pressure units: pascal, kilopascal, bar, atmosphere, psi, mmHg, torr
  - Energy units: joule, kilojoule, calorie, kilocalorie, watt-hour, kilowatt-hour, BTU, electronvolt
  - 25 new tests (144 total, passing on both Xcode 16.1 and 26.2)

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

- Initial release
 - A beautiful natural language calculator for iOS
