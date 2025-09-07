import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petconnect/screens/admin_dashboard.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'High Priority'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _navigateToPendingRequests(BuildContext context) {
    final adminDashboardState =
        context.findAncestorStateOfType<AdminDashboardState>();
    if (adminDashboardState != null) {
      adminDashboardState.setState(() {
        adminDashboardState.selectedIndex = 2;
        adminDashboardState.petsManagementInitialTab = 'Pending';
        adminDashboardState.isNotificationsOpen = false;
      });
    }
  }

  void _navigateToTanodReports(BuildContext context) {
    final adminDashboardState =
        context.findAncestorStateOfType<AdminDashboardState>();
    if (adminDashboardState != null) {
      adminDashboardState.setState(() {
        adminDashboardState.selectedIndex = 7;
        adminDashboardState.isNotificationsOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('petRequests').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading pet requests');
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final petRequests = snapshot.data!.docs;
                final unreadCount = petRequests.length;

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pet Registration Requests ($unreadCount)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _navigateToPendingRequests(context);
                      },
                      icon: const Icon(Icons.pets),
                      label: const Text('View All Requests'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Tanod Reports Section
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('tanod_reports').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading tanod reports');
                }

                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final tanodReports = snapshot.data!.docs;
                // Count reports from the last 24 hours as "new"
                final now = DateTime.now();
                final yesterday = now.subtract(const Duration(hours: 24));

                final newReports = tanodReports.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = data['createdAt'] as Timestamp?;
                  return createdAt != null &&
                      createdAt.toDate().isAfter(yesterday);
                }).length;

                if (newReports == 0) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'New Tanod Reports ($newReports)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _navigateToTanodReports(context);
                          },
                          icon: const Icon(Icons.report),
                          label: const Text('View All Reports'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6750A4),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor:
                          isSelected ? const Color(0xFFEADDFF) : Colors.white,
                      selectedColor: const Color(0xFFEADDFF),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF6750A4)
                            : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('petRequests').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading notifications'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final petRequests = snapshot.data!.docs;

                  final totalNotifications = petRequests.length;

                  if (totalNotifications == 0) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: totalNotifications,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // Pet request notification
                      final request =
                          petRequests[index].data() as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: const Icon(
                                Icons.pets,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "New Pet Registration Request",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning,
                                      color: Colors.red.shade700, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'High Priority',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "Pet: ${request['petName']}\nOwner: ${request['ownerName']}\nStatus: Pending Approval",
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request['timestamp']?.toDate().toString() ??
                                  'No timestamp',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // Show options menu
                          },
                        ),
                        onTap: () {
                          _navigateToPendingRequests(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
