import 'dart:async';
import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'widgets/styled_background.dart';
import 'screens/jigsaw_puzzle_screen.dart';
import 'screens/drag_drop_screen.dart';

void main() => runApp(const UnifiedGameApp());

class UnifiedGameApp extends StatelessWidget {
  const UnifiedGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NBCC Strategy Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final AudioService _audioService = AudioService();
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioService.initialize();
  }

  void _login() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter your code.');
      return;
    }

    _audioService.playBackgroundMusic();
    _audioService.playSound('click');
    _audioService.playSound('game_start');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameFlowScreen(
          playerCode: code,
          playerName: code,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NBCC Strategy Games'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StyledBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter your code to play:',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Code',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manages the game flow: Jigsaw Puzzle -> Drag & Drop Game
class GameFlowScreen extends StatefulWidget {
  final String playerCode;
  final String playerName;

  const GameFlowScreen({
    super.key,
    required this.playerCode,
    required this.playerName,
  });

  @override
  State<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends State<GameFlowScreen> {
  int _currentGame = 0; // 0 = Jigsaw, 1 = Drag & Drop

  void _proceedToNextGame() {
    AudioService().playSound('game_start');
    setState(() {
      _currentGame = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGame == 0) {
      return JigsawPuzzlePage(
        playerCode: widget.playerCode,
        playerName: widget.playerName,
        onGameCompleted: _proceedToNextGame,
      );
    } else {
      return DragDropGamePage(
        playerCode: widget.playerCode,
        playerName: widget.playerName,
      );
    }
  }
}
