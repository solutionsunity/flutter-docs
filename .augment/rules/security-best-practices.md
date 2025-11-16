---
type: "manual"
---

# Flutter Security Best Practices

> **Comprehensive security guidelines for Flutter applications**

---

## Table of Contents
- [API Key Management](#api-key-management)
- [Secure Storage](#secure-storage)
- [Authentication & Authorization](#authentication--authorization)
- [Network Security](#network-security)
- [Input Validation](#input-validation)
- [Code Obfuscation](#code-obfuscation)
- [Platform-Specific Security](#platform-specific-security)
- [Common Vulnerabilities](#common-vulnerabilities)

---

## API Key Management

### Environment Variables

#### ✅ DO: Use environment variables for sensitive data

```dart
// ✅ CORRECT: API keys in environment variables

// 1. Create .env file (add to .gitignore!)
// .env
API_KEY=your_api_key_here
API_SECRET=your_secret_here
BASE_URL=https://api.example.com

// 2. Add to .gitignore
// .gitignore
.env
.env.*
!.env.example

// 3. Create .env.example for team
// .env.example
API_KEY=your_api_key_here
API_SECRET=your_secret_here
BASE_URL=https://api.example.com

// 4. Use flutter_dotenv package
// pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0

assets:
  - .env

// 5. Load and use environment variables
// main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

// api_client.dart
class ApiClient {
  static final String apiKey = dotenv.env['API_KEY'] ?? '';
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<Response> getData() async {
    return http.get(
      Uri.parse('$baseUrl/data'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );
  }
}
```

#### ❌ DON'T: Hardcode API keys in source code

```dart
// ❌ INCORRECT: Hardcoded API keys - NEVER DO THIS!
class ApiClient {
  static const String apiKey = 'sk_live_abc123xyz789'; // ❌ Exposed in source!
  static const String apiSecret = 'secret_key_12345'; // ❌ Security risk!
  
  Future<Response> getData() async {
    return http.get(
      Uri.parse('https://api.example.com/data'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );
  }
}

// ❌ INCORRECT: API keys in version control
// config.dart
const Map<String, String> config = {
  'api_key': 'sk_live_abc123xyz789', // ❌ Will be in git history!
  'secret': 'my_secret_key',
};
```

**Why it matters:**
- ❌ Hardcoded keys are visible in source code
- ❌ Keys end up in version control history
- ❌ Anyone with code access has your keys
- ❌ Can't rotate keys without code changes
- ✅ Environment variables keep secrets out of code
- ✅ Easy to rotate keys per environment

---

### Supabase Credentials Management

#### ✅ DO: Use environment variables for Supabase credentials

```dart
// ✅ CORRECT: Supabase credentials in environment variables

// 1. Create .env file (add to .gitignore!)
// .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

// 2. Add to .gitignore
// .gitignore
.env

// 3. Create .env.example for team
// .env.example
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

// 4. Add flutter_dotenv to pubspec.yaml
// pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
  supabase_flutter: ^2.0.0

flutter:
  assets:
    - .env

// 5. Load environment variables in main.dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables BEFORE initializing Supabase
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

// 6. Use environment variables in constants
// lib/core/constants/app_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration - loaded from environment variables
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
```

#### ❌ DON'T: Hardcode Supabase credentials in source code

```dart
// ❌ INCORRECT: Hardcoded Supabase credentials - CRITICAL SECURITY VIOLATION!

// lib/core/constants/app_constants.dart
class AppConstants {
  // ❌ NEVER hardcode Supabase URL and keys!
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  // ❌ These will be committed to version control!
  // ❌ Anyone with code access can access your database!
}

// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ❌ Using hardcoded credentials
  await Supabase.initialize(
    url: AppConstants.supabaseUrl, // ❌ Exposed in source code
    anonKey: AppConstants.supabaseAnonKey, // ❌ Security risk
  );

  runApp(const MyApp());
}
```

**Why it matters:**
- ❌ Supabase credentials in source code expose your entire database
- ❌ Credentials in git history can't be removed without rewriting history
- ❌ Anyone who clones the repository has full database access
- ❌ Rotating compromised keys requires code changes and redeployment
- ❌ Anon keys can be extracted from compiled apps and used maliciously
- ✅ Environment variables keep credentials out of version control
- ✅ Easy to rotate keys without code changes
- ✅ Different credentials for development, staging, and production
- ✅ Follows security best practices for all backend services

**Real-world impact:**
```
Hardcoded Supabase credentials have led to:
- Unauthorized database access and data breaches
- Malicious users extracting keys from APK/IPA files
- Entire databases being deleted or corrupted
- Costly data recovery and security audits
- Loss of user trust and potential legal liability
```

---

### Build-time Configuration

#### ✅ DO: Use --dart-define for build-time secrets

```dart
// ✅ CORRECT: Build-time configuration

// 1. Define constants
// lib/config/app_config.dart
class AppConfig {
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static const bool isProduction = environment == 'production';
}

// 2. Build with --dart-define
// flutter build apk --dart-define=API_KEY=your_key --dart-define=ENVIRONMENT=production
// flutter run --dart-define=API_KEY=dev_key --dart-define=ENVIRONMENT=development

// 3. Use in code
class ApiClient {
  final String apiKey = AppConfig.apiKey;
  final bool isProduction = AppConfig.isProduction;
}

// 4. Create build scripts
// scripts/build_prod.sh
#!/bin/bash
flutter build apk \
  --dart-define=API_KEY=$PROD_API_KEY \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BASE_URL=https://api.production.com

// scripts/build_dev.sh
#!/bin/bash
flutter build apk \
  --dart-define=API_KEY=$DEV_API_KEY \
  --dart-define=ENVIRONMENT=development \
  --dart-define=BASE_URL=https://api.dev.com
```

#### ❌ DON'T: Mix development and production keys

```dart
// ❌ INCORRECT: Mixing environments
class ApiClient {
  static const String devApiKey = 'dev_key_123';
  static const String prodApiKey = 'prod_key_456'; // ❌ Both keys in code!
  
  String get apiKey {
    return kDebugMode ? devApiKey : prodApiKey; // ❌ Prod key in debug builds!
  }
}
```

**Why it matters:**
- ❌ Production keys exposed in development builds
- ❌ Risk of using wrong key in wrong environment
- ✅ Build-time configuration separates environments
- ✅ Production keys never in development builds

---

## Secure Storage

### Using flutter_secure_storage

#### ✅ DO: Store sensitive data securely

```dart
// ✅ CORRECT: Secure storage for sensitive data

// pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0

// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Store auth token
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Retrieve auth token
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Delete auth token
  static Future<void> deleteAuthToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Clear all secure data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

// Usage
class AuthService {
  Future<void> login(String email, String password) async {
    final response = await _apiClient.login(email, password);
    final token = response.data['token'];
    
    // ✅ Store token securely
    await SecureStorageService.saveAuthToken(token);
  }

  Future<void> logout() async {
    // ✅ Delete token on logout
    await SecureStorageService.deleteAuthToken();
  }

  Future<String?> getStoredToken() async {
    // ✅ Retrieve token securely
    return await SecureStorageService.getAuthToken();
  }
}
```

#### ❌ DON'T: Store sensitive data in SharedPreferences

```dart
// ❌ INCORRECT: Storing sensitive data in SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';

class BadAuthService {
  Future<void> login(String email, String password) async {
    final response = await _apiClient.login(email, password);
    final token = response.data['token'];

    // ❌ SharedPreferences is NOT encrypted!
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token); // ❌ Stored in plain text!
    await prefs.setString('password', password); // ❌ NEVER store passwords!
  }
}

// ❌ INCORRECT: Storing credit card info
class BadPaymentService {
  Future<void> saveCard(String cardNumber, String cvv) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_number', cardNumber); // ❌ PCI violation!
    await prefs.setString('cvv', cvv); // ❌ Extremely dangerous!
  }
}
```

**Why it matters:**
- ❌ SharedPreferences stores data in plain text
- ❌ Accessible via device file system
- ❌ Can be extracted from device backups
- ❌ Violates PCI DSS for payment data
- ✅ flutter_secure_storage uses platform encryption (Keychain/Keystore)
- ✅ Data encrypted at rest

---

## Authentication & Authorization

### JWT Token Management

#### ✅ DO: Implement secure token refresh

```dart
// ✅ CORRECT: Secure JWT token management with refresh

class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  // Store both access and refresh tokens
  Future<void> login(String email, String password) async {
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final accessToken = response.data['access_token'];
    final refreshToken = response.data['refresh_token'];

    // ✅ Store both tokens securely
    await _storage.saveAuthToken(accessToken);
    await _storage.saveRefreshToken(refreshToken);
  }

  // Refresh access token when expired
  Future<String?> refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();

    if (refreshToken == null) {
      return null;
    }

    try {
      final response = await _apiClient.post('/auth/refresh', {
        'refresh_token': refreshToken,
      });

      final newAccessToken = response.data['access_token'];
      await _storage.saveAuthToken(newAccessToken);

      return newAccessToken;
    } catch (e) {
      // Refresh failed, user needs to login again
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAuthToken();
    await _storage.deleteRefreshToken();
  }
}

// API Client with automatic token refresh
class ApiClient {
  final Dio _dio;
  final AuthService _authService;

  ApiClient(this._authService) : _dio = Dio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ✅ Add token to every request
          final token = await SecureStorageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // ✅ Token expired, try to refresh
            final newToken = await _authService.refreshAccessToken();

            if (newToken != null) {
              // ✅ Retry request with new token
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';

              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (e) {
                handler.reject(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }
}
```

#### ❌ DON'T: Store tokens without expiration handling

```dart
// ❌ INCORRECT: No token refresh logic
class BadAuthService {
  Future<void> login(String email, String password) async {
    final response = await _apiClient.login(email, password);
    final token = response.data['token'];

    // ❌ Only storing access token, no refresh token
    await _storage.saveAuthToken(token);

    // ❌ No expiration handling
    // ❌ No refresh logic
  }
}

// ❌ INCORRECT: No automatic retry on 401
class BadApiClient {
  Future<Response> getData() async {
    final token = await _storage.getAuthToken();

    try {
      return await http.get(
        Uri.parse('/data'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      // ❌ No handling of expired tokens
      // ❌ User gets error instead of automatic refresh
      rethrow;
    }
  }
}
```

**Why it matters:**
- ❌ Users logged out when token expires
- ❌ Poor user experience
- ❌ No automatic recovery from expired tokens
- ✅ Refresh tokens enable seamless re-authentication
- ✅ Better UX with automatic token refresh

---

### Biometric Authentication

#### ✅ DO: Implement biometric authentication

```dart
// ✅ CORRECT: Biometric authentication with fallback

// pubspec.yaml
dependencies:
  local_auth: ^2.1.7

// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Check if biometrics are available
  Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // ✅ Allow PIN/pattern fallback
          useErrorDialogs: useErrorDialogs,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}

// Usage in login flow
class LoginScreen extends StatelessWidget {
  final BiometricService _biometricService = BiometricService();
  final AuthService _authService = AuthService();

  Future<void> _loginWithBiometrics() async {
    // Check if biometrics are available
    final canUseBiometrics = await _biometricService.canUseBiometrics();

    if (!canUseBiometrics) {
      // ✅ Fallback to password login
      _showPasswordLogin();
      return;
    }

    // Authenticate with biometrics
    final authenticated = await _biometricService.authenticate(
      reason: 'Please authenticate to login',
    );

    if (authenticated) {
      // ✅ Get stored credentials securely
      final token = await SecureStorageService.getAuthToken();

      if (token != null) {
        // ✅ Login with stored token
        await _authService.loginWithToken(token);
      } else {
        // ✅ No stored token, show password login
        _showPasswordLogin();
      }
    }
  }
}
```

#### ❌ DON'T: Store passwords for biometric login

```dart
// ❌ INCORRECT: Storing password for biometric login
class BadBiometricLogin {
  Future<void> enableBiometricLogin(String email, String password) async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Enable biometric login',
    );

    if (authenticated) {
      // ❌ NEVER store passwords!
      await _storage.saveEmail(email);
      await _storage.savePassword(password); // ❌ Extremely dangerous!
    }
  }

  Future<void> loginWithBiometrics() async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Login',
    );

    if (authenticated) {
      // ❌ Retrieving stored password
      final email = await _storage.getEmail();
      final password = await _storage.getPassword(); // ❌ Security risk!

      // ❌ Logging in with stored password
      await _authService.login(email, password);
    }
  }
}
```

**Why it matters:**
- ❌ NEVER store passwords, even encrypted
- ❌ Passwords can be compromised if device is rooted/jailbroken
- ✅ Store tokens instead of passwords
- ✅ Tokens can be revoked server-side
- ✅ Biometrics should unlock tokens, not passwords

---

## Network Security

### HTTPS and SSL Pinning

#### ✅ DO: Enforce HTTPS and implement SSL pinning

```dart
// ✅ CORRECT: HTTPS enforcement and SSL pinning

// pubspec.yaml
dependencies:
  dio: ^5.3.3

// lib/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com', // ✅ Always use HTTPS
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status! < 500,
      ),
    );

    // ✅ Implement SSL pinning for production
    if (AppConfig.isProduction) {
      _setupSSLPinning();
    }
  }

  void _setupSSLPinning() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      client.badCertificateCallback = (cert, host, port) {
        // ✅ Verify certificate fingerprint
        final expectedFingerprint = AppConfig.sslFingerprint;
        final actualFingerprint = _getCertificateFingerprint(cert);

        return actualFingerprint == expectedFingerprint;
      };

      return client;
    };
  }

  String _getCertificateFingerprint(X509Certificate cert) {
    // Calculate SHA-256 fingerprint
    final bytes = cert.der;
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

#### ❌ DON'T: Allow HTTP or disable certificate validation

```dart
// ❌ INCORRECT: Using HTTP instead of HTTPS
class BadApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://api.example.com', // ❌ Unencrypted HTTP!
    ),
  );
}

// ❌ INCORRECT: Disabling certificate validation
class VeryBadApiClient {
  VeryBadApiClient() {
    final dio = Dio();

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      // ❌ NEVER DO THIS! Accepts any certificate!
      client.badCertificateCallback = (cert, host, port) => true;

      return client;
    };
  }
}
```

**Why it matters:**
- ❌ HTTP traffic can be intercepted (man-in-the-middle attacks)
- ❌ Disabling certificate validation defeats HTTPS purpose
- ❌ Sensitive data exposed in transit
- ✅ HTTPS encrypts all network traffic
- ✅ SSL pinning prevents certificate spoofing
- ✅ Protects against man-in-the-middle attacks

---

## Input Validation

### Sanitizing User Input

#### ✅ DO: Validate and sanitize all user input

```dart
// ✅ CORRECT: Comprehensive input validation

class InputValidator {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // ✅ Regex validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    // ✅ Length validation
    if (value.length > 254) {
      return 'Email too long';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // ✅ Minimum length
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // ✅ Maximum length (prevent DoS)
    if (value.length > 128) {
      return 'Password too long';
    }

    // ✅ Complexity requirements
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasDigit || !hasSpecialChar) {
      return 'Password must contain uppercase, lowercase, digit, and special character';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // ✅ Remove non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // ✅ Length validation
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Invalid phone number';
    }

    return null;
  }

  // Sanitize text input (prevent XSS if displaying in WebView)
  static String sanitizeText(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  // Validate and sanitize URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    try {
      final uri = Uri.parse(value);

      // ✅ Only allow HTTPS
      if (uri.scheme != 'https') {
        return 'Only HTTPS URLs are allowed';
      }

      // ✅ Validate domain
      if (uri.host.isEmpty) {
        return 'Invalid URL';
      }

      return null;
    } catch (e) {
      return 'Invalid URL format';
    }
  }
}

// Usage in forms
class RegistrationForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            validator: InputValidator.validateEmail, // ✅ Validate email
            keyboardType: TextInputType.emailAddress,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            validator: InputValidator.validatePassword, // ✅ Validate password
            obscureText: true,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Phone'),
            validator: InputValidator.validatePhoneNumber, // ✅ Validate phone
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
```

#### ❌ DON'T: Trust user input without validation

```dart
// ❌ INCORRECT: No input validation
class BadRegistrationForm extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    // ❌ No validation!
    final email = _emailController.text;
    final password = _passwordController.text;

    // ❌ Sending unvalidated input to API
    await _apiClient.register(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          // ❌ No validator
        ),
        TextField(
          controller: _passwordController,
          // ❌ No validator
          // ❌ Not obscured!
        ),
        ElevatedButton(
          onPressed: _register,
          child: const Text('Register'),
        ),
      ],
    );
  }
}

// ❌ INCORRECT: Weak password validation
String? badPasswordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password required';
  }

  // ❌ Only checking length, no complexity
  if (value.length < 6) {
    return 'Too short';
  }

  // ❌ No maximum length (DoS risk)
  // ❌ No complexity requirements

  return null;
}
```

**Why it matters:**
- ❌ Unvalidated input can cause crashes
- ❌ Security vulnerabilities (injection attacks)
- ❌ Poor data quality
- ❌ Weak passwords compromise accounts
- ✅ Validation prevents malicious input
- ✅ Better user experience with clear error messages
- ✅ Protects against common attacks

---

## Code Obfuscation

### Build Configuration

#### ✅ DO: Enable obfuscation for release builds

```bash
# ✅ CORRECT: Build with obfuscation

# Android
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols

# iOS
flutter build ios --obfuscate --split-debug-info=build/ios/symbols

# ✅ Keep symbols for crash reporting
# Upload symbols to Firebase Crashlytics or similar service
```

#### ✅ DO: Protect sensitive strings

```dart
// ✅ CORRECT: Obfuscate sensitive strings

class SecurityUtils {
  // ✅ Use base64 encoding for sensitive strings
  static String get apiEndpoint {
    // Decode at runtime
    return String.fromCharCodes(base64.decode('aHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20='));
  }

  // ✅ Split strings to avoid detection
  static String get sensitiveKey {
    final parts = ['sk_', 'live_', 'abc123'];
    return parts.join();
  }
}
```

#### ❌ DON'T: Rely only on obfuscation for secrets

```dart
// ❌ INCORRECT: Obfuscation is not encryption!
class BadSecurity {
  // ❌ Obfuscation can be reversed
  static const String apiKey = 'sk_live_abc123'; // ❌ Still visible with effort

  // ❌ Don't store secrets in code, even obfuscated
  static const String privateKey = '''
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
    -----END PRIVATE KEY-----
  '''; // ❌ NEVER do this!
}
```

**Why it matters:**
- ❌ Obfuscation is not encryption
- ❌ Can be reversed with effort
- ❌ Not a substitute for proper secret management
- ✅ Makes reverse engineering harder
- ✅ Protects business logic
- ✅ Should be combined with other security measures

---

## Platform-Specific Security

### Android Security

#### ✅ DO: Configure Android security properly

```xml
<!-- ✅ CORRECT: android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="MyApp"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:allowBackup="false"
        android:fullBackupContent="false">

        <!-- ✅ Prevent screenshots in sensitive screens -->
        <activity
            android:name=".MainActivity"
            android:windowSoftInputMode="adjustResize"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true">

            <!-- ✅ Prevent app from appearing in recent apps -->
            <meta-data
                android:name="io.flutter.embedding.android.EnableSplashScreen"
                android:value="true" />
        </activity>
    </application>

    <!-- ✅ Only request necessary permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- Don't request unnecessary permissions -->
</manifest>

<!-- ✅ Network security config -->
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <!-- ✅ SSL pinning for production -->
    <domain-config>
        <domain includeSubdomains="true">api.example.com</domain>
        <pin-set>
            <pin digest="SHA-256">base64_encoded_pin_here</pin>
            <pin digest="SHA-256">backup_pin_here</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

#### ✅ DO: Prevent screenshots in sensitive screens

```dart
// ✅ CORRECT: Disable screenshots for sensitive screens

import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class SecureScreen extends StatefulWidget {
  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    _disableScreenshots();
  }

  Future<void> _disableScreenshots() async {
    if (Platform.isAndroid) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  @override
  void dispose() {
    _enableScreenshots();
    super.dispose();
  }

  Future<void> _enableScreenshots() async {
    if (Platform.isAndroid) {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Screen')),
      body: const Center(
        child: Text('This screen cannot be screenshotted'),
      ),
    );
  }
}
```

---

### iOS Security

#### ✅ DO: Configure iOS security properly

```xml
<!-- ✅ CORRECT: ios/Runner/Info.plist -->
<dict>
    <!-- ✅ Require HTTPS -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>

    <!-- ✅ Request only necessary permissions with clear descriptions -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to scan QR codes</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo access to upload profile pictures</string>

    <!-- ✅ Enable data protection -->
    <key>NSFileProtectionComplete</key>
    <true/>
</dict>
```

---

## Common Vulnerabilities

### SQL Injection Prevention

#### ✅ DO: Use parameterized queries

```dart
// ✅ CORRECT: Parameterized queries with sqflite

import 'package:sqflite/sqflite.dart';

class UserDatabase {
  final Database db;

  UserDatabase(this.db);

  // ✅ Safe: Using parameterized query
  Future<List<Map<String, dynamic>>> getUserByEmail(String email) async {
    return await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email], // ✅ Parameters prevent injection
    );
  }

  // ✅ Safe: Using named parameters
  Future<int> insertUser(String name, String email) async {
    return await db.insert(
      'users',
      {'name': name, 'email': email}, // ✅ Safe
    );
  }
}
```

#### ❌ DON'T: Concatenate user input into queries

```dart
// ❌ INCORRECT: SQL injection vulnerability!

class BadUserDatabase {
  final Database db;

  BadUserDatabase(this.db);

  // ❌ DANGEROUS: String concatenation allows SQL injection
  Future<List<Map<String, dynamic>>> getUserByEmail(String email) async {
    // ❌ If email = "'; DROP TABLE users; --"
    // ❌ Query becomes: SELECT * FROM users WHERE email = ''; DROP TABLE users; --'
    return await db.rawQuery(
      "SELECT * FROM users WHERE email = '$email'", // ❌ NEVER DO THIS!
    );
  }
}
```

**Why it matters:**
- ❌ SQL injection can delete/modify data
- ❌ Attackers can access unauthorized data
- ❌ Database can be completely compromised
- ✅ Parameterized queries prevent injection
- ✅ Database driver handles escaping

---

## Summary

### Security Checklist

#### API Keys & Secrets
- ✅ Use environment variables or --dart-define
- ✅ Never commit secrets to version control
- ✅ Add .env to .gitignore
- ✅ Rotate keys regularly
- ❌ Never hardcode API keys

#### Secure Storage
- ✅ Use flutter_secure_storage for sensitive data
- ✅ Store tokens, never passwords
- ✅ Clear data on logout
- ❌ Never use SharedPreferences for sensitive data

#### Authentication
- ✅ Implement token refresh
- ✅ Use biometrics when available
- ✅ Handle token expiration gracefully
- ❌ Never store passwords

#### Network Security
- ✅ Always use HTTPS
- ✅ Implement SSL pinning for production
- ✅ Validate certificates
- ❌ Never disable certificate validation

#### Input Validation
- ✅ Validate all user input
- ✅ Sanitize data before display
- ✅ Enforce password complexity
- ✅ Set maximum input lengths
- ❌ Never trust user input

#### Code Protection
- ✅ Enable obfuscation for release builds
- ✅ Keep debug symbols for crash reporting
- ✅ Protect sensitive screens from screenshots
- ❌ Don't rely only on obfuscation

#### Platform Security
- ✅ Request only necessary permissions
- ✅ Disable cleartext traffic
- ✅ Configure network security
- ✅ Enable data protection

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0
