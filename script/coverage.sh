#!/bin/bash

# Run tests with coverage
flutter test --no-test-assets --coverage

# Install lcov if not already installed (macOS)
if ! command -v lcov &> /dev/null; then
    echo "Installing lcov..."
    brew install lcov
fi

# Process coverage file to exclude generated files
lcov \
  --remove coverage/lcov.info \
  'lib/**.g.dart' \
  'lib/**.pigeon.dart' \
  'test/**' \
  --ignore-errors unused,unused \
  -o coverage/lcov.cleaned.info >/dev/null 2>&1

# Generate HTML report
genhtml coverage/lcov.cleaned.info -o coverage/html

# Open the HTML report (macOS)
open coverage/html/index.html

# Extract coverage percentage
COVERAGE_PERCENT=$(lcov --summary coverage/lcov.cleaned.info | grep "lines.......:" | grep -o '[0-9]\+\.[0-9]\+%' | tr -d '%')

# Add empty line for better readability
echo

# Check if coverage meets threshold (90%)
THRESHOLD=90
if (( $(echo "$COVERAGE_PERCENT >= $THRESHOLD" | bc -l) )); then
    # Green checkmark and text
    echo -e "\033[32m✅ Coverage is ${COVERAGE_PERCENT}% (meets ${THRESHOLD}% threshold)\033[0m"
else
    # Red X and text
    echo -e "\033[31m❌ Coverage is ${COVERAGE_PERCENT}% (below ${THRESHOLD}% threshold)\033[0m"
    exit 1
fi

# # After running lcov --remove to create lcov.cleaned.info
# COVERAGE_PERCENT=$(lcov --summary coverage/lcov.cleaned.info | grep "lines.......:" | grep -o '[0-9]\+\.[0-9]\+%' | tr -d '%')
# echo "Current coverage: ${COVERAGE_PERCENT}%"

# # Test with 50% threshold first
# if (( $(echo "$COVERAGE_PERCENT < 50" | bc -l) )); then
#     echo "Coverage is below 50%. Current: ${COVERAGE_PERCENT}%"
#     exit 1
# else
#     echo "Coverage is above 50%. Current: ${COVERAGE_PERCENT}%"
# fi
