import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/user_preferences.dart';
import '../l10n/l10n.dart';
import '../widgets/app_version_label.dart';

/// Personal settings: notification preferences + privacy explanation.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const privacyPolicyUrl = 'https://buildingo.com/privacy';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserPreferences? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await UserPreferences.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(SettingsScreen.privacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = _prefs;

    return Scaffold(
      backgroundColor: DiraColors.cream,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: _loading || prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Text(
                  l10n.settingsNotificationsSection,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: DiraColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DiraColors.sagePale,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DiraColors.sageLight),
                  ),
                  child: Text(
                    l10n.settingsNotificationsNote,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: DiraColors.inkSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _PrefCard(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsNotifyTickets),
                      subtitle: Text(
                        l10n.settingsNotifyTicketsHint,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      value: prefs.notifyTickets,
                      activeTrackColor: DiraColors.sageDark,
                      onChanged: (v) async {
                        await prefs.setNotifyTickets(v);
                        setState(() {});
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsNotifyAnnouncements),
                      subtitle: Text(
                        l10n.settingsNotifyAnnouncementsHint,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      value: prefs.notifyAnnouncements,
                      activeTrackColor: DiraColors.sageDark,
                      onChanged: (v) async {
                        await prefs.setNotifyAnnouncements(v);
                        setState(() {});
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsNotifyPayments),
                      subtitle: Text(
                        l10n.settingsNotifyPaymentsHint,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      value: prefs.notifyPayments,
                      activeTrackColor: DiraColors.sageDark,
                      onChanged: (v) async {
                        await prefs.setNotifyPayments(v);
                        setState(() {});
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsNotifyMessages),
                      subtitle: Text(
                        l10n.settingsNotifyMessagesHint,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      value: prefs.notifyMessages,
                      activeTrackColor: DiraColors.sageDark,
                      onChanged: (v) async {
                        await prefs.setNotifyMessages(v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.settingsPrivacySection,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: DiraColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _PrefCard(
                  children: [
                    Text(
                      l10n.settingsPrivacyBody,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: DiraColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.settingsPrivacyBullets,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openPrivacyPolicy,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(l10n.settingsPrivacyPolicyLink),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const AppVersionLabel(),
              ],
            ),
    );
  }
}

class _PrefCard extends StatelessWidget {
  final List<Widget> children;

  const _PrefCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
