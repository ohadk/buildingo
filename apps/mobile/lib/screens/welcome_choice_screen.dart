import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'create_building_screen.dart';
import 'join_building_screen.dart';

/// First screen for a signed-in user whose phone isn't linked to any
/// building: create one (Vaad), find one (tenant), or enter a code.
/// Also renders the waiting / rejected states of a pending join request.
class WelcomeChoiceScreen extends StatelessWidget {
  const WelcomeChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final request = session.joinRequest;

    if (request?.status == 'pending') return _WaitingView(request: request!);
    if (request?.status == 'rejected') return _RejectedView(request: request!);
    return const _ChoiceView();
  }
}

class _ChoiceView extends StatelessWidget {
  const _ChoiceView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.read<SessionController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton(
                  onPressed: () => session.signOut(),
                  child: Text(
                    l10n.signOut,
                    style: const TextStyle(color: DiraColors.brickDark),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 16),
                    const Icon(
                      Icons.home_work_rounded,
                      size: 56,
                      color: DiraColors.brick,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.howToJoinTitle,
                      textAlign: TextAlign.center,
                      style: heading(fontSize: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.welcomeNoBuilding,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DiraColors.brickDark),
                    ),
                    const SizedBox(height: 28),
                    _ChoiceCard(
                      icon: Icons.apartment_rounded,
                      color: DiraColors.brick,
                      title: l10n.choiceVaadTitle,
                      subtitle: l10n.choiceVaadSubtitle,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateBuildingScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ChoiceCard(
                      icon: Icons.person_search_rounded,
                      color: DiraColors.sage,
                      title: l10n.choiceTenantTitle,
                      subtitle: l10n.choiceTenantSubtitle,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JoinBuildingScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ChoiceCard(
                      icon: Icons.key_rounded,
                      color: DiraColors.gold,
                      title: l10n.choiceCodeTitle,
                      subtitle: l10n.choiceCodeSubtitle,
                      onTap: () => _enterCode(context),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enterCode(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.creamCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CodeSheet(),
    );
  }
}

/// Bottom sheet: enter a code → resolve it → (building code) pick an
/// apartment → join.
class _CodeSheet extends StatefulWidget {
  const _CodeSheet();

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  final _codeController = TextEditingController();
  final _aptController = TextEditingController();
  final _nameController = TextEditingController();
  String? _buildingName;
  String? _kind; // building | invitation
  bool _busy = false;
  String? _error;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await api.get(
        '/api/join?code=${Uri.encodeComponent(_codeController.text.trim())}',
      );
      if (!mounted) return;
      setState(() {
        _kind = res['kind'];
        _buildingName = res['building']?['name'];
      });
      // Personal invitations carry the apartment already — join now.
      if (_kind == 'invitation') await _join();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<SessionController>().joinWithCode(
        _codeController.text.trim(),
        apartmentNumber: int.tryParse(_aptController.text.trim()),
        fullName: _nameController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _buildingFormValid =>
      _nameController.text.trim().length >= 2 &&
      int.tryParse(_aptController.text.trim()) != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.joinCodeTitle, style: heading(fontSize: 20)),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textDirection: TextDirection.ltr,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.codeLabel),
          ),
          if (_kind == 'building' && _buildingName != null) ...[
            const SizedBox(height: 14),
            Card(
              color: DiraColors.sagePale,
              child: ListTile(
                leading: const Icon(
                  Icons.apartment,
                  color: DiraColors.sageDark,
                ),
                title: Text(l10n.joiningBuilding(_buildingName!)),
                subtitle: Text(
                  l10n.joinPendingNote,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.fullName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _aptController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.yourApartmentNumber),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _busy
                ? null
                : _kind == 'building'
                ? (_buildingFormValid ? _join : null)
                : (_codeController.text.trim().length >= 4 ? _check : null),
            child: Text(
              _busy
                  ? l10n.pleaseWait
                  : _kind == 'building'
                  ? l10n.askToJoin
                  : l10n.checkCode,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: DiraColors.brick),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: heading(fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: DiraColors.inkSoft,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: DiraColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  final dynamic request;
  const _WaitingView({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.read<SessionController>();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: DiraColors.goldLight,
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 36,
                  color: DiraColors.goldDark,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.waitingApprovalTitle,
                textAlign: TextAlign.center,
                style: heading(fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.waitingApprovalBody(request.buildingName ?? ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: DiraColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => session.refreshMe(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.checkAgain),
              ),
              TextButton(
                onPressed: () => session.signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectedView extends StatelessWidget {
  final dynamic request;
  const _RejectedView({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.read<SessionController>();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: DiraColors.terracottaSoft,
                child: Icon(
                  Icons.block_rounded,
                  size: 36,
                  color: DiraColors.brick,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.requestRejectedTitle,
                textAlign: TextAlign.center,
                style: heading(fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.requestRejectedBody(request.buildingName ?? ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: DiraColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinBuildingScreen()),
                ),
                child: Text(l10n.searchAnotherBuilding),
              ),
              TextButton(
                onPressed: () => session.signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
