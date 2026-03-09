import 'package:flutter/material.dart';
import '../search/search_engine.dart';

/// Side panel showing relevance score breakdown for a search result.
class ExplainPanel extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onClose;

  const ExplainPanel({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = result.product;

    // Find the maximum component score for the bar chart
    final maxScore = result.breakdown.isEmpty
        ? 1.0
        : result.breakdown
            .map((c) => c.value)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outline.withAlpha(40))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: cs.outline.withAlpha(40))),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Score Breakdown',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Product name + total score
                Text(p.name,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Total score: ',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurface.withAlpha(140))),
                    Text(
                      result.score.toStringAsFixed(3),
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Score components
                if (result.breakdown.isEmpty)
                  Text('No scoring signals (empty query).',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurface.withAlpha(120)))
                else ...[
                  Text(
                    'SIGNALS',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: cs.onSurface.withAlpha(140),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.breakdown.map(
                    (comp) => _ScoreRow(
                      component: comp,
                      maxScore: maxScore,
                      totalScore: result.score,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Matched terms
                Text(
                  'MATCHED TERMS',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: cs.onSurface.withAlpha(140),
                  ),
                ),
                const SizedBox(height: 8),
                if (result.matchedTerms.isEmpty)
                  Text('None', style: tt.bodySmall)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: result.matchedTerms
                        .map((term) => _TermChip(term: term))
                        .toList(),
                  ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Product metadata
                Text(
                  'PRODUCT INFO',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: cs.onSurface.withAlpha(140),
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow('Brand', p.brand),
                _InfoRow('Category', p.category),
                _InfoRow('Rating', '${p.rating} ★'),
                _InfoRow('Reviews', p.reviewCount.toString()),
                _InfoRow('Price', '\$${p.effectivePrice.toStringAsFixed(2)}'),
                if (p.isOnSale)
                  _InfoRow('Original', '\$${p.price.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final ScoreComponent component;
  final double maxScore;
  final double totalScore;

  const _ScoreRow({
    required this.component,
    required this.maxScore,
    required this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final barFraction = maxScore > 0 ? (component.value / maxScore) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  component.label,
                  style: tt.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${component.value.toStringAsFixed(3)}',
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Container(
                height: 4,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: barFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TermChip extends StatelessWidget {
  final String term;
  const _TermChip({required this.term});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        term,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurface.withAlpha(140))),
          ),
          Expanded(
            child: Text(value,
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
