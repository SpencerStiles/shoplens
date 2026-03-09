import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoplens/models/product.dart';
import 'package:shoplens/search/search_engine.dart';
import 'package:shoplens/widgets/result_card.dart';

Product _makeProduct({
  int id = 1,
  String name = 'Test Product',
  double price = 49.99,
  double? salePrice,
  double rating = 4.2,
  int reviewCount = 150,
  String brand = 'TestBrand',
  String category = 'Electronics',
}) {
  return Product(
    id: id,
    name: name,
    description: 'A test description',
    brand: brand,
    category: category,
    subcategory: 'Sub',
    price: price,
    salePrice: salePrice,
    currency: 'USD',
    rating: rating,
    reviewCount: reviewCount,
    imageUrl: 'https://picsum.photos/seed/p$id/300/300',
    tags: [],
  );
}

SearchResult _makeResult(Product product, {double score = 0.5}) {
  return SearchResult(
    product: product,
    score: score,
    breakdown: [
      const ScoreComponent('name match "test" (exact)', 0.45),
      const ScoreComponent('popularity (4.2★, 150 reviews)', 0.05),
    ],
    matchedTerms: {'test'},
  );
}

void main() {
  group('ResultCard', () {
    testWidgets('displays product name', (tester) async {
      final product = _makeProduct(name: 'Wireless Headphones');
      final result = _makeResult(product);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Wireless Headphones'), findsOneWidget);
    });

    testWidgets('shows sale price when on sale', (tester) async {
      final product = _makeProduct(price: 99.99, salePrice: 69.99);
      final result = _makeResult(product);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('\$69.99'), findsOneWidget);
      expect(find.text('\$99.99'), findsOneWidget); // strikethrough original
    });

    testWidgets('shows regular price when not on sale', (tester) async {
      final product = _makeProduct(price: 49.99);
      final result = _makeResult(product);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('\$49.99'), findsOneWidget);
    });

    testWidgets('shows rating and review count', (tester) async {
      final product = _makeProduct(rating: 4.2, reviewCount: 150);
      final result = _makeResult(product);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('4.2'), findsOneWidget);
      expect(find.text('(150)'), findsOneWidget);
    });

    testWidgets('shows brand and category', (tester) async {
      final product = _makeProduct(brand: 'Sony', category: 'Electronics');
      final result = _makeResult(product);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultCard(result: result),
            ),
          ),
        ),
      );

      expect(find.textContaining('Sony'), findsOneWidget);
    });

    testWidgets('tapping calls onTap', (tester) async {
      final product = _makeProduct();
      final result = _makeResult(product);
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResultCard(result: result, onTap: () => tapped = true),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ResultCard));
      expect(tapped, true);
    });
  });
}
