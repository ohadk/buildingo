import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/phone_field.dart';

/// The signed-in user's own profile: photo, editable name/email, and
/// read-only account details (phone, role, building, apartment).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user!;
    _name = TextEditingController(text: user.fullName);
    _email = TextEditingController(text: user.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final picked = await pickAttachments(context);
    if (picked.isEmpty || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      await context.read<SessionController>().uploadAvatar(
        picked.first.bytes,
        picked.first.name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<SessionController>().updateProfile(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileUpdated)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionController>();
    final user = session.user!;
    final building = session.building;
    final apartment = session.apartment;
    final initial = user.fullName.isEmpty
        ? '?'
        : user.fullName.characters.first.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Photo ────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: DiraColors.terracottaSoft,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: _uploadingPhoto
                      ? const CircularProgressIndicator(
                          color: DiraColors.brickDark,
                        )
                      : user.avatarUrl == null
                      ? Text(
                          initial,
                          style: heading(
                            fontSize: 40,
                            color: DiraColors.brickDark,
                          ),
                        )
                      : null,
                ),
                PositionedDirectional(
                  bottom: 0,
                  end: 0,
                  child: Material(
                    color: DiraColors.brick,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploadingPhoto ? null : _changePhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _uploadingPhoto ? null : _changePhoto,
              child: Text(l10n.changePhoto),
            ),
          ),
          const SizedBox(height: 16),

          // ── Editable details ─────────────────────────────────────
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.fullName),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: l10n.emailOptional),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.saving : l10n.save),
            ),
          ),
          const SizedBox(height: 28),

          // ── Read-only account info ───────────────────────────────
          Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: l10n.phoneNumber,
                  value: PhoneField.formatDisplay(user.phoneNumber),
                  ltrValue: true,
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  value: user.isVaad ? l10n.vaadBadge : l10n.resident,
                ),
                if (building != null) ...[
                  const Divider(height: 1, indent: 56),
                  _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: building.city,
                    value: building.name,
                  ),
                ],
                if (apartment != null) ...[
                  const Divider(height: 1, indent: 56),
                  _InfoRow(
                    icon: Icons.door_front_door_outlined,
                    value: l10n.apartmentAndFloor(
                      '${apartment.apartmentNumber}',
                      '${apartment.floor}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final bool ltrValue;

  const _InfoRow({
    required this.icon,
    required this.value,
    this.label,
    this.ltrValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: DiraColors.sagePale,
        child: Icon(icon, size: 20, color: DiraColors.sageDark),
      ),
      title: Text(
        value,
        textDirection: ltrValue ? TextDirection.ltr : null,
        textAlign: TextAlign.start,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: label == null
          ? null
          : Text(
              label!,
              style: const TextStyle(color: DiraColors.inkSoft, fontSize: 12.5),
            ),
    );
  }
}
