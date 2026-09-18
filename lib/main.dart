import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExamTrackApp());
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

enum ExamCategory { government, college, placement, entrance, personal }

extension ExamCategoryX on ExamCategory {
  String get label => switch (this) {
        ExamCategory.government => 'Government',
        ExamCategory.college => 'College',
        ExamCategory.placement => 'Placement',
        ExamCategory.entrance => 'Entrance',
        ExamCategory.personal => 'Personal',
      };

  IconData get icon => switch (this) {
        ExamCategory.government => Icons.account_balance,
        ExamCategory.college => Icons.school,
        ExamCategory.placement => Icons.work,
        ExamCategory.entrance => Icons.assignment,
        ExamCategory.personal => Icons.star,
      };

  Color get color => switch (this) {
        ExamCategory.government => const Color(0xFF3F51B5),
        ExamCategory.college => const Color(0xFF00897B),
        ExamCategory.placement => const Color(0xFFFB8C00),
        ExamCategory.entrance => const Color(0xFF8E24AA),
        ExamCategory.personal => const Color(0xFFD81B60),
      };

  List<Color> get gradient => switch (this) {
        ExamCategory.government => const [Color(0xFF3F51B5), Color(0xFF7E57C2)],
        ExamCategory.college => const [Color(0xFF00897B), Color(0xFF26C6DA)],
        ExamCategory.placement => const [Color(0xFFFB8C00), Color(0xFFFF7043)],
        ExamCategory.entrance => const [Color(0xFF8E24AA), Color(0xFFEC407A)],
        ExamCategory.personal => const [Color(0xFFD81B60), Color(0xFFE57373)],
      };
}

/// How precisely the user knows when the exam will happen.
enum ExamDateMode { exact, range, month }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// ---------------------------------------------------------------------------
// Exam model
// ---------------------------------------------------------------------------

class Exam {
  final String id;
  final String title;
  final String organization;
  final ExamCategory category;
  final ExamDateMode dateMode;

  final DateTime? examDate; // exact mode
  final DateTime? rangeStart; // range mode
  final DateTime? rangeEnd; // range mode
  final DateTime? monthStart; // month mode (1st of month)
  final DateTime? monthEnd; // month mode (1st of month)

  final bool trackApplication;
  final DateTime? applicationStart;
  final DateTime? applicationEnd;

  final int? fee;
  final String notes;
  double progress;
  String applicationStatus;
  bool remindersOn;

  Exam({
    required this.id,
    required this.title,
    this.organization = '',
    required this.category,
    required this.dateMode,
    this.examDate,
    this.rangeStart,
    this.rangeEnd,
    this.monthStart,
    this.monthEnd,
    this.trackApplication = false,
    this.applicationStart,
    this.applicationEnd,
    this.fee,
    this.notes = '',
    this.progress = 0,
    this.applicationStatus = 'Not Applied',
    this.remindersOn = true,
  });

  DateTime get windowStart => switch (dateMode) {
        ExamDateMode.exact => examDate!,
        ExamDateMode.range => rangeStart!,
        ExamDateMode.month => monthStart!,
      };

  DateTime get windowEnd => switch (dateMode) {
        ExamDateMode.exact => examDate!,
        ExamDateMode.range => rangeEnd!,
        ExamDateMode.month => DateTime(monthEnd!.year, monthEnd!.month + 1, 0),
      };

  bool occursOn(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(_dateOnly(windowStart)) && !d.isAfter(_dateOnly(windowEnd));
  }

  bool get isOngoing {
    final t = _dateOnly(DateTime.now());
    return !t.isBefore(_dateOnly(windowStart)) && !t.isAfter(_dateOnly(windowEnd));
  }

  bool get isPast => _dateOnly(DateTime.now()).isAfter(_dateOnly(windowEnd));

  int get daysToStart => _dateOnly(windowStart).difference(_dateOnly(DateTime.now())).inDays;

  String get whenLabel {
    switch (dateMode) {
      case ExamDateMode.exact:
        return DateFormat('EEE, dd MMM yyyy').format(examDate!);
      case ExamDateMode.range:
        final sameMonth = rangeStart!.month == rangeEnd!.month && rangeStart!.year == rangeEnd!.year;
        if (sameMonth) {
          return '${DateFormat('dd').format(rangeStart!)}–${DateFormat('dd MMM yyyy').format(rangeEnd!)}';
        }
        return '${DateFormat('dd MMM yyyy').format(rangeStart!)} → ${DateFormat('dd MMM yyyy').format(rangeEnd!)}';
      case ExamDateMode.month:
        final sameMonth = monthStart!.month == monthEnd!.month && monthStart!.year == monthEnd!.year;
        if (sameMonth) return DateFormat('MMMM yyyy').format(monthStart!);
        final sameYear = monthStart!.year == monthEnd!.year;
        if (sameYear) {
          return '${DateFormat('MMMM').format(monthStart!)} – ${DateFormat('MMMM yyyy').format(monthEnd!)}';
        }
        return '${DateFormat('MMMM yyyy').format(monthStart!)} – ${DateFormat('MMMM yyyy').format(monthEnd!)}';
    }
  }

  String get windowKind => switch (dateMode) {
        ExamDateMode.exact => 'Exact date',
        ExamDateMode.range => 'Date range',
        ExamDateMode.month => 'Month window',
      };

  static DateTime? _fromMs(dynamic v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'organization': organization,
        'category': category.name,
        'dateMode': dateMode.name,
        'examDate': examDate?.millisecondsSinceEpoch,
        'rangeStart': rangeStart?.millisecondsSinceEpoch,
        'rangeEnd': rangeEnd?.millisecondsSinceEpoch,
        'monthStart': monthStart?.millisecondsSinceEpoch,
        'monthEnd': monthEnd?.millisecondsSinceEpoch,
        'trackApplication': trackApplication,
        'applicationStart': applicationStart?.millisecondsSinceEpoch,
        'applicationEnd': applicationEnd?.millisecondsSinceEpoch,
        'fee': fee,
        'notes': notes,
        'progress': progress,
        'applicationStatus': applicationStatus,
        'remindersOn': remindersOn,
      };

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: j['id'] as String,
        title: j['title'] as String,
        organization: j['organization'] as String? ?? '',
        category: ExamCategory.values.byName(j['category'] as String),
        dateMode: ExamDateMode.values.byName(j['dateMode'] as String),
        examDate: _fromMs(j['examDate']),
        rangeStart: _fromMs(j['rangeStart']),
        rangeEnd: _fromMs(j['rangeEnd']),
        monthStart: _fromMs(j['monthStart']),
        monthEnd: _fromMs(j['monthEnd']),
        trackApplication: j['trackApplication'] as bool? ?? false,
        applicationStart: _fromMs(j['applicationStart']),
        applicationEnd: _fromMs(j['applicationEnd']),
        fee: j['fee'] as int?,
        notes: j['notes'] as String? ?? '',
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        applicationStatus: j['applicationStatus'] as String? ?? 'Not Applied',
        remindersOn: j['remindersOn'] as bool? ?? true,
      );
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

class ExamStore extends ChangeNotifier {
  List<Exam> exams = [];
  static const _key = 'examtrack_exams_v2';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      exams = list.map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(exams.map((e) => e.toJson()).toList()));
  }

  Future<void> addExam(Exam e) async {
    exams.add(e);
    await _persist();
    notifyListeners();
  }

  Future<void> updateExam(Exam e) async {
    final i = exams.indexWhere((x) => x.id == e.id);
    if (i != -1) exams[i] = e;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteExam(String id) async {
    exams.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> updateProgress(Exam e, double v) async {
    e.progress = v;
    await _persist();
    notifyListeners();
  }

  Future<void> updateStatus(Exam e, String s) async {
    e.applicationStatus = s;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleReminder(Exam e) async {
    e.remindersOn = !e.remindersOn;
    await _persist();
    notifyListeners();
  }

  List<Exam> get sorted => [...exams]..sort((a, b) {
      final pastCmp = (a.isPast ? 1 : 0) - (b.isPast ? 1 : 0);
      if (pastCmp != 0) return pastCmp;
      return a.windowStart.compareTo(b.windowStart);
    });
}

// ---------------------------------------------------------------------------
// App shell
// ---------------------------------------------------------------------------

class ExamTrackApp extends StatefulWidget {
  const ExamTrackApp({super.key});
  @override
  State<ExamTrackApp> createState() => _ExamTrackAppState();
}

class _ExamTrackAppState extends State<ExamTrackApp> {
  final store = ExamStore();
  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (_, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ExamTrack',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF5C6BC0),
            brightness: Brightness.light,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: EdgeInsets.zero,
              color: const Color(0xFFF3F3FB),
            ),
            chipTheme: ChipThemeData(shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300))),
          ),
          home: MainShell(store: store),
        ),
      );
}

class MainShell extends StatefulWidget {
  final ExamStore store;
  const MainShell({super.key, required this.store});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store),
      CalendarPage(store: widget.store),
      ExamListPage(store: widget.store),
      AlertsPage(store: widget.store),
      ProfilePage(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'My Exams'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable graphical widgets
// ---------------------------------------------------------------------------

/// A circular progress ring, drawn with a custom painter + gradient sweep.
class RingProgress extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget? child;
  const RingProgress({
    super.key,
    required this.value,
    this.size = 84,
    this.strokeWidth = 9,
    required this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(value: value.clamp(0, 1), color: color, strokeWidth: strokeWidth),
            ),
            if (child != null) child!,
          ],
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;
  _RingPainter({required this.value, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = color.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: const GradientRotation(-math.pi / 2),
      colors: [color.withOpacity(0.45), color],
    );
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}

/// Horizontal breakdown of exam counts per category, rendered as gradient bars.
class CategoryBreakdown extends StatelessWidget {
  final Map<ExamCategory, int> counts;
  const CategoryBreakdown({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final active = ExamCategory.values.where((c) => (counts[c] ?? 0) > 0).toList();
    final maxCount = active.isEmpty ? 1 : active.map((c) => counts[c]!).reduce((a, b) => a > b ? a : b);
    return Column(
      children: active.map((c) {
        final n = counts[c] ?? 0;
        final frac = maxCount == 0 ? 0.0 : n / maxCount;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(c.icon, size: 15, color: c.color),
              const SizedBox(width: 8),
              SizedBox(width: 76, child: Text(c.label, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => Stack(
                      children: [
                        Container(height: 10, color: c.color.withOpacity(0.12)),
                        Container(
                          height: 10,
                          width: constraints.maxWidth * frac,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: c.gradient)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 18, child: Text('$n', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Small pill showing urgency (days left / ongoing / passed).
class CountdownChip extends StatelessWidget {
  final Exam exam;
  const CountdownChip({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String text;
    if (exam.isPast) {
      bg = Colors.grey;
      text = 'Passed';
    } else if (exam.isOngoing) {
      bg = Colors.green.shade600;
      text = 'Happening now';
    } else {
      final d = exam.daysToStart;
      bg = d <= 3 ? Colors.red.shade400 : (d <= 14 ? Colors.orange.shade700 : exam.category.color);
      text = 'In $d day${d == 1 ? '' : 's'}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class HomePage extends StatelessWidget {
  final ExamStore store;
  const HomePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = store.sorted;
    final upcoming = all.where((e) => !e.isPast).toList();
    final thisMonth = all.where((e) => e.windowStart.year == now.year && e.windowStart.month == now.month).length;
    final next7 = upcoming.where((e) => e.daysToStart <= 7).length;
    final counts = <ExamCategory, int>{};
    for (final e in all) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final featured = upcoming.isNotEmpty ? upcoming.first : null;
    final rest = upcoming.length > 1 ? upcoming.sublist(1) : <Exam>[];
    final past = all.where((e) => e.isPast).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditExamPage(store: store))),
        icon: const Icon(Icons.add),
        label: const Text('Add Exam'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            title: Text('ExamTrack'),
          ),
          if (all.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)]),
                        ),
                        child: const Icon(Icons.event_note, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 18),
                      const Text('No exams yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Add the exams you\'re tracking, with your own titles and dates.\nNot sure of the exact date? Use a month window instead —\ne.g. NCRTC is usually Nov–Dec.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditExamPage(store: store))),
                        icon: const Icon(Icons.add),
                        label: const Text('Add your first exam'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.event_note, label: 'Total', value: '${all.length}', color: const Color(0xFF5C6BC0))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.calendar_view_month, label: 'This month', value: '$thisMonth', color: const Color(0xFF00897B))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.bolt, label: 'Next 7 days', value: '$next7', color: const Color(0xFFFB8C00))),
                  ],
                ),
              ),
            ),
            if (featured != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: _FeaturedExamCard(exam: featured, store: store),
                ),
              ),
            if (counts.length > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('By category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 10),
                          CategoryBreakdown(counts: counts),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _sectionHeader(context, 'Upcoming', rest.length)),
            if (rest.isEmpty && featured == null)
              const SliverToBoxAdapter(child: SizedBox())
            else if (rest.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text('Nothing else coming up — add another exam any time.', style: TextStyle(color: Colors.grey.shade600)),
                ),
              )
            else
              SliverList.builder(itemCount: rest.length, itemBuilder: (_, i) => ExamTile(exam: rest[i], store: store)),
            if (past.isNotEmpty) ...[
              SliverToBoxAdapter(child: _sectionHeader(context, 'Past', past.length)),
              SliverList.builder(itemCount: past.length, itemBuilder: (_, i) => ExamTile(exam: past[i], store: store)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Chip(label: Text('$count'), visualDensity: VisualDensity.compact),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      );
}

class _FeaturedExamCard extends StatelessWidget {
  final Exam exam;
  final ExamStore store;
  const _FeaturedExamCard({required this.exam, required this.store});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDetailPage(exam: exam, store: store))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: exam.category.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: exam.category.color.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'ring-${exam.id}',
              child: RingProgress(
                value: exam.progress,
                color: Colors.white,
                size: 78,
                strokeWidth: 7,
                child: Text('${(exam.progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXT UP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(exam.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.event, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(exam.whenLabel, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      exam.isOngoing ? 'Happening now' : (exam.daysToStart <= 0 ? 'Today' : '${exam.daysToStart} days to go'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exam tile (shared list item)
// ---------------------------------------------------------------------------

class ExamTile extends StatelessWidget {
  final Exam exam;
  final ExamStore store;
  const ExamTile({super.key, required this.exam, required this.store});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: exam.isPast ? 0.55 : 1,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDetailPage(exam: exam, store: store))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: exam.category.gradient)),
                  child: Icon(exam.category.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (exam.organization.isNotEmpty) Text(exam.organization, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.event, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(child: Text(exam.whenLabel, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CountdownChip(exam: exam),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

class CalendarPage extends StatefulWidget {
  final ExamStore store;
  const CalendarPage({super.key, required this.store});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();
  DateTime focused = DateTime.now();

  List<Exam> _examsOn(DateTime d) => widget.store.exams.where((e) => e.occursOn(d)).toList();

  @override
  Widget build(BuildContext context) {
    final day = _examsOn(selected);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Exam Calendar', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        TableCalendar<Exam>(
          firstDay: DateTime(2025),
          lastDay: DateTime(2032),
          focusedDay: focused,
          selectedDayPredicate: (d) => DateUtils.isSameDay(d, selected),
          onDaySelected: (s, f) => setState(() {
            selected = s;
            focused = f;
          }),
          eventLoader: _examsOn,
          calendarStyle: const CalendarStyle(markersMaxCount: 3, markerSize: 6),
          calendarBuilders: CalendarBuilders<Exam>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Positioned(
                bottom: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((e) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: e.category.color),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: day.isEmpty
              ? Center(
                  child: Text('No exams on ${DateFormat('dd MMM yyyy').format(selected)}.', style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView(children: day.map((e) => ExamTile(exam: e, store: widget.store)).toList()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Full list with search & filter
// ---------------------------------------------------------------------------

class ExamListPage extends StatefulWidget {
  final ExamStore store;
  const ExamListPage({super.key, required this.store});
  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  String query = '';
  ExamCategory? filter;

  @override
  Widget build(BuildContext context) {
    final list = widget.store.sorted.where((e) {
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || e.title.toLowerCase().contains(q) || e.organization.toLowerCase().contains(q);
      return matchesQuery && (filter == null || e.category == filter);
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditExamPage(store: widget.store))),
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, title: Text('My Exams')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'Search your exams...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: const Text('All'), selected: filter == null, onSelected: (_) => setState(() => filter = null)),
                  ),
                  ...ExamCategory.values.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(c.icon, size: 15, color: filter == c ? Colors.white : c.color),
                          label: Text(c.label),
                          selected: filter == c,
                          selectedColor: c.color,
                          labelStyle: TextStyle(color: filter == c ? Colors.white : null),
                          onSelected: (_) => setState(() => filter = filter == c ? null : c),
                        ),
                      )),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  widget.store.exams.isEmpty ? 'No exams added yet.\nTap + to add your first one.' : 'No exams match your search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => Dismissible(
                key: ValueKey(list[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(18)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete exam?'),
                    content: Text('Remove "${list[i].title}" from your list?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                ),
                onDismissed: (_) => widget.store.deleteExam(list[i].id),
                child: ExamTile(exam: list[i], store: widget.store),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail page
// ---------------------------------------------------------------------------

class ExamDetailPage extends StatelessWidget {
  final Exam exam;
  final ExamStore store;
  const ExamDetailPage({super.key, required this.exam, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exam.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditExamPage(store: store, existing: exam))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete exam?'),
                  content: Text('Remove "${exam.title}" from your list? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) {
                await store.deleteExam(exam.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: exam.category.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'ring-${exam.id}',
                  child: RingProgress(
                    value: exam.progress,
                    color: Colors.white,
                    child: Text('${(exam.progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.category.label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(exam.title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      if (exam.organization.isNotEmpty) Text(exam.organization, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      CountdownChip(exam: exam),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(context, exam.windowKind, exam.whenLabel),
                  _stat(context, 'Fee', exam.fee == null ? '—' : (exam.fee == 0 ? 'Free' : '₹${exam.fee}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Preparation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: exam.progress, borderRadius: BorderRadius.circular(10), minHeight: 8, color: exam.category.color),
                  const SizedBox(height: 6),
                  Text('${(exam.progress * 100).round()}% prepared'),
                  Slider(
                    value: exam.progress,
                    activeColor: exam.category.color,
                    onChanged: (v) => store.updateProgress(exam, v),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: exam.applicationStatus,
                    decoration: const InputDecoration(labelText: 'Application status'),
                    items: ['Not Applied', 'Applied', 'Admit Card', 'Completed']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (s) {
                      if (s != null) store.updateStatus(exam, s);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminders'),
                    value: exam.remindersOn,
                    onChanged: (_) => store.toggleReminder(exam),
                  ),
                ],
              ),
            ),
          ),
          if (exam.trackApplication && exam.applicationStart != null && exam.applicationEnd != null)
            _info('Application Window', '${DateFormat('dd MMM yyyy').format(exam.applicationStart!)} → ${DateFormat('dd MMM yyyy').format(exam.applicationEnd!)}'),
          if (exam.notes.isNotEmpty) _info('Notes', exam.notes),
        ],
      ),
    );
  }

  Widget _stat(BuildContext c, String a, String b) => Column(children: [
        Text(a, style: Theme.of(c).textTheme.labelMedium, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(b, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
      ]);

  Widget _info(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(b),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Add / Edit
// ---------------------------------------------------------------------------

class AddEditExamPage extends StatefulWidget {
  final ExamStore store;
  final Exam? existing;
  const AddEditExamPage({super.key, required this.store, this.existing});
  @override
  State<AddEditExamPage> createState() => _AddEditExamPageState();
}

class _AddEditExamPageState extends State<AddEditExamPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _orgCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _notesCtrl;

  late ExamCategory category;
  late ExamDateMode dateMode;
  DateTime? examDate;
  DateTime? rangeStart, rangeEnd;
  DateTime? monthStart, monthEnd;
  bool trackApplication = false;
  DateTime? applicationStart, applicationEnd;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _orgCtrl = TextEditingController(text: e?.organization ?? '');
    _feeCtrl = TextEditingController(text: e?.fee?.toString() ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    category = e?.category ?? ExamCategory.personal;
    dateMode = e?.dateMode ?? ExamDateMode.exact;
    examDate = e?.examDate;
    rangeStart = e?.rangeStart;
    rangeEnd = e?.rangeEnd;
    monthStart = e?.monthStart;
    monthEnd = e?.monthEnd;
    trackApplication = e?.trackApplication ?? false;
    applicationStart = e?.applicationStart;
    applicationEnd = e?.applicationEnd;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    _feeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _err(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<DateTime?> _pickMonth(DateTime? initial) async {
    int month = initial?.month ?? DateTime.now().month;
    int year = initial?.year ?? DateTime.now().year;
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Select month'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: month,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(value: m, child: Text(DateFormat('MMMM').format(DateTime(2020, m)))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSt(() => month = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: List.generate(6, (i) => DateTime.now().year + i)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSt(() => year = v);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, DateTime(year, month, 1)), child: const Text('OK')),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (dateMode == ExamDateMode.exact && examDate == null) {
      _err('Please select the exam date');
      return;
    }
    if (dateMode == ExamDateMode.range) {
      if (rangeStart == null || rangeEnd == null) {
        _err('Please select a start and end date');
        return;
      }
      if (rangeEnd!.isBefore(rangeStart!)) {
        _err('End date must be on or after the start date');
        return;
      }
    }
    if (dateMode == ExamDateMode.month) {
      if (monthStart == null || monthEnd == null) {
        _err('Please select a start and end month');
        return;
      }
      if (monthEnd!.isBefore(monthStart!)) {
        _err('End month must be on or after the start month');
        return;
      }
    }
    if (trackApplication && (applicationStart == null || applicationEnd == null)) {
      _err('Please set the application window, or turn tracking off');
      return;
    }

    final exam = Exam(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      organization: _orgCtrl.text.trim(),
      category: category,
      dateMode: dateMode,
      examDate: dateMode == ExamDateMode.exact ? examDate : null,
      rangeStart: dateMode == ExamDateMode.range ? rangeStart : null,
      rangeEnd: dateMode == ExamDateMode.range ? rangeEnd : null,
      monthStart: dateMode == ExamDateMode.month ? monthStart : null,
      monthEnd: dateMode == ExamDateMode.month ? monthEnd : null,
      trackApplication: trackApplication,
      applicationStart: trackApplication ? applicationStart : null,
      applicationEnd: trackApplication ? applicationEnd : null,
      fee: _feeCtrl.text.trim().isEmpty ? null : int.tryParse(_feeCtrl.text.trim()),
      notes: _notesCtrl.text.trim(),
      progress: widget.existing?.progress ?? 0,
      applicationStatus: widget.existing?.applicationStatus ?? 'Not Applied',
      remindersOn: widget.existing?.remindersOn ?? true,
    );

    if (isEditing) {
      widget.store.updateExam(exam);
    } else {
      widget.store.addExam(exam);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Exam' : 'Add Exam')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Exam title *', hintText: 'e.g. NCRTC Junior Executive'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _orgCtrl,
              decoration: const InputDecoration(labelText: 'Conducting body / organization (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExamCategory.values
                  .map((c) => ChoiceChip(
                        avatar: Icon(c.icon, size: 16, color: category == c ? Colors.white : c.color),
                        label: Text(c.label),
                        selected: category == c,
                        selectedColor: c.color,
                        labelStyle: TextStyle(color: category == c ? Colors.white : null),
                        onSelected: (_) => setState(() => category = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 22),
            const Text('When might it happen?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Not sure of the exact date? Use a range or a month window — e.g. NCRTC exams usually fall in Nov–Dec.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            SegmentedButton<ExamDateMode>(
              segments: const [
                ButtonSegment(value: ExamDateMode.exact, label: Text('Exact date'), icon: Icon(Icons.event)),
                ButtonSegment(value: ExamDateMode.range, label: Text('Date range'), icon: Icon(Icons.date_range)),
                ButtonSegment(value: ExamDateMode.month, label: Text('Month range'), icon: Icon(Icons.calendar_view_month)),
              ],
              selected: {dateMode},
              onSelectionChanged: (s) => setState(() => dateMode = s.first),
            ),
            const SizedBox(height: 14),
            if (dateMode == ExamDateMode.exact)
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: examDate ?? now.add(const Duration(days: 30)),
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) setState(() => examDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(examDate == null ? 'Select exam date' : DateFormat('EEE, dd MMM yyyy').format(examDate!)),
              ),
            if (dateMode == ExamDateMode.range)
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                    initialDateRange: (rangeStart != null && rangeEnd != null) ? DateTimeRange(start: rangeStart!, end: rangeEnd!) : null,
                  );
                  if (result != null) {
                    setState(() {
                      rangeStart = result.start;
                      rangeEnd = result.end;
                    });
                  }
                },
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  rangeStart == null ? 'Select date range' : '${DateFormat('dd MMM yyyy').format(rangeStart!)} → ${DateFormat('dd MMM yyyy').format(rangeEnd!)}',
                ),
              ),
            if (dateMode == ExamDateMode.month)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _pickMonth(monthStart);
                        if (picked != null) setState(() => monthStart = picked);
                      },
                      icon: const Icon(Icons.calendar_view_month, size: 16),
                      label: Text(monthStart == null ? 'From month' : DateFormat('MMM yyyy').format(monthStart!)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _pickMonth(monthEnd ?? monthStart);
                        if (picked != null) setState(() => monthEnd = picked);
                      },
                      icon: const Icon(Icons.calendar_view_month, size: 16),
                      label: Text(monthEnd == null ? 'To month' : DateFormat('MMM yyyy').format(monthEnd!)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 22),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Track application window'),
              subtitle: const Text('Optional — set this if you know when applications open and close'),
              value: trackApplication,
              onChanged: (v) => setState(() => trackApplication = v),
            ),
            if (trackApplication)
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                    initialDateRange: (applicationStart != null && applicationEnd != null)
                        ? DateTimeRange(start: applicationStart!, end: applicationEnd!)
                        : null,
                  );
                  if (result != null) {
                    setState(() {
                      applicationStart = result.start;
                      applicationEnd = result.end;
                    });
                  }
                },
                icon: const Icon(Icons.app_registration, size: 16),
                label: Text(
                  applicationStart == null
                      ? 'Select application window'
                      : '${DateFormat('dd MMM yyyy').format(applicationStart!)} → ${DateFormat('dd MMM yyyy').format(applicationEnd!)}',
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Application fee in ₹ (optional)', prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes / syllabus (optional)', alignLabelWithHint: true, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? 'Save changes' : 'Add exam'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alerts
// ---------------------------------------------------------------------------

class AlertsPage extends StatelessWidget {
  final ExamStore store;
  const AlertsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final list = store.sorted.where((e) => !e.isPast).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Alerts & Reminders', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Stay ahead of application deadlines and exam windows.'),
        const SizedBox(height: 18),
        ...list.map(
          (e) => Card(
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: e.category.gradient)),
                child: Icon(e.category.icon, color: Colors.white, size: 18),
              ),
              title: Text(e.title),
              subtitle: Text(
                '${e.whenLabel}${e.trackApplication && e.applicationStatus != 'Not Applied' ? '\nApplication: ${e.applicationStatus}' : ''}',
              ),
              isThreeLine: e.trackApplication && e.applicationStatus != 'Not Applied',
              trailing: Switch(value: e.remindersOn, onChanged: (_) => store.toggleReminder(e)),
            ),
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30),
            child: Center(
              child: Text(
                store.exams.isEmpty ? 'Add exams to see reminders here.' : 'Nothing upcoming — you\'re all caught up.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  final ExamStore store;
  const ProfilePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final total = store.exams.length;
    final tracked = store.exams.where((e) => e.trackApplication).length;
    final avgProgress = total == 0 ? 0.0 : store.exams.map((e) => e.progress).reduce((a, b) => a + b) / total;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 45)),
        const SizedBox(height: 12),
        const Center(child: Text('Student', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _StatCard(icon: Icons.event_note, label: 'Exams tracked', value: '$total', color: const Color(0xFF5C6BC0))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: Icons.app_registration, label: 'Applications', value: '$tracked', color: const Color(0xFF00897B))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(icon: Icons.trending_up, label: 'Avg. ready', value: '${(avgProgress * 100).round()}%', color: const Color(0xFFFB8C00))),
          ],
        ),
        const SizedBox(height: 25),
        const Card(
          child: Column(
            children: [
              ListTile(leading: Icon(Icons.school), title: Text('Education'), subtitle: Text('Set your degree and graduation year')),
              ListTile(leading: Icon(Icons.interests), title: Text('Interests'), subtitle: Text('Government • College • Placement • Entrance • Personal')),
              ListTile(leading: Icon(Icons.notifications), title: Text('Notification Preferences'), subtitle: Text('Deadlines, exam reminders and updates')),
              ListTile(leading: Icon(Icons.info_outline), title: Text('About ExamTrack'), subtitle: Text('Your own, fully self-built exam and opportunity calendar')),
            ],
          ),
        ),
      ],
    );
  }
}
