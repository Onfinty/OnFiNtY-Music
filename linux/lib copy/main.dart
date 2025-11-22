// ignore_for_file: unintended_html_in_doc_comment

/*
 * 🚀 RIVERPOD 3.0 ULTRA-DETAILED DOCUMENTATION 🚀
 * 
 * Every line explained - Learn by understanding WHY, not just HOW
 * 
 * TABLE OF CONTENTS:
 * 1. Setup & Imports
 * 2. Code Generation Basics
 * 3. Notifier Pattern
 * 4. AsyncNotifier Pattern
 * 5. Computed Providers
 * 6. Family Providers
 * 7. UI Patterns
 * 8. Design Improvements
 */

// ============================================================================
// 📦 SECTION 1: IMPORTS - What Each Package Does
// ============================================================================

// Flutter's core UI framework - provides widgets, themes, navigation
import 'package:flutter/material.dart';

// Riverpod's Flutter integration - provides ConsumerWidget, WidgetRef
// This is the bridge between Riverpod state and Flutter widgets
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod's annotation system - provides @riverpod decorator
// This tells build_runner "generate provider code from this"
import 'package:riverpod_annotation/riverpod_annotation.dart';

// ============================================================================
// 🔗 THE MAGIC LINE - Generated Code Import
// ============================================================================
// This imports the file that build_runner creates (main.g.dart)
// 
// WHY 'part'? 
// - Makes this file and main.g.dart share the same library
// - Generated code can access private members (_$Cart, _$ClickCounter, etc.)
// - They become ONE logical file, split physically for organization
//
// ERRORS BEFORE build_runner?
// - YES! main.g.dart doesn't exist yet
// - All _$ClassName references show red errors
// - This is NORMAL and EXPECTED
// - After running: dart run build_runner build
// - Errors disappear because main.g.dart is created
part 'main.g.dart';

// ============================================================================
// 📚 LESSON 1: SIMPLE PROVIDERS - Constants & Computed Values
// ============================================================================

/// Tax rate for the store (15%)
/// 
/// HOW IT WORKS:
/// 1. @riverpod tells build_runner: "make this a provider"
/// 2. Function name = taxRate → Generated provider = taxRateProvider
/// 3. Return type = double → Provider type = Provider<double>
/// 4. The 'Ref' parameter lets you read other providers
/// 
/// WHAT build_runner GENERATES:
/// ```dart
/// final taxRateProvider = Provider<double>((ref) {
///   return taxRate(ref);
/// });
/// ```
/// 
/// WHEN TO USE:
/// - Constants that might change (config values)
/// - Values computed from other providers
/// - Business logic that doesn't need state
@riverpod
double taxRate(Ref ref) {
  // Just return a value - no state management needed
  // If you need to change this, you'd use a Notifier instead
  return 0.15;
}

/// Application name
/// 
/// WHY SEPARATE FROM appTitle?
/// - Single Responsibility Principle
/// - appName might be used elsewhere (settings, about page)
/// - Easier to test individual pieces
/// - Allows appTitle to focus on formatting
@riverpod
String appName(Ref ref) {
  return "ModernShop 2025";
}

/// Application title with formatting
/// 
/// DEMONSTRATES: Provider Dependencies
/// - Watches appNameProvider using ref.watch()
/// - Automatically rebuilds if appName changes
/// - Creates a reactive chain: appName → appTitle
/// 
/// ref.watch() vs ref.read():
/// - watch() = Subscribe to changes, rebuilds when value changes
/// - read() = One-time read, no subscription, use in callbacks/events
@riverpod
String appTitle(Ref ref) {
  // Get the app name from another provider
  final name = ref.watch(appNameProvider);
  
  // Add some branding to it
  return "$name - Next Gen Shopping";
}

// ============================================================================
// 📚 LESSON 2: DATA MODELS - The Foundation
// ============================================================================

/// Product model represents items in our store
/// 
/// WHY A CLASS?
/// - Type safety: Can't mix up product fields
/// - Methods: Can add computed properties (like discounted price)
/// - Immutability: Use final fields + copyWith for safety
/// 
/// DESIGN PATTERN: Immutable Data Class
/// - All fields are final (can't be changed after creation)
/// - Use copyWith() to create modified copies
/// - Prevents bugs from unexpected mutations
class Product {
  // final = can't change after creation
  final String id;
  final String name;
  final double price;
  final String emoji;

  // Constructor with required named parameters
  // Named parameters are self-documenting: Product(name: "iPhone", ...)
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
  });

  /// Creates a copy with some fields changed
  /// 
  /// WHY NEEDED?
  /// - Since fields are final, can't do: product.price = 99
  /// - Instead: product.copyWith(price: 99)
  /// - Maintains immutability while allowing updates
  /// 
  /// USAGE:
  /// ```dart
  /// final iPhone = Product(id: '1', name: 'iPhone', price: 999, emoji: '📱');
  /// final discountedPhone = iPhone.copyWith(price: 799);
  /// iPhone.price is still 999, discountedPhone.price is 799
  /// ```
  Product copyWith({String? id, String? name, double? price, String? emoji}) {
    return Product(
      id: id ?? this.id,           // Use new value if provided, else keep current
      name: name ?? this.name,
      price: price ?? this.price,
      emoji: emoji ?? this.emoji,
    );
  }
}

/// Cart item combines product with quantity
/// 
/// WHY SEPARATE FROM Product?
/// - Separation of concerns: Product = catalog, CartItem = cart
/// - A product can exist without being in cart
/// - CartItem adds cart-specific data (quantity)
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  /// Computed property - calculates on access
  /// 
  /// WHY A GETTER?
  /// - Always up-to-date (recalculates each time)
  /// - No need to store and sync totalPrice field
  /// - Clean syntax: item.totalPrice (looks like a field)
  double get totalPrice => product.price * quantity;

  /// Create modified copy
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

// ============================================================================
// 📚 LESSON 3: NOTIFIER - Modern State Management
// ============================================================================

/// Shopping cart manager
/// 
/// ARCHITECTURE DECISION: Why Notifier over StateNotifier?
/// 
/// OLD WAY (StateNotifier - Deprecated):
/// ```dart
/// class CartNotifier extends StateNotifier<List<CartItem>> {
///   CartNotifier() : super([]); // Initial state in constructor
///   
///   void addProduct(Product p) {
///     state = [...state, CartItem(product: p, quantity: 1)];
///   }
/// }
/// 
/// final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
///   return CartNotifier();
/// });
/// ```
/// 
/// NEW WAY (Notifier with @riverpod):
/// - Cleaner: build() method for initial state
/// - Type-safe: No manual provider declaration
/// - Less boilerplate: Generated code handles wiring
/// - Better DX: build_runner shows errors immediately
/// 
/// HOW IT WORKS:
/// 1. @riverpod + class = NotifierProvider is generated
/// 2. Extends _$Cart (generated base class with boilerplate)
/// 3. build() returns initial state
/// 4. Methods modify state using 'state =' syntax
/// 5. Any widget watching cartProvider rebuilds on state change
@riverpod
class Cart extends _$Cart {
  // _$Cart is in main.g.dart, contains:
  // - Provider declaration
  // - Ref management
  // - State change notifications
  // - Type safety infrastructure
  
  /// Initial state - called once when provider is first accessed
  /// 
  /// LIFECYCLE:
  /// 1. Widget calls ref.watch(cartProvider)
  /// 2. Provider doesn't exist yet
  /// 3. build() is called to create initial state
  /// 4. Provider now exists with state = []
  /// 5. Future reads use existing state
  @override
  List<CartItem> build() {
    // Empty cart at start
    // Could also initialize from local storage:
    // final saved = ref.watch(localStorageProvider);
    // return saved ?? [];
    return [];
  }

  /// Add product to cart or increase quantity
  /// 
  /// ALGORITHM BREAKDOWN:
  /// 1. Check if product already exists in cart
  /// 2. If exists: Increase quantity (immutably)
  /// 3. If new: Add as new item
  /// 
  /// WHY IMMUTABLE UPDATES?
  /// - Riverpod compares references to detect changes
  /// - Mutating: state[0].quantity++ (Riverpod doesn't see change)
  /// - Immutable: state = [...newList] (Riverpod sees new reference)
  void addProduct(Product product) {
    // Find product in cart by ID
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Product exists - increase quantity
      // 
      // TECHNIQUE: Immutable list update by index
      // - Take items before index: ...state.sublist(0, existingIndex)
      // - Replace item at index: state[existingIndex].copyWith(...)
      // - Take items after index: ...state.sublist(existingIndex + 1)
      state = [
        ...state.sublist(0, existingIndex),
        state[existingIndex].copyWith(
          quantity: state[existingIndex].quantity + 1,
        ),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // New product - add to cart
      // Spread operator (...) copies existing items
      state = [...state, CartItem(product: product, quantity: 1)];
    }
    
    // After 'state =' assignment:
    // 1. Riverpod detects state change
    // 2. Notifies all listeners (widgets watching cartProvider)
    // 3. Those widgets rebuild with new state
  }

  /// Remove product completely from cart
  /// 
  /// WHY where() + toList()?
  /// - where() creates an Iterable (lazy)
  /// - toList() converts to List (what our state type is)
  /// - Filters out the item with matching ID
  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Decrease quantity or remove if it hits 0
  /// 
  /// BUSINESS LOGIC:
  /// - Quantity > 1: Decrease by 1
  /// - Quantity = 1: Remove item entirely
  void decreaseQuantity(String productId) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == productId,
    );

    if (existingIndex >= 0) {
      final currentItem = state[existingIndex];

      if (currentItem.quantity > 1) {
        // Decrease quantity (same immutable technique as addProduct)
        state = [
          ...state.sublist(0, existingIndex),
          currentItem.copyWith(quantity: currentItem.quantity - 1),
          ...state.sublist(existingIndex + 1),
        ];
      } else {
        // Quantity is 1, remove item
        removeProduct(productId);
      }
    }
  }

  /// Clear entire cart - reset to empty
  void clearCart() {
    state = [];
  }
}

/// Simple counter example
/// 
/// WHY THIS EXAMPLE?
/// - Shows minimal Notifier usage
/// - Only 3 lines in build() + methods
/// - Perfect for learning basics before complex cart logic
@riverpod
class ClickCounter extends _$ClickCounter {
  @override
  int build() => 0; // Initial value: 0
  
  // Arrow functions for simple one-liners
  void increment() => state++;      // Shorthand for: state = state + 1
  void decrement() => state--;      // Shorthand for: state = state - 1
  void reset() => state = 0;        // Set back to initial value
}

/// Dark mode toggle
/// 
/// UI STATE PATTERN:
/// - UI preferences belong in state management
/// - Allows persistence: save to local storage in build()
/// - Accessible app-wide: any screen can toggle theme
@riverpod
class DarkMode extends _$DarkMode {
  @override
  bool build() => false; // Light mode by default
  
  void toggle() => state = !state;  // Flip: true ↔ false
  void enable() => state = true;    // Force dark mode
  void disable() => state = false;  // Force light mode
}

// ============================================================================
// 📚 LESSON 4: ASYNCNOTIFIER - Async State Management
// ============================================================================

/// Products loader - fetches data asynchronously
/// 
/// WHY ASYNCNOTIFIER?
/// - API calls take time (network latency)
/// - Need loading/error states
/// - AsyncNotifier gives us AsyncValue<T> for free
/// 
/// AsyncValue<List<Product>> has 3 states:
/// 1. AsyncLoading() - Fetching data
/// 2. AsyncData(products) - Success with data
/// 3. AsyncError(error, stack) - Failed with error
/// 
/// DIFFERENCE FROM NOTIFIER:
/// - Notifier: Synchronous state (List<Product>)
/// - AsyncNotifier: Async state (AsyncValue<List<Product>>)
@riverpod
class Products extends _$Products {
  /// Build returns Future - makes this an AsyncNotifier
  /// 
  /// LIFECYCLE:
  /// 1. First access: State = AsyncLoading()
  /// 2. build() starts executing
  /// 3. await pauses, returns control to Flutter
  /// 4. When complete: State = AsyncData(products)
  /// 5. If error thrown: State = AsyncError(error, stack)
  @override
  Future<List<Product>> build() async {
    // Simulate network delay (in real app: API call)
    await Future.delayed(Duration(seconds: 2));
    
    // In production, replace with:
    // final response = await http.get('https://api.myshop.com/products');
    // return (json.decode(response.body) as List)
    //     .map((item) => Product.fromJson(item))
    //     .toList();

    return [
      Product(id: '1', name: 'iPhone 15 Pro', price: 999.99, emoji: '📱'),
      Product(id: '2', name: 'MacBook Air M3', price: 2499.99, emoji: '💻'),
      Product(id: '3', name: 'AirPods Max', price: 549.99, emoji: '🎧'),
      Product(id: '4', name: 'iPad Pro', price: 799.99, emoji: '📟'),
      Product(id: '5', name: 'Apple Watch Ultra', price: 799.99, emoji: '⌚'),
      Product(id: '6', name: 'Vision Pro', price: 3499.99, emoji: '🥽'),
    ];
  }

  /// Manual refresh - like pull-to-refresh
  /// 
  /// PATTERN: Optimistic Update with Error Handling
  /// 1. Set loading state immediately (spinner appears)
  /// 2. Fetch new data
  /// 3. AsyncValue.guard() catches errors automatically
  /// 4. State becomes Data or Error based on result
  Future<void> refreshProducts() async {
    // Show loading spinner
    state = const AsyncValue.loading();

    // Fetch fresh data with automatic error handling
    // guard() is equivalent to:
    // try {
    //   final data = await fetchData();
    //   state = AsyncValue.data(data);
    // } catch (error, stack) {
    //   state = AsyncValue.error(error, stack);
    // }
    state = await AsyncValue.guard(() async {
      await Future.delayed(Duration(seconds: 1));
      return [
        Product(id: '1', name: 'iPhone 16', price: 1099.99, emoji: '📱'),
        Product(id: '2', name: 'MacBook Pro M4', price: 2699.99, emoji: '💻'),
        Product(id: '3', name: 'AirPods Pro 3', price: 299.99, emoji: '🎧'),
        Product(id: '4', name: 'iPad Air M3', price: 899.99, emoji: '📟'),
        Product(id: '5', name: 'Apple Watch S10', price: 499.99, emoji: '⌚'),
        Product(id: '6', name: 'Vision Pro 2', price: 2999.99, emoji: '🥽'),
      ];
    });
  }
}

/// Live discount stream - real-time updates
/// 
/// STREAM VS FUTURE:
/// - Future: Single value over time (one API call)
/// - Stream: Multiple values over time (websocket, real-time data)
/// 
/// WHY @riverpod for streams?
/// - Auto-converts to StreamProvider
/// - Widgets get AsyncValue<int> (same pattern as AsyncNotifier)
/// - Handles subscription lifecycle automatically
/// 
/// async* SYNTAX:
/// - async = returns Future
/// - async* = returns Stream
/// - yield = emit value to stream (like return but for streams)
@riverpod
Stream<int> discountStream(Ref ref) async* {
  // Discount percentages to cycle through
  final discounts = [5, 10, 15, 20, 25, 30];
  int index = 0;

  // Infinite loop - keeps emitting values
  while (true) {
    await Future.delayed(Duration(seconds: 3)); // Wait 3 seconds
    yield discounts[index % discounts.length];   // Emit next discount
    index++;
  }
  
  // In production with websocket:
  // final channel = WebSocketChannel.connect(Uri.parse('ws://...'));
  // await for (final message in channel.stream) {
  //   yield parseDiscount(message);
  // }
}

// ============================================================================
// 📚 LESSON 5: COMPUTED PROVIDERS - Reactive Chains
// ============================================================================

/// Count total items across all cart items
/// 
/// COMPUTED PROVIDER PATTERN:
/// - Reads other providers
/// - Recalculates when dependencies change
/// - No state of its own
/// 
/// REACTIVE CHAIN:
/// Cart changes → cartItemCount recalculates → Widgets rebuild
/// 
/// WHY NOT A METHOD ON CART?
/// - Separation: Cart manages data, this computes derived values
/// - Reusability: Multiple widgets can watch this independently
/// - Performance: Riverpod caches result until cart changes
@riverpod
int cartItemCount(Ref ref) {
  final cart = ref.watch(cartProvider);
  
  // fold() is like reduce()
  // Starts with 0, adds each item's quantity
  // [item1(qty:2), item2(qty:3)] → 0 + 2 + 3 = 5
  return cart.fold<int>(0, (sum, item) => sum + item.quantity);
}

/// Calculate subtotal (before tax)
/// 
/// BUSINESS LOGIC:
/// - Sum of all (item.price × item.quantity)
@riverpod
double cartSubtotal(Ref ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<double>(0, (sum, item) => sum + item.totalPrice);
}

/// Calculate tax amount
/// 
/// DEMONSTRATES: Multi-level dependencies
/// - Reads cartSubtotal (which reads cart)
/// - Reads taxRate
/// - Creates chain: cart → subtotal → tax
@riverpod
double cartTax(Ref ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final taxRate = ref.watch(taxRateProvider);
  return subtotal * taxRate;
}

/// Calculate final total (subtotal + tax)
@riverpod
double cartTotal(Ref ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final tax = ref.watch(cartTaxProvider);
  return subtotal + tax;
}

/// Cart summary as single object
/// 
/// WHY A MAP?
/// - Convenient for passing multiple values together
/// - Easy to destructure: summary['itemCount']
/// - Alternative: Create CartSummary class
/// 
/// USAGE IN UI:
/// ```dart
/// final summary = ref.watch(cartSummaryProvider);
/// Text('Items: ${summary['itemCount']}')
/// Text('Total: \$${summary['total']}')
/// ```
@riverpod
Map<String, dynamic> cartSummary(Ref ref) {
  return {
    'itemCount': ref.watch(cartItemCountProvider),
    'subtotal': ref.watch(cartSubtotalProvider),
    'tax': ref.watch(cartTaxProvider),
    'total': ref.watch(cartTotalProvider),
  };
}

// ============================================================================
// 📚 LESSON 6: FAMILY PROVIDERS - Parameterized Providers
// ============================================================================

/// Get product by ID
/// 
/// FAMILY PATTERN:
/// - Provider that takes parameters
/// - Each unique parameter creates separate provider instance
/// 
/// HOW IT WORKS:
/// ```dart
/// ref.watch(productByIdProvider('1')) // Instance for ID '1'
/// ref.watch(productByIdProvider('2')) // Instance for ID '2'
/// ```
/// 
/// CACHING:
/// - '1' creates provider, caches result
/// - Next read of '1' uses cached value
/// - '2' creates NEW provider instance
/// 
/// GENERATED SIGNATURE:
/// The first parameter after Ref is the family parameter
/// build_runner sees this and creates a family provider
@riverpod
Future<Product?> productById(Ref ref, String id) async {
  // Watch the products (triggers rebuild if products change)
  final productsAsync = ref.watch(productsProvider);

  // Handle all 3 AsyncValue states
  return productsAsync.when(
    // Data state: Search for product
    data: (products) {
      try {
        return products.firstWhere((p) => p.id == id);
      } catch (e) {
        // firstWhere throws if not found
        return null;
      }
    },
    // Loading state: Don't have data yet
    loading: () => null,
    // Error state: Failed to load products
    error: (_, __) => null,
  );
}

/// Filter products by price range
/// 
/// MULTIPLE PARAMETERS:
/// - Can have multiple family parameters
/// - Each combination is a unique instance
/// 
/// EXAMPLE:
/// ```dart
/// ref.watch(productsByPriceRangeProvider(0, 100))    // Instance 1
/// ref.watch(productsByPriceRangeProvider(100, 500))  // Instance 2
/// ref.watch(productsByPriceRangeProvider(0, 100))    // Reuses Instance 1
/// ```
@riverpod
Future<List<Product>> productsByPriceRange(
  Ref ref,
  double minPrice,
  double maxPrice,
) async {
  final productsAsync = ref.watch(productsProvider);

  return productsAsync.when(
    data: (products) => products
        .where((p) => p.price >= minPrice && p.price <= maxPrice)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}

// ============================================================================
// 📚 LESSON 7: SEARCH & FILTERING
// ============================================================================

/// Search query state
/// 
/// UI STATE PATTERN:
/// - Stores user input
/// - Other providers read this to filter data
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => ''; // Empty search initially
  
  void update(String query) => state = query;
  void clear() => state = '';
}

/// Filtered products based on search
/// 
/// REACTIVE FILTERING:
/// - Watches searchQuery and products
/// - Rebuilds when either changes
/// - Always shows filtered results
/// 
/// PERFORMANCE NOTE:
/// - Filtering happens in provider, not UI
/// - Results are cached until dependencies change
/// - Multiple widgets can share filtered list efficiently
@riverpod
Future<List<Product>> filteredProducts(Ref ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final productsAsync = ref.watch(productsProvider);

  return productsAsync.when(
    data: (products) {
      if (query.isEmpty) return products;
      return products
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
}

// ============================================================================
// 🎨 UI LAYER - Bringing It All Together
// ============================================================================

/// App entry point
/// 
/// CRITICAL: ProviderScope
/// - Required at root of app
/// - Creates container for all providers
/// - Without it, providers crash with error
/// 
/// WHAT IT DOES:
/// - Manages provider lifecycle
/// - Handles provider disposal
/// - Enables provider overrides (testing)
void main() {
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

/// Root widget of the app
/// 
/// WHY CONSUMERWIDGET?
/// - Need WidgetRef to read providers
/// - ConsumerWidget gives us ref in build()
/// - Alternative: Wrap with Consumer() but less clean
/// 
/// WIDGET vs CONSUMERWIDGET:
/// - Widget: No provider access, slightly faster
/// - ConsumerWidget: Has ref, rebuilds on provider changes
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch dark mode - rebuilds MaterialApp when theme changes
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp(
      title: ref.watch(appTitleProvider),
      debugShowCheckedModeBanner: false,
      
      // Reactive theme switching
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      
      home: const ProductListScreen(),
    );
  }
}

/// Main product listing screen
/// 
/// WHY CONSUMERSTATEFULWIDGET?
/// - Need both State (for TextField controller, etc.) AND WidgetRef
/// - StatefulWidget can't access providers
/// - ConsumerStatefulWidget = StatefulWidget + WidgetRef
/// 
/// WHEN TO USE:
/// - Need lifecycle methods (initState, dispose)
/// - Need local UI state (scroll position, animation controllers)
/// - Need provider access
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch various providers - rebuilds when any change
    final asyncProducts = ref.watch(productsProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final discountStream = ref.watch(discountStreamProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // ========================================================================
    // 📚 LESSON 8: ref.listen() - Side Effects Without Rebuilds
    // ========================================================================
    // 
    // THE PROBLEM:
    // - ref.watch() rebuilds widget on every change
    // - We want to show snackbar without rebuilding
    // 
    // THE SOLUTION: ref.listen()
    // - Runs callback when provider changes
    // - Doesn't trigger rebuild
    // - Perfect for: navigation, snackbars, dialogs, logging
    // 
    // CALLBACK PARAMETERS:
    // - previous: Old state (null on first call)
    // - next: New state
    // 
    // COMMON USE CASES:
    // - Show snackbar on data change
    // - Navigate on authentication state change
    // - Log analytics events
    // - Show error dialogs
    // - Play sounds/haptics
    
    ref.listen<List<CartItem>>(cartProvider, (previous, next) {
      // Check if item was added (cart size increased)
      if (previous != null && next.length > previous.length) {
        // Show snackbar - UI side effect
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Item added to cart!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Could also handle other cases:
      // if (next.length < previous.length) {
      //   // Item removed
      // }
    });
    
    // THIS WIDGET DOESN'T REBUILD when cart changes!
    // Only the snackbar appears. That's the power of ref.listen()!
    // ========================================================================

    return Scaffold(
      // ======================================================================
      // APP BAR - Top navigation with actions
      // ======================================================================
      appBar: AppBar(
        title: const Text('ModernShop'),
        actions: [
          // Dark mode toggle button
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // ref.read() for one-time read in callbacks
              // .notifier gets the Notifier instance (not just the state)
              ref.read(darkModeProvider.notifier).toggle();
            },
          ),
          
          // Cart button with badge showing item count
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Navigate to cart screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              
              // Badge showing cart item count
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      
      body: Column(
        children: [
          // ==================================================================
          // DISCOUNT BANNER - Real-time stream display
          // ==================================================================
          // AsyncValue.when() handles all stream states
          discountStream.when(
            // Data received: Show discount
            data: (discount) => Container(
              color: Colors.green,
              padding: const EdgeInsets.all(8),
              child: Text(
                '🎉 FLASH SALE: $discount% OFF! 🎉',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Stream hasn't emitted yet: Show nothing
            loading: () => const SizedBox.shrink(),
            // Stream errored: Show nothing (could show error message)
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ==================================================================
          // SEARCH BAR - User input with reactive filtering
          // ==================================================================
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              // onChanged fires on every keystroke
              onChanged: (value) {
                // Update search query state
                // This triggers filteredProductsProvider to recalculate
                ref.read(searchQueryProvider.notifier).update(value);
              },
            ),
          ),

          // ==================================================================
          // PRODUCTS LIST - Main content area
          // ==================================================================
          Expanded(
            child: asyncProducts.when(
              // ================================================================
              // LOADING STATE: Show spinner while fetching
              // ================================================================
              loading: () => const Center(child: CircularProgressIndicator()),
              
              // ================================================================
              // ERROR STATE: Show error message with retry button
              // ================================================================
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    ElevatedButton(
                      onPressed: () {
                        // ref.invalidate() forces provider to rebuild
                        // Calls build() again, refetching data
                        ref.invalidate(productsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              
              // ================================================================
              // DATA STATE: Show products list
              // ================================================================
              data: (products) {
                // Filter products based on search query
                // (Alternatively, could use filteredProductsProvider)
                final filtered = searchQuery.isEmpty
                    ? products
                    : products
                        .where((p) =>
                            p.name.toLowerCase().contains(searchQuery.toLowerCase()))
                        .toList();

                // Empty state
                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                // Build scrollable list of products
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    
                    // ListTile: Material Design list item
                    // - leading: Icon/image on left
                    // - title: Primary text
                    // - subtitle: Secondary text
                    // - trailing: Action button on right
                    return ListTile(
                      leading: Text(
                        product.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(product.name),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          // Add to cart
                          // ref.read() because we're in callback (not build)
                          ref.read(cartProvider.notifier).addProduct(product);
                          
                          // ref.listen() will show snackbar automatically!
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // ====================================================================
      // FLOATING ACTION BUTTON - Manual refresh
      // ====================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Call refreshProducts method on Products notifier
          ref.read(productsProvider.notifier).refreshProducts();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}

// ============================================================================
// CART SCREEN - Shopping cart view
// ============================================================================

/// Shopping cart screen
/// 
/// WHY CONSUMERWIDGET HERE?
/// - No local state needed (no controllers, animations, etc.)
/// - Only need to read providers
/// - Simpler than ConsumerStatefulWidget
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart items and summary
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);

    return Scaffold(
      // ======================================================================
      // APP BAR with clear cart action
      // ======================================================================
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          // Only show clear button if cart has items
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                // Clear entire cart
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      
      body: cart.isEmpty
          // ==================================================================
          // EMPTY STATE: Show friendly message
          // ==================================================================
          ? const Center(
              child: Text(
                '🛒 Your cart is empty!',
                style: TextStyle(fontSize: 20),
              ),
            )
          // ==================================================================
          // CART ITEMS: Show items with controls
          // ==================================================================
          : Column(
              children: [
                // ==============================================================
                // CART ITEMS LIST
                // ==============================================================
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      
                      return ListTile(
                        leading: Text(
                          item.product.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text(
                          '\$${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                        ),
                        
                        // QUANTITY CONTROLS: +/- buttons
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease quantity button
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .decreaseQuantity(item.product.id);
                              },
                            ),
                            
                            // Current quantity display
                            Text('${item.quantity}'),
                            
                            // Increase quantity button
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addProduct(item.product);
                              },
                            ),
                            
                            // Delete item button
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeProduct(item.product.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // ==============================================================
                // PRICE SUMMARY SECTION
                // ==============================================================
                // Fixed at bottom, shows pricing breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: const Border(
                      top: BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Item count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items:'),
                          Text('${summary['itemCount']}'),
                        ],
                      ),
                      
                      // Subtotal (before tax)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('${summary['subtotal'].toStringAsFixed(2)}'),
                        ],
                      ),
                      
                      // Tax amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (15%):'),
                          Text('${summary['tax'].toStringAsFixed(2)}'),
                        ],
                      ),

                     
                      
                      // Divider before total
                      const Divider(thickness: 2, color: Colors.black,),
                      
                      // Final total (bold and larger)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${summary['total'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // ===========================================================
                      // CHECKOUT BUTTON
                      // ===========================================================
                      ElevatedButton(
                        onPressed: () {
                          // Show order confirmation dialog
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Order Placed! 🎉'),
                              content: Text(
                                'Total: ${summary['total'].toStringAsFixed(2)}\nThank you!',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Clear cart after checkout
                                    ref.read(cartProvider.notifier).clearCart();
                                    
                                    // Close dialog
                                    Navigator.pop(context);
                                    
                                    // Return to product list
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('CHECKOUT'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// 🎨 DESIGN IMPROVEMENTS GUIDE
// ============================================================================
/*
 * CURRENT DESIGN: Functional but basic Material Design
 * 
 * HERE'S HOW TO MAKE IT LOOK PROFESSIONAL:
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 1. CUSTOM THEME - Brand identity
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Replace basic ThemeData with custom brand colors:
 * 
 * ```dart
 * theme: ThemeData(
 *   primarySwatch: Colors.deepPurple,
 *   colorScheme: ColorScheme.fromSeed(
 *     seedColor: Colors.deepPurple,
 *     brightness: Brightness.light,
 *   ),
 *   cardTheme: CardTheme(
 *     elevation: 4,
 *     shape: RoundedRectangleBorder(
 *       borderRadius: BorderRadius.circular(16),
 *     ),
 *   ),
 *   elevatedButtonTheme: ElevatedButtonThemeData(
 *     style: ElevatedButton.styleFrom(
 *       shape: RoundedRectangleBorder(
 *         borderRadius: BorderRadius.circular(12),
 *       ),
 *       padding: EdgeInsets.symmetric(vertical: 16),
 *     ),
 *   ),
 * ),
 * ```
 * 
 * WHY? Creates consistent brand experience across all widgets
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 2. PRODUCT CARDS - More visual appeal
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Replace ListTile with Card widgets:
 * 
 * ```dart
 * return Padding(
 *   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 *   child: Card(
 *     child: InkWell(
 *       onTap: () => showProductDetails(product),
 *       child: Padding(
 *         padding: EdgeInsets.all(12),
 *         child: Row(
 *           children: [
 *             // Product image/emoji in circle
 *             CircleAvatar(
 *               radius: 30,
 *               backgroundColor: Colors.deepPurple[50],
 *               child: Text(product.emoji, style: TextStyle(fontSize: 32)),
 *             ),
 *             SizedBox(width: 12),
 *             
 *             // Product info
 *             Expanded(
 *               child: Column(
 *                 crossAxisAlignment: CrossAxisAlignment.start,
 *                 children: [
 *                   Text(
 *                     product.name,
 *                     style: TextStyle(
 *                       fontSize: 16,
 *                       fontWeight: FontWeight.w600,
 *                     ),
 *                   ),
 *                   SizedBox(height: 4),
 *                   Text(
 *                     '\${product.price.toStringAsFixed(2)}',
 *                     style: TextStyle(
 *                       fontSize: 18,
 *                       color: Colors.deepPurple,
 *                       fontWeight: FontWeight.bold,
 *                     ),
 *                   ),
 *                 ],
 *               ),
 *             ),
 *             
 *             // Add button with animation
 *             Material(
 *               color: Colors.deepPurple,
 *               borderRadius: BorderRadius.circular(8),
 *               child: InkWell(
 *                 borderRadius: BorderRadius.circular(8),
 *                 onTap: () => ref.read(cartProvider.notifier).addProduct(product),
 *                 child: Padding(
 *                   padding: EdgeInsets.all(12),
 *                   child: Icon(Icons.add_shopping_cart, color: Colors.white),
 *                 ),
 *               ),
 *             ),
 *           ],
 *         ),
 *       ),
 *     ),
 *   ),
 * );
 * ```
 * 
 * WHY? Cards create depth, easier to scan, more professional
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 3. GRID LAYOUT - Better use of space
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Replace ListView with GridView for tablets/desktop:
 * 
 * ```dart
 * GridView.builder(
 *   padding: EdgeInsets.all(12),
 *   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
 *     crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
 *     childAspectRatio: 0.75,
 *     crossAxisSpacing: 12,
 *     mainAxisSpacing: 12,
 *   ),
 *   itemCount: filtered.length,
 *   itemBuilder: (context, index) {
 *     // Build card here
 *   },
 * );
 * ```
 * 
 * WHY? Responsive design, adapts to screen size
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 4. ANIMATIONS - Smooth transitions
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Add hero animations between screens:
 * 
 * ```dart
 * // Product list
 * Hero(
 *   tag: 'product-${product.id}',
 *   child: Text(product.emoji, style: TextStyle(fontSize: 32)),
 * ),
 * 
 * // Product details
 * Hero(
 *   tag: 'product-${product.id}',
 *   child: Text(product.emoji, style: TextStyle(fontSize: 64)),
 * ),
 * ```
 * 
 * Animate cart badge:
 * 
 * ```dart
 * AnimatedContainer(
 *   duration: Duration(milliseconds: 300),
 *   curve: Curves.elasticOut,
 *   child: Text('$cartItemCount'),
 * );
 * ```
 * 
 * WHY? Makes app feel alive, guides user attention
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 5. LOADING STATES - Better UX
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Add shimmer loading placeholders:
 * 
 * ```dart
 * import 'package:shimmer/shimmer.dart';
 * 
 * loading: () => ListView.builder(
 *   itemCount: 6,
 *   itemBuilder: (context, index) => Shimmer.fromColors(
 *     baseColor: Colors.grey[300]!,
 *     highlightColor: Colors.grey[100]!,
 *     child: Card(
 *       child: Container(height: 80),
 *     ),
 *   ),
 * );
 * ```
 * 
 * WHY? Users know something is happening, reduces perceived wait time
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 6. EMPTY STATES - More engaging
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * ```dart
 * Column(
 *   mainAxisAlignment: MainAxisAlignment.center,
 *   children: [
 *     Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
 *     SizedBox(height: 16),
 *     Text('Your cart is empty', style: TextStyle(fontSize: 20)),
 *     SizedBox(height: 8),
 *     Text('Add products to get started', style: TextStyle(color: Colors.grey)),
 *     SizedBox(height: 24),
 *     ElevatedButton(
 *       onPressed: () => Navigator.pop(context),
 *       child: Text('Browse Products'),
 *     ),
 *   ],
 * );
 * ```
 * 
 * WHY? Guides users to next action, reduces confusion
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 7. SEARCH IMPROVEMENTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Add debouncing to search (wait for user to finish typing):
 * 
 * ```dart
 * Timer? _debounce;
 * 
 * onChanged: (value) {
 *   _debounce?.cancel();
 *   _debounce = Timer(Duration(milliseconds: 500), () {
 *     ref.read(searchQueryProvider.notifier).update(value);
 *   });
 * },
 * ```
 * 
 * WHY? Reduces unnecessary computations, better performance
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 8. CART ANIMATIONS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Animate item removal:
 * 
 * ```dart
 * ListView.builder(
 *   // ... other properties
 *   itemBuilder: (context, index) {
 *     return Dismissible(
 *       key: Key(item.product.id),
 *       background: Container(color: Colors.red),
 *       onDismissed: (_) {
 *         ref.read(cartProvider.notifier).removeProduct(item.product.id);
 *       },
 *       child: CartItemWidget(item: item),
 *     );
 *   },
 * );
 * ```
 * 
 * WHY? Swipe to delete is intuitive, provides visual feedback
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 9. RESPONSIVE LAYOUT
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Adapt to different screen sizes:
 * 
 * ```dart
 * Widget build(BuildContext context) {
 *   final isWideScreen = MediaQuery.of(context).size.width > 600;
 *   
 *   return isWideScreen
 *     ? Row(
 *         children: [
 *           Expanded(flex: 2, child: ProductList()),
 *           Expanded(flex: 1, child: CartSidebar()),
 *         ],
 *       )
 *     : ProductList(); // Mobile: full width
 * }
 * ```
 * 
 * WHY? Better tablet/desktop experience
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * 10. ACCESSIBILITY
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Add semantic labels:
 * 
 * ```dart
 * IconButton(
 *   icon: Icon(Icons.add_shopping_cart),
 *   tooltip: 'Add ${product.name} to cart',
 *   onPressed: () => ...,
 * );
 * 
 * Semantics(
 *   label: 'Shopping cart with ${cartItemCount} items',
 *   child: Icon(Icons.shopping_cart),
 * );
 * ```
 * 
 * WHY? Screen readers can describe UI to visually impaired users
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * PERFORMANCE TIPS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. Use const constructors:
 *    - const Text('Hello') vs Text('Hello')
 *    - Prevents unnecessary rebuilds
 * 
 * 2. Split large widgets:
 *    - Create ProductCard widget
 *    - Create CartItemCard widget
 *    - Easier to optimize individual parts
 * 
 * 3. Use keys for animated lists:
 *    - Key('product-${product.id}')
 *    - Helps Flutter track which items changed
 * 
 * 4. Debounce expensive operations:
 *    - Search filtering
 *    - API calls
 *    - Complex calculations
 * 
 * 5. Use AutoDisposeNotifier:
 *    - Memory management
 *    - Cleans up when not used
 *    - Add @riverpod with keepAlive: false
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * RIVERPOD BEST PRACTICES
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. Provider naming:
 *    ✅ cartProvider (clear, concise)
 *    ❌ theCartProvider (unnecessary article)
 * 
 * 2. Granular providers:
 *    ✅ cartItemCountProvider (specific)
 *    ❌ cartStatsProvider returning { count, total, tax } (too broad)
 * 
 * 3. Computed providers over methods:
 *    ✅ @riverpod int cartItemCount(Ref ref)
 *    ❌ class Cart { int getItemCount() }
 * 
 * 4. Use ref.watch in build, ref.read in callbacks:
 *    ✅ final cart = ref.watch(cartProvider)
 *    ✅ onPressed: () => ref.read(cartProvider.notifier).clear()
 *    ❌ onPressed: () => ref.watch(...) // Rebuilds unnecessarily
 * 
 * 5. Keep Notifiers focused:
 *    ✅ Cart handles cart operations only
 *    ❌ Cart also handles user auth, settings, etc.
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * TESTING YOUR RIVERPOD CODE
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * ```dart
 * test('adding product increases cart count', () {
 *   final container = ProviderContainer();
 *   
 *   final product = Product(id: '1', name: 'Test', price: 10, emoji: '📱');
 *   
 *   // Initial state
 *   expect(container.read(cartProvider), []);
 *   expect(container.read(cartItemCountProvider), 0);
 *   
 *   // Add product
 *   container.read(cartProvider.notifier).addProduct(product);
 *   
 *   // Verify
 *   expect(container.read(cartProvider).length, 1);
 *   expect(container.read(cartItemCountProvider), 1);
 *   
 *   container.dispose();
 * });
 * ```
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * CONGRATULATIONS! 🎉
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * You now understand:
 * ✅ How @riverpod generates providers
 * ✅ Notifier vs AsyncNotifier differences
 * ✅ When to use ref.watch vs ref.read vs ref.listen
 * ✅ How to create reactive chains with computed providers
 * ✅ Family providers for parameterized state
 * ✅ Design patterns for professional UIs
 * ✅ Performance optimization techniques
 * ✅ Testing strategies
 * 
 * NEXT STEPS:
 * 1. Build a real app using these patterns
 * 2. Add persistent storage (shared_preferences)
 * 3. Integrate with real APIs
 * 4. Add authentication with AsyncNotifier
 * 5. Implement advanced caching strategies
 * 
 * You're now a Riverpod 3.0 expert! 🚀
 */