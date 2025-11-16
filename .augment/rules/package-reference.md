---
type: "agent_requested"
description: "Example description"
---

# Official Package Reference Guide

> **Comprehensive reference for packages officially used across our Flutter projects**

---

## Table of Contents
- [Overview](#overview)
- [State Management](#state-management)
- [UI Components](#ui-components)
- [Animations](#animations)
- [Image Handling](#image-handling)
- [Backend & Database](#backend--database)
- [Testing](#testing)
- [Development Tools](#development-tools)
- [Installation Guide](#installation-guide)
- [Best Practices](#best-practices)

---

## Overview

This guide documents the official packages we use across our Flutter projects. These packages have been carefully selected based on:
- **Reliability** - Well-maintained with active communities
- **Performance** - Optimized for production use
- **Team Familiarity** - Consistent usage across projects
- **Best Practices** - Align with Flutter and Dart standards

**Package Version Policy:**
- ✅ Use the versions specified in this guide
- ✅ Test thoroughly before upgrading major versions
- ✅ Keep packages up-to-date with minor/patch releases
- ❌ Don't add new packages without team discussion

---

## State Management

### flutter_bloc ^8.1.3

**Purpose:** Predictable state management using the BLoC (Business Logic Component) pattern

**Why we use it:**
- Clear separation of business logic and UI
- Excellent testability
- Scales well for medium to large applications
- Strong typing and compile-time safety

**Related Documentation:** [BLoC Pattern Guide](bloc-pattern-guide.md)

#### ✅ DO: Use flutter_bloc for feature state management

```dart
// ✅ CORRECT: BLoC for managing authentication state
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase})
      : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
}
```

#### ❌ DON'T: Use multiple state management solutions

```dart
// ❌ INCORRECT: Mixing state management approaches
class BadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ❌ Using Provider and BLoC together unnecessarily
    return Provider<SomeService>(
      create: (_) => SomeService(),
      child: BlocProvider(
        create: (_) => SomeBloc(),
        child: SomeWidget(),
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Increases complexity and confusion
- ❌ Makes code harder to maintain
- ❌ Team members need to learn multiple patterns
- ✅ Stick to one state management solution (flutter_bloc)

---

### equatable ^2.0.5

**Purpose:** Simplify value equality comparisons for BLoC events and states

**Why we use it:**
- Eliminates boilerplate for equality checks
- Essential for BLoC pattern (comparing states)
- Improves performance by preventing unnecessary rebuilds

#### ✅ DO: Use Equatable for BLoC events and states

```dart
// ✅ CORRECT: Equatable for automatic equality
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

// BLoC can now properly compare events
// LoginRequested(email: 'a', password: 'b') == LoginRequested(email: 'a', password: 'b')
```

#### ❌ DON'T: Manually implement equality without Equatable

```dart
// ❌ INCORRECT: Manual equality implementation (error-prone)
class BadLoginEvent {
  final String email;
  final String password;

  BadLoginEvent({required this.email, required this.password});

  // ❌ Easy to forget to update when adding fields
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadLoginEvent &&
          runtimeType == other.runtimeType &&
          email == other.email;
          // ❌ Forgot to compare password!

  @override
  int get hashCode => email.hashCode; // ❌ Incomplete
}
```

**Why it matters:**
- ❌ Manual equality is error-prone
- ❌ Easy to forget fields when updating
- ❌ Inconsistent hashCode implementations
- ✅ Equatable handles it automatically and correctly

---

## UI Components

### shimmer ^3.0.0

**Purpose:** Create loading skeleton animations for better UX

**Why we use it:**
- Improves perceived performance
- Better user experience than spinners
- Easy to implement
- Customizable appearance

#### ✅ DO: Use Shimmer for loading states

```dart
// ✅ CORRECT: Shimmer loading skeleton
import 'package:shimmer/shimmer.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 16,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 16,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

// Usage in BLoC
BlocBuilder<ProductsBloc, ProductsState>(
  builder: (context, state) {
    return state.when(
      loading: () => ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      ),
      loaded: (products) => ProductsList(products: products),
      error: (message) => ErrorWidget(message: message),
    );
  },
)
```

#### ❌ DON'T: Use only CircularProgressIndicator for all loading states

```dart
// ❌ INCORRECT: Generic spinner for content loading
class BadProductsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is Loading) {
          // ❌ Poor UX - doesn't show content structure
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        // ...
      },
    );
  }
}
```

**Why it matters:**
- ❌ Spinners don't show content structure
- ❌ Users can't anticipate what's loading
- ❌ Feels slower than skeleton screens
- ✅ Shimmer provides better perceived performance

---

## Animations

### animations ^2.0.11

**Purpose:** Google's official Material motion patterns and transitions

**Why we use it:**
- Official Google package
- Beautiful, polished animations
- Material Design compliant
- Easy to implement

#### ✅ DO: Use animations for page transitions

```dart
// ✅ CORRECT: Smooth page transitions with animations package
import 'package:animations/animations.dart';

class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return OpenContainer(
          closedBuilder: (context, action) => ProductCard(
            product: products[index],
          ),
          openBuilder: (context, action) => ProductDetailScreen(
            product: products[index],
          ),
          transitionType: ContainerTransitionType.fade,
          transitionDuration: const Duration(milliseconds: 500),
        );
      },
    );
  }
}
```

---

### flutter_animate ^4.5.0

**Purpose:** Easy-to-use animation library with minimal code

**Why we use it:**
- Extremely simple API
- Chainable animations
- Great for quick animations
- Minimal boilerplate

#### ✅ DO: Use flutter_animate for simple animations

```dart
// ✅ CORRECT: Simple fade and slide animation
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Welcome!')
      .animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: -0.2, end: 0);
  }
}
```

---

### flutter_staggered_animations ^1.1.1

**Purpose:** Staggered animations for lists and grids

**Why we use it:**
- Beautiful entrance animations
- Perfect for lists and grids
- Customizable timing
- Smooth performance

#### ✅ DO: Use for list/grid entrance animations

```dart
// ✅ CORRECT: Staggered list animation
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ProductsList extends StatelessWidget {
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ProductCard(product: products[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

### confetti ^0.7.0

**Purpose:** Celebration and particle effects

**Why we use it:**
- Fun user feedback
- Gamification elements
- Success celebrations
- Easy to customize

#### ✅ DO: Use for success states and celebrations

```dart
// ✅ CORRECT: Confetti on successful purchase
import 'package:confetti/confetti.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        state.whenOrNull(
          success: () => _confettiController.play(),
        );
      },
      child: Stack(
        children: [
          // Your checkout UI
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
```

---

## Image Handling

### cached_network_image ^3.3.0

**Purpose:** Load and cache network images efficiently

**Why we use it:**
- Automatic caching
- Placeholder support
- Error handling
- Memory efficient
- Industry standard

#### ✅ DO: Always use for network images

```dart
// ✅ CORRECT: Cached network image with placeholder and error handling
import 'package:cached_network_image/cached_network_image.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;

  const ProductImage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: 200,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.error, color: Colors.red),
      ),
      fit: BoxFit.cover,
    );
  }
}
```

#### ❌ DON'T: Use Image.network without caching

```dart
// ❌ INCORRECT: No caching, poor UX
class BadProductImage extends StatelessWidget {
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    // ❌ Reloads every time, wastes bandwidth
    return Image.network(
      imageUrl,
      // ❌ No placeholder
      // ❌ No error handling
      // ❌ No caching
    );
  }
}
```

**Why it matters:**
- ❌ Image.network reloads every time
- ❌ Wastes bandwidth and data
- ❌ Slower user experience
- ❌ No offline support
- ✅ CachedNetworkImage handles all of this

---

## Backend & Database

### supabase_flutter ^2.0.0

**Purpose:** Open-source Firebase alternative with PostgreSQL backend

**Why we use it:**
- Real-time database
- Authentication built-in
- Storage for files/images
- PostgreSQL (more powerful than NoSQL)
- Open-source and self-hostable
- Row Level Security (RLS)

**Related Documentation:** [Supabase Integration Guide](supabase-integration-guide.md)

#### ✅ DO: Use Supabase for backend services

```dart
// ✅ CORRECT: Supabase initialization and usage
import 'package:supabase_flutter/supabase_flutter.dart';

// Initialize in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

// Usage in repository
class ProductRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Product.fromJson(json))
        .toList();
  }

  Future<void> addProduct(Product product) async {
    await _supabase
        .from('products')
        .insert(product.toJson());
  }
}
```

---

## Testing

### mocktail ^1.0.4

**Purpose:** Mocking library for unit tests

**Why we use it:**
- Null-safe
- Better than mockito (no code generation needed)
- Simple API
- Great for testing BLoCs

#### ✅ DO: Use mocktail for mocking dependencies

```dart
// ✅ CORRECT: Mocking with mocktail
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    authBloc = AuthBloc(loginUseCase: mockLoginUseCase);
  });

  test('emits authenticated state when login succeeds', () async {
    // Arrange
    when(() => mockLoginUseCase(any()))
        .thenAnswer((_) async => Right(testUser));

    // Act
    authBloc.add(const LoginRequested(
      email: 'test@example.com',
      password: 'password123',
    ));

    // Assert
    await expectLater(
      authBloc.stream,
      emitsInOrder([
        const AuthState.loading(),
        AuthState.authenticated(testUser),
      ]),
    );
  });
}
```

---

### bloc_test ^9.1.7

**Purpose:** Testing library specifically for BLoCs

**Why we use it:**
- Simplifies BLoC testing
- Clear, readable test syntax
- Handles async properly
- Verifies state emissions

#### ✅ DO: Use bloc_test for testing BLoCs

```dart
// ✅ CORRECT: Testing BLoC with bloc_test
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when login succeeds',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Right(testUser));
        return AuthBloc(loginUseCase: mockLoginUseCase);
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthState.loading(),
        AuthState.authenticated(testUser),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when login fails',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));
        return AuthBloc(loginUseCase: mockLoginUseCase);
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'test@example.com',
        password: 'wrong',
      )),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('Invalid credentials'),
      ],
    );
  });
}
```

---

## Development Tools

### flutter_lints ^5.0.0

**Purpose:** Official Flutter linting rules

**Why we use it:**
- Official Flutter team recommendations
- Catches common mistakes
- Enforces best practices
- Keeps code consistent

#### ✅ DO: Enable flutter_lints in all projects

```yaml
# ✅ CORRECT: pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

```yaml
# ✅ CORRECT: analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Add any custom rules here
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
```

---

### cupertino_icons ^1.0.8

**Purpose:** iOS-style icons for Cupertino widgets

**Why we use it:**
- Required for iOS-style UI
- Lightweight
- Official Flutter package

---

### device_preview ^1.1.0

**Purpose:** Preview your app on multiple device sizes and orientations during development

**Why we use it:**
- Test responsive layouts without physical devices
- Preview different screen sizes simultaneously
- Test dark mode and accessibility features
- Identify UI issues early in development
- Great for demos and presentations

**Related Documentation:** [Core Principles - UI and Styling](core-principles.md#ui-and-styling)

#### ✅ DO: Use device_preview for responsive design testing

```dart
// ✅ CORRECT: Wrap your app with DevicePreview in debug mode
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Only enabled in debug/profile mode
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ✅ Use DevicePreview's locale and builder
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      // ✅ Disable debug banner when using DevicePreview
      debugShowCheckedModeBanner: false,

      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

#### ✅ DO: Test responsive layouts with LayoutBuilder

```dart
// ✅ CORRECT: Use LayoutBuilder for responsive design
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ Adapt layout based on screen width
        if (constraints.maxWidth > 900) {
          return const DesktopLayout();
        } else if (constraints.maxWidth > 600) {
          return const TabletLayout();
        } else {
          return const MobileLayout();
        }
      },
    );
  }
}

// ✅ Test this with DevicePreview to see all layouts
```

#### ✅ DO: Use MediaQuery for device-specific adjustments

```dart
// ✅ CORRECT: Use MediaQuery with DevicePreview
class AdaptiveCard extends StatelessWidget {
  const AdaptiveCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      margin: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
        child: Column(
          children: [
            Text(
              'Adaptive Card',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isSmallScreen ? 18 : 24,
              ),
            ),
            // Content adapts to screen size
          ],
        ),
      ),
    );
  }
}
```

#### ❌ DON'T: Leave DevicePreview enabled in production

```dart
// ❌ INCORRECT: DevicePreview always enabled
void main() {
  runApp(
    DevicePreview(
      enabled: true, // ❌ Will show in production builds!
      builder: (context) => const MyApp(),
    ),
  );
}
```

**Why it matters:**
- ❌ DevicePreview adds significant overhead
- ❌ Shows development UI to end users
- ❌ Increases app size unnecessarily
- ✅ Use `!kReleaseMode` to auto-disable in production

#### ❌ DON'T: Hardcode sizes instead of using responsive design

```dart
// ❌ INCORRECT: Fixed sizes don't work across devices
class BadLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375, // ❌ Hardcoded iPhone width
      height: 812, // ❌ Hardcoded iPhone height
      child: Column(
        children: [
          Container(
            width: 300, // ❌ Fixed width
            height: 200, // ❌ Fixed height
            child: Text('This breaks on tablets!'),
          ),
        ],
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Breaks on different screen sizes
- ❌ Poor user experience on tablets/desktops
- ❌ Not accessible
- ✅ Use responsive design with LayoutBuilder/MediaQuery

#### ✅ DO: Test different device configurations

```dart
// ✅ CORRECT: Test with DevicePreview's device selector
// In DevicePreview, you can:
// 1. Switch between iPhone, iPad, Android phones, tablets
// 2. Rotate devices to test landscape/portrait
// 3. Toggle dark mode
// 4. Test different text scaling (accessibility)
// 5. Test different locales

// Example: Testing text scaling
class AccessibleText extends StatelessWidget {
  const AccessibleText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'This text respects user font size preferences',
      style: Theme.of(context).textTheme.bodyLarge, // ✅ Uses theme
      // ✅ Test with DevicePreview's accessibility settings
    );
  }
}
```

#### Common Use Cases

**1. Testing Responsive Layouts:**
```dart
// Use DevicePreview to test on:
// - iPhone SE (small screen)
// - iPhone 15 Pro (standard)
// - iPad Pro (tablet)
// - Desktop (large screen)
```

**2. Testing Dark Mode:**
```dart
// Toggle dark mode in DevicePreview to ensure:
// - Colors have sufficient contrast
// - Images look good in both modes
// - Theme.of(context) is used consistently
```

**3. Testing Accessibility:**
```dart
// Use DevicePreview to test:
// - Large text sizes (accessibility)
// - Screen reader compatibility
// - Touch target sizes (minimum 48x48)
```

**4. Demo and Presentations:**
```dart
// Use DevicePreview to:
// - Show app on multiple devices simultaneously
// - Record demos with device frames
// - Present to stakeholders
```

---

## Installation Guide

### Complete pubspec.yaml Template

```yaml
name: your_app_name
description: "Your app description"
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter

  # Icons
  cupertino_icons: ^1.0.8

  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # UI Components
  shimmer: ^3.0.0

  # Animations
  animations: ^2.0.11
  flutter_animate: ^4.5.0
  flutter_staggered_animations: ^1.1.1
  confetti: ^0.7.0

  # Image Handling
  cached_network_image: ^3.3.0

  # Backend
  supabase_flutter: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Linting
  flutter_lints: ^5.0.0

  # Testing
  mocktail: ^1.0.4
  bloc_test: ^9.1.7

  # Development Tools
  device_preview: ^1.1.0

flutter:
  uses-material-design: true
```

### Installation Steps

1. **Add dependencies to pubspec.yaml**
2. **Run pub get:**
   ```bash
   flutter pub get
   ```
3. **Import in your Dart files:**
   ```dart
   import 'package:flutter_bloc/flutter_bloc.dart';
   import 'package:equatable/equatable.dart';
   import 'package:shimmer/shimmer.dart';
   import 'package:device_preview/device_preview.dart';
   // etc.
   ```

---

## Best Practices

### Package Management

#### ✅ DO: Keep packages up-to-date

```bash
# Check for outdated packages
flutter pub outdated

# Update packages (respecting version constraints)
flutter pub upgrade

# Update to latest major versions (carefully!)
flutter pub upgrade --major-versions
```

#### ✅ DO: Use version constraints properly

```yaml
# ✅ CORRECT: Caret syntax allows minor and patch updates
dependencies:
  flutter_bloc: ^8.1.3  # Allows 8.1.4, 8.2.0, but not 9.0.0
  equatable: ^2.0.5     # Allows 2.0.6, 2.1.0, but not 3.0.0
```

#### ❌ DON'T: Use exact versions or 'any'

```yaml
# ❌ INCORRECT: Too restrictive
dependencies:
  flutter_bloc: 8.1.3  # Won't get bug fixes

# ❌ INCORRECT: Too permissive
dependencies:
  flutter_bloc: any  # Could break on major updates
```

---

### Testing Package Upgrades

#### ✅ DO: Test thoroughly after upgrading

```bash
# 1. Upgrade packages
flutter pub upgrade

# 2. Run all tests
flutter test

# 3. Check for deprecation warnings
flutter analyze

# 4. Test on real devices
flutter run
```

---

### Adding New Packages

#### ✅ DO: Evaluate packages before adding

**Checklist before adding a new package:**
- [ ] Is it actively maintained? (recent commits)
- [ ] Does it have good documentation?
- [ ] What's the pub.dev score? (aim for 130+)
- [ ] How many likes/pub points?
- [ ] Are there any open critical issues?
- [ ] Is there a better alternative we already use?
- [ ] Does the team agree it's needed?

#### ❌ DON'T: Add packages without discussion

```yaml
# ❌ INCORRECT: Adding packages without team approval
dependencies:
  some_random_package: ^1.0.0  # What does this do? Why do we need it?
  another_package: ^2.0.0      # Do we already have something similar?
```

---

## Summary

### Our Official Package Stack

| Category | Package | Version | Purpose |
|----------|---------|---------|---------|
| **State Management** | flutter_bloc | ^8.1.3 | BLoC pattern implementation |
| **State Management** | equatable | ^2.0.5 | Value equality for BLoC |
| **UI Components** | shimmer | ^3.0.0 | Loading skeletons |
| **Animations** | animations | ^2.0.11 | Material transitions |
| **Animations** | flutter_animate | ^4.5.0 | Simple animations |
| **Animations** | flutter_staggered_animations | ^1.1.1 | List/grid animations |
| **Animations** | confetti | ^0.7.0 | Celebration effects |
| **Images** | cached_network_image | ^3.3.0 | Network image caching |
| **Backend** | supabase_flutter | ^2.0.0 | Backend services |
| **Testing** | mocktail | ^1.0.4 | Mocking for tests |
| **Testing** | bloc_test | ^9.1.7 | BLoC testing |
| **Dev Tools** | flutter_lints | ^5.0.0 | Code quality |
| **Icons** | cupertino_icons | ^1.0.8 | iOS-style icons |

### Quick Reference

**For new projects, always include:**
1. flutter_bloc + equatable (state management)
2. shimmer + cached_network_image (UI/UX)
3. animations + flutter_animate (animations)
4. supabase_flutter (backend)
5. mocktail + bloc_test (testing)
6. flutter_lints (code quality)

**Related Documentation:**
- [BLoC Pattern Guide](bloc-pattern-guide.md) - Detailed BLoC implementation
- [Supabase Integration Guide](supabase-integration-guide.md) - Backend setup
- [Testing Guide](testing-guide.md) - Testing strategies
- [Core Principles](core-principles.md) - General best practices

---

**Last Updated:** 2025-11-16
**Version:** 1.0.0



