---
type: "agent_requested"
description: "Reference documentation for officially approved packages including flutter_bloc, equatable, shimmer, animations, cached_network_image, supabase_flutter, mocktail, bloc_test, and flutter_lints with usage examples."
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
- [Payment Processing](#payment-processing)
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

### onesignal_flutter ^5.3.4

**Purpose:** Push notifications, in-app messages, email, and SMS messaging service for mobile apps

**Why we use it:**
- Free push notification service
- Multi-channel messaging (push, in-app, email, SMS)
- User segmentation and targeting
- Real-time analytics and delivery tracking
- Cross-platform support (iOS and Android)
- Easy integration with Flutter apps
- Rich notification features (images, action buttons, deep linking)

**Official Documentation:** [OneSignal Flutter SDK Setup](https://documentation.onesignal.com/docs/en/flutter-sdk-setup)

#### ✅ DO: Initialize OneSignal in main.dart

```dart
// ✅ CORRECT: OneSignal initialization
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize OneSignal
  // ⚠️ CRITICAL: Never hardcode your OneSignal App ID
  // Always use environment variables
  final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID']!;

  OneSignal.initialize(oneSignalAppId);

  // Request push notification permission (iOS)
  OneSignal.Notifications.requestPermission(true);

  runApp(const MyApp());
}
```

#### ✅ DO: Handle notification events

```dart
// ✅ CORRECT: Listen to notification events
class NotificationService {
  static void initialize() {
    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked: ${event.notification.notificationId}');

      // Handle deep linking
      final data = event.notification.additionalData;
      if (data != null && data.containsKey('screen')) {
        // Navigate to specific screen
        navigateToScreen(data['screen']);
      }
    });

    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('Notification received in foreground');

      // You can prevent the notification from displaying
      // event.preventDefault();

      // Or modify the notification before displaying
      event.notification.display();
    });
  }

  static void navigateToScreen(String screen) {
    // Your navigation logic here
  }
}
```

#### ✅ DO: Set user identification and tags

```dart
// ✅ CORRECT: Identify users and add tags for segmentation
class UserService {
  static Future<void> identifyUser(String userId) async {
    // Set external user ID (your backend user ID)
    await OneSignal.login(userId);
  }

  static Future<void> setUserTags(Map<String, String> tags) async {
    // Add tags for user segmentation
    await OneSignal.User.addTags(tags);
  }

  static Future<void> logout() async {
    // Remove user identification
    await OneSignal.logout();
  }
}

// Usage example
await UserService.identifyUser('user_123');
await UserService.setUserTags({
  'subscription_tier': 'premium',
  'user_level': '10',
  'preferred_language': 'en',
});
```

#### ✅ DO: Use environment variables for OneSignal App ID

```dart
// ✅ CORRECT: Store OneSignal App ID in .env file
// .env file:
// ONESIGNAL_APP_ID=your-onesignal-app-id-here

// main.dart:
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID']!;
  OneSignal.initialize(oneSignalAppId);

  runApp(const MyApp());
}

// .gitignore:
// .env
```

#### ❌ DON'T: Hardcode OneSignal App ID

```dart
// ❌ INCORRECT: Hardcoded App ID exposes credentials
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ❌ CRITICAL SECURITY ISSUE: Never hardcode credentials
  OneSignal.initialize('12345678-1234-1234-1234-123456789012');

  runApp(const MyApp());
}
```

**Why it matters:**
- ❌ Hardcoded credentials can be extracted from the app
- ❌ Credentials committed to version control are exposed
- ❌ Difficult to use different credentials for dev/staging/prod
- ✅ Environment variables keep credentials secure
- ✅ Easy to manage different environments

#### ❌ DON'T: Request permission without context

```dart
// ❌ INCORRECT: Requesting permission immediately without explanation
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OneSignal.initialize(oneSignalAppId);

  // ❌ Bad UX: User doesn't know why they should allow notifications
  OneSignal.Notifications.requestPermission(true);

  runApp(const MyApp());
}
```

#### ✅ DO: Request permission with context

```dart
// ✅ CORRECT: Show explanation before requesting permission
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({Key? key}) : super(key: key);

  Future<void> _requestPermission(BuildContext context) async {
    final hasPermission = await OneSignal.Notifications.requestPermission(true);

    if (hasPermission) {
      // Navigate to next screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show message explaining benefits
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable notifications to receive important updates'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications, size: 100),
            const SizedBox(height: 24),
            const Text(
              'Stay Updated',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Get notified about new features, updates, and special offers',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _requestPermission(context),
              child: const Text('Enable Notifications'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Immediate permission requests have low acceptance rates
- ❌ Users don't understand the value of notifications
- ✅ Contextual permission requests increase acceptance by 2-3x
- ✅ Better user experience and engagement

#### Platform-Specific Setup

**Android Setup:**
- OneSignal automatically handles Firebase Cloud Messaging (FCM) setup
- No additional configuration needed beyond adding the package

**iOS Setup:**
1. Add Push Notifications capability in Xcode
2. Add Background Modes capability (Remote notifications)
3. Add App Group capability
4. Add Notification Service Extension for rich notifications
5. Configure APNs certificates in OneSignal dashboard

See [OneSignal Flutter SDK Setup](https://documentation.onesignal.com/docs/en/flutter-sdk-setup) for detailed iOS setup instructions.

#### Best Practices

**✅ DO:**
- Use external user IDs to identify users across devices
- Add tags for user segmentation and personalization
- Handle notification clicks for deep linking
- Test notifications on both iOS and Android devices
- Use in-app messages for onboarding and engagement
- Respect user privacy and consent preferences

**❌ DON'T:**
- Send too many notifications (causes users to disable them)
- Request permission without explaining the value
- Hardcode OneSignal App ID or credentials
- Ignore notification click events
- Send generic notifications (use segmentation and personalization)

---

## Payment Processing

### moyasar ^2.1.1

**Purpose:** Payment gateway for accepting Apple Pay, STC Pay, and Credit Card payments in Saudi Arabia

**Why we use it:**
- Supports multiple payment methods (Apple Pay, STC Pay, Credit Card)
- Managed 3DS (3D Secure) authentication for credit cards
- Saudi Arabia-focused payment gateway
- Easy integration with Flutter apps
- Sandbox environment for testing
- Secure payment processing with PCI compliance
- Real-time payment status updates

**Official Documentation:** [Moyasar Flutter SDK](https://docs.moyasar.com/category/flutter)

#### ✅ DO: Use environment variables for API keys

```dart
// ✅ CORRECT: Store Moyasar API keys in .env file
// .env file:
// MOYASAR_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
// MOYASAR_SECRET_KEY=sk_test_your_secret_key_here
// MOYASAR_APPLE_PAY_MERCHANT_ID=merchant.com.yourcompany.app

// main.dart:
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

// payment_config.dart:
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentConfig {
  static String get publishableKey => dotenv.env['MOYASAR_PUBLISHABLE_KEY']!;
  static String get appleMerchantId => dotenv.env['MOYASAR_APPLE_PAY_MERCHANT_ID']!;
}

// .gitignore:
// .env
```

#### ✅ DO: Use Moyasar widgets for payment

```dart
// ✅ CORRECT: Using Moyasar's built-in widgets
import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CheckoutScreen extends StatelessWidget {
  final double totalAmount;
  final String orderId;

  const CheckoutScreen({
    Key? key,
    required this.totalAmount,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paymentConfig = PaymentConfig(
      publishableApiKey: dotenv.env['MOYASAR_PUBLISHABLE_KEY']!,
      amount: (totalAmount * 100).toInt(), // Amount in halalas (SAR 257.58 = 25758)
      description: 'Order #$orderId',
      metadata: {
        'order_id': orderId,
        'customer_id': 'user_123',
      },
      creditCard: CreditCardConfig(
        saveCard: true,
        manual: false,
      ),
      applePay: ApplePayConfig(
        merchantId: dotenv.env['MOYASAR_APPLE_PAY_MERCHANT_ID']!,
        label: 'Your Store Name',
        manual: false,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total: SAR ${totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ApplePay(
              config: paymentConfig,
              onPaymentResult: _onPaymentResult,
            ),
            const SizedBox(height: 16),
            const Text('or'),
            const SizedBox(height: 16),
            CreditCard(
              config: paymentConfig,
              onPaymentResult: _onPaymentResult,
            ),
          ],
        ),
      ),
    );
  }

  void _onPaymentResult(result) {
    if (result is PaymentResponse) {
      switch (result.status) {
        case PaymentStatus.paid:
          // ✅ Payment successful
          print('Payment successful: ${result.id}');
          // Navigate to success screen
          break;
        case PaymentStatus.failed:
          // ❌ Payment failed
          print('Payment failed: ${result.source?.message}');
          // Show error message to user
          break;
        case PaymentStatus.initiated:
          // ⏳ Payment initiated (3DS in progress)
          print('Payment initiated: ${result.id}');
          break;
      }
    }
  }
}
```

#### ✅ DO: Handle payment results properly

```dart
// ✅ CORRECT: Comprehensive payment result handling
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moyasar/moyasar.dart';

class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit() : super(const PaymentState.initial());

  void handlePaymentResult(dynamic result) {
    if (result is PaymentResponse) {
      switch (result.status) {
        case PaymentStatus.paid:
          emit(PaymentState.success(
            paymentId: result.id,
            amount: result.amount / 100, // Convert halalas to SAR
          ));
          // Send confirmation to backend
          _confirmPaymentWithBackend(result.id);
          break;

        case PaymentStatus.failed:
          final errorMessage = result.source?.message ?? 'Payment failed';
          emit(PaymentState.error(errorMessage));
          break;

        case PaymentStatus.initiated:
          emit(const PaymentState.processing());
          break;
      }
    } else {
      emit(const PaymentState.error('Unknown payment result'));
    }
  }

  Future<void> _confirmPaymentWithBackend(String paymentId) async {
    try {
      // Verify payment with your backend
      await _paymentRepository.verifyPayment(paymentId);
    } catch (e) {
      print('Error confirming payment: $e');
    }
  }
}
```

#### ❌ DON'T: Hardcode API keys

```dart
// ❌ INCORRECT: Hardcoded API keys expose credentials
import 'package:moyasar/moyasar.dart';

class CheckoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final paymentConfig = PaymentConfig(
      // ❌ CRITICAL SECURITY ISSUE: Never hardcode API keys
      publishableApiKey: 'pk_test_1234567890abcdef',
      amount: 25758,
      description: 'Order #123',
      applePay: ApplePayConfig(
        // ❌ Hardcoded merchant ID
        merchantId: 'merchant.com.myapp',
        label: 'My Store',
        manual: false,
      ),
    );

    return CreditCard(
      config: paymentConfig,
      onPaymentResult: (result) {},
    );
  }
}
```

**Why it matters:**
- ❌ Hardcoded credentials can be extracted from the app
- ❌ Credentials committed to version control are exposed
- ❌ Difficult to use different credentials for dev/staging/prod
- ❌ Security risk if publishable key is compromised
- ✅ Environment variables keep credentials secure
- ✅ Easy to manage different environments (test/live)

#### ❌ DON'T: Trust client-side payment status alone

```dart
// ❌ INCORRECT: Only checking client-side payment status
void _onPaymentResult(result) {
  if (result is PaymentResponse && result.status == PaymentStatus.paid) {
    // ❌ BAD: Trusting client-side status without backend verification
    _orderRepository.markOrderAsPaid(orderId);
    Navigator.pushNamed(context, '/order-success');
  }
}
```

#### ✅ DO: Verify payments on the backend

```dart
// ✅ CORRECT: Verify payment with backend before fulfilling order
void _onPaymentResult(result) async {
  if (result is PaymentResponse && result.status == PaymentStatus.paid) {
    try {
      // ✅ Verify payment with backend using Moyasar secret key
      final verified = await _paymentRepository.verifyPayment(result.id);

      if (verified) {
        // Only mark as paid after backend verification
        await _orderRepository.markOrderAsPaid(orderId);
        Navigator.pushNamed(context, '/order-success');
      } else {
        _showError('Payment verification failed');
      }
    } catch (e) {
      _showError('Error verifying payment: $e');
    }
  }
}

// Backend verification (using Moyasar API)
class PaymentRepository {
  Future<bool> verifyPayment(String paymentId) async {
    final response = await http.get(
      Uri.parse('https://api.moyasar.com/v1/payments/$paymentId'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('${dotenv.env['MOYASAR_SECRET_KEY']}:'))}',
      },
    );

    if (response.statusCode == 200) {
      final payment = json.decode(response.body);
      return payment['status'] == 'paid';
    }
    return false;
  }
}
```

**Why it matters:**
- ❌ Client-side checks can be bypassed
- ❌ Users could manipulate payment status
- ❌ Risk of fulfilling orders without actual payment
- ✅ Backend verification ensures payment was actually processed
- ✅ Protects against fraud and manipulation

#### Platform-Specific Setup

**iOS Setup (Apple Pay):**
1. Follow [Apple Pay setup guide](https://docs.moyasar.com/guides/apple-pay-using-developer-account) to configure your Apple Developer account
2. Enable Apple Pay capability in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Click "+ Capability" → Add "Apple Pay"
   - Add your Merchant ID
3. Add merchant ID to `Info.plist` (handled automatically by the package)

**Android Setup (Credit Card):**
1. Set minimum SDK version in `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for Moyasar
    }
}
```

#### Testing

**Credit Card Testing:**
Moyasar provides test cards for sandbox environment:

| Card Number | Scenario | CVV | Expiry |
|-------------|----------|-----|--------|
| 4111111111111111 | Successful payment | Any 3 digits | Any future date |
| 5200000000000007 | Failed payment | Any 3 digits | Any future date |
| 4000000000000002 | 3DS authentication required | Any 3 digits | Any future date |

**Apple Pay Testing:**
- Use a real iOS device (not simulator)
- Add a test card to Apple Wallet
- Use sandbox environment for testing
- See [Moyasar Apple Pay testing guide](https://docs.moyasar.com/guides/apple-pay-testing)

#### Best Practices

**✅ DO:**
- Store API keys in environment variables (.env file)
- Verify payments on the backend before fulfilling orders
- Handle all payment statuses (paid, failed, initiated)
- Use proper error handling and user feedback
- Test with sandbox environment before going live
- Convert amounts to halalas (multiply by 100)
- Add metadata to payments for tracking
- Implement proper loading states during payment

**❌ DON'T:**
- Hardcode API keys or merchant IDs
- Trust client-side payment status alone
- Forget to handle 3DS authentication flow
- Use production keys in development
- Ignore payment errors or edge cases
- Store sensitive card data in your app
- Process payments without user confirmation

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

### logger ^2.0.0

**Purpose:** Beautiful, formatted console logs with different log levels (debug, info, warning, error) and customizable output

**Why we use it:**
- Professional, readable console output with colors and formatting
- Multiple log levels for different scenarios (debug, info, warning, error)
- Customizable output format (simple, pretty, or custom)
- Better debugging experience than print()
- Easy to filter logs by level
- Stack trace support for errors

**Related Documentation:** [Core Principles - Error Handling](core-principles.md#error-handling)

#### Installation

```yaml
# pubspec.yaml
dependencies:
  logger: ^2.0.0
```

#### ✅ DO: Initialize logger and use appropriate log levels

```dart
// ✅ CORRECT: Create a logger instance and use appropriate levels
import 'package:logger/logger.dart';

class UserRepository {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: false, // Should each log print contain a timestamp
    ),
  );

  Future<User> fetchUser(String userId) async {
    _logger.d('Fetching user with ID: $userId'); // Debug

    try {
      final response = await _apiClient.get('/users/$userId');
      _logger.i('Successfully fetched user: ${response.data['name']}'); // Info
      return User.fromJson(response.data);
    } catch (e, stackTrace) {
      _logger.e('Failed to fetch user', error: e, stackTrace: stackTrace); // Error
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    _logger.d('Updating user: ${user.id}');

    if (user.email.isEmpty) {
      _logger.w('User email is empty, this might cause issues'); // Warning
    }

    try {
      await _apiClient.put('/users/${user.id}', data: user.toJson());
      _logger.i('User updated successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to update user', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

#### ✅ DO: Use logger instead of print() for debugging

```dart
// ✅ CORRECT: Logger provides better debugging experience
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Logger _logger = Logger();

  AuthBloc() : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.d('Login requested for email: ${event.email}');
    emit(const AuthState.loading());

    try {
      final user = await _authRepository.login(event.email, event.password);
      _logger.i('Login successful for user: ${user.id}');
      emit(AuthState.authenticated(user));
    } catch (e, stackTrace) {
      _logger.e('Login failed', error: e, stackTrace: stackTrace);
      emit(AuthState.error('Login failed: ${e.toString()}'));
    }
  }
}
```

#### ✅ DO: Use different log levels appropriately

```dart
// ✅ CORRECT: Use appropriate log levels for different scenarios
class PaymentService {
  final Logger _logger = Logger();

  Future<void> processPayment(Payment payment) async {
    // Debug: Detailed information for debugging
    _logger.d('Processing payment: ${payment.toJson()}');

    // Info: General informational messages
    _logger.i('Payment initiated for amount: ${payment.amount}');

    // Warning: Potentially harmful situations
    if (payment.amount > 10000) {
      _logger.w('Large payment amount detected: ${payment.amount}');
    }

    try {
      final result = await _paymentGateway.charge(payment);
      _logger.i('Payment successful: ${result.transactionId}');
    } catch (e, stackTrace) {
      // Error: Error events with stack traces
      _logger.e(
        'Payment processing failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
```

#### ✅ DO: Configure logger for production

```dart
// ✅ CORRECT: Use simple printer in production, pretty printer in debug
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static Logger get instance {
    return Logger(
      printer: kReleaseMode
          ? SimplePrinter() // Simple output in production
          : PrettyPrinter(  // Pretty output in debug
              methodCount: 2,
              errorMethodCount: 8,
              lineLength: 120,
              colors: true,
              printEmojis: true,
            ),
      level: kReleaseMode ? Level.warning : Level.debug, // Less verbose in production
    );
  }
}

// Usage
class MyService {
  final Logger _logger = AppLogger.instance;

  void doSomething() {
    _logger.d('Debug message'); // Only shown in debug mode
    _logger.w('Warning message'); // Shown in both debug and production
  }
}
```

#### ❌ DON'T: Use print() instead of logger

```dart
// ❌ INCORRECT: print() is less informative and harder to filter
class UserRepository {
  Future<User> fetchUser(String userId) async {
    print('Fetching user: $userId'); // ❌ No log level, no formatting

    try {
      final response = await _apiClient.get('/users/$userId');
      print('Got response: $response'); // ❌ Hard to read
      return User.fromJson(response.data);
    } catch (e) {
      print('Error: $e'); // ❌ No stack trace, no context
      rethrow;
    }
  }
}
```

**Why it matters:**
- ❌ print() output is hard to read and filter
- ❌ No log levels means you can't filter by severity
- ❌ No automatic stack traces for errors
- ❌ print() statements are removed in release builds
- ✅ Logger provides professional, filterable output
- ✅ Easy to disable debug logs in production

#### ❌ DON'T: Log sensitive information

```dart
// ❌ INCORRECT: Logging sensitive data is a security risk
class AuthService {
  final Logger _logger = Logger();

  Future<void> login(String email, String password) async {
    // ❌ NEVER log passwords!
    _logger.d('Login attempt - Email: $email, Password: $password');

    final response = await _apiClient.post('/login', data: {
      'email': email,
      'password': password,
    });

    // ❌ NEVER log API keys or tokens!
    _logger.d('Login response: ${response.data}'); // Contains auth token!
  }
}

class PaymentService {
  final Logger _logger = Logger();

  Future<void> processPayment(CreditCard card) async {
    // ❌ NEVER log credit card details!
    _logger.d('Processing payment with card: ${card.number}');
  }
}
```

**Why it matters:**
- ❌ Logs can be accessed by malicious actors
- ❌ Sensitive data in logs violates privacy regulations (GDPR, PCI-DSS)
- ❌ Logs might be stored in crash reporting services
- ❌ Developers might accidentally commit logs with sensitive data
- ✅ Only log non-sensitive information (user IDs, timestamps, status codes)

#### ✅ DO: Log safely without exposing sensitive data

```dart
// ✅ CORRECT: Log useful information without sensitive data
class AuthService {
  final Logger _logger = Logger();

  Future<void> login(String email, String password) async {
    // ✅ Log email (not sensitive) but NOT password
    _logger.d('Login attempt for email: $email');

    try {
      final response = await _apiClient.post('/login', data: {
        'email': email,
        'password': password,
      });

      // ✅ Log success without exposing token
      _logger.i('Login successful for user: ${response.data['user_id']}');
    } catch (e, stackTrace) {
      // ✅ Log error without exposing credentials
      _logger.e('Login failed for email: $email', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

class PaymentService {
  final Logger _logger = Logger();

  Future<void> processPayment(Payment payment) async {
    // ✅ Log payment ID and amount, not card details
    _logger.d('Processing payment: ${payment.id}, amount: ${payment.amount}');

    try {
      final result = await _paymentGateway.charge(payment);
      // ✅ Log transaction ID, not card details
      _logger.i('Payment successful: ${result.transactionId}');
    } catch (e, stackTrace) {
      _logger.e('Payment failed: ${payment.id}', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

#### ❌ DON'T: Use logger excessively in production

```dart
// ❌ INCORRECT: Too much logging impacts performance
class BadService {
  final Logger _logger = Logger(level: Level.debug); // ❌ Debug level in production

  Future<List<Item>> fetchItems() async {
    _logger.d('Fetching items...'); // ❌ Unnecessary in production

    final items = await _repository.getAll();

    // ❌ Logging every item in a loop!
    for (final item in items) {
      _logger.d('Item: ${item.id}, ${item.name}, ${item.description}...');
    }

    _logger.d('Fetched ${items.length} items'); // ❌ Too verbose
    return items;
  }
}
```

**Why it matters:**
- ❌ Excessive logging impacts app performance
- ❌ Fills up log storage unnecessarily
- ❌ Makes it harder to find important logs
- ✅ Use appropriate log levels (warning/error in production)
- ✅ Only log important events in production

#### Common Use Cases

**1. Debugging API Calls:**
```dart
class ApiClient {
  final Logger _logger = Logger();

  Future<Response> get(String path) async {
    _logger.d('GET request to: $path');

    try {
      final response = await _dio.get(path);
      _logger.i('GET $path - Status: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      _logger.e('GET $path failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

**2. Tracking User Actions:**
```dart
class AnalyticsService {
  final Logger _logger = Logger();

  void trackEvent(String eventName, Map<String, dynamic> properties) {
    _logger.i('Event: $eventName, Properties: $properties');
    // Send to analytics service
  }
}
```

**3. Monitoring Background Tasks:**
```dart
class SyncService {
  final Logger _logger = Logger();

  Future<void> syncData() async {
    _logger.i('Starting data sync...');

    try {
      final result = await _performSync();
      _logger.i('Sync completed: ${result.itemsSynced} items');
    } catch (e, stackTrace) {
      _logger.e('Sync failed', error: e, stackTrace: stackTrace);
    }
  }
}
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
  onesignal_flutter: ^5.3.4

  # Payment Processing
  moyasar: ^2.1.1

  # Environment Variables
  flutter_dotenv: ^5.1.0

  # Logging
  logger: ^2.0.0

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
   import 'package:logger/logger.dart';
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
| **Backend** | onesignal_flutter | ^5.3.4 | Push notifications |
| **Payments** | moyasar | ^2.1.1 | Payment gateway (Apple Pay, STC Pay, Credit Card) |
| **Environment** | flutter_dotenv | ^5.1.0 | Environment variables |
| **Logging** | logger | ^2.0.0 | Beautiful console logs |
| **Testing** | mocktail | ^1.0.4 | Mocking for tests |
| **Testing** | bloc_test | ^9.1.7 | BLoC testing |
| **Dev Tools** | flutter_lints | ^5.0.0 | Code quality |
| **Dev Tools** | device_preview | ^1.1.0 | Multi-device preview |
| **Icons** | cupertino_icons | ^1.0.8 | iOS-style icons |

### Quick Reference

**For new projects, always include:**
1. flutter_bloc + equatable (state management)
2. shimmer + cached_network_image (UI/UX)
3. animations + flutter_animate (animations)
4. supabase_flutter (backend)
5. flutter_dotenv (environment variables)
6. logger (logging and debugging)
7. mocktail + bloc_test (testing)
8. flutter_lints (code quality)

**For projects with specific needs:**
- **Push Notifications:** onesignal_flutter
- **Payment Processing:** moyasar (Saudi Arabia payments)
- **Multi-device Testing:** device_preview

**Related Documentation:**
- [BLoC Pattern Guide](bloc-pattern-guide.md) - Detailed BLoC implementation
- [Supabase Integration Guide](supabase-integration-guide.md) - Backend setup
- [Testing Guide](testing-guide.md) - Testing strategies
- [Core Principles](core-principles.md) - General best practices
- [Security Best Practices](security-best-practices.md) - API keys and security

---

**Last Updated:** 2025-11-18
**Version:** 1.2.0



