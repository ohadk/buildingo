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
import '../widgets/status_pill.dart';
import '../widgets/pending_ticket_card.dart';
import '../core/tickets_controller.dart';
import 'activity_log_screen.dart';
import 'board_messages_screen.dart';
import 'building_settings_screen.dart';
import 'documents_screen.dart';
import 'maintenance_screen.dart';
import 'meetings_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';
import 'whatsapp_connect_screen.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Ticket> _tickets = [];
  List<Announcement> _announcements = [];
  List<Payment> _payments = [];
  List<JoinRequest> _joinRequests = [];
  List<DirectoryEntry> _apartments = [];
  List<ScheduleOccurrence> _todayEvents = [];
  bool _loading = true;
  StreamSubscription<String>? _realtimeSub;
  Timer? _pollTimer;
  final Set<String> _seenAnnouncementIds = {};
  bool _announcementBaselineReady = false;
  TicketsController? _ticketsInbox;
  int _lastPendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _realtimeSub = realtime.listen({
      'tickets',
      'ticket_events',
      'announcements',
      'payments',
      'join_requests',
      'schedule_events',
      'meetings',
    }, () => _load(silent: true));
    // Fallback when Realtime isn't configured: keep the board live.
    _pollTimer = Timer.periodic(
      Duration(seconds: realtimeEnabled ? 25 : 6),
      (_) => _load(silent: true),
    );
    // When an optimistic create finishes, refresh so the real ticket appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ticketsInbox = context.read<TicketsController>();
      _ticketsInbox!.addListener(_onPendingTicketsChanged);
    });
  }

  void _onPendingTicketsChanged() {
    final pending = _ticketsInbox?.pending ?? const <PendingTicket>[];
    final count = pending.length;
    final hasDone = pending.any((p) => p.phase == PendingTicketPhase.done);
    if (hasDone || count < _lastPendingCount) {
      _load(silent: true);
    }
    _lastPendingCount = count;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticketsInbox?.removeListener(_onPendingTicketsChanged);
    _realtimeSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    final isVaad = context.read<SessionController>().user?.isVaad ?? false;
    try {
      final results = await Future.wait([
        Future.wait([
          api.get('/api/tickets'),
          api.get('/api/announcements'),
          api.get('/api/payments'),
          if (isVaad) api.get('/api/join-requests'),
          if (isVaad) api.get('/api/directory'),
        ]),
        _fetchTodayEvents(),
      ]);
      if (!mounted) return;
      final core = results[0] as List;
      final todayRaw = results[1] as Map<String, dynamic>;
      final nextAnnouncements = ((core[1]['announcements'] ?? []) as List)
          .map((a) => Announcement.fromJson(a as Map<String, dynamic>))
          .toList();
      _notifyNewAnnouncements(nextAnnouncements);
      final todayEvents = ((todayRaw['occurrences'] ?? []) as List)
          .map((e) => ScheduleOccurrence.fromJson(e as Map<String, dynamic>))
          .where((o) => o.eventType != 'announcement')
          .toList();
      setState(() {
        _tickets = ((core[0]['tickets'] ?? []) as List)
            .map((t) => Ticket.fromJson(t))
            .toList();
        _announcements = nextAnnouncements;
        _payments = ((core[2]['payments'] ?? []) as List)
            .map((p) => Payment.fromJson(p))
            .toList();
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
        _todayEvents = todayEvents;
        _loading = false;
      });
    } on ApiException {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  /// Soft-fail schedule fetch so a missing table never breaks home.
  Future<Map<String, dynamic>> _fetchTodayEvents() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      return await api.get(
        '/api/schedule-events?from=$today&to=$today',
      );
    } on ApiException {
      return const {'occurrences': <dynamic>[]};
    }
  }

  void _notifyNewAnnouncements(List<Announcement> next) {
    final ids = next.map((a) => a.id).toSet();
    if (!_announcementBaselineReady) {
      _seenAnnouncementIds
        ..clear()
        ..addAll(ids);
      _announcementBaselineReady = true;
      return;
    }
    final fresh = next
        .where((a) => !_seenAnnouncementIds.contains(a.id))
        .toList();
    _seenAnnouncementIds
      ..clear()
      ..addAll(ids);
    if (fresh.isEmpty || !mounted) return;
    final newest = fresh.first;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DiraColors.goldDark,
        duration: const Duration(seconds: 5),
        content: Text(
          '${l10n.announcementTag}: ${newest.title}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  List<Ticket> get _openTickets {
    final list = _tickets
        .where((t) => t.displayStatus != 'resolved')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  double _expectedMonthlyTotal(Building? building) {
    if (building == null || _apartments.isEmpty) return 0;
    double feeFor(DirectoryEntry a) {
      if (building.feeMethod == 'per_sqm' &&
          building.pricePerSqm != null &&
          a.sizeSqm != null) {
        return (a.sizeSqm! * building.pricePerSqm!).ceilToDouble();
      }
      if (building.feeMethod == 'fixed' && building.fixedMonthlyFee != null) {
        return building.fixedMonthlyFee!.ceilToDouble();
      }
      return a.monthlyFee.ceilToDouble();
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
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
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    color: DiraColors.inkSoft,
                    label: l10n.settingsTitle,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
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
                        MaterialPageRoute(
                          builder: (_) => const ScheduleScreen(),
                        ),
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
                        MaterialPageRoute(
                          builder: (_) => const MeetingsScreen(),
                        ),
                      );
                    },
                  ),
                  if (isVaad) ...[
                    _MenuTile(
                      icon: Icons.settings_suggest_rounded,
                      color: DiraColors.brick,
                      label: l10n.buildingSettings,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BuildingSettingsScreen(),
                          ),
                        );
                      },
                    ),
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
                    _MenuTile(
                      icon: Icons.chat_rounded,
                      color: DiraColors.sage,
                      label: l10n.whatsappConnect,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WhatsAppConnectScreen(),
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
          ),
        );
      },
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
          if (_todayEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TodayScheduleBanner(
              events: _todayEvents,
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              ),
            ),
          ],
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
  // Tenant body: building board + service calls
  // ------------------------------------------------------------------
  List<Widget> _tenantBody(BuildContext context) {
    final l10n = context.l10n;
    return [
      ..._boardSection(context),
      const SizedBox(height: 22),
      _SectionHeader(
        title: l10n.myTickets,
        actionLabel: l10n.viewAllCalls,
        onAction: _openTicketsScreen,
      ),
      const SizedBox(height: 10),
      _serviceCallsList(
        context,
        tickets: _openTickets.take(5).toList(),
      ),
      const SizedBox(height: 110),
    ];
  }

  // ------------------------------------------------------------------
  // Vaad body: building board + open service calls
  // ------------------------------------------------------------------
  List<Widget> _vaadBody(BuildContext context) {
    final l10n = context.l10n;
    return [
      ..._boardSection(context),
      const SizedBox(height: 22),
      _SectionHeader(
        title: l10n.myTickets,
        actionLabel: l10n.viewAllCalls,
        onAction: _openTicketsScreen,
      ),
      const SizedBox(height: 10),
      _serviceCallsList(
        context,
        tickets: _openTickets.take(5).toList(),
        showReporter: true,
      ),
      const SizedBox(height: 110),
    ];
  }

  Widget _serviceCallsList(
    BuildContext context, {
    required List<Ticket> tickets,
    bool showReporter = false,
  }) {
    final pending = context.watch<TicketsController>().pending;
    final pendingIds =
        pending.map((p) => p.createdId).whereType<String>().toSet();
    final visible =
        tickets.where((t) => !pendingIds.contains(t.id)).toList();

    if (_loading && pending.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: DiraColors.brick),
        ),
      );
    }
    if (pending.isEmpty && visible.isEmpty) {
      return const _TicketsEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DiraColors.creamDeep),
      ),
      child: Column(
        children: [
          for (var i = 0; i < pending.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: DiraColors.creamDeep,
              ),
            PendingTicketCard(pending: pending[i]),
          ],
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0 || pending.isNotEmpty)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: DiraColors.creamDeep,
              ),
            _ServiceCallRow(
              ticket: visible[i],
              showReporter: showReporter,
              onTap: _openTicketsScreen,
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Building board — horizontal message cards (design-aligned)
  // ------------------------------------------------------------------
  List<Widget> _boardSection(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final relevant = _announcements
        .where((a) => isAnnouncementOnHomeBoard(a, locale: locale))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final cards = <_BoardCardData>[
      for (final a in relevant.take(8))
        _BoardCardData(
          title: a.title,
          body: a.body.isNotEmpty ? a.body : l10n.announcementTag,
          publishedLabel: DateFormat(
            'd MMM yyyy',
            locale,
          ).format(a.createdAt.toLocal()),
          icon: _boardIconFor(a.title),
          color: _boardColorFor(a.title),
          onTap: () => showAnnouncementDetail(context, a),
        ),
    ];

    return [
      _SectionHeader(
        title: l10n.communityBoard,
        actionLabel: _announcements.isEmpty
            ? null
            : l10n.viewAllBoardMessages,
        onAction: _announcements.isEmpty
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BoardMessagesScreen(
                      announcements: _announcements,
                    ),
                  ),
                ),
      ),
      const SizedBox(height: 12),
      if (cards.isEmpty && !_loading)
        _EmptySoftCard(
          message: _announcements.isEmpty
              ? l10n.nothingOnBoard
              : l10n.noCurrentBoardMessages,
        )
      else if (cards.isNotEmpty)
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _BoardMessageCard(data: cards[i]),
          ),
        ),
    ];
  }

  IconData _boardIconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('אסיפ') || t.contains('meeting') || t.contains('assembly')) {
      return Icons.groups_rounded;
    }
    if (t.contains('תחזוק') ||
        t.contains('ירוק') ||
        t.contains('maintenance') ||
        t.contains('clean')) {
      return Icons.eco_rounded;
    }
    if (t.contains('calendar') || t.contains('לוח')) {
      return Icons.calendar_month_rounded;
    }
    return Icons.campaign_rounded;
  }

  Color _boardColorFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('אסיפ') || t.contains('meeting') || t.contains('assembly')) {
      return DiraColors.goldDark;
    }
    if (t.contains('תחזוק') ||
        t.contains('ירוק') ||
        t.contains('maintenance') ||
        t.contains('clean')) {
      return DiraColors.sageDark;
    }
    return DiraColors.brick;
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

/// Soft sage strip highlighting building services happening today.
class _TodayScheduleBanner extends StatelessWidget {
  final List<ScheduleOccurrence> events;
  final VoidCallback onOpen;

  const _TodayScheduleBanner({
    required this.events,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = events.take(3).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: DiraColors.sagePale,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: DiraColors.sageMist.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DiraColors.sageDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.happeningToday,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.viewCalendar,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: DiraColors.sageDark,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: DiraColors.sageDark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _TodayEventRow(occurrence: shown[i]),
                ],
                if (events.length > shown.length) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+${events.length - shown.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DiraColors.sageDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayEventRow extends StatelessWidget {
  final ScheduleOccurrence occurrence;
  const _TodayEventRow({required this.occurrence});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = ScheduleUi.colorFor(occurrence.eventType);
    final title = ScheduleUi.displayTitle(l10n, occurrence);
    final timeLabel = occurrence.startsAt != null
        ? DateFormat.Hm(Localizations.localeOf(context).languageCode)
            .format(occurrence.startsAt!.toLocal())
        : occurrence.timeOfDay;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            ScheduleUi.iconFor(occurrence.eventType),
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scheduleEventToday(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: color == DiraColors.sageMist
                      ? DiraColors.sageDeep
                      : color,
                  height: 1.2,
                ),
              ),
              if (timeLabel != null && timeLabel.isNotEmpty)
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DiraColors.sageDark,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Soft empty-state card matching the light home redesign.
class _EmptySoftCard extends StatelessWidget {
  final String message;
  const _EmptySoftCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiraColors.creamDeep),
      ),
      child: Text(
        message,
        style: const TextStyle(color: DiraColors.inkSoft, fontSize: 14),
      ),
    );
  }
}

/// Designed empty state when the building has no open service calls.
class _TicketsEmptyState extends StatelessWidget {
  const _TicketsEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [DiraColors.sagePale, DiraColors.creamCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DiraColors.creamDeep),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DiraColors.sageDark.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 34,
              color: DiraColors.sageDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.homeTicketsClearTitle,
            textAlign: TextAlign.center,
            style: heading(fontSize: 18, color: DiraColors.sageDark),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeTicketsClearBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: DiraColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardCardData {
  final String title;
  final String body;
  final String publishedLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BoardCardData({
    required this.title,
    required this.body,
    required this.publishedLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Horizontal building-board message card from the marketing design.
class _BoardMessageCard extends StatelessWidget {
  final _BoardCardData data;
  const _BoardMessageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: 168,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DiraColors.creamDeep),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2B261F),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                  color: data.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 18, color: data.color),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  data.publishedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: DiraColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              data.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: DiraColors.inkSoft,
                height: 1.3,
              ),
            ),
          ),
          InkWell(
            onTap: data.onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.seeDetails,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: DiraColors.brick,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: DiraColors.brick,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Light service-call row: category glyph + title/date + status pill.
class _ServiceCallRow extends StatelessWidget {
  final Ticket ticket;
  final bool showReporter;
  final VoidCallback onTap;

  const _ServiceCallRow({
    required this.ticket,
    this.showReporter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat(
      'd.M.yy',
      locale,
    ).format(ticket.createdAt.toLocal());
    final subtitle = showReporter && (ticket.reporterName ?? '').isNotEmpty
        ? '${ticket.reporterName} · ${l10n.ticketCreatedOn(date)}'
        : l10n.ticketCreatedOn(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CategoryGlyph.forTicket(
                categoryId: ticket.category,
                title: ticket.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill.ticket(context, ticket.displayStatus),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: DiraColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
