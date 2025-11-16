---
type: "agent_requested"
description: "Example description"
---

# BLoC Pattern Guide

> **Comprehensive guide for implementing the BLoC (Business Logic Component) pattern in Flutter**

---

## Table of Contents
- [Overview](#overview)
- [Core Concepts](#core-concepts)
- [Events](#events)
- [States](#states)
- [BLoC Implementation](#bloc-implementation)
- [UI Integration](#ui-integration)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Best Practices](#best-practices)

---

## Overview

**BLoC (Business Logic Component)** is a state management pattern that:
- Separates business logic from UI
- Uses streams for reactive programming
- Follows event-driven architecture
- Provides predictable state management

**Use BLoC when:**
- ✅ Building medium to large applications
- ✅ Need clear separation of concerns
- ✅ Want predictable state management
- ✅ Require testable business logic
- ✅ Team is familiar with reactive programming

**Don't use BLoC when:**
- ❌ Building simple apps or MVPs
- ❌ Team is unfamiliar with streams
- ❌ Need rapid prototyping
- ❌ App has minimal state management needs (use Cubit instead)

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  freezed_annotation: ^2.4.1

dev_dependencies:
  bloc_test: ^9.1.4
  freezed: ^2.4.5
  build_runner: ^2.4.6
```

---

## Core Concepts

### The BLoC Flow

```
UI Event → BLoC → Business Logic → New State → UI Update
```

**Key Components:**
1. **Events** - User actions or system events
2. **States** - UI states representing different conditions
3. **BLoC** - Business logic that transforms events into states
4. **Widgets** - UI components that react to state changes

---

## Events

Events represent user actions or system events that trigger state changes.

### ✅ DO: Use Freezed for immutable events

```dart
// ✅ CORRECT: Freezed events with union types
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = LoginRequested;
  
  const factory AuthEvent.signUpRequested({
    required String email,
    required String password,
    required String name,
  }) = SignUpRequested;
  
  const factory AuthEvent.logoutRequested() = LogoutRequested;
  
  const factory AuthEvent.passwordResetRequested({
    required String email,
  }) = PasswordResetRequested;
  
  const factory AuthEvent.authStatusChecked() = AuthStatusChecked;
}
```

### ✅ DO: Use Equatable for simple events

```dart
// ✅ CORRECT: Equatable events (alternative to Freezed)
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

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}
```

### ❌ DON'T: Create mutable events

```dart
// ❌ INCORRECT: Mutable event
class BadLoginEvent {
  String email;    // ❌ Mutable
  String password; // ❌ Mutable
  
  BadLoginEvent(this.email, this.password);
}
```

**Why it matters:**
- ❌ Mutable events can be changed unexpectedly
- ❌ Hard to debug state changes
- ❌ Can't use equality comparison
- ✅ Immutable events are predictable and testable

---

## States

States represent different conditions of the UI.

### ✅ DO: Use Freezed for union states

```dart
// ✅ CORRECT: Freezed states with union types
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

### ✅ DO: Include data in states when needed

```dart
// ✅ CORRECT: States with data
@freezed
class PostsState with _$PostsState {
  const factory PostsState.initial() = Initial;
  
  const factory PostsState.loading() = Loading;
  
  const factory PostsState.loaded({
    required List<Post> posts,
    required bool hasMore,
    required int currentPage,
  }) = Loaded;
  
  const factory PostsState.loadingMore({
    required List<Post> posts,
    required int currentPage,
  }) = LoadingMore;
  
  const factory PostsState.error({
    required String message,
    List<Post>? cachedPosts, // Keep cached data on error
  }) = Error;
}
```

### ❌ DON'T: Use boolean flags for states

```dart
// ❌ INCORRECT: Boolean flags instead of proper states
class BadAuthState {
  final bool isLoading;     // ❌ Boolean flag
  final bool isAuthenticated; // ❌ Boolean flag
  final bool hasError;      // ❌ Boolean flag
  final User? user;
  final String? errorMessage;
  
  BadAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.hasError = false,
    this.user,
    this.errorMessage,
  });
}
```

**Why it matters:**
- ❌ Can have invalid state combinations (loading + error)
- ❌ Hard to handle all cases in UI
- ❌ No compile-time safety
- ✅ Union states prevent invalid combinations

---

## BLoC Implementation

### ✅ DO: Use event handlers with on<Event>

```dart
// ✅ CORRECT: BLoC with event handlers
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../../core/usecases/usecase.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Login loginUseCase;
  final Logout logoutUseCase;
  final GetCurrentUser getCurrentUserUseCase;
  
  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthState.initial()) {
    // Register event handlers
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await loginUseCase(
      LoginParams(
        email: event.email,
        password: event.password,
      ),
    );
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
  
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await logoutUseCase(NoParams());
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }
  
  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await getCurrentUserUseCase(NoParams());
    
    result.fold(
      (_) => emit(const AuthState.unauthenticated()),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
}
```

### ❌ DON'T: Put business logic directly in event handlers

```dart
// ❌ INCORRECT: Business logic in BLoC
class BadAuthBloc extends Bloc<AuthEvent, AuthState> {
  final http.Client client; // ❌ Direct dependency

  BadAuthBloc(this.client) : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    // ❌ Business logic and API calls in BLoC
    try {
      final response = await client.post(
        Uri.parse('https://api.example.com/login'),
        body: jsonEncode({
          'email': event.email,
          'password': event.password,
        }),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Login failed'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }
}
```

**Why it matters:**
- ❌ Can't test business logic independently
- ❌ BLoC becomes tightly coupled
- ❌ Hard to reuse logic
- ✅ Use cases keep BLoC focused on state management

---

### ✅ DO: Use transformers for event debouncing/throttling

```dart
// ✅ CORRECT: Debounce search events
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchPosts searchPostsUseCase;

  SearchBloc({required this.searchPostsUseCase})
      : super(const SearchState.initial()) {
    // Debounce search events
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );

    // Throttle load more events
    on<LoadMoreResults>(
      _onLoadMoreResults,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const SearchState.initial());
      return;
    }

    emit(const SearchState.loading());

    final result = await searchPostsUseCase(SearchParams(query: event.query));

    result.fold(
      (failure) => emit(SearchState.error(failure.message)),
      (posts) => emit(SearchState.loaded(posts)),
    );
  }

  Future<void> _onLoadMoreResults(
    LoadMoreResults event,
    Emitter<SearchState> emit,
  ) async {
    // Implementation
  }
}

// Transformer helpers
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

EventTransformer<E> throttle<E>(Duration duration) {
  return (events, mapper) => events.throttle(duration).switchMap(mapper);
}
```

---

## UI Integration

### ✅ DO: Use BlocProvider to provide BLoC

```dart
// ✅ CORRECT: Provide BLoC with BlocProvider
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection_container.dart' as di;

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthBloc>()
        ..add(const AuthEvent.authStatusChecked()),
      child: const LoginView(),
    );
  }
}
```

### ✅ DO: Use BlocBuilder for UI updates

```dart
// ✅ CORRECT: BlocBuilder for reactive UI
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocBuilder<AuthBloc, AuthState>(
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

### ✅ DO: Use BlocListener for side effects

```dart
// ✅ CORRECT: BlocListener for navigation and snackbars
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          loading: () {},
          authenticated: (user) {
            // Navigate to home on successful login
            Navigator.of(context).pushReplacementNamed('/home');
          },
          unauthenticated: () {},
          error: (message) {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // UI building logic
          return const LoginForm();
        },
      ),
    );
  }
}
```

### ✅ DO: Use BlocConsumer for both building and listening

```dart
// ✅ CORRECT: BlocConsumer combines builder and listener
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Side effects
        state.whenOrNull(
          authenticated: (user) {
            Navigator.of(context).pushReplacementNamed('/home');
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      },
      builder: (context, state) {
        // UI building
        return state.when(
          initial: () => const LoginForm(),
          loading: () => const Center(child: CircularProgressIndicator()),
          authenticated: (user) => const SizedBox(),
          unauthenticated: () => const LoginForm(),
          error: (_) => const LoginForm(),
        );
      },
    );
  }
}
```

### ❌ DON'T: Access BLoC directly without provider

```dart
// ❌ INCORRECT: Creating BLoC directly in widget
class BadLoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authBloc = AuthBloc( // ❌ Creating BLoC in build method
      loginUseCase: di.sl(),
      logoutUseCase: di.sl(),
      getCurrentUserUseCase: di.sl(),
    );

    return BlocBuilder<AuthBloc, AuthState>(
      bloc: authBloc,
      builder: (context, state) {
        // UI
      },
    );
  }
}
```

**Why it matters:**
- ❌ BLoC recreated on every build
- ❌ Memory leaks
- ❌ Can't access BLoC from child widgets
- ✅ BlocProvider manages lifecycle properly

---

### ✅ DO: Use buildWhen and listenWhen for optimization

```dart
// ✅ CORRECT: Optimize rebuilds with buildWhen
class PostsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsBloc, PostsState>(
      buildWhen: (previous, current) {
        // Only rebuild when posts actually change
        return previous.whenOrNull(
          loaded: (prevPosts, _, __) => current.whenOrNull(
            loaded: (currPosts, _, __) => prevPosts != currPosts,
          ) ?? true,
        ) ?? true;
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox(),
          loading: () => const CircularProgressIndicator(),
          loaded: (posts, hasMore, page) => ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) => PostItem(post: posts[index]),
          ),
          loadingMore: (posts, page) => ListView.builder(
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index < posts.length) {
                return PostItem(post: posts[index]);
              }
              return const CircularProgressIndicator();
            },
          ),
          error: (message, cachedPosts) => Text('Error: $message'),
        );
      },
    );
  }
}
```

```dart
// ✅ CORRECT: Optimize listeners with listenWhen
class PostsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<PostsBloc, PostsState>(
      listenWhen: (previous, current) {
        // Only listen to error states
        return current is Error;
      },
      listener: (context, state) {
        if (state is Error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: PostsList(),
    );
  }
}
```

---

## Error Handling

### ✅ DO: Handle errors gracefully with cached data

```dart
// ✅ CORRECT: Keep cached data on error
@freezed
class PostsState with _$PostsState {
  const factory PostsState.initial() = Initial;
  const factory PostsState.loading() = Loading;
  const factory PostsState.loaded({
    required List<Post> posts,
    required bool hasMore,
  }) = Loaded;
  const factory PostsState.error({
    required String message,
    List<Post>? cachedPosts, // ✅ Keep cached data
  }) = Error;
}

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPosts getPostsUseCase;

  PostsBloc({required this.getPostsUseCase})
      : super(const PostsState.initial()) {
    on<LoadPosts>(_onLoadPosts);
    on<RefreshPosts>(_onRefreshPosts);
  }

  Future<void> _onLoadPosts(
    LoadPosts event,
    Emitter<PostsState> emit,
  ) async {
    emit(const PostsState.loading());

    final result = await getPostsUseCase(NoParams());

    result.fold(
      (failure) => emit(PostsState.error(message: failure.message)),
      (posts) => emit(PostsState.loaded(posts: posts, hasMore: true)),
    );
  }

  Future<void> _onRefreshPosts(
    RefreshPosts event,
    Emitter<PostsState> emit,
  ) async {
    // Keep current posts while refreshing
    final currentPosts = state.whenOrNull(
      loaded: (posts, _) => posts,
    );

    final result = await getPostsUseCase(NoParams());

    result.fold(
      (failure) => emit(PostsState.error(
        message: failure.message,
        cachedPosts: currentPosts, // ✅ Preserve cached data
      )),
      (posts) => emit(PostsState.loaded(posts: posts, hasMore: true)),
    );
  }
}
```

### ✅ DO: Use BlocObserver for global error tracking

```dart
// ✅ CORRECT: BlocObserver for logging and error tracking
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    print('onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('onChange -- ${bloc.runtimeType}, $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('onError -- ${bloc.runtimeType}, $error');
    // Send to error tracking service
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('onClose -- ${bloc.runtimeType}');
  }
}

// Initialize in main.dart
void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}
```

---

## Testing

### ✅ DO: Use bloc_test for testing BLoCs

```dart
// ✅ CORRECT: Test BLoC with bloc_test
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLogin extends Mock implements Login {}
class MockLogout extends Mock implements Logout {}
class MockGetCurrentUser extends Mock implements GetCurrentUser {}

void main() {
  late AuthBloc authBloc;
  late MockLogin mockLogin;
  late MockLogout mockLogout;
  late MockGetCurrentUser mockGetCurrentUser;

  setUp(() {
    mockLogin = MockLogin();
    mockLogout = MockLogout();
    mockGetCurrentUser = MockGetCurrentUser();
    authBloc = AuthBloc(
      loginUseCase: mockLogin,
      logoutUseCase: mockLogout,
      getCurrentUserUseCase: mockGetCurrentUser,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    const tUser = User(
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
    );

    test('initial state is Initial', () {
      expect(authBloc.state, const AuthState.initial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when login succeeds',
      build: () {
        when(() => mockLogin(any())).thenAnswer(
          (_) async => const Right(tUser),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.loginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
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

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Error] when login fails',
      build: () {
        when(() => mockLogin(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Invalid credentials')),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.loginRequested(
        email: 'test@example.com',
        password: 'wrong',
      )),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when logout succeeds',
      build: () {
        when(() => mockLogout(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return authBloc;
      },
      seed: () => const AuthState.authenticated(tUser),
      act: (bloc) => bloc.add(const AuthEvent.logoutRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ],
    );
  });
}
```

---

## Best Practices

### ✅ DO: Keep BLoCs focused and single-purpose

```dart
// ✅ CORRECT: Separate BLoCs for different features
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Only handles authentication
}

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  // Only handles user profile
}

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  // Only handles posts
}
```

### ❌ DON'T: Create god BLoCs

```dart
// ❌ INCORRECT: One BLoC handling everything
class AppBloc extends Bloc<AppEvent, AppState> {
  // ❌ Handles auth, profile, posts, comments, etc.
}
```

### ✅ DO: Close BLoCs when done

```dart
// ✅ CORRECT: BlocProvider automatically closes BLoC
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostsBloc(getPostsUseCase: di.sl()),
      child: PostsView(),
    ); // ✅ BLoC automatically closed when widget disposed
  }
}
```

### ✅ DO: Use const constructors for events and states

```dart
// ✅ CORRECT: Const constructors
const factory AuthEvent.loginRequested({
  required String email,
  required String password,
}) = LoginRequested;

const factory AuthState.loading() = Loading;
```

---

## Summary

### Quick Reference

**Events:**
- ✅ Use Freezed or Equatable for immutability
- ✅ Make events descriptive and specific
- ✅ Use const constructors
- ❌ Don't create mutable events
- ❌ Don't reuse events across BLoCs

**States:**
- ✅ Use Freezed for union types
- ✅ Include necessary data in states
- ✅ Use const constructors
- ❌ Don't use boolean flags
- ❌ Don't allow invalid state combinations

**BLoC:**
- ✅ Use event handlers with on<Event>
- ✅ Delegate business logic to use cases
- ✅ Use transformers for debouncing/throttling
- ❌ Don't put business logic in BLoC
- ❌ Don't create god BLoCs

**UI Integration:**
- ✅ Use BlocProvider for providing BLoCs
- ✅ Use BlocBuilder for UI updates
- ✅ Use BlocListener for side effects
- ✅ Use buildWhen/listenWhen for optimization
- ❌ Don't create BLoCs in build methods

**Error Handling:**
- ✅ Keep cached data on errors
- ✅ Use BlocObserver for global tracking
- ✅ Show user-friendly error messages
- ❌ Don't ignore errors
- ❌ Don't crash on errors

**Testing:**
- ✅ Use bloc_test for testing
- ✅ Mock dependencies
- ✅ Test all state transitions
- ✅ Verify use case calls
- ❌ Don't skip testing

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0



