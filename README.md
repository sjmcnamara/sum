# Sum

A natural language calculator for iOS. Type expressions in a notepad-like editor and see results appear in real-time beside each line.

Inspired by [Numi](https://numi.app/) for macOS.

## What it does

Sum turns plain English — or Spanish, or Portuguese — into live calculations. Write `$200 split 4 ways` and get `$50`. Write `5 km in miles` and get `3.11 mi`. Switch to Spanish and type `5 más 3`, or Portuguese and type `10 quilômetros em milhas`. Every line is evaluated as you type, with results displayed alongside your input.

- **Arithmetic** in words or symbols — `8 times 9`, `2 ^ 10`, `17 mod 5`
- **Unit conversions** across 13 categories — length, weight, temperature, area, volume, time, speed, pressure, energy, data, angle, CSS, and currency
- **Live currency rates** for 30+ fiat currencies and 30+ cryptocurrencies including BTC, ETH, SOL, DOGE, and SATS
- **Percentages, tips, and tax** — `20% tip on $85`, `6% off 40 EUR`
- **Bill splitting** — `15% tip on €90 split 3 ways`
- **Variables and constants** — `price = $150` then `price * 2` on the next line
- **Functions** — `sqrt`, `log`, `sin`, `fact`, `round`, and more
- **Number formats** — hex (`0xFF`), binary (`0b1010`), octal (`0o77`), scientific (`1.5e10`)
- **Aggregation** — `sum` and `average` across lines
- **Smart suggestions** — autocomplete chips as you type
- **Syntax highlighting** — color-coded keywords, functions, variables, and comments
- **Multiple notes** — separate scratchpads with search
- **Multi-language** — English, Spanish, and Portuguese, with localized keywords, UI, and error messages
- **Onboarding** — first-launch overlay with tappable example cards, tappable placeholder lines
- **Animated results** — results fade in smoothly and pulse on value changes
- **Contextual errors** — incompatible units show `kg ≠ °C`, unknown identifiers are named
- **Theme options** — Classic Green, Amber, Ocean, and Light mode

For the full feature reference with examples, see the **[Documentation Wiki](https://github.com/sjmcnamara/sum/wiki)**.

## Requirements

- Xcode 26.2 **or** Xcode 16.1+ — builds and tests pass on both
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- iOS 16.0+ deployment target

## Setup

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Build
xcodebuild build -project Sum.xcodeproj -scheme Sum \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run tests
xcodebuild test -project Sum.xcodeproj -scheme Sum \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Or use the included build script (auto-detects simulator):

```bash
./scripts/build.sh              # generate + build
./scripts/build.sh test         # generate + build + test
./scripts/build.sh test-all     # test with both Xcode 16 and Xcode 26
./scripts/build.sh clean        # clean build artifacts

# Select Xcode version explicitly
XCODE=old ./scripts/build.sh test    # Xcode 16.1 (iOS 16-18)
XCODE=new ./scripts/build.sh test    # Xcode 26.2 (iOS 26)
```

## Project Structure

```
project.yml                           # XcodeGen project spec
scripts/build.sh                      # Build, test, clean automation
Sum/
  Sources/
    App/NumiApp.swift                 # @main entry point
    Models/
      NumiTypes.swift                 # Value types, units, tokens, operators
      FormattingConfig.swift          # Immutable formatting preferences
      AppSettings.swift               # UserDefaults-backed settings singleton
      Theme.swift                     # Shared color constants (NumiTheme)
      Language.swift                  # i18n: Language enum + parser keyword tables
      L10n.swift                      # i18n: UI string localization helper
    Parser/
      Tokenizer.swift                 # Lexer (text -> tokens + highlight ranges)
      NumiParser.swift                # Precedence-climbing expression evaluator
    Views/
      CalculatorView.swift            # Main UI (green-on-black theme)
      NumiTextEditor.swift            # UITextView wrapper with syntax highlighting
      LineNumberView.swift            # Optional line number gutter
      OnboardingOverlayView.swift     # First-launch onboarding overlay
      SettingsView.swift              # Formatting, editor, and info settings
      NotesListView.swift             # Note management sheet
      AboutView.swift                 # Version, app icon, and scrolling credits
      LicenseView.swift               # MIT license display
    ViewModels/
      CalculatorViewModel.swift       # State management + Combine bindings
    Services/
      CurrencyService.swift           # Fiat + crypto rate fetching
      NoteStorage.swift               # JSON persistence with corruption resilience
      SuggestionEngine.swift          # Autocomplete prefix matching engine
      NumiLogger.swift                # os.Logger infrastructure
  Resources/
    Assets.xcassets/                   # App icon, accent color, in-app icon image
    CHANGELOG.md                      # Bundled for About screen credits
    en.lproj/Localizable.strings      # English UI strings
    es.lproj/Localizable.strings      # Spanish UI strings
    pt.lproj/Localizable.strings      # Portuguese UI strings
SumTests/                             # 225 tests
```

## Architecture

- **SwiftUI + UIKit hybrid** — UIViewRepresentable wrapping UITextView for rich text editing with NSAttributedString syntax highlighting
- **Tokenizer/Parser** — hand-written lexer and precedence-climbing expression evaluator
- **Currency rates** — fetched in parallel from open.er-api.com (fiat) and CoinGecko (crypto), with offline fallback rates
- **Settings** — AppSettings ObservableObject with Combine, producing immutable FormattingConfig snapshots
- **Persistence** — UserDefaults with JSON-encoded notes and settings

## License

MIT
