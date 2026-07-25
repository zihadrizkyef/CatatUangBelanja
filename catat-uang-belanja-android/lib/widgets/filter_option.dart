import 'package:flutter/foundation.dart';

/// One selectable row inside a [FilterDropdown]'s expanded panel — used for
/// Semua Transaksi's wallet and category filters.
typedef FilterOption = ({String id, String label, String? iconAsset, bool selected, VoidCallback onSelect});
