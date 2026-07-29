import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import '../utils/snackbar.dart';
import 'profile_edit_sheet_view.dart';

/// Add/edit bottom sheet for the local profile (name + avatar) shown on
/// Pengaturan's profile card. Works fully offline — Phase 3 adds best-effort
/// sync to a backend account on top of this. Reads [FinanceRepository] and
/// wires up the sheet's [Navigator] dismissal; hands the rest to
/// [ProfileEditSheetView].
class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({super.key});

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _nameController;
  late String _avatarIconValue;

  @override
  void initState() {
    super.initState();
    final repository = context.read<FinanceRepository>();
    _nameController = TextEditingController(text: repository.profileName);
    _avatarIconValue = repository.profileAvatarIconValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnackBarMessage(context, 'Isi nama kamu dulu ya, Bun');
      return;
    }

    final repository = context.read<FinanceRepository>();
    await repository.updateProfile(name: name, avatarIconValue: _avatarIconValue);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileEditSheetView(
      nameController: _nameController,
      selectedAvatarIconValue: _avatarIconValue,
      onSelectAvatar: (value) => setState(() => _avatarIconValue = value),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
