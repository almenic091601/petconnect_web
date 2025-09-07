import 'package:flutter/material.dart';
import 'package:petconnect/widgets/admin/document_editor.dart';
import 'package:petconnect/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCategory = 'Theme';

  @override
  void initState() {
    super.initState();
    _loadLegalDocs();
  }

  Future<void> _loadLegalDocs() async {
    // Implementation of _loadLegalDocs method
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings Categories
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Settings Navigation
                Card(
                  child: SizedBox(
                    width: 250,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildSettingsCategory(
                          icon: Icons.palette,
                          title: 'Theme',
                        ),
                        _buildSettingsCategory(
                          icon: Icons.gavel,
                          title: 'Terms & Legal',
                        ),
                        _buildSettingsCategory(
                          icon: Icons.logout,
                          title: 'Logout',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Right side - Settings Content
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: _buildSettingsContent(themeProvider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(ThemeProvider themeProvider) {
    switch (_selectedCategory) {
      case 'Theme':
        return _buildThemeSettings(themeProvider);
      case 'Terms & Legal':
        return _buildTermsLegal();
      case 'Logout':
        return _buildLogoutConfirmation();
      default:
        return _buildThemeSettings(themeProvider);
    }
  }

  Widget _buildThemeSettings(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermsLegal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Terms & Legal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingSection(
          title: 'Legal Documents',
          children: [
            Card(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('terms_of_service')
                    .doc('current')
                    .snapshots(),
                builder: (context, snapshot) {
                  String content = 'Loading...';
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    content = (snapshot.data!.data()
                            as Map<String, dynamic>)['content'] ??
                        'No Terms of Service set.';
                  }
                  return ListTile(
                    title: const Text('Terms of Service'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Text(content),
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      _openDocumentEditor(
                        'Terms of Service',
                        content,
                        (newContent) async {
                          await FirebaseFirestore.instance
                              .collection('terms_of_service')
                              .doc('current')
                              .set({
                            'content': newContent,
                            'updatedAt': FieldValue.serverTimestamp()
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Terms of Service updated in Firestore')),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Card(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('privacy_policy')
                    .doc('current')
                    .snapshots(),
                builder: (context, snapshot) {
                  String content = 'Loading...';
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    content = (snapshot.data!.data()
                            as Map<String, dynamic>)['content'] ??
                        'No Privacy Policy set.';
                  }
                  return ListTile(
                    title: const Text('Privacy Policy'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Text(content),
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      _openDocumentEditor(
                        'Privacy Policy',
                        content,
                        (newContent) async {
                          await FirebaseFirestore.instance
                              .collection('privacy_policy')
                              .doc('current')
                              .set({
                            'content': newContent,
                            'updatedAt': FieldValue.serverTimestamp()
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Privacy Policy updated in Firestore')),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openDocumentEditor(
    String title,
    String initialContent,
    Function(String) onSave,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentEditor(
          title: title,
          initialContent: initialContent,
          onSave: onSave,
        ),
      ),
    );
  }

  Widget _buildLogoutConfirmation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.logout,
            size: 64,
            color: Color.fromARGB(255, 60, 244, 54),
          ),
          const SizedBox(height: 24),
          const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You will be redirected to the login screen.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'Theme';
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: _logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCategory({
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedCategory == title;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildProfileNavigation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Profile Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Click the button below to manage your profile',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.person),
            label: const Text('Go to Profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to logout')),
        );
      }
    }
  }
}
