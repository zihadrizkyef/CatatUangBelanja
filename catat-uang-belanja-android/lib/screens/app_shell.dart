import 'package:flutter/material.dart';

import 'beranda_screen.dart';
import 'dompet_screen.dart';
import 'pengaturan_screen.dart';
import 'rangkuman_screen.dart';
import 'transaction_sheet.dart';

/// Hosts the four bottom-nav tabs (Beranda/Dompet/Rangkuman/Pengaturan) in an
/// IndexedStack so tab state survives switching, plus the "+" FAB that opens
/// [TransactionSheet].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = [
    BerandaScreen(),
    DompetScreen(),
    RangkumanScreen(),
    PengaturanScreen(),
  ];

  void _openTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const TransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _openTransactionSheet,
        tooltip: 'Catat transaksi',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Dompet'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Rangkuman'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
        ],
      ),
    );
  }
}
