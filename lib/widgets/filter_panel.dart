import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final categories = ref.watch(categoriesProvider);
    final brands = ref.watch(brandsProvider);
    final maxPrice = ref.watch(maxProductPriceProvider);
    final cs = Theme.of(context).colorScheme;

    final effectiveMax = maxPrice > 0 ? maxPrice : 2000.0;
    final currentMax = filters.maxPrice == double.infinity
        ? effectiveMax
        : filters.maxPrice.clamp(0.0, effectiveMax);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(right: BorderSide(color: cs.outline.withAlpha(40))),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.tune, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Filters',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (filters.isActive)
                  TextButton(
                    onPressed: () => ref
                        .read(filtersProvider.notifier)
                        .state = const FilterState(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text('Clear all',
                        style: TextStyle(color: cs.error, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable filter content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Categories
                _SectionHeader(label: 'Category'),
                const SizedBox(height: 8),
                ...categories.map((cat) {
                  final selected = filters.categories.contains(cat);
                  return _FilterCheckbox(
                    label: cat,
                    selected: selected,
                    onChanged: (val) {
                      final newCats = Set<String>.from(filters.categories);
                      if (val) {
                        newCats.add(cat);
                      } else {
                        newCats.remove(cat);
                      }
                      ref.read(filtersProvider.notifier).state =
                          filters.copyWith(categories: newCats);
                    },
                  );
                }),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Price range
                _SectionHeader(label: 'Price Range'),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${filters.minPrice.round()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      filters.maxPrice == double.infinity
                          ? 'Any'
                          : '\$${currentMax.round()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(
                    filters.minPrice.clamp(0.0, effectiveMax),
                    currentMax,
                  ),
                  min: 0,
                  max: effectiveMax,
                  divisions: 40,
                  onChanged: (range) {
                    final newMax = range.end >= effectiveMax
                        ? double.infinity
                        : range.end;
                    ref.read(filtersProvider.notifier).state =
                        filters.copyWith(
                      minPrice: range.start,
                      maxPrice: newMax,
                    );
                  },
                ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // Minimum rating
                _SectionHeader(label: 'Min Rating'),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    final active = filters.minRating >= star;
                    return GestureDetector(
                      onTap: () {
                        final newRating = filters.minRating == star.toDouble()
                            ? 0.0
                            : star.toDouble();
                        ref.read(filtersProvider.notifier).state =
                            filters.copyWith(minRating: newRating);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          active ? Icons.star : Icons.star_border,
                          color: active ? Colors.amber : Colors.grey,
                          size: 28,
                        ),
                      ),
                    );
                  }),
                ),
                if (filters.minRating > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${filters.minRating.round()}+ stars',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.primary),
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Brands
                _SectionHeader(label: 'Brand'),
                const SizedBox(height: 8),
                ...brands.map((brand) {
                  final selected = filters.brands.contains(brand);
                  return _FilterCheckbox(
                    label: brand,
                    selected: selected,
                    onChanged: (val) {
                      final newBrands = Set<String>.from(filters.brands);
                      if (val) {
                        newBrands.add(brand);
                      } else {
                        newBrands.remove(brand);
                      }
                      ref.read(filtersProvider.notifier).state =
                          filters.copyWith(brands: newBrands);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
          ),
    );
  }
}

class _FilterCheckbox extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _FilterCheckbox({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: selected,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
