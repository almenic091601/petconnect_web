import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _horizontalScrollController.dispose();
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
          // Header with Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Search and Filter Bar
          _buildSearchAndFilterBar(),
          const SizedBox(height: 24),

          // Users Table
          Expanded(
            child: Card(
              elevation: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return User(
                      id: doc.id,
                      fullName: data['fullName'] ?? 'N/A',
                      email: data['email'] ?? 'N/A',
                      phoneNumber: data['phoneNumber'] ?? 'N/A',
                      accountType: data['accountType'] ?? 'User',
                      verificationStatus: (data['isVerified'] ?? false) == true
                          ? 'Verified'
                          : 'Pending',
                      status: (data['isBlocked'] ?? false) == true
                          ? 'Blocked'
                          : 'Active',
                      registeredDate:
                          (data['createdAt'] as Timestamp?)?.toDate() ??
                              DateTime.now(),
                      profileImageUrl: data['profileImageUrl'] ?? '',
                    );
                  }).toList();

                  return Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.depth == 0,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 48,
                          ),
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Profile')),
                              DataColumn(label: Text('Full Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Phone')),
                              DataColumn(label: Text('Account Type')),
                              DataColumn(label: Text('Verification')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Registered')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: users
                                .where((user) => _filterUser(user))
                                .toList()
                                .map((user) => DataRow(
                                      cells: [
                                        DataCell(
                                          Builder(
                                            builder: (context) {
                                              final imageUrl =
                                                  user.profileImageUrl;
                                              if (imageUrl.isNotEmpty) {
                                                return GestureDetector(
                                                  onTap: () =>
                                                      _showFullScreenImage(
                                                          context, imageUrl),
                                                  child: CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    backgroundImage:
                                                        NetworkImage(imageUrl),
                                                  ),
                                                );
                                              } else {
                                                // Fallback to initials
                                                final initials = user
                                                        .fullName.isNotEmpty
                                                    ? user.fullName
                                                        .split(' ')
                                                        .where(
                                                            (e) => e.isNotEmpty)
                                                        .map((e) => e[0])
                                                        .take(2)
                                                        .join()
                                                        .toUpperCase()
                                                    : '?';
                                                return CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor:
                                                      Colors.grey[200],
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        DataCell(Text(user.fullName)),
                                        DataCell(Text(user.email)),
                                        DataCell(Text(user.phoneNumber)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getAccountTypeColor(
                                                  user.accountType),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.accountType,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              Icon(
                                                user.verificationStatus ==
                                                        'Verified'
                                                    ? Icons.verified
                                                    : Icons.pending,
                                                color:
                                                    user.verificationStatus ==
                                                            'Verified'
                                                        ? Colors.green
                                                        : Colors.orange,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(user.verificationStatus),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getStatusColor(user.status),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.status,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(
                                            '${user.registeredDate.day}/${user.registeredDate.month}/${user.registeredDate.year}')),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.visibility),
                                                onPressed: () =>
                                                    _showUserDetails(user),
                                                tooltip: 'View Details',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteUser(user),
                                                tooltip: 'Delete User',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getUsersStream() {
    Query query = _firestore.collection('users');

    // Apply sorting
    switch (_selectedSort) {
      case 'Newest':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'Oldest':
        query = query.orderBy('createdAt', descending: false);
        break;
      case 'Name':
        query = query.orderBy('fullName', descending: false);
        break;
    }

    return query.snapshots();
  }

  bool _filterUser(User user) {
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      if (!user.fullName.toLowerCase().contains(searchTerm) &&
          !user.email.toLowerCase().contains(searchTerm) &&
          !user.phoneNumber.toLowerCase().contains(searchTerm)) {
        return false;
      }
    }

    switch (_selectedFilter) {
      case 'Active':
        return user.status == 'Active';
      case 'Verified':
        return user.verificationStatus == 'Verified';
      default:
        return true;
    }
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        final totalUsers = users.length;
        final activeUsers = users
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['isOnline'] == true)
            .length;
        final verifiedUsers = users
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['isVerified'] == true)
            .length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSummaryCard(
                'Total Users',
                totalUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Active Users',
                activeUsers.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Verified Users',
                verifiedUsers.toString(),
                Icons.verified,
                Colors.purple,
              ),
            ],
          ),
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
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
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
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _selectedFilter,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Users')),
            DropdownMenuItem(value: 'Active', child: Text('Active Users')),
            DropdownMenuItem(value: 'Verified', child: Text('Verified Users')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFilter = value!;
            });
          },
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _selectedSort,
          items: const [
            DropdownMenuItem(value: 'Newest', child: Text('Newest First')),
            DropdownMenuItem(value: 'Oldest', child: Text('Oldest First')),
            DropdownMenuItem(value: 'Name', child: Text('Name A-Z')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSort = value!;
            });
          },
        ),
      ],
    );
  }

  Color _getAccountTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'user':
        return Colors.blue;
      case 'vet':
        return Colors.green;
      case 'barangay staff':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'blocked':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showUserDetails(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.id).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    String addressString = '';
    if (userData['address'] != null) {
      if (userData['address'] is String) {
        addressString = userData['address'];
      } else if (userData['address'] is Map) {
        // Join all values in the address map into a single string
        addressString = (userData['address'] as Map).values.join(', ');
      } else {
        addressString = userData['address'].toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phoneNumber),
              _buildDetailRow('Account Type', user.accountType),
              _buildDetailRow('Verification Status', user.verificationStatus),
              _buildDetailRow('Account Status', user.status),
              _buildDetailRow('Registration Date',
                  '${user.registeredDate.day}/${user.registeredDate.month}/${user.registeredDate.year}'),
              if (addressString.isNotEmpty)
                _buildDetailRow('Address', addressString),
              if (userData['pets'] != null)
                _buildDetailRow(
                    'Number of Pets', userData['pets'].length.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editUser(User user) {
    // Implement edit user dialog with Firestore update
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content:
            const Text('Edit user functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement update logic
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete user's profile picture if exists
        if (user.profileImageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(user.profileImageUrl).delete();
          } catch (e) {
            print('Error deleting profile picture: $e');
          }
        }

        // Delete user document
        await _firestore.collection('users').doc(user.id).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 100, color: Colors.white),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String accountType;
  final String verificationStatus;
  final String status;
  final DateTime registeredDate;
  final String profileImageUrl;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.accountType,
    required this.verificationStatus,
    required this.status,
    required this.registeredDate,
    required this.profileImageUrl,
  });
}
