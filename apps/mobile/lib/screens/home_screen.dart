import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/ticket_timeline.dart';
import 'activity_log_screen.dart';
import 'documents_screen.dart';
import 'maintenance_screen.dart';
import 'meetings_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

/// Home tab. Tenants get the design's home: blush hero with the two
/// stat cards (open tickets / next payment), gold announcement banner,
/// "My Tickets" timeline cards and the community board. The Vaad gets
/// a management dashboard: building stats, quick actions, open tickets
/// and the apartments that haven't paid this month.
class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Ticket> _tickets = [];
  List<Announcement> _announcements = [];
  List<Payment> _payments = [];
  List<JoinRequest> _joinRequests = [];
  List<ScheduleOccurrence> _upcomingSchedule = [];
  List<DirectoryEntry> _apartments = [];
  bool _loading = true;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({
      'tickets',
      'ticket_events',
      'announcements',
      'payments',
      'join_requests',
      'schedule_events',
      'meetings',
    }, _load);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final isVaad = context.read<SessionController>().user?.isVaad ?? false;
    final fmt = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();
    final horizon = today.add(const Duration(days: 14));
    try {
      final core = await Future.wait([
        api.get('/api/tickets'),
        api.get('/api/announcements'),
        api.get('/api/payments'),
        if (isVaad) api.get('/api/join-requests'),
        if (isVaad) api.get('/api/directory'),
      ]);
      var schedule = <ScheduleOccurrence>[];
      try {
        final scheduleRes = await api.get(
          '/api/schedule-events?from=${fmt.format(today)}&to=${fmt.format(horizon)}',
        );
        schedule = ((scheduleRes['occurrences'] ?? []) as List)
            .map((e) => ScheduleOccurrence.fromJson(e))
            .toList();
      } on ApiException {
        // Schedule is optional until migration 0018 is applied.
      }
      if (!mounted) return;
      setState(() {
        _tickets = ((core[0]['tickets'] ?? []) as List)
            .map((t) => Ticket.fromJson(t))
            .toList();
        _announcements = ((core[1]['announcements'] ?? []) as List)
            .map((a) => Announcement.fromJson(a))
            .toList();
        _payments = ((core[2]['payments'] ?? []) as List)
            .map((p) => Payment.fromJson(p))
            .toList();
        _upcomingSchedule = schedule;
        _joinRequests = isVaad
            ? ((core[3]['joinRequests'] ?? []) as List)
                  .map((e) => JoinRequest.fromJson(e))
                  .toList()
            : [];
        _apartments = isVaad
            ? ((core[4]['directory'] ?? []) as List)
                .map((e) => DirectoryEntry.fromJson(e))
                .toList()
            : [];
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Ticket> get _openTickets => _tickets
      .where((t) => ['open', 'approved', 'in_progress'].contains(t.status))
      .toList();

  double _expectedMonthlyTotal(Building? building) {
    if (building == null || _apartments.isEmpty) return 0;
    double feeFor(DirectoryEntry a) {
      if (building.feeMethod == 'per_sqm' &&
          building.pricePerSqm != null &&
          a.sizeSqm != null) {
        return a.sizeSqm! * building.pricePerSqm!;
      }
      if (building.feeMethod == 'fixed' && building.fixedMonthlyFee != null) {
        return building.fixedMonthlyFee!;
      }
      return a.monthlyFee;
    }

    return _apartments.fold(0.0, (sum, a) => sum + feeFor(a));
  }

  String? _ticketTrendSub(AppLocalizations l10n) {
    final now = DateTime.now();
    final thisMonth = _tickets
        .where(
          (t) =>
              t.createdAt.year == now.year && t.createdAt.month == now.month,
        )
        .length;
    final last = DateTime(now.year, now.month - 1);
    final lastMonth = _tickets
        .where(
          (t) =>
              t.createdAt.year == last.year && t.createdAt.month == last.month,
        )
        .length;
    if (thisMonth == 0 && lastMonth == 0) return l10n.noTicketsThisMonth;
    if (lastMonth == 0) return l10n.ticketsThisMonth('$thisMonth');
    final pct = ((thisMonth - lastMonth) / lastMonth * 100).round();
    if (pct == 0) return l10n.ticketsSameAsLastMonth;
    if (pct > 0) return l10n.ticketsUpVsLastMonth('$pct');
    return l10n.ticketsDownVsLastMonth('${pct.abs()}');
  }

  Future<void> _decideJoin(JoinRequest request, bool approve) async {
    try {
      await api.patch('/api/join-requests/${request.id}', {
        'action': approve ? 'approve' : 'reject',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? context.l10n.joinApprovedSnack(request.fullName ?? '')
                  : context.l10n.joinRejectedSnack(request.fullName ?? ''),
            ),
          ),
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isVaad = session.user?.isVaad ?? false;

    return RefreshIndicator(
      onRefresh: _load,
      color: DiraColors.brick,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, session, isVaad)),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                isVaad ? _vaadBody(context) : _tenantBody(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTicketsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
    );
  }

  /// All secondary destinations live behind the hamburger, keeping the
  /// hero header to just the greeting + profile.
  void _openMenu(
    BuildContext context,
    SessionController session,
    bool isVaad,
  ) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.account_circle_outlined,
              color: DiraColors.brick,
              label: l10n.myProfile,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _MenuTile(
              icon: Icons.handyman_rounded,
              color: DiraColors.terracotta,
              label: l10n.maintenance,
              onTap: () {
                Navigator.pop(ctx);
                _openTicketsScreen();
              },
            ),
            _MenuTile(
              icon: Icons.calendar_month_rounded,
              color: DiraColors.sage,
              label: l10n.buildingSchedule,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                );
              },
            ),
            _MenuTile(
              icon: Icons.campaign_rounded,
              color: DiraColors.goldDark,
              label: l10n.assemblies,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MeetingsScreen()),
                );
              },
            ),
            if (isVaad) ...[
              _MenuTile(
                icon: Icons.folder_rounded,
                color: DiraColors.gold,
                label: l10n.documents,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DocumentsScreen(),
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.history_rounded,
                color: DiraColors.sageDark,
                label: l10n.activityLog,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ActivityLogScreen(),
                    ),
                  );
                },
              ),
            ],
            _MenuTile(
              icon: Icons.language,
              color: DiraColors.sageDeep,
              label: l10n.language,
              onTap: () {
                Navigator.pop(ctx);
                context.read<LocaleController>().toggle(context);
              },
            ),
            const Divider(height: 16, indent: 20, endIndent: 20),
            _MenuTile(
              icon: Icons.logout,
              color: DiraColors.brickDark,
              label: l10n.signOut,
              onTap: () {
                Navigator.pop(ctx);
                session.signOut();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Hero header: greeting, apartment line, stat cards, gold banner
  // ------------------------------------------------------------------
  Widget _buildHeader(
    BuildContext context,
    SessionController session,
    bool isVaad,
  ) {
    final l10n = context.l10n;
    final user = session.user!;
    final firstName = user.fullName.isEmpty
        ? l10n.neighbor
        : user.fullName.split(' ').first;

    final agentCount = _openTickets
        .where((t) => t.agentStatus != 'idle')
        .length;

    // Tenant: the next unpaid due. Vaad: this month's collection status.
    final now = DateTime.now();
    final unpaid = _payments.where((p) => p.status != 'paid').toList()
      ..sort((a, b) => (a.year * 12 + a.month).compareTo(b.year * 12 + b.month));
    final monthPayments = _payments
        .where((p) => p.month == now.month && p.year == now.year)
        .toList();
    final collected = monthPayments
        .where((p) => p.status == 'paid')
        .fold<double>(0, (s, p) => s + p.amount);
    final expectedTotal = _expectedMonthlyTotal(session.building);
    final totalDue = monthPayments.isNotEmpty
        ? monthPayments.fold<double>(0, (s, p) => s + p.amount)
        : expectedTotal;
    final collectedPct =
        totalDue > 0 ? (collected / totalDue * 100).round() : 0;
    final ticketSub = _ticketTrendSub(l10n);

    return Container(
      decoration: const BoxDecoration(
        gradient: heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.hello(firstName),
                  style: heading(fontSize: 26, color: DiraColors.brickDeep),
                ),
              ),
              IconButton(
                tooltip: l10n.menu,
                onPressed: () => _openMenu(context, session, isVaad),
                icon: const Icon(
                  Icons.menu_rounded,
                  color: DiraColors.brickDark,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isVaad) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DiraColors.sageDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.vaadBadge,
                    style: const TextStyle(fontSize: 10.5, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  session.apartment != null
                      ? l10n.aptFloorAddress(
                          '${session.apartment!.apartmentNumber}',
                          '${session.apartment!.floor}',
                          session.building?.address ?? '',
                        )
                      : (session.building?.name ?? ''),
                  style: const TextStyle(
                    color: DiraColors.brickDark,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatCard(
                  label: l10n.openTicketsStat,
                  value: '${_openTickets.length}',
                  sub: agentCount > 0
                      ? l10n.withAgentCount('$agentCount')
                      : ticketSub,
                  icon: Icons.home_repair_service_rounded,
                  onTap: _openTicketsScreen,
                ),
                const SizedBox(width: 10),
                if (isVaad)
                  _StatCard(
                    label: l10n.collectedThisMonth,
                    value: '₪${collected.toStringAsFixed(0)}',
                    sub: totalDue > 0
                        ? l10n.collectionHeroSub(
                            '₪${totalDue.toStringAsFixed(0)}',
                            '$collectedPct',
                          )
                        : l10n.noApartmentsYet,
                    icon: Icons.credit_card_rounded,
                    accent: collectedPct < 100 && totalDue > 0,
                    onTap: () => widget.onNavigate(1),
                  )
                else
                  _StatCard(
                    label: l10n.nextPayment,
                    value: unpaid.isEmpty
                        ? l10n.allPaid
                        : '₪${unpaid.first.amount.toStringAsFixed(0)}',
                    sub: unpaid.isEmpty ? null : '1.${unpaid.first.month}',
                    icon: Icons.credit_card_rounded,
                    accent: unpaid.isNotEmpty,
                    onTap: () => widget.onNavigate(1),
                  ),
              ],
            ),
          ),
          if (isVaad && _joinRequests.isNotEmpty) ...[
            const SizedBox(height: 10),
            _JoinRequestsBanner(
              requests: _joinRequests,
              onDecide: _decideJoin,
              onSeeAll: () => widget.onNavigate(2),
            ),
          ] else if (_announcements.isNotEmpty) ...[
            const SizedBox(height: 10),
            _GoldBanner(
              kicker: l10n.fromTheVaad,
              title: _announcements.first.title,
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Tenant body: my tickets + community board
  // ------------------------------------------------------------------
  List<Widget> _tenantBody(BuildContext context) {
    final l10n = context.l10n;
    return [
      _SectionHeader(
        title: l10n.myTickets,
        actionLabel: '${l10n.newReport} +',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewTicketScreen()),
        ),
      ),
      const SizedBox(height: 12),
      if (_loading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: DiraColors.brick),
          ),
        )
      else if (_tickets.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.noOpenTickets,
              style: const TextStyle(color: DiraColors.inkSoft),
            ),
          ),
        )
      else
        ..._tickets
            .take(3)
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TicketCard(ticket: t),
              ),
            ),
      const SizedBox(height: 16),
      ..._scheduleSection(context),
      const SizedBox(height: 16),
      ..._boardSection(context),
      const SizedBox(height: 110),
    ];
  }

  // ------------------------------------------------------------------
  // Vaad body: schedule, community board, open tickets
  // ------------------------------------------------------------------
  List<Widget> _vaadBody(BuildContext context) {
    final l10n = context.l10n;
    return [
      ..._scheduleSection(context),
      const SizedBox(height: 16),
      ..._boardSection(context),
      const SizedBox(height: 16),
      _SectionHeader(
        title: l10n.openTicketsStat,
        actionLabel: l10n.viewAll,
        onAction: _openTicketsScreen,
      ),
      const SizedBox(height: 12),
      if (_loading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: DiraColors.brick),
          ),
        )
      else if (_openTickets.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.noOpenTickets,
              style: const TextStyle(color: DiraColors.inkSoft),
            ),
          ),
        )
      else
        ..._openTickets
            .take(3)
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TicketCard(ticket: t, showReporter: true),
              ),
            ),
      const SizedBox(height: 110),
    ];
  }

  // ------------------------------------------------------------------
  // Building schedule preview (shared)
  // ------------------------------------------------------------------
  List<Widget> _scheduleSection(BuildContext context) {
    final l10n = context.l10n;
    void openCalendar() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScheduleScreen()),
      );
    }

    return [
      _SectionHeader(
        title: l10n.comingUp,
        actionLabel: l10n.viewCalendar,
        onAction: openCalendar,
      ),
      const SizedBox(height: 12),
      if (_loading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: DiraColors.brick),
          ),
        )
      else if (_upcomingSchedule.isEmpty)
        Card(
          child: InkWell(
            onTap: openCalendar,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: DiraColors.sage.withValues(alpha: 0.35),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: DiraColors.sageDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.scheduleEmptyTitle,
                      style: const TextStyle(
                        color: DiraColors.inkSoft,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: DiraColors.inkSoft),
                ],
              ),
            ),
          ),
        )
      else
        ..._upcomingSchedule.take(3).map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ScheduleEventTile(occurrence: o),
          ),
        ),
    ];
  }

  // ------------------------------------------------------------------
  // Community board (shared)
  // ------------------------------------------------------------------
  List<Widget> _boardSection(BuildContext context) {
    final l10n = context.l10n;
    return [
      Text(l10n.communityBoard, style: heading(fontSize: 18)),
      const SizedBox(height: 12),
      if (_announcements.isEmpty && !_loading)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.nothingOnBoard,
              style: const TextStyle(color: DiraColors.inkSoft),
            ),
          ),
        )
      else
        ..._announcements
            .take(4)
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DiraColors.terracottaSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.announcementTag,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: DiraColors.brickDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _relativeDate(context, a.createdAt.toLocal()),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: DiraColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (a.body.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            a.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: DiraColors.inkSoft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ];
  }

  String _relativeDate(BuildContext context, DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return context.l10n.dateToday;
    if (days == 1) return context.l10n.dateYesterday;
    return context.l10n.daysAgo('$days');
  }
}

/// Row in the hamburger bottom-sheet menu.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.13),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
    );
  }
}

/// White KPI card inside the blush hero, per the design mockup.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final bool accent;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    this.sub,
    required this.icon,
    this.accent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: DiraColors.creamCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142B261F),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: DiraColors.inkSoft,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: accent ? DiraColors.brick : DiraColors.sageDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: heading(
                        fontSize: 22,
                        color: accent ? DiraColors.brick : DiraColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(
                  sub!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: DiraColors.inkSoft,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title with an optional trailing text action, e.g.
/// "הקריאות שלי                    + דיווח חדש".
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: heading(fontSize: 18)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DiraColors.brickDark,
              ),
            ),
          ),
      ],
    );
  }
}

/// Gold hero strip for pending join requests: each row shows the
/// requester's name + apartment with instant approve/reject buttons.
/// Tapping a row opens the residents tab for the full details.
class _JoinRequestsBanner extends StatelessWidget {
  final List<JoinRequest> requests;
  final void Function(JoinRequest request, bool approve) onDecide;
  final VoidCallback onSeeAll;

  const _JoinRequestsBanner({
    required this.requests,
    required this.onDecide,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: DiraColors.goldLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                color: DiraColors.goldDark,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.newResidents,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: DiraColors.goldDark.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          ...requests.take(3).map(
            (r) => InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.fullName ?? r.phoneNumber ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: DiraColors.goldDark,
                          ),
                        ),
                        if (r.apartmentNumber != null)
                          Text(
                            l10n.apartmentShort('${r.apartmentNumber}'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: DiraColors.goldDark.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.approve,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: DiraColors.sageDark,
                      size: 28,
                    ),
                    onPressed: () => onDecide(r, true),
                  ),
                  IconButton(
                    tooltip: l10n.reject,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: DiraColors.brick,
                      size: 28,
                    ),
                    onPressed: () => onDecide(r, false),
                  ),
                ],
              ),
            ),
          ),
          if (requests.length > 3)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onSeeAll,
                child: Text(
                  '+${requests.length - 3}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DiraColors.goldDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gold announcement strip from the design header.
class _GoldBanner extends StatelessWidget {
  final String kicker;
  final String title;
  const _GoldBanner({required this.kicker, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DiraColors.goldLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_rounded,
            color: DiraColors.goldDark,
            size: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: DiraColors.goldDark.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DiraColors.goldDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable ticket card with the sage-green timeline panel.
class _TicketCard extends StatefulWidget {
  final Ticket ticket;
  final bool showReporter;
  const _TicketCard({required this.ticket, this.showReporter = false});

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Container(
      decoration: BoxDecoration(
        color: DiraColors.sageDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: DiraColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: heading(fontSize: 15, color: Colors.white),
                        ),
                        if (widget.showReporter &&
                            (t.reporterName ?? '').isNotEmpty)
                          Text(
                            t.reporterName!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: TicketTimeline(ticket: t),
            ),
        ],
      ),
    );
  }
}
