import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Completes the tenant profile after the invite was matched during
/// token exchange: full name, occupants, optional lease upload.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _inviteController = TextEditingController();
  int _occupants = 1;
  String? _leaseFileName;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Users arriving via a join request / self-serve already gave a name.
    _nameController.text = context.read<SessionController>().user?.fullName ?? '';
  }

  Future<void> _pickLease() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = result.firstOrNull;
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      await api.uploadFile(
        '/api/onboarding/lease',
        bytes: bytes,
        filename: file.name,
      );
      setState(() => _leaseFileName = file.name);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final session = context.read<SessionController>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // A user signing in without a phone-matched invite can paste the
      // invite code they received by SMS.
      if (session.user?.apartmentId == null &&
          _inviteController.text.trim().isNotEmpty) {
        await session.bootstrap(inviteCode: _inviteController.text.trim());
      }
      await session.completeOnboarding(
        fullName: _nameController.text.trim(),
        numOccupants: _occupants,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final hasApartment = session.user?.apartmentId != null;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.completeProfile),
        actions: [
          TextButton(
            onPressed: () => session.signOut(),
            child: Text(l10n.signOut),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.building != null)
              Card(
                color: DiraColors.sageLight,
                child: ListTile(
                  leading: const Icon(
                    Icons.apartment,
                    color: DiraColors.sageDark,
                  ),
                  title: Text(session.building!.name),
                  subtitle: Text(
                    l10n.apartmentAndFloor(
                      '${session.apartment?.apartmentNumber ?? '—'}',
                      '${session.apartment?.floor ?? '—'}',
                    ),
                  ),
                ),
              ),
            if (!hasApartment) ...[
              const SizedBox(height: 16),
              Text(
                l10n.noInviteFound,
                style: const TextStyle(color: DiraColors.inkSoft),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _inviteController,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.inviteCode),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.fullName),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(l10n.numOccupants)),
                IconButton(
                  onPressed: _occupants > 1
                      ? () => setState(() => _occupants--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_occupants',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _occupants++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy || !hasApartment ? null : _pickLease,
              icon: const Icon(Icons.upload_file),
              label: Text(_leaseFileName ?? l10n.uploadLease),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy || _nameController.text.trim().length < 2
                  ? null
                  : _submit,
              child: Text(_busy ? l10n.saving : l10n.enterMyBuilding),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: DiraColors.brick),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
