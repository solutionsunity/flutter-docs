# Flutter Development Documentation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![AI Agent Ready](https://img.shields.io/badge/AI%20Agent-Ready-brightgreen.svg)](https://github.com/solutionsunity/flutter-docs)

Centralized documentation and development standards for **AI-powered Flutter development**. This repository provides comprehensive coding standards, guidelines, and AI assistant configurations that can be shared across multiple Flutter projects, designed primarily for AI agents with human developer support.

## ✨ Features

- 🤖 **AI Agent Optimized** - Pre-configured for AI assistants (Augment, Cursor, etc.)
- 📚 **Comprehensive Documentation** - Complete Flutter coding standards and guidelines
- 🔗 **One-Line Setup** - Instant integration with any Flutter project
- 🔄 **Auto-Update** - Keep standards current across all projects
- 🎯 **Tiered Approach** - Guidelines for small, medium, and large projects
- 🏗️ **Architecture Patterns** - Clean Architecture, BLoC, Cubit, and more

## 🚀 Quick Setup

### Step 1: One-Line Installation (Recommended)

**Install in default directory:** (`/opt/flutter/flutter-docs`)
```bash
curl -sSL https://raw.githubusercontent.com/solutionsunity/flutter-docs/main/install.sh | bash
```

**Install in specific project directory:**
```bash
# Syntax: bash -s [project_path]
curl -sSL https://raw.githubusercontent.com/solutionsunity/flutter-docs/main/install.sh | bash -s /path/to/project
```

**What the installer does:**
- 📥 Clones/updates the flutter-docs repository to `/opt/flutter/flutter-docs` (standardized location)
- 🔗 Creates symlinks to documentation and AI configuration
- 📝 Updates `.gitignore` with proper root-relative paths

### Step 2: Link to Existing Installation

If you already have flutter-docs installed, simply create symlinks from your project:

```bash
# From your Flutter project directory
/opt/flutter/flutter-docs/link.sh
```

**What the linker does:**
- 🔗 Creates symlink to `docs/` directory
- 🔗 Creates symlink to `.augment/` directory
- 📝 Updates `.gitignore` with proper root-relative paths (`/docs`, `/.augment`)
- ✅ Validates target directory and prevents conflicts
- 🔄 Detects existing symlinks and avoids duplicates

### Manual Installation

If you prefer manual setup:

```bash
# 1. Clone the repository
git clone https://github.com/solutionsunity/flutter-docs.git /opt/flutter/flutter-docs

# 2. Navigate to your Flutter project
cd /path/to/your/flutter-project

# 3. Create symlinks and update .gitignore
/opt/flutter/flutter-docs/link.sh
```

## 📁 Repository Structure

```
flutter-docs/
├── .augment/                      # 🤖 AI Assistant Configuration
│   └── rules/                     # AI agent rules and guidelines
│       ├── README.md              # Documentation index
│       ├── core-principles.md     # Essential coding standards
│       ├── state-management-guide.md  # Tiered state management
│       ├── testing-guide.md       # Testing pyramid & best practices
│       ├── security-best-practices.md # Security guidelines
│       ├── package-reference.md   # Official packages
│       ├── clean-architecture-guide.md # Clean Architecture
│       ├── bloc-pattern-guide.md  # BLoC pattern
│       ├── cubit-pattern-guide.md # Cubit pattern
│       ├── supabase-integration-guide.md # Supabase
│       └── dartz-functional-programming-guide.md # Functional programming
├── docs/                          # 📚 Legacy documentation
│   ├── legacy/                    # Archived documentation
│   └── sync.sh                    # Synchronization script
├── install.sh                     # 🔧 One-line installer
├── link.sh                        # 🔗 Symlink creation script
└── README.md                      # This file
```

## 📚 Documentation Standards

### Core Documentation (Start Here)

| Document | Description | Purpose |
|----------|-------------|---------|
| **[Core Principles](.augment/rules/core-principles.md)** | Essential coding standards | Code quality, Dart/Flutter best practices |
| **[State Management](.augment/rules/state-management-guide.md)** | Tiered approach | setState, Provider, BLoC/Cubit |
| **[Testing Guide](.augment/rules/testing-guide.md)** | Testing pyramid | 70% unit, 20% widget, 10% integration |
| **[Security](.augment/rules/security-best-practices.md)** | Security best practices | API keys, secure storage, authentication |
| **[Package Reference](.augment/rules/package-reference.md)** | Official packages | flutter_bloc, equatable, supabase, etc. |

### Advanced & Tech-Stack Specific Guides

| Document | Description | Purpose |
|----------|-------------|---------|
| **[Clean Architecture](.augment/rules/clean-architecture-guide.md)** | Three-layer architecture | Domain, Data, Presentation layers |
| **[BLoC Pattern](.augment/rules/bloc-pattern-guide.md)** | Event-driven state management | Complex state management |
| **[Cubit Pattern](.augment/rules/cubit-pattern-guide.md)** | Simplified state management | Simpler than BLoC |
| **[Supabase Integration](.augment/rules/supabase-integration-guide.md)** | Backend integration | Auth, database, storage |
| **[Dartz FP](.augment/rules/dartz-functional-programming-guide.md)** | Functional programming | Either/Option types, error handling |

## 🤖 AI Agent Integration

This repository is **optimized for AI agents** like Augment, Cursor, GitHub Copilot, and others:

### For AI Agents
- **`.augment/rules/`** - Contains AI-specific instructions and context
- **Comprehensive docs** - All standards in easily parseable markdown
- **Auto-sync** - AI can run `./docs/sync.sh` to get latest updates
- **Tiered approach** - Guidelines scale from small to large projects

### Recommended AI Workflow
1. **Session start**: Run `./docs/sync.sh` to ensure latest updates
2. **Before coding**: Reference `./.augment/rules/README.md` for guidelines
3. **During development**: Follow standards in documentation
4. **State management**: Use decision tree in state-management-guide.md
5. **Testing**: Follow testing pyramid in testing-guide.md

## 🔄 Staying Updated

Keep your documentation and standards current:

```bash
# From any project with symlinked docs
./docs/sync.sh
```

This script automatically:
- Pulls the latest changes from this repository
- Updates all symlinked documentation across your projects
- Ensures you're always using the current standards

## 📊 Project Size Decision Matrix

| Project Size | Screens | Developers | Timeline | State Management | Architecture |
|--------------|---------|------------|----------|------------------|--------------|
| **Small** | 1-5 | 1-2 | <3 months | setState, ValueNotifier | Component-based |
| **Medium** | 5-20 | 2-5 | 3-12 months | Provider | Feature-first |
| **Large** | 20+ | 5+ | 12+ months | BLoC/Cubit | Clean Architecture |

## 🎯 Key Principles

### Code Quality
- ✅ Explicit type declarations (no `dynamic`)
- ✅ Descriptive naming with auxiliary verbs
- ✅ Functions under 30 lines
- ✅ Early returns to avoid nesting

### Performance
- ✅ `const` constructors everywhere possible
- ✅ `ListView.builder` for long lists
- ✅ Extract widgets to reduce nesting
- ✅ Avoid deeply nested widget trees

### Testing
- ✅ 70% unit tests (business logic)
- ✅ 20% widget tests (UI components)
- ✅ 10% integration tests (user flows)
- ✅ Mock dependencies for fast, reliable tests

### Security
- ✅ **CRITICAL:** Never hardcode API keys or credentials
- ✅ **CRITICAL:** Use flutter_dotenv for environment variables
- ✅ Use flutter_secure_storage for sensitive data
- ✅ Always use HTTPS
- ✅ Validate all user input

### State Management
- ✅ **CRITICAL:** Use StatelessWidget for screens with Cubit/BLoC
- ✅ Only use StatefulWidget for local UI state
- ✅ Avoid dual state management (setState + Cubit)
- ✅ Single source of truth for business logic

## ❓ FAQ

### **Q: I ran `link.sh` before initializing git. How do I get the .gitignore entries?**
**A:** Simply run `link.sh` again after `git init`. The script detects git repositories and will create the .gitignore entries automatically.

```bash
git init
/opt/flutter/flutter-docs/link.sh
```

### **Q: Can I use this in a directory that's not a git repository?**
**A:** Yes! The `link.sh` script works in any directory. It will create symlinks but skip .gitignore updates if git isn't initialized.

### **Q: How do I update to the latest documentation standards?**
**A:** Run `./docs/sync.sh` from any project with symlinked docs. This pulls the latest updates from the central repository.

### **Q: Will this interfere with my Flutter package `docs/` directories?**
**A:** No! The .gitignore uses root-relative paths (`/docs`) that only ignore the symlinked docs directory at your repository root.

### **Q: What's the difference between this and the odoo-docs repository?**
**A:** Both follow the same pattern but contain different technology-specific guidelines. This repository is for Flutter development, while odoo-docs is for Odoo development.

## 💡 Best Practices

1. **Always symlink** - Don't copy files, use symlinks to stay updated
2. **Sync regularly** - Run `./docs/sync.sh` before starting work
3. **Follow standards** - Check documentation before coding
4. **Use tiered approach** - Choose patterns based on project size
5. **Test thoroughly** - Follow the testing pyramid (70/20/10)

## 🤝 Contributing

We welcome contributions to improve these standards:

1. Fork this repository
2. Create a feature branch
3. Make your improvements
4. Submit a pull request

## 📄 License

MIT License - Feel free to use and adapt for your projects.

---

**Last Updated:** 2025-11-16
**Version:** 2.1.0
**Maintained by:** Flutter Development Team

