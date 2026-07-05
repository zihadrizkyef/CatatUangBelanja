import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import '../theme/app_theme.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

class DompetScreen extends StatelessWidget {
  const DompetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final wallets = repository.wallets.where((w) => !w.isArchived).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dompet', style: AppTheme.heading(fontSize: 24)),
            const SizedBox(height: 16),
            Expanded(
              child: wallets.isEmpty
                  ? Center(child: Text('Belum ada dompet', style: AppTheme.body()))
                  : ListView.builder(
                      itemCount: wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = wallets[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Color(int.parse(wallet.color.replaceFirst('#', '0xFF'))),
                              child: Text(
                                wallet.name.isNotEmpty ? wallet.name[0].toUpperCase() : '?',
                              ),
                            ),
                            title: Text(wallet.name, style: AppTheme.body(fontWeight: FontWeight.bold)),
                            trailing: Text(_currency.format(repository.balanceOf(wallet.id))),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
