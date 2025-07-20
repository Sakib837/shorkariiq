import 'package:flutter/material.dart';
import 'package:shorkariiq/screens/HomePage.dart';

void main() {
  runApp(const ShorkariIQ());
}
class ShorkariIQ extends StatelessWidget {
  const ShorkariIQ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShorkariIQ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: Homepage.id : (context) => const Homepage(),
    );
  }
}
