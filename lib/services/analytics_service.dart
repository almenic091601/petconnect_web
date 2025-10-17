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
  // Analytics from petRequests
  final Map<String, double> vaccinationStatus;
  final List<MapEntry<String, int>> topBreeds;
  final List<MapEntry<String, int>> ageDistribution;
  final List<FlSpot> requestTimeline;
  final Map<String, double> genderDistribution;
  final List<MapEntry<String, double>> petTypeDistribution;
  final double totalRequests;
  final double vaccinationRate;
  final double averageAge;

  AnalyticsData({
    required this.userGrowth,
    required this.petDistribution,
    required this.trackerActivity,
    required this.qrCodeScans,
    required this.announcementEngagement,
    required this.vaccinationStatus,
    required this.topBreeds,
    required this.ageDistribution,
    required this.requestTimeline,
    required this.genderDistribution,
    required this.petTypeDistribution,
    required this.totalRequests,
    required this.vaccinationRate,
    required this.averageAge,
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
      final analyticsData = await _fetchAllAnalytics();
      
      if (!(_analyticsController?.isClosed ?? true)) {
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
      final data = doc.data();
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

  Future<Map<String, double>> _calculateGenderDistribution() async {
    final Map<String, double> distribution = {};

    try {
      final requests = await _firestore.collection('petRequests').get();
      if (requests.docs.isEmpty) return {};

      for (var doc in requests.docs) {
        final data = doc.data();
        final gender = data['gender']?.toString().trim();
        if (gender != null && gender.isNotEmpty) {
          distribution[gender] = (distribution[gender] ?? 0) + 1;
        }
      }
    } catch (e) {
      print('Error calculating gender distribution: $e');
    }

    return distribution;
  }

  Future<List<MapEntry<String, double>>> _calculatePetTypeDistribution() async {
    final Map<String, double> distribution = {};

    try {
      final requests = await _firestore.collection('petRequests').get();
      if (requests.docs.isEmpty) return [];

      for (var doc in requests.docs) {
        final data = doc.data();
        final petType = data['petType']?.toString().trim();
        if (petType != null && petType.isNotEmpty) {
          distribution[petType] = (distribution[petType] ?? 0) + 1;
        }
      }

      final entries = distribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries;
    } catch (e) {
      print('Error calculating pet type distribution: $e');
      return [];
    }
  }

  Future<double> _calculateAverageAge() async {
    try {
      final requests = await _firestore.collection('petRequests').get();
      if (requests.docs.isEmpty) return 0;

      var totalAge = 0.0;
      var count = 0;
      final now = DateTime.now();

      for (var doc in requests.docs) {
        final data = doc.data();
        final birthDateStr = data['birthDate']?.toString();
        
        if (birthDateStr != null) {
          try {
            final birthDate = DateTime.parse(birthDateStr);
            final age = now.difference(birthDate).inDays / 365;
            totalAge += age;
            count++;
          } catch (e) {
            print('Error parsing birth date: $e');
          }
        }
      }

      return count > 0 ? totalAge / count : 0;
    } catch (e) {
      print('Error calculating average age: $e');
      return 0;
    }
  }

  Future<Map<String, double>> _calculateVaccinationStatus() async {
    final Map<String, double> status = {'Vaccinated': 0, 'Not Vaccinated': 0};

    try {
      final requests = await _firestore.collection('petRequests').get();
      if (requests.docs.isEmpty) return {};

      for (var doc in requests.docs) {
        final data = doc.data();
        if (data['isVaccinated'] == true || data['vaccinationStatus']?.toString().toLowerCase() == 'vaccinated') {
          status['Vaccinated'] = (status['Vaccinated'] ?? 0) + 1;
        } else {
          status['Not Vaccinated'] = (status['Not Vaccinated'] ?? 0) + 1;
        }
      }
    } catch (e) {
      print('Error calculating vaccination status: $e');
      return {};
    }

    return status;
  }

  Future<List<MapEntry<String, int>>> _calculateTopBreeds() async {
    final Map<String, int> breeds = {};

    try {
      final requests = await _firestore.collection('petRequests').get();
      if (requests.docs.isEmpty) return [];

      for (var doc in requests.docs) {
        final data = doc.data();
        final breed = data['breed']?.toString().trim();
        if (breed != null && breed.isNotEmpty) {
          breeds[breed] = (breeds[breed] ?? 0) + 1;
        }
      }

      // Sort breeds by count and take top 5
      final sortedBreeds = breeds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedBreeds.take(5).toList();
    } catch (e) {
      print('Error calculating top breeds: $e');
      return [];
    }
  }

  Future<List<MapEntry<String, int>>> _calculateAgeDistribution() async {
    final Map<String, int> ages = {
      '< 1 year': 0,
      '1-3 years': 0,
      '3-5 years': 0,
      '5-10 years': 0,
      '10+ years': 0,
    };

    try {
      final requests = await _firestore.collection('petRequests').get();
      if (requests.docs.isEmpty) return [];
      
      final now = DateTime.now();

      for (var doc in requests.docs) {
        final data = doc.data();
        final birthDateStr = data['birthDate']?.toString();
        
        if (birthDateStr != null) {
          try {
            final birthDate = DateTime.parse(birthDateStr);
            final age = now.difference(birthDate).inDays / 365;

            if (age < 1) ages['< 1 year'] = (ages['< 1 year'] ?? 0) + 1;
            else if (age < 3) ages['1-3 years'] = (ages['1-3 years'] ?? 0) + 1;
            else if (age < 5) ages['3-5 years'] = (ages['3-5 years'] ?? 0) + 1;
            else if (age < 10) ages['5-10 years'] = (ages['5-10 years'] ?? 0) + 1;
            else ages['10+ years'] = (ages['10+ years'] ?? 0) + 1;
          } catch (e) {
            print('Error parsing birth date: $e');
          }
        }
      }

      // Only return non-zero entries
      return ages.entries.where((e) => e.value > 0).toList();
    } catch (e) {
      print('Error calculating age distribution: $e');
      return [];
    }
  }

  Future<List<FlSpot>> _calculateRequestTimeline() async {
    try {
      final Map<String, int> dailyRequests = {};
      
      final requests = await _firestore
          .collection('petRequests')
          .orderBy('createdAt', descending: true)
          .get();

      if (requests.docs.isEmpty) return [];

      // Get requests for the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (var doc in requests.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          if (date.isAfter(thirtyDaysAgo)) {
            final key = DateFormat('yyyy-MM-dd').format(date);
            dailyRequests[key] = (dailyRequests[key] ?? 0) + 1;
          }
        }
      }

      if (dailyRequests.isEmpty) return [];

      // Convert to spots
      final spots = <FlSpot>[];
      var index = 0.0;
      final sortedDates = dailyRequests.keys.toList()..sort();
      
      for (var date in sortedDates) {
        spots.add(FlSpot(index, dailyRequests[date]!.toDouble()));
        index++;
      }

      return spots;
    } catch (e) {
      print('Error calculating request timeline: $e');
      return [];
    }
  }

  Future<AnalyticsData> _fetchAllAnalytics() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final requestsSnapshot = await _firestore.collection('petRequests').get();
    final requestCount = requestsSnapshot.size.toDouble();
    
    final userGrowth = await _calculateUserGrowth(usersSnapshot.docs);
    final petDistribution = await _calculatePetDistribution();
    final trackerActivity = await _calculateTrackerActivity();
    final announcementEngagement = await _calculateAnnouncementEngagement();
    
    // Pet requests analytics
    final vaccinationStatus = await _calculateVaccinationStatus();
    final topBreeds = await _calculateTopBreeds();
    final ageDistribution = await _calculateAgeDistribution();
    final requestTimeline = await _calculateRequestTimeline();
    final genderDistribution = await _calculateGenderDistribution();
    final petTypeDistribution = await _calculatePetTypeDistribution();
    final averageAge = await _calculateAverageAge();

    // Calculate vaccination rate
    double vaccinationRate = 0;
    if (vaccinationStatus.isNotEmpty && requestCount > 0) {
      final vaccinated = vaccinationStatus['Vaccinated'] ?? 0;
      vaccinationRate = vaccinated / requestCount;
    }

    return AnalyticsData(
      userGrowth: userGrowth,
      petDistribution: petDistribution,
      trackerActivity: trackerActivity,
      qrCodeScans: [],
      announcementEngagement: announcementEngagement,
      vaccinationStatus: vaccinationStatus,
      topBreeds: topBreeds,
      ageDistribution: ageDistribution,
      requestTimeline: requestTimeline,
      genderDistribution: genderDistribution,
      petTypeDistribution: petTypeDistribution,
      totalRequests: requestCount,
      vaccinationRate: vaccinationRate,
      averageAge: averageAge,
    );
  }
}
