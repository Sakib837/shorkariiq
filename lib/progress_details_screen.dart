import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'user_service.dart';

class ProgressDetailsScreen extends StatelessWidget {
  const ProgressDetailsScreen({super.key});



  String _fmtDateTime(DateTime d) {
    final dl = d.toLocal();
    final y = dl.year.toString().padLeft(4, '0');
    final m = dl.month.toString().padLeft(2, '0');
    final day = dl.day.toString().padLeft(2, '0');
    final hh = dl.hour.toString().padLeft(2, '0');
    final mm = dl.minute.toString().padLeft(2, '0');
    final ss = dl.second.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user loaded')));
    }

    // Aggregate per day
    final Map<DateTime, int> correctPerDay = {};
    final Map<DateTime, int> wrongPerDay = {};

    // Tag stats: answered + correct per tag
    final Map<String, int> tagAnswered = {};
    final Map<String, int> tagCorrect = {};

    for (final quiz in user.quizzes) {
      final tsString = quiz['timestamp'] as String?;
      final ts = tsString != null ? DateTime.tryParse(tsString) : null;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);

      final questions = (quiz['questions'] ?? []) as List;
      for (final q in questions) {
        final bool ok = q['correct'] == true;
        final List tags = (q['tags'] ?? []) as List;

        if (ok) {
          correctPerDay[day] = (correctPerDay[day] ?? 0) + 1;
        } else {
          wrongPerDay[day] = (wrongPerDay[day] ?? 0) + 1;
        }

        for (final t in tags) {
          final tag = t.toString();
          tagAnswered[tag] = (tagAnswered[tag] ?? 0) + 1;
          if (ok) tagCorrect[tag] = (tagCorrect[tag] ?? 0) + 1;
        }
      }
    }

    final days = <DateTime>{...correctPerDay.keys, ...wrongPerDay.keys}.toList()
      ..sort();

    // Build double bars per day (Correct=green, Wrong=red)
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < days.length; i++) {
      final d = days[i];
      final c = (correctPerDay[d] ?? 0).toDouble();
      final w = (wrongPerDay[d] ?? 0).toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 8,
          barRods: [
            BarChartRodData(toY: c, width: 12, color: Colors.green),
            BarChartRodData(toY: w, width: 12, color: Colors.red),
          ],
        ),
      );
    }

    // Build quiz history (new order: after Weak Areas)
    final quizzes = List<Map<String, dynamic>>.from(user.quizzes);
    quizzes.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    // Build weak areas list with percentages
    final tags = tagAnswered.keys.toList()..sort();
    final weakTiles = tags.map((tag) {
      final answered = tagAnswered[tag] ?? 0;
      final correct = tagCorrect[tag] ?? 0;
      final pct = answered == 0 ? 0.0 : (correct * 100.0 / answered);
      final pctStr = pct.toStringAsFixed(1);
      return ListTile(
        leading: const Icon(Icons.label_outline),
        title: Text(tag),
        subtitle: Text('Correct $correct / $answered  ($pctStr%)'),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1) CHART
          const Text(
            'Correct vs Wrong by Day',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            const Text('No data yet.')
          else
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  groupsSpace: 16,
                  barGroups: groups,
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox.shrink();
                          final d = days[i];
                          final label = "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label, style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 5, // steps of 5
                        getTitlesWidget: (value, meta) {
                          final v = value.toInt();
                          if (v % 5 == 0) {
                            return Text('$v', style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _LegendDot(label: 'Correct', color: Colors.green),
              SizedBox(width: 12),
              _LegendDot(label: 'Wrong', color: Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          // 2) WEAK AREAS
          const Text(
            'Weak Areas (by Topic)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (weakTiles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('No data yet.'),
            )
          else
            ...weakTiles,

          const SizedBox(height: 24),

          // 3) QUIZ HISTORY
          const Text(
            'Quiz History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (quizzes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('No quizzes taken yet.'),
            )
          else
            ...quizzes.map((q) {
              final tsStr = q['timestamp'] ?? '';
              DateTime? ts = DateTime.tryParse(tsStr);
              final shown = ts != null ? _fmtDateTime(ts) : tsStr;
              final score = q['score'] ?? 0;
              final count = (q['questions'] as List?)?.length ?? 0;
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text('Score: $score/$count'),
                subtitle: Text(shown),
              );
            }),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
