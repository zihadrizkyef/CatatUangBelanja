enum TransactionType { income, expense, transfer }

enum SyncStatus { synced, pending, failed }

/// Not part of the original doc 5.2 model — added for the Bank Jago email
/// sync (integrasi-jago). Server-set only; the app never constructs a
/// [Transaction] with [TransactionSource.emailSync] itself, it only reads
/// one back via [Transaction.fromMap] after a pull.
enum TransactionSource { manual, emailSync }

/// See doc 5.2. Transfers (doc 4.3) reuse this single row: [walletId] is the
/// source wallet, [targetWalletId] is the destination — see
/// FinanceRepository.balanceOf for how both sides are applied.
class Transaction {
  final String id;
  final TransactionType type;
  final int amount;
  final String walletId;
  final String? targetWalletId;
  final String? categoryId;
  final DateTime dateTime;
  final String? note;
  final String? attachmentUrl;
  final String? recurringId;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TransactionSource source;
  // Gmail message id for source == emailSync, otherwise null — server-set
  // dedupe key, never read/written by app code beyond round-tripping it.
  final String? externalId;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.walletId,
    this.targetWalletId,
    this.categoryId,
    required this.dateTime,
    this.note,
    this.attachmentUrl,
    this.recurringId,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    required this.updatedAt,
    this.source = TransactionSource.manual,
    this.externalId,
  });

  Transaction copyWith({
    TransactionType? type,
    int? amount,
    String? walletId,
    String? targetWalletId,
    String? categoryId,
    DateTime? dateTime,
    String? note,
    // `note ?? this.note` alone can't express "clear the note" since passing
    // null is indistinguishable from not passing it — this flag lets a
    // caller (see TransactionSheet's edit mode) explicitly clear it.
    bool clearNote = false,
    String? attachmentUrl,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      targetWalletId: targetWalletId ?? this.targetWalletId,
      categoryId: categoryId ?? this.categoryId,
      dateTime: dateTime ?? this.dateTime,
      note: clearNote ? null : (note ?? this.note),
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      recurringId: recurringId,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Not editable via copyWith — same treatment as recurringId above:
      // server-set provenance the UI can read but never reassign.
      source: source,
      externalId: externalId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'wallet_id': walletId,
      'target_wallet_id': targetWalletId,
      'category_id': categoryId,
      'date_time': dateTime.toIso8601String(),
      'note': note,
      'attachment_url': attachmentUrl,
      'recurring_id': recurringId,
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'source': source.name,
      'external_id': externalId,
    };
  }

  factory Transaction.fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      amount: map['amount'] as int,
      walletId: map['wallet_id'] as String,
      targetWalletId: map['target_wallet_id'] as String?,
      categoryId: map['category_id'] as String?,
      dateTime: DateTime.parse(map['date_time'] as String),
      note: map['note'] as String?,
      attachmentUrl: map['attachment_url'] as String?,
      recurringId: map['recurring_id'] as String?,
      isDeleted: (map['is_deleted'] as int) == 1,
      syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      // Older rows (pre-integrasi-jago) have no 'source' column value cached
      // anywhere but the DB default — fall back to manual, matching that
      // column's SQLite `DEFAULT 'manual'` (see AppDatabase._onUpgrade).
      source: TransactionSource.values.byName(map['source'] as String? ?? 'manual'),
      externalId: map['external_id'] as String?,
    );
  }
}
