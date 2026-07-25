import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_theme.dart';
import 'filter_dropdown_panel.dart';
import 'filter_option.dart';

/// A collapsed filter button ("👛 Semua Dompet ▾") that expands into a
/// searchable option list floated in the app's [Overlay] — used by Semua
/// Transaksi for its wallet and category filters. Stateful only to manage
/// the [OverlayEntry] lifecycle (a rendering/positioning concern); open/
/// closed state and option data still come entirely from the caller via
/// [isOpen]/[options], so this stays presentation-only.
class FilterDropdown extends StatefulWidget {
  const FilterDropdown({
    super.key,
    required this.prefixEmoji,
    required this.label,
    required this.isOpen,
    required this.onToggle,
    required this.searchController,
    required this.searchHint,
    required this.options,
    required this.noMatchesText,
    required this.palette,
  });

  final String prefixEmoji;
  final String label;
  final bool isOpen;
  final VoidCallback onToggle;
  final TextEditingController searchController;
  final String searchHint;

  /// Already filtered by the container based on [searchController]'s text.
  final List<FilterOption> options;
  final String noMatchesText;
  final AppPalette palette;

  @override
  State<FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<FilterDropdown> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void didUpdateWidget(covariant FilterDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Overlay.insert()/markNeedsBuild() can't run synchronously here — this
    // runs mid-build, and the Overlay may already be building this frame.
    // Deferring to a post-frame callback avoids "setState() or
    // markNeedsBuild() called during build" for both cases.
    if (widget.isOpen != oldWidget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.isOpen ? _showOverlay() : _hideOverlay();
      });
    } else if (widget.isOpen) {
      // Same open/closed state, but options/search text may have changed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _hideOverlay();
    final renderBox = context.findRenderObject() as RenderBox;
    _overlayEntry = OverlayEntry(
      // Positioned (rather than a bare CompositedTransformFollower) is
      // required here: an unpositioned OverlayEntry child is stretched to
      // fill the entire Overlay (the whole screen) by its internal Stack.
      // left/top with no width/height/right/bottom lets the child size
      // itself intrinsically instead — the actual on-screen position still
      // comes from the follower's link + offset, not from these coordinates.
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 6),
          child: SizedBox(
            width: renderBox.size.width,
            child: Material(
              color: Colors.transparent,
              child: FilterDropdownPanel(
                searchController: widget.searchController,
                searchHint: widget.searchHint,
                options: widget.options,
                noMatchesText: widget.noMatchesText,
                palette: widget.palette,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onToggle,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.prefixEmoji} ${widget.label}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary),
                  ),
                ),
                Icon(widget.isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: palette.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'FilterDropdown · tertutup')
Widget previewFilterDropdownClosed() {
  return FilterDropdown(
    prefixEmoji: '👛',
    label: 'Semua Dompet',
    isOpen: false,
    onToggle: () {},
    searchController: TextEditingController(),
    searchHint: 'Cari dompet…',
    options: const [],
    noMatchesText: 'Dompet tidak ditemukan',
    palette: AppPalette.light,
  );
}

@Preview(name: 'FilterDropdown · terbuka')
Widget previewFilterDropdownOpen() {
  return FilterDropdown(
    prefixEmoji: '🏷️',
    label: 'Belanja Dapur',
    isOpen: true,
    onToggle: () {},
    searchController: TextEditingController(),
    searchHint: 'Cari kategori…',
    options: [
      (id: '', label: 'Semua Kategori', iconAsset: null, selected: false, onSelect: () {}),
      (id: 'k1', label: 'Belanja Dapur', iconAsset: 'assets/icons/openmoji/shopping_trolley.svg', selected: true, onSelect: () {}),
      (id: 'k2', label: 'Jajan Anak', iconAsset: 'assets/icons/openmoji/lollipop.svg', selected: false, onSelect: () {}),
    ],
    noMatchesText: 'Kategori tidak ditemukan',
    palette: AppPalette.light,
  );
}
