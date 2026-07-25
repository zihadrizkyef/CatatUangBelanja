/// "Hari ini" / "Kemarin" / "N hari lalu" relative-date label for a
/// transaction's [dateTime], shared by every screen that lists transactions
/// (Beranda, Dompet detail, Semua Transaksi).
String relativeDateLabel(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return '$diff hari lalu';
}
