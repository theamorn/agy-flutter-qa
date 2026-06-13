import 'package:flutter/material.dart';

/// Placeholder shown for tabs 2–5. The features behind them are not built yet,
/// so we tell the user plainly rather than showing a broken/empty screen.
class InProgressTab extends StatelessWidget {
  const InProgressTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'This section is in progress.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
