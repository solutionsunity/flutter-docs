# Git Commit Standards

**⚠️ PRECAUTION: Never use `git add .`, `git add -A`, or `git add --all`. These commands add all changes at once, which can lead to unintended commits and poor commit hygiene. Always add files selectively by specifying individual files or at most a single feature directory (e.g., `git add lib/features/authentication/`). This ensures you review each change and maintain clean, focused commits.**

## Before Commit
Ensure to follow these steps before a commit:
1. Check if only necessary files are added, avoid staging all files in repository.
2. Check if pubspec.yaml version needs to be updated (major, minor, patch)
3. Check if CHANGELOG.md exists, and update it if necessary (**Ensure date is correct**)
4. Check if README.md exists, and update it if necessary
5. Run `flutter analyze` to ensure no linting errors
6. Run tests with `flutter test` to ensure nothing is broken

## Commit Message Format

```
[TYPE] feature_name: one line description

Detailed description of the changes (for significant changes only)
- Technical references
- Use case explanation
- Result of the change
```

## Types

- **[FIX]**: Bug fixes
- **[ADD]**: New features
- **[REM]**: Feature removal
- **[REF]**: Code refactoring without functionality change
- **[IMP]**: Improvements to existing features
- **[MOV]**: Code moving without functionality change
- **[CLN]**: Code cleanup (removing dead code, comments, etc.)
- **[UPD]**: Update dependencies or data
- **[DOC]**: Documentation updates
- **[TEST]**: Test additions or corrections

## Examples

### Simple commit (one-liner)

```
[FIX] authentication: Reset user state when token expires
```

### Detailed commit (with description)

```
[IMP] product_list: Add support for infinite scroll pagination

Technical:
- Implemented pagination using ListView.builder with scroll controller
- Added loading indicator at bottom of list
- Integrated with ProductCubit for state management
- Added error handling for failed page loads

Use case:
- Users need to browse large product catalogs efficiently
- Previous implementation loaded all products at once causing performance issues

Result:
- Improved app performance with lazy loading
- Better UX with smooth scrolling and loading states
- Reduced initial load time from 5s to 0.5s
```

## Best Practices

1. **Be specific**: The one-liner should clearly indicate what changed
2. **Use present tense**: Write "Add feature" not "Added feature"
3. **Feature/Component name**: Always include the affected feature or component name
4. **Detailed description**: For significant changes, include:
   - Technical details of the implementation
   - The use case or problem being solved
   - The result or impact of the change
5. **Reference issues**: Include references to issues or tickets when applicable
6. **Keep it concise**: The one-liner should be less than 72 characters if possible
7. **Separate commits**: Make separate commits for separate concerns

## When to Use Detailed Descriptions

Include detailed descriptions when:
- Making significant changes to functionality
- Implementing complex features
- Making architectural changes
- Fixing complex bugs
- Changes that affect multiple features or screens
- Performance optimizations
- State management changes
- API integration changes

## Flutter-Specific Commit Examples

### Widget Changes
```
[FIX] user_profile_card: Fix avatar image not loading on iOS
[ADD] custom_button: Add ripple effect animation
[IMP] product_card: Optimize widget rebuild performance
```

### State Management
```
[REF] auth_cubit: Migrate from BLoC to Cubit pattern
[FIX] cart_state: Fix state not persisting after app restart
[ADD] settings_provider: Add theme mode persistence
```

### Navigation & Routing
```
[FIX] deep_linking: Fix navigation to product details from notification
[ADD] app_router: Add nested navigation for settings flow
[IMP] navigation: Add transition animations between screens
```

### API & Data
```
[FIX] user_repository: Handle network timeout errors gracefully
[ADD] cache_manager: Implement offline-first data strategy
[UPD] api_client: Update to use Dio 5.0.0
```

### UI/UX
```
[IMP] login_screen: Add form validation with real-time feedback
[FIX] product_grid: Fix layout overflow on small screens
[ADD] shimmer_loading: Add skeleton loading states
```

### Performance
```
[IMP] image_cache: Implement cached_network_image for better performance
[REF] product_list: Use ListView.builder instead of ListView
[FIX] memory_leak: Dispose controllers in StatefulWidget
```

### Testing
```
[TEST] auth_cubit: Add unit tests for login flow
[TEST] product_repository: Add integration tests for API calls
[FIX] widget_test: Fix flaky animation tests
```

## Opening GitHub Issues

### Issue Title Format

```
[feature_name] short description
```

### Examples

```
[authentication] Login fails with Google Sign-In on Android 14
[product_list] Add support for filtering by category
[checkout] Payment processing error with Stripe integration
[profile] Avatar upload fails for images larger than 5MB
```

### Issue Labels

Use only standard GitHub labels for categorization:

- **bug**: Something isn't working as expected
- **enhancement**: New feature or improvement request
- **documentation**: Documentation related issues
- **question**: General questions or clarifications needed
- **duplicate**: This issue already exists
- **wontfix**: Issue that won't be addressed
- **help wanted**: Extra attention is needed
- **good first issue**: Good for newcomers

**Important**: Do not create or use custom labels. Stick to the standard GitHub label types to maintain consistency across the repository.

