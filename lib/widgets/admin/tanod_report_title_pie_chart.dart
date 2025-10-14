import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TanodReportTitlePieChart extends StatefulWidget {
  const TanodReportTitlePieChart({super.key});

  @override
  State<TanodReportTitlePieChart> createState() => _TanodReportTitlePieChartState();
}

class _TanodReportTitlePieChartState extends State<TanodReportTitlePieChart> {
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
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_titleCounts.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No data available')),
      );
    }
    final entries = _titleCounts.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final color = _pieColor(idx);
                  return PieChartSectionData(
                    color: color,
                    value: e.value.toDouble(),
                    title: '${e.value}',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: entries.asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              final color = _pieColor(idx);
              final percent = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: color, margin: const EdgeInsets.only(right: 4)),
                  Text('${e.key} ($percent%)', style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _pieColor(int idx) {
    // Use a set of distinct colors
    const colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.brown,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.yellow,
      Colors.grey,
    ];
    return colors[idx % colors.length];
  }
}
