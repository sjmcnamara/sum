# Roadmap

## Completed

### v1.0.0 — Initial Release
- Natural language calculator for iOS

### v1.1.0 — Polish & Usability
- Settings, about, license views
- Tap-to-copy results, haptic feedback, error indicators
- Keyboard toolbar, empty state placeholder

### v1.2.0 — Formatting & Display
- Thousands separator toggle, decimal precision control
- Line numbers, syntax highlighting
- Settings panel reorganized, case-insensitive currency codes

### v1.3.0 — Power Features
- Comments (`//` and `#`), bitwise NOT (`~`, `not`)
- Constants library (speedoflight, avogadro, planck, boltzmann, echarge, gravity, phi, tau)
- Speed units (mph, kph, mps, knots, fps)
- Pressure units (pascal, bar, atm, psi, mmHg, torr)
- Energy units (joule, kilojoule, calorie, kilocalorie, watt-hour, kilowatt-hour, BTU, electronvolt)
- Word operators (mod, xor, not) highlighted as keywords

### v1.4.0 — NL Queries & Smart Suggestions
- Natural language queries: split bills, tip/tax, compound expressions
- Smart suggestions: autocomplete toolbar chips for functions, keywords, units, currencies, variables
- Compound speed unit syntax: `km/h`, `m/s`, `miles/h`, `ft/s`
- Fix: `speedoflight` now carries m/s unit for proper conversions

### v1.4.1 — Refactoring, Performance & Crash Resilience
- Fix UTF-16 crash, NoteStorage corruption resilience
- Debounce recalculate, O(1) unit lookup
- os.Logger infrastructure, unified tokenizer, NumiTheme color constants
- 14 new edge case tests (186 total)

### v1.4.2 — UI Tweaks & Polish
- Settings font hierarchy: larger headings, smaller items
- Default currency selector (14 common currencies)
- About view: 3D app icon, retro scrolling credits from CHANGELOG
- New 3D metallic sigma app icon

### v1.5.0 — Internationalization (i18n)
- Language picker in Settings (English / Español)
- All UI labels localized via .strings resource files
- Parser accepts localized keywords (más, menos, por, dividido entre)
- Localized unit names, duration output, error messages, autocomplete suggestions
- English keywords always work regardless of language setting
- 19 new tests (205 total)

### v1.5.1 — Portuguese Language Support
- Language picker adds Português (3 languages total)
- Portuguese parser keywords, unit names, currency names (real/reais → BRL)
- Full Portuguese UI strings (Configurações, Formatação, Casas Decimais, etc.)
- 14 new tests (219 total)

### v1.6.0 — Polish & Delight
- Onboarding overlay with tappable example cards on first launch
- Tappable placeholder lines that insert expressions into the editor
- Result appearance animations: fade-in, pulse on change, fade-out
- Better error messages with context (incompatible units show `kg ≠ °C`, unknown identifiers named)
- Onboarding localized in all 3 languages
- 219 tests (unchanged)

### v1.7.0 — Theme Options
- 4 color themes: Classic Green (default), Amber, Ocean, Light
- Theme picker in Settings with instant live preview
- Light mode for daytime use; dark terminal themes (Amber, Ocean) for variety
- All UIKit elements update dynamically (toolbar, placeholder, toast)
- 6 new tests (225 total)

---

## Upcoming

### v1.8 — Sharing & Export
- Share sheet — export a note as plain text or formatted image
- Copy all results — one-tap copy of the full note with results
- Import/export notes — share `.sum` files between devices
- iCloud sync — notes available across iPhone and iPad
- Widget — home screen widget showing a pinned calculation or live currency rate

### v2.0 — Intelligence
- Custom functions — `f(x) = x^2 + 3x`
- Conditional expressions — `if price > 100 then "expensive" else "cheap"`
- Frequently used conversions — learn from usage patterns
- Spotlight integration — type expressions in iOS search
- Siri Shortcuts — "Hey Siri, what's 100 USD in EUR"
