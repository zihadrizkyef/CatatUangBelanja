import 'package:flutter/material.dart';

import '../models/category.dart' as models;
import 'category_picker_sheet_view.dart';

/// Opened from [TransactionSheetView]'s category selector button so the
/// amount keypad in the parent sheet stays put on screen regardless of how
/// many categories exist (system + user-added) — the inline strip used to
/// grow past the keypad once a household had more than a couple of custom
/// categories. Lets the user search instead of scanning a long list; pops
/// with the picked [models.Category], or null if dismissed.
class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.accentColor,
  });

  final List<models.Category> categories;
  final models.Category? selectedCategory;
  final Color accentColor;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.categories
        : widget.categories
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();

    return CategoryPickerSheetView(
      searchController: _searchController,
      query: _query,
      categories: filtered,
      selectedCategory: widget.selectedCategory,
      accentColor: widget.accentColor,
      onQueryChanged: (value) => setState(() => _query = value),
      onSelectCategory: (cat) => Navigator.of(context).pop(cat),
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
