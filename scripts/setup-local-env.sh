#!/bin/bash

set -e

echo "🧪 VoiceLearn - Local Test Environment Setup"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check Homebrew
print_step "Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    print_success "Homebrew installed"
fi

# Install tools
print_step "Installing development tools..."
brew install swiftlint swiftformat xcbeautify

# Check Xcode
print_step "Checking Xcode installation..."
if ! command -v xcodebuild &> /dev/null; then
    print_warning "Xcode not found. Please install from App Store."
else
    xcodebuild -version
    print_success "Xcode installed"
fi

# Create iOS Simulators
print_step "Setting up iOS Simulators..."
xcrun simctl list devices

# Set up environment file
if [ ! -f .env ]; then
    print_step "Creating .env file..."
    cp .env.example .env
    print_success "Created .env - Please add your API keys"
else
    print_warning ".env already exists"
fi

# Install git hooks
print_step "Installing git hooks..."
cat > .git/hooks/pre-commit << 'HOOK_EOF'
#!/bin/bash
./scripts/health-check.sh
HOOK_EOF
chmod +x .git/hooks/pre-commit
print_success "Git hooks installed"

echo ""
echo "✅ Local environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env and add your API keys:"
echo "   code .env"
echo ""
echo "2. Generate test audio fixtures (optional):"
echo "   ./Tests/Fixtures/generate-test-audio.sh"
echo ""
echo "3. Run tests to verify setup:"
echo "   ./scripts/test-quick.sh"
echo ""
echo "4. Before committing, run:"
echo "   ./scripts/health-check.sh"
echo ""
