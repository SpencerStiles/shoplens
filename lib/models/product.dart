class Product {
  final int id;
  final String name;
  final String description;
  final String brand;
  final String category;
  final String subcategory;
  final double price;
  final double? salePrice;
  final String currency;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> tags;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.salePrice,
    required this.currency,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.tags,
  });

  bool get isOnSale => salePrice != null;

  double get effectivePrice => salePrice ?? price;

  /// All searchable text lowercased for indexing.
  String get searchableText =>
      '${name.toLowerCase()} ${brand.toLowerCase()} '
      '${category.toLowerCase()} ${subcategory.toLowerCase()} '
      '${description.toLowerCase()} ${tags.join(" ").toLowerCase()}';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      price: (json['price'] as num).toDouble(),
      salePrice: json['salePrice'] != null
          ? (json['salePrice'] as num).toDouble()
          : null,
      currency: json['currency'] as String? ?? 'USD',
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      imageUrl: json['imageUrl'] as String,
      tags: List<String>.from(json['tags'] as List),
    );
  }
}
