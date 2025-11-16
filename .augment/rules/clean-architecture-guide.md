---
type: "agent_requested"
description: "Example description"
---

# Clean Architecture Guide

> **Comprehensive guide for implementing Clean Architecture in Flutter applications**

---

## Table of Contents
- [Overview](#overview)
- [Core Principles](#core-principles)
- [Layer Structure](#layer-structure)
- [Domain Layer](#domain-layer)
- [Data Layer](#data-layer)
- [Presentation Layer](#presentation-layer)
- [Dependency Injection](#dependency-injection)
- [Feature-First Organization](#feature-first-organization)
- [Testing Strategy](#testing-strategy)

---

## Overview

**Clean Architecture** is a software design philosophy that separates concerns into distinct layers, making code:
- Independent of frameworks
- Testable
- Independent of UI
- Independent of databases
- Independent of external agencies

**Use Clean Architecture when:**
- ✅ Building large-scale applications (20+ screens)
- ✅ Working with teams of 5+ developers
- ✅ Need long-term maintainability (12+ months)
- ✅ Require high testability
- ✅ Have complex business logic
- ✅ Need to support multiple platforms

**Don't use Clean Architecture when:**
- ❌ Building simple apps or MVPs
- ❌ Working solo on small projects
- ❌ Need rapid prototyping
- ❌ App has minimal business logic

---

## Core Principles

### The Dependency Rule

**The Dependency Rule:** Source code dependencies must point only inward, toward higher-level policies.

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (UI, Widgets, State Management)      │
│              ↓ depends on               │
├─────────────────────────────────────────┤
│          Domain Layer                   │
│   (Entities, Use Cases, Interfaces)     │
│              ↑ depended on by           │
├─────────────────────────────────────────┤
│           Data Layer                    │
│  (Repositories, Data Sources, Models)   │
└─────────────────────────────────────────┘
```

### ✅ DO: Follow the dependency rule

```dart
// ✅ CORRECT: Dependencies point inward

// Domain Layer (innermost - no dependencies)
abstract class UserRepository {
  Future<User> getUser(String id);
}

class User {
  final String id;
  final String name;
  
  const User({required this.id, required this.name});
}

// Data Layer (depends on Domain)
class UserRepositoryImpl implements UserRepository {
  final RemoteDataSource remoteDataSource;
  
  UserRepositoryImpl(this.remoteDataSource);
  
  @override
  Future<User> getUser(String id) async {
    final userModel = await remoteDataSource.fetchUser(id);
    return userModel.toEntity(); // Convert model to entity
  }
}

// Presentation Layer (depends on Domain)
class GetUserUseCase {
  final UserRepository repository;
  
  GetUserUseCase(this.repository);
  
  Future<User> call(String id) {
    return repository.getUser(id);
  }
}
```

### ❌ DON'T: Let inner layers depend on outer layers

```dart
// ❌ INCORRECT: Domain layer depends on Data layer

// Domain Layer
import 'package:my_app/data/models/user_model.dart'; // ❌ Wrong!

class GetUserUseCase {
  Future<UserModel> call(String id) { // ❌ Using Data layer model
    // ❌ Domain should not know about Data layer
  }
}
```

**Why it matters:**
- ❌ Tight coupling between layers
- ❌ Can't test domain logic independently
- ❌ Hard to change data sources
- ✅ Proper dependencies enable independent testing

---

## Layer Structure

### ✅ DO: Organize code into three distinct layers

```
lib/
├── core/                          # Shared code across features
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   └── network_info.dart
│   ├── usecases/
│   │   └── usecase.dart
│   └── utils/
│       ├── constants.dart
│       └── extensions.dart
├── features/                      # Feature modules
│   └── authentication/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── auth_local_data_source.dart
│       │   │   └── auth_remote_data_source.dart
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       ├── login.dart
│       │       ├── logout.dart
│       │       └── get_current_user.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           ├── pages/
│           │   ├── login_page.dart
│           │   └── profile_page.dart
│           └── widgets/
│               └── login_form.dart
└── main.dart
```

---

## Domain Layer

The **Domain Layer** contains business logic and is independent of any framework or external library.

### Entities

#### ✅ DO: Create pure business objects

```dart
// ✅ CORRECT: Pure entity with business logic
class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final bool isEmailVerified;
  
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.isEmailVerified,
  });
  
  // Business logic belongs in entities
  bool get canPostContent => isEmailVerified;
  
  bool get isNewUser {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation < 7;
  }
  
  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
```

#### ❌ DON'T: Mix framework dependencies in entities

```dart
// ❌ INCORRECT: Entity depends on external packages
import 'package:json_annotation/json_annotation.dart'; // ❌ Wrong!

@JsonSerializable() // ❌ Framework dependency in domain
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  // ❌ JSON serialization logic in entity
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

**Why it matters:**
- ❌ Entities become coupled to frameworks
- ❌ Can't change serialization without changing domain
- ❌ Harder to test business logic
- ✅ Pure entities are framework-independent

---

### Repository Interfaces

#### ✅ DO: Define repository contracts in domain layer

```dart
// ✅ CORRECT: Repository interface in domain layer
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, void>> resetPassword(String email);
}
```

---

### Use Cases

#### ✅ DO: Create single-responsibility use cases

```dart
// ✅ CORRECT: Single-responsibility use case
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class Login implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  Login(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}
```

```dart
// ✅ CORRECT: Base UseCase interface
// core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
```

```dart
// ✅ CORRECT: Use case with no parameters
class GetCurrentUser implements UseCase<User, NoParams> {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
```

#### ❌ DON'T: Put multiple responsibilities in one use case

```dart
// ❌ INCORRECT: Use case doing too much
class AuthUseCase {
  final AuthRepository repository;

  AuthUseCase(this.repository);

  // ❌ Multiple responsibilities in one class
  Future<User> login(String email, String password) async {
    // Login logic
  }

  Future<User> signUp(String email, String password) async {
    // Sign up logic
  }

  Future<void> logout() async {
    // Logout logic
  }

  Future<void> resetPassword(String email) async {
    // Reset password logic
  }
}
```

**Why it matters:**
- ❌ Hard to test individual operations
- ❌ Violates Single Responsibility Principle
- ❌ Difficult to maintain and extend
- ✅ Single-purpose use cases are easier to test and maintain

---

## Data Layer

The **Data Layer** implements repository interfaces and handles data sources.

### Models

#### ✅ DO: Create models that extend entities

```dart
// ✅ CORRECT: Model extends entity and handles serialization
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String name,
    required DateTime createdAt,
    required bool isEmailVerified,
  }) : super(
          id: id,
          email: email,
          name: name,
          createdAt: createdAt,
          isEmailVerified: isEmailVerified,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Convert entity to model
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      createdAt: user.createdAt,
      isEmailVerified: user.isEmailVerified,
    );
  }

  // Convert model to entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      createdAt: createdAt,
      isEmailVerified: isEmailVerified,
    );
  }
}
```

#### ❌ DON'T: Use models directly in domain layer

```dart
// ❌ INCORRECT: Repository returns model instead of entity
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<Failure, UserModel>> login({ // ❌ Should return User entity
    required String email,
    required String password,
  }) async {
    // Implementation
  }
}
```

---

### Data Sources

#### ✅ DO: Separate remote and local data sources

```dart
// ✅ CORRECT: Remote data source with clear contract
abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw ServerException();
    }
  }

  // ... other methods
}
```

```dart
// ✅ CORRECT: Local data source for caching
abstract class AuthLocalDataSource {
  Future<UserModel> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cachedUserKey = 'CACHED_USER';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> getCachedUser() async {
    final jsonString = sharedPreferences.getString(cachedUserKey);

    if (jsonString != null) {
      return UserModel.fromJson(jsonDecode(jsonString));
    } else {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      cachedUserKey,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(cachedUserKey);
  }
}
```

---

### Repository Implementation

#### ✅ DO: Implement repositories with proper error handling

```dart
// ✅ CORRECT: Repository implementation with error handling
import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.login(
          email: email,
          password: password,
        );

        // Cache the user
        await localDataSource.cacheUser(userModel);

        return Right(userModel.toEntity());
      } on UnauthorizedException {
        return Left(AuthFailure('Invalid email or password'));
      } on ServerException {
        return Left(ServerFailure('Server error. Please try again later.'));
      } catch (e) {
        return Left(UnexpectedFailure('An unexpected error occurred'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Try to get cached user first
      final cachedUser = await localDataSource.getCachedUser();
      return Right(cachedUser.toEntity());
    } on CacheException {
      // If no cache, fetch from remote
      if (await networkInfo.isConnected) {
        try {
          final userModel = await remoteDataSource.getCurrentUser();
          await localDataSource.cacheUser(userModel);
          return Right(userModel.toEntity());
        } on ServerException {
          return Left(ServerFailure('Failed to fetch user'));
        }
      } else {
        return Left(NetworkFailure('No internet connection'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure('Failed to logout'));
    }
  }

  // ... other methods
}
```

#### ❌ DON'T: Ignore error handling or network checks

```dart
// ❌ INCORRECT: No error handling or network checks
class BadAuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  BadAuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    // ❌ No network check
    // ❌ No try-catch
    // ❌ No caching
    final userModel = await remoteDataSource.login(
      email: email,
      password: password,
    );

    return Right(userModel.toEntity());
  }
}
```

**Why it matters:**
- ❌ App crashes on network errors
- ❌ No offline support
- ❌ Poor user experience
- ✅ Proper error handling provides resilience

---

## Presentation Layer

The **Presentation Layer** contains UI and state management.

### BLoC/Cubit

#### ✅ DO: Use BLoC with use cases

```dart
// ✅ CORRECT: BLoC using use cases from domain layer
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../../core/usecases/usecase.dart';

part 'auth_bloc.freezed.dart';

// Events
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = LoginRequested;

  const factory AuthEvent.logoutRequested() = LogoutRequested;

  const factory AuthEvent.checkAuthStatus() = CheckAuthStatus;
}

// States
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = Initial;
  const factory AuthState.loading() = Loading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error(String message) = Error;
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Login loginUseCase;
  final Logout logoutUseCase;
  final GetCurrentUser getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
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

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await getCurrentUserUseCase(NoParams());

    result.fold(
      (failure) => emit(const AuthState.unauthenticated()),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
}
```

#### ❌ DON'T: Put business logic in BLoC

```dart
// ❌ INCORRECT: Business logic in BLoC
class BadAuthBloc extends Bloc<AuthEvent, AuthState> {
  final http.Client client; // ❌ Direct dependency on HTTP client

  BadAuthBloc(this.client) : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    // ❌ Business logic and API calls directly in BLoC
    try {
      final response = await client.post(
        Uri.parse('https://api.example.com/login'),
        body: {
          'email': event.email,
          'password': event.password,
        },
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
- ❌ BLoC becomes tightly coupled to implementation
- ❌ Hard to reuse logic in other parts of app
- ✅ Use cases keep BLoC focused on state management

---

## Dependency Injection

### ✅ DO: Use GetIt for dependency injection

```dart
// ✅ CORRECT: Dependency injection setup
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  //! Features - Authentication
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      client: sl(),
      baseUrl: 'https://api.example.com',
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
```

```dart
// ✅ CORRECT: Initialize in main.dart
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}
```

```dart
// ✅ CORRECT: Use in widgets
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthEvent.checkAuthStatus()),
      child: LoginView(),
    );
  }
}
```

---

## Feature-First Organization

### ✅ DO: Organize by features, not by layers

```
lib/
├── core/                          # Shared across features
│   ├── error/
│   ├── network/
│   ├── usecases/
│   └── utils/
├── features/
│   ├── authentication/            # Feature 1
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── posts/                     # Feature 2
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/                   # Feature 3
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

### ❌ DON'T: Organize by technical layers

```
lib/
├── data/                          # ❌ All data layer code together
│   ├── auth_repository.dart
│   ├── post_repository.dart
│   └── profile_repository.dart
├── domain/                        # ❌ All domain code together
│   ├── auth_entities.dart
│   ├── post_entities.dart
│   └── profile_entities.dart
└── presentation/                  # ❌ All UI code together
    ├── auth_pages.dart
    ├── post_pages.dart
    └── profile_pages.dart
```

**Why it matters:**
- ❌ Hard to find related code
- ❌ Features become scattered
- ❌ Difficult to work on one feature
- ✅ Feature-first makes code easier to navigate

---

## Testing Strategy

### ✅ DO: Test each layer independently

```dart
// ✅ CORRECT: Test use case with mocked repository
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Login useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = Login(mockRepository);
  });

  group('Login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUser = User(
      id: '1',
      email: tEmail,
      name: 'Test User',
      createdAt: DateTime(2024, 1, 1),
      isEmailVerified: true,
    );

    test('should return User when login is successful', () async {
      // Arrange
      when(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(tUser));

      // Act
      final result = await useCase(
        const LoginParams(email: tEmail, password: tPassword),
      );

      // Assert
      expect(result, const Right(tUser));
      verify(() => mockRepository.login(
            email: tEmail,
            password: tPassword,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AuthFailure when credentials are invalid', () async {
      // Arrange
      when(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));

      // Act
      final result = await useCase(
        const LoginParams(email: tEmail, password: tPassword),
      );

      // Assert
      expect(result, Left(AuthFailure('Invalid credentials')));
      verify(() => mockRepository.login(
            email: tEmail,
            password: tPassword,
          )).called(1);
    });
  });
}
```

```dart
// ✅ CORRECT: Test repository implementation
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUserModel = UserModel(
      id: '1',
      email: tEmail,
      name: 'Test User',
      createdAt: DateTime(2024, 1, 1),
      isEmailVerified: true,
    );

    test('should check if device is online', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async => Future.value());

      // Act
      await repository.login(email: tEmail, password: tPassword);

      // Assert
      verify(() => mockNetworkInfo.isConnected);
    });

    test('should cache user when login is successful', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async => Future.value());

      // Act
      await repository.login(email: tEmail, password: tPassword);

      // Assert
      verify(() => mockLocalDataSource.cacheUser(tUserModel));
    });

    test('should return NetworkFailure when device is offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.login(email: tEmail, password: tPassword);

      // Assert
      expect(result, Left(NetworkFailure('No internet connection')));
      verifyNever(() => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });
  });
}
```

---

## Summary

### Quick Reference

**Core Principles:**
- ✅ Follow the dependency rule (dependencies point inward)
- ✅ Keep domain layer pure and framework-independent
- ✅ Use interfaces for repositories in domain layer
- ❌ Don't let inner layers depend on outer layers
- ❌ Don't mix framework code with business logic

**Layer Organization:**
- ✅ Domain: Entities, repository interfaces, use cases
- ✅ Data: Models, data sources, repository implementations
- ✅ Presentation: UI, BLoC/Cubit, widgets
- ❌ Don't organize by technical layers
- ✅ Organize by features

**Use Cases:**
- ✅ Single responsibility per use case
- ✅ Use Either<Failure, Success> for error handling
- ✅ Accept parameters object
- ❌ Don't put multiple operations in one use case
- ❌ Don't put business logic in BLoC

**Repository Pattern:**
- ✅ Define interface in domain layer
- ✅ Implement in data layer
- ✅ Handle network checks and caching
- ✅ Convert models to entities
- ❌ Don't return models from repositories
- ❌ Don't ignore error handling

**Dependency Injection:**
- ✅ Use GetIt for service location
- ✅ Register factories for BLoCs
- ✅ Register lazy singletons for use cases and repositories
- ✅ Initialize in main.dart
- ❌ Don't create dependencies manually

**Testing:**
- ✅ Test each layer independently
- ✅ Mock dependencies with mocktail
- ✅ Test use cases with mocked repositories
- ✅ Test repositories with mocked data sources
- ✅ Test BLoCs with mocked use cases

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0

