#!/bin/bash

# UnaMentis Setup Verification Script
# Checks that everything is ready to run the app

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔍 UnaMentis Setup Verification"
echo "================================"
echo ""

# Function to print status
print_check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

ISSUES=0

# Check 1: Xcode
echo "Checking Xcode..."
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "Unknown")
    print_check 0 "Xcode installed: $XCODE_VERSION"
else
    print_check 1 "Xcode not found"
    print_info "Install Xcode from Mac App Store"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 2: Xcode project
echo "Checking project files..."
if [ -f "UnaMentis.xcodeproj/project.pbxproj" ]; then
    print_check 0 "Xcode project exists"
else
    print_check 1 "Xcode project not found"
    ISSUES=$((ISSUES + 1))
fi

if [ -f "Package.swift" ]; then
    print_check 0 "Package.swift exists"
else
    print_check 1 "Package.swift missing"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 3: Log server
echo "Checking log server..."
if curl -s http://localhost:8765/health > /dev/null 2>&1; then
    print_check 0 "Log server running (http://localhost:8765/)"
else
    print_check 1 "Log server not running"
    print_info "Start it: python3 scripts/log_server.py &"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 4: Python
echo "Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_check 0 "Python installed: $PYTHON_VERSION"
else
    print_check 1 "Python3 not found"
    print_info "Install: brew install python@3.12"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 5: Package dependencies
echo "Checking Swift package status..."
if [ -d ".build" ]; then
    print_check 0 "Swift packages downloaded"
else
    print_warning "Swift packages not yet downloaded"
    print_info "Xcode will download them on first build"
fi
echo ""

# Check 6: Git status
echo "Checking Git status..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current)
    print_check 0 "Git repository (branch: $BRANCH)"

    UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
    if [ "$UNCOMMITTED" -gt 0 ]; then
        print_warning "$UNCOMMITTED uncommitted changes"
    else
        print_check 0 "No uncommitted changes"
    fi
else
    print_check 1 "Not a Git repository"
fi
echo ""

# Check 7: Development tools
echo "Checking optional development tools..."
command -v swiftlint &> /dev/null && print_check 0 "SwiftLint installed" || print_warning "SwiftLint not installed (optional)"
command -v swiftformat &> /dev/null && print_check 0 "SwiftFormat installed" || print_warning "SwiftFormat not installed (optional)"
command -v xcbeautify &> /dev/null && print_check 0 "xcbeautify installed" || print_warning "xcbeautify not installed (optional)"
echo ""

# Summary
echo "================================"
if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Ready to build and run UnaMentis:"
    echo "1. Xcode is already open with the project"
    echo "2. Select an iPhone simulator from the device menu"
    echo "3. Press ⌘R to build and run"
    echo ""
    echo "Or run from command line:"
    echo "  xcodebuild -project UnaMentis.xcodeproj -scheme UnaMentis \\"
    echo "    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\"
    echo "    build"
else
    echo -e "${RED}⚠ Found $ISSUES issue(s)${NC}"
    echo ""
    echo "Please fix the issues above before running the app."
fi

echo ""
echo "Quick references:"
echo "  • Log server:   http://localhost:8765/"
echo "  • Quick start:  cat QUICKSTART.md"
echo "  • Next steps:   cat QUICKSTART_STEPS.md"
echo ""
