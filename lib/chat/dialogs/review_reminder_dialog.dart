
import 'package:flutter/material.dart';

/// Opens a reminder picker.
/// Returns:
///   - int days: 1, 3, 7, 15, 30
///   - 0: Off
///   - null: Cancelled/closed
Future<int?> showReviewReminderDialog(
    BuildContext context, {
      int? initialDays, // pass `null` to preselect Off
    }) {
  // Represent options as strings: 'off','1','3','7','15','30'
  String choice = (initialDays == null || initialDays <= 0)
      ? 'off'
      : initialDays.toString();

  return showDialog<int>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Review Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Off'),
                value: 'off',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? 'off'),
              ),
              RadioListTile<String>(
                title: const Text('Daily'),
                value: '1',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? '1'),
              ),
              RadioListTile<String>(
                title: const Text('Every 3 days'),
                value: '3',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? '3'),
              ),
              RadioListTile<String>(
                title: const Text('Every 7 days'),
                value: '7',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? '7'),
              ),
              RadioListTile<String>(
                title: const Text('Every 15 days'),
                value: '15',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? '15'),
              ),
              RadioListTile<String>(
                title: const Text('Every 30 days'),
                value: '30',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? '30'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (choice == 'off') {
                  Navigator.of(context).pop(0); // Off
                } else {
                  Navigator.of(context).pop(int.tryParse(choice) ?? 0);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
}
