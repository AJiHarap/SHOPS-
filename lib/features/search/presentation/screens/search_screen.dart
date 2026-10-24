import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../features/listings/data/listings_repository.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/widgets/listing_card.dart';



const _conditions = [
  'new', 'like_new', 'good', 'fair', 'salvage'
];

const _conditionLabels = {
  'new': 'New',
  'like_new': 'Like New',
  'good': 'Good',
  'fair': 'Fair',
  'salvage': 'Salvage',
};

const _sortOptions = [
  ('created_at', false, 'Newest first'),
  ('created_at', true, 'Oldest first'),
  ('price', true, 'Price: low to high'),
  ('price', false, 'Price: high to low'),
];

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const SearchScreen({super.key, this.initialQuery, this.initialCategory});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  String? _selectedCategory;
  String? _selectedCondition;
  int _sortIndex = 0;
  List<Listing> _results = [];
  bool _isLoading = false;
  String? _error;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _selectedCategory = widget.initialCategory;
    _search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search({bool reset = true}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _results = [];
        _hasMore = true;
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final sort = _sortOptions[_sortIndex];
      final newItems = await ref.read(listingsRepositoryProvider).fetchListings(
            query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            category: _selectedCategory,
            condition: _selectedCondition,
            sortBy: sort.$1,
            ascending: sort.$2,
            page: _page,
            pageSize: 20,
          );

      setState(() {
        if (reset) {
          _results = newItems;
        } else {
          _results = [..._results, ...newItems];
        }
        _hasMore = newItems.length == 20;
        if (!reset) _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadMore() {
    if (_isLoading || !_hasMore) return;
    _search(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        titleSpacing: 0,
        leading: const BackButton(),
        title: TextField(
          controller: _searchController,
          autofocus: widget.initialQuery == null,
          decoration: InputDecoration(
            hintText: 'Search materials...',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.mutedGrey),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: AppTypography.bodyMedium,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                _searchController.clear();
                _search();
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter row
          _FilterRow(
            selectedCategory: _selectedCategory,
            selectedCondition: _selectedCondition,
            sortIndex: _sortIndex,
            onCategoryChanged: (c) {
              setState(() => _selectedCategory = c);
              _search();
            },
            onConditionChanged: (c) {
              setState(() => _selectedCondition = c);
              _search();
            },
            onSortChanged: (i) {
              setState(() => _sortIndex = i);
              _search();
            },
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.warmGrey),
            const SizedBox(height: 12),
            Text('Search failed.', style: AppTypography.bodyMedium),
            const SizedBox(height: 4),
            Text(_error!, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (_isLoading && _results.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ListingCardShimmer(),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.mutedGrey),
            const SizedBox(height: 16),
            Text('No listings found.', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Try a different search or remove filters.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _results.length + (_hasMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= _results.length) return const ListingCardShimmer();
          return ListingCard(listing: _results[index]);
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedCondition;
  final int sortIndex;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onConditionChanged;
  final ValueChanged<int> onSortChanged;

  const _FilterRow({
    required this.selectedCategory,
    required this.selectedCondition,
    required this.sortIndex,
    required this.onCategoryChanged,
    required this.onConditionChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // Category filter
          _FilterChip(
            label: selectedCategory ?? 'Category',
            isActive: selectedCategory != null,
            onTap: () => _showCategorySheet(context),
          ),
          const SizedBox(width: 8),
          // Condition filter
          _FilterChip(
            label: selectedCondition != null
                ? _conditionLabels[selectedCondition!] ?? 'Condition'
                : 'Condition',
            isActive: selectedCondition != null,
            onTap: () => _showConditionSheet(context),
          ),
          const SizedBox(width: 8),
          // Sort
          _FilterChip(
            label: _sortOptions[sortIndex].$3,
            isActive: sortIndex != 0,
            icon: Icons.sort,
            onTap: () => _showSortSheet(context),
          ),
        ],
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _BottomSheet(
        title: 'Category',
        options: const ['All', ...AppConstants.categories],
        selected: selectedCategory ?? 'All',
        onSelect: (v) => onCategoryChanged(v == 'All' ? null : v),
      ),
    );
  }

  void _showConditionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _BottomSheet(
        title: 'Condition',
        options: const ['Any', ..._conditions],
        optionLabels: const {'Any': 'Any', ..._conditionLabels},
        selected: selectedCondition ?? 'Any',
        onSelect: (v) => onConditionChanged(v == 'Any' ? null : v),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _BottomSheet(
        title: 'Sort by',
        options: List.generate(_sortOptions.length, (i) => i.toString()),
        optionLabels: {
          for (var i = 0; i < _sortOptions.length; i++) i.toString(): _sortOptions[i].$3
        },
        selected: sortIndex.toString(),
        onSelect: (v) => onSortChanged(int.parse(v)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({required this.label, required this.isActive, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.ember : AppColors.cream,
          borderRadius: AppRadius.sm,
          border: Border.all(color: isActive ? AppColors.ember : AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isActive ? AppColors.warmWhite : AppColors.charcoal),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isActive ? AppColors.warmWhite : AppColors.charcoal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isActive ? AppColors.warmWhite : AppColors.charcoal,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final Map<String, String>? optionLabels;
  final String selected;
  final ValueChanged<String> onSelect;

  const _BottomSheet({
    required this.title,
    required this.options,
    this.optionLabels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title, style: AppTypography.headlineSmall),
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final label = optionLabels?[opt] ?? opt;
            final isSelected = opt == selected;
            return ListTile(
              dense: true,
              title: Text(label, style: AppTypography.bodyMedium),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.ember, size: 18)
                  : null,
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
