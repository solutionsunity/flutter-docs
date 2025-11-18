---
type: "agent_requested"
description: "Integration patterns for Supabase including authentication, database operations, storage, real-time subscriptions, and Row Level Security policies for Flutter applications."
---

# Supabase Integration Guide

> **Comprehensive guide for integrating Supabase with Flutter applications**

---

## Table of Contents
- [Overview](#overview)
- [Setup and Configuration](#setup-and-configuration)
- [Authentication](#authentication)
- [Database (PostgreSQL)](#database-postgresql)
- [Storage](#storage)
- [Real-time Subscriptions](#real-time-subscriptions)
- [Error Handling](#error-handling)
- [Security Best Practices](#security-best-practices)

---

## Overview

**Supabase** is an open-source Firebase alternative providing:
- PostgreSQL database
- Authentication (email, OAuth, magic links)
- Storage for files
- Real-time subscriptions
- Edge Functions
- Row Level Security (RLS)

**Use Supabase when:**
- ✅ You need a PostgreSQL database with real-time capabilities
- ✅ You want open-source backend infrastructure
- ✅ You need fine-grained access control with RLS
- ✅ You prefer SQL over NoSQL
- ✅ You want to self-host your backend

---

## Setup and Configuration

### Installation

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  flutter_dotenv: ^5.1.0  # For environment variables

dev_dependencies:
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
```

### ✅ DO: Initialize Supabase properly with environment variables

```dart
// ✅ CORRECT: Secure initialization with environment variables
// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // More secure
    ),
  );
  
  runApp(const MyApp());
}

// Global accessor
final supabase = Supabase.instance.client;
```

```env
# .env file (add to .gitignore!)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

```gitignore
# .gitignore
.env
*.env
```

### ❌ DON'T: Hardcode credentials in source code

```dart
// ❌ INCORRECT: Hardcoded credentials exposed in source control
await Supabase.initialize(
  url: 'https://xyzcompany.supabase.co', // ❌ Exposed in git
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // ❌ Security risk
);
```

**Why it matters:**
- ❌ Credentials exposed in version control
- ❌ Can't use different keys for dev/staging/prod
- ❌ Security vulnerability if repo is public
- ✅ Environment variables keep secrets safe

---

## Authentication

### Email/Password Authentication

#### ✅ DO: Implement proper authentication with error handling

```dart
// ✅ CORRECT: Comprehensive auth service with error handling
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata, // Additional user data
      );
      
      if (response.user == null) {
        throw Exception('Sign up failed: No user returned');
      }
      
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Unexpected error during sign up: $e');
    }
  }
  
  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Unexpected error during sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle auth exceptions with user-friendly messages
  String _handleAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        return 'Invalid email or password';
      case '422':
        return 'Email already registered';
      case '429':
        return 'Too many requests. Please try again later';
      default:
        return e.message;
    }
  }
}
```

#### ❌ DON'T: Ignore error handling or expose raw errors to users

```dart
// ❌ INCORRECT: No error handling, raw exceptions exposed
class BadAuthService {
  final supabase = Supabase.instance.client;

  Future<void> signIn(String email, String password) async {
    // ❌ No try-catch, will crash on error
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String email, String password) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    // ❌ No validation if user was created
    // ❌ No error handling
  }
}
```

**Why it matters:**
- ❌ App crashes on network errors or invalid credentials
- ❌ Users see technical error messages
- ❌ No way to handle specific error cases
- ✅ Proper error handling provides better UX

---

### OAuth Authentication

#### ✅ DO: Implement OAuth with proper deep linking

```dart
// ✅ CORRECT: OAuth with Google
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      return response;
    } on AuthException catch (e) {
      debugPrint('OAuth error: ${e.message}');
      return false;
    }
  }

  Future<bool> signInWithGithub() async {
    try {
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
    } on AuthException catch (e) {
      debugPrint('OAuth error: ${e.message}');
      return false;
    }
  }
}
```

```dart
// ✅ CORRECT: Handle deep link callback
// In your main.dart or app initialization
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... app configuration
    );
  }
}
```

---

## Database (PostgreSQL)

### Basic CRUD Operations

#### ✅ DO: Use type-safe models with proper error handling

```dart
// ✅ CORRECT: Type-safe model with JSON serialization
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? website;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.website,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
```

```dart
// ✅ CORRECT: Repository with proper error handling
class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Database error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return null;
    }
  }

  // Create or update profile
  Future<bool> upsertProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .upsert(profile.toJson());

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Database error: ${e.message}');
      return false;
    }
  }

  // Delete profile
  Future<bool> deleteProfile(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', userId);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Database error: ${e.message}');
      return false;
    }
  }

  // Fetch multiple profiles with filtering
  Future<List<UserProfile>> searchProfiles(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Database error: ${e.message}');
      return [];
    }
  }
}
```

#### ❌ DON'T: Use dynamic types or ignore errors

```dart
// ❌ INCORRECT: No type safety, poor error handling
class BadUserRepository {
  final supabase = Supabase.instance.client;

  Future<dynamic> getUser(String id) async {
    // ❌ Returns dynamic, no type safety
    // ❌ No error handling
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .single();

    return data; // ❌ Raw JSON, not a typed object
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    // ❌ No validation of data structure
    // ❌ No error handling
    await supabase.from('profiles').upsert(data);
  }
}
```

**Why it matters:**
- ❌ No compile-time type checking
- ❌ Runtime errors from missing/wrong fields
- ❌ Hard to maintain and refactor
- ✅ Type-safe models catch errors at compile time

---

### Advanced Queries

#### ✅ DO: Use query builders for complex queries

```dart
// ✅ CORRECT: Complex queries with joins and filters
class PostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch posts with author information (join)
  Future<List<Map<String, dynamic>>> getPostsWithAuthors() async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            title,
            content,
            created_at,
            author:profiles!posts_author_id_fkey (
              id,
              username,
              avatar_url
            )
          ''')
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint('Query error: ${e.message}');
      return [];
    }
  }

  // Pagination with range
  Future<List<Map<String, dynamic>>> getPostsPaginated({
    required int page,
    int pageSize = 10,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from('posts')
          .select()
          .range(from, to)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint('Pagination error: ${e.message}');
      return [];
    }
  }

  // Full-text search
  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      final response = await _supabase
          .from('posts')
          .select()
          .textSearch('title', query, config: 'english')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint('Search error: ${e.message}');
      return [];
    }
  }

  // Count with filters
  Future<int> getPostCount({String? authorId}) async {
    try {
      var query = _supabase
          .from('posts')
          .select('id', const FetchOptions(count: CountOption.exact));

      if (authorId != null) {
        query = query.eq('author_id', authorId);
      }

      final response = await query;
      return response.count ?? 0;
    } on PostgrestException catch (e) {
      debugPrint('Count error: ${e.message}');
      return 0;
    }
  }
}
```

---

## Storage

### File Upload and Download

#### ✅ DO: Implement secure file operations with progress tracking

```dart
// ✅ CORRECT: Secure storage service with progress tracking
import 'dart:io';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload file with progress tracking
  Future<String?> uploadFile({
    required File file,
    required String bucket,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileExt = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from(bucket).upload(
        filePath,
        file,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('Upload error: ${e.message}');
      return null;
    }
  }

  // Upload avatar with size validation
  Future<String?> uploadAvatar({
    required File file,
    required String userId,
  }) async {
    try {
      // Validate file size (max 2MB)
      final fileSize = await file.length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception('File size must be less than 2MB');
      }

      // Validate file type
      final fileExt = path.extension(file.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.gif'].contains(fileExt)) {
        throw Exception('Only image files are allowed');
      }

      final filePath = 'avatars/$userId$fileExt';

      // Delete old avatar if exists
      try {
        await _supabase.storage.from('avatars').remove([filePath]);
      } catch (_) {
        // Ignore if file doesn't exist
      }

      // Upload new avatar
      await _supabase.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      return _supabase.storage.from('avatars').getPublicUrl(filePath);
    } on StorageException catch (e) {
      debugPrint('Avatar upload error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Validation error: $e');
      return null;
    }
  }

  // Download file
  Future<Uint8List?> downloadFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .download(filePath);

      return response;
    } on StorageException catch (e) {
      debugPrint('Download error: ${e.message}');
      return null;
    }
  }

  // Delete file
  Future<bool> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([filePath]);
      return true;
    } on StorageException catch (e) {
      debugPrint('Delete error: ${e.message}');
      return false;
    }
  }

  // List files in a folder
  Future<List<FileObject>> listFiles({
    required String bucket,
    required String folder,
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .list(path: folder);

      return response;
    } on StorageException catch (e) {
      debugPrint('List error: ${e.message}');
      return [];
    }
  }
}
```

#### ❌ DON'T: Upload files without validation or error handling

```dart
// ❌ INCORRECT: No validation, poor error handling
class BadStorageService {
  final supabase = Supabase.instance.client;

  Future<String> uploadFile(File file) async {
    // ❌ No file size validation
    // ❌ No file type validation
    // ❌ No error handling
    // ❌ Predictable file names (security risk)

    await supabase.storage
        .from('public')
        .upload('file.jpg', file); // ❌ Same name every time

    return supabase.storage
        .from('public')
        .getPublicUrl('file.jpg');
  }
}
```

**Why it matters:**
- ❌ Users can upload huge files (DoS attack)
- ❌ Users can upload malicious files
- ❌ File name collisions overwrite existing files
- ❌ No error feedback to users
- ✅ Validation and unique names ensure security

---

## Real-time Subscriptions

### ✅ DO: Implement real-time listeners with proper cleanup

```dart
// ✅ CORRECT: Real-time subscription with cleanup
import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  final String channelId;

  const MessagesScreen({Key? key, required this.channelId}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<Message> _messages = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _subscribeToMessages();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('channel_id', widget.channelId)
          .order('created_at', ascending: true)
          .limit(50);

      setState(() {
        _messages.addAll(
          (response as List).map((json) => Message.fromJson(json)).toList(),
        );
      });
    } on PostgrestException catch (e) {
      debugPrint('Error loading messages: ${e.message}');
    }
  }

  void _subscribeToMessages() {
    _channel = _supabase
        .channel('messages:${widget.channelId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: widget.channelId,
          ),
          callback: (payload) {
            final newMessage = Message.fromJson(payload.newRecord);
            setState(() {
              _messages.add(newMessage);
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: widget.channelId,
          ),
          callback: (payload) {
            final deletedId = payload.oldRecord['id'];
            setState(() {
              _messages.removeWhere((msg) => msg.id == deletedId);
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    // ✅ IMPORTANT: Unsubscribe to prevent memory leaks
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return ListTile(
            title: Text(message.content),
            subtitle: Text(message.createdAt.toString()),
          );
        },
      ),
    );
  }
}
```

#### ❌ DON'T: Forget to unsubscribe or handle errors

```dart
// ❌ INCORRECT: Memory leak, no error handling
class BadMessagesScreen extends StatefulWidget {
  @override
  State<BadMessagesScreen> createState() => _BadMessagesScreenState();
}

class _BadMessagesScreenState extends State<BadMessagesScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // ❌ No reference to channel (can't unsubscribe)
    supabase
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // ❌ No error handling
            // ❌ Updating state without checking if mounted
            setState(() {
              // Update UI
            });
          },
        )
        .subscribe();
  }

  // ❌ No dispose method - memory leak!

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

**Why it matters:**
- ❌ Memory leaks from active subscriptions
- ❌ Crashes when updating disposed widgets
- ❌ No error handling for connection issues
- ✅ Proper cleanup prevents memory leaks

---

## Error Handling

### ✅ DO: Create a centralized error handler

```dart
// ✅ CORRECT: Centralized error handling
class SupabaseErrorHandler {
  static String handleError(Object error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is PostgrestException) {
      return _handleDatabaseError(error);
    } else if (error is StorageException) {
      return _handleStorageError(error);
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static String _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '400':
        return 'Invalid credentials. Please check your email and password.';
      case '422':
        return 'This email is already registered.';
      case '429':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message;
    }
  }

  static String _handleDatabaseError(PostgrestException error) {
    if (error.code == '23505') {
      return 'This record already exists.';
    } else if (error.code == '23503') {
      return 'Cannot delete: related records exist.';
    } else if (error.code == 'PGRST116') {
      return 'No records found.';
    }
    return 'Database error: ${error.message}';
  }

  static String _handleStorageError(StorageException error) {
    if (error.statusCode == '404') {
      return 'File not found.';
    } else if (error.statusCode == '413') {
      return 'File is too large.';
    }
    return 'Storage error: ${error.message}';
  }
}
```

---

## Security Best Practices

### Row Level Security (RLS)

#### ✅ DO: Enable RLS and create proper policies

```sql
-- ✅ CORRECT: Enable RLS and create policies
-- Enable RLS on the table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Users can delete their own profile
CREATE POLICY "Users can delete their own profile"
  ON profiles FOR DELETE
  USING (auth.uid() = id);
```

```sql
-- ✅ CORRECT: More complex policy with role-based access
CREATE POLICY "Users can view posts in their organization"
  ON posts FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_organizations
      WHERE user_id = auth.uid()
    )
  );
```

#### ❌ DON'T: Disable RLS or use overly permissive policies

```sql
-- ❌ INCORRECT: RLS disabled (security risk!)
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- ❌ INCORRECT: Overly permissive policy
CREATE POLICY "Anyone can do anything"
  ON profiles FOR ALL
  USING (true)
  WITH CHECK (true);
```

### ✅ DO: Validate data on the client and server

```dart
// ✅ CORRECT: Client-side validation before sending to Supabase
class ProfileValidator {
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (username.length > 20) {
      return 'Username must be less than 20 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  static String? validateWebsite(String? website) {
    if (website == null || website.isEmpty) {
      return null; // Optional field
    }

    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b',
    );

    if (!urlPattern.hasMatch(website)) {
      return 'Please enter a valid URL';
    }

    return null;
  }
}
```

```sql
-- ✅ CORRECT: Server-side validation with database constraints
ALTER TABLE profiles
  ADD CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 20),
  ADD CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$');
```

---

## Summary

### Quick Reference

**Authentication:**
- ✅ Use environment variables for credentials
- ✅ Handle AuthException properly
- ✅ Implement OAuth with deep linking
- ❌ Don't hardcode credentials
- ❌ Don't expose raw errors to users

**Database:**
- ✅ Use type-safe models with json_serializable
- ✅ Handle PostgrestException
- ✅ Use query builders for complex queries
- ❌ Don't use dynamic types
- ❌ Don't ignore errors

**Storage:**
- ✅ Validate file size and type
- ✅ Use unique file names
- ✅ Handle StorageException
- ❌ Don't allow unlimited uploads
- ❌ Don't use predictable file names

**Real-time:**
- ✅ Unsubscribe in dispose()
- ✅ Load initial data before subscribing
- ✅ Handle connection errors
- ❌ Don't forget to clean up subscriptions
- ❌ Don't update state after dispose

**Security:**
- ✅ Enable Row Level Security (RLS)
- ✅ Create specific policies per operation
- ✅ Validate on client and server
- ❌ Don't disable RLS
- ❌ Don't use overly permissive policies

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0


