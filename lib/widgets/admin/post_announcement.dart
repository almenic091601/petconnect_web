import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({super.key});

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'General';
  String _selectedPriority = 'Normal';
  bool _isPinned = false;
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedRecipients = ['All Users'];
  List<String> _attachments = [];

  // Mock data for existing announcements

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: isWideScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildAnnouncementForm(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: _buildAnnouncementsList(),
                ),
              ],
            )
          : Column(
              children: [
                _buildAnnouncementForm(),
                const SizedBox(height: 24),
                _buildAnnouncementsList(),
              ],
            ),
    );
  }

  Widget _buildAnnouncementForm() {
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
                'Create New Announcement',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter announcement content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type and Priority
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'General', child: Text('General')),
                        DropdownMenuItem(
                            value: 'Health', child: Text('Health')),
                        DropdownMenuItem(
                            value: 'System', child: Text('System')),
                        DropdownMenuItem(value: 'Event', child: Text('Event')),
                        DropdownMenuItem(
                            value: 'Emergency', child: Text('Emergency')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(
                            value: 'Normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(
                            value: 'Urgent', child: Text('Urgent')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date and Pin
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 200,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: CheckboxListTile(
                      title: const Text('Pin Announcement'),
                      value: _isPinned,
                      onChanged: (value) {
                        setState(() {
                          _isPinned = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recipients
              const Text('Recipients:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All Users'),
                    selected: _selectedRecipients.contains('All Users'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRecipients.add('All Users');
                        } else {
                          _selectedRecipients.remove('All Users');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Pet Owners'),
                    selected: _selectedRecipients.contains('Pet Owners'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRecipients.add('Pet Owners');
                        } else {
                          _selectedRecipients.remove('Pet Owners');
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Attachments
              const Text('Attachments:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._attachments.map((file) => Chip(
                        label: Text(file),
                        onDeleted: () {
                          setState(() {
                            _attachments.remove(file);
                          });
                        },
                      )),
                  TextButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Attachment'),
                    onPressed: () async {
                      final uploadInput = html.FileUploadInputElement();
                      uploadInput.click();
                      uploadInput.onChange.listen((e) {
                        final file = uploadInput.files?.first;
                        if (file != null) {
                          setState(() {
                            _attachments.add(file.name);
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAnnouncement,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Post Announcement'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Announcements',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Text('No announcements yet.');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(
                      _getAnnouncementIcon(data['type'] ?? 'General'),
                      color: _getPriorityColor(data['priority'] ?? 'Normal'),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (data['isPinned'] == true)
                          const Icon(Icons.push_pin, size: 16),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['content'] ?? ''),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(data['type'] ?? ''),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                            Chip(
                              label: Text(data['priority'] ?? ''),
                              backgroundColor: _getPriorityColor(
                                      data['priority'] ?? 'Normal')
                                  .withOpacity(0.1),
                            ),
                            ...(data['recipients'] as List<dynamic>? ?? [])
                                .map((recipient) => Chip(
                                      label: Text(recipient.toString()),
                                      backgroundColor:
                                          Colors.green.withOpacity(0.1),
                                    )),
                          ],
                        ),
                        if ((data['attachments'] as List<dynamic>? ?? [])
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (data['attachments'] as List<dynamic>)
                                .map((file) => Chip(
                                      label: Text(file.toString()),
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.1),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                        PopupMenuItem(
                          value: data['isPinned'] == true ? 'unpin' : 'pin',
                          child:
                              Text(data['isPinned'] == true ? 'Unpin' : 'Pin'),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showEditAnnouncementDialog(doc.id, data);
                        } else if (value == 'delete') {
                          await FirebaseFirestore.instance
                              .collection('announcements')
                              .doc(doc.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Announcement deleted.')),
                          );
                        } else if (value == 'pin' || value == 'unpin') {
                          await FirebaseFirestore.instance
                              .collection('announcements')
                              .doc(doc.id)
                              .update({
                            'isPinned': value == 'pin',
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(value == 'pin'
                                    ? 'Announcement pinned.'
                                    : 'Announcement unpinned.')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showEditAnnouncementDialog(String docId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final contentController =
        TextEditingController(text: data['content'] ?? '');
    String type = data['type'] ?? 'General';
    String priority = data['priority'] ?? 'Normal';
    bool isPinned = data['isPinned'] ?? false;
    DateTime date = (data['date'] is Timestamp)
        ? (data['date'] as Timestamp).toDate()
        : (data['date'] ?? DateTime.now());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('General')),
                  DropdownMenuItem(value: 'Health', child: Text('Health')),
                  DropdownMenuItem(value: 'System', child: Text('System')),
                  DropdownMenuItem(value: 'Event', child: Text('Event')),
                  DropdownMenuItem(
                      value: 'Emergency', child: Text('Emergency')),
                ],
                onChanged: (value) => type = value!,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                ],
                onChanged: (value) => priority = value!,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Pin Announcement'),
                value: isPinned,
                onChanged: (value) => isPinned = value ?? false,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    date = picked;
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text('${date.day}/${date.month}/${date.year}'),
                ),
              ),
              const SizedBox(height: 8),
              // Recipients and attachments editing can be added here if needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('announcements')
                  .doc(docId)
                  .update({
                'title': titleController.text,
                'content': contentController.text,
                'type': type,
                'priority': priority,
                'isPinned': isPinned,
                'date': date,
                // Optionally update recipients and attachments
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _submitAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      final announcementData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'type': _selectedType,
        'priority': _selectedPriority,
        'date': _selectedDate,
        'isPinned': _isPinned,
        'recipients': _selectedRecipients,
        'attachments': _attachments,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('announcements')
          .add(announcementData);

      setState(() {
        _titleController.clear();
        _contentController.clear();
        _selectedType = 'General';
        _selectedPriority = 'Normal';
        _isPinned = false;
        _selectedDate = DateTime.now();
        _selectedRecipients = ['All Users'];
        _attachments = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted successfully!')),
      );
    }
  }

  IconData _getAnnouncementIcon(String type) {
    switch (type) {
      case 'Health':
        return Icons.medical_services;
      case 'System':
        return Icons.computer;
      case 'Event':
        return Icons.event;
      case 'Emergency':
        return Icons.warning;
      default:
        return Icons.announcement;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Normal':
        return Colors.blue;
      case 'High':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type;
  final String priority;
  final DateTime date;
  final bool isPinned;
  final List<String> recipients;
  final List<String> attachments;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.date,
    required this.isPinned,
    required this.recipients,
    required this.attachments,
  });
}
