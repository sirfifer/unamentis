#!/bin/bash
set -e
echo "🏥 Running health check..."
echo ""
echo "1. SwiftLint..."
swiftlint lint --strict
echo ""
echo "2. Quick tests..."
./scripts/test-quick.sh
echo ""
echo "✅ Health check passed!"
