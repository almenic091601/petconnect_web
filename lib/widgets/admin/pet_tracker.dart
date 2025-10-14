import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetTrackerScreen extends StatefulWidget {
  const PetTrackerScreen({super.key});

  @override
  State<PetTrackerScreen> createState() => _PetTrackerScreenState();
}

class _PetTrackerScreenState extends State<PetTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLocationTrackingEnabled = false;
  DateTime _registrationDate = DateTime.now();

  // Mock data for recent registrations

  final List<String> _deviceTypes = ['GPS', 'RFID', 'Bluetooth'];
  final List<String> _statusOptions = [
    'Active',
    'Inactive',
    'Lost',
    'Maintenance'
  ];

  // Form controllers
  final TextEditingController _trackerIdController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedPet;
  String? _selectedDeviceType;
  String? _selectedStatus;

  @override
  void dispose() {
    _trackerIdController.dispose();
    _modelNameController.dispose();
    _manufacturerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchPets() async {
    final snapshot = await FirebaseFirestore.instance.collection('pets').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'breed': data['breed'] ?? '',
        'owner': data['ownerName'] ?? '',
        'photo': data['photoUrl'] ?? '',
      };
    }).toList();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement form submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing Registration...')),
      );
    }
  }

  void _handleReset() {
    setState(() {
      _formKey.currentState?.reset();
      _trackerIdController.clear();
      _modelNameController.clear();
      _manufacturerController.clear();
      _notesController.clear();
      _selectedPet = null;
      _selectedDeviceType = null;
      _selectedStatus = null;
      _isLocationTrackingEnabled = false;
      _registrationDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Registration Form
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildPetSelection(),
                    const SizedBox(height: 24),
                    _buildTrackerDeviceInfo(),
                    const SizedBox(height: 24),
                    _buildLinkingInfo(),
                    const SizedBox(height: 24),
                    _buildAttachments(),
                    const SizedBox(height: 24),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
          // Right side - Recent Registrations
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Registrations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTrackedPetsList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Register New Tracker',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPetSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🐾 Pet Selection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No pets found.');
                }
                final pets = snapshot.data!;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedPet,
                  decoration: const InputDecoration(
                    labelText: 'Select Pet *',
                    border: OutlineInputBorder(),
                  ),
                  items: pets.map((pet) {
                    return DropdownMenuItem<String>(
                      value: pet['id'] as String,
                      child: Row(
                        children: [
                          (pet['photo'] as String).isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(pet['photo']),
                                  radius: 16,
                                )
                              : CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[200],
                                  child: const Icon(Icons.pets,
                                      color: Colors.grey),
                                ),
                          const SizedBox(width: 8),
                          Text('${pet['name']} (${pet['breed']})'),
                          const SizedBox(width: 8),
                          Text(
                            '- Owner: ${pet['owner']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPet = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a pet' : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerDeviceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🆔 Tracker Device Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trackerIdController,
              decoration: const InputDecoration(
                labelText: 'Tracker ID / Serial Number *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'This field is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDeviceType,
              decoration: const InputDecoration(
                labelText: 'Device Type',
                border: OutlineInputBorder(),
              ),
              items: _deviceTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedDeviceType = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelNameController,
              decoration: const InputDecoration(
                labelText: 'Model Name / Version',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(
                labelText: 'Manufacturer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _registrationDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _registrationDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Registration Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_registrationDate.day}/${_registrationDate.month}/${_registrationDate.year}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔗 Linking Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              enabled: false,
              initialValue: 'admin@petconnect.com', // TODO: Get from auth
              decoration: const InputDecoration(
                labelText: 'Assigned By',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Location Tracking Enabled'),
              value: _isLocationTrackingEnabled,
              onChanged: (bool value) {
                setState(() => _isLocationTrackingEnabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📁 Optional Attachments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement file upload
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Device Certificate / Warranty'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes / Remarks',
                border: OutlineInputBorder(),
                hintText: 'Add any additional notes here...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.save),
                label: const Text('Save / Register Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _handleReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackedPetsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trackers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No tracked pets found.');
        }
        final pets = snapshot.data!.docs;
        return ListView.separated(
          itemCount: pets.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final pet = pets[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          _getStatusColor((pet['status'] ?? '').toString())
                              .withOpacity(0.1),
                      child: const Icon(Icons.pets),
                    ),
                    if ((pet['batteryLevel'] ?? 100) < 20)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.battery_alert,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(pet['petName'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Owner: ${pet['owner'] ?? ''}'),
                    Text('Last seen: ${pet['lastSeen'] ?? ''}'),
                    Row(
                      children: [
                        Icon(
                          Icons.battery_full,
                          size: 16,
                          color: _getBatteryColor(
                              (pet['batteryLevel'] ?? 100) as int),
                        ),
                        const SizedBox(width: 4),
                        Text('${pet['batteryLevel'] ?? 100}%'),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.location_searching),
                  onPressed: () {
                    // TODO: Implement center map on pet location
                  },
                  tooltip: 'Locate',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'lost':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel < 20) {
      return Colors.red;
    } else if (batteryLevel < 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
