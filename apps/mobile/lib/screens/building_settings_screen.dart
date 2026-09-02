import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/fee_settings_card.dart';
import 'whatsapp_connect_screen.dart';

/// Vaad hub for building-wide configuration: fees, join policy, WhatsApp,
/// and (later) entrance codes, cleaning schedules, etc.
class BuildingSettingsScreen extends StatelessWidget {
  const BuildingSettingsScreen({super.key});

  Future<void> _shareApp(BuildContext context) async {
    final l10n = context.l10n;
    final link = await ApiClient.appDownloadLink();
    final message = l10n.shareAppMessage(link);
    await launchUrl(
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionController>();
    final building = session.building;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.buildingSettings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: building == null
          ? Center(child: Text(l10n.noBuildingFound))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (building.name.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      '${building.name} · ${building.address}, ${building.city}',
                      style: const TextStyle(
                        color: DiraColors.inkSoft,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                _SettingsSection(
                  title: l10n.updateVaadFee,
                  child: FeeSettingsCard(building: building),
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  title: l10n.joinPolicySection,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.requireDocsTitle),
                    subtitle: Text(
                      l10n.requireDocsSubtitle,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    value: building.requireJoinDocs,
                    activeTrackColor: DiraColors.sageDark,
                    onChanged: (v) async {
                      try {
                        await api.patch('/api/buildings/${building.id}', {
                          'requireJoinDocs': v,
                        });
                        await session.refreshMe();
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  title: l10n.whatsappConnect,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF25D366),
                      child: Icon(Icons.chat_rounded, color: Colors.white),
                    ),
                    title: Text(l10n.whatsappConnect),
                    subtitle: Text(l10n.whatsappConnectBody),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WhatsAppConnectScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  title: l10n.shareAppSection,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF25D366),
                      child: Icon(Icons.ios_share_rounded, color: Colors.white),
                    ),
                    title: Text(l10n.shareAppTitle),
                    subtitle: Text(l10n.shareAppSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _shareApp(context),
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  title: l10n.comingSoonSection,
                  child: Column(
                    children: [
                      _ComingSoonRow(
                        icon: Icons.lock_outline_rounded,
                        label: l10n.entranceCodesSoon,
                      ),
                      _ComingSoonRow(
                        icon: Icons.delete_outline_rounded,
                        label: l10n.garbageScheduleSoon,
                      ),
                      _ComingSoonRow(
                        icon: Icons.cleaning_services_outlined,
                        label: l10n.cleaningScheduleSoon,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: DiraColors.brickDark,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ComingSoonRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ComingSoonRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DiraColors.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: DiraColors.inkSoft),
            ),
          ),
          Text(
            context.l10n.comingSoon,
            style: const TextStyle(fontSize: 11.5, color: DiraColors.goldDark),
          ),
        ],
      ),
    );
  }
}
