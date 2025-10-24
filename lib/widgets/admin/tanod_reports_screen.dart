import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Conditional import: use web printing implementation when running on web,
// otherwise use a stub that reports unsupported.
import 'web_printing.dart';

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

  String _escapeHtml(String text) {
    return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  Future<String> _imageToBase64(String assetPath) async {
    final ByteData bytes = await rootBundle.load(assetPath);
    final Uint8List list = bytes.buffer.asUint8List();
    return base64Encode(list);
  }

  String _generateHtmlForReports(List<QueryDocumentSnapshot> reports, String leftImageBase64, String rightImageBase64) {
    final buffer = StringBuffer();
    final formatter = DateFormat('MMMM d, yyyy h:mm a');
    
    // Add print-specific styles
    buffer.write('''
      <!DOCTYPE html>
      <html>
        <head>
          <title>Tanod Reports</title>
          <style>
            @media print {
              body { 
                margin: 0;
                padding: 12px;
                font-family: Arial, sans-serif;
              }
              table { 
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
                font-size: 10px;
              }
              th, td { 
                padding: 4px 6px;
                text-align: left;
                border: 1px solid #ddd;
                vertical-align: top;
              }
              th { 
                background-color: #f5f5f5 !important;
                -webkit-print-color-adjust: exact;
                font-weight: bold;
                font-size: 10px;
              }
              h1 { 
                margin-bottom: 12px; 
                font-size: 18px;
              }
              .report-header { margin-bottom: 12px; }
              .timestamp { 
                color: #666; 
                font-size: 10px;
              }
              .details { 
                max-width: 250px;
                word-wrap: break-word;
                line-height: 1.1;
              }
              .detail-row {
                margin: 1px 0;
                padding: 0;
              }
              .detail-row small {
                font-size: 9px;
                color: #333;
                display: block;
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
              }
            }
          </style>
        </head>
        <body>
          <div class="report-header">
            <div style="display: flex; align-items: center; justify-content: center; margin-bottom: 16px; border-bottom: 2px solid #000; padding-bottom: 12px;">
              <img src="data:image/png;base64,$leftImageBase64" alt="Logo" style="height: 60px; margin-right: 20px;">
              <div style="text-align: center;">
                <h1 style="margin: 0; font-size: 20px; color: red;">CITY OF OROQUIETA</h1>
                <h2 style="margin: 4px 0; font-size: 16px;">BARANGAY MOBOD</h2>
              </div>
              <img src="data:image/png;base64,$rightImageBase64" alt="Logo" style="height: 60px; margin-left: 20px;">
            </div>
            <h1>Tanod Reports Summary</h1>
            <p class="timestamp">Generated on ${formatter.format(DateTime.now())}</p>
            <p>Total Reports: ${reports.length}</p>
            <hr>
          </div>
          
          <table>
            <thead>
              <tr>
                <th>Report ID</th>
                <th>Date</th>
                <th>Tanod ID</th>
                <th>Location</th>
                <th>Pet Details</th>
              </tr>
            </thead>
            <tbody>
    ''');

    // Add each report as a row
    for (var doc in reports) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] as Timestamp;
      final date = formatter.format(createdAt.toDate());
      
      // Parse and format pet details
      String rawDetails = data['details']?.toString() ?? '{}';
      
      // Convert the raw string into proper JSON format
      Map<String, dynamic> details = {};
      try {
        // Remove curly braces and split by comma
        String cleaned = rawDetails.replaceAll('{', '').replaceAll('}', '');
        List<String> pairs = cleaned.split(',').map((s) => s.trim()).toList();
        
        // Convert each key-value pair into proper JSON format
        for (String pair in pairs) {
          List<String> keyValue = pair.split(':').map((s) => s.trim()).toList();
          if (keyValue.length == 2) {
            String key = keyValue[0];
            String value = keyValue[1];
            details[key] = value;
          }
        }
      } catch (e) {
        print('Error parsing details: $e');
        print('Raw details: $rawDetails');
      }

      // Format the birthdate if present
      String birthDate = details['birthDate'] ?? 'N/A';
      if (birthDate != 'N/A') {
        try {
          final date = DateTime.parse(birthDate);
          birthDate = DateFormat('MM/dd/yyyy').format(date);
        } catch (e) {
          // Keep original if parsing fails
        }
      }

      // Format the birth date
      String formattedDate = 'N/A';
      if (details['birthDate'] != null) {
        try {
          // Extract just the date part and parse it
          String dateStr = details['birthDate'].toString().split('T')[0];
          DateTime date = DateTime.parse(dateStr);
          formattedDate = DateFormat('MM/dd/yyyy').format(date);
        } catch (e) {
          print('Error formatting date: $e');
        }
      }
      
      final formattedDetails = '''
        <div class="details">
          <div class="detail-row"><small>Pet: ${_escapeHtml(details['petName'] ?? 'N/A')} (${_escapeHtml(details['type'] ?? 'N/A')})</small></div>
          <div class="detail-row"><small>Owner: ${_escapeHtml(details['ownerName'] ?? 'N/A')}</small></div>
          <div class="detail-row"><small>Breed: ${_escapeHtml(details['breed'] ?? 'N/A')}</small></div>
          <div class="detail-row"><small>Birth: $formattedDate</small></div>
          <div class="detail-row"><small>Status: ${_escapeHtml(details['vaccinationStatus'] ?? 'N/A')}</small></div>
        </div>
      ''';
      
      buffer.write('''
              <tr>
                <td>${_escapeHtml(doc.id.substring(0, 8))}</td>
                <td>${_escapeHtml(date)}</td>
                <td>${_escapeHtml(data['tanodId']?.toString() ?? 'N/A')}</td>
                <td>${_escapeHtml(data['location']?.toString() ?? 'No location')}</td>
                <td>$formattedDetails</td>
              </tr>
      ''');
    }

    buffer.write('''
            </tbody>
          </table>
        </body>
      </html>
    ''');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Print button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tanod Reports',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Print All'),
                onPressed: () async {
                  try {
                    // Show loading indicator
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Fetch reports
                    final snapshot = await _firestore
                        .collection('tanod_reports')
                        .orderBy('createdAt', descending: true)
                        .get();

                    if (!mounted) return;
                    Navigator.of(context).pop(); // Remove loading

                    if (snapshot.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No reports to print')),
                      );
                      return;
                    }

                    // Load images and convert to base64
                    final leftImageBase64 = await _imageToBase64('images/logo-v2.png');
                    final rightImageBase64 = await _imageToBase64('images/mobod.jpg');

                    // Print directly without confirmation
                    final html = _generateHtmlForReports(snapshot.docs, leftImageBase64, rightImageBase64);
                    try {
                      await WebPrinting.printHtml(html);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Print failed: $e')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.of(context).pop(); // Remove loading if shown
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to prepare print preview: $e')),
                    );
                  }
                },
              ),
            ],
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
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Refresh
                            },
                            child: const Text('Retry'),
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
                          const Icon(Icons.report_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No reports found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total in Firestore: ${reports.length}, After filtering: ${filteredReports.length}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current filter: $_selectedFilter, Sort: $_selectedSort',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilter = 'All';
                                _selectedSort = 'Newest';
                              });
                            },
                            child: const Text('Reset Filters'),
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

    Map<String, dynamic> detailsData = {};

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
        final details = data["details"];
        if (details is Map<String, dynamic>) {
          detailsData = details;
        } else if (details is String) {
          try {
            detailsData = Map<String, dynamic>.from(jsonDecode(details));
          } catch (e) {
            print('Error parsing details string: $e');
          }
        }

        final petId = detailsData['petId'] ?? 'N/A';
        print('Pet ID: $petId');

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