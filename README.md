# Sum

A natural language calculator for iOS. Type expressions in a notepad-like editor and see results appear in real-time beside each line.

Inspired by [Numi](https://numi.app/) for macOS.

## Features

- **Natural language math** - type `2 + 2`, `20% of 150`, `sin(pi/4)`
- **Unit conversions** - `100 km in miles`, `72 fahrenheit in celsius`, `5 GB in MB`
- **Currency conversion** - `$100 in EUR`, `1 BTC in USD` (live rates from exchangerate-api and CoinGecko)
- **Crypto support** - BTC, ETH, SOL, and 25+ other cryptocurrencies including SATS
- **Variables** - `price = 42` then `price * 3` on the next line
- **Aggregates** - `sum` and `avg` keywords total preceding lines
- **Multiple notes** - create, rename, and switch between calculation pages
- **Number formats** - hex (`0xFF`), binary (`0b1010`), octal (`0o77`)
- **Functions** - `sqrt`, `abs`, `log`, `ln`, `sin`, `cos`, `tan`, `round`, `ceil`, `floor`, `fact`
- **Percentage arithmetic** - `$100 + 15%`, `25% off 200`, `$50 as a % of $200`
- **Display conversions** - `255 in hex`, `10 in binary`
- **Comments** - `// line comment` or `# hash comment` (inline too: `5 + 3 // note`)
- **Constants** - `pi`, `e`, `tau`, `phi`, `speedoflight`, `avogadro`, `planck`, `boltzmann`, `gravity`, `echarge`
- **Bitwise operators** - AND (`&`), OR (`|`), XOR (`xor`), NOT (`~` / `not`), shifts (`<<`, `>>`)
- **Speed units** - `60 mph in kph`, `100 knots in mps`
- **Pressure units** - `1 atm in psi`, `100 kpa in bar`
- **Energy units** - `1000 cal in kcal`, `1 kwh in joules`
- **Formatting controls** - thousands separator toggle, decimal precision (auto/2/4/6)
- **Syntax highlighting** - keywords, functions, variables, comments colored distinctly
- **Line numbers** - optional gutter display
- **Tap to copy** - tap any result or the grand total to copy
- **Persistence** - notes, settings, and current page saved across app launches

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
    Parser/
      Tokenizer.swift                 # Lexer (text -> tokens + highlight ranges)
      NumiParser.swift                # Precedence-climbing expression evaluator
    Views/
      CalculatorView.swift            # Main UI (green-on-black theme)
      NumiTextEditor.swift            # UITextView wrapper with syntax highlighting
      LineNumberView.swift            # Optional line number gutter
      SettingsView.swift              # Formatting, editor, and info settings
      NotesListView.swift             # Note management sheet
      AboutView.swift                 # Version and app info
      LicenseView.swift               # MIT license display
    ViewModels/
      CalculatorViewModel.swift       # State management + Combine bindings
    Services/
      CurrencyService.swift           # Fiat + crypto rate fetching
      NoteStorage.swift               # UserDefaults persistence
  Resources/
    Assets.xcassets/                   # App icon and accent color
SumTests/
  SumTests.swift                      # Core parser and evaluator tests
  FormattingConfigTests.swift         # Formatting configuration tests
  TokenRangeTests.swift               # Syntax highlighting range tests
  AppSettingsTests.swift              # Settings persistence tests
  PowerFeatureTests.swift             # Comments, constants, NOT, unit tests
```

## Architecture

- **SwiftUI + UIKit hybrid** - UIViewRepresentable wrapping UITextView for rich text editing with NSAttributedString syntax highlighting
- **Tokenizer/Parser** - hand-written lexer and precedence-climbing expression evaluator
- **Currency rates** - fetched in parallel from open.er-api.com (fiat) and CoinGecko (crypto), with offline fallback rates
- **Settings** - AppSettings ObservableObject with Combine, producing immutable FormattingConfig snapshots
- **Persistence** - UserDefaults with JSON-encoded notes and settings

## License

MIT
