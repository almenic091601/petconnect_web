import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsData {
  final List<FlSpot> userGrowth;
  final List<double> petDistribution;
  final List<FlSpot> trackerActivity;
  final List<double> qrCodeScans;
  final List<FlSpot> announcementEngagement;

  AnalyticsData({
    required this.userGrowth,
    required this.petDistribution,
    required this.trackerActivity,
    required this.qrCodeScans,
    required this.announcementEngagement,
  });
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamController<AnalyticsData>? _analyticsController;
  Timer? _timer;
  bool _isRunning = false;

  Stream<AnalyticsData> get analyticsStream {
    _analyticsController ??= StreamController<AnalyticsData>.broadcast();
    return _analyticsController!.stream;
  }

  void startFetchingData() {
    if (!_isRunning) {
      if (_analyticsController == null || _analyticsController!.isClosed) {
        _analyticsController = StreamController<AnalyticsData>.broadcast();
      }

      _isRunning = true;
      _fetchData(); // Initial fetch
      _timer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchData());
    }
  }

  void stopFetchingData() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void dispose() {
    stopFetchingData();
    _analyticsController?.close();
    _analyticsController = null;
  }

  Future<void> _fetchData() async {
    if (_analyticsController == null || _analyticsController!.isClosed) {
      stopFetchingData();
      return;
    }

    try {
      // Fetch users data
      final usersSnapshot = await _firestore.collection('users').get();

      // Calculate user growth over time
      final userGrowth = await _calculateUserGrowth(usersSnapshot.docs);

      // Calculate pet distribution (now based on pets collection)
      final petDistribution = await _calculatePetDistribution();

      // Calculate tracker activity
      final trackerActivity = await _calculateTrackerActivity();

      // Calculate announcement engagement
      final announcementEngagement = await _calculateAnnouncementEngagement();

      if (!(_analyticsController?.isClosed ?? true)) {
        final analyticsData = AnalyticsData(
          userGrowth: userGrowth,
          petDistribution: petDistribution,
          trackerActivity: trackerActivity,
          qrCodeScans: [],
          announcementEngagement: announcementEngagement,
        );

        _analyticsController?.add(analyticsData);
      }
    } catch (e) {
      print('Error fetching analytics data: $e');
    }
  }

  Future<List<FlSpot>> _calculateUserGrowth(
      List<QueryDocumentSnapshot> users) async {
    // Group users by creation date
    final Map<String, int> dailyCounts = {};

    for (var user in users) {
      final createdAt =
          (user.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = DateFormat('yyyy-MM-dd').format(createdAt.toDate());
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }
    }

    // Sort dates and calculate cumulative counts
    final sortedDates = dailyCounts.keys.toList()..sort();
    var cumulativeCount = 0;
    final result = <FlSpot>[];

    for (var i = 0; i < sortedDates.length; i++) {
      cumulativeCount += dailyCounts[sortedDates[i]]!;
      result.add(FlSpot(i.toDouble(), cumulativeCount.toDouble()));
    }

    return result;
  }

  Future<List<double>> _calculatePetDistribution() async {
    final distribution = [0.0, 0.0, 0.0, 0.0]; // Dogs, Cats, Birds, Others

    final petsSnapshot = await _firestore.collection('pets').get();
    for (var doc in petsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = (data['type'] as String?)?.toLowerCase();
      switch (type) {
        case 'dog':
          distribution[0]++;
          break;
        case 'cat':
          distribution[1]++;
          break;
        case 'bird':
          distribution[2]++;
          break;
        default:
          distribution[3]++;
      }
    }

    return distribution;
  }

  Future<List<FlSpot>> _calculateTrackerActivity() async {
    final result = <FlSpot>[];
    final now = DateTime.now();

    // Get tracker activity for the last 5 days
    for (var i = 0; i < 5; i++) {
      final date = now.subtract(Duration(days: 4 - i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('tracker_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .count()
          .get();

      result.add(FlSpot(i.toDouble(), snapshot.count?.toDouble() ?? 0.0));
    }

    return result;
  }

  Future<List<FlSpot>> _calculateAnnouncementEngagement() async {
    final result = <FlSpot>[];

    // Get announcement engagement for the last 5 announcements
    final announcementsSnapshot = await _firestore
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    for (var i = 0; i < announcementsSnapshot.docs.length; i++) {
      final announcement = announcementsSnapshot.docs[i];
      final views = (announcement.data()['views'] as int?)?.toDouble() ?? 0.0;
      result.add(FlSpot(i.toDouble(), views));
    }

    return result;
  }
}
