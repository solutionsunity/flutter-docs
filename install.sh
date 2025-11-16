#!/bin/bash
# Flutter Documentation Installer
# One-line setup for AI-powered Flutter development

set -e

# Standard installation path (centralized for all projects)
DOCS_PATH="/opt/flutter/flutter-docs"
PROJECT_PATH="${1:-$(pwd)}"

echo "🤖 Installing Flutter Development Documentation for AI Agents..."
echo "📁 Project: $PROJECT_PATH"
echo "📚 Docs: $DOCS_PATH"

# Clone or update documentation repository
if [ ! -d "$DOCS_PATH" ]; then
    echo "📥 Cloning flutter-docs repository..."
    git clone https://github.com/solutionsunity/flutter-docs.git "$DOCS_PATH"
else
    echo "🔄 Updating existing flutter-docs repository..."
    cd "$DOCS_PATH" && git pull origin main
fi

# Navigate to project directory
cd "$PROJECT_PATH"

# Run the link script to create symlinks
echo "🔗 Creating symlinks to documentation..."
"$DOCS_PATH/link.sh"

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 Created symlinks:"
echo "   ./.augment/                - Augment AI configuration and rules"
echo "   ./docs/                    - Flutter development documentation"
echo ""
echo "📚 Available documentation:"
echo "   ./docs/                    - Legacy documentation"
echo "   ./.augment/rules/          - AI agent rules and guidelines"
echo "   ./.augment/rules/README.md - Documentation index"
echo ""
echo "🔄 To update documentation later:"
echo "   Run: ./docs/sync.sh (or cd $DOCS_PATH && git pull)"
echo ""
echo "Happy AI-powered Flutter development! 🚀"

