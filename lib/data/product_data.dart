import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/product.dart';

class ProductData {
  static Future<List<Product>> loadProducts() async {
    final jsonStr = await rootBundle.loadString('assets/products.json');
    final list = jsonDecode(jsonStr) as List;
    return list
        .map((j) => Product.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
