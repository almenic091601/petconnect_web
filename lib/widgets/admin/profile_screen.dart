import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  Uint8List? _profileImageBytes; // For web
  String? _profileImageUrl;
  String? _profileImageName; // For web
  bool _isLoading = false;
  bool isEditing = false;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('admins').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _profileImageUrl = data['profileImage'];
          _profileImageBytes = null;
          _profileImageName = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _profileImageBytes = result.files.single.bytes;
        _profileImageName = result.files.single.name;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_profileImageBytes == null || _profileImageName == null) return null;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(
              '${DateTime.now().millisecondsSinceEpoch}_$_profileImageName');
      await storageRef.putData(_profileImageBytes!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Upload image if selected
      if (_profileImageBytes != null) {
        _profileImageUrl = await _uploadImage();
      }

      await _firestore.collection('admins').doc(user.uid).set({
        'name': _nameController.text,
        'email': user.email,
        'phone': _phoneController.text,
        if (_profileImageUrl != null) 'profileImage': _profileImageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return false;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return false;
    }
    return true;
  }

  void _cancelChanges() {
    _loadProfileData();
    setState(() {
      _profileImageBytes = null;
      _profileImageName = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isEditing ? _buildEditProfileForm() : _buildProfileView(),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!)
                          as ImageProvider<Object>?
                      : null,
                  child: _profileImageBytes == null
                      ? ClipOval(
                          child: _profileImageUrl != null
                              ? Image.network(
                                  _profileImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(width: 48),
            // Profile Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField('Full Name', _nameController.text),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Email', _emailController.text),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Phone Number', _phoneController.text),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                isEditing = true;
                              });
                            },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value.isNotEmpty ? value : '-',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                              as ImageProvider<Object>?
                          : null,
                      child: _profileImageBytes == null
                          ? ClipOval(
                              child: _profileImageUrl != null
                                  ? Image.network(
                                      _profileImageUrl!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                            )
                          : null,
                    ),
                    if (_isLoading)
                      const Positioned.fill(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Photo'),
                ),
              ],
            ),
            const SizedBox(width: 48),
            // Profile Form
            Expanded(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Email is read-only
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    isEditing = false;
                                    _cancelChanges();
                                  });
                                },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  await _saveProfile();
                                  setState(() {
                                    isEditing = false;
                                  });
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
