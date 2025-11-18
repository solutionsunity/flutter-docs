---
type: "agent_requested"
description: "Functional programming patterns using Dartz including Either/Option types, failure handling hierarchy, functional composition, and integration with repositories and use cases."
---

# Dartz Functional Programming Guide

> **Comprehensive guide for functional programming with Dartz in Flutter**

---

## Table of Contents
- [Overview](#overview)
- [Either Type](#either-type)
- [Option Type](#option-type)
- [Failure Handling](#failure-handling)
- [Functional Composition](#functional-composition)
- [Common Patterns](#common-patterns)
- [Best Practices](#best-practices)

---

## Overview

**Dartz** is a functional programming library for Dart that provides:
- `Either<L, R>` - Represents a value of one of two possible types
- `Option<T>` - Represents an optional value (alternative to null)
- Functional utilities (map, flatMap, fold, etc.)
- Immutable data structures

**Use Dartz when:**
- ✅ Building applications with Clean Architecture
- ✅ Need explicit error handling without exceptions
- ✅ Want to leverage functional programming patterns
- ✅ Require composable error handling
- ✅ Building large-scale applications

**Don't use Dartz when:**
- ❌ Building simple apps or MVPs
- ❌ Team is unfamiliar with functional programming
- ❌ Need rapid prototyping
- ❌ App has minimal error handling needs

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  dartz: ^0.10.1
```

---

## Either Type

The `Either<L, R>` type represents a value that can be either **Left** (typically an error) or **Right** (typically a success value).

**Convention:**
- `Left` = Failure/Error
- `Right` = Success/Value

### ✅ DO: Use Either for operations that can fail

```dart
// ✅ CORRECT: Either for error handling
import 'package:dartz/dartz.dart';

// Define failure types
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

// Repository method returning Either
class UserRepository {
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      if (!await _networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }
      
      final response = await _apiClient.get('/users/$id');
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        return Right(user);
      } else if (response.statusCode == 404) {
        return const Left(ServerFailure('User not found'));
      } else {
        return const Left(ServerFailure('Failed to fetch user'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
  
  Future<Either<Failure, void>> updateUser(User user) async {
    // Validate before making API call
    final validationResult = _validateUser(user);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }
    
    try {
      await _apiClient.put('/users/${user.id}', data: user.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update user'));
    }
  }
  
  String? _validateUser(User user) {
    if (user.name.isEmpty) {
      return 'Name cannot be empty';
    }
    if (user.email.isEmpty) {
      return 'Email cannot be empty';
    }
    if (!user.email.contains('@')) {
      return 'Invalid email format';
    }
    return null;
  }
}
```

### ❌ DON'T: Use exceptions for expected errors

```dart
// ❌ INCORRECT: Using exceptions for control flow
class BadUserRepository {
  Future<User> getUser(String id) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection'); // ❌ Exception for expected error
    }
    
    final response = await _apiClient.get('/users/$id');
    
    if (response.statusCode == 404) {
      throw NotFoundException('User not found'); // ❌ Exception for expected error
    }
    
    return User.fromJson(response.data);
  }
}
```

**Why it matters:**
- ❌ Exceptions are for unexpected errors
- ❌ Forces try-catch everywhere
- ❌ Easy to forget error handling
- ✅ Either makes errors explicit and type-safe

---

### Handling Either Results

#### ✅ DO: Use fold() to handle both cases

```dart
// ✅ CORRECT: Using fold to handle both success and failure
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUser getUserUseCase;
  
  UserBloc(this.getUserUseCase) : super(const UserState.initial()) {
    on<LoadUser>(_onLoadUser);
  }
  
  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserState.loading());
    
    final result = await getUserUseCase(event.userId);
    
    // ✅ fold handles both Left and Right
    result.fold(
      (failure) => emit(UserState.error(failure.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
}
```

```dart
// ✅ CORRECT: Using fold to return a value
String getUserDisplayName(Either<Failure, User> result) {
  return result.fold(
    (failure) => 'Unknown User', // Left case
    (user) => user.name,          // Right case
  );
}
```

#### ✅ DO: Use getOrElse() for default values

```dart
// ✅ CORRECT: Provide default value on failure
Future<User> getUserOrDefault(String userId) async {
  final result = await userRepository.getUser(userId);
  
  return result.getOrElse(
    () => User.guest(), // Default user if failed
  );
}
```

#### ✅ DO: Use map() to transform success values

```dart
// ✅ CORRECT: Transform the Right value
Future<Either<Failure, String>> getUserName(String userId) async {
  final result = await userRepository.getUser(userId);
  
  // Transform User to String (only if Right)
  return result.map((user) => user.name);
}
```

#### ✅ DO: Use flatMap() (bind) for chaining operations

```dart
// ✅ CORRECT: Chain multiple Either-returning operations
Future<Either<Failure, Post>> createPost({
  required String userId,
  required String title,
  required String content,
}) async {
  // Get user, then create post
  final result = await userRepository.getUser(userId);

  return result.flatMap((user) async {
    // Only executes if getUser succeeded
    if (!user.canPost) {
      return const Left(ValidationFailure('User cannot create posts'));
    }

    return await postRepository.createPost(
      authorId: user.id,
      title: title,
      content: content,
    );
  });
}
```

```dart
// ✅ CORRECT: Multiple chained operations
Future<Either<Failure, String>> getUserPostTitle(
  String userId,
  String postId,
) async {
  return (await userRepository.getUser(userId))
      .flatMap((user) => postRepository.getPost(postId))
      .map((post) => post.title);
}
```

#### ❌ DON'T: Nest fold() calls

```dart
// ❌ INCORRECT: Nested fold is hard to read
Future<void> badExample(String userId) async {
  final userResult = await userRepository.getUser(userId);

  userResult.fold(
    (failure) => print('Error: ${failure.message}'),
    (user) async {
      final postsResult = await postRepository.getUserPosts(user.id);

      postsResult.fold( // ❌ Nested fold
        (failure) => print('Error: ${failure.message}'),
        (posts) => print('Posts: $posts'),
      );
    },
  );
}
```

```dart
// ✅ CORRECT: Use flatMap instead
Future<Either<Failure, List<Post>>> getUserPosts(String userId) async {
  return (await userRepository.getUser(userId))
      .flatMap((user) => postRepository.getUserPosts(user.id));
}
```

**Why it matters:**
- ❌ Nested fold is hard to read and maintain
- ❌ Error handling becomes complex
- ✅ flatMap keeps code flat and composable

---

## Option Type

The `Option<T>` type represents an optional value - either `Some(value)` or `None`.

### ✅ DO: Use Option instead of nullable types

```dart
// ✅ CORRECT: Option for optional values
import 'package:dartz/dartz.dart';

class UserProfile {
  final String id;
  final String name;
  final Option<String> bio;        // Optional bio
  final Option<String> avatarUrl;  // Optional avatar
  final Option<DateTime> birthDate; // Optional birth date

  const UserProfile({
    required this.id,
    required this.name,
    required this.bio,
    required this.avatarUrl,
    required this.birthDate,
  });

  // Helper to get bio or default
  String getBioOrDefault() {
    return bio.getOrElse(() => 'No bio available');
  }

  // Check if user has avatar
  bool get hasAvatar => avatarUrl.isSome();

  // Get age if birth date is available
  Option<int> get age {
    return birthDate.map((date) {
      final now = DateTime.now();
      return now.year - date.year;
    });
  }
}
```

```dart
// ✅ CORRECT: Repository returning Option
class UserRepository {
  Future<Option<User>> findUserByEmail(String email) async {
    try {
      final response = await _apiClient.get('/users/search?email=$email');

      if (response.statusCode == 200 && response.data != null) {
        return Some(User.fromJson(response.data));
      } else {
        return const None();
      }
    } catch (e) {
      return const None();
    }
  }
}
```

### ❌ DON'T: Use null for optional values in domain layer

```dart
// ❌ INCORRECT: Nullable types in domain
class BadUserProfile {
  final String id;
  final String name;
  final String? bio;        // ❌ Nullable
  final String? avatarUrl;  // ❌ Nullable

  BadUserProfile({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
  });

  String getBio() {
    return bio ?? 'No bio available'; // ❌ Null check everywhere
  }
}
```

**Why it matters:**
- ❌ Null checks scattered throughout code
- ❌ Easy to forget null checks
- ❌ No functional composition
- ✅ Option provides functional operations

---

### Working with Option

#### ✅ DO: Use Option methods for transformations

```dart
// ✅ CORRECT: Option transformations
class UserService {
  // Transform Option value
  Option<String> getUppercaseBio(UserProfile profile) {
    return profile.bio.map((bio) => bio.toUpperCase());
  }

  // Filter Option value
  Option<String> getLongBio(UserProfile profile) {
    return profile.bio.filter((bio) => bio.length > 100);
  }

  // Provide default value
  String getBioOrDefault(UserProfile profile) {
    return profile.bio.getOrElse(() => 'No bio');
  }

  // Check if value exists
  bool hasBio(UserProfile profile) {
    return profile.bio.isSome();
  }

  // Pattern matching with fold
  String formatBio(UserProfile profile) {
    return profile.bio.fold(
      () => 'User has not added a bio yet',  // None case
      (bio) => 'Bio: $bio',                   // Some case
    );
  }
}
```

#### ✅ DO: Convert between Option and nullable

```dart
// ✅ CORRECT: Converting between Option and nullable
class Converters {
  // Nullable to Option
  Option<String> nullableToOption(String? value) {
    return optionOf(value); // Returns Some(value) or None
  }

  // Option to nullable
  String? optionToNullable(Option<String> option) {
    return option.toNullable();
  }

  // Example usage
  void example() {
    String? nullableValue = 'Hello';
    Option<String> option = optionOf(nullableValue); // Some('Hello')

    String? backToNullable = option.toNullable(); // 'Hello'

    Option<String> noneOption = optionOf(null); // None
    String? nullValue = noneOption.toNullable(); // null
  }
}
```

---

## Failure Handling

### ✅ DO: Create a hierarchy of failure types

```dart
// ✅ CORRECT: Failure hierarchy
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection'])
      : super(message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Request timed out'])
      : super(message);
}

// Server failures
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(String message, [this.statusCode]) : super(message);

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class UnauthorizedFailure extends ServerFailure {
  const UnauthorizedFailure([String message = 'Unauthorized'])
      : super(message, 401);
}

class NotFoundFailure extends ServerFailure {
  const NotFoundFailure([String message = 'Resource not found'])
      : super(message, 404);
}

// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(String message, [this.fieldErrors]) : super(message);

  @override
  List<Object> get props => [message, fieldErrors ?? {}];
}

// Cache failures
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error']) : super(message);
}

// Unexpected failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'An unexpected error occurred'])
      : super(message);
}
```

### ✅ DO: Map exceptions to failures

```dart
// ✅ CORRECT: Exception to Failure mapping
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  Future<Either<Failure, T>> safeApiCall<T>(
    Future<T> Function() apiCall,
  ) async {
    try {
      final result = await apiCall();
      return Right(result);
    } on SocketException {
      return const Left(NetworkFailure('No internet connection'));
    } on HttpException {
      return const Left(ServerFailure('Server error'));
    } on FormatException {
      return const Left(ServerFailure('Invalid response format'));
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: $e'));
    }
  }
}

// Usage
class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<Either<Failure, User>> getUser(String id) async {
    return _apiClient.safeApiCall(() async {
      final response = await http.get(Uri.parse('/users/$id'));

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw const NotFoundFailure('User not found');
      } else {
        throw ServerFailure('Failed to fetch user', response.statusCode);
      }
    });
  }
}
```

---

## Functional Composition

### ✅ DO: Compose multiple operations

```dart
// ✅ CORRECT: Functional composition
class UserService {
  final UserRepository userRepository;
  final PostRepository postRepository;
  final AnalyticsService analyticsService;

  UserService({
    required this.userRepository,
    required this.postRepository,
    required this.analyticsService,
  });

  // Compose multiple Either operations
  Future<Either<Failure, UserStats>> getUserStats(String userId) async {
    return (await userRepository.getUser(userId))
        .flatMap((user) async {
          final postsResult = await postRepository.getUserPosts(user.id);
          return postsResult.map((posts) => (user, posts));
        })
        .map((tuple) {
          final (user, posts) = tuple;
          return UserStats(
            user: user,
            postCount: posts.length,
            totalLikes: posts.fold(0, (sum, post) => sum + post.likes),
          );
        });
  }

  // Parallel operations with Either
  Future<Either<Failure, UserDashboard>> getUserDashboard(
    String userId,
  ) async {
    final userResult = await userRepository.getUser(userId);

    return userResult.flatMap((user) async {
      // Execute multiple operations in parallel
      final results = await Future.wait([
        postRepository.getUserPosts(user.id),
        postRepository.getUserDrafts(user.id),
        analyticsService.getUserAnalytics(user.id),
      ]);

      // Combine results
      final postsResult = results[0] as Either<Failure, List<Post>>;
      final draftsResult = results[1] as Either<Failure, List<Post>>;
      final analyticsResult = results[2] as Either<Failure, Analytics>;

      // Check if all succeeded
      return postsResult.flatMap((posts) {
        return draftsResult.flatMap((drafts) {
          return analyticsResult.map((analytics) {
            return UserDashboard(
              user: user,
              posts: posts,
              drafts: drafts,
              analytics: analytics,
            );
          });
        });
      });
    });
  }
}
```

### ✅ DO: Create helper functions for common patterns

```dart
// ✅ CORRECT: Helper functions for Either
extension EitherExtensions<L, R> on Either<L, R> {
  // Execute side effect only on Right
  Either<L, R> onRight(void Function(R value) action) {
    return fold(
      (left) => Left(left),
      (right) {
        action(right);
        return Right(right);
      },
    );
  }

  // Execute side effect only on Left
  Either<L, R> onLeft(void Function(L value) action) {
    return fold(
      (left) {
        action(left);
        return Left(left);
      },
      (right) => Right(right),
    );
  }

  // Convert to Future
  Future<Either<L, R>> toFuture() async => this;
}

// Usage
Future<void> example() async {
  final result = await userRepository.getUser('123')
      .onRight((user) => print('User loaded: ${user.name}'))
      .onLeft((failure) => print('Error: ${failure.message}'));
}
```

---

## Common Patterns

### Pattern 1: Validation with Either

#### ✅ DO: Use Either for validation

```dart
// ✅ CORRECT: Validation returning Either
class UserValidator {
  Either<ValidationFailure, User> validateUser({
    required String name,
    required String email,
    required String password,
  }) {
    // Validate name
    if (name.isEmpty) {
      return const Left(ValidationFailure('Name cannot be empty'));
    }
    if (name.length < 2) {
      return const Left(ValidationFailure('Name must be at least 2 characters'));
    }

    // Validate email
    if (email.isEmpty) {
      return const Left(ValidationFailure('Email cannot be empty'));
    }
    if (!email.contains('@')) {
      return const Left(ValidationFailure('Invalid email format'));
    }

    // Validate password
    if (password.isEmpty) {
      return const Left(ValidationFailure('Password cannot be empty'));
    }
    if (password.length < 8) {
      return const Left(ValidationFailure('Password must be at least 8 characters'));
    }

    // All validations passed
    return Right(User(
      name: name,
      email: email,
      password: password,
    ));
  }
}

// Usage in BLoC
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final UserValidator validator;
  final AuthRepository authRepository;

  SignUpBloc({
    required this.validator,
    required this.authRepository,
  }) : super(const SignUpState.initial()) {
    on<SignUpSubmitted>(_onSignUpSubmitted);
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    emit(const SignUpState.loading());

    // Validate first
    final validationResult = validator.validateUser(
      name: event.name,
      email: event.email,
      password: event.password,
    );

    // Chain validation with sign up
    final result = await validationResult.fold(
      (failure) async => Left<Failure, User>(failure),
      (user) => authRepository.signUp(user),
    );

    result.fold(
      (failure) => emit(SignUpState.error(failure.message)),
      (user) => emit(SignUpState.success(user)),
    );
  }
}
```

### Pattern 2: Combining Multiple Either Results

#### ✅ DO: Use helper to combine Either results

```dart
// ✅ CORRECT: Combine multiple Either results
Either<Failure, T> combine2<T>(
  Either<Failure, dynamic> e1,
  Either<Failure, dynamic> e2,
  T Function(dynamic, dynamic) combiner,
) {
  return e1.flatMap((v1) {
    return e2.map((v2) => combiner(v1, v2));
  });
}

Either<Failure, T> combine3<T>(
  Either<Failure, dynamic> e1,
  Either<Failure, dynamic> e2,
  Either<Failure, dynamic> e3,
  T Function(dynamic, dynamic, dynamic) combiner,
) {
  return e1.flatMap((v1) {
    return e2.flatMap((v2) {
      return e3.map((v3) => combiner(v1, v2, v3));
    });
  });
}

// Usage
Future<Either<Failure, CompleteProfile>> getCompleteProfile(
  String userId,
) async {
  final userResult = await userRepository.getUser(userId);
  final postsResult = await postRepository.getUserPosts(userId);
  final followersResult = await socialRepository.getFollowers(userId);

  return combine3(
    userResult,
    postsResult,
    followersResult,
    (user, posts, followers) => CompleteProfile(
      user: user,
      posts: posts,
      followers: followers,
    ),
  );
}
```

### Pattern 3: Retry Logic with Either

#### ✅ DO: Implement retry with Either

```dart
// ✅ CORRECT: Retry logic
Future<Either<Failure, T>> retryOperation<T>(
  Future<Either<Failure, T>> Function() operation, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  int attempts = 0;

  while (attempts < maxAttempts) {
    final result = await operation();

    final shouldRetry = result.fold(
      (failure) => failure is NetworkFailure || failure is TimeoutFailure,
      (_) => false,
    );

    if (!shouldRetry) {
      return result;
    }

    attempts++;
    if (attempts < maxAttempts) {
      await Future.delayed(delay * attempts); // Exponential backoff
    }
  }

  return const Left(NetworkFailure('Max retry attempts reached'));
}

// Usage
Future<Either<Failure, User>> getUserWithRetry(String userId) async {
  return retryOperation(
    () => userRepository.getUser(userId),
    maxAttempts: 3,
  );
}
```

---

## Best Practices

### ✅ DO: Keep Either in domain and data layers

```dart
// ✅ CORRECT: Either in repository (data layer)
class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<Failure, User>> getUser(String id) async {
    // Implementation
  }
}

// ✅ CORRECT: Either in use case (domain layer)
class GetUser implements UseCase<User, String> {
  final UserRepository repository;

  GetUser(this.repository);

  @override
  Future<Either<Failure, User>> call(String userId) {
    return repository.getUser(userId);
  }
}

// ✅ CORRECT: Either in BLoC (presentation layer)
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUser getUserUseCase;

  UserBloc(this.getUserUseCase) : super(const UserState.initial()) {
    on<LoadUser>(_onLoadUser);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserState.loading());

    final result = await getUserUseCase(event.userId);

    result.fold(
      (failure) => emit(UserState.error(failure.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
}
```

### ❌ DON'T: Expose Either to UI widgets

```dart
// ❌ INCORRECT: Either in widget
class UserProfileWidget extends StatelessWidget {
  final Either<Failure, User> userResult; // ❌ Don't expose Either to UI

  @override
  Widget build(BuildContext context) {
    return userResult.fold(
      (failure) => Text('Error: ${failure.message}'),
      (user) => Text(user.name),
    );
  }
}
```

```dart
// ✅ CORRECT: Convert Either to state in BLoC
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = Initial;
  const factory UserState.loading() = Loading;
  const factory UserState.loaded(User user) = Loaded;
  const factory UserState.error(String message) = Error;
}

class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox(),
          loading: () => const CircularProgressIndicator(),
          loaded: (user) => Text(user.name),
          error: (message) => Text('Error: $message'),
        );
      },
    );
  }
}
```

---

## Summary

### Quick Reference

**Either Type:**
- ✅ Use Either<Failure, Success> for operations that can fail
- ✅ Left = Failure, Right = Success
- ✅ Use fold() to handle both cases
- ✅ Use flatMap() to chain operations
- ❌ Don't use exceptions for expected errors
- ❌ Don't nest fold() calls

**Option Type:**
- ✅ Use Option<T> for optional values in domain layer
- ✅ Use map(), filter(), fold() for transformations
- ✅ Use getOrElse() for default values
- ❌ Don't use nullable types in domain layer
- ❌ Don't scatter null checks

**Failure Handling:**
- ✅ Create a hierarchy of failure types
- ✅ Map exceptions to failures
- ✅ Use Equatable for failure comparison
- ❌ Don't expose raw exceptions
- ❌ Don't use generic error messages

**Composition:**
- ✅ Chain operations with flatMap()
- ✅ Transform values with map()
- ✅ Create helper functions for common patterns
- ✅ Use extension methods for convenience
- ❌ Don't create deeply nested structures

**Best Practices:**
- ✅ Keep Either in domain and data layers
- ✅ Convert Either to state in presentation layer
- ✅ Use retry logic for network operations
- ✅ Validate with Either before API calls
- ❌ Don't expose Either to UI widgets

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0



