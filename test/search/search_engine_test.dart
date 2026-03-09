import 'package:flutter_test/flutter_test.dart';
import 'package:shoplens/models/product.dart';
import 'package:shoplens/search/search_engine.dart';

Product _makeProduct({
  int id = 1,
  String name = 'Test Product',
  String description = 'A test description',
  String brand = 'TestBrand',
  String category = 'TestCategory',
  double price = 10.0,
  double? salePrice,
  double rating = 4.0,
  int reviewCount = 100,
  List<String> tags = const [],
}) {
  return Product(
    id: id,
    name: name,
    description: description,
    brand: brand,
    category: category,
    subcategory: 'Sub',
    price: price,
    salePrice: salePrice,
    currency: 'USD',
    rating: rating,
    reviewCount: reviewCount,
    imageUrl: '',
    tags: tags,
  );
}

void main() {
  group('SearchEngine - tokenize', () {
    test('splits text into lowercase tokens', () {
      final tokens = SearchEngine.tokenize('Running Shoes Nike');
      expect(tokens, ['running', 'shoes', 'nike']);
    });

    test('removes punctuation', () {
      final tokens = SearchEngine.tokenize("Men's high-top sneakers!");
      expect(tokens, containsAll(['mens', 'high', 'top', 'sneakers']));
    });

    test('handles empty string', () {
      final tokens = SearchEngine.tokenize('');
      expect(tokens, isEmpty);
    });
  });

  group('SearchEngine - index and exact search', () {
    late SearchEngine engine;

    setUp(() {
      engine = SearchEngine([
        _makeProduct(id: 1, name: 'Running Shoes', brand: 'Nike', category: 'Sports'),
        _makeProduct(id: 2, name: 'Basketball Shoes', brand: 'Adidas', category: 'Sports'),
        _makeProduct(id: 3, name: 'Cotton T-Shirt', brand: 'Uniqlo', category: 'Clothing'),
      ]);
    });

    test('exact name match returns correct product', () {
      final results = engine.search('running shoes');
      expect(results.isNotEmpty, true);
      expect(results.first.product.id, 1);
    });

    test('brand search returns correct products', () {
      final results = engine.search('nike');
      expect(results.any((r) => r.product.id == 1), true);
    });

    test('empty query returns all products', () {
      final results = engine.search('');
      expect(results.length, 3);
    });

    test('gibberish returns no results', () {
      final results = engine.search('xyzzyplugh');
      expect(results, isEmpty);
    });

    test('name match scores higher than description match', () {
      final products = [
        _makeProduct(id: 1, name: 'Wireless Headphones', description: 'Great sound'),
        _makeProduct(id: 2, name: 'Phone Case', description: 'Works with wireless headphones'),
      ];
      final eng = SearchEngine(products);
      final results = eng.search('wireless headphones');

      expect(results.length, 2);
      expect(results.first.product.id, 1);
    });
  });

  group('SearchEngine - fuzzy matching', () {
    late SearchEngine engine;

    setUp(() {
      engine = SearchEngine([
        _makeProduct(id: 1, name: 'Running Shoes', brand: 'Nike'),
        _makeProduct(id: 2, name: 'Basketball Shoes', brand: 'Adidas'),
        _makeProduct(id: 3, name: 'Wireless Headphones', brand: 'Sony'),
      ]);
    });

    test('finds products with 1-char typo', () {
      final results = engine.search('runnign shoes');
      expect(results.any((r) => r.product.id == 1), true);
    });

    test('finds products with 2-char typo', () {
      final results = engine.search('wireles headphnes');
      expect(results.any((r) => r.product.id == 3), true);
    });

    test('fuzzy match scores lower than exact match', () {
      final results = engine.search('runnign shoes');
      final fuzzyResult = results.firstWhere((r) => r.product.id == 1);

      final exactResults = engine.search('running shoes');
      final exactResult = exactResults.firstWhere((r) => r.product.id == 1);

      expect(exactResult.score, greaterThan(fuzzyResult.score));
    });
  });

  group('SearchEngine - levenshtein', () {
    test('identical strings have distance 0', () {
      expect(SearchEngine.levenshteinDistance('hello', 'hello'), 0);
    });

    test('single insertion', () {
      expect(SearchEngine.levenshteinDistance('helo', 'hello'), 1);
    });

    test('single deletion', () {
      expect(SearchEngine.levenshteinDistance('hello', 'helo'), 1);
    });

    test('single substitution', () {
      expect(SearchEngine.levenshteinDistance('hello', 'hallo'), 1);
    });

    test('distance of 2', () {
      expect(SearchEngine.levenshteinDistance('running', 'runnign'), 2);
    });
  });

  group('SearchEngine - autocomplete', () {
    test('returns prefix-matching terms', () {
      final engine = SearchEngine([
        _makeProduct(name: 'Running Shoes', brand: 'Nike'),
        _makeProduct(id: 2, name: 'Rugby Ball', brand: 'Gilbert'),
      ]);

      final suggestions = engine.autocomplete('run');
      expect(suggestions, contains('running'));
    });

    test('limits results to maxResults', () {
      final engine = SearchEngine([
        _makeProduct(name: 'Running Shoes'),
        _makeProduct(id: 2, name: 'Runner Jacket'),
        _makeProduct(id: 3, name: 'Runt Dog Toy'),
      ]);

      final suggestions = engine.autocomplete('run', maxResults: 2);
      expect(suggestions.length, lessThanOrEqualTo(2));
    });
  });
}
