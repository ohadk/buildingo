import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'directory_screen.dart';
import 'documents_screen.dart';
import 'home_screen.dart';
import 'maintenance_screen.dart';
import 'payments_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screens = [
      HomeScreen(onNavigate: (i) => setState(() => _index = i)),
      const PaymentsScreen(),
      const MaintenanceScreen(),
      const DirectoryScreen(),
      const DocumentsScreen(),
    ];
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: screens),
      // Centered "new report" FAB docked into the nav bar's notch.
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewTicketScreen()),
        ),
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
              // Middle tab sits under the docked FAB: label only.
              _NavItem(
                icon: null,
                label: l10n.navMaintenance,
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: Icons.people_alt_rounded,
                label: l10n.navResidents,
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
              _NavItem(
                icon: Icons.folder_rounded,
                label: l10n.navDocs,
                selected: _index == 4,
                onTap: () => setState(() => _index = 4),
              ),
            ],
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
