
import 'package:flutter/material.dart';

Future<void> showUserMenuSheet(
    BuildContext context, {
      String? username,
      String? languageLabel, // NEW
      required VoidCallback onSetReminder,
      required VoidCallback onChangeLanguage, // NEW
      required VoidCallback onViewProgress,
      required VoidCallback onLogout,
    }) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (username != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Logged in as: $username",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Change Language (English / বাংলা)"),
            subtitle: Text(languageLabel ?? ''),
            onTap: () {
              Navigator.of(context).pop();
              onChangeLanguage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text("Set Review Reminder"),
            onTap: () {
              Navigator.of(context).pop();
              onSetReminder();
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("View Progress Details"),
            onTap: () {
              Navigator.of(context).pop();
              onViewProgress();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout / Change User"),
            onTap: () {
              Navigator.of(context).pop();
              onLogout();
            },
          ),
        ],
      ),
    ),
  );
}
