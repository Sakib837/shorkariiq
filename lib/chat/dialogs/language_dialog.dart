
import 'package:flutter/material.dart';

Future<String?> showLanguageDialog(BuildContext context, {String initial = 'en'}) {
  String choice = initial; // 'en' or 'bn'
  return showDialog<String>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Language for Chat & Explanations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? 'en'),
              ),
              RadioListTile<String>(
                title: const Text('বাংলা (Bangla)'),
                value: 'bn',
                groupValue: choice,
                onChanged: (v) => setStateDialog(() => choice = v ?? 'bn'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(choice),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
}
