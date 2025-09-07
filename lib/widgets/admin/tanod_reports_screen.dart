import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TanodReportsScreen extends StatefulWidget {
  const TanodReportsScreen({super.key});

  @override
  State<TanodReportsScreen> createState() => _TanodReportsScreenState();
}

class _TanodReportsScreenState extends State<TanodReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Tanod Reports',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage all tanod reports',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Search and Filter Bar
          _buildSearchAndFilterBar(),
          const SizedBox(height: 24),

          // Reports Table
          Expanded(
            child: Card(
              elevation: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: _getReportsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Refresh
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data?.docs ?? [];
                  final filteredReports = _filterReports(reports);

                  if (filteredReports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.report_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No reports found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Total in Firestore: ${reports.length}, After filtering: ${filteredReports.length}',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Current filter: $_selectedFilter, Sort: $_selectedSort',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilter = 'All';
                                _selectedSort = 'Newest';
                              });
                            },
                            child: Text('Reset Filters'),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildReportsTable(filteredReports);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tanod_reports').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final reports = snapshot.data!.docs;
        final totalReports = reports.length;
        final todayReports = reports.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp == null) return false;
          final date = timestamp.toDate();
          final today = DateTime.now();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).length;

        // Since status field doesn't exist in your structure, we'll show different stats
        final recentReports = reports.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp == null) return false;
          final date = timestamp.toDate();
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          return date.isAfter(weekAgo);
        }).length;

        final reportsWithLocation = reports.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final location = data['location'] as String?;
          return location != null && location.trim().isNotEmpty;
        }).length;

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Reports',
                totalReports.toString(),
                Icons.report,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Today\'s Reports',
                todayReports.toString(),
                Icons.today,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'This Week',
                recentReports.toString(),
                Icons.calendar_today,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'With Location',
                reportsWithLocation.toString(),
                Icons.location_on,
                Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Search reports by tanod ID, title, details, or location...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _selectedFilter,
          onChanged: (value) {
            setState(() {
              _selectedFilter = value!;
            });
          },
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Reports')),
            DropdownMenuItem(
                value: 'with_location', child: Text('With Location')),
            DropdownMenuItem(
                value: 'without_location', child: Text('Without Location')),
          ],
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _selectedSort,
          onChanged: (value) {
            setState(() {
              _selectedSort = value!;
            });
          },
          items: const [
            DropdownMenuItem(value: 'Newest', child: Text('Newest First')),
            DropdownMenuItem(value: 'Oldest', child: Text('Oldest First')),
            DropdownMenuItem(value: 'TanodId', child: Text('By Tanod ID')),
          ],
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getReportsStream() {
    return _firestore.collection('tanod_reports').snapshots();
  }

  List<QueryDocumentSnapshot> _filterReports(
      List<QueryDocumentSnapshot> reports) {
    List<QueryDocumentSnapshot> filtered = reports;

    // Apply location filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as String?;

        if (_selectedFilter == 'with_location') {
          return location != null && location.trim().isNotEmpty;
        } else if (_selectedFilter == 'without_location') {
          return location == null || location.trim().isEmpty;
        }
        return true;
      }).toList();
    }

    // Apply search filter
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final tanodId = (data['tanodId'] as String?)?.toLowerCase() ?? '';
        final title = (data['title'] as String?)?.toLowerCase() ?? '';
        final location = (data['location'] as String?)?.toLowerCase() ?? '';
        final details = (data['details'] as String?)?.toLowerCase() ?? '';

        return tanodId.contains(searchTerm) ||
            title.contains(searchTerm) ||
            location.contains(searchTerm) ||
            details.contains(searchTerm);
      }).toList();
    }

    return filtered;
  }

  Widget _buildReportsTable(List<QueryDocumentSnapshot> reports) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Report ID')),
            DataColumn(label: Text('Tanod ID')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Details')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: reports.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['createdAt'] as Timestamp?;
            final dateStr = timestamp != null
                ? DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toDate())
                : 'N/A';

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    doc.id.substring(0, 8),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                DataCell(Text(data['tanodId'] ?? 'N/A')),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      data['title'] ?? 'N/A',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      data['location'] ?? 'N/A',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      data['details'] ?? 'N/A',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                DataCell(Text(dateStr)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () => _viewReportDetails(doc.id, data),
                        tooltip: 'View Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _deleteReport(doc.id),
                        tooltip: 'Delete Report',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _viewReportDetails(String reportId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details - ${reportId.substring(0, 8)}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Tanod ID', data['tanodId'] ?? 'N/A'),
                _buildDetailRow('Title', data['title'] ?? 'N/A'),
                _buildDetailRow('Location', data['location'] ?? 'N/A'),
                _buildDetailRow('Details', data['details'] ?? 'N/A'),
                if (data['createdAt'] != null)
                  _buildDetailRow(
                    'Reported At',
                    DateFormat('MMMM dd, yyyy at HH:mm')
                        .format((data['createdAt'] as Timestamp).toDate()),
                  ),
                if (data['coordinates'] != null)
                  _buildDetailRow(
                    'Coordinates',
                    '${data['coordinates']['lat']}, ${data['coordinates']['lng']}',
                  ),
                if (data['imageUrl'] != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Attached Image:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Image.network(
                    data['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Failed to load image'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _deleteReport(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Report - ${reportId.substring(0, 8)}'),
        content: const Text(
          'Are you sure you want to delete this report? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _firestore
                    .collection('tanod_reports')
                    .doc(reportId)
                    .delete();

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete report: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
