import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:petconnect/services/analytics_service.dart';
import 'tanod_report_title_analytics.dart';
import 'tanod_report_title_pie_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.startFetchingData();
  }

  @override
  void dispose() {
    _analyticsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: StreamBuilder<AnalyticsData>(
        stream: _analyticsService.analyticsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Analytics',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Overview of platform activity and engagement',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                // Top row: Vaccinated Pets + Tanod Reports Pie
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Vaccinated Pets',
                        icon: Icons.vaccines,
                        child: Builder(
                          builder: (context) {
                            final vaccinated = data.vaccinationStatus['Vaccinated'] ?? 0;
                            final notVaccinated = data.vaccinationStatus['Not Vaccinated'] ?? 0;
                            final total = vaccinated + notVaccinated;
                            final percent = total > 0 ? (vaccinated / total * 100).toStringAsFixed(1) : '0';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.verified, color: Colors.green, size: 20),
                                    const SizedBox(width: 6),
                                    Text('Vaccinated: $vaccinated', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.cancel, color: Colors.red, size: 20),
                                    const SizedBox(width: 6),
                                    Text('Not Vaccinated: $notVaccinated', style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: total > 0 ? vaccinated / total : 0,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 12),
                                Text('Vaccination Rate: $percent%', style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.w500)),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Tanod Reports by Title',
                        icon: Icons.pie_chart,
                        child: TanodReportTitlePieChart(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Second row: User Growth + Pet Distribution
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnalyticsCard(
                        title: 'User Growth',
                        icon: Icons.show_chart,
                        child: data.userGrowth.isEmpty
                            ? const SizedBox(
                                height: 220,
                                child: Center(child: Text('No data available')),
                              )
                            : SizedBox(
                                height: 220,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: data.userGrowth,
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.blue.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Pet Distribution',
                        icon: Icons.pets,
                        child: data.petDistribution.isEmpty || data.petDistribution.every((e) => e == 0)
                            ? const SizedBox(
                                height: 220,
                                child: Center(child: Text('No data available')),
                              )
                            : SizedBox(
                                height: 220,
                                child: BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            switch (value.toInt()) {
                                              case 0:
                                                return const Text('Dogs');
                                              case 1:
                                                return const Text('Cats');
                                              case 2:
                                                return const Text('Birds');
                                              case 3:
                                                return const Text('Others');
                                              default:
                                                return const Text('');
                                            }
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: List.generate(
                                      data.petDistribution.length,
                                      (index) => BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: data.petDistribution[index],
                                            color: [
                                              Colors.brown,
                                              Colors.orange,
                                              Colors.blue,
                                              Colors.grey,
                                            ][index],
                                            width: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Third row: Tracker Activity + Announcement Engagement
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Tracker Activity',
                        icon: Icons.track_changes,
                        child: data.trackerActivity.isEmpty
                            ? const SizedBox(
                                height: 220,
                                child: Center(child: Text('No data available')),
                              )
                            : SizedBox(
                                height: 220,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            switch (value.toInt()) {
                                              case 0:
                                                return const Text('Mon');
                                              case 1:
                                                return const Text('Tue');
                                              case 2:
                                                return const Text('Wed');
                                              case 3:
                                                return const Text('Thu');
                                              case 4:
                                                return const Text('Fri');
                                              default:
                                                return const Text('');
                                            }
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: data.trackerActivity,
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.blue.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                    Expanded(
                      child: AnalyticsCard(
                        title: 'Announcement Engagement',
                        icon: Icons.announcement,
                        child: data.announcementEngagement.isEmpty
                            ? const SizedBox(
                                height: 220,
                                child: Center(child: Text('No data available')),
                              )
                            : SizedBox(
                                height: 220,
                                child: BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            return Text('A${value.toInt() + 1}');
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: List.generate(
                                      data.announcementEngagement.length,
                                      (index) => BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: data.announcementEngagement[index].y,
                                            color: Colors.purple,
                                            width: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Icon(icon, color: Theme.of(context).primaryColor, size: 28),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
