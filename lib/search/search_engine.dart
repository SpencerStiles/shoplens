import '../models/product.dart';

/// Field weights for relevance scoring.
enum SearchField {
  name(3.0),
  brand(2.0),
  category(1.5),
  tags(1.5),
  description(1.0);

  final double weight;
  const SearchField(this.weight);
}

/// A single posting in the inverted index.
class IndexEntry {
  final int productIndex;
  final SearchField field;

  const IndexEntry(this.productIndex, this.field);
}

/// Score breakdown for a single signal.
class ScoreComponent {
  final String label;
  final double value;

  const ScoreComponent(this.label, this.value);
}

/// A search result with score breakdown.
class SearchResult {
  final Product product;
  final double score;
  final List<ScoreComponent> breakdown;
  final Set<String> matchedTerms;

  const SearchResult({
    required this.product,
    required this.score,
    required this.breakdown,
    required this.matchedTerms,
  });
}

class SearchEngine {
  final List<Product> _products;
  final Map<String, List<IndexEntry>> _index = {};

  SearchEngine(this._products) {
    _buildIndex();
  }

  /// Tokenize text into lowercase terms, stripping punctuation.
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[']"), '')
        .replaceAll(RegExp(r"[-_]"), ' ')
        .replaceAll(RegExp(r"[^\w\s]"), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  void _buildIndex() {
    for (var i = 0; i < _products.length; i++) {
      final p = _products[i];
      _indexField(i, p.name, SearchField.name);
      _indexField(i, p.brand, SearchField.brand);
      _indexField(i, p.category, SearchField.category);
      _indexField(i, p.tags.join(' '), SearchField.tags);
      _indexField(i, p.description, SearchField.description);
    }
  }

  void _indexField(int productIndex, String text, SearchField field) {
    for (final token in tokenize(text)) {
      _index.putIfAbsent(token, () => []).add(IndexEntry(productIndex, field));
    }
  }

  /// All indexed terms (for autocomplete).
  Iterable<String> get terms => _index.keys;

  /// Levenshtein edit distance between two strings.
  static int levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List.generate(b.length + 1, (i) => i);
    List<int> curr = List.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,    // insertion
          prev[j] + 1,        // deletion
          prev[j - 1] + cost, // substitution
        ].reduce((x, y) => x < y ? x : y);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[b.length];
  }

  /// Find fuzzy matches for a token (edit distance 1–2).
  List<MapEntry<String, int>> _fuzzyMatches(String token) {
    final matches = <MapEntry<String, int>>[];
    if (token.length < 3) return matches;

    for (final indexedTerm in _index.keys) {
      if ((indexedTerm.length - token.length).abs() > 2) continue;
      final dist = levenshteinDistance(token, indexedTerm);
      if (dist > 0 && dist <= 2) {
        matches.add(MapEntry(indexedTerm, dist));
      }
    }
    return matches;
  }

  /// Get autocomplete suggestions for a partial query.
  List<String> autocomplete(String partial, {int maxResults = 5}) {
    final token = partial.toLowerCase().trim();
    if (token.isEmpty) return [];
    return _index.keys
        .where((term) => term.startsWith(token) && term != token)
        .take(maxResults)
        .toList();
  }

  /// Search products by query string.
  List<SearchResult> search(String query) {
    final queryTokens = tokenize(query);

    // Empty query → return all products (no scoring)
    if (queryTokens.isEmpty) {
      return _products
          .map((p) => SearchResult(
                product: p,
                score: 0,
                breakdown: [],
                matchedTerms: {},
              ))
          .toList();
    }

    final scores = <int, _ProductScore>{};

    for (final token in queryTokens) {
      // Exact match
      final exactEntries = _index[token];
      if (exactEntries != null) {
        for (final entry in exactEntries) {
          scores
              .putIfAbsent(entry.productIndex,
                  () => _ProductScore(_products[entry.productIndex]))
              .addMatch(token, entry.field, 'exact');
        }
      }

      // Prefix match (only when no exact match)
      if (exactEntries == null || exactEntries.isEmpty) {
        for (final indexedTerm in _index.keys) {
          if (indexedTerm.startsWith(token) && indexedTerm != token) {
            for (final entry in _index[indexedTerm]!) {
              scores
                  .putIfAbsent(entry.productIndex,
                      () => _ProductScore(_products[entry.productIndex]))
                  .addMatch(token, entry.field, 'prefix');
            }
          }
        }
      }

      // Fuzzy match (only if still no match for this token)
      if (!scores.values.any((ps) => ps.matchedTerms.contains(token))) {
        final fuzzyMatches = _fuzzyMatches(token);
        for (final match in fuzzyMatches) {
          for (final entry in _index[match.key]!) {
            scores
                .putIfAbsent(entry.productIndex,
                    () => _ProductScore(_products[entry.productIndex]))
                .addMatch(token, entry.field, 'fuzzy');
          }
        }
      }
    }

    final results =
        scores.values.map((ps) => ps.toResult(queryTokens)).toList();
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}

class _ProductScore {
  final Product product;
  final Map<String, _FieldMatch> _fieldMatches = {};
  final Set<String> matchedTerms = {};

  _ProductScore(this.product);

  void addMatch(String queryTerm, SearchField field, String matchType) {
    matchedTerms.add(queryTerm);
    final key = '${field.name}:$queryTerm';
    final existing = _fieldMatches[key];
    if (existing == null || matchType == 'exact') {
      _fieldMatches[key] = _FieldMatch(field, queryTerm, matchType);
    }
  }

  SearchResult toResult(List<String> queryTokens) {
    final breakdown = <ScoreComponent>[];
    double total = 0;

    // Text match score
    for (final fm in _fieldMatches.values) {
      final multiplier = fm.matchType == 'exact'
          ? 1.0
          : fm.matchType == 'prefix'
              ? 0.6
              : 0.35; // fuzzy
      final score = fm.field.weight * 0.15 * multiplier;
      total += score;
      breakdown.add(ScoreComponent(
        '${fm.field.name} match "${fm.queryTerm}" (${fm.matchType})',
        score,
      ));
    }

    // Query coverage bonus
    final coverage = matchedTerms.length / queryTokens.length;
    if (coverage == 1.0 && queryTokens.length > 1) {
      const bonus = 0.1;
      total += bonus;
      breakdown.add(const ScoreComponent('all terms matched', bonus));
    }

    // Popularity boost
    const maxReviews = 5000.0;
    final popularityRaw = (product.rating / 5.0) *
        (product.reviewCount / maxReviews).clamp(0.0, 1.0);
    final popularityBoost = (popularityRaw * 0.2).clamp(0.0, 0.2);
    if (popularityBoost > 0.01) {
      total += popularityBoost;
      breakdown.add(ScoreComponent(
        'popularity (${product.rating}★, ${product.reviewCount} reviews)',
        popularityBoost,
      ));
    }

    // Sale boost
    if (product.isOnSale) {
      const saleBoost = 0.07;
      total += saleBoost;
      breakdown.add(const ScoreComponent('sale price', saleBoost));
    }

    return SearchResult(
      product: product,
      score: total,
      breakdown: breakdown,
      matchedTerms: matchedTerms,
    );
  }
}

class _FieldMatch {
  final SearchField field;
  final String queryTerm;
  final String matchType;

  const _FieldMatch(this.field, this.queryTerm, this.matchType);
}
