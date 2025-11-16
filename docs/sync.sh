#!/bin/bash
# Flutter Documentation Sync Script
# Updates the centralized flutter-docs repository to get latest standards

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find the flutter-docs directory
DOCS_DIR="/opt/flutter/flutter-docs"

echo -e "${BLUE}Flutter Documentation Sync${NC}"
echo -e "${BLUE}===========================${NC}"
echo ""

# Check if docs directory exists
if [[ ! -d "$DOCS_DIR" ]]; then
    echo -e "${YELLOW}⚠️  Flutter docs not found at $DOCS_DIR${NC}"
    echo -e "   Run the installer first:"
    echo -e "   curl -sSL https://raw.githubusercontent.com/solutionsunity/flutter-docs/main/install.sh | bash"
    exit 1
fi

# Navigate to docs directory
cd "$DOCS_DIR"

# Check if it's a git repository
if [[ ! -d ".git" ]]; then
    echo -e "${YELLOW}⚠️  $DOCS_DIR is not a git repository${NC}"
    exit 1
fi

# Pull latest changes
echo -e "📥 Pulling latest documentation updates..."
git pull origin main

echo ""
echo -e "${GREEN}✓ Documentation updated successfully!${NC}"
echo ""
echo -e "${BLUE}Latest standards are now available in:${NC}"
echo -e "  📁 ./.augment/rules/ - AI agent guidelines"
echo -e "  📁 ./docs/ - Legacy documentation"
echo ""
echo -e "${BLUE}All symlinked projects will automatically use the updated documentation.${NC}"

