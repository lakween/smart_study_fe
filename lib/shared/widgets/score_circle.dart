import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ScoreCircle extends StatefulWidget {
  final double score;
  final double size;
  final bool showLabel;

  const ScoreCircle({
    super.key,
    required this.score,
    this.size = 160,
    this.showLabel = true,
  });

  @override
  State<ScoreCircle> createState() => _ScoreCircleState();
}

class _ScoreCircleState extends State<ScoreCircle> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    if (widget.score >= 75) return AppColors.success;
    if (widget.score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final current = _anim.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: widget.size * 0.32,
                  sections: [
                    PieChartSectionData(
                      value: current,
                      color: _scoreColor,
                      radius: widget.size * 0.18,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - current,
                      color: _scoreColor.withValues(alpha: 0.12),
                      radius: widget.size * 0.18,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              if (widget.showLabel)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${current.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: widget.size * 0.18,
                        fontWeight: FontWeight.bold,
                        color: _scoreColor,
                      ),
                    ),
                    Text(
                      widget.score >= 60 ? 'Pass' : 'Fail',
                      style: TextStyle(
                        fontSize: widget.size * 0.09,
                        color: _scoreColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
