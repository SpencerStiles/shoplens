import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../search/search_engine.dart';
import '../widgets/filter_panel.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/result_card.dart';
import '../widgets/explain_panel.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  SearchResult? _selectedResult;

  @override
  Widget build(BuildContext context) {
    final productData = ref.watch(productDataProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: productData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text('Failed to load products', style: TextStyle(color: cs.error)),
              const SizedBox(height: 8),
              Text('$e',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (_) => _SearchLayout(
          selectedResult: _selectedResult,
          onResultSelected: (result) =>
              setState(() => _selectedResult = result),
          onExplainClosed: () => setState(() => _selectedResult = null),
        ),
      ),
    );
  }
}

class _SearchLayout extends ConsumerWidget {
  final SearchResult? selectedResult;
  final ValueChanged<SearchResult?> onResultSelected;
  final VoidCallback onExplainClosed;

  const _SearchLayout({
    required this.selectedResult,
    required this.onResultSelected,
    required this.onExplainClosed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Left: filter panel (fixed width)
        const FilterPanel(),

        // Center: search + results
        Expanded(
          child: Column(
            children: [
              _TopBar(onResultSelected: onResultSelected),
              const Expanded(child: _ResultList()),
            ],
          ),
        ),

        // Right: explain panel (appears on card tap)
        if (selectedResult != null)
          ExplainPanel(
            result: selectedResult!,
            onClose: onExplainClosed,
          ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  final ValueChanged<SearchResult?> onResultSelected;
  const _TopBar({required this.onResultSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sort = ref.watch(sortModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline.withAlpha(40))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // App logo / name
          Icon(Icons.search_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'ShopLens',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
          ),
          const SizedBox(width: 16),

          // Search bar (expands)
          const Expanded(child: SearchBarWidget()),

          const SizedBox(width: 12),

          // Sort dropdown
          _SortDropdown(
            current: sort,
            onChange: (s) {
              ref.read(sortModeProvider.notifier).state = s;
              onResultSelected(null);
            },
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final SortMode current;
  final ValueChanged<SortMode> onChange;

  const _SortDropdown({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<SortMode>(
        value: current,
        isDense: true,
        borderRadius: BorderRadius.circular(8),
        items: const [
          DropdownMenuItem(value: SortMode.relevance, child: Text('Relevance')),
          DropdownMenuItem(value: SortMode.priceLow, child: Text('Price ↑')),
          DropdownMenuItem(value: SortMode.priceHigh, child: Text('Price ↓')),
          DropdownMenuItem(value: SortMode.rating, child: Text('Rating')),
        ],
        onChanged: (v) => onChange(v ?? SortMode.relevance),
      ),
    );
  }
}

class _ResultList extends ConsumerWidget {
  const _ResultList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final filters = ref.watch(filtersProvider);
    final productData = ref.watch(productDataProvider);

    // Show skeleton while loading
    if (productData.isLoading) {
      return const _LoadingSkeleton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active filter chips
        if (filters.isActive) _ActiveFilterChips(filters: filters),

        // Result count header
        if (results.isNotEmpty || query.isNotEmpty || filters.isActive)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(140),
                  ),
            ),
          ),

        // Results or empty state
        Expanded(
          child: results.isEmpty
              ? _EmptyState(query: query, hasFilters: filters.isActive)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final result = results[i];
                    return ResultCard(
                      result: result,
                      onTap: () {
                        final screen = context
                            .findAncestorStateOfType<_SearchScreenState>();
                        screen?.setState(
                            () => screen._selectedResult = result);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ActiveFilterChips extends ConsumerWidget {
  final FilterState filters;
  const _ActiveFilterChips({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    void removeFilter(FilterState updated) {
      ref.read(filtersProvider.notifier).state = updated;
    }

    final chips = <Widget>[];

    for (final cat in filters.categories) {
      chips.add(_FilterChip(
        label: cat,
        onRemove: () => removeFilter(
          filters.copyWith(
              categories: Set.from(filters.categories)..remove(cat)),
        ),
      ));
    }
    for (final brand in filters.brands) {
      chips.add(_FilterChip(
        label: brand,
        onRemove: () => removeFilter(
          filters.copyWith(brands: Set.from(filters.brands)..remove(brand)),
        ),
      ));
    }
    if (filters.minPrice > 0 || filters.maxPrice < double.infinity) {
      final label = filters.maxPrice == double.infinity
          ? '\$${filters.minPrice.round()}+'
          : '\$${filters.minPrice.round()}–\$${filters.maxPrice.round()}';
      chips.add(_FilterChip(
        label: label,
        onRemove: () => removeFilter(
          filters.copyWith(
              minPrice: 0.0, maxPrice: double.infinity),
        ),
      ));
    }
    if (filters.minRating > 0) {
      chips.add(_FilterChip(
        label: '${filters.minRating.round()}★+',
        onRemove: () => removeFilter(filters.copyWith(minRating: 0.0)),
      ));
    }

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shimmer = cs.surfaceContainerHighest;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, i) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 14, width: double.infinity, color: shimmer),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 120, color: shimmer),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 80, color: shimmer),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 60, color: shimmer),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final bool hasFilters;

  const _EmptyState({required this.query, required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isSearching = query.isNotEmpty || hasFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.shopping_bag_outlined,
              size: 64,
              color: cs.onSurface.withAlpha(80),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No results found' : 'Search for products',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? query.isNotEmpty
                      ? 'Try a different search term or adjust your filters.'
                      : 'No products match the current filters.'
                  : 'Type a product name, brand, or category to get started.',
              style:
                  tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(120)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
