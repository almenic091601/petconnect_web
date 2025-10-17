import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TanodReportTitleAnalytics extends StatefulWidget {
  const TanodReportTitleAnalytics({super.key});

  @override
  State<TanodReportTitleAnalytics> createState() => _TanodReportTitleAnalyticsState();
}

class _TanodReportTitleAnalyticsState extends State<TanodReportTitleAnalytics> {
  Map<String, int> _titleCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTitleCounts();
  }

  Future<void> _fetchTitleCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('tanod_reports').get();
    final counts = <String, int>{};
    for (var doc in snapshot.docs) {
      final title = doc.data()['title']?.toString().trim() ?? 'Unknown';
      counts[title] = (counts[title] ?? 0) + 1;
    }
    setState(() {
      _titleCounts = counts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_titleCounts.isEmpty) {
      return const Text('No Tanod Reports found.');
    }
    final entries = _titleCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    return RotatedBox(
                      quarterTurns: 1,
                      child: Text(entries[idx].key, style: const TextStyle(fontSize: 12)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entries[index].value.toDouble(),
                color: Colors.blueAccent,
                width: 20,
              ),
            ],
          )),
        ),
      ),
    );
  }
}
