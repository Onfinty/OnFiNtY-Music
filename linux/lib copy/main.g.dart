// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(taxRate)
const taxRateProvider = TaxRateProvider._();

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

final class TaxRateProvider extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
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
  const TaxRateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taxRateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taxRateHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return taxRate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$taxRateHash() => r'e3b74c2df09865ff86ce19f950762eb8cc96f2f5';

/// Application name
///
/// WHY SEPARATE FROM appTitle?
/// - Single Responsibility Principle
/// - appName might be used elsewhere (settings, about page)
/// - Easier to test individual pieces
/// - Allows appTitle to focus on formatting

@ProviderFor(appName)
const appNameProvider = AppNameProvider._();

/// Application name
///
/// WHY SEPARATE FROM appTitle?
/// - Single Responsibility Principle
/// - appName might be used elsewhere (settings, about page)
/// - Easier to test individual pieces
/// - Allows appTitle to focus on formatting

final class AppNameProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Application name
  ///
  /// WHY SEPARATE FROM appTitle?
  /// - Single Responsibility Principle
  /// - appName might be used elsewhere (settings, about page)
  /// - Easier to test individual pieces
  /// - Allows appTitle to focus on formatting
  const AppNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appNameHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appName(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appNameHash() => r'985d1ba9fd179e622bdc2541881ee4443a10a8b3';

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

@ProviderFor(appTitle)
const appTitleProvider = AppTitleProvider._();

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

final class AppTitleProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
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
  const AppTitleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appTitleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appTitleHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appTitle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appTitleHash() => r'aeded69a044759c4aece32a042afbafae50580bd';

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

@ProviderFor(Cart)
const cartProvider = CartProvider._();

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
final class CartProvider extends $NotifierProvider<Cart, List<CartItem>> {
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
  const CartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartHash();

  @$internal
  @override
  Cart create() => Cart();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CartItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CartItem>>(value),
    );
  }
}

String _$cartHash() => r'20a7662b291b7a6909e8a22718b4e7abc37f01ed';

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

abstract class _$Cart extends $Notifier<List<CartItem>> {
  List<CartItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<CartItem>, List<CartItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<CartItem>, List<CartItem>>,
              List<CartItem>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Simple counter example
///
/// WHY THIS EXAMPLE?
/// - Shows minimal Notifier usage
/// - Only 3 lines in build() + methods
/// - Perfect for learning basics before complex cart logic

@ProviderFor(ClickCounter)
const clickCounterProvider = ClickCounterProvider._();

/// Simple counter example
///
/// WHY THIS EXAMPLE?
/// - Shows minimal Notifier usage
/// - Only 3 lines in build() + methods
/// - Perfect for learning basics before complex cart logic
final class ClickCounterProvider extends $NotifierProvider<ClickCounter, int> {
  /// Simple counter example
  ///
  /// WHY THIS EXAMPLE?
  /// - Shows minimal Notifier usage
  /// - Only 3 lines in build() + methods
  /// - Perfect for learning basics before complex cart logic
  const ClickCounterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clickCounterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clickCounterHash();

  @$internal
  @override
  ClickCounter create() => ClickCounter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$clickCounterHash() => r'db6caa0cf02865d5f70f34a789f37960efc2874f';

/// Simple counter example
///
/// WHY THIS EXAMPLE?
/// - Shows minimal Notifier usage
/// - Only 3 lines in build() + methods
/// - Perfect for learning basics before complex cart logic

abstract class _$ClickCounter extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Dark mode toggle
///
/// UI STATE PATTERN:
/// - UI preferences belong in state management
/// - Allows persistence: save to local storage in build()
/// - Accessible app-wide: any screen can toggle theme

@ProviderFor(DarkMode)
const darkModeProvider = DarkModeProvider._();

/// Dark mode toggle
///
/// UI STATE PATTERN:
/// - UI preferences belong in state management
/// - Allows persistence: save to local storage in build()
/// - Accessible app-wide: any screen can toggle theme
final class DarkModeProvider extends $NotifierProvider<DarkMode, bool> {
  /// Dark mode toggle
  ///
  /// UI STATE PATTERN:
  /// - UI preferences belong in state management
  /// - Allows persistence: save to local storage in build()
  /// - Accessible app-wide: any screen can toggle theme
  const DarkModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'darkModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$darkModeHash();

  @$internal
  @override
  DarkMode create() => DarkMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$darkModeHash() => r'a9a7d48be3124592efdf72f1a673aa41cae05ba2';

/// Dark mode toggle
///
/// UI STATE PATTERN:
/// - UI preferences belong in state management
/// - Allows persistence: save to local storage in build()
/// - Accessible app-wide: any screen can toggle theme

abstract class _$DarkMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

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

@ProviderFor(Products)
const productsProvider = ProductsProvider._();

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
final class ProductsProvider
    extends $AsyncNotifierProvider<Products, List<Product>> {
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
  const ProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productsHash();

  @$internal
  @override
  Products create() => Products();
}

String _$productsHash() => r'e235b1c9b3a4ab62d1154bb975e6a9b91fadc1e0';

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

abstract class _$Products extends $AsyncNotifier<List<Product>> {
  FutureOr<List<Product>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Product>>, List<Product>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Product>>, List<Product>>,
              AsyncValue<List<Product>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
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

@ProviderFor(discountStream)
const discountStreamProvider = DiscountStreamProvider._();

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

final class DiscountStreamProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
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
  const DiscountStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discountStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discountStreamHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return discountStream(ref);
  }
}

String _$discountStreamHash() => r'05674bc53ab4d46cdf2f7b9bc7229aab3fac3dcf';

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

@ProviderFor(cartItemCount)
const cartItemCountProvider = CartItemCountProvider._();

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

final class CartItemCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
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
  const CartItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartItemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartItemCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return cartItemCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$cartItemCountHash() => r'4d6454ed2feafb9a33a7b32c734977d966ec0e61';

/// Calculate subtotal (before tax)
///
/// BUSINESS LOGIC:
/// - Sum of all (item.price × item.quantity)

@ProviderFor(cartSubtotal)
const cartSubtotalProvider = CartSubtotalProvider._();

/// Calculate subtotal (before tax)
///
/// BUSINESS LOGIC:
/// - Sum of all (item.price × item.quantity)

final class CartSubtotalProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Calculate subtotal (before tax)
  ///
  /// BUSINESS LOGIC:
  /// - Sum of all (item.price × item.quantity)
  const CartSubtotalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartSubtotalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartSubtotalHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return cartSubtotal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$cartSubtotalHash() => r'321ea5e88d115e0cbc1f777a521f58b53be78ccc';

/// Calculate tax amount
///
/// DEMONSTRATES: Multi-level dependencies
/// - Reads cartSubtotal (which reads cart)
/// - Reads taxRate
/// - Creates chain: cart → subtotal → tax

@ProviderFor(cartTax)
const cartTaxProvider = CartTaxProvider._();

/// Calculate tax amount
///
/// DEMONSTRATES: Multi-level dependencies
/// - Reads cartSubtotal (which reads cart)
/// - Reads taxRate
/// - Creates chain: cart → subtotal → tax

final class CartTaxProvider extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Calculate tax amount
  ///
  /// DEMONSTRATES: Multi-level dependencies
  /// - Reads cartSubtotal (which reads cart)
  /// - Reads taxRate
  /// - Creates chain: cart → subtotal → tax
  const CartTaxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartTaxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartTaxHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return cartTax(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$cartTaxHash() => r'ddb694b6a31c8b3d1397026b414e967dbe2bbb60';

/// Calculate final total (subtotal + tax)

@ProviderFor(cartTotal)
const cartTotalProvider = CartTotalProvider._();

/// Calculate final total (subtotal + tax)

final class CartTotalProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Calculate final total (subtotal + tax)
  const CartTotalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartTotalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartTotalHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return cartTotal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$cartTotalHash() => r'abb61e94628dc207946b8637c2ee014ae31eb50a';

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

@ProviderFor(cartSummary)
const cartSummaryProvider = CartSummaryProvider._();

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

final class CartSummaryProvider
    extends
        $FunctionalProvider<
          Map<String, dynamic>,
          Map<String, dynamic>,
          Map<String, dynamic>
        >
    with $Provider<Map<String, dynamic>> {
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
  const CartSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartSummaryHash();

  @$internal
  @override
  $ProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, dynamic> create(Ref ref) {
    return cartSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, dynamic>>(value),
    );
  }
}

String _$cartSummaryHash() => r'50f83277407e9ef3656a29b44de0a26f51154bc3';

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

@ProviderFor(productById)
const productByIdProvider = ProductByIdFamily._();

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

final class ProductByIdProvider
    extends
        $FunctionalProvider<AsyncValue<Product?>, Product?, FutureOr<Product?>>
    with $FutureModifier<Product?>, $FutureProvider<Product?> {
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
  const ProductByIdProvider._({
    required ProductByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productByIdHash();

  @override
  String toString() {
    return r'productByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Product?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Product?> create(Ref ref) {
    final argument = this.argument as String;
    return productById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productByIdHash() => r'6da324a74c7a57735f876ba9d4a56ea0436fec6c';

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

final class ProductByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Product?>, String> {
  const ProductByIdFamily._()
    : super(
        retry: null,
        name: r'productByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  ProductByIdProvider call(String id) =>
      ProductByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'productByIdProvider';
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

@ProviderFor(productsByPriceRange)
const productsByPriceRangeProvider = ProductsByPriceRangeFamily._();

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

final class ProductsByPriceRangeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          FutureOr<List<Product>>
        >
    with $FutureModifier<List<Product>>, $FutureProvider<List<Product>> {
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
  const ProductsByPriceRangeProvider._({
    required ProductsByPriceRangeFamily super.from,
    required (double, double) super.argument,
  }) : super(
         retry: null,
         name: r'productsByPriceRangeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productsByPriceRangeHash();

  @override
  String toString() {
    return r'productsByPriceRangeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Product>> create(Ref ref) {
    final argument = this.argument as (double, double);
    return productsByPriceRange(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductsByPriceRangeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productsByPriceRangeHash() =>
    r'28d8c671455efca1053527225340134762bd8a5c';

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

final class ProductsByPriceRangeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Product>>, (double, double)> {
  const ProductsByPriceRangeFamily._()
    : super(
        retry: null,
        name: r'productsByPriceRangeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  ProductsByPriceRangeProvider call(double minPrice, double maxPrice) =>
      ProductsByPriceRangeProvider._(
        argument: (minPrice, maxPrice),
        from: this,
      );

  @override
  String toString() => r'productsByPriceRangeProvider';
}

/// Search query state
///
/// UI STATE PATTERN:
/// - Stores user input
/// - Other providers read this to filter data

@ProviderFor(SearchQuery)
const searchQueryProvider = SearchQueryProvider._();

/// Search query state
///
/// UI STATE PATTERN:
/// - Stores user input
/// - Other providers read this to filter data
final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  /// Search query state
  ///
  /// UI STATE PATTERN:
  /// - Stores user input
  /// - Other providers read this to filter data
  const SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'790bd96a8a13bb944767c7bf06a5378cfc78a54d';

/// Search query state
///
/// UI STATE PATTERN:
/// - Stores user input
/// - Other providers read this to filter data

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
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

@ProviderFor(filteredProducts)
const filteredProductsProvider = FilteredProductsProvider._();

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

final class FilteredProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          FutureOr<List<Product>>
        >
    with $FutureModifier<List<Product>>, $FutureProvider<List<Product>> {
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
  const FilteredProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Product>> create(Ref ref) {
    return filteredProducts(ref);
  }
}

String _$filteredProductsHash() => r'82d7039f08ed497112218b704856cb918cfbab79';
