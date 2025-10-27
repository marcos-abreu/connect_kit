#!/usr/bin/env bash
# ================================================================
# Script: generate_code.sh
# Purpose: Regenerate boilerplate code for Dart, Kotlin and Swift
#          used in the ConnectKit plugi
# Usage: bash ./scripts/generate_code.sh
# ================================================================

set -e  # Exit on first error
set -u  # Treat unset vars as errors

# Ensure Flutter dependencies are available
flutter pub get

echo ""
echo "🔧 Starting code generation..."

# echo "build_runner code generation..."
# dart run build_runner build --delete-conflicting-outputs
# if [ $? -eq 0 ]; then
#     echo "✅ build_runner code generation completed successfully."
# else
#     echo "❌ build_runner code generation failed."
#     exit 1
# fi

echo "Pigeon code generation..."
dart run pigeon --input pigeon/messages.dart
if [ $? -eq 0 ]; then
    echo "✅ Pigeon code generation completed successfully."
else
    echo "❌ Pigeon code generation failed."
    exit 1
fi

echo "🎉 Code generation completed successfully."

echo ""

dart run tool/generate_ck_type.dart
if [ $? -eq 0 ]; then
    echo "✅ CKTypes code generation completed successfully."
else
    echo "❌ CKTypes code generation failed."
    exit 1
fi
