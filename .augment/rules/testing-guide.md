---
type: "manual"
---

# Flutter Testing Guide

> **Comprehensive testing strategies and examples for Flutter applications**

---

## Table of Contents
- [Testing Pyramid](#testing-pyramid)
- [Unit Testing](#unit-testing)
- [Widget Testing](#widget-testing)
- [Integration Testing](#integration-testing)
- [Test Organization](#test-organization)
- [Mocking and Stubbing](#mocking-and-stubbing)
- [Coverage](#coverage)
- [Best Practices](#best-practices)

---

## Testing Pyramid

```
        /\
       /  \
      / E2E\     10% - Integration/E2E Tests
     /______\
    /        \
   /  Widget  \   20% - Widget Tests
  /____________\
 /              \
/   Unit Tests   \ 70% - Unit Tests
/__________________\
```

### Test Distribution

| Test Type | Percentage | Purpose | Speed | Cost |
|-----------|------------|---------|-------|------|
| **Unit Tests** | 70% | Test business logic, models, utilities | ⚡ Fast | 💰 Low |
| **Widget Tests** | 20% | Test UI components and interactions | ⚡⚡ Medium | 💰💰 Medium |
| **Integration Tests** | 10% | Test complete user flows | ⚡⚡⚡ Slow | 💰💰💰 High |

---

## Unit Testing

**Purpose:** Test individual functions, methods, and classes in isolation

**Setup:**
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.1  # For mocking
```

---

### Testing Business Logic

#### ✅ DO: Write focused unit tests with Arrange-Act-Assert

```dart
// ✅ CORRECT: Clear test structure with AAA pattern
import 'package:flutter_test/flutter_test.dart';

class Calculator {
  int add(int a, int b) => a + b;
  int subtract(int a, int b) => a - b;
  double divide(int a, int b) {
    if (b == 0) throw ArgumentError('Cannot divide by zero');
    return a / b;
  }
}

void main() {
  group('Calculator', () {
    late Calculator calculator;

    setUp(() {
      // Arrange: Create fresh instance for each test
      calculator = Calculator();
    });

    test('add returns sum of two numbers', () {
      // Arrange
      const inputA = 5;
      const inputB = 3;
      const expectedResult = 8;

      // Act
      final actualResult = calculator.add(inputA, inputB);

      // Assert
      expect(actualResult, expectedResult);
    });

    test('subtract returns difference of two numbers', () {
      // Arrange
      const inputA = 10;
      const inputB = 4;
      const expectedResult = 6;

      // Act
      final actualResult = calculator.subtract(inputA, inputB);

      // Assert
      expect(actualResult, expectedResult);
    });

    test('divide returns quotient of two numbers', () {
      // Arrange
      const inputA = 10;
      const inputB = 2;
      const expectedResult = 5.0;

      // Act
      final actualResult = calculator.divide(inputA, inputB);

      // Assert
      expect(actualResult, expectedResult);
    });

    test('divide throws ArgumentError when dividing by zero', () {
      // Arrange
      const inputA = 10;
      const inputB = 0;

      // Act & Assert
      expect(
        () => calculator.divide(inputA, inputB),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

#### ❌ DON'T: Write unclear tests without structure

```dart
// ❌ INCORRECT: Unclear test structure, poor naming
void main() {
  test('test1', () {
    var c = Calculator();
    expect(c.add(5, 3), 8); // What are 5 and 3? Why 8?
  });

  test('test2', () {
    var c = Calculator();
    var result = c.divide(10, 2);
    expect(result, 5.0); // No context about what's being tested
  });

  test('divide', () {
    var c = Calculator();
    c.divide(10, 0); // ❌ No assertion! Test passes even if it shouldn't
  });
}
```

**Why it matters:**
- ❌ Unclear what's being tested
- ❌ Hard to debug when tests fail
- ❌ No clear separation of setup, action, and verification
- ✅ AAA pattern makes tests self-documenting

---

### Testing Models and Data Classes

#### ✅ DO: Test JSON serialization/deserialization

```dart
// ✅ CORRECT: Comprehensive model testing
import 'package:flutter_test/flutter_test.dart';

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

void main() {
  group('User', () {
    test('fromJson creates User from valid JSON', () {
      // Arrange
      final json = {
        'id': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, '123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
    });

    test('toJson returns correct JSON map', () {
      // Arrange
      final user = User(
        id: '123',
        name: 'John Doe',
        email: 'john@example.com',
      );
      final expectedJson = {
        'id': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
      };

      // Act
      final actualJson = user.toJson();

      // Assert
      expect(actualJson, expectedJson);
    });

    test('fromJson throws when JSON is missing required fields', () {
      // Arrange
      final invalidJson = {
        'id': '123',
        // Missing name and email
      };

      // Act & Assert
      expect(
        () => User.fromJson(invalidJson),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
```

#### ❌ DON'T: Skip edge cases and error scenarios

```dart
// ❌ INCORRECT: Only testing happy path
void main() {
  test('user test', () {
    var json = {'id': '123', 'name': 'John', 'email': 'john@example.com'};
    var user = User.fromJson(json);
    expect(user.name, 'John');
    // ❌ No tests for:
    // - Missing fields
    // - Null values
    // - Wrong types
    // - toJson()
  });
}
```

**Why it matters:**
- ❌ Production bugs from untested edge cases
- ❌ False confidence in code quality
- ✅ Comprehensive tests catch bugs early

---

### Testing Repositories

#### ✅ DO: Test repository logic with mocked dependencies

```dart
// ✅ CORRECT: Repository testing with mocks
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockApiClient extends Mock implements ApiClient {}
class MockCacheManager extends Mock implements CacheManager {}

class UserRepository {
  final ApiClient apiClient;
  final CacheManager cacheManager;

  UserRepository({required this.apiClient, required this.cacheManager});

  Future<User> getUser(String userId) async {
    // Try cache first
    final cached = await cacheManager.get('user_$userId');
    if (cached != null) {
      return User.fromJson(cached);
    }

    // Fetch from API
    final response = await apiClient.get('/users/$userId');
    final user = User.fromJson(response.data);

    // Cache the result
    await cacheManager.set('user_$userId', user.toJson());

    return user;
  }
}

void main() {
  group('UserRepository', () {
    late UserRepository repository;
    late MockApiClient mockApiClient;
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockApiClient = MockApiClient();
      mockCacheManager = MockCacheManager();
      repository = UserRepository(
        apiClient: mockApiClient,
        cacheManager: mockCacheManager,
      );
    });

    test('getUser returns cached user when available', () async {
      // Arrange
      const userId = '123';
      final cachedUserJson = {
        'id': userId,
        'name': 'John Doe',
        'email': 'john@example.com',
      };
      when(() => mockCacheManager.get('user_$userId'))
          .thenAnswer((_) async => cachedUserJson);

      // Act
      final user = await repository.getUser(userId);

      // Assert
      expect(user.id, userId);
      expect(user.name, 'John Doe');
      verify(() => mockCacheManager.get('user_$userId')).called(1);
      verifyNever(() => mockApiClient.get(any())); // API not called
    });

    test('getUser fetches from API when cache is empty', () async {
      // Arrange
      const userId = '123';
      final apiResponse = ApiResponse(
        data: {
          'id': userId,
          'name': 'Jane Doe',
          'email': 'jane@example.com',
        },
      );
      when(() => mockCacheManager.get('user_$userId'))
          .thenAnswer((_) async => null);
      when(() => mockApiClient.get('/users/$userId'))
          .thenAnswer((_) async => apiResponse);
      when(() => mockCacheManager.set(any(), any()))
          .thenAnswer((_) async => {});

      // Act
      final user = await repository.getUser(userId);

      // Assert
      expect(user.id, userId);
      expect(user.name, 'Jane Doe');
      verify(() => mockCacheManager.get('user_$userId')).called(1);
      verify(() => mockApiClient.get('/users/$userId')).called(1);
      verify(() => mockCacheManager.set('user_$userId', any())).called(1);
    });

    test('getUser caches API response', () async {
      // Arrange
      const userId = '123';
      final apiResponse = ApiResponse(
        data: {
          'id': userId,
          'name': 'Jane Doe',
          'email': 'jane@example.com',
        },
      );
      when(() => mockCacheManager.get(any())).thenAnswer((_) async => null);
      when(() => mockApiClient.get(any())).thenAnswer((_) async => apiResponse);
      when(() => mockCacheManager.set(any(), any()))
          .thenAnswer((_) async => {});

      // Act
      await repository.getUser(userId);

      // Assert
      final captured = verify(
        () => mockCacheManager.set('user_$userId', captureAny()),
      ).captured;
      expect(captured.first['id'], userId);
      expect(captured.first['name'], 'Jane Doe');
    });

    test('getUser throws exception when API fails', () async {
      // Arrange
      const userId = '123';
      when(() => mockCacheManager.get(any())).thenAnswer((_) async => null);
      when(() => mockApiClient.get(any()))
          .thenThrow(NetworkException('No internet'));

      // Act & Assert
      expect(
        () => repository.getUser(userId),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

#### ❌ DON'T: Test with real dependencies

```dart
// ❌ INCORRECT: Using real API client in tests
void main() {
  test('getUser test', () async {
    final apiClient = ApiClient(); // ❌ Real API client
    final cache = CacheManager(); // ❌ Real cache
    final repo = UserRepository(apiClient: apiClient, cacheManager: cache);

    final user = await repo.getUser('123'); // ❌ Makes real network call!

    expect(user.name, 'John'); // ❌ Depends on external API state
  });
}
```

**Why it matters:**
- ❌ Tests are slow (network calls)
- ❌ Tests are flaky (network issues)
- ❌ Tests depend on external services
- ❌ Can't test error scenarios easily
- ✅ Mocks make tests fast, reliable, and comprehensive

---

## Widget Testing

**Purpose:** Test UI components and user interactions

---

### Testing Widgets

#### ✅ DO: Test widget rendering and interactions

```dart
// ✅ CORRECT: Comprehensive widget testing
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CounterWidget extends StatefulWidget {
  const CounterWidget({Key? key}) : super(key: key);

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_counter', key: const Key('counter_text')),
        ElevatedButton(
          key: const Key('increment_button'),
          onPressed: _increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

void main() {
  group('CounterWidget', () {
    testWidgets('displays initial count of 0', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterWidget(),
          ),
        ),
      );

      // Assert
      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Increment'), findsOneWidget);
    });

    testWidgets('increments counter when button is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterWidget(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump(); // Rebuild widget

      // Assert
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Count: 0'), findsNothing);
    });

    testWidgets('increments counter multiple times', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterWidget(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump();

      // Assert
      expect(find.text('Count: 3'), findsOneWidget);
    });
  });
}
```

#### ❌ DON'T: Forget to pump after interactions

```dart
// ❌ INCORRECT: Missing pump() after tap
testWidgets('bad test', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: CounterWidget())),
  );

  await tester.tap(find.text('Increment'));
  // ❌ Missing await tester.pump()!

  expect(find.text('Count: 1'), findsOneWidget); // ❌ Fails! Widget not rebuilt
});

// ✅ CORRECT: Always pump after interactions
testWidgets('good test', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: CounterWidget())),
  );

  await tester.tap(find.text('Increment'));
  await tester.pump(); // ✅ Rebuild widget

  expect(find.text('Count: 1'), findsOneWidget); // ✅ Passes
});
```

**Why it matters:**
- ❌ Tests fail unexpectedly
- ❌ Widget state not updated
- ✅ pump() triggers widget rebuild

---

### Testing Forms

#### ✅ DO: Test form validation and submission

```dart
// ✅ CORRECT: Comprehensive form testing
class LoginForm extends StatefulWidget {
  final void Function(String email, String password) onSubmit;

  const LoginForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('email_field'),
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          TextFormField(
            key: const Key('password_field'),
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          ElevatedButton(
            key: const Key('submit_button'),
            onPressed: _handleSubmit,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('LoginForm', () {
    testWidgets('shows validation errors for empty fields', (tester) async {
      // Arrange
      var submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginForm(
              onSubmit: (email, password) {
                submitted = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Assert
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(submitted, false);
    });

    testWidgets('shows error for invalid email', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginForm(onSubmit: (_, __) {}),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Assert
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginForm(onSubmit: (_, __) {}),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), '12345');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Assert
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('calls onSubmit with valid credentials', (tester) async {
      // Arrange
      String? submittedEmail;
      String? submittedPassword;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginForm(
              onSubmit: (email, password) {
                submittedEmail = email;
                submittedPassword = password;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Assert
      expect(submittedEmail, 'test@example.com');
      expect(submittedPassword, 'password123');
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsNothing);
    });
  });
}
```

---

### Testing with State Management

#### ✅ DO: Test widgets with Provider

```dart
// ✅ CORRECT: Testing widgets with Provider
import 'package:provider/provider.dart';

class CounterProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterProvider>();
    return Text('Count: ${counter.count}');
  }
}

void main() {
  testWidgets('CounterDisplay shows current count', (tester) async {
    // Arrange
    final counterProvider = CounterProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: counterProvider,
        child: MaterialApp(
          home: Scaffold(
            body: CounterDisplay(),
          ),
        ),
      ),
    );

    // Assert initial state
    expect(find.text('Count: 0'), findsOneWidget);

    // Act
    counterProvider.increment();
    await tester.pump();

    // Assert updated state
    expect(find.text('Count: 1'), findsOneWidget);
  });
}
```

#### ✅ DO: Test widgets with BLoC

```dart
// ✅ CORRECT: Testing widgets with BLoC
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

class CounterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterCubit, int>(
      builder: (context, count) {
        return Column(
          children: [
            Text('Count: $count'),
            ElevatedButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}

void main() {
  testWidgets('CounterView increments count', (tester) async {
    // Arrange
    final counterCubit = CounterCubit();
    await tester.pumpWidget(
      BlocProvider.value(
        value: counterCubit,
        child: MaterialApp(
          home: Scaffold(
            body: CounterView(),
          ),
        ),
      ),
    );

    // Assert initial state
    expect(find.text('Count: 0'), findsOneWidget);

    // Act
    await tester.tap(find.text('Increment'));
    await tester.pump();

    // Assert
    expect(find.text('Count: 1'), findsOneWidget);
  });

  testWidgets('CounterView with mock cubit', (tester) async {
    // Arrange
    final mockCubit = MockCounterCubit();
    when(() => mockCubit.state).thenReturn(5);
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(5));

    await tester.pumpWidget(
      BlocProvider<CounterCubit>.value(
        value: mockCubit,
        child: MaterialApp(
          home: Scaffold(
            body: CounterView(),
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Count: 5'), findsOneWidget);
  });
}
```

---

## Integration Testing

**Purpose:** Test complete user flows end-to-end

**Setup:**
```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

Create `integration_test/app_test.dart`:

#### ✅ DO: Test complete user journeys

```dart
// ✅ CORRECT: Integration test for login flow
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow', () {
    testWidgets('user can login and see home screen', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Assert we're on login screen
      expect(find.text('Login'), findsOneWidget);

      // Act: Enter credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // Act: Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Assert: Navigate to home screen
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    });

    testWidgets('shows error for invalid credentials', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act: Enter invalid credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'wrong@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'wrongpassword',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Assert: Error message shown
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget); // Still on login screen
    });
  });

  group('Shopping Cart Flow', () {
    testWidgets('user can add items to cart and checkout', (tester) async {
      // Arrange: Login first
      app.main();
      await tester.pumpAndSettle();
      await _performLogin(tester);

      // Act: Navigate to products
      await tester.tap(find.byIcon(Icons.shopping_bag));
      await tester.pumpAndSettle();

      // Act: Add product to cart
      await tester.tap(find.byKey(const Key('add_to_cart_0')));
      await tester.pumpAndSettle();

      // Assert: Cart badge shows 1 item
      expect(find.text('1'), findsOneWidget);

      // Act: Go to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // Assert: Cart shows product
      expect(find.text('Product 1'), findsOneWidget);

      // Act: Proceed to checkout
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();

      // Assert: On checkout screen
      expect(find.text('Order Summary'), findsOneWidget);
    });
  });
}

Future<void> _performLogin(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(const Key('password_field')), 'password123');
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}
```

#### ❌ DON'T: Test implementation details in integration tests

```dart
// ❌ INCORRECT: Testing internal state in integration tests
testWidgets('bad integration test', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // ❌ Accessing internal state
  final state = tester.state<_LoginScreenState>(find.byType(LoginScreen));
  expect(state.isLoading, false);

  // ❌ Testing widget internals instead of user behavior
  expect(state.emailController.text, '');
});

// ✅ CORRECT: Test user-visible behavior
testWidgets('good integration test', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // ✅ Test what user sees
  expect(find.text('Login'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

**Why it matters:**
- ❌ Integration tests should test user flows, not implementation
- ❌ Brittle tests that break with refactoring
- ✅ Focus on user-visible behavior

---

## Test Organization

### File Structure

```
test/
├── unit/
│   ├── models/
│   │   ├── user_test.dart
│   │   └── product_test.dart
│   ├── repositories/
│   │   ├── user_repository_test.dart
│   │   └── product_repository_test.dart
│   └── utils/
│       └── validators_test.dart
├── widget/
│   ├── screens/
│   │   ├── login_screen_test.dart
│   │   └── home_screen_test.dart
│   └── widgets/
│       ├── counter_widget_test.dart
│       └── product_card_test.dart
└── helpers/
    ├── test_helpers.dart
    └── mock_data.dart

integration_test/
├── app_test.dart
└── login_flow_test.dart
```

### Naming Conventions

#### ✅ DO: Use descriptive test names

```dart
// ✅ CORRECT: Clear, descriptive test names
test('add returns sum of two positive numbers', () {});
test('add returns negative result when adding negative numbers', () {});
test('divide throws ArgumentError when dividing by zero', () {});

testWidgets('LoginForm shows validation error for empty email', (tester) async {});
testWidgets('LoginForm calls onSubmit with valid credentials', (tester) async {});
```

#### ❌ DON'T: Use vague test names

```dart
// ❌ INCORRECT: Vague test names
test('test1', () {});
test('add test', () {});
test('it works', () {});

testWidgets('form test', (tester) async {});
testWidgets('button', (tester) async {});
```

---

## Mocking and Stubbing

### Using Mocktail

#### ✅ DO: Create mocks for dependencies

```dart
// ✅ CORRECT: Proper mocking with mocktail
import 'package:mocktail/mocktail.dart';

// Define mock classes
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  group('LoginBloc', () {
    late LoginBloc loginBloc;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      loginBloc = LoginBloc(authService: mockAuthService);
    });

    tearDown(() {
      loginBloc.close();
    });

    test('emits success state when login succeeds', () async {
      // Arrange
      final user = User(id: '123', name: 'John');
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async => user);

      // Assert later
      expectLater(
        loginBloc.stream,
        emitsInOrder([
          const LoginState.loading(),
          LoginState.success(user),
        ]),
      );

      // Act
      loginBloc.add(const LoginEvent.submit('email', 'password'));
    });

    test('emits error state when login fails', () async {
      // Arrange
      when(() => mockAuthService.login(any(), any()))
          .thenThrow(AuthException('Invalid credentials'));

      // Assert later
      expectLater(
        loginBloc.stream,
        emitsInOrder([
          const LoginState.loading(),
          const LoginState.error('Invalid credentials'),
        ]),
      );

      // Act
      loginBloc.add(const LoginEvent.submit('email', 'password'));
    });

    test('calls authService.login with correct parameters', () async {
      // Arrange
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async => User(id: '123', name: 'John'));

      // Act
      loginBloc.add(const LoginEvent.submit('test@example.com', 'password123'));
      await Future.delayed(Duration.zero); // Let async code run

      // Assert
      verify(() => mockAuthService.login('test@example.com', 'password123'))
          .called(1);
    });
  });
}
```

---

## Coverage

### Running Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage in browser (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Targets

| Code Type | Target Coverage | Priority |
|-----------|----------------|----------|
| **Business Logic** | 90-100% | 🔴 Critical |
| **Repositories** | 80-90% | 🟠 High |
| **Models** | 80-90% | 🟠 High |
| **Widgets** | 60-80% | 🟡 Medium |
| **UI Screens** | 40-60% | 🟢 Low |

#### ✅ DO: Focus on critical business logic

```dart
// ✅ CORRECT: High coverage for business logic
class PaymentProcessor {
  Future<PaymentResult> processPayment(Payment payment) async {
    // Critical business logic - must have 100% coverage
    if (payment.amount <= 0) {
      throw InvalidPaymentException('Amount must be positive');
    }

    if (payment.currency != 'USD') {
      throw UnsupportedCurrencyException('Only USD supported');
    }

    // Process payment...
  }
}

// Comprehensive tests
void main() {
  test('throws for negative amount', () {});
  test('throws for zero amount', () {});
  test('throws for unsupported currency', () {});
  test('processes valid payment', () {});
  test('handles network errors', () {});
  test('retries on timeout', () {});
}
```

#### ❌ DON'T: Obsess over 100% coverage everywhere

```dart
// ❌ INCORRECT: Testing trivial getters
class User {
  final String name;
  User(this.name);
}

// ❌ Unnecessary test
test('name getter returns name', () {
  final user = User('John');
  expect(user.name, 'John'); // ❌ Trivial, no value
});
```

---

## Best Practices

### ✅ DO: Follow the AAA Pattern

```dart
test('example', () {
  // Arrange: Set up test data and dependencies
  final calculator = Calculator();
  const input = 5;

  // Act: Execute the code being tested
  final result = calculator.double(input);

  // Assert: Verify the result
  expect(result, 10);
});
```

### ✅ DO: Use setUp and tearDown

```dart
group('UserRepository', () {
  late UserRepository repository;
  late MockApiClient mockApiClient;

  setUp(() {
    // Runs before each test
    mockApiClient = MockApiClient();
    repository = UserRepository(apiClient: mockApiClient);
  });

  tearDown(() {
    // Runs after each test
    repository.dispose();
  });

  test('test 1', () {});
  test('test 2', () {});
});
```

### ✅ DO: Test one thing per test

```dart
// ✅ CORRECT: Focused tests
test('add returns sum of positive numbers', () {
  expect(calculator.add(2, 3), 5);
});

test('add returns sum of negative numbers', () {
  expect(calculator.add(-2, -3), -5);
});

// ❌ INCORRECT: Testing multiple things
test('add works', () {
  expect(calculator.add(2, 3), 5);
  expect(calculator.add(-2, -3), -5);
  expect(calculator.add(0, 0), 0);
  expect(calculator.add(100, 200), 300);
});
```

### ✅ DO: Use test helpers for common setup

```dart
// test/helpers/test_helpers.dart
MaterialApp buildTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

Future<void> pumpLoginScreen(WidgetTester tester) async {
  await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
}

// Usage
testWidgets('test', (tester) async {
  await pumpLoginScreen(tester);
  // Test code...
});
```

### ❌ DON'T: Have flaky tests

```dart
// ❌ INCORRECT: Flaky test with timing issues
test('flaky test', () async {
  final result = await someAsyncOperation();
  await Future.delayed(Duration(milliseconds: 100)); // ❌ Arbitrary delay
  expect(result.isComplete, true); // ❌ May fail randomly
});

// ✅ CORRECT: Deterministic test
test('reliable test', () async {
  final result = await someAsyncOperation();
  expect(result.isComplete, true); // ✅ Waits for completion
});
```

### ❌ DON'T: Test implementation details

```dart
// ❌ INCORRECT: Testing private methods
test('bad test', () {
  final widget = MyWidget();
  final state = widget.createState();
  state._privateMethod(); // ❌ Testing implementation
});

// ✅ CORRECT: Test public API
testWidgets('good test', (tester) async {
  await tester.pumpWidget(MyWidget());
  await tester.tap(find.text('Button'));
  expect(find.text('Result'), findsOneWidget); // ✅ Test behavior
});
```

---

## Summary

### Testing Checklist

- ✅ **70% unit tests** - Fast, focused, comprehensive
- ✅ **20% widget tests** - UI components and interactions
- ✅ **10% integration tests** - Complete user flows
- ✅ **Use AAA pattern** - Arrange, Act, Assert
- ✅ **Mock dependencies** - Fast, reliable tests
- ✅ **Descriptive names** - Self-documenting tests
- ✅ **One assertion per test** - Focused and clear
- ✅ **Test edge cases** - Null, empty, errors
- ✅ **Use setUp/tearDown** - Clean test state
- ✅ **Avoid flaky tests** - Deterministic results

### Common Mistakes to Avoid

- ❌ Testing implementation details
- ❌ Forgetting to pump() after interactions
- ❌ Using real dependencies instead of mocks
- ❌ Vague test names
- ❌ Testing multiple things in one test
- ❌ Skipping edge cases
- ❌ Not using setUp/tearDown
- ❌ Obsessing over 100% coverage

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0
