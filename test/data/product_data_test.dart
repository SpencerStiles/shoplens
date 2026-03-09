import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoplens/models/product.dart';

void main() {
  test('products.json is valid and parses all products', () {
    final file = File('assets/products.json');
    expect(file.existsSync(), true);

    final jsonStr = file.readAsStringSync();
    final list = jsonDecode(jsonStr) as List;

    expect(list.length, greaterThanOrEqualTo(500));

    final products = list.map((j) => Product.fromJson(j as Map<String, dynamic>)).toList();
    expect(products.length, list.length);

    final categories = products.map((p) => p.category).toSet();
    expect(categories.length, greaterThanOrEqualTo(8));

    final brands = products.map((p) => p.brand).toSet();
    expect(brands.length, greaterThanOrEqualTo(20));
  });
}
