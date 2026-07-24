import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import '../models/game_state.dart';
import 'farm_theme.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      appBar: AppBar(
        backgroundColor: FarmTheme.bg,
        foregroundColor: FarmTheme.textPrimary,
        elevation: 0,
        title: Text(l10n.plannerBtn, style: FarmTheme.headingMd),
        iconTheme: const IconThemeData(color: FarmTheme.accent),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Container(height: 1, color: FarmTheme.border),
            TabBar(
              controller: _tabController,
              indicatorColor: FarmTheme.accent,
              indicatorWeight: 2,
              labelColor: FarmTheme.accent,
              unselectedLabelColor: FarmTheme.textMuted,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              tabs: const [
                Tab(text: 'Weekly Plan'),
                Tab(text: 'All Tasks'),
              ],
            ),
          ]),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildWeeklyView(),
            _buildAllTasksView(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: FarmTheme.accent,
        foregroundColor: FarmTheme.bg,
        elevation: 2,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  // ─── Weekly view ──────────────────────────────────────────────
  Widget _buildWeeklyView() {
    final gameState = Provider.of<GameState>(context);
    final currentDay = gameState.currentDay;
    final weekStart  = ((currentDay - 1) ~/ 7) * 7 + 1;
    final weekEnd    = weekStart + 6;

    final weeklyTasks = gameState.customActivities
        .where((t) {
          final d = t['day'] as int;
          return d >= weekStart && d <= weekEnd;
        })
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Week header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: FarmTheme.card,
          child: Row(children: [
            const Icon(Icons.date_range_outlined,
                color: FarmTheme.accent, size: 18),
            const SizedBox(width: 10),
            Text(
              'Week ${((currentDay - 1) ~/ 7) + 1} — Days $weekStart to $weekEnd',
              style: FarmTheme.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ]),
        ),
      ),

      Expanded(
        child: weeklyTasks.isEmpty
            ? _buildEmpty('No tasks scheduled for this week.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                itemCount: weeklyTasks.length,
                itemBuilder: (context, i) {
                  final task = weeklyTasks[i];
                  final globalIdx =
                      gameState.customActivities.indexOf(task);
                  return _taskCard(context, gameState, task, globalIdx);
                },
              ),
      ),
    ]);
  }

  // ─── All tasks view ───────────────────────────────────────────
  Widget _buildAllTasksView() {
    final gameState = Provider.of<GameState>(context);
    final sorted = List<Map<String, dynamic>>.from(
        gameState.customActivities)
      ..sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));

    if (sorted.isEmpty) {
      return _buildEmpty('No tasks planned yet. Tap + to add one.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final task     = sorted[i];
        final globalIdx = gameState.customActivities.indexOf(task);
        return _taskCard(context, gameState, task, globalIdx);
      },
    );
  }

  // ─── Task card ────────────────────────────────────────────────
  Widget _taskCard(
    BuildContext context,
    GameState gameState,
    Map<String, dynamic> task,
    int idx,
  ) {
    final isDone = task['isCompleted'] ?? false;
    final type   = task['type'] as String;
    final typeColor = type == 'daily'
        ? FarmTheme.accent
        : (type == 'weekly' ? FarmTheme.accentWarm : FarmTheme.accentBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: isDone ? FarmTheme.card : BoxDecoration(
        gradient: FarmTheme.cardGradient,
        borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
        border: Border.all(color: typeColor.withOpacity(0.25)),
      ),
      child: Row(children: [
        // Checkbox circle
        GestureDetector(
          onTap: () => gameState.toggleActivityCompletion(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isDone ? FarmTheme.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? FarmTheme.accent : FarmTheme.border,
                width: 1.5,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded,
                    color: FarmTheme.bg, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              task['title'],
              style: FarmTheme.headingMd.copyWith(
                fontSize: 14,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? FarmTheme.textMuted : FarmTheme.textPrimary,
              ),
            ),
            if ((task['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(task['description'],
                  style: FarmTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 5),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(type.toUpperCase(),
                    style: TextStyle(
                        color: typeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text('Day ${task['day']}', style: FarmTheme.caption.copyWith(fontSize: 10)),
            ]),
          ]),
        ),
        // Delete button
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.delete_outline,
              color: FarmTheme.accentRed, size: 16),
          onPressed: () => gameState.removeCustomActivity(idx),
        ),
      ]),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────
  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.event_note_outlined,
              size: 52, color: FarmTheme.border),
          const SizedBox(height: 14),
          Text('No tasks yet',
              style: FarmTheme.headingMd.copyWith(color: FarmTheme.textMuted)),
          const SizedBox(height: 6),
          Text(message,
              style: FarmTheme.caption, textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ─── Add task dialog ─────────────────────────────────────────
  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final dayCtrl   = TextEditingController();
    String type     = 'daily';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final gameState = Provider.of<GameState>(context, listen: false);
          return Dialog(
            backgroundColor: FarmTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FarmTheme.radiusLg),
              side: const BorderSide(color: FarmTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Add New Task', style: FarmTheme.headingMd),
                const SizedBox(height: 20),

                // Type selector
                Row(children: ['daily', 'weekly', 'monthly'].map((t) {
                  final selected = type == t;
                  final color = t == 'daily'
                      ? FarmTheme.accent
                      : (t == 'weekly' ? FarmTheme.accentWarm : FarmTheme.accentBlue);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => type = t),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.15)
                              : FarmTheme.surfaceAlt,
                          borderRadius:
                              BorderRadius.circular(FarmTheme.radiusSm),
                          border: Border.all(
                              color: selected
                                  ? color.withOpacity(0.4)
                                  : FarmTheme.border),
                        ),
                        child: Text(
                          t.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: selected ? color : FarmTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList()),

                const SizedBox(height: 16),
                _field('Task Title', titleCtrl),
                const SizedBox(height: 12),
                _field('Description', descCtrl),
                const SizedBox(height: 12),
                _field('Target Day (e.g. 3)', dayCtrl,
                    type: TextInputType.number),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: FarmTheme.ghostButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isEmpty) return;
                        final day = int.tryParse(dayCtrl.text) ??
                            gameState.currentDay;
                        gameState.customActivities.add({
                          'type': type,
                          'title': titleCtrl.text,
                          'description': descCtrl.text,
                          'isCompleted': false,
                          'day': day,
                          'timestamp': DateTime.now().toIso8601String(),
                        });
                        // Trigger rebuild via a safe toggle
                        if (gameState.customActivities.isNotEmpty) {
                          gameState.toggleActivityCompletion(
                              gameState.customActivities.length - 1);
                          gameState.toggleActivityCompletion(
                              gameState.customActivities.length - 1);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FarmTheme.accent,
                        foregroundColor: FarmTheme.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(FarmTheme.radiusMd)),
                        elevation: 0,
                      ),
                      child: const Text('Add Task',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: FarmTheme.body,
      cursorColor: FarmTheme.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: FarmTheme.textMuted, fontSize: 13),
        filled: true,
        fillColor: FarmTheme.surfaceAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          borderSide: const BorderSide(color: FarmTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          borderSide:
              const BorderSide(color: FarmTheme.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
