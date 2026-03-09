import 'package:flutter/material.dart';
import '../search/search_engine.dart';

class ResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onTap;

  const ResultCard({super.key, required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = result.product;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  p.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported,
                        color: cs.onSurfaceVariant, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      p.name,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Brand · Category
                    Text(
                      '${p.brand} · ${p.category}',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurface.withAlpha(140)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Rating row
                    Row(
                      children: [
                        Icon(Icons.star, size: 13, color: Colors.amber.shade600),
                        const SizedBox(width: 2),
                        Text(p.rating.toStringAsFixed(1),
                            style: tt.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('(${p.reviewCount})',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurface.withAlpha(120))),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price row
                    Row(
                      children: [
                        if (p.isOnSale) ...[
                          Text(
                            '\$${p.effectivePrice.toStringAsFixed(2)}',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.error,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '\$${p.price.toStringAsFixed(2)}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withAlpha(120),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _SaleBadge(
                              discount: ((1 - p.effectivePrice / p.price) * 100)
                                  .round()),
                        ] else
                          Text(
                            '\$${p.price.toStringAsFixed(2)}',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Score chip (debug-style relevance indicator)
              if (result.score > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _ScoreChip(score: result.score),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleBadge extends StatelessWidget {
  final int discount;
  const _SaleBadge({required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-$discount%',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final double score;
  const _ScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        score.toStringAsFixed(2),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
