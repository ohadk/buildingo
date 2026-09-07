import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/announcement_categories.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Create or edit a building-board announcement (Vaad).
class AnnouncementComposerSheet extends StatefulWidget {
  final Announcement? initial;

  const AnnouncementComposerSheet({super.key, this.initial});

  @override
  State<AnnouncementComposerSheet> createState() =>
      _AnnouncementComposerSheetState();
}

class _AnnouncementComposerSheetState extends State<AnnouncementComposerSheet> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late AnnouncementCategory _category;
  DateTime? _eventDate;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.initial != null;

  bool get _valid =>
      _title.text.trim().length >= 2 && _body.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _title = TextEditingController(text: a?.title ?? '');
    _body = TextEditingController(text: a?.body ?? '');
    _category = a?.category != null && a!.category!.isNotEmpty
        ? AnnouncementCategory.byId(a.category)
        : AnnouncementCategory.update;
    _eventDate = a?.eventDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  InputDecoration _boxDecoration(String label) => InputDecoration(
    labelText: label,
    alignLabelWithHint: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: DiraColors.ink.withValues(alpha: 0.14)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: DiraColors.brick, width: 1.5),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final payload = {
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'category': _category.id,
        'eventDate': _eventDate == null ? null : fmt.format(_eventDate!),
      };
      if (_isEdit) {
        await api.patch('/api/announcements/${widget.initial!.id}', payload);
      } else {
        await api.post('/api/announcements', {
          'title': payload['title'],
          'body': payload['body'],
          'category': payload['category'],
          if (_eventDate != null) 'eventDate': payload['eventDate'],
        });
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DiraColors.ink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: DiraColors.goldLight,
                  child: Icon(
                    Icons.campaign_rounded,
                    color: DiraColors.goldDark,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit
                            ? l10n.editBoardMessage
                            : l10n.messageToBuilding,
                        style: heading(fontSize: 19),
                      ),
                      Text(
                        l10n.announcementSubtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: DiraColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              l10n.announcementCategoryLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in AnnouncementCategory.all)
                  ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 17,
                      color: _category.id == cat.id
                          ? cat.color
                          : DiraColors.inkSoft,
                    ),
                    label: Text(cat.label(l10n)),
                    selected: _category.id == cat.id,
                    selectedColor: cat.color.withValues(alpha: 0.18),
                    onSelected: (v) {
                      if (v) setState(() => _category = cat);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.next,
              decoration: _boxDecoration(l10n.titleLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              onChanged: (_) => setState(() {}),
              maxLines: 5,
              minLines: 4,
              decoration: _boxDecoration(l10n.announcementBody),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.event_outlined,
                color: DiraColors.goldDark,
              ),
              title: Text(l10n.announcementDateOptional),
              subtitle: Text(
                _eventDate == null
                    ? l10n.announcementDateHint
                    : DateFormat(
                        'EEEE, d MMMM yyyy',
                        locale,
                      ).format(_eventDate!),
              ),
              trailing: _eventDate == null
                  ? const Icon(Icons.add)
                  : IconButton(
                      tooltip: l10n.clear,
                      onPressed: () => setState(() => _eventDate = null),
                      icon: const Icon(Icons.close),
                    ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy || !_valid ? null : _save,
              icon: Icon(
                _isEdit ? Icons.check_rounded : Icons.send_rounded,
                size: 18,
              ),
              label: Text(
                _busy
                    ? l10n.pleaseWait
                    : (_isEdit ? l10n.save : l10n.publishAnnouncement),
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
      ),
    );
  }
}

Future<bool?> showAnnouncementComposer(
  BuildContext context, {
  Announcement? initial,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DiraColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AnnouncementComposerSheet(initial: initial),
  );
}
