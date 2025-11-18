---
type: "always_apply"
description: "Example description"
---

# Flutter Development Guidelines - Core Principles

> **Universal best practices applicable to all Flutter projects, regardless of size or complexity**

---

## Table of Contents
- [Code Quality Fundamentals](#code-quality-fundamentals)
- [Dart/Flutter Best Practices](#dartflutter-best-practices)
- [File Organization](#file-organization)
- [Functions and Methods](#functions-and-methods)
- [Classes and Objects](#classes-and-objects)
- [Error Handling](#error-handling)
- [Performance Optimization](#performance-optimization)
- [UI and Styling](#ui-and-styling)
- [Model Conventions](#model-conventions)

---

## Code Quality Fundamentals

### Principle: Write Clear, Type-Safe Code

#### ✅ DO: Always declare types explicitly

```dart
// ✅ CORRECT: Explicit types make code self-documenting and catch errors at compile time
class UserRepository {
  final ApiClient apiClient;
  final CacheManager cacheManager;
  
  UserRepository({
    required this.apiClient,
    required this.cacheManager,
  });
  
  Future<User> fetchUser(String userId) async {
    final response = await apiClient.get('/users/$userId');
    return User.fromJson(response.data);
  }
  
  List<String> getUserIds(List<User> users) {
    return users.map((user) => user.id).toList();
  }
}
```

#### ❌ DON'T: Use dynamic or omit types

```dart
// ❌ INCORRECT: Dynamic types hide errors and make code hard to understand
class UserRepository {
  var apiClient; // What type is this? No IDE support!
  var cacheManager;
  
  UserRepository(this.apiClient, this.cacheManager); // No type safety
  
  fetchUser(userId) async { // What does this return? What type is userId?
    var response = await apiClient.get('/users/$userId');
    return User.fromJson(response.data); // Runtime error if response is wrong type
  }
  
  getUserIds(users) { // What type of list? What does it return?
    return users.map((user) => user.id).toList();
  }
}
```

**Why it matters:**
- ❌ Runtime errors instead of compile-time errors
- ❌ No IDE autocomplete or refactoring support
- ❌ Harder to understand code intent
- ❌ Difficult to maintain and debug

---

### Principle: Use Descriptive Names with Auxiliary Verbs

#### ✅ DO: Use meaningful names that describe purpose

```dart
// ✅ CORRECT: Clear, self-documenting variable names
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  bool hasError = false;
  bool canSubmit = false;
  String? errorMessage;
  
  void _validateForm() {
    final email = _emailController.text;
    final password = _passwordController.text;
    
    setState(() {
      canSubmit = email.isNotEmpty && 
                  password.length >= 8 &&
                  _isValidEmail(email);
    });
  }
  
  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }
}
```

#### ❌ DON'T: Use vague or abbreviated names

```dart
// ❌ INCORRECT: Unclear variable names
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false; // Is it loading? Will it load? Was it loading?
  bool err = false; // What kind of error?
  bool ok = false; // OK for what?
  String? msg; // What message?
  
  void _validate() { // Validate what?
    final e = _emailController.text; // e for email? Could be anything
    final p = _passwordController.text; // p for password? Unclear
    
    setState(() {
      ok = e.isNotEmpty && p.length >= 8 && _chk(e); // What is chk?
    });
  }
  
  bool _chk(String s) { // Check what? What is s?
    return s.contains('@') && s.contains('.');
  }
}
```

**Why it matters:**
- ❌ Code is harder to read and understand
- ❌ Increases cognitive load for other developers
- ❌ Makes debugging more difficult
- ❌ Reduces code maintainability

---

### Principle: Centralize String Constants

#### ✅ DO: Define all constant strings in a centralized constants file

```dart
// ✅ CORRECT: Centralized string constants
// lib/core/constants/app_constants.dart
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  // UI Labels
  static const String loginButton = 'Login';
  static const String signUpButton = 'Sign Up';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String submitButton = 'Submit';
  static const String cancelButton = 'Cancel';

  // Error Messages
  static const String invalidEmailError = 'Please enter a valid email address';
  static const String passwordTooShortError = 'Password must be at least 8 characters';
  static const String requiredFieldError = 'This field is required';
  static const String networkError = 'No internet connection. Please check your network.';

  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String profileUpdated = 'Profile updated successfully';
}

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.example.com';
  static const String users = '/users';
  static const String products = '/products';
  static const String orders = '/orders';
}

class StorageKeys {
  StorageKeys._();

  static const String userToken = 'user_token';
  static const String themePreference = 'theme_preference';
  static const String languageCode = 'language_code';
}

class RouteNames {
  RouteNames._();

  static const String home = '/home';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

// Usage in widgets
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: AppStrings.emailLabel, // ✅ Using constant
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text(AppStrings.loginButton), // ✅ Using constant
          ),
        ],
      ),
    );
  }
}

// Usage in validation
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return AppStrings.requiredFieldError; // ✅ Using constant
  }
  if (!email.contains('@')) {
    return AppStrings.invalidEmailError; // ✅ Using constant
  }
  return null;
}

// Usage in navigation
Navigator.pushNamed(context, RouteNames.home); // ✅ Using constant

// Usage in API calls
final response = await http.get('${ApiEndpoints.baseUrl}${ApiEndpoints.users}');
```

#### ❌ DON'T: Hardcode strings throughout the codebase

```dart
// ❌ INCORRECT: Hardcoded strings scattered everywhere
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Email Address', // ❌ Hardcoded
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('Login'), // ❌ Hardcoded
          ),
        ],
      ),
    );
  }
}

// ❌ Hardcoded error messages
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return 'This field is required'; // ❌ Hardcoded
  }
  if (!email.contains('@')) {
    return 'Please enter a valid email address'; // ❌ Hardcoded (typo risk!)
  }
  return null;
}

// ❌ Hardcoded route names
Navigator.pushNamed(context, '/home'); // ❌ Hardcoded (typo risk!)

// ❌ Hardcoded API endpoints
final response = await http.get('https://api.example.com/users'); // ❌ Hardcoded
```

**Why it matters:**
- ❌ Inconsistent text across the app (e.g., "Login" vs "Log In" vs "Sign In")
- ❌ Typos in hardcoded strings cause runtime errors (e.g., '/hom' instead of '/home')
- ❌ Difficult to update text globally (must search and replace across many files)
- ❌ Makes future localization/internationalization extremely difficult
- ❌ No compile-time safety for string references
- ✅ Centralized constants provide single source of truth
- ✅ IDE autocomplete helps prevent typos
- ✅ Easy to update text globally by changing one constant
- ✅ Simplifies future localization efforts
- ✅ Improves code searchability and refactoring

**Exceptions (strings that should NOT be constants):**
- Dynamic content from APIs or databases
- User-generated content
- Formatted strings with runtime variables (use string interpolation with constant templates)
- Localized strings (use `intl`, `easy_localization`, or `flutter_localizations` packages instead)

**Example with string interpolation:**
```dart
// ✅ CORRECT: Constant template with dynamic values
class AppStrings {
  static const String welcomeMessageTemplate = 'Welcome back, {name}!';
  static const String itemsInCartTemplate = 'You have {count} items in your cart';
}

// Usage with interpolation
String getWelcomeMessage(String userName) {
  return AppStrings.welcomeMessageTemplate.replaceAll('{name}', userName);
}

// Or using Dart's string interpolation
String getItemsMessage(int count) {
  return 'You have $count items in your cart'; // Dynamic part is the variable
}
```

---

## Dart/Flutter Best Practices

### Principle: Use const Constructors for Immutable Widgets

#### ✅ DO: Use const for widgets that don't change

```dart
// ✅ CORRECT: const widgets are not rebuilt, improving performance
class ProductCard extends StatelessWidget {
  final String title;
  final double price;
  
  const ProductCard({
    Key? key,
    required this.title,
    required this.price,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0), // const padding
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle( // const style
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8), // const spacer
            Text('\$$price'),
          ],
        ),
      ),
    );
  }
}

// Usage with const constructor
const ProductCard(title: 'Widget', price: 9.99)
```

#### ❌ DON'T: Omit const when possible

```dart
// ❌ INCORRECT: Missing const causes unnecessary rebuilds
class ProductCard extends StatelessWidget {
  final String title;
  final double price;

  ProductCard({ // Missing const
    Key? key,
    required this.title,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0), // Missing const - creates new object every build
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle( // Missing const - creates new object every build
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8), // Missing const - creates new object every build
            Text('\$$price'),
          ],
        ),
      ),
    );
  }
}

// Usage without const
ProductCard(title: 'Widget', price: 9.99) // Widget rebuilt unnecessarily
```

**Why it matters:**
- ❌ Performance degradation - widgets rebuilt unnecessarily
- ❌ Increased memory usage - new objects created on every build
- ❌ Slower UI rendering, especially in lists
- ✅ Using const can improve performance by 2-3x in widget-heavy UIs

**Performance Impact:**
```dart
// ❌ BAD: In a ListView with 1000 items, this creates 1000 new objects per scroll
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) {
    return ProductCard(title: 'Item $index', price: 9.99);
  },
)

// ✅ GOOD: Reuses the same widget instance
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) {
    return const ProductCard(title: 'Item', price: 9.99);
  },
)
```

---

### Principle: Prefer Composition Over Inheritance

#### ✅ DO: Compose widgets from smaller pieces

```dart
// ✅ CORRECT: Composition makes code flexible and reusable
class UserProfile extends StatelessWidget {
  final User user;

  const UserProfile({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserAvatar(imageUrl: user.avatarUrl), // Composed widget
        UserInfo(user: user), // Composed widget
        UserStats(user: user), // Composed widget
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String imageUrl;

  const UserAvatar({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}

class UserInfo extends StatelessWidget {
  final User user;

  const UserInfo({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(user.name, style: Theme.of(context).textTheme.titleLarge),
        Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
```

#### ❌ DON'T: Use deep inheritance hierarchies

```dart
// ❌ INCORRECT: Deep inheritance makes code rigid and hard to modify
abstract class BaseProfile extends StatelessWidget {
  final User user;
  const BaseProfile({Key? key, required this.user}) : super(key: key);

  Widget buildAvatar();
  Widget buildInfo();
  Widget buildStats();
}

abstract class StandardProfile extends BaseProfile {
  const StandardProfile({Key? key, required User user})
      : super(key: key, user: user);

  @override
  Widget buildAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(user.avatarUrl),
    );
  }
}

class UserProfile extends StandardProfile {
  const UserProfile({Key? key, required User user})
      : super(key: key, user: user);

  @override
  Widget buildInfo() {
    return Column(
      children: [
        Text(user.name),
        Text(user.email),
      ],
    );
  }

  @override
  Widget buildStats() {
    return Text('Stats here');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildAvatar(),
        buildInfo(),
        buildStats(),
      ],
    );
  }
}
```

**Why it matters:**
- ❌ Hard to understand the widget hierarchy
- ❌ Difficult to reuse individual components
- ❌ Changes to base class affect all subclasses
- ❌ Testing becomes more complex
- ✅ Composition allows mixing and matching components easily

---

### Principle: Use Trailing Commas for Better Formatting

#### ✅ DO: Add trailing commas for multi-line parameters

```dart
// ✅ CORRECT: Trailing commas enable better auto-formatting
class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;

  const UserCard({
    Key? key,
    required this.name,
    required this.email,
    required this.avatarUrl, // Trailing comma
  }) : super(key: key); // Trailing comma

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl),
        ), // Trailing comma
        title: Text(name),
        subtitle: Text(email),
      ), // Trailing comma
    ); // Trailing comma
  }
}
```

#### ❌ DON'T: Omit trailing commas

```dart
// ❌ INCORRECT: No trailing commas makes formatting messy
class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;

  const UserCard({
    Key? key,
    required this.name,
    required this.email,
    required this.avatarUrl // No trailing comma - harder to add new parameters
  }) : super(key: key); // No trailing comma

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl)
        ), // No trailing comma - auto-formatter can't help
        title: Text(name),
        subtitle: Text(email)
      ) // No trailing comma - messy diffs when adding parameters
    ); // No trailing comma
  }
}
```

**Why it matters:**
- ❌ Git diffs show changes on multiple lines when adding parameters
- ❌ Auto-formatter can't properly format the code
- ❌ Harder to add new parameters
- ✅ Trailing commas make diffs cleaner (only the new line shows as changed)

**Git Diff Example:**
```diff
// ❌ WITHOUT trailing comma - 2 lines changed
- required this.avatarUrl
+ required this.avatarUrl,
+ required this.phoneNumber

// ✅ WITH trailing comma - 1 line changed
  required this.avatarUrl,
+ required this.phoneNumber,
```

---

## Functions and Methods

### Principle: Write Short, Focused Functions

#### ✅ DO: Keep functions under 30 lines with single purpose

```dart
// ✅ CORRECT: Small, focused functions
class OrderService {
  Future<Order> createOrder(List<CartItem> items, User user) async {
    _validateItems(items);
    final total = _calculateTotal(items);
    final order = _buildOrder(items, user, total);
    return await _saveOrder(order);
  }

  void _validateItems(List<CartItem> items) {
    if (items.isEmpty) {
      throw ValidationException('Cart cannot be empty');
    }
    for (final item in items) {
      if (item.quantity <= 0) {
        throw ValidationException('Invalid quantity for ${item.name}');
      }
    }
  }

  double _calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Order _buildOrder(List<CartItem> items, User user, double total) {
    return Order(
      id: _generateOrderId(),
      userId: user.id,
      items: items,
      total: total,
      createdAt: DateTime.now(),
    );
  }

  Future<Order> _saveOrder(Order order) async {
    return await _repository.save(order);
  }

  String _generateOrderId() {
    return 'ORD-${DateTime.now().millisecondsSinceEpoch}';
  }
}
```

#### ❌ DON'T: Write long, multi-purpose functions

```dart
// ❌ INCORRECT: Long function doing too many things (50+ lines)
class OrderService {
  Future<Order> createOrder(List<CartItem> items, User user) async {
    // Validation
    if (items.isEmpty) {
      throw ValidationException('Cart cannot be empty');
    }
    for (final item in items) {
      if (item.quantity <= 0) {
        throw ValidationException('Invalid quantity for ${item.name}');
      }
      if (item.price < 0) {
        throw ValidationException('Invalid price for ${item.name}');
      }
    }

    // Calculate total
    double total = 0.0;
    for (final item in items) {
      total += item.price * item.quantity;
    }

    // Apply discounts
    if (user.isPremium) {
      total *= 0.9; // 10% discount
    }
    if (total > 100) {
      total -= 10; // $10 off for orders over $100
    }

    // Generate order ID
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    // Build order object
    final order = Order(
      id: orderId,
      userId: user.id,
      items: items,
      total: total,
      createdAt: DateTime.now(),
    );

    // Save to database
    try {
      await _repository.save(order);
    } catch (e) {
      print('Error saving order: $e');
      rethrow;
    }

    // Send confirmation email
    try {
      await _emailService.sendOrderConfirmation(user.email, order);
    } catch (e) {
      print('Error sending email: $e');
      // Don't fail the order if email fails
    }

    // Update inventory
    for (final item in items) {
      await _inventoryService.decrementStock(item.productId, item.quantity);
    }

    return order;
  }
}
```

**Why it matters:**
- ❌ Hard to understand what the function does
- ❌ Difficult to test individual pieces
- ❌ Hard to reuse logic
- ❌ Violates Single Responsibility Principle
- ✅ Small functions are easier to test, understand, and maintain

---

### Principle: Use Early Returns to Avoid Nesting

#### ✅ DO: Return early to reduce nesting

```dart
// ✅ CORRECT: Early returns keep code flat and readable
class UserValidator {
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    if (!email.contains('@')) {
      return 'Email must contain @';
    }

    if (!email.contains('.')) {
      return 'Email must contain a domain';
    }

    if (email.length < 5) {
      return 'Email is too short';
    }

    return null; // Valid
  }

  Future<User?> getUser(String userId) async {
    if (userId.isEmpty) {
      return null;
    }

    final cached = _cache.get(userId);
    if (cached != null) {
      return cached;
    }

    final user = await _repository.fetchUser(userId);
    if (user != null) {
      _cache.set(userId, user);
    }

    return user;
  }
}
```

#### ❌ DON'T: Use deep nesting

```dart
// ❌ INCORRECT: Deep nesting is hard to follow
class UserValidator {
  String? validateEmail(String? email) {
    if (email != null && email.isNotEmpty) {
      if (email.contains('@')) {
        if (email.contains('.')) {
          if (email.length >= 5) {
            return null; // Valid - buried 4 levels deep!
          } else {
            return 'Email is too short';
          }
        } else {
          return 'Email must contain a domain';
        }
      } else {
        return 'Email must contain @';
      }
    } else {
      return 'Email is required';
    }
  }

  Future<User?> getUser(String userId) async {
    if (userId.isNotEmpty) {
      final cached = _cache.get(userId);
      if (cached != null) {
        return cached;
      } else {
        final user = await _repository.fetchUser(userId);
        if (user != null) {
          _cache.set(userId, user);
          return user;
        } else {
          return null;
        }
      }
    } else {
      return null;
    }
  }
}
```

**Why it matters:**
- ❌ Deep nesting increases cognitive load
- ❌ Harder to follow the logic flow
- ❌ More prone to bugs
- ✅ Flat code is easier to read and maintain

---

## Performance Optimization

### Principle: Avoid Deeply Nested Widget Trees

#### ✅ DO: Extract widgets to reduce nesting

```dart
// ✅ CORRECT: Flat widget tree with extracted components
class ProductListScreen extends StatelessWidget {
  final List<Product> products;

  const ProductListScreen({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ProductList(products: products),
    );
  }
}

class ProductList extends StatelessWidget {
  final List<Product> products;

  const ProductList({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductListItem(product: products[index]);
      },
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;

  const ProductListItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ProductImage(url: product.imageUrl),
        title: Text(product.name),
        subtitle: ProductPrice(price: product.price),
        trailing: AddToCartButton(product: product),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String url;

  const ProductImage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: 50,
      height: 50,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    );
  }
}
```

#### ❌ DON'T: Create deeply nested widget trees

```dart
// ❌ INCORRECT: Deeply nested, hard to read and maintain
class ProductListScreen extends StatelessWidget {
  final List<Product> products;

  const ProductListScreen({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: ListTile(
              leading: Image.network(
                product.imageUrl,
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error);
                },
              ),
              title: Text(product.name),
              subtitle: Row(
                children: [
                  const Icon(Icons.attach_money, size: 16),
                  Text(
                    product.price.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {
                  // Add to cart logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          // Undo logic
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Harder to read and understand
- ❌ Difficult to reuse components
- ❌ Harder to test individual pieces
- ❌ Performance issues - entire tree rebuilds
- ✅ Extracted widgets can be const, improving performance

---

### Principle: Use ListView.builder for Long Lists

#### ✅ DO: Use builder for efficient list rendering

```dart
// ✅ CORRECT: ListView.builder only builds visible items
class MessageList extends StatelessWidget {
  final List<Message> messages;

  const MessageList({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageTile(message: message);
      },
    );
  }
}

// Even better: Use ListView.separated for dividers
class MessageListWithDividers extends StatelessWidget {
  final List<Message> messages;

  const MessageListWithDividers({Key? key, required this.messages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: messages.length,
      itemBuilder: (context, index) => MessageTile(message: messages[index]),
      separatorBuilder: (context, index) => const Divider(),
    );
  }
}
```

#### ❌ DON'T: Use ListView with children for long lists

```dart
// ❌ INCORRECT: Creates all widgets at once, even if not visible
class MessageList extends StatelessWidget {
  final List<Message> messages;

  const MessageList({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: messages.map((message) {
        return MessageTile(message: message);
      }).toList(), // Creates ALL widgets immediately!
    );
  }
}

// Even worse: Using Column in SingleChildScrollView
class MessageListWorse extends StatelessWidget {
  final List<Message> messages;

  const MessageListWorse({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: messages.map((message) {
          return MessageTile(message: message);
        }).toList(), // Creates ALL widgets AND lays them out!
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Memory issues with large lists (1000+ items)
- ❌ Slow initial render time
- ❌ Janky scrolling performance
- ✅ ListView.builder only creates visible widgets (60fps smooth scrolling)

**Performance Comparison:**
```
List with 10,000 items:
❌ ListView(children: ...) - 5000ms initial render, 500MB memory
✅ ListView.builder(...) - 16ms initial render, 50MB memory
```

---

## Error Handling

### Principle: Handle Errors Gracefully

#### ✅ DO: Provide user-friendly error messages

```dart
// ✅ CORRECT: Clear error handling with user-friendly messages
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Navigate to home on success
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on NetworkException {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network.';
      });
    } on InvalidCredentialsException {
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    } on ServerException catch (e) {
      setState(() {
        _errorMessage = 'Server error: ${e.message}. Please try again later.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      // Log the error for debugging
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_errorMessage != null)
            ErrorBanner(message: _errorMessage!),
          // Login form...
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

#### ❌ DON'T: Ignore errors or show technical messages

```dart
// ❌ INCORRECT: Poor error handling
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleLogin() async {
    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // ❌ Shows technical error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // "Error: SocketException: Failed host lookup"
      );
    }
  }

  // Even worse: Silently ignoring errors
  Future<void> _handleLoginSilent() async {
    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // ❌ Error silently ignored - user has no idea what happened!
      print('Login failed: $e');
    }
  }

  // Also bad: Using print instead of proper logging
  Future<void> _handleLoginWithPrint() async {
    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      print('Error: $e'); // ❌ print statements removed in release builds
    }
  }
}
```

**Why it matters:**
- ❌ Technical errors confuse users
- ❌ Silent failures leave users wondering what happened
- ❌ print() doesn't work in release mode
- ✅ Clear error messages improve user experience
- ✅ Proper logging helps debugging

---

## UI and Styling

### Principle: Use Theme for Consistent Styling

#### ✅ DO: Use Theme.of(context) for styling

```dart
// ✅ CORRECT: Uses theme for consistent, maintainable styling
class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: theme.textTheme.titleLarge, // ✅ Uses theme
            ),
            const SizedBox(height: 8),
            Text(
              article.author,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary, // ✅ Uses theme colors
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.content,
              style: theme.textTheme.bodySmall, // ✅ Uses theme
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

#### ❌ DON'T: Hardcode styles throughout the app

```dart
// ❌ INCORRECT: Hardcoded styles are inconsistent and hard to maintain
class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: const TextStyle( // ❌ Hardcoded
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.author,
              style: const TextStyle( // ❌ Hardcoded
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.content,
              style: const TextStyle( // ❌ Hardcoded
                fontSize: 12,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Inconsistent styling across the app
- ❌ Hard to implement dark mode
- ❌ Difficult to rebrand or change theme
- ❌ Accessibility issues (can't respect user font size preferences)
- ✅ Theme-based styling is consistent and maintainable

**Dark Mode Example:**
```dart
// ✅ With theme - dark mode works automatically
Text('Hello', style: Theme.of(context).textTheme.bodyLarge)

// ❌ Hardcoded - stays black even in dark mode
Text('Hello', style: TextStyle(color: Colors.black))
```

---

## Model Conventions

### Principle: Use Proper JSON Serialization

#### ✅ DO: Use json_serializable with proper annotations

```dart
// ✅ CORRECT: Proper JSON serialization with snake_case mapping
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  @JsonKey(includeFromJson: true, includeToJson: false)
  final DateTime createdAt;

  @JsonKey(includeFromJson: true, includeToJson: false)
  final DateTime updatedAt;

  @JsonKey(defaultValue: false)
  final bool isDeleted;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// API response: {"id": "123", "first_name": "John", "last_name": "Doe", ...}
// Automatically maps to: User(firstName: "John", lastName: "Doe", ...)
```

#### ❌ DON'T: Manually parse JSON

```dart
// ❌ INCORRECT: Manual JSON parsing is error-prone
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  // ❌ Manual parsing - error-prone and verbose
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String, // Runtime error if null or wrong type
      firstName: json['first_name'] as String, // Easy to typo
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String), // Can crash
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  // ❌ Manual serialization - easy to forget fields
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      // ❌ Forgot to exclude createdAt and updatedAt!
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
```

**Why it matters:**
- ❌ Manual parsing is error-prone
- ❌ Easy to make typos in field names
- ❌ No compile-time safety
- ❌ Verbose and repetitive
- ✅ Code generation catches errors at compile time
- ✅ Automatic snake_case ↔ camelCase conversion

---

## Summary: Quick Reference

### Code Quality Checklist

- [ ] All types explicitly declared (no `dynamic` or `var` without type)
- [ ] Variables use descriptive names with auxiliary verbs (isLoading, hasError)
- [ ] String constants centralized in `lib/core/constants/app_constants.dart`
- [ ] No hardcoded strings for UI labels, error messages, routes, or API endpoints
- [ ] Functions are short (< 30 lines) with single purpose
- [ ] Early returns used to avoid deep nesting
- [ ] Composition preferred over inheritance

### Performance Checklist

- [ ] `const` constructors used for immutable widgets
- [ ] `ListView.builder` used for long lists
- [ ] Widgets extracted to reduce nesting
- [ ] Trailing commas added for better formatting
- [ ] Images have error builders

### Error Handling Checklist

- [ ] User-friendly error messages (not technical stack traces)
- [ ] Errors logged with `debugPrint` or logging package (not `print`)
- [ ] Loading states shown during async operations
- [ ] Empty states handled gracefully

### UI/Styling Checklist

- [ ] `Theme.of(context)` used for styling
- [ ] `Theme.of(context).textTheme.titleLarge` instead of deprecated `headline6`
- [ ] Responsive design with `LayoutBuilder` or `MediaQuery`
- [ ] Accessibility considered (semantic labels, contrast)

### Model Checklist

- [ ] `@JsonSerializable(fieldRename: FieldRename.snake)` used
- [ ] `createdAt`, `updatedAt`, `isDeleted` fields included
- [ ] Read-only fields marked with `@JsonKey(includeFromJson: true, includeToJson: false)`
- [ ] Enums use `@JsonValue(int)` for database storage

---

## Next Steps

- **Small Projects:** See [State Management Guide](state-management-guide.md#small-projects) for setState patterns
- **Medium Projects:** See [State Management Guide](state-management-guide.md#medium-projects) for Provider patterns
- **Large Projects:** See [State Management Guide](state-management-guide.md#large-projects) for BLoC patterns
- **Testing:** See [Testing Guide](testing-guide.md) for comprehensive testing strategies
- **Security:** See [Security Best Practices](security-best-practices.md) for secure coding patterns

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0
```

