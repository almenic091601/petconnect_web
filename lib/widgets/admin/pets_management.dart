import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'package:universal_html/html.dart' as html;
import 'dart:ui' as ui;

class PetsManagementScreen extends StatefulWidget {
  final String initialTab;
  const PetsManagementScreen({super.key, required this.initialTab});

  @override
  State<PetsManagementScreen> createState() => _PetsManagementScreenState();
}

class _PetsManagementScreenState extends State<PetsManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  String _selectedPetType = 'All';
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;
  List<String> _ownerSuggestions = [];
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Set the initial tab based on the widget's initialTab parameter
    if (widget.initialTab == 'Pending') {
      _tabController.index = 1; // Index 1 is the Pending Requests tab
    } else if (widget.initialTab == 'Rejected') {
      _tabController.index = 2; // Index 2 is the Rejected Requests tab
    }

    // Initialize search suggestions
    _loadOwnerSuggestions();
  }

  void _loadOwnerSuggestions() {
    _firestore.collection('pets').snapshots().listen((snapshot) {
      final owners = snapshot.docs
          .map((doc) => (doc.data())['ownerName'] as String)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _ownerSuggestions = owners;
        _filteredSuggestions = owners;
      });
    });
  }

  void _filterSuggestions(String query) {
    setState(() {
      _filteredSuggestions = _ownerSuggestions
          .where((owner) => owner.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Summary Cards
            _buildSummaryCards(),
            const SizedBox(height: 24),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Registered Pets'),
                Tab(text: 'Pending Requests'),
                Tab(text: 'Rejected Requests'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Search and Filter Bar
            _buildSearchAndFilterBar(),
            const SizedBox(height: 24),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Registered Pets Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('pets').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final pets = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        // Handle date conversion
                        DateTime dateOfBirth;
                        try {
                          final birthDateData = data['dateOfBirth'];
                          if (birthDateData is Timestamp) {
                            dateOfBirth = birthDateData.toDate();
                          } else if (birthDateData is String) {
                            dateOfBirth = DateTime.parse(birthDateData);
                          } else {
                            dateOfBirth = DateTime.now();
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print('Error parsing date: $e');
                          }
                          dateOfBirth = DateTime.now();
                        }

                        return Pet(
                          id: doc.id,
                          name: data['name'] ?? 'N/A',
                          breed: data['breed'] ?? 'N/A',
                          type: data['type'] ?? 'Other',
                          ownerName: data['ownerName'] ?? 'N/A',
                          dateOfBirth: dateOfBirth,
                          location: data['location'] ?? 'N/A',
                          qrCode: data['qrCode'] ?? '',
                          vaccinationStatus:
                              data['vaccinationStatus'] ?? 'Unknown',
                          photo: data['photoUrl'] ?? '',
                        );
                      }).toList();

                      // Filter pets based on selected type
                      List<Pet> filteredPets = pets;
                      if (_selectedPetType != 'All') {
                        if (_selectedPetType == 'Other') {
                          filteredPets = pets
                              .where((pet) =>
                                  pet.type.toLowerCase() != 'dog' &&
                                  pet.type.toLowerCase() != 'cat')
                              .toList();
                        } else {
                          filteredPets = pets
                              .where((pet) =>
                                  pet.type.toLowerCase() ==
                                  _selectedPetType.toLowerCase())
                              .toList();
                        }
                      }

                      // Filter pets based on vaccination status
                      if (_selectedFilter != 'All') {
                        filteredPets = filteredPets.where((pet) {
                          if (_selectedFilter == 'Vaccinated') {
                            return pet.vaccinationStatus.toLowerCase() ==
                                'vaccinated';
                          } else if (_selectedFilter == 'Not Vaccinated') {
                            return pet.vaccinationStatus.toLowerCase() !=
                                'vaccinated';
                          }
                          return true;
                        }).toList();
                      }

                      // Sort pets based on selected sort option
                      switch (_selectedSort) {
                        case 'Newest':
                          filteredPets.sort(
                              (a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
                          break;
                        case 'Oldest':
                          filteredPets.sort(
                              (a, b) => a.dateOfBirth.compareTo(b.dateOfBirth));
                          break;
                        case 'Name':
                          filteredPets.sort((a, b) => a.name
                              .toLowerCase()
                              .compareTo(b.name.toLowerCase()));
                          break;
                      }

                      return _buildPetsTable(filteredPets);
                    },
                  ),
                  // Pending Requests Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('petRequests')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        if (kDebugMode) {
                          print('Firestore Error: ${snapshot.error}');
                        }
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No pending requests found'),
                        );
                      }

                      final requests = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return PetRegistrationRequest(
                          id: doc.id,
                          petName: data['petName'] ?? 'N/A',
                          ownerName: data['ownerName'] ?? 'N/A',
                          requestDate:
                              (data['createdAt'] as Timestamp?)?.toDate() ??
                                  DateTime.now(),
                          status: data['status'] ?? 'pending',
                          documents: const [],
                        );
                      }).toList();
                      return _buildRequestsTable(requests, 'Pending');
                    },
                  ),
                  // Rejected Requests Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('petRequests')
                        .where('status', isEqualTo: 'rejected')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final requests = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return PetRegistrationRequest(
                          id: doc.id,
                          petName: data['petName'] ?? 'N/A',
                          ownerName: data['ownerName'] ?? 'N/A',
                          requestDate:
                              (data['requestDate'] as Timestamp?)?.toDate() ??
                                  DateTime.now(),
                          status: data['status'] ?? 'Rejected',
                          documents: (data['documents'] as List<dynamic>?)
                                  ?.map((e) => e.toString())
                                  .toList() ??
                              [],
                        );
                      }).toList();
                      return _buildRequestsTable(requests, 'Rejected');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('pets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pets = snapshot.data!.docs;
        final totalPets = pets.length;
        final dogs = pets
            .where(
                (pet) => (pet.data() as Map<String, dynamic>)['type'] == 'Dog')
            .length;
        final cats = pets
            .where(
                (pet) => (pet.data() as Map<String, dynamic>)['type'] == 'Cat')
            .length;
        final others = pets.where((pet) {
          final type = (pet.data() as Map<String, dynamic>)['type'];
          return type != 'Dog' && type != 'Cat';
        }).length;
        final vaccinated = pets
            .where((pet) =>
                (pet.data() as Map<String, dynamic>)['vaccinationStatus'] ==
                'Vaccinated')
            .length;

        return Row(
          children: [
            _buildSummaryCard(
              'Registered Pets',
              totalPets.toString(),
              Icons.pets,
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Dogs',
              dogs.toString(),
              Icons.pets,
              Colors.brown,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Cats',
              cats.toString(),
              Icons.pets,
              Colors.grey,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Others',
              others.toString(),
              Icons.pets,
              Colors.purple,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Vaccinated',
              vaccinated.toString(),
              Icons.medical_services,
              Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
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
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search by owner name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      _filterSuggestions(value);
                      setState(() {
                        _showSuggestions = value.isNotEmpty;
                      });
                    },
                    onTap: () {
                      setState(() {
                        _showSuggestions = _searchController.text.isNotEmpty;
                      });
                    },
                  ),
                  if (_showSuggestions)
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredSuggestions.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_filteredSuggestions[index]),
                                onTap: () {
                                  setState(() {
                                    _searchController.text =
                                        _filteredSuggestions[index];
                                    _showSuggestions = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedPetType,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Types')),
                DropdownMenuItem(value: 'Dog', child: Text('Dogs')),
                DropdownMenuItem(value: 'Cat', child: Text('Cats')),
                DropdownMenuItem(value: 'Other', child: Text('Others')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPetType = value!;
                });
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedFilter,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Pets')),
                DropdownMenuItem(
                    value: 'Vaccinated', child: Text('Vaccinated')),
                DropdownMenuItem(
                    value: 'Not Vaccinated', child: Text('Not Vaccinated')),
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
        ),
      ],
    );
  }

  Color _getPetTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return Colors.brown;
      case 'cat':
        return Colors.grey;
      case 'bird':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  Color _getVaccinationColor(String status) {
    switch (status.toLowerCase()) {
      case 'up-to-date':
        return Colors.green;
      case 'not updated':
        return Colors.red;
      case 'partial':
        return const Color.fromARGB(255, 0, 255, 4);
      default:
        return Colors.grey;
    }
  }

  void _showPetDetails(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pet Details: ${pet.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile image row only
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 200.0),
                    child: FutureBuilder<Widget>(
                      future: _buildPetAvatar(pet.photo),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final avatar = snapshot.data ?? const Icon(Icons.pets);
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(context, pet.photo),
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: avatar,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Name', pet.name),
              _buildDetailRow('Breed', pet.breed),
              _buildDetailRow('Type', pet.type),
              _buildDetailRow('Owner', pet.ownerName),
              _buildDetailRow('Date of Birth',
                  '${pet.dateOfBirth.day}/${pet.dateOfBirth.month}/${pet.dateOfBirth.year}'),
              _buildDetailRow('Location', pet.location),
              Padding(
                padding: const EdgeInsets.only(right: 50.0),
                child: _buildDetailRow('QR/Tag ID', pet.qrCode),
              ),
              _buildDetailRow('Vaccination Status', pet.vaccinationStatus),
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
            child: label == 'QR/Tag ID' && value.isNotEmpty
                ? Image.network(
                    value,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.qr_code, size: 48, color: Colors.grey),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  void _deletePet(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text(
            'Are you sure you want to delete ${pet.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete the pet document from Firestore
                await _firestore.collection('pets').doc(pet.id).delete();

                // If there's a photo in storage, delete it
                if (pet.photo.isNotEmpty) {
                  try {
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('pet_images/${pet.photo}');
                    await ref.delete();
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error deleting pet photo: $e');
                    }
                  }
                }

                // Also delete any associated requests
                final requestsSnapshot = await _firestore
                    .collection('petRequests')
                    .where('petName', isEqualTo: pet.name)
                    .where('ownerName', isEqualTo: pet.ownerName)
                    .get();

                for (var doc in requestsSnapshot.docs) {
                  await doc.reference.delete();
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${pet.name} has been deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting pet: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showQrCodeActions(
      BuildContext context, String qrCodeUrl, String petName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$petName\'s QR Code',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  qrCodeUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 40),
                          SizedBox(height: 8),
                          Text('Failed to load QR code'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Download the QR code image from the URL
                        html.AnchorElement(href: qrCodeUrl)
                          ..setAttribute('download', '${petName}_QR_Code.png')
                          ..click();
                        // Optionally show a success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR code downloaded successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error downloading QR code: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download QR Code'),
                  ),
ElevatedButton.icon(
  onPressed: () {
    try {
      // Create a hidden iframe
      final iframe = html.IFrameElement()
        ..style.display = 'none'
        ..srcdoc = '''
          <html>
            <head>
              <title>Print QR Code</title>
              <style>
                body {
                  margin: 0;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  height: 100vh;
                }
                img {
                  max-width: 80%;
                  max-height: 80%;
                }
              </style>
            </head>
            <body>
              <img src="$qrCodeUrl" onload="window.print();">
            </body>
          </html>
        ''';

      // Add iframe to the DOM
      html.document.body?.append(iframe);

      // Remove iframe after printing
      iframe.onLoad.listen((_) {
        Future.delayed(const Duration(seconds: 2), () {
          iframe.remove();
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  icon: const Icon(Icons.print),
  label: const Text('Print QR Code'),
),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetsTable(List<Pet> pets) {
    return Card(
      elevation: 2,
      child: Scrollbar(
        thumbVisibility: true,
        controller: _scrollController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Photo')),
              DataColumn(label: Text('Pet Name')),
              DataColumn(label: Text('Breed')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Owner')),
              DataColumn(label: Text('DOB')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('QR Code')),
              DataColumn(label: Text('Vaccination')),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: pets.map((pet) {
              String formattedDate;
              try {
                formattedDate =
                    '${pet.dateOfBirth.day}/${pet.dateOfBirth.month}/${pet.dateOfBirth.year}';
              } catch (e) {
                formattedDate = 'Invalid Date';
              }

              return DataRow(
                cells: [
                  DataCell(
                    pet.photo.isNotEmpty
                        ? GestureDetector(
                            onTap: () =>
                                _showFullScreenImage(context, pet.photo),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: NetworkImage(pet.photo),
                            ),
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.pets, color: Colors.grey),
                          ),
                  ),
                  DataCell(Text(pet.name)),
                  DataCell(Text(pet.breed)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPetTypeColor(pet.type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pet.type,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  DataCell(Text(pet.ownerName)),
                  DataCell(Text(formattedDate)),
                  DataCell(
                    SizedBox(
                      width: 400,
                      child: Text(pet.location),
                    ),
                  ),
                  DataCell(
                    pet.qrCode.isNotEmpty
                        ? InkWell(
                            onTap: () => _showQrCodeActions(
                                context, pet.qrCode, pet.name),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  pet.qrCode,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.qr_code,
                                          color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            ),
                          )
                        : const Icon(Icons.qr_code, color: Colors.grey),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getVaccinationColor(pet.vaccinationStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pet.vaccinationStatus,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _showPetDetails(pet),
                          tooltip: 'View Details',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePet(pet),
                          tooltip: 'Delete Pet',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsTable(
      List<PetRegistrationRequest> requests, String status) {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Request ID')),
            DataColumn(label: Text('Pet Name')),
            DataColumn(label: Text('Owner')),
            DataColumn(label: Text('Request Date')),
            DataColumn(label: Text('Documents')),
            DataColumn(label: Text('Actions')),
          ],
          rows: requests
              .map((request) => DataRow(
                    cells: [
                      DataCell(Text(request.id)),
                      DataCell(Text(request.petName)),
                      DataCell(Text(request.ownerName)),
                      DataCell(Text(
                          '${request.requestDate.day}/${request.requestDate.month}/${request.requestDate.year}')),
                      DataCell(
                        Wrap(
                          spacing: 4,
                          children: request.documents
                              .map((doc) => Chip(
                                    label: Text(doc),
                                    backgroundColor:
                                        Colors.blue.withOpacity(0.1),
                                  ))
                              .toList(),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            if (status == 'Pending') ...[
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _acceptRequest(request),
                                tooltip: 'Accept Request',
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectRequest(request),
                                tooltip: 'Reject Request',
                              ),
                            ] else if (status == 'Rejected') ...[
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _acceptRequest(request),
                                tooltip: 'Accept Request',
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRequest(request),
                                tooltip: 'Delete Request',
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewRequestDetails(request),
                              tooltip: 'View Details',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _acceptRequest(PetRegistrationRequest request) async {
    try {
      // Get the request data
      final requestDoc =
          await _firestore.collection('petRequests').doc(request.id).get();
      final requestData = requestDoc.data() as Map<String, dynamic>;

      // Convert the birthDate string to Timestamp
      DateTime birthDate;
      try {
        birthDate = DateTime.parse(requestData['birthDate'] as String);
      } catch (e) {
        birthDate = DateTime.now();
      }

      // Format the QR code data in a structured way
      final formattedData = '''
Pet ID: ${request.id}
Pet Name: ${requestData['petName']}
Owner: ${requestData['ownerName']}
Type: ${requestData['petType']}
Breed: ${requestData['breed']}
Birth Date: ${birthDate.toIso8601String().split('T')[0]}
Vaccination: ${requestData['isVaccinated'] ? 'Vaccinated' : 'Not Vaccinated'}
''';

      // Generate QR code image
      final qrCode = QrCode.fromData(
        data: formattedData,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );

      // Set the size for the QR code image (smaller, e.g., 256)
      const double size = 256.0;

      // Create a recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white background
      final paint = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), paint);

      // Draw the QR code on top
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        gapless: true,
      );
      painter.paint(canvas, const Size(size, size));

      // Convert to image
      final image =
          await recorder.endRecording().toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to generate QR code image');
      final imageData = byteData.buffer.asUint8List();

      // Upload QR code image to Firebase Storage
      final qrCodeRef = FirebaseStorage.instance.ref().child(
          'qr_codes/${request.id}_${DateTime.now().millisecondsSinceEpoch}.png');

      await qrCodeRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/png'),
      );

      // Get the download URL
      final qrCodeUrl = await qrCodeRef.getDownloadURL();

      // Create a new pet document with QR code
      await _firestore.collection('pets').add({
        'name': requestData['petName'],
        'ownerName': requestData['ownerName'],
        'type': requestData['petType'],
        'breed': requestData['breed'],
        'dateOfBirth': Timestamp.fromDate(birthDate),
        'location': requestData['ownerAddress'],
        'qrCode': qrCodeUrl,
        'qrData': formattedData, // Store the formatted data
        'vaccinationStatus':
            requestData['isVaccinated'] ? 'Vaccinated' : 'Not Vaccinated',
        'photoUrl': requestData['imageUrl'],
        'gender': requestData['gender'],
        'weight': requestData['weight'],
        'registrationDate': Timestamp.now(),
      });

      // Update the request status to 'accepted'
      await _firestore.collection('petRequests').doc(request.id).update({
        'status': 'accepted',
        'processedDate': Timestamp.now(),
        'qrCodeUrl': qrCodeUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Pet registration request accepted and QR code generated')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting request: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $e')),
      );
    }
  }

  void _rejectRequest(PetRegistrationRequest request) async {
    try {
      // Update the request status to 'rejected'
      await _firestore.collection('petRequests').doc(request.id).update({
        'status': 'rejected',
        'processedDate': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet registration request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
  }

  void _viewRequestDetails(PetRegistrationRequest request) {
    // Implement view request details
  }

  void _deleteRequest(PetRegistrationRequest request) async {
    try {
      // Delete the request from Firestore
      await _firestore.collection('petRequests').doc(request.id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet registration request deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting request: $e')),
      );
    }
  }

  Future<Widget> _buildPetAvatar(String photoUrl) async {
    if (kDebugMode) {
      print('Original photo URL: $photoUrl');
    }

    if (photoUrl.isEmpty) {
      if (kDebugMode) {
        print('Empty photo URL, showing default icon');
      }
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.pets, color: Colors.grey),
      );
    }

    try {
      String downloadUrl;

      if (!photoUrl.startsWith('http')) {
        final ref =
            FirebaseStorage.instance.ref().child('pet_images/$photoUrl');
        downloadUrl = await ref.getDownloadURL();
      } else {
        downloadUrl = photoUrl;
      }

      if (kDebugMode) {
        print('Using download URL: $downloadUrl');
      }

      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: Image.network(
            downloadUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator();
            },
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                print('Error loading image: $error');
              }
              if (kDebugMode) {
                print('Failed URL: $downloadUrl');
              }
              return const Icon(Icons.pets, color: Colors.grey);
            },
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing image URL: $e');
      }
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.pets, color: Colors.grey),
      );
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
                    const Icon(Icons.pets, size: 100, color: Colors.white),
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

class Pet {
  final String id;
  final String name;
  final String breed;
  final String type;
  final String ownerName;
  final DateTime dateOfBirth;
  final String location;
  final String qrCode;
  final String vaccinationStatus;
  final String photo;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.type,
    required this.ownerName,
    required this.dateOfBirth,
    required this.location,
    required this.qrCode,
    required this.vaccinationStatus,
    required this.photo,
  });
}

class PetRegistrationRequest {
  final String id;
  final String petName;
  final String ownerName;
  final DateTime requestDate;
  final String status;
  final List<String> documents;

  PetRegistrationRequest({
    required this.id,
    required this.petName,
    required this.ownerName,
    required this.requestDate,
    required this.status,
    required this.documents,
  });
}
