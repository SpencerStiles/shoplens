import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_data.dart';
import '../models/product.dart';
import '../search/search_engine.dart';

/// Loads products from bundled JSON asset.
final productDataProvider = FutureProvider<List<Product>>((ref) async {
  return ProductData.loadProducts();
});

/// Builds search index when products are loaded.
final searchEngineProvider = Provider<SearchEngine?>((ref) {
  final productsAsync = ref.watch(productDataProvider);
  return productsAsync.whenData((products) => SearchEngine(products)).value;
});

/// Current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Sort mode.
enum SortMode { relevance, priceLow, priceHigh, rating }

final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.relevance);

/// Active filters.
class FilterState {
  final Set<String> categories;
  final Set<String> brands;
  final double minPrice;
  final double maxPrice;
  final double minRating;

  const FilterState({
    this.categories = const {},
    this.brands = const {},
    this.minPrice = 0,
    this.maxPrice = double.infinity,
    this.minRating = 0,
  });

  FilterState copyWith({
    Set<String>? categories,
    Set<String>? brands,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    return FilterState(
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
    );
  }

  bool get isActive =>
      categories.isNotEmpty ||
      brands.isNotEmpty ||
      minPrice > 0 ||
      maxPrice < double.infinity ||
      minRating > 0;

  bool matches(Product p) {
    if (categories.isNotEmpty && !categories.contains(p.category)) return false;
    if (brands.isNotEmpty && !brands.contains(p.brand)) return false;
    if (p.effectivePrice < minPrice) return false;
    if (maxPrice < double.infinity && p.effectivePrice > maxPrice) return false;
    if (p.rating < minRating) return false;
    return true;
  }
}

final filtersProvider = StateProvider<FilterState>((ref) => const FilterState());

/// Computed: search results filtered and sorted.
final searchResultsProvider = Provider<List<SearchResult>>((ref) {
  final engine = ref.watch(searchEngineProvider);
  if (engine == null) return [];

  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(filtersProvider);
  final sortMode = ref.watch(sortModeProvider);

  var results = engine.search(query);
  results = results.where((r) => filters.matches(r.product)).toList();

  switch (sortMode) {
    case SortMode.relevance:
      break;
    case SortMode.priceLow:
      results.sort(
          (a, b) => a.product.effectivePrice.compareTo(b.product.effectivePrice));
    case SortMode.priceHigh:
      results.sort(
          (a, b) => b.product.effectivePrice.compareTo(a.product.effectivePrice));
    case SortMode.rating:
      results.sort((a, b) => b.product.rating.compareTo(a.product.rating));
  }

  return results;
});

/// Available categories from loaded products.
final categoriesProvider = Provider<List<String>>((ref) {
  final productsAsync = ref.watch(productDataProvider);
  return productsAsync.when(
    data: (products) {
      final cats = products.map((p) => p.category).toSet().toList()..sort();
      return cats;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Available brands from loaded products.
final brandsProvider = Provider<List<String>>((ref) {
  final productsAsync = ref.watch(productDataProvider);
  return productsAsync.when(
    data: (products) {
      final brands = products.map((p) => p.brand).toSet().toList()..sort();
      return brands;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Max price across all products (for slider upper bound).
final maxProductPriceProvider = Provider<double>((ref) {
  final productsAsync = ref.watch(productDataProvider);
  return productsAsync.when(
    data: (products) =>
        products.map((p) => p.price).reduce((a, b) => a > b ? a : b),
    loading: () => 2000.0,
    error: (_, __) => 2000.0,
  );
});
