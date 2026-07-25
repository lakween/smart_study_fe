import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/performance_provider.dart';

class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() => _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState extends ConsumerState<PerformanceDashboardScreen> {
  String _period = 'This Week';

  String get _periodParam => switch (_period) {
        'This Week' => 'week',
        'This Month' => 'month',
        _ => 'all',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(performanceProvider);
    final summary = state.summary;
    final subjectScores = state.subjectScores;
    final weeklyAttempts = state.weeklyActivity;
    final scoreTrend = state.scoreTrend;
    final upcomingRevisions = state.upcomingRevisions;
    final insights = state.insights;

    if (state.isLoading && summary.isEmpty) {
      return const Scaffold(appBar: null, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Performance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['This Week', 'This Month', 'All Time'].map((p) {
                final sel = p == _period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _period = p);
                      ref.read(performanceProvider.notifier).load(period: _periodParam);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.primary : AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.primary)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Summary'),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _SummaryCard(label: 'Quizzes\nAttempted', value: '${summary['totalQuizzesAttempted'] ?? 0}', color: AppColors.primary, icon: Icons.quiz_outlined),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Exams\nCompleted', value: '${summary['totalExamsCompleted'] ?? 0}', color: AppColors.accent, icon: Icons.assignment_outlined),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Avg Quiz\nScore', value: '${((summary['avgQuizScore'] as num?) ?? 0).toStringAsFixed(0)}%', color: AppColors.warning, icon: Icons.bar_chart),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Avg Exam\nScore', value: '${((summary['avgExamScore'] as num?) ?? 0).toStringAsFixed(0)}%', color: const Color(0xFF8B5CF6), icon: Icons.grade_outlined),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Best\nSubject', value: (summary['bestSubject'] as String?)?.split(' ').first ?? '—', color: AppColors.success, icon: Icons.star_outlined),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Weakest\nSubject', value: (summary['weakestSubject'] as String?)?.split(' ').first ?? '—', color: AppColors.error, icon: Icons.warning_amber_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Score Trend'),
            const SizedBox(height: 12),
            AppCard(
              child: SizedBox(
                height: 180,
                child: scoreTrend.isEmpty
                    ? const Center(child: Text('No quiz attempts yet', style: TextStyle(color: AppColors.textMuted)))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20, getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1)),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 20, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
                            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minY: 0, maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: scoreTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['score'] as num).toDouble())).toList(),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Subject Performance'),
            const SizedBox(height: 12),
            AppCard(
              child: SizedBox(
                height: 200,
                child: subjectScores.isEmpty
                    ? const Center(child: Text('No data yet', style: TextStyle(color: AppColors.textMuted)))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(subjectScores.keys.elementAt(v.toInt().clamp(0, subjectScores.length - 1)), style: const TextStyle(fontSize: 9, color: AppColors.textMuted)))),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 25, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: subjectScores.values.toList().asMap().entries.map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [BarChartRodData(toY: e.value, color: AppColors.primary, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))],
                          )).toList(),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Weekly Activity'),
            const SizedBox(height: 12),
            AppCard(
              child: SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (weeklyAttempts.isEmpty ? 1 : weeklyAttempts.reduce((a, b) => a > b ? a : b)).clamp(5, 999).toDouble(),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(['M','T','W','T','F','S','S'][v.toInt().clamp(0, 6)], style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: weeklyAttempts.asMap().entries.map((e) => BarChartGroupData(
                      x: e.key,
                      barRods: [BarChartRodData(toY: e.value.toDouble(), color: AppColors.accent, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
                    )).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: '📅 Upcoming Revisions'),
            const SizedBox(height: 12),
            if (upcomingRevisions.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Nothing due for revision right now', style: TextStyle(color: AppColors.textMuted)))
            else
              ...upcomingRevisions.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.access_alarm, color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r['quizTitle'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                  Text(r['lastScore'] != null ? '${(r['lastScore'] as num).toStringAsFixed(0)}%' : '--', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                ]),
              )),
            const SizedBox(height: 24),
            const SectionHeader(title: '💡 Insights'),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Attempt a few quizzes to see personalized insights here.', style: TextStyle(color: AppColors.textMuted)))
            else
              ...insights.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InsightCard(icon: i['icon'] as String, text: i['message'] as String),
              )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCardBg : AppColors.cardBg, borderRadius: BorderRadius.circular(14), boxShadow: isDark ? [] : AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.3)),
      ]),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String icon; final String text;
  const _InsightCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}
