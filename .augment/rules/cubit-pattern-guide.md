---
type: "agent_requested"
description: "Simplified state management using Cubit pattern with emit() method, StatelessWidget integration, controller management inside Cubit, and testing strategies for medium to large Flutter applications."
---

# Cubit Pattern Guide

> **Comprehensive guide for implementing the Cubit pattern in Flutter**

---

## Table of Contents
- [Overview](#overview)
- [Cubit vs BLoC](#cubit-vs-bloc)
- [States](#states)
- [Cubit Implementation](#cubit-implementation)
- [UI Integration](#ui-integration)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Migration from BLoC](#migration-from-bloc)
- [Best Practices](#best-practices)

---

## Overview

**Cubit** is a simplified version of BLoC that:
- Exposes methods instead of events
- Uses `emit()` to emit states
- Has less boilerplate than BLoC
- Is easier to learn and use

**Use Cubit when:**
- ✅ Building simple to medium applications
- ✅ State changes are straightforward
- ✅ Don't need event transformers
- ✅ Want less boilerplate
- ✅ Team prefers imperative style

**Use BLoC instead when:**
- ❌ Need event transformers (debounce, throttle)
- ❌ Need event replay/undo functionality
- ❌ Complex event handling logic
- ❌ Need to track event history

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.3  # Includes Cubit
  equatable: ^2.0.5
  freezed_annotation: ^2.4.1

dev_dependencies:
  bloc_test: ^9.1.4
  freezed: ^2.4.5
  build_runner: ^2.4.6
```

---

## Cubit vs BLoC

### Key Differences

| Feature | Cubit | BLoC |
|---------|-------|------|
| **Input** | Methods | Events |
| **Boilerplate** | Less | More |
| **Complexity** | Simpler | More complex |
| **Event Transformers** | ❌ No | ✅ Yes |
| **Event History** | ❌ No | ✅ Yes |
| **Learning Curve** | Easier | Steeper |

### Example Comparison

```dart
// BLoC - Event-driven
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Handle event
  }
}

// Usage
authBloc.add(const AuthEvent.loginRequested(
  email: 'test@example.com',
  password: 'password',
));
```

```dart
// Cubit - Method-driven
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.initial());
  
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Handle login
  }
}

// Usage
authCubit.login(
  email: 'test@example.com',
  password: 'password',
);
```

---

## States

States in Cubit are identical to BLoC states.

### ✅ DO: Use Freezed for union states

```dart
// ✅ CORRECT: Freezed states
import 'package:freezed_annotation/freezed_annotation.dart';
import '../entities/user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = Initial;
  const factory AuthState.loading() = Loading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error(String message) = Error;
}
```

### ✅ DO: Include data in states

```dart
// ✅ CORRECT: States with data
@freezed
class CounterState with _$CounterState {
  const factory CounterState({
    required int count,
    required bool isLoading,
    String? errorMessage,
  }) = _CounterState;
  
  factory CounterState.initial() => const CounterState(
    count: 0,
    isLoading: false,
  );
}
```

---

## Cubit Implementation

### ✅ DO: Use methods to trigger state changes

```dart
// ✅ CORRECT: Cubit with methods
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../../core/usecases/usecase.dart';

class AuthCubit extends Cubit<AuthState> {
  final Login loginUseCase;
  final Logout logoutUseCase;
  final GetCurrentUser getCurrentUserUseCase;
  
  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthState.initial());
  
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    
    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
  
  Future<void> logout() async {
    emit(const AuthState.loading());
    
    final result = await logoutUseCase(NoParams());
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }
  
  Future<void> checkAuthStatus() async {
    emit(const AuthState.loading());
    
    final result = await getCurrentUserUseCase(NoParams());
    
    result.fold(
      (_) => emit(const AuthState.unauthenticated()),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
}
```

### ✅ DO: Use emit() to change states

```dart
// ✅ CORRECT: Using emit()
class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterState.initial());
  
  void increment() {
    emit(state.copyWith(count: state.count + 1));
  }
  
  void decrement() {
    emit(state.copyWith(count: state.count - 1));
  }
  
  void reset() {
    emit(CounterState.initial());
  }
}
```

### ❌ DON'T: Modify state directly

```dart
// ❌ INCORRECT: Modifying state directly
class BadCounterCubit extends Cubit<CounterState> {
  BadCounterCubit() : super(CounterState.initial());
  
  void increment() {
    state.count++; // ❌ Can't modify state directly
  }
}
```

**Why it matters:**
- ❌ States are immutable
- ❌ UI won't update
- ❌ Can't track state changes
- ✅ emit() properly notifies listeners

---

### ✅ DO: Handle async operations properly

```dart
// ✅ CORRECT: Async operations in Cubit
class PostsCubit extends Cubit<PostsState> {
  final GetPosts getPostsUseCase;
  final CreatePost createPostUseCase;
  
  PostsCubit({
    required this.getPostsUseCase,
    required this.createPostUseCase,
  }) : super(const PostsState.initial());
  
  Future<void> loadPosts() async {
    emit(const PostsState.loading());
    
    final result = await getPostsUseCase(NoParams());
    
    result.fold(
      (failure) => emit(PostsState.error(failure.message)),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }
  
  Future<void> createPost({
    required String title,
    required String content,
  }) async {
    // Keep current state while creating
    final currentState = state;
    
    emit(const PostsState.creating());
    
    final result = await createPostUseCase(
      CreatePostParams(title: title, content: content),
    );
    
    result.fold(
      (failure) {
        // Restore previous state on error
        emit(currentState);
        emit(PostsState.error(failure.message));
      },
      (newPost) {
        // Add new post to existing posts
        if (currentState is Loaded) {
          final updatedPosts = [newPost, ...currentState.posts];
          emit(PostsState.loaded(updatedPosts));
        } else {
          loadPosts(); // Reload if state is unknown
        }
      },
    );
  }
  
  Future<void> refreshPosts() async {
    // Keep current posts while refreshing
    final currentPosts = state.whenOrNull(
      loaded: (posts) => posts,
    );
    
    final result = await getPostsUseCase(NoParams());
    
    result.fold(
      (failure) => emit(PostsState.error(
        failure.message,
        cachedPosts: currentPosts,
      )),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }
}
```

### ❌ DON'T: Emit states after Cubit is closed

```dart
// ❌ INCORRECT: Emitting after close
class BadPostsCubit extends Cubit<PostsState> {
  BadPostsCubit() : super(const PostsState.initial());

  Future<void> loadPosts() async {
    emit(const PostsState.loading());

    await Future.delayed(const Duration(seconds: 5));

    // ❌ Cubit might be closed by now
    emit(const PostsState.loaded([]));
  }
}
```

```dart
// ✅ CORRECT: Check if closed before emitting
class PostsCubit extends Cubit<PostsState> {
  PostsCubit() : super(const PostsState.initial());

  Future<void> loadPosts() async {
    emit(const PostsState.loading());

    final result = await getPostsUseCase(NoParams());

    // ✅ Check if closed
    if (isClosed) return;

    result.fold(
      (failure) => emit(PostsState.error(failure.message)),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }
}
```

**Why it matters:**
- ❌ Emitting after close causes errors
- ❌ Memory leaks
- ✅ Always check isClosed for long operations

---

## UI Integration

### ✅ DO: Use BlocProvider to provide Cubit

```dart
// ✅ CORRECT: Provide Cubit with BlocProvider
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection_container.dart' as di;

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthCubit>()..checkAuthStatus(),
      child: const LoginView(),
    );
  }
}
```

### ✅ DO: Use BlocBuilder for UI updates

```dart
// ✅ CORRECT: BlocBuilder with Cubit
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return state.when(
            initial: () => const LoginForm(),
            loading: () => const Center(child: CircularProgressIndicator()),
            authenticated: (user) => Text('Welcome, ${user.name}!'),
            unauthenticated: () => const LoginForm(),
            error: (message) => Column(
              children: [
                Text('Error: $message', style: TextStyle(color: Colors.red)),
                const LoginForm(),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### ✅ DO: Call Cubit methods from UI

```dart
// ✅ CORRECT: Calling Cubit methods
class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: () {
            // ✅ Call Cubit method directly
            context.read<AuthCubit>().login(
              email: _emailController.text,
              password: _passwordController.text,
            );
          },
          child: const Text('Login'),
        ),
      ],
    );
  }
}
```

### ✅ DO: Use context.read() for one-time calls

```dart
// ✅ CORRECT: context.read() for calling methods
ElevatedButton(
  onPressed: () {
    context.read<CounterCubit>().increment();
  },
  child: const Text('Increment'),
)
```

### ✅ DO: Use context.watch() for reactive updates

```dart
// ✅ CORRECT: context.watch() for reactive UI
class CounterText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CounterCubit>().state.count;
    return Text('Count: $count');
  }
}
```

### ❌ DON'T: Use context.watch() in callbacks

```dart
// ❌ INCORRECT: context.watch() in callback
ElevatedButton(
  onPressed: () {
    // ❌ Don't use watch in callbacks
    context.watch<CounterCubit>().increment();
  },
  child: const Text('Increment'),
)
```

```dart
// ✅ CORRECT: Use context.read() in callbacks
ElevatedButton(
  onPressed: () {
    context.read<CounterCubit>().increment();
  },
  child: const Text('Increment'),
)
```

**Why it matters:**
- ❌ watch() rebuilds widget on every state change
- ❌ Causes unnecessary rebuilds in callbacks
- ✅ read() is for one-time access
- ✅ watch() is for reactive updates

---

## StatelessWidget vs StatefulWidget with Cubit

### Principle: Use StatelessWidget for Screens with Cubit

When using Cubit (or any declarative state management like BLoC, Provider, Riverpod), screens should be **StatelessWidget**. The Cubit manages all state, eliminating the need for StatefulWidget's `setState()` or lifecycle methods.

### ✅ DO: Use StatelessWidget with BlocBuilder

```dart
// ✅ CORRECT: StatelessWidget with Cubit state management
class ProductListPage extends StatelessWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<ProductCubit>()..loadProducts(),
      child: const ProductListView(),
    );
  }
}

class ProductListView extends StatelessWidget {
  const ProductListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductError) {
            return ErrorDisplay(
              message: state.message,
              onRetry: () => context.read<ProductCubit>().retry(),
            );
          }

          if (state is ProductLoaded) {
            return ListView.builder(
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                return ProductCard(product: state.products[index]);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### ❌ DON'T: Use StatefulWidget with Cubit for state management

```dart
// ❌ INCORRECT: StatefulWidget with Cubit - dual state management anti-pattern
class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // ❌ Mixing StatefulWidget state with Cubit state
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<ProductCubit>()..loadProducts(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            // ❌ Duplicating state management - Cubit already handles this!
            if (state is ProductLoading) {
              setState(() => _isLoading = true); // ❌ Unnecessary
            }

            if (state is ProductError) {
              setState(() {
                _isLoading = false;
                _errorMessage = state.message; // ❌ Cubit already has this
              });
            }

            // ❌ Using local state instead of Cubit state
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage != null) {
              return ErrorDisplay(message: _errorMessage!);
            }

            if (state is ProductLoaded) {
              return ListView.builder(
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: state.products[index]);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Dual state management creates confusion about source of truth
- ❌ setState() calls are unnecessary when Cubit manages state
- ❌ Harder to test - need to test both widget state and Cubit state
- ❌ More boilerplate code to maintain
- ❌ Risk of state synchronization bugs
- ✅ StatelessWidget with Cubit provides single source of truth
- ✅ Easier to test - only test Cubit logic
- ✅ Less boilerplate and cleaner code
- ✅ Follows Flutter best practices for declarative UI

### ✅ DO: Use StatelessWidget for EVERYTHING - Manage controllers in Cubit/BLoC

**CRITICAL RULE:** When using Cubit or BLoC for state management, **NEVER** use StatefulWidget. ALL widgets must be StatelessWidget, and ALL controllers must be managed inside the Cubit/BLoC.

**Why manage controllers in Cubit/BLoC:**
- ✅ Single source of truth - all state in one place
- ✅ Easier to test - controllers are part of Cubit state
- ✅ No StatefulWidget needed - everything is StatelessWidget
- ✅ Better separation of concerns
- ✅ Controllers can be accessed from multiple widgets
- ✅ Lifecycle managed by Cubit (automatic disposal)

```dart
// ✅ CORRECT: TextEditingController managed in Cubit
class SearchCubit extends Cubit<SearchState> {
  final TextEditingController searchController = TextEditingController();
  final ProductRepository repository;

  SearchCubit({required this.repository}) : super(const SearchState.initial());

  void searchProducts(String query) {
    emit(SearchState.loading());
    // Use controller value or passed query
    final searchQuery = query.isEmpty ? searchController.text : query;
    // Search logic...
  }

  void clearSearch() {
    searchController.clear();
    emit(const SearchState.initial());
  }

  @override
  Future<void> close() {
    searchController.dispose(); // ✅ Disposed in Cubit
    return super.close();
  }
}

// ✅ CORRECT: StatelessWidget using controller from Cubit
class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();

    return TextField(
      controller: cubit.searchController, // ✅ Controller from Cubit
      decoration: const InputDecoration(labelText: 'Search'),
      onSubmitted: cubit.searchProducts,
    );
  }
}

// ✅ CORRECT: AnimationController managed in Cubit
class ProductAnimationCubit extends Cubit<ProductAnimationState> {
  late final AnimationController animationController;

  ProductAnimationCubit({required TickerProvider vsync})
      : super(const ProductAnimationState.initial()) {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );
  }

  void startAnimation() {
    animationController.forward();
    emit(const ProductAnimationState.animating());
  }

  void resetAnimation() {
    animationController.reset();
    emit(const ProductAnimationState.initial());
  }

  @override
  Future<void> close() {
    animationController.dispose(); // ✅ Disposed in Cubit
    return super.close();
  }
}

// ✅ CORRECT: StatelessWidget using animation from Cubit
class AnimatedProductCard extends StatelessWidget {
  final Product product;

  const AnimatedProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductAnimationCubit>();

    return FadeTransition(
      opacity: cubit.animationController, // ✅ Controller from Cubit
      child: ProductCard(product: product),
    );
  }
}

// ✅ CORRECT: Form with multiple controllers in Cubit
class LoginCubit extends Cubit<LoginState> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final AuthRepository repository;

  LoginCubit({required this.repository}) : super(const LoginState.initial());

  Future<void> login() async {
    emit(const LoginState.loading());

    final email = emailController.text;
    final password = passwordController.text;

    final result = await repository.login(email, password);

    result.fold(
      (failure) => emit(LoginState.error(failure.message)),
      (user) => emit(LoginState.success(user)),
    );
  }

  void clearForm() {
    emailController.clear();
    passwordController.clear();
    emailFocusNode.unfocus();
    passwordFocusNode.unfocus();
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    return super.close();
  }
}
```

### When to use StatefulWidget vs StatelessWidget with Cubit:

| Use Case | Widget Type | Reason |
|----------|-------------|--------|
| **Screen/Page with Cubit** | ✅ StatelessWidget | Cubit manages ALL state |
| **Business logic state** | ✅ StatelessWidget | Cubit manages state |
| **Loading/Error states** | ✅ StatelessWidget | Cubit manages state |
| **Form validation** | ✅ StatelessWidget | Cubit manages state |
| **Bottom Navigation index** | ✅ StatelessWidget | Cubit manages state |
| **TextEditingController** | ✅ StatelessWidget | Cubit manages controller |
| **AnimationController** | ✅ StatelessWidget | Cubit manages controller |
| **TabController** | ✅ StatelessWidget | Cubit manages controller |
| **ScrollController** | ✅ StatelessWidget | Cubit manages controller |
| **FocusNode** | ✅ StatelessWidget | Cubit manages focus node |

**Key Rule:**
- ✅ Use **StatelessWidget** for EVERYTHING when using Cubit/BLoC
- ✅ Manage ALL controllers inside Cubit/BLoC
- ✅ Dispose controllers in Cubit's close() method
- ❌ NEVER use StatefulWidget when using Cubit/BLoC
- ❌ NEVER use setState() when using Cubit/BLoC
- ❌ NEVER create controllers in widgets - always in Cubit/BLoC

---

## Error Handling

### ✅ DO: Handle errors with state

```dart
// ✅ CORRECT: Error handling in Cubit
class PostsCubit extends Cubit<PostsState> {
  final GetPosts getPostsUseCase;

  PostsCubit({required this.getPostsUseCase})
      : super(const PostsState.initial());

  Future<void> loadPosts() async {
    emit(const PostsState.loading());

    final result = await getPostsUseCase(NoParams());

    result.fold(
      (failure) {
        // ✅ Emit error state with message
        emit(PostsState.error(failure.message));
      },
      (posts) {
        emit(PostsState.loaded(posts));
      },
    );
  }

  Future<void> retryLoadPosts() async {
    // Clear error and retry
    await loadPosts();
  }
}
```

### ✅ DO: Keep cached data on errors

```dart
// ✅ CORRECT: Preserve data on error
@freezed
class PostsState with _$PostsState {
  const factory PostsState.initial() = Initial;
  const factory PostsState.loading() = Loading;
  const factory PostsState.loaded(List<Post> posts) = Loaded;
  const factory PostsState.error({
    required String message,
    List<Post>? cachedPosts, // ✅ Keep cached data
  }) = Error;
}

class PostsCubit extends Cubit<PostsState> {
  Future<void> refreshPosts() async {
    final currentPosts = state.whenOrNull(
      loaded: (posts) => posts,
      error: (_, cachedPosts) => cachedPosts,
    );

    final result = await getPostsUseCase(NoParams());

    result.fold(
      (failure) => emit(PostsState.error(
        message: failure.message,
        cachedPosts: currentPosts, // ✅ Preserve data
      )),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }
}
```

---

## Testing

### ✅ DO: Use bloc_test for testing Cubits

```dart
// ✅ CORRECT: Test Cubit with bloc_test
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLogin extends Mock implements Login {}
class MockLogout extends Mock implements Logout {}
class MockGetCurrentUser extends Mock implements GetCurrentUser {}

void main() {
  late AuthCubit authCubit;
  late MockLogin mockLogin;
  late MockLogout mockLogout;
  late MockGetCurrentUser mockGetCurrentUser;

  setUp(() {
    mockLogin = MockLogin();
    mockLogout = MockLogout();
    mockGetCurrentUser = MockGetCurrentUser();
    authCubit = AuthCubit(
      loginUseCase: mockLogin,
      logoutUseCase: mockLogout,
      getCurrentUserUseCase: mockGetCurrentUser,
    );
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit', () {
    const tUser = User(
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
    );

    test('initial state is Initial', () {
      expect(authCubit.state, const AuthState.initial());
    });

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Authenticated] when login succeeds',
      build: () {
        when(() => mockLogin(any())).thenAnswer(
          (_) async => const Right(tUser),
        );
        return authCubit;
      },
      act: (cubit) => cubit.login(
        email: 'test@example.com',
        password: 'password123',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(tUser),
      ],
      verify: (_) {
        verify(() => mockLogin(const LoginParams(
          email: 'test@example.com',
          password: 'password123',
        ))).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Error] when login fails',
      build: () {
        when(() => mockLogin(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Invalid credentials')),
        );
        return authCubit;
      },
      act: (cubit) => cubit.login(
        email: 'test@example.com',
        password: 'wrong',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('Invalid credentials'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Unauthenticated] when logout succeeds',
      build: () {
        when(() => mockLogout(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return authCubit;
      },
      seed: () => const AuthState.authenticated(tUser),
      act: (cubit) => cubit.logout(),
      expect: () => [
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ],
    );
  });
}
```

### ✅ DO: Test state transitions

```dart
// ✅ CORRECT: Test multiple state transitions
blocTest<CounterCubit, CounterState>(
  'increments counter from 0 to 3',
  build: () => CounterCubit(),
  act: (cubit) {
    cubit.increment();
    cubit.increment();
    cubit.increment();
  },
  expect: () => [
    const CounterState(count: 1, isLoading: false),
    const CounterState(count: 2, isLoading: false),
    const CounterState(count: 3, isLoading: false),
  ],
);

blocTest<CounterCubit, CounterState>(
  'resets counter to 0',
  build: () => CounterCubit(),
  seed: () => const CounterState(count: 5, isLoading: false),
  act: (cubit) => cubit.reset(),
  expect: () => [
    CounterState.initial(),
  ],
);
```

---

## Migration from BLoC

### Step 1: Remove Events

```dart
// Before (BLoC)
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = LoginRequested;
}

// After (Cubit) - No events needed
```

### Step 2: Convert BLoC to Cubit

```dart
// Before (BLoC)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    // Login logic
  }
}

// After (Cubit)
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.initial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    // Login logic
  }
}
```

### Step 3: Update UI calls

```dart
// Before (BLoC)
context.read<AuthBloc>().add(const AuthEvent.loginRequested(
  email: 'test@example.com',
  password: 'password',
));

// After (Cubit)
context.read<AuthCubit>().login(
  email: 'test@example.com',
  password: 'password',
);
```

### Step 4: Update providers

```dart
// Before (BLoC)
BlocProvider(
  create: (_) => AuthBloc(),
  child: LoginView(),
)

// After (Cubit)
BlocProvider(
  create: (_) => AuthCubit(),
  child: LoginView(),
)
```

---

## Best Practices

### ✅ DO: Keep Cubits simple and focused

```dart
// ✅ CORRECT: Simple, focused Cubit
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}
```

### ✅ DO: Use Cubit for simple state management

```dart
// ✅ CORRECT: Cubit for toggle state
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  void toggleTheme() {
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  void setTheme(ThemeMode mode) {
    emit(mode);
  }
}
```

### ✅ DO: Delegate business logic to use cases

```dart
// ✅ CORRECT: Cubit delegates to use cases
class PostsCubit extends Cubit<PostsState> {
  final GetPosts getPostsUseCase;
  final CreatePost createPostUseCase;
  final DeletePost deletePostUseCase;

  PostsCubit({
    required this.getPostsUseCase,
    required this.createPostUseCase,
    required this.deletePostUseCase,
  }) : super(const PostsState.initial());

  Future<void> loadPosts() async {
    emit(const PostsState.loading());

    // ✅ Delegate to use case
    final result = await getPostsUseCase(NoParams());

    result.fold(
      (failure) => emit(PostsState.error(failure.message)),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }
}
```

### ❌ DON'T: Put business logic in Cubit

```dart
// ❌ INCORRECT: Business logic in Cubit
class BadPostsCubit extends Cubit<PostsState> {
  final http.Client client;

  BadPostsCubit(this.client) : super(const PostsState.initial());

  Future<void> loadPosts() async {
    emit(const PostsState.loading());

    // ❌ Business logic in Cubit
    try {
      final response = await client.get(
        Uri.parse('https://api.example.com/posts'),
      );

      if (response.statusCode == 200) {
        final posts = (jsonDecode(response.body) as List)
            .map((json) => Post.fromJson(json))
            .toList();
        emit(PostsState.loaded(posts));
      } else {
        emit(const PostsState.error('Failed to load posts'));
      }
    } catch (e) {
      emit(PostsState.error(e.toString()));
    }
  }
}
```

**Why it matters:**
- ❌ Can't test business logic independently
- ❌ Cubit becomes tightly coupled
- ❌ Hard to reuse logic
- ✅ Use cases keep Cubit focused

### ✅ DO: Close Cubits when done

```dart
// ✅ CORRECT: BlocProvider automatically closes Cubit
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: CounterView(),
    ); // ✅ Cubit automatically closed when widget disposed
  }
}
```

### ✅ DO: Use const constructors for states

```dart
// ✅ CORRECT: Const states
const factory AuthState.loading() = Loading;
const factory AuthState.authenticated(User user) = Authenticated;
```

---

## Summary

### Quick Reference

**When to Use:**
- ✅ Simple to medium complexity
- ✅ Straightforward state changes
- ✅ Don't need event transformers
- ✅ Want less boilerplate
- ❌ Use BLoC for complex event handling

**Implementation:**
- ✅ Extend Cubit<State>
- ✅ Use methods instead of events
- ✅ Use emit() to change states
- ✅ Check isClosed before emitting
- ❌ Don't modify state directly

**UI Integration:**
- ✅ Use BlocProvider to provide Cubit
- ✅ Use BlocBuilder for UI updates
- ✅ Use context.read() for method calls
- ✅ Use context.watch() for reactive updates
- ❌ Don't use watch() in callbacks

**Error Handling:**
- ✅ Handle errors with state
- ✅ Keep cached data on errors
- ✅ Provide retry mechanisms
- ❌ Don't ignore errors

**Testing:**
- ✅ Use bloc_test for testing
- ✅ Mock dependencies
- ✅ Test all state transitions
- ✅ Verify use case calls

**Best Practices:**
- ✅ Keep Cubits simple and focused
- ✅ Delegate business logic to use cases
- ✅ Close Cubits when done
- ✅ Use const constructors
- ❌ Don't put business logic in Cubit

**Migration from BLoC:**
1. Remove event classes
2. Convert Bloc to Cubit
3. Replace event handlers with methods
4. Update UI to call methods instead of adding events
5. Update providers (BlocProvider works for both)

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0
