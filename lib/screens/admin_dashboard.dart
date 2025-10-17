import 'package:flutter/material.dart';
import 'dart:async';
import 'package:petconnect/constants/theme.dart';
import 'package:petconnect/widgets/admin/user_management.dart';
import 'package:petconnect/widgets/admin/pet_tracker.dart';
import 'package:petconnect/widgets/admin/analytics.dart';
import 'package:petconnect/widgets/admin/settings.dart';
import 'package:petconnect/widgets/admin/pets_management.dart';
import 'package:petconnect/widgets/admin/post_announcement.dart';
import 'package:petconnect/widgets/admin/tracker_map.dart';
import 'package:petconnect/widgets/admin/messages_screen.dart';
import 'package:petconnect/widgets/admin/notifications_screen.dart';
import 'package:petconnect/widgets/admin/profile_screen.dart';
import 'package:petconnect/widgets/admin/tanod_accounts.dart';
import 'package:petconnect/widgets/admin/tanod_reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  bool isSidebarCollapsed = false;
  bool isMessagesOpen = false;
  bool isNotificationsOpen = false;
  bool isProfileOpen = false;
  int unreadMessages = 0;
  int unreadNotifications = 0;
  int unreadTanodReports = 0;
  String? petsManagementInitialTab;
  StreamSubscription? _pendingPetsSubscription;
  StreamSubscription? _tanodReportsSubscription;

  @override
  void initState() {
    super.initState();
    _setupPendingPetsListener();
    _setupTanodReportsListener();
  }

  @override
  void dispose() {
    _pendingPetsSubscription?.cancel();
    _tanodReportsSubscription?.cancel();
    super.dispose();
  }

  void _setupPendingPetsListener() {
    _pendingPetsSubscription = FirebaseFirestore.instance
        .collection('pets')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        unreadNotifications = snapshot.docs.length + unreadTanodReports;
      });
    });
  }

  void _setupTanodReportsListener() {
    _tanodReportsSubscription = FirebaseFirestore.instance
        .collection('tanod_reports')
        .snapshots()
        .listen((snapshot) {
      // Count reports from the last 24 hours as "new"
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      int newReports = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null && createdAt.toDate().isAfter(yesterday)) {
          newReports++;
        }
      }

      setState(() {
        unreadTanodReports = newReports;
        unreadNotifications =
            (unreadNotifications - unreadTanodReports) + newReports;
      });
    });
  }

  void setSelectedIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void setNotificationsOpen(bool value) {
    setState(() {
      isNotificationsOpen = value;
      if (value) {
        unreadNotifications = 0; // Reset notification count when opened
      }
    });
  }

  void navigateToPendingRequests() {
    setState(() {
      selectedIndex = 2; // Index for Pets Management
      petsManagementInitialTab = 'Pending';
      isNotificationsOpen = false;
    });
  }

  void navigateToTanodReports() {
    setState(() {
      selectedIndex = 7; // Index for Tanod Reports
      isNotificationsOpen = false;
    });
  }

  final List<Widget> _screens = [
    const AnalyticsScreen(),
    const UserManagementScreen(),
    const PetsManagementScreen(initialTab: 'All'),
    const PetTrackerScreen(),
    const TrackerMapScreen(),
    const PostAnnouncementScreen(),
    const TanodAccountsScreen(),
    const TanodReportsScreen(),
    const SettingsScreen(),
  ];

  void _toggleSidebar() {
    setState(() {
      isSidebarCollapsed = !isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (isDesktop || isTablet)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSidebarCollapsed ? 80 : 250,
              child: Material(
                elevation: 2,
                color: AppTheme.sidebarBackground,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            // Logo and Title Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  if (isSidebarCollapsed)
                                    Container(
                                      height: 48,
                                      width: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        Container(
                                          height: 150,
                                          width: 150,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.white.withOpacity(0.1),
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/logo.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Pet Connect',
                                          style: AppTheme.sidebarTitleStyle,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 2,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Navigation Items
                            _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                            _buildNavItem(1, Icons.people, 'Users'),
                            _buildNavItem(2, Icons.pets, 'Pets'),
                            _buildNavItem(
                                3, Icons.track_changes, 'Pet Tracker'),
                            _buildNavItem(4, Icons.map, 'Tracker Map'),
                            _buildNavItem(
                                5, Icons.announcement, 'Announcements'),
                            _buildNavItem(
                                6, Icons.badge, 'Create Tanod Accounts'),
                            _buildNavItem(7, Icons.report, 'Tanod Reports'),
                            _buildNavItem(8, Icons.settings, 'Settings'),
                          ],
                        ),
                        // Collapse Button at Bottom
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: IconButton(
                            icon: Icon(
                              isSidebarCollapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                              color: Colors.white,
                            ),
                            onPressed: _toggleSidebar,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                AppBar(
                  backgroundColor: const Color.fromARGB(255, 0, 77, 64),
                  elevation: 1,
                  title: _getTitle(selectedIndex),
                  actions: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              isMessagesOpen = !isMessagesOpen;
                              isNotificationsOpen = false;
                            });
                          },
                          tooltip: 'Messages',
                        ),
                        if (unreadMessages > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadMessages.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              isNotificationsOpen = !isNotificationsOpen;
                              isMessagesOpen = false;
                            });
                          },
                          tooltip: 'Notifications',
                        ),
                        if (unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadNotifications.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          isProfileOpen = true;
                          isMessagesOpen = false;
                          isNotificationsOpen = false;
                        });
                      },
                      tooltip: 'Profile',
                    ),
                    const SizedBox(width: 16),
                  ],
                ),

                // Main Content Area with Overlays
                Expanded(
                  child: Stack(
                    children: [
                      selectedIndex == 2
                          ? PetsManagementScreen(
                              initialTab: petsManagementInitialTab ?? 'All')
                          : _screens[selectedIndex],
                      if (isMessagesOpen)
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: Material(
                            elevation: 8,
                            color: Colors.white,
                            child: Column(
                              children: [
                                AppBar(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  automaticallyImplyLeading: false,
                                  title: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.black87, size: 28),
                                        onPressed: () {
                                          setState(() {
                                            isMessagesOpen = false;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Messages',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                const Expanded(
                                  child: MessagesScreen(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isNotificationsOpen)
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: Material(
                            elevation: 8,
                            color: Colors.white,
                            child: Column(
                              children: [
                                AppBar(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  automaticallyImplyLeading: false,
                                  title: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.black87, size: 28),
                                        onPressed: () {
                                          setState(() {
                                            isNotificationsOpen = false;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Notifications',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                const Expanded(
                                  child: NotificationsScreen(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isProfileOpen)
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: Material(
                            elevation: 8,
                            color: Colors.white,
                            child: Column(
                              children: [
                                AppBar(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  automaticallyImplyLeading: false,
                                  title: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.black87, size: 28),
                                        onPressed: () {
                                          setState(() {
                                            isProfileOpen = false;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Profile',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                const Expanded(
                                  child: ProfileScreen(),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation for Mobile
      bottomNavigationBar: !isDesktop && !isTablet
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people),
                  label: 'Users',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pets),
                  label: 'Pets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.track_changes),
                  label: 'Pet Tracker',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.announcement),
                  label: 'Announcements',
                ),
                NavigationDestination(
                  icon: Icon(Icons.badge),
                  label: 'Tanod',
                ),
                NavigationDestination(
                  icon: Icon(Icons.report),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
      ),
      title: isSidebarCollapsed
          ? null
          : Text(
              title,
              style: AppTheme.sidebarTextStyle.copyWith(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              ),
            ),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.1),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }

  Widget _getTitle(int index) {
    switch (index) {
      case 0:
        return const Text(
          'Dashboard Overview',
          style: TextStyle(color: Colors.white),
        );
      case 1:
        return const Text(
          'User Management',
          style: TextStyle(color: Colors.white),
        );
      case 2:
        return const Text(
          'Pets Management',
          style: TextStyle(color: Colors.white),
        );
      case 3:
        return const Text(
          'Pet Tracker Registration',
          style: TextStyle(color: Colors.white),
        );
      case 4:
        return const Text(
          'Live Tracker Map',
          style: TextStyle(color: Colors.white),
        );
      case 5:
        return const Text(
          'Post Announcement',
          style: TextStyle(color: Colors.white),
        );
      case 6:
        return const Text(
          'Create Tanod Accounts',
          style: TextStyle(color: Colors.white),
        );
      case 7:
        return const Text(
          'Tanod Reports',
          style: TextStyle(color: Colors.white),
        );
      case 8:
        return const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        );
      default:
        return const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        );
    }
  }
}
