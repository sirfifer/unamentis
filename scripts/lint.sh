#!/bin/bash
set -e
echo "🔍 Running SwiftLint..."
swiftlint lint --strict
echo "✓ Code passes linting"
