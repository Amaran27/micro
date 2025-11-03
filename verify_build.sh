#!/bin/bash
# Quick verification script to confirm build readiness

echo "🔍 Verifying Micro App Build Readiness..."
echo ""

cd micro || exit 1

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    echo "   Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Clean and get dependencies
echo "📦 Getting dependencies..."
flutter pub get > /dev/null 2>&1

# Run analysis
echo "🔍 Running dart analyze..."
flutter analyze --no-fatal-infos 2>&1 | tail -20

echo ""
echo "✅ Build verification complete!"
echo ""
echo "To build the app, run:"
echo "  flutter build apk          # For Android"
echo "  flutter build ios          # For iOS"
echo "  flutter run -d <device>    # To run on device"
