---
type: "agent_requested"
description: "Guide for choosing and implementing state management solutions (setState, Provider, BLoC, Cubit) based on project size and complexity with decision trees and migration strategies."
---

# Flutter State Management Guide

> **Comprehensive guide to choosing and implementing state management based on project size**

---

## Table of Contents
- [Decision Tree](#decision-tree)
- [Choosing Based on Developer Preference](#choosing-based-on-developer-preference)
- [Small Projects: Built-in State Management](#small-projects-built-in-state-management)
  - [setState](#setstate)
  - [InheritedWidget](#inheritedwidget)
  - [ValueNotifier & ChangeNotifier](#valuenotifier--changenotifier)
- [Medium Projects: Provider](#medium-projects-provider)
- [Large Projects: BLoC/Cubit](#large-projects-bloccubit)
- [Comparison Matrix](#comparison-matrix)
- [Migration Strategies](#migration-strategies)

---

## Decision Tree

```
Start Here
    |
    ├─ 1-5 screens, 1-2 developers, < 3 months?
    |   └─ YES → Recommended: Built-in State Management (setState, InheritedWidget, ValueNotifier, Cubit)
    |
    ├─ 5-20 screens, 2-5 developers, 3-12 months?
    |   └─ YES → Recommended: Provider, Cubit
    |
    └─ 20+ screens, 5+ developers, 12+ months?
        └─ YES → Recommended: BLoC, Cubit
```

### Quick Selection Guide

| Project Size | Screens | Team Size | Duration | Recommended State Management | Complexity |
|--------------|---------|-----------|----------|------------------------------|------------|
| **Small** | 1-5 | 1-2 | < 3 months | setState, InheritedWidget, ValueNotifier, Cubit | ⭐ Low |
| **Medium** | 5-20 | 2-5 | 3-12 months | Provider, Cubit | ⭐⭐ Medium |
| **Large** | 20+ | 5+ | 12+ months | BLoC, Cubit | ⭐⭐⭐ High |

---

## Choosing Based on Developer Preference

### 🎨 Flexibility Over Rigidity

**Important Principle:** The recommendations above are **guidelines based on typical complexity needs**, not strict requirements. Your choice of state management should be driven by:

#### ✅ Primary Decision Factors

1. **Developer Preference & Comfort**
   - Use what you understand deeply and can implement correctly
   - Mastery of a "simpler" solution often beats poor implementation of a "better" solution

2. **Team Familiarity & Expertise**
   - Leverage existing team knowledge rather than forcing a new pattern
   - Training time and learning curve impact project velocity

3. **Project Consistency**
   - Using the same pattern across all your projects improves productivity
   - Reduces context switching and mental overhead

4. **Actual Complexity Needs**
   - Match the solution to your real state complexity, not just project size
   - A small project with complex state logic might benefit from BLoC
   - A large project with simple state might work fine with Provider

#### 🟢 Valid Scenarios (All Acceptable)

**Using "Advanced" Patterns in Small Projects:**
```dart
// ✅ VALID: Using Cubit in a small 3-screen app for consistency
// Reason: Developer uses Cubit in all projects for muscle memory
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}
// Even though setState would work, Cubit provides consistency
```

**Using "Simple" Patterns in Large Projects:**
```dart
// ✅ VALID: Using Provider in a 50-screen enterprise app
// Reason: Team has 3 years of Provider experience, zero BLoC experience
class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }
}
// Team can maintain this effectively, which matters more than "best practice"
```

**Mixing State Management Approaches:**
```dart
// ✅ VALID: Hybrid approach based on complexity
// Simple state: Provider
class ThemeProvider extends ChangeNotifier { ... }

// Complex state: Cubit
class AuthCubit extends Cubit<AuthState> { ... }
class CheckoutCubit extends Cubit<CheckoutState> { ... }

// This pragmatic approach uses the right tool for each job
```

**Starting with BLoC for Known Scale:**
```dart
// ✅ VALID: Using BLoC from day one in a 5-screen MVP
// Reason: Team knows this will scale to 100+ screens in 6 months
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  // Starting with BLoC avoids costly migration later
}
```

#### ❌ What NOT to Do

**Don't choose based on:**
- ❌ "This is what everyone uses" (popularity ≠ right fit)
- ❌ "This is the most advanced" (complexity without benefit)
- ❌ "This is what the tutorial used" (tutorials optimize for teaching, not production)
- ❌ Project size alone (consider actual state complexity)

**Don't mix poorly:**
- ❌ Using setState AND Cubit for the same state (dual source of truth)
- ❌ Switching patterns mid-project without clear migration plan
- ❌ Using different patterns per developer (team consistency matters)

#### 🎯 Decision Framework

Ask yourself these questions:

1. **Can my team implement this correctly?**
   - If no → Choose something simpler

2. **Can my team maintain this long-term?**
   - If no → Choose something more familiar

3. **Does this match our actual state complexity?**
   - If no → Adjust up or down

4. **Will this work across our project portfolio?**
   - If yes → Consistency bonus

5. **Are we solving a real problem or following a trend?**
   - If trend → Reconsider

**The Golden Rule:** Choose a state management solution that your team can implement correctly and maintain effectively. A well-implemented "simple" solution beats a poorly-implemented "advanced" solution every time.

---

## Small Projects: Built-in State Management

**Use when:**
- ✅ Prototyping or MVP
- ✅ Learning Flutter
- ✅ Personal projects
- ✅ Simple apps with minimal state sharing

**Advantages:**
- Zero dependencies
- Fastest development
- Minimal learning curve
- Perfect for simple use cases

**Limitations:**
- Doesn't scale well
- Can lead to prop drilling
- Limited testing capabilities

---

### setState

**Best for:** Local widget state that doesn't need to be shared

#### ✅ DO: Use setState for simple, local state

```dart
// ✅ CORRECT: setState for counter - simple local state
class CounterScreen extends StatefulWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++; // Only updates this widget
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

#### ✅ DO: Use setState for form state

```dart
// ✅ CORRECT: setState for form validation
class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
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

#### ❌ DON'T: Use setState for shared state across widgets

```dart
// ❌ INCORRECT: Passing setState callbacks through multiple widgets (prop drilling)
class ShoppingApp extends StatefulWidget {
  @override
  State<ShoppingApp> createState() => _ShoppingAppState();
}

class _ShoppingAppState extends State<ShoppingApp> {
  List<Product> _cart = [];

  void _addToCart(Product product) {
    setState(() {
      _cart.add(product);
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      _cart.remove(product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ❌ Passing callbacks through multiple levels
        ProductList(
          onAddToCart: _addToCart, // Prop drilling
        ),
        CartWidget(
          cart: _cart,
          onRemove: _removeFromCart, // Prop drilling
        ),
      ],
    );
  }
}

class ProductList extends StatelessWidget {
  final Function(Product) onAddToCart;

  const ProductList({Key? key, required this.onAddToCart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ProductCard(onAddToCart: onAddToCart), // ❌ Passing down again
        ProductCard(onAddToCart: onAddToCart),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Function(Product) onAddToCart;

  const ProductCard({Key? key, required this.onAddToCart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onAddToCart(Product()), // ❌ Finally used here
      child: const Text('Add to Cart'),
    );
  }
}
```

**Why it matters:**
- ❌ Prop drilling makes code hard to maintain
- ❌ Every intermediate widget needs to know about the callback
- ❌ Difficult to add new features
- ❌ Hard to test
- ✅ Use InheritedWidget or Provider for shared state instead

---

### InheritedWidget

**Best for:** Sharing state down the widget tree without prop drilling

#### ✅ DO: Use InheritedWidget for shared state

```dart
// ✅ CORRECT: InheritedWidget for theme or configuration
class AppConfig extends InheritedWidget {
  final String apiUrl;
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const AppConfig({
    Key? key,
    required this.apiUrl,
    required this.isDarkMode,
    required this.toggleTheme,
    required Widget child,
  }) : super(key: key, child: child);

  static AppConfig of(BuildContext context) {
    final AppConfig? result = context.dependOnInheritedWidgetOfExactType<AppConfig>();
    assert(result != null, 'No AppConfig found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppConfig oldWidget) {
    return apiUrl != oldWidget.apiUrl || isDarkMode != oldWidget.isDarkMode;
  }
}

// Usage in parent widget
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppConfig(
      apiUrl: 'https://api.example.com',
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
        home: const HomeScreen(),
      ),
    );
  }
}

// Usage in child widget (no prop drilling!)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.of(context); // ✅ Access anywhere in tree

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SwitchListTile(
        title: const Text('Dark Mode'),
        value: config.isDarkMode,
        onChanged: (_) => config.toggleTheme(),
      ),
    );
  }
}
```

#### ✅ DO: Use InheritedWidget for dependency injection

```dart
// ✅ CORRECT: InheritedWidget for simple DI
class ServiceProvider extends InheritedWidget {
  final ApiService apiService;
  final AuthService authService;
  final StorageService storageService;

  const ServiceProvider({
    Key? key,
    required this.apiService,
    required this.authService,
    required this.storageService,
    required Widget child,
  }) : super(key: key, child: child);

  static ServiceProvider of(BuildContext context) {
    final ServiceProvider? result =
        context.dependOnInheritedWidgetOfExactType<ServiceProvider>();
    assert(result != null, 'No ServiceProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ServiceProvider oldWidget) => false;
}

// Setup in main.dart
void main() {
  final apiService = ApiService();
  final authService = AuthService(apiService);
  final storageService = StorageService();

  runApp(
    ServiceProvider(
      apiService: apiService,
      authService: authService,
      storageService: storageService,
      child: const MyApp(),
    ),
  );
}

// Usage in any widget
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = ServiceProvider.of(context);

    return ElevatedButton(
      onPressed: () async {
        await services.authService.login('email', 'password');
      },
      child: const Text('Login'),
    );
  }
}
```

#### ❌ DON'T: Use InheritedWidget for frequently changing state

```dart
// ❌ INCORRECT: InheritedWidget for rapidly changing state
class CounterProvider extends InheritedWidget {
  final int counter;
  final VoidCallback increment;

  const CounterProvider({
    Key? key,
    required this.counter,
    required this.increment,
    required Widget child,
  }) : super(key: key, child: child);

  static CounterProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CounterProvider>()!;
  }

  @override
  bool updateShouldNotify(CounterProvider oldWidget) {
    return counter != oldWidget.counter; // ❌ Rebuilds entire tree on every increment!
  }
}

// ❌ Every widget below CounterProvider rebuilds on every counter change
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return CounterProvider(
      counter: _counter,
      increment: () => setState(() => _counter++),
      child: MaterialApp( // ❌ Entire app rebuilds on every increment!
        home: Scaffold(
          body: Column(
            children: [
              const HeavyWidget(), // ❌ Rebuilds unnecessarily
              const AnotherHeavyWidget(), // ❌ Rebuilds unnecessarily
              const CounterDisplay(), // Only this needs to rebuild
            ],
          ),
        ),
      ),
    );
  }
}
```

**Why it matters:**
- ❌ Rebuilds entire widget subtree on every change
- ❌ Performance issues with frequently changing state
- ❌ No granular control over rebuilds
- ✅ Use ValueNotifier or Provider for frequently changing state

---

### ValueNotifier & ChangeNotifier

**Best for:** Reactive state updates with minimal boilerplate

#### ✅ DO: Use ValueNotifier for simple reactive state

```dart
// ✅ CORRECT: ValueNotifier for counter with reactive updates
class CounterScreen extends StatefulWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  @override
  void dispose() {
    _counter.dispose(); // ✅ Always dispose
    super.dispose();
  }

  void _incrementCounter() {
    _counter.value++; // ✅ Automatically notifies listeners
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            ValueListenableBuilder<int>(
              valueListenable: _counter,
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

#### ✅ DO: Use ChangeNotifier for complex state

```dart
// ✅ CORRECT: ChangeNotifier for shopping cart
class CartModel extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  void addItem(Product product) {
    _items.add(product);
    notifyListeners(); // ✅ Notify after state change
  }

  void removeItem(Product product) {
    _items.remove(product);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// Usage with ValueListenableBuilder
class ShoppingApp extends StatefulWidget {
  @override
  State<ShoppingApp> createState() => _ShoppingAppState();
}

class _ShoppingAppState extends State<ShoppingApp> {
  final CartModel _cart = CartModel();

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductList(cart: _cart),
        AnimatedBuilder(
          animation: _cart,
          builder: (context, child) {
            return CartSummary(
              itemCount: _cart.itemCount,
              totalPrice: _cart.totalPrice,
            );
          },
        ),
      ],
    );
  }
}

class ProductList extends StatelessWidget {
  final CartModel cart;

  const ProductList({Key? key, required this.cart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ProductCard(
          product: Product(name: 'Widget', price: 9.99),
          onAddToCart: cart.addItem,
        ),
        ProductCard(
          product: Product(name: 'Flutter', price: 19.99),
          onAddToCart: cart.addItem,
        ),
      ],
    );
  }
}
```

#### ❌ DON'T: Forget to call notifyListeners()

```dart
// ❌ INCORRECT: Missing notifyListeners() - UI won't update!
class CartModel extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => _items;

  void addItem(Product product) {
    _items.add(product);
    // ❌ Missing notifyListeners() - listeners won't be notified!
  }

  void removeItem(Product product) {
    _items.remove(product);
    // ❌ Missing notifyListeners()
  }
}

// UI won't update when items are added/removed!
```

#### ❌ DON'T: Call notifyListeners() too frequently

```dart
// ❌ INCORRECT: Calling notifyListeners() in a loop
class CartModel extends ChangeNotifier {
  final List<Product> _items = [];

  void addMultipleItems(List<Product> products) {
    for (final product in products) {
      _items.add(product);
      notifyListeners(); // ❌ Rebuilds UI on every iteration!
    }
  }

  // ✅ BETTER: Notify once after all changes
  void addMultipleItemsCorrect(List<Product> products) {
    _items.addAll(products);
    notifyListeners(); // ✅ Single notification
  }
}
```

#### ❌ DON'T: Forget to dispose

```dart
// ❌ INCORRECT: Memory leak - ChangeNotifier not disposed
class ShoppingApp extends StatefulWidget {
  @override
  State<ShoppingApp> createState() => _ShoppingAppState();
}

class _ShoppingAppState extends State<ShoppingApp> {
  final CartModel _cart = CartModel();

  // ❌ Missing dispose() - memory leak!

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cart,
      builder: (context, child) {
        return Text('Items: ${_cart.itemCount}');
      },
    );
  }
}

// ✅ CORRECT: Always dispose
class _ShoppingAppStateCorrect extends State<ShoppingApp> {
  final CartModel _cart = CartModel();

  @override
  void dispose() {
    _cart.dispose(); // ✅ Prevents memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cart,
      builder: (context, child) {
        return Text('Items: ${_cart.itemCount}');
      },
    );
  }
}
```

**Why it matters:**
- ❌ Missing notifyListeners() means UI won't update
- ❌ Too many notifications cause performance issues
- ❌ Not disposing causes memory leaks
- ✅ Proper usage gives reactive updates with minimal code

---

### When to Migrate from Built-in State Management

**Migrate to Provider when:**
- ✅ You have more than 5 screens
- ✅ State needs to be shared across multiple screens
- ✅ You're experiencing prop drilling
- ✅ Team is growing beyond 2 developers
- ✅ Testing becomes difficult

**Warning signs:**
- ❌ Passing callbacks through 3+ widget levels
- ❌ Duplicating state across widgets
- ❌ Difficulty testing widgets in isolation
- ❌ Complex state synchronization logic

---

## Medium Projects: Provider

**Use when:**
- ✅ 5-20 screens
- ✅ 2-5 developers
- ✅ 3-12 months timeline
- ✅ Need to share state across multiple screens
- ✅ Want good testing capabilities

**Advantages:**
- Official Flutter recommendation
- Good balance of simplicity and power
- Excellent documentation
- Easy to test
- Minimal boilerplate
- Multiple provider types for different use cases

**Setup:**
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
```

---

### ChangeNotifierProvider

**Best for:** Mutable state that changes over time

#### ✅ DO: Use ChangeNotifierProvider for app-wide state

```dart
// ✅ CORRECT: ChangeNotifier for authentication state
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      _user = user;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}

// Setup in main.dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

// Usage with Consumer
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => auth.logout(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!auth.isAuthenticated) {
            return const Center(child: Text('Please login'));
          }

          return Center(
            child: Text('Welcome, ${auth.user!.name}!'),
          );
        },
      ),
    );
  }
}

// Usage with context.read() for actions (no rebuild)
class LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // ✅ context.read() doesn't rebuild when state changes
        context.read<AuthProvider>().login('email', 'password');
      },
      child: const Text('Login'),
    );
  }
}

// Usage with context.watch() for reactive updates
class UserGreeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ context.watch() rebuilds when state changes
    final auth = context.watch<AuthProvider>();

    return Text('Hello, ${auth.user?.name ?? "Guest"}');
  }
}
```

#### ❌ DON'T: Use Consumer when you only need to call methods

```dart
// ❌ INCORRECT: Using Consumer when you don't need to rebuild
class LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // ❌ This widget rebuilds every time AuthProvider changes,
        // even though we only need the login method
        return ElevatedButton(
          onPressed: () => auth.login('email', 'password'),
          child: const Text('Login'),
        );
      },
    );
  }
}

// ✅ CORRECT: Use context.read() for methods only
class LoginButtonCorrect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // ✅ No unnecessary rebuilds
        context.read<AuthProvider>().login('email', 'password');
      },
      child: const Text('Login'),
    );
  }
}
```

---

### MultiProvider

**Best for:** Apps with multiple providers

#### ✅ DO: Use MultiProvider for multiple state providers

```dart
// ✅ CORRECT: MultiProvider for organized state management
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ProxyProvider<AuthProvider, OrderProvider>(
          update: (_, auth, __) => OrderProvider(auth.user),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Access multiple providers
class CheckoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Text('User: ${auth.user?.name}'),
          Text('Items: ${cart.itemCount}'),
          Text('Total: \$${cart.totalPrice}'),
          ElevatedButton(
            onPressed: () {
              context.read<OrderProvider>().createOrder(cart.items);
            },
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }
}
```

#### ❌ DON'T: Nest providers deeply

```dart
// ❌ INCORRECT: Deeply nested providers are hard to read
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: ChangeNotifierProvider(
            create: (_) => OrderProvider(),
            child: const MyApp(), // ❌ Hard to read and maintain
          ),
        ),
      ),
    ),
  );
}
```

---

### FutureProvider

**Best for:** One-time async data loading

#### ✅ DO: Use FutureProvider for initial data loading

```dart
// ✅ CORRECT: FutureProvider for loading user profile
class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureProvider<User?>(
      create: (_) => UserService().fetchUser(userId),
      initialData: null,
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Consumer<User?>(
          builder: (context, user, child) {
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Text(user.name),
                Text(user.email),
                Text(user.bio),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

#### ❌ DON'T: Use FutureProvider for frequently changing data

```dart
// ❌ INCORRECT: FutureProvider doesn't refresh automatically
class MessageListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureProvider<List<Message>>(
      create: (_) => MessageService().fetchMessages(),
      initialData: const [],
      child: Consumer<List<Message>>(
        builder: (context, messages, child) {
          // ❌ Won't update when new messages arrive
          // ❌ No way to refresh the data
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return MessageTile(message: messages[index]);
            },
          );
        },
      ),
    );
  }
}

// ✅ CORRECT: Use StreamProvider for real-time data
class MessageListScreenCorrect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<Message>>(
      create: (_) => MessageService().messagesStream(),
      initialData: const [],
      child: Consumer<List<Message>>(
        builder: (context, messages, child) {
          // ✅ Updates automatically when stream emits new data
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return MessageTile(message: messages[index]);
            },
          );
        },
      ),
    );
  }
}
```

---

### StreamProvider

**Best for:** Real-time data that changes over time

#### ✅ DO: Use StreamProvider for real-time updates

```dart
// ✅ CORRECT: StreamProvider for real-time chat messages
class ChatScreen extends StatelessWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<Message>>(
      create: (_) => ChatService().messagesStream(chatId),
      initialData: const [],
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const MessageList(),
      ),
    );
  }
}

class MessageList extends StatelessWidget {
  const MessageList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<List<Message>>();

    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet'));
    }

    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  }
}

// Service with Stream
class ChatService {
  Stream<List<Message>> messagesStream(String chatId) {
    // ✅ Returns a stream that emits new data
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    });
  }
}
```

---

### Testing with Provider

#### ✅ DO: Override providers in tests

```dart
// ✅ CORRECT: Testing with provider overrides
void main() {
  testWidgets('Login button calls auth provider', (tester) async {
    final mockAuthProvider = MockAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Find and tap login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify login was called
    verify(mockAuthProvider.login(any, any)).called(1);
  });

  testWidgets('Shows user name when authenticated', (tester) async {
    final mockAuthProvider = MockAuthProvider();
    when(mockAuthProvider.user).thenReturn(User(name: 'John Doe'));
    when(mockAuthProvider.isAuthenticated).thenReturn(true);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('Welcome, John Doe!'), findsOneWidget);
  });
}
```

---

### When to Migrate from Provider to BLoC

**Migrate to BLoC when:**
- ✅ You have more than 20 screens
- ✅ Complex business logic with multiple events
- ✅ Need explicit event-driven architecture
- ✅ Team is growing beyond 5 developers
- ✅ Need better separation of concerns

**Warning signs:**
- ❌ ChangeNotifiers becoming too large (>200 lines)
- ❌ Complex state transitions
- ❌ Difficulty tracking state changes
- ❌ Need for time-travel debugging

---

## Large Projects: BLoC/Cubit

**Use when:**
- ✅ 20+ screens
- ✅ 5+ developers
- ✅ 12+ months timeline
- ✅ Complex business logic
- ✅ Need event-driven architecture

**Advantages:**
- Explicit event-driven architecture
- Excellent for complex business logic
- Predictable state transitions
- Built-in debugging tools (BlocObserver)
- Industry standard for enterprise apps
- Scales to large teams

**Setup:**
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  freezed_annotation: ^2.4.1
  equatable: ^2.0.5

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.5
```

---

### Cubit

**Best for:** Simple state management without events

#### ✅ DO: Use Cubit for simple state

```dart
// ✅ CORRECT: Cubit for counter
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

// Usage with BlocProvider
class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Counter')),
        body: Center(
          child: BlocBuilder<CounterCubit, int>(
            builder: (context, count) {
              return Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            },
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: () => context.read<CounterCubit>().decrement(),
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### ✅ DO: Use Freezed for complex Cubit states

```dart
// ✅ CORRECT: Cubit with Freezed states
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(const AuthState.initial());

  Future<void> login(String email, String password) async {
    emit(const AuthState.loading());

    try {
      final user = await _authService.login(email, password);
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(const AuthState.loading());
    await _authService.logout();
    emit(const AuthState.unauthenticated());
  }
}

// Usage with pattern matching
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SplashScreen(),
          loading: () => const Center(child: CircularProgressIndicator()),
          authenticated: (user) => HomeContent(user: user),
          unauthenticated: () => const LoginScreen(),
          error: (message) => ErrorScreen(message: message),
        );
      },
    );
  }
}
```

---

### BLoC

**Best for:** Complex event-driven logic

#### ✅ DO: Use BLoC for complex state machines

```dart
// ✅ CORRECT: BLoC with events and states
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'todo_event.freezed.dart';
part 'todo_state.freezed.dart';

// Events
@freezed
class TodoEvent with _$TodoEvent {
  const factory TodoEvent.loadTodos() = _LoadTodos;
  const factory TodoEvent.addTodo(String title) = _AddTodo;
  const factory TodoEvent.toggleTodo(String id) = _ToggleTodo;
  const factory TodoEvent.deleteTodo(String id) = _DeleteTodo;
  const factory TodoEvent.filterChanged(TodoFilter filter) = _FilterChanged;
}

// States
@freezed
class TodoState with _$TodoState {
  const factory TodoState({
    required List<Todo> todos,
    required TodoFilter filter,
    required bool isLoading,
    String? errorMessage,
  }) = _TodoState;

  factory TodoState.initial() => const TodoState(
        todos: [],
        filter: TodoFilter.all,
        isLoading: false,
      );
}

enum TodoFilter { all, active, completed }

// BLoC
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;

  TodoBloc(this._repository) : super(TodoState.initial()) {
    on<_LoadTodos>(_onLoadTodos);
    on<_AddTodo>(_onAddTodo);
    on<_ToggleTodo>(_onToggleTodo);
    on<_DeleteTodo>(_onDeleteTodo);
    on<_FilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoadTodos(_LoadTodos event, Emitter<TodoState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final todos = await _repository.fetchTodos();
      emit(state.copyWith(todos: todos, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddTodo(_AddTodo event, Emitter<TodoState> emit) async {
    try {
      final todo = await _repository.createTodo(event.title);
      emit(state.copyWith(todos: [...state.todos, todo]));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleTodo(_ToggleTodo event, Emitter<TodoState> emit) async {
    final updatedTodos = state.todos.map((todo) {
      if (todo.id == event.id) {
        return todo.copyWith(isCompleted: !todo.isCompleted);
      }
      return todo;
    }).toList();

    emit(state.copyWith(todos: updatedTodos));

    try {
      await _repository.updateTodo(
        updatedTodos.firstWhere((t) => t.id == event.id),
      );
    } catch (e) {
      // Revert on error
      emit(state.copyWith(
        todos: state.todos,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onFilterChanged(_FilterChanged event, Emitter<TodoState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onDeleteTodo(_DeleteTodo event, Emitter<TodoState> emit) async {
    final previousTodos = state.todos;
    final updatedTodos = state.todos.where((t) => t.id != event.id).toList();

    emit(state.copyWith(todos: updatedTodos));

    try {
      await _repository.deleteTodo(event.id);
    } catch (e) {
      // Revert on error
      emit(state.copyWith(
        todos: previousTodos,
        errorMessage: e.toString(),
      ));
    }
  }
}

// Usage
class TodoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoBloc(context.read<TodoRepository>())
        ..add(const TodoEvent.loadTodos()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todos'),
          actions: [
            BlocBuilder<TodoBloc, TodoState>(
              builder: (context, state) {
                return PopupMenuButton<TodoFilter>(
                  onSelected: (filter) {
                    context.read<TodoBloc>().add(
                          TodoEvent.filterChanged(filter),
                        );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: TodoFilter.all,
                      child: Text('All'),
                    ),
                    const PopupMenuItem(
                      value: TodoFilter.active,
                      child: Text('Active'),
                    ),
                    const PopupMenuItem(
                      value: TodoFilter.completed,
                      child: Text('Completed'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<TodoBloc, TodoState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredTodos = _filterTodos(state.todos, state.filter);

            return ListView.builder(
              itemCount: filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = filteredTodos[index];
                return TodoTile(todo: todo);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTodoDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Todo> _filterTodos(List<Todo> todos, TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return todos;
      case TodoFilter.active:
        return todos.where((t) => !t.isCompleted).toList();
      case TodoFilter.completed:
        return todos.where((t) => t.isCompleted).toList();
    }
  }
}
```

#### ❌ DON'T: Use BLoC for simple state

```dart
// ❌ INCORRECT: BLoC overkill for simple counter
@freezed
class CounterEvent with _$CounterEvent {
  const factory CounterEvent.increment() = _Increment;
  const factory CounterEvent.decrement() = _Decrement;
}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<_Increment>((event, emit) => emit(state + 1));
    on<_Decrement>((event, emit) => emit(state - 1));
  }
}

// ✅ BETTER: Use Cubit for simple state
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

---

### BlocListener vs BlocBuilder

#### ✅ DO: Use BlocListener for side effects

```dart
// ✅ CORRECT: BlocListener for navigation and snackbars
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          authenticated: (user) {
            // ✅ Navigate on success
            Navigator.pushReplacementNamed(context, '/home');
          },
          error: (message) {
            // ✅ Show snackbar on error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          orElse: () {},
        );
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            orElse: () => const LoginForm(),
          );
        },
      ),
    );
  }
}
```

#### ✅ DO: Use BlocConsumer for both

```dart
// ✅ CORRECT: BlocConsumer combines listener and builder
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        // Side effects
        state.maybeWhen(
          authenticated: (_) => Navigator.pushReplacementNamed(context, '/home'),
          error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          ),
          orElse: () {},
        );
      },
      builder: (context, state) {
        // UI updates
        return state.maybeWhen(
          loading: () => const Center(child: CircularProgressIndicator()),
          orElse: () => const LoginForm(),
        );
      },
    );
  }
}
```

---

## Comparison Matrix

| Feature | setState | InheritedWidget | ValueNotifier | Provider | BLoC/Cubit |
|---------|----------|-----------------|---------------|----------|------------|
| **Learning Curve** | ⭐ Easy | ⭐⭐ Medium | ⭐⭐ Medium | ⭐⭐ Medium | ⭐⭐⭐ Hard |
| **Boilerplate** | ⭐⭐⭐⭐⭐ Minimal | ⭐⭐⭐ Medium | ⭐⭐⭐⭐ Low | ⭐⭐⭐ Medium | ⭐⭐ High |
| **Testability** | ⭐⭐ Poor | ⭐⭐⭐ Medium | ⭐⭐⭐ Medium | ⭐⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Scalability** | ⭐ Poor | ⭐⭐ Limited | ⭐⭐⭐ Medium | ⭐⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Performance** | ⭐⭐⭐ Medium | ⭐⭐ Can be slow | ⭐⭐⭐⭐ Good | ⭐⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **State Sharing** | ❌ No | ✅ Yes | ⚠️ Limited | ✅ Yes | ✅ Yes |
| **Debugging** | ⭐⭐ Basic | ⭐⭐ Basic | ⭐⭐⭐ Medium | ⭐⭐⭐ Medium | ⭐⭐⭐⭐⭐ Excellent |
| **Dependencies** | ✅ None | ✅ None | ✅ None | 📦 provider | 📦 flutter_bloc |
| **Best For** | Local state | Config/DI | Simple reactive | Medium apps | Large apps |

---

## Migration Strategies

### Small → Medium (setState → Provider)

#### Step 1: Identify shared state

```dart
// Before: setState with prop drilling
class ShoppingApp extends StatefulWidget {
  @override
  State<ShoppingApp> createState() => _ShoppingAppState();
}

class _ShoppingAppState extends State<ShoppingApp> {
  List<Product> _cart = [];

  void _addToCart(Product product) {
    setState(() => _cart.add(product));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductList(onAddToCart: _addToCart), // Prop drilling
        CartWidget(cart: _cart),
      ],
    );
  }
}
```

#### Step 2: Create ChangeNotifier

```dart
// After: Provider
class CartProvider extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;

  void addItem(Product product) {
    _items.add(product);
    notifyListeners();
  }

  void removeItem(Product product) {
    _items.remove(product);
    notifyListeners();
  }
}
```

#### Step 3: Wrap app with Provider

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MyApp(),
    ),
  );
}
```

#### Step 4: Replace setState with Provider

```dart
class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ProductCard(
          product: Product(name: 'Widget', price: 9.99),
          onAddToCart: () {
            // ✅ No prop drilling!
            context.read<CartProvider>().addItem(product);
          },
        ),
      ],
    );
  }
}

class CartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Text('Items: ${cart.itemCount}');
  }
}
```

---

### Medium → Large (Provider → BLoC)

#### Step 1: Identify complex state logic

```dart
// Before: Provider with complex logic
class OrderProvider extends ChangeNotifier {
  OrderState _state = OrderState.initial();

  Future<void> createOrder(List<Product> items) async {
    _state = OrderState.loading();
    notifyListeners();

    try {
      final order = await _repository.createOrder(items);
      _state = OrderState.success(order);
    } catch (e) {
      _state = OrderState.error(e.toString());
    }
    notifyListeners();
  }
}
```

#### Step 2: Define Events and States with Freezed

```dart
// After: BLoC with events and states
@freezed
class OrderEvent with _$OrderEvent {
  const factory OrderEvent.createOrder(List<Product> items) = _CreateOrder;
  const factory OrderEvent.cancelOrder(String orderId) = _CancelOrder;
  const factory OrderEvent.trackOrder(String orderId) = _TrackOrder;
}

@freezed
class OrderState with _$OrderState {
  const factory OrderState.initial() = _Initial;
  const factory OrderState.loading() = _Loading;
  const factory OrderState.success(Order order) = _Success;
  const factory OrderState.error(String message) = _Error;
}
```

#### Step 3: Implement BLoC

```dart
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;

  OrderBloc(this._repository) : super(const OrderState.initial()) {
    on<_CreateOrder>(_onCreateOrder);
    on<_CancelOrder>(_onCancelOrder);
    on<_TrackOrder>(_onTrackOrder);
  }

  Future<void> _onCreateOrder(
    _CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderState.loading());

    try {
      final order = await _repository.createOrder(event.items);
      emit(OrderState.success(order));
    } catch (e) {
      emit(OrderState.error(e.toString()));
    }
  }

  // Other event handlers...
}
```

#### Step 4: Replace Provider with BlocProvider

```dart
// Before
ChangeNotifierProvider(
  create: (_) => OrderProvider(),
  child: OrderScreen(),
)

// After
BlocProvider(
  create: (_) => OrderBloc(context.read<OrderRepository>()),
  child: OrderScreen(),
)
```

#### Step 5: Update UI to use BLoC

```dart
// Before: Consumer
Consumer<OrderProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return const CircularProgressIndicator();
    }
    return OrderDetails(order: provider.order);
  },
)

// After: BlocBuilder
BlocBuilder<OrderBloc, OrderState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      success: (order) => OrderDetails(order: order),
      error: (message) => ErrorWidget(message: message),
    );
  },
)
```

---

## Summary

### Quick Decision Guide

**Use setState when:**
- ✅ Local widget state only
- ✅ No state sharing needed
- ✅ Simple forms or toggles

**Use InheritedWidget when:**
- ✅ Sharing config/theme
- ✅ Simple dependency injection
- ✅ Rarely changing state

**Use ValueNotifier when:**
- ✅ Simple reactive state
- ✅ Minimal boilerplate needed
- ✅ Small projects

**Use Provider when:**
- ✅ 5-20 screens
- ✅ State sharing across screens
- ✅ Medium complexity
- ✅ Good balance needed

**Use BLoC/Cubit when:**
- ✅ 20+ screens
- ✅ Complex business logic
- ✅ Event-driven architecture
- ✅ Large teams
- ✅ Enterprise apps

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0

