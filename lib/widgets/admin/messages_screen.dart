import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Message? _selectedMessage;
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  String _searchQuery = '';

  List<Message> get _filteredMessages {
    if (_searchQuery.isEmpty) {
      return _mockMessages;
    }
    return _mockMessages.where((message) {
      final searchLower = _searchQuery.toLowerCase();
      return message.sender.toLowerCase().contains(searchLower) ||
          message.subject.toLowerCase().contains(searchLower) ||
          message.preview.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _searchController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Messages List
              Expanded(
                flex: _selectedMessage == null ? 2 : 1,
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    // Messages List
                    Expanded(
                      child: _filteredMessages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredMessages.length,
                              itemBuilder: (context, index) {
                                final message = _filteredMessages[index];
                                final isSelected = _selectedMessage == message;
                                return Card(
                                  color:
                                      isSelected ? Colors.blue.shade50 : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: message.isRead
                                          ? Colors.grey[300]
                                          : Colors.blue,
                                      child: Text(
                                        message.sender[0].toUpperCase(),
                                        style: TextStyle(
                                          color: message.isRead
                                              ? Colors.black54
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      message.sender,
                                      style: TextStyle(
                                        fontWeight: message.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.subject,
                                          style: TextStyle(
                                            fontWeight: message.isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          message.preview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: message.isRead
                                                ? Colors.grey
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          message.time,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.isRead
                                                ? Colors.grey
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (!message.isRead)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedMessage = message;
                                        message.isRead = true;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Message Detail View
              if (_selectedMessage != null)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Message Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedMessage = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedMessage!.subject,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'From: ${_selectedMessage!.sender}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Message Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedMessage!.preview),
                                if (_selectedMessage!.replies.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Previous Replies',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...List.generate(
                                    _selectedMessage!.replies.length,
                                    (index) => Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.blue,
                                                child: Icon(
                                                  Icons.admin_panel_settings,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Admin',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    _selectedMessage!
                                                        .replies[index].time,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(_selectedMessage!
                                              .replies[index].content),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // Reply Input
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  focusNode: _replyFocusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Type your reply...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  maxLines: 3,
                                  minLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send),
                                color: Colors.blue,
                                onPressed: () {
                                  if (_replyController.text.trim().isNotEmpty) {
                                    setState(() {
                                      _selectedMessage!.replies.add(
                                        Reply(
                                          content: _replyController.text.trim(),
                                          time: 'Just now',
                                        ),
                                      );
                                      _replyController.clear();
                                    });
                                    _replyFocusNode.requestFocus();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class Message {
  final String sender;
  final String subject;
  final String preview;
  final String time;
  bool isRead;
  final List<Reply> replies;

  Message({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    required this.isRead,
    List<Reply>? replies,
  }) : replies = replies ?? [];
}

class Reply {
  final String content;
  final String time;

  Reply({
    required this.content,
    required this.time,
  });
}

final List<Message> _mockMessages = [
  Message(
    sender: "John Smith",
    subject: "Pet Registration Update",
    preview:
        "Hello Admin,\n\nI submitted a registration for my dog Max last week. Could you please check if everything is in order? I've attached all the required documents including vaccination records and microchip information.\n\nThanks,\nJohn",
    time: "10:30 AM",
    isRead: false,
    replies: [
      Reply(
        content:
            "Hi John, I've reviewed your application and everything looks good. Max's registration has been approved. You should receive a confirmation email shortly.",
        time: "10:45 AM",
      ),
    ],
  ),
  Message(
    sender: "Sarah Johnson",
    subject: "Vaccination Reminder",
    preview:
        "Dear Admin,\n\nI received a vaccination reminder for my cat Luna, but we just had her shots updated last month. Could you please check the records and update them accordingly?\n\nBest regards,\nSarah",
    time: "9:15 AM",
    isRead: false,
  ),
  Message(
    sender: "Vet Clinic",
    subject: "Appointment Confirmation",
    preview:
        "Hello,\n\nWe'd like to confirm the scheduled check-ups for next week. Please review the attached list of appointments and let us know if any adjustments are needed.\n\nBest regards,\nPet Connect Vet Clinic",
    time: "Yesterday",
    isRead: true,
    replies: [
      Reply(
        content:
            "Thank you for the schedule. Everything looks correct. We'll make sure to notify all pet owners about their upcoming appointments.",
        time: "Yesterday",
      ),
    ],
  ),
  Message(
    sender: "System Admin",
    subject: "New Feature Update",
    preview:
        "Hi Team,\n\nWe've rolled out new tracking features in the latest update. Please review the changes and let me know if you notice any issues.\n\nRegards,\nTech Team",
    time: "2 days ago",
    isRead: true,
  ),
];
