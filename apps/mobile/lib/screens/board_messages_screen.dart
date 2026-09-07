import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/announcement_categories.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/announcement_composer_sheet.dart';

/// Result of opening an announcement detail sheet (for parent refresh).
enum AnnouncementDetailResult { edited, deleted }

/// Full list of building-board messages (including older ones filtered
/// out of the home carousel).
class BoardMessagesScreen extends StatefulWidget {
  final List<Announcement> announcements;

  const BoardMessagesScreen({super.key, required this.announcements});

  @override
  State<BoardMessagesScreen> createState() => _BoardMessagesScreenState();
}

class _BoardMessagesScreenState extends State<BoardMessagesScreen> {
  late List<Announcement> _items;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _items = List<Announcement>.from(widget.announcements)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _openDetail(Announcement a) async {
    final result = await showAnnouncementDetail(context, a);
    if (!mounted || result == null) return;
    _changed = true;
    if (result == AnnouncementDetailResult.deleted) {
      setState(() => _items.removeWhere((x) => x.id == a.id));
      return;
    }
    // Reload list so edited fields show.
    try {
      final data = await api.get('/api/announcements');
      if (!mounted) return;
      setState(() {
        _items = ((data['announcements'] ?? []) as List)
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
      });
    } catch (_) {
      /* keep existing list */
    }
  }

  Future<void> _editFromRow(Announcement a) async {
    final saved = await showAnnouncementComposer(context, initial: a);
    if (saved != true || !mounted) return;
    _changed = true;
    try {
      final data = await api.get('/api/announcements');
      if (!mounted) return;
      setState(() {
        _items = ((data['announcements'] ?? []) as List)
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
      });
    } catch (_) {
      /* keep existing list */
    }
  }

  Future<bool> _confirmDeleteAnnouncement(Announcement a) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.deleteBoardMessage),
        content: Text(l10n.deleteBoardMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: TextButton.styleFrom(foregroundColor: DiraColors.brickDark),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return false;
    try {
      await api.delete('/api/announcements/${a.id}');
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return false;
    }
  }

  void _onAnnouncementDeleted(Announcement a) {
    _changed = true;
    setState(() => _items.removeWhere((x) => x.id == a.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.allBoardMessages,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: _items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.nothingOnBoard,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DiraColors.inkSoft),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final a = _items[i];
                  return _AnnouncementTile(
                    announcement: a,
                    locale: locale,
                    canManage: isVaad,
                    onTap: () => _openDetail(a),
                    onEdit: isVaad ? () => _editFromRow(a) : null,
                    onDelete:
                        isVaad ? () => _confirmDeleteAnnouncement(a) : null,
                    onDeleted:
                        isVaad ? () => _onAnnouncementDeleted(a) : null,
                  );
                },
              ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final String locale;
  final VoidCallback onTap;
  final bool canManage;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDelete;
  final VoidCallback? onDeleted;

  const _AnnouncementTile({
    required this.announcement,
    required this.locale,
    required this.onTap,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cat = announcement.category != null &&
            announcement.category!.isNotEmpty
        ? AnnouncementCategory.byId(announcement.category)
        : AnnouncementCategory.inferFromTitle(announcement.title);
    final published = DateFormat(
      'd MMM yyyy',
      locale,
    ).format(announcement.createdAt.toLocal());
    final event = announcement.eventDate == null
        ? null
        : DateFormat(
            'd MMM yyyy',
            locale,
          ).format(announcement.eventDate!.toLocal());

    Future<void> deleteViaIcon() async {
      final deleted = await onDelete?.call() ?? false;
      if (deleted) onDeleted?.call();
    }

    final tile = Material(
      color: DiraColors.creamCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DiraColors.creamDeep),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cat.icon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.label(l10n),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: cat.color,
                          ),
                        ),
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage) ...[
                    IconButton(
                      tooltip: l10n.edit,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: l10n.delete,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: onDelete == null ? null : deleteViaIcon,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: DiraColors.brickDark,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text(
                  announcement.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DiraColors.inkSoft,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text(
                  event == null
                      ? l10n.boardPublishedOn(published)
                      : '${l10n.boardPublishedOn(published)} · $event',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: DiraColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!canManage || onDelete == null) return tile;

    return Dismissible(
      key: ValueKey(announcement.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete!(),
      onDismissed: (_) => onDeleted?.call(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: DiraColors.brick,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      child: tile,
    );
  }
}

Future<AnnouncementDetailResult?> showAnnouncementDetail(
  BuildContext context,
  Announcement announcement,
) {
  final isVaad = context.read<SessionController>().user?.isVaad ?? false;
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).languageCode;
  final cat = announcement.category != null && announcement.category!.isNotEmpty
      ? AnnouncementCategory.byId(announcement.category)
      : AnnouncementCategory.inferFromTitle(announcement.title);
  final published = DateFormat(
    'd MMM yyyy',
    locale,
  ).format(announcement.createdAt.toLocal());
  final event = announcement.eventDate == null
      ? null
      : DateFormat(
          'd MMM yyyy',
          locale,
        ).format(announcement.eventDate!.toLocal());

  return showModalBottomSheet<AnnouncementDetailResult>(
    context: context,
    backgroundColor: DiraColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat.icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.label(l10n),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: cat.color,
                        ),
                      ),
                      Text(announcement.title, style: heading(fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.boardPublishedOn(published),
              style: const TextStyle(
                fontSize: 12.5,
                color: DiraColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (event != null) ...[
              const SizedBox(height: 4),
              Text(
                event,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: DiraColors.inkSoft,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              announcement.body,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
            if (isVaad) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final saved = await showAnnouncementComposer(
                          ctx,
                          initial: announcement,
                        );
                        if (saved == true && ctx.mounted) {
                          Navigator.pop(
                            ctx,
                            AnnouncementDetailResult.edited,
                          );
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.edit),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DiraColors.brickDark,
                        side: const BorderSide(color: DiraColors.brick),
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: Text(l10n.deleteBoardMessage),
                            content: Text(l10n.deleteBoardMessageConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: DiraColors.brickDark,
                                ),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !ctx.mounted) return;
                        try {
                          await api.delete(
                            '/api/announcements/${announcement.id}',
                          );
                          if (ctx.mounted) {
                            Navigator.pop(
                              ctx,
                              AnnouncementDetailResult.deleted,
                            );
                          }
                        } on ApiException catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Home board: event dated this calendar week, or published in the last 7 days.
bool isAnnouncementOnHomeBoard(Announcement a, {DateTime? now, String locale = 'en'}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);

  if (a.eventDate != null) {
    final event = DateTime(
      a.eventDate!.year,
      a.eventDate!.month,
      a.eventDate!.day,
    );
    final weekStart = _weekStart(today, locale);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return !event.isBefore(weekStart) && !event.isAfter(weekEnd);
  }

  final published = a.createdAt.toLocal();
  final cutoff = n.subtract(const Duration(days: 7));
  return !published.isBefore(cutoff);
}

DateTime _weekStart(DateTime day, String locale) {
  final d = DateTime(day.year, day.month, day.day);
  if (locale == 'he') {
    // Sunday-start week (common in Israel).
    final daysFromSunday = d.weekday % 7;
    return d.subtract(Duration(days: daysFromSunday));
  }
  return d.subtract(Duration(days: d.weekday - 1));
}
