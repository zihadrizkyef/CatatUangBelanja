import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

String _syncLabel(SyncState state) => switch (state) {
      SyncState.idle => 'Tersinkron',
      SyncState.syncing => 'Menyinkron...',
      SyncState.offline => 'Offline',
      SyncState.error => 'Gagal sinkron',
    };

String _syncIcon(SyncState state) => switch (state) {
      SyncState.idle => AppIcons.syncSynced,
      SyncState.syncing => AppIcons.syncSyncing,
      SyncState.offline => AppIcons.syncOffline,
      SyncState.error => AppIcons.syncOffline,
    };

/// Beranda's accent-colored header: time-of-day greeting plus a tappable
/// sync-status pill (doc 7.2: "tersinkron / menunggu / offline"). Tapping it
/// triggers a manual sync (doc 4.10's pull-to-refresh equivalent).
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.greeting, required this.syncState, required this.onTapSync});

  final String greeting;
  final SyncState syncState;
  final VoidCallback onTapSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 56),
      color: AppColors.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppTheme.heading(fontSize: 21, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  'Yuk catat belanja hari ini',
                  style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTapSync,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OpenMojiIcon(_syncIcon(syncState), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _syncLabel(syncState),
                      style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'HeroBanner - tersinkron')
Widget previewHeroBanner() {
  return HeroBanner(greeting: 'Selamat pagi, Bun 👋', syncState: SyncState.idle, onTapSync: () {});
}

@Preview(name: 'HeroBanner - offline')
Widget previewHeroBannerOffline() {
  return HeroBanner(greeting: 'Selamat pagi, Bun 👋', syncState: SyncState.offline, onTapSync: () {});
}
