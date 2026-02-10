import 'package:flutter/material.dart';
import 'leaderboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Leaderboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LeaderboardScreen(
        baseUrl: 'https://nbcc2026gamesbackend.onrender.com',
        // baseUrl: 'http://localhost:8000', // Change to your backend URL
      ),
    );
  }
}
