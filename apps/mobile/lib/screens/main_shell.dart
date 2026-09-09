import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/deep_links.dart';
import '../core/push_permission.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/announcement_composer_sheet.dart';
import 'directory_screen.dart';
import 'documents_screen.dart';
import 'home_screen.dart';
import 'maintenance_screen.dart' show NewTicketScreen;
import 'agents_coming_soon_screen.dart';
import 'meetings_screen.dart';
import 'payments_coming_soon_screen.dart';
import 'payments_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  DeepLinkController? _deepLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyDeepLink();
      _maybeRequestPushPermission();
    });
  }

  Future<void> _maybeRequestPushPermission() async {
    if (!mounted) return;
    await PushPermission.ensureRequested(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deep = context.read<DeepLinkController>();
    if (!identical(_deepLinks, deep)) {
      _deepLinks?.removeListener(_applyDeepLink);
      _deepLinks = deep;
      _deepLinks!.addListener(_applyDeepLink);
    }
  }

  @override
  void dispose() {
    _deepLinks?.removeListener(_applyDeepLink);
    super.dispose();
  }

  void _applyDeepLink() {
    final tab = _deepLinks?.takePendingTab();
    if (tab == null || !mounted) return;
    setState(() => _index = tab);
    // Payment reminder links land on a Coming Soon page (in-app pay not live yet).
    if (tab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PaymentsComingSoonScreen(),
          ),
        );
      });
    }
  }

  /// The + button: tenants go straight to a new ticket; the Vaad picks
  /// between an announcement, a ticket, or a resident assembly.
  void _openCreateSheet() {
    final isVaad = context.read<SessionController>().user?.isVaad ?? false;
    if (!isVaad) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NewTicketScreen()),
      );
      return;
    }
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.whatToCreate,
                textAlign: TextAlign.center,
                style: heading(fontSize: 18),
              ),
              const SizedBox(height: 14),
              _CreateOption(
                icon: Icons.campaign_rounded,
                color: DiraColors.gold,
                label: l10n.messageToBuilding,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _composeAnnouncement();
                },
              ),
              _CreateOption(
                icon: Icons.handyman_rounded,
                color: DiraColors.brick,
                label: l10n.reportFault,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewTicketScreen()),
                  );
                },
              ),
              _CreateOption(
                icon: Icons.groups_rounded,
                color: DiraColors.sageDark,
                label: l10n.newAssembly,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MeetingsScreen(openComposer: true),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _composeAnnouncement() async {
    final sent = await showAnnouncementComposer(context);
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.announcementPublished)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The Vaad manages AI vendor agents often enough to earn a tab;
    // their documents vault moves to the home hamburger menu. Tenants
    // keep the documents tab (they have no agents to manage).
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    final screens = [
      HomeScreen(onNavigate: (i) => setState(() => _index = i)),
      const PaymentsScreen(),
      const DirectoryScreen(),
      if (isVaad) const VendorAgentsScreen() else const DocumentsScreen(),
    ];
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: screens),
      // Centered "create" FAB docked into the nav bar's notch.
      floatingActionButton: FloatingActionButton(
        heroTag: 'shell-fab',
        onPressed: _openCreateSheet,
        tooltip: l10n.newReport,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: DiraColors.sageDeep,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        padding: EdgeInsets.zero,
        height: 60 + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.credit_card_rounded,
                label: l10n.navPayments,
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              // Empty slot under the docked FAB.
              const Expanded(child: SizedBox()),
              _NavItem(
                icon: Icons.people_alt_rounded,
                label: l10n.navResidents,
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: isVaad ? Icons.smart_toy_rounded : Icons.folder_rounded,
                label: isVaad ? l10n.navAgents : l10n.navDocs,
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: DiraColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white54;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (icon != null)
              Icon(icon, color: color, size: 24)
            else
              // Space claimed by the FAB riding in the notch above.
              const SizedBox(height: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
