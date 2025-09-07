import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TanodAccountsScreen extends StatefulWidget {
  const TanodAccountsScreen({super.key});

  @override
  State<TanodAccountsScreen> createState() => _TanodAccountsScreenState();
}

class _TanodAccountsScreenState extends State<TanodAccountsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tanodIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _createTanod() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await FirebaseFirestore.instance.collection('tanod account').add({
        'tanodId': _tanodIdController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanod account created')),
        );
        _tanodIdController.clear();
        _passwordController.clear();
        _phoneController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 1000;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFormCard()),
                const SizedBox(width: 24),
                Expanded(child: _buildListCard()),
              ],
            )
          : Column(
              children: [
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildListCard(),
              ],
            ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Tanod Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tanodIdController,
                decoration: const InputDecoration(
                  labelText: 'Tanod ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Tanod ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.trim().length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createTanod,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        Text(_isSubmitting ? 'Creating...' : 'Create Account'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanod Accounts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tanod account')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('No tanod accounts yet.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.badge)),
                      title: Text(data['tanodId'] ?? ''),
                      subtitle: Text(
                        (data['password'] != null &&
                                (data['password'] as String).isNotEmpty)
                            ? 'Password set'
                            : 'No password',
                      ),
                      trailing: Switch(
                        value: (data['active'] as bool?) ?? true,
                        onChanged: (val) async {
                          await docs[index].reference.update({'active': val});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
