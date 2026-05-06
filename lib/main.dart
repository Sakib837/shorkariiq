import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'notification_service.dart';
import 'user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await UserService.loadUsers();
  
  runApp(const ShorkariIQ());
}

class ShorkariIQ extends StatefulWidget {
  const ShorkariIQ({super.key});
  @override
  State<ShorkariIQ> createState() => _ShorkariIQState();
}

class _ShorkariIQState extends State<ShorkariIQ> {
  bool _loggedIn = false;

  void _handleLoginSuccess() async {
    setState(() => _loggedIn = true);
    // if the user has a reminder set, ensure it’s scheduled
    final u = UserService.currentUser;
    if (u != null && (u.reminderDays ?? 0) > 0) {
      await NotificationService.scheduleReviewReminderPeriodDays(u.reminderDays!);
    }
  }

  void _handleLogout() {
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShorkariIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: _loggedIn
          ? ChatScreen(onLogout: _handleLogout)
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}
