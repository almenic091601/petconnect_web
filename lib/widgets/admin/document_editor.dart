import 'package:flutter/material.dart';

class DocumentEditor extends StatefulWidget {
  final String title;
  final String initialContent;
  final Function(String) onSave;

  const DocumentEditor({
    super.key,
    required this.title,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter content here...',
          ),
        ),
      ),
    );
  }
}
