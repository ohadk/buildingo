import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/announcement_categories.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Full list of building-board messages (including older ones filtered
/// out of the home carousel).
class BoardMessagesScreen extends StatelessWidget {
  final List<Announcement> announcements;

  const BoardMessagesScreen({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final sorted = List<Announcement>.from(announcements)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.allBoardMessages,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: sorted.isEmpty
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
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = sorted[i];
                return _AnnouncementTile(
                  announcement: a,
                  locale: locale,
                );
              },
            ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final String locale;

  const _AnnouncementTile({
    required this.announcement,
    required this.locale,
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

    return Material(
      color: DiraColors.creamCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAnnouncementDetail(context, announcement),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: DiraColors.inkSoft,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                event == null
                    ? l10n.boardPublishedOn(published)
                    : '${l10n.boardPublishedOn(published)} · $event',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: DiraColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAnnouncementDetail(
  BuildContext context,
  Announcement announcement,
) {
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

  return showModalBottomSheet<void>(
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
