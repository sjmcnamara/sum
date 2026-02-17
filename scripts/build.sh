#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="Sum.xcodeproj"
SCHEME="Sum"

# ---------------------------------------------------------------------------
# Xcode version handling
# ---------------------------------------------------------------------------
# XCODE env var selects the toolchain:
#   XCODE=old  → Xcode 16.1  (iOS 16-18 SDK)
#   XCODE=new  → Xcode 26.2  (iOS 26 SDK)     ← default
#   (unset)    → whichever is active via xcode-select

XCODE_OLD="/Applications/Xcode.app/Contents/Developer"
XCODE_NEW="/Applications/Xcode-26.2.0.app/Contents/Developer"

resolve_xcode() {
    case "${XCODE:-}" in
        old)
            if [ -d "$XCODE_OLD" ]; then
                export DEVELOPER_DIR="$XCODE_OLD"
            else
                echo "Error: Xcode 16.1 not found at $XCODE_OLD"
                exit 1
            fi
            ;;
        new)
            if [ -d "$XCODE_NEW" ]; then
                export DEVELOPER_DIR="$XCODE_NEW"
            else
                echo "Error: Xcode 26.2 not found at $XCODE_NEW"
                exit 1
            fi
            ;;
        "")
            # Use whatever xcode-select points to
            ;;
        *)
            # Treat as a path to a Developer directory
            if [ -d "$XCODE" ]; then
                export DEVELOPER_DIR="$XCODE"
            else
                echo "Error: XCODE path not found: $XCODE"
                exit 1
            fi
            ;;
    esac
}

print_xcode_info() {
    local ver
    ver=$(xcodebuild -version 2>/dev/null | head -1 || true)
    local sdk
    sdk=$(xcrun --show-sdk-version 2>/dev/null || echo "unknown")
    echo "    Xcode: $ver  (SDK $sdk)"
}

# ---------------------------------------------------------------------------
# Simulator auto-detection
# ---------------------------------------------------------------------------
# Preference order varies by Xcode version.
# Xcode 26:  iPhone 17 Pro > iPhone 16 Pro > iPhone 16
# Xcode 16:  iPhone 16 Pro > iPhone 15 Pro > iPhone 16

detect_destination() {
    local dest
    local sdk_ver
    sdk_ver=$(xcrun --show-sdk-version 2>/dev/null || echo "0")

    # Determine search order based on SDK major version
    local pattern
    if [ "${sdk_ver%%.*}" -ge 26 ] 2>/dev/null; then
        pattern="iPhone (17 Pro|16 Pro|16 ) "
    else
        pattern="iPhone (16 Pro|15 Pro|16 |15 ) "
    fi

    dest=$(xcrun simctl list devices available 2>/dev/null \
        | grep -E "$pattern" \
        | head -1 \
        | sed 's/.*(\([A-F0-9-]*\)).*/\1/') || true

    if [ -n "$dest" ] && [ ${#dest} -eq 36 ]; then
        echo "platform=iOS Simulator,id=$dest"
    else
        # Fallback: pick the first available iPhone simulator
        dest=$(xcrun simctl list devices available 2>/dev/null \
            | grep -E "iPhone" \
            | head -1 \
            | sed 's/.*(\([A-F0-9-]*\)).*/\1/') || true
        if [ -n "$dest" ] && [ ${#dest} -eq 36 ]; then
            echo "platform=iOS Simulator,id=$dest"
        else
            echo "platform=iOS Simulator,name=iPhone 16 Pro"
        fi
    fi
}

resolve_xcode

DESTINATION="${DESTINATION:-$(detect_destination)}"

cd "$PROJECT_DIR"

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

generate() {
    echo "==> Generating Xcode project..."
    if ! command -v xcodegen &>/dev/null; then
        echo "Error: xcodegen not found. Install with: brew install xcodegen"
        exit 1
    fi
    xcodegen generate
    echo "    Created $PROJECT"
}

build() {
    echo "==> Building $SCHEME..."
    print_xcode_info
    echo "    Destination: $DESTINATION"
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -quiet
    echo "    Build succeeded."
}

test_suite() {
    echo "==> Running tests..."
    local result_bundle="/tmp/Sum_test_$$_$(date +%s).xcresult"
    rm -rf "$result_bundle"
    local output
    output=$(xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -resultBundlePath "$result_bundle" \
        2>&1) || {
        echo "$output" | grep -E "(error:|failed|FAIL)" | while IFS= read -r line; do
            echo "    $line"
        done || true
        echo "    Tests FAILED."
        rm -rf "$result_bundle"
        exit 1
    }
    # Show summary
    echo "$output" | grep -E "Executed [0-9]+ tests" | tail -1 | while IFS= read -r line; do
        echo "    $line"
    done || true
    echo "    Tests passed."
    rm -rf "$result_bundle"
}

clean() {
    echo "==> Cleaning build artifacts..."
    xcodebuild clean \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -quiet 2>/dev/null || true

    rm -rf "$PROJECT_DIR/Sum.xcodeproj"
    echo "    Cleaned."
}

# Run generate+build+test against both Xcode versions
test_all() {
    local failed=0

    for xc in old new; do
        echo ""
        echo "========================================"
        echo "  Testing with XCODE=$xc"
        echo "========================================"
        # Unset DEVELOPER_DIR so each subprocess resolves its own
        DEVELOPER_DIR="" XCODE="$xc" "$0" test || {
            echo "    *** XCODE=$xc FAILED ***"
            failed=1
        }
    done

    echo ""
    if [ "$failed" -eq 0 ]; then
        echo "==> All builds passed."
    else
        echo "==> Some builds FAILED."
        exit 1
    fi
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [command]

Commands:
  (none)      Generate project and build (default)
  test        Generate project and run tests
  test-all    Run tests against both Xcode 16 and Xcode 26
  clean       Remove build artifacts and generated project
  generate    Generate Xcode project only
  help        Show this help

Environment:
  XCODE         Select Xcode version:
                  old   → Xcode 16.1  (iOS 16-18)
                  new   → Xcode 26.2  (iOS 26)     [default]
                  /path → custom Developer directory
  DESTINATION   Override simulator destination
                (default: auto-detected per Xcode version)

Examples:
  ./scripts/build.sh                    # build with current Xcode
  ./scripts/build.sh test               # test with current Xcode
  XCODE=old ./scripts/build.sh test     # test with Xcode 16.1
  XCODE=new ./scripts/build.sh test     # test with Xcode 26.2
  ./scripts/build.sh test-all           # test both Xcode versions
  DESTINATION="platform=iOS Simulator,name=iPhone 16e" ./scripts/build.sh test
EOF
}

case "${1:-build}" in
    build)
        generate
        build
        ;;
    test)
        generate
        build
        test_suite
        ;;
    test-all)
        test_all
        ;;
    clean)
        clean
        ;;
    generate)
        generate
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
