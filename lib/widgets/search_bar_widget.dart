import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      ref.read(searchQueryProvider.notifier).state = value;
      _updateSuggestions(value);
    });
  }

  void _updateSuggestions(String value) {
    final engine = ref.read(searchEngineProvider);
    if (engine == null || value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Autocomplete on the last word being typed
    final lastWord = value.trim().split(' ').last;
    if (lastWord.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final suggestions = engine.autocomplete(lastWord, maxResults: 5);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  void _selectSuggestion(String suggestion) {
    final current = _controller.text.trim();
    final words = current.split(' ');
    words[words.length - 1] = suggestion;
    final newText = '${words.join(' ')} ';
    _controller.text = newText;
    _controller.selection =
        TextSelection.collapsed(offset: newText.length);
    ref.read(searchQueryProvider.notifier).state = newText.trim();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultCount = ref.watch(searchResultsProvider).length;
    final query = ref.watch(searchQueryProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outline.withAlpha(80)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.search, color: cs.primary),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  onSubmitted: (_) => setState(() => _showSuggestions = false),
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search 1,000 products…',
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clear,
                  tooltip: 'Clear',
                ),
              // Performance badge
              if (query.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$resultCount results',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Autocomplete dropdown
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outline.withAlpha(60)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((suggestion) {
                return InkWell(
                  onTap: () => _selectSuggestion(suggestion),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 16,
                            color: cs.onSurface.withAlpha(100)),
                        const SizedBox(width: 12),
                        _buildHighlightedSuggestion(context, suggestion),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedSuggestion(BuildContext context, String suggestion) {
    final lastWord = _controller.text.trim().split(' ').last.toLowerCase();
    if (!suggestion.startsWith(lastWord) || lastWord.isEmpty) {
      return Text(suggestion);
    }
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(
            text: suggestion.substring(0, lastWord.length),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: suggestion.substring(lastWord.length)),
        ],
      ),
    );
  }
}
