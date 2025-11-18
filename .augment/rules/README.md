---
type: "manual"
---

# Flutter Development Documentation

> **Comprehensive, tiered Flutter development guidelines for projects of all sizes**

---

## 📚 Documentation Index

### Core Documentation (Start Here)

#### 1. [Core Principles](core-principles.md) 🎯
Essential coding standards: code quality, Dart/Flutter best practices, performance, error handling, UI conventions, JSON serialization.

#### 2. [State Management Guide](state-management-guide.md) 🔄
Tiered approach with decision trees: setState (small), Provider (medium), BLoC/Cubit (large). Includes migration strategies.

#### 3. [Testing Guide](testing-guide.md) 🧪
Testing pyramid (70% unit, 20% widget, 10% integration) with AAA pattern, mocking, and best practices.

#### 4. [Security Best Practices](security-best-practices.md) 🔒
API key management, secure storage, authentication, network security, input validation, code protection.

#### 5. [Official Package Reference](package-reference.md) 📦
flutter_bloc, equatable, shimmer, animations, flutter_animate, cached_network_image, supabase_flutter, mocktail, bloc_test, flutter_lints.

---

### Advanced & Tech-Stack Specific Guides

#### 6. [Supabase Integration Guide](supabase-integration-guide.md) 🗄️
Environment setup, authentication, database operations, storage, real-time subscriptions, RLS policies.

#### 7. [Clean Architecture Guide](clean-architecture-guide.md) 🏗️
Three-layer architecture: Domain, Data, Presentation layers with BLoC/Cubit, GetIt DI, feature-first organization.

#### 8. [Dartz Functional Programming Guide](dartz-functional-programming-guide.md) �
Either/Option types, failure hierarchy, functional composition, integration with repositories and use cases.

#### 9. [BLoC Pattern Guide](bloc-pattern-guide.md) 🔄
Event-driven state management: events, states, transformers, UI integration, testing with bloc_test.

#### 10. [Cubit Pattern Guide](cubit-pattern-guide.md) ⚡
Simplified state management: Cubit vs BLoC, emit() usage, UI integration, testing, migration strategies.

---

## �🗂️ Documentation Structure

```
docs/
├── README.md (this file)
│
├── Core Documentation (General Flutter Best Practices)
│   ├── core-principles.md
│   ├── state-management-guide.md
│   ├── testing-guide.md
│   ├── security-best-practices.md
│   └── package-reference.md
│
├── Advanced & Tech-Stack Guides (Specific Technologies)
│   ├── supabase-integration-guide.md
│   ├── clean-architecture-guide.md
│   ├── dartz-functional-programming-guide.md
│   ├── bloc-pattern-guide.md
│   └── cubit-pattern-guide.md
│
└── legacy/
    ├── README.md
    ├── doc1-riverpod-supabase.md
    ├── doc2-clean-code.md
    ├── doc3-bloc-firebase.md
    └── doc4-clean-architecture.md
```

---

## 🚀 Quick Start Guide

### For New Projects

**Step 1: Core Foundation**
1. **Read [Core Principles](core-principles.md)** - Understand fundamental best practices
2. **Review [Official Packages](package-reference.md)** - Use our standard package stack
3. **Choose State Management** - Use [State Management Guide](state-management-guide.md) decision tree
4. **Set Up Testing** - Follow [Testing Guide](testing-guide.md) pyramid approach
5. **Implement Security** - Apply [Security Best Practices](security-best-practices.md) from day one

**Step 2: Choose Your Tech Stack (Optional)**
- Using **Supabase**? → Read [Supabase Integration Guide](supabase-integration-guide.md)
- Building **large app**? → Read [Clean Architecture Guide](clean-architecture-guide.md)
- Using **functional patterns**? → Read [Dartz Guide](dartz-functional-programming-guide.md)
- Need **complex state management**? → Read [BLoC Guide](bloc-pattern-guide.md) or [Cubit Guide](cubit-pattern-guide.md)

### For Existing Projects

**Step 1: Audit & Improve**
1. **Audit Current Code** - Compare against [Core Principles](core-principles.md)
2. **Evaluate State Management** - Check if current approach matches project size
3. **Improve Test Coverage** - Use [Testing Guide](testing-guide.md) to reach targets
4. **Security Review** - Verify compliance with [Security Best Practices](security-best-practices.md)

**Step 2: Adopt Advanced Patterns (If Needed)**
- Migrating to **Supabase**? → Follow [Supabase Integration Guide](supabase-integration-guide.md)
- Scaling up? → Consider [Clean Architecture Guide](clean-architecture-guide.md)
- Improving error handling? → Adopt [Dartz patterns](dartz-functional-programming-guide.md)
- Refactoring state management? → Choose [BLoC](bloc-pattern-guide.md) or [Cubit](cubit-pattern-guide.md)

---

## 📊 Project Size Decision Matrix

| Project Size | Screens | Developers | Timeline | Recommended State Management | Architecture |
|--------------|---------|------------|----------|------------------------------|--------------|
| **Small** | 1-5 | 1-2 | <3 months | setState, ValueNotifier, Cubit | Component-based |
| **Medium** | 5-20 | 2-5 | 3-12 months | Provider, Cubit | Feature-first |
| **Large** | 20+ | 5+ | 12+ months | BLoC, Cubit | Clean Architecture |

### 🎨 State Management Flexibility

**Important:** The state management recommendations above are **guidelines, not requirements**. Choose based on:

✅ **Developer Preference** - Use what you and your team are comfortable with
✅ **Team Familiarity** - Leverage existing expertise rather than forcing a pattern
✅ **Project Consistency** - Using the same pattern across all projects can improve productivity
✅ **Complexity Needs** - Match the solution to your actual state complexity, not just project size

**Valid Scenarios:**
- 🟢 Using **Cubit in a small project** for consistency across your portfolio
- 🟢 Using **Provider in a large project** if your team has deep Provider expertise
- 🟢 **Mixing approaches** (e.g., Provider for simple state, Cubit for complex features)
- 🟢 Using **BLoC from day one** if you know the project will scale significantly

**The key principle:** Choose a state management solution that your team can implement correctly and maintain effectively, regardless of project size.

---

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
- ✅ **CRITICAL:** Never hardcode API keys or Supabase credentials
- ✅ **CRITICAL:** Use flutter_dotenv for environment variables (.env file)
- ✅ Use flutter_secure_storage for sensitive data
- ✅ Always use HTTPS
- ✅ Validate all user input
- ✅ Add .env to .gitignore to prevent committing secrets

### State Management
- ✅ **CRITICAL:** Use StatelessWidget for screens with Cubit/BLoC
- ✅ Only use StatefulWidget for local UI state (controllers, animations)
- ✅ Avoid dual state management (setState + Cubit)
- ✅ Single source of truth for business logic

### Widget Organization
- ✅ **CRITICAL:** Each widget must be in its own separate file
- ✅ **CRITICAL:** Screen/view files should not exceed 120-150 lines
- ✅ Extract any widget logic beyond this limit into separate widget files
- ✅ Use feature-first folder structure: group related widgets together
- ✅ Name widget files using snake_case matching the widget class name (e.g., `user_profile_card.dart` for `UserProfileCard`)

**Why it matters:**
- ✅ Improves code reusability and testability
- ✅ Makes code easier to navigate and maintain
- ✅ Enforces separation of concerns
- ✅ Reduces merge conflicts in team environments
- ✅ Keeps files focused and manageable

---

## 📖 Legacy Documentation

The `legacy/` folder contains the original four documentation files that were archived on 2025-11-14:
- **[doc1-riverpod-supabase.md](legacy/doc1-riverpod-supabase.md)** - Riverpod + Supabase approach
- **[doc2-clean-code.md](legacy/doc2-clean-code.md)** - Clean code principles
- **[doc3-bloc-firebase.md](legacy/doc3-bloc-firebase.md)** - BLoC + Firebase approach
- **[doc4-clean-architecture.md](legacy/doc4-clean-architecture.md)** - Clean Architecture with flutter_bloc

---

## 🔄 Version History

- **v2.4.0** (2025-11-18) - Added String Constants Management principle
  - Added new "Centralize String Constants" section to core-principles.md
  - CRITICAL: All constant strings must be defined in centralized constants file
  - Create `lib/core/constants/app_constants.dart` with organized constant classes
  - Group constants: AppStrings, ApiEndpoints, StorageKeys, RouteNames
  - No hardcoded strings for UI labels, error messages, routes, or API endpoints
  - Updated Code Quality Checklist to include string constants verification
  - Benefits: single source of truth, prevents typos, easier maintenance, simplifies localization

- **v2.3.0** (2025-11-18) - Added Widget Organization principle
  - Added new "Widget Organization" section to Key Principles
  - CRITICAL: Each widget must be in its own separate file
  - CRITICAL: Screen/view files should not exceed 120-150 lines
  - Extract widget logic beyond limit into separate widget files
  - Use feature-first folder structure with snake_case naming
  - Benefits: improved reusability, testability, maintainability, reduced merge conflicts

- **v2.2.0** (2025-11-17) - BREAKING: Zero StatefulWidget policy with Cubit/BLoC
  - **BREAKING CHANGE:** Updated cubit-pattern-guide.md to enforce strict StatelessWidget-only pattern
  - NEVER use StatefulWidget when using Cubit/BLoC
  - ALL controllers (TextEditingController, AnimationController, etc.) must be managed inside Cubit/BLoC
  - Added comprehensive examples of controller management in Cubit
  - Controllers disposed in Cubit's close() method
  - Single source of truth - all state and controllers in Cubit/BLoC
  - Benefits: easier testing, better separation of concerns, shared controller access

- **v2.1.0** (2025-11-16) - Added official package reference guide
  - Created package-reference.md - Official Package Reference Guide (959 lines)
  - Comprehensive documentation for all officially used packages
  - Includes installation guide, best practices, and DO/DON'T examples
  - Updated README.md to include package reference in core documentation

- **v2.0.0** (2025-11-14) - Added advanced tech-stack specific guides
  - Created supabase-integration-guide.md (1,113 lines)
  - Created clean-architecture-guide.md (1,219 lines)
  - Created dartz-functional-programming-guide.md (1,019 lines)
  - Created bloc-pattern-guide.md (991 lines)
  - Created cubit-pattern-guide.md (1,024 lines)
  - Updated README.md with new documentation structure

- **v1.0.0** (2025-11-14) - Initial consolidated documentation
  - Created core-principles.md
  - Created state-management-guide.md with tiered approach
  - Created testing-guide.md with testing pyramid
  - Created security-best-practices.md
  - Archived legacy documentation

---

## 🤝 Contributing

When updating documentation:
1. Follow the ✅ DO / ❌ DON'T example format
2. Include "Why it matters" explanations
3. Provide complete, runnable code examples
4. Update this README if adding new documents
5. Maintain consistency with existing style

---

## 📞 Support

For questions or suggestions about these guidelines:
1. Review the relevant documentation section
2. Check legacy docs for additional context
3. Consult with team leads for project-specific guidance

---

**Last Updated:** 2025-11-18
**Version:** 2.4.0
**Maintained by:** Flutter Development Team

