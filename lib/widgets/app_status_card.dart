import 'package:flutter/material.dart';

class AppStatusCard extends StatefulWidget {
  final String title;

  const AppStatusCard({
    super.key,
    required this.title,
  });

  @override
  State<AppStatusCard> createState() => _AppStatusCardState();
}

class _AppStatusCardState extends State<AppStatusCard> {
  bool _isActive = true;

  void _toggleStatus() {
    setState(() {
      _isActive = !_isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isActive ? 'Status: Active' : 'Status: Inactive',
              key: const Key('status_text'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('toggle_status_button'),
              onPressed: _toggleStatus,
              child: const Text('Toggle Status'),
            ),
          ],
        ),
      ),
    );
  }
}
