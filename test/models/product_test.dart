import 'package:flutter_test/flutter_test.dart';
import 'package:shoplens/models/product.dart';

void main() {
  group('Product', () {
    test('fromJson creates a valid Product', () {
      final json = {
        'id': 1,
        'name': 'Running Shoes',
        'description': 'Lightweight running shoes for daily training',
        'brand': 'Nike',
        'category': 'Sports',
        'subcategory': 'Footwear',
        'price': 129.99,
        'salePrice': 99.99,
        'currency': 'USD',
        'rating': 4.5,
        'reviewCount': 1234,
        'imageUrl': 'https://example.com/shoe.jpg',
        'tags': ['running', 'lightweight', 'sports'],
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Running Shoes');
      expect(product.brand, 'Nike');
      expect(product.category, 'Sports');
      expect(product.price, 129.99);
      expect(product.salePrice, 99.99);
      expect(product.isOnSale, true);
      expect(product.rating, 4.5);
      expect(product.reviewCount, 1234);
      expect(product.tags, ['running', 'lightweight', 'sports']);
    });

    test('fromJson handles null salePrice', () {
      final json = {
        'id': 2,
        'name': 'Basic Tee',
        'description': 'Plain cotton t-shirt',
        'brand': 'Uniqlo',
        'category': 'Clothing',
        'subcategory': 'Tops',
        'price': 19.99,
        'salePrice': null,
        'currency': 'USD',
        'rating': 4.0,
        'reviewCount': 500,
        'imageUrl': 'https://example.com/tee.jpg',
        'tags': ['cotton', 'basics'],
      };

      final product = Product.fromJson(json);

      expect(product.salePrice, isNull);
      expect(product.isOnSale, false);
    });

    test('searchableText concatenates all searchable fields', () {
      final product = Product(
        id: 1,
        name: 'Running Shoes',
        description: 'Great for jogging',
        brand: 'Nike',
        category: 'Sports',
        subcategory: 'Footwear',
        price: 100,
        salePrice: null,
        currency: 'USD',
        rating: 4.0,
        reviewCount: 100,
        imageUrl: '',
        tags: ['running'],
      );

      expect(product.searchableText, contains('running shoes'));
      expect(product.searchableText, contains('nike'));
      expect(product.searchableText, contains('sports'));
    });
  });
}
