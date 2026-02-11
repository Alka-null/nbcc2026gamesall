import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:beer_cup_game/models/question.dart';
import 'package:beer_cup_game/services/audio_service.dart';
import 'package:beer_cup_game/widgets/styled_background.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beer Cup Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A),
          primary: const Color(0xFF66BB6A),
          secondary: const Color(0xFF81C784),
        ),
        useMaterial3: true,
      ),
      home: const BeerCupGameHome(),
    );
  }

  // Utility to darken a color by [amount] (0.0 - 1.0)
  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final adjusted = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return adjusted.toColor();
  }
}

class BeerCupGameHome extends StatefulWidget {
  const BeerCupGameHome({super.key});

  @override
  State<BeerCupGameHome> createState() => _BeerCupGameHomeState();
}

class _BeerCupGameHomeState extends State<BeerCupGameHome> with TickerProviderStateMixin {
  static const String _baseUrl = 'https://nbcc2026gamesbackend.onrender.com/api/auth';
  // static const String _baseUrl = 'http://localhost:8000/api/auth';
  final AudioService _audioService = AudioService();
  String? _userCode;
  String? _playerName;
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initAnimations();
  }

  void _initAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initAudio() async {
    await _audioService.initialize();
    // Music will start on first user interaction (login button click)
  }

  @override
  void dispose() {
    _codeController.dispose();
    _rotationController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your code';
      });
      return;
    }

    // Start background music on first user interaction
    _audioService.playBackgroundMusic();
    _audioService.playSound('click');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/code-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'unique_code': _codeController.text.trim()}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['access'] != null) {
        _audioService.playSound('game_start');
        setState(() {
          _userCode = _codeController.text.trim();
          _playerName = data['player']['name'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['detail'] ?? data['message'] ?? 'Invalid code.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _logout() {
    setState(() {
      _userCode = null;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userCode == null) {
      return _buildLoginScreen();
    }
    return BeerCupGameScreen(
      userCode: _userCode!,
      onLogout: _logout,
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      body: StyledBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF81C784).withOpacity(0.2),
                const Color(0xFF66BB6A).withOpacity(0.2),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated 3D Trophy
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                      builder: (context, entranceValue, child) {
                        return Transform.translate(
                          offset: Offset(0, -100 * (1 - entranceValue)),
                          child: Opacity(
                            opacity: entranceValue.clamp(0.0, 1.0),
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_rotationController, _floatController, _pulseController]),
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(_rotationController.value * 2 * math.pi)
                                        ..rotateZ(math.sin(_floatController.value * math.pi) * 0.1),
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.amber.withOpacity(0.6),
                                              blurRadius: 40 * _pulseAnimation.value,
                                              spreadRadius: 10 * _pulseAnimation.value,
                                            ),
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(0.4),
                                              blurRadius: 60 * _pulseAnimation.value,
                                              spreadRadius: 20 * _pulseAnimation.value,
                                            ),
                                            BoxShadow(
                                              color: Colors.yellow.withOpacity(0.3),
                                              blurRadius: 80 * _pulseAnimation.value,
                                              spreadRadius: 30 * _pulseAnimation.value,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.emoji_events,
                                          size: 80,
                                          color: Colors.amber.shade300,
                                          shadows: [
                                            Shadow(
                                              color: Colors.yellow.withOpacity(0.8),
                                              blurRadius: 20,
                                            ),
                                            Shadow(
                                              color: Colors.orange.withOpacity(0.6),
                                              blurRadius: 30,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(-50 * (1 - value), 0),
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.amber.shade100,
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                'Beer Cup Game',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.amber.withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Text(
                              'Fill the Beer Cup Game',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    // Login card with scale animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: _codeController,
                                      decoration: InputDecoration(
                                        labelText: 'Enter Your Code',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        prefixIcon: Icon(Icons.person),
                                        errorText: _errorMessage,
                                      ),
                                      textCapitalization: TextCapitalization.characters,
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? CircularProgressIndicator(color: Colors.white)
                                            : Text(
                                                'START GAME',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BeerCupGameScreen extends StatefulWidget {
  final String userCode;
  final VoidCallback onLogout;

  const BeerCupGameScreen({
    super.key,
    required this.userCode,
    required this.onLogout,
  });

  @override
  State<BeerCupGameScreen> createState() => _BeerCupGameScreenState();
}

class _BeerCupGameScreenState extends State<BeerCupGameScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _remainingSeconds = 180; // 3 minutes
  Timer? _timer;
  int? _selectedAnswer;
  bool _isAnswered = false;
  late AnimationController _fillController;
  late AnimationController _bubbleController;
  late AnimationController _glassSwoshController;
  late AnimationController _liquidSwoshController;
  late Animation<double> _fillAnimation;
  late Animation<double> _glassSwoshAnimation;
  late Animation<double> _liquidSwoshAnimation;
  
  // Track answer history for backend submission
  final List<Map<String, dynamic>> _answerHistory = [];
  static const String _gameplayApiUrl = 'https://nbcc2026gamesbackend.onrender.com/api/gameplay';

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Glass swosh - gentle oscillation
    _glassSwoshController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Liquid swosh - wave effect
    _liquidSwoshController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    
    _fillAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );
    
    _glassSwoshAnimation = Tween<double>(begin: -0.008, end: 0.008).animate(
      CurvedAnimation(parent: _glassSwoshController, curve: Curves.easeInOut),
    );
    
    _liquidSwoshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _liquidSwoshController, curve: Curves.easeInOut),
    );
    
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _showTimeUpDialog();
      }
    });
  }

  void _updateBeerLevel() {
    final progress = _correctAnswers / QuestionBank.allQuestions.length;
    _fillAnimation = Tween<double>(
      begin: _fillAnimation.value,
      end: progress,
    ).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );
    _fillController.forward(from: 0);
  }

  void _answerQuestion(int selectedIndex) {
    if (_isAnswered) return;

    AudioService().playSound('click');

    setState(() {
      _selectedAnswer = selectedIndex;
      _isAnswered = true;
    });

    final question = QuestionBank.allQuestions[_currentQuestionIndex];
    final isCorrect = selectedIndex == question.correctAnswer;

    // Record answer for backend submission
    _answerHistory.add({
      'question_id': question.id,
      'question_text': question.question,
      'selected_answer': question.options[selectedIndex],
      'correct_answer': question.options[question.correctAnswer],
      'is_correct': isCorrect,
      'time_taken_seconds': (180 - _remainingSeconds).toDouble(),
    });

    if (isCorrect) {
      AudioService().playSound('correct');
      setState(() {
        _correctAnswers++;
      });
      _updateBeerLevel();
    } else {
      AudioService().playSound('error');
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentQuestionIndex < QuestionBank.allQuestions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
          _isAnswered = false;
          _remainingSeconds = 180; // Reset timer for next question
        });
        _startTimer();
      } else {
        _timer?.cancel();
        _showCompletionScreen();
      }
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Time\'s Up!'),
          ],
        ),
        content: Text('Moving to next question...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_currentQuestionIndex < QuestionBank.allQuestions.length - 1) {
                setState(() {
                  _currentQuestionIndex++;
                  _selectedAnswer = null;
                  _isAnswered = false;
                  _remainingSeconds = 180;
                });
                _startTimer();
              } else {
                _showCompletionScreen();
              }
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showCompletionScreen() async {
    final percentage = (_correctAnswers / QuestionBank.allQuestions.length * 100).round();
    final isCupFull = percentage >= 80;

    // Save game answers to backend
    await _saveGameAnswers();

    AudioService().playSound('success');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompletionScreen(
          userCode: widget.userCode,
          correctAnswers: _correctAnswers,
          totalQuestions: QuestionBank.allQuestions.length,
          isCupFull: isCupFull,
          onPlayAgain: () {
            // Pop the completion screen and go back to login
            Navigator.of(context).pop();
            widget.onLogout();
          },
          onExit: () {
            // Pop the completion screen and exit to login
            Navigator.of(context).pop();
            widget.onLogout();
          },
        ),
      ),
    );
  }

  Future<void> _saveGameAnswers() async {
    if (_answerHistory.isEmpty) return;
    
    try {
      await http.post(
        Uri.parse('$_gameplayApiUrl/game-answers/bulk/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_code': widget.userCode,
          'game_type': 'beer_cup',
          'answers': _answerHistory,
          'total_time_seconds': _answerHistory.fold<double>(
            0.0, 
            (sum, answer) => sum + (answer['time_taken_seconds'] as double)
          ),
        }),
      );
    } catch (e) {
      // Silently fail - don't block game completion for API errors
      debugPrint('Failed to save game answers: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fillController.dispose();
    _bubbleController.dispose();
    _glassSwoshController.dispose();
    _liquidSwoshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = QuestionBank.allQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / QuestionBank.allQuestions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}/${QuestionBank.allQuestions.length}'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: StyledBackground(
        child: Column(
          children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            minHeight: 6,
          ),
          
          Expanded(
            child: Row(
              children: [
                // Question area (70% width)
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timer with bounce animation
                        TweenAnimationBuilder<double>(
                          key: ValueKey('timer'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, -30 * (1 - value)),
                              child: Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _remainingSeconds < 30
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _remainingSeconds < 30
                                          ? Colors.red
                                          : Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        color: _remainingSeconds < 30
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _remainingSeconds < 30
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),

                        // ENHANCED Phase Banner - DOMINANT & OUTSTANDING
                        TweenAnimationBuilder<double>(
                          key: ValueKey('phase_banner_${question.phase}'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child!,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1B5E20),
                                  Color(0xFF2E7D32),
                                  Color(0xFF43A047),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.greenAccent.withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Phase Title with Icon
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.flash_on,
                                        color: Colors.amberAccent,
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PHASE',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            question.phase,
                                            style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black45,
                                                          offset: Offset(2, 2),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        // Category Badge
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            question.category,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                        SizedBox(height: 24),

                        // ENHANCED Storyline - DRAMATIC ENTRANCE
                        TweenAnimationBuilder<double>(
                          key: ValueKey('storyline_$_currentQuestionIndex'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: Transform.scale(
                                scale: 0.97 + (0.03 * value),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade50,
                                          Colors.blue.shade100,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: Offset(0, 6),
                                          spreadRadius: 1,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.blue.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.article_outlined,
                                                color: Colors.blue.shade700,
                                                size: 28,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'STORYLINE',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue.shade900,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            question.storyline,
                                            style: TextStyle(
                                              fontSize: 17,
                                              height: 1.6,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.blue.shade900,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 24),

                        // Question with enhanced slide-in and bounce animation
                        TweenAnimationBuilder<double>(
                          key: ValueKey('question_$_currentQuestionIndex'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: Transform.scale(
                                scale: 0.97 + (0.03 * value),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      question.question,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        height: 1.4,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 24),

                        // Answer options with enhanced staggered entrance animations
                        ...List.generate(question.options.length, (index) {
                          final isSelected = _selectedAnswer == index;
                          final isCorrect = index == question.correctAnswer;
                          final showResult = _isAnswered;

                          Color? cardColor;
                          if (showResult) {
                            if (isCorrect) {
                              cardColor = Colors.green[100];
                            } else if (isSelected && !isCorrect) {
                              cardColor = Colors.red[100];
                            }
                          }

                          return TweenAnimationBuilder<double>(
                            key: ValueKey('${_currentQuestionIndex}_option_$index'),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 450 + (index * 120)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(-50 * (1 - value), 0),
                                child: Transform.scale(
                                  scale: 0.85 + (0.15 * value),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        onTap: () => _answerQuestion(index),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: cardColor ?? Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.grey[300]!,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Colors.grey[200],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    String.fromCharCode(65 + index),
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  question.options[index],
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              if (showResult && isCorrect)
                                                Icon(Icons.check_circle, color: Colors.green),
                                              if (showResult && isSelected && !isCorrect)
                                                Icon(Icons.cancel, color: Colors.red),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Beer glass area (30% width)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: BeerGlassWidget(
                        fillAnimation: _fillAnimation,
                        bubbleAnimation: _bubbleController,
                        glassSwoshAnimation: _glassSwoshAnimation,
                        liquidSwoshAnimation: _liquidSwoshAnimation,
                        correctAnswers: _correctAnswers,
                        totalQuestions: QuestionBank.allQuestions.length,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class BeerGlassWidget extends StatelessWidget {
  final Animation<double> fillAnimation;
  final Animation<double> bubbleAnimation;
  final Animation<double> glassSwoshAnimation;
  final Animation<double> liquidSwoshAnimation;
  final int correctAnswers;
  final int totalQuestions;

  const BeerGlassWidget({
    super.key,
    required this.fillAnimation,
    required this.bubbleAnimation,
    required this.glassSwoshAnimation,
    required this.liquidSwoshAnimation,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([fillAnimation, bubbleAnimation, glassSwoshAnimation, liquidSwoshAnimation]),
      builder: (context, child) {
        final percentage = (correctAnswers / totalQuestions * 100).round();
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$correctAnswers / $totalQuestions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 24),
            
            // Beer glass with advanced 3D effects and swosh animations
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                // Static 3D tilt to show depth
                ..rotateY(-0.15) // Slight tilt to show 3D perspective
                // Gentle glass oscillation (swosh)
                ..rotateZ(glassSwoshAnimation.value)
                ..rotateY(math.sin(bubbleAnimation.value * 2 * math.pi) * 0.05 + glassSwoshAnimation.value * 0.5)
                ..rotateX(math.cos(bubbleAnimation.value * 2 * math.pi) * 0.02),
              alignment: Alignment.center,
              child: Transform.scale(
                scale: 1.0 + (fillAnimation.value * 0.08), // Slight scale up as it fills
                child: Container(
                  width: 180,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      // Main shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 25,
                        offset: Offset(8, 12),
                        spreadRadius: 3,
                      ),
                      // Ambient shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        offset: Offset(0, 15),
                        spreadRadius: 5,
                      ),
                      // Colored glow based on fill level
                      BoxShadow(
                        color: fillAnimation.value > 0.5
                            ? Colors.amber.withOpacity(0.3 * fillAnimation.value)
                            : Colors.orange.withOpacity(0.15 * fillAnimation.value),
                        blurRadius: 35,
                        offset: Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      // Top light reflection
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(-5, -8),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: BeerGlassPainter(
                      fillLevel: fillAnimation.value,
                      bubbleOffset: bubbleAnimation.value,
                      liquidSwoshOffset: liquidSwoshAnimation.value,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            if (percentage >= 80)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[700]!, Colors.amber[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Prize Unlocked!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class BeerGlassPainter extends CustomPainter {
  final double fillLevel;
  final double bubbleOffset;
  final double liquidSwoshOffset;

  BeerGlassPainter({
    required this.fillLevel,
    required this.bubbleOffset,
    required this.liquidSwoshOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.45; // Shifted left to accommodate handle
    final glassWidth = size.width * 0.55;
    final glassLeft = size.width * 0.15;
    final glassRight = glassLeft + glassWidth;
    
    // === 3D HANDLE (Draw first, behind glass) ===
    _drawHandle(canvas, size, glassRight);
    
    // === MULTI-LAYER SHADOW FOR DEPTH ===
    // Ground shadow (elliptical)
    final groundShadow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = Colors.black.withOpacity(0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 10, size.height + 8),
        width: glassWidth * 0.9,
        height: 20,
      ),
      groundShadow,
    );
    
    // Soft outer shadow for 3D lift
    final outerShadow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = Colors.black.withOpacity(0.18);
    final outerShadowPath = Path();
    outerShadowPath.moveTo(glassLeft + glassWidth * 0.15 + 6, 6);
    outerShadowPath.lineTo(glassLeft + 6, size.height + 3);
    outerShadowPath.lineTo(glassRight + 6, size.height + 3);
    outerShadowPath.lineTo(glassRight - glassWidth * 0.15 + 6, 6);
    outerShadowPath.close();
    canvas.drawPath(outerShadowPath, outerShadow);

    // === GLASS BACK WALL (Creates 3D depth) ===
    final backWallPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          Color(0xFFE8E8E8).withOpacity(0.4),
          Color(0xFFD0D0D0).withOpacity(0.3),
          Color(0xFFC0C0C0).withOpacity(0.25),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(glassLeft, 0, glassWidth, size.height));
    
    final backWallPath = Path();
    backWallPath.moveTo(glassLeft + glassWidth * 0.18, 5);
    backWallPath.lineTo(glassLeft + glassWidth * 0.05, size.height - 3);
    backWallPath.lineTo(glassRight - glassWidth * 0.05, size.height - 3);
    backWallPath.lineTo(glassRight - glassWidth * 0.18, 5);
    backWallPath.close();
    canvas.drawPath(backWallPath, backWallPaint);

    // === BEER LIQUID WITH ADVANCED 3D GRADIENTS ===
    if (fillLevel > 0) {
      final fillHeight = size.height * fillLevel;
      final bottomY = size.height;
      final topY = size.height - fillHeight;
      
      // Calculate liquid width at top based on glass trapezoid shape
      final topRatio = topY / size.height;
      final leftEdgeAtTop = glassLeft + glassWidth * (0.15 - 0.10 * topRatio);
      final rightEdgeAtTop = glassRight - glassWidth * (0.15 - 0.10 * topRatio);
      final liquidTopWidth = rightEdgeAtTop - leftEdgeAtTop;
      
      // Calculate liquid swosh wave effect
      final swoshWave = math.sin(liquidSwoshOffset * math.pi * 2) * 3;
      final swoshTilt = math.cos(liquidSwoshOffset * math.pi * 2) * 2;
      
      // Main beer body with rich 3D gradient (darker edges, lighter center)
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            Color(0xFFE65100).withOpacity(0.7), // Dark left edge
            Color(0xFFFFB300), // Bright center-left
            Color(0xFFFFD54F), // Brightest center
            Color(0xFFFFB300), // Bright center-right
            Color(0xFFE65100).withOpacity(0.7), // Dark right edge
          ],
          stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTRB(
          glassLeft, topY, glassRight, bottomY
        ));

      final fillPath = Path();
      fillPath.moveTo(glassLeft + glassWidth * 0.05, bottomY);
      fillPath.lineTo(leftEdgeAtTop + swoshTilt, topY + swoshWave);
      fillPath.lineTo(rightEdgeAtTop - swoshTilt, topY - swoshWave);
      fillPath.lineTo(glassRight - glassWidth * 0.05, bottomY);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      
      // Vertical depth gradient overlay
      final depthOverlay = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            Color(0xFFFFF176).withOpacity(0.3), // Light top
            Colors.transparent,
            Color(0xFFE65100).withOpacity(0.4), // Dark bottom
          ],
          stops: [0.0, 0.4, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(glassLeft, topY, glassRight, bottomY));
      canvas.drawPath(fillPath, depthOverlay);

      // === ADVANCED BUBBLES WITH PHYSICS ===
      if (fillLevel > 0.1) {
        for (int i = 0; i < 18; i++) {
          final bubbleProgress = (bubbleOffset + i * 0.12) % 1.0;
          final bubbleY = bottomY - (fillHeight * 0.08) - (bubbleProgress * fillHeight * 0.88);
          final xOffset = math.sin(bubbleProgress * math.pi * 4 + i) * 12;
          final bubbleX = glassLeft + glassWidth * 0.2 + (i * 4) + xOffset;
          final bubbleSize = 2.0 + (i % 4) * 1.3 * (1 - bubbleProgress * 0.4);
          
          if (bubbleX < glassLeft + 10 || bubbleX > glassRight - 10) continue;
          
          final bubbleGradient = Paint()
            ..style = PaintingStyle.fill
            ..shader = RadialGradient(
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.2),
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(Rect.fromCircle(center: Offset(bubbleX, bubbleY), radius: bubbleSize));
          
          canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleSize, bubbleGradient);
          
          // Bubble highlight
          canvas.drawCircle(
            Offset(bubbleX - bubbleSize * 0.35, bubbleY - bubbleSize * 0.35),
            bubbleSize * 0.35,
            Paint()..color = Colors.white.withOpacity(0.95),
          );
        }
      }

      // === REALISTIC FOAM WITH 3D TEXTURE ===
      if (fillLevel > 0.3) {
        final foamHeight = fillLevel > 0.8 ? 28.0 : 22.0;
        
        // Foam shadow underneath
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX, topY + 2), width: liquidTopWidth + 4, height: 10),
          Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
            ..color = Color(0xFFFF8F00).withOpacity(0.35),
        );
        
        // Multiple foam layers for 3D dome effect
        for (int layer = 5; layer >= 0; layer--) {
          final layerOffset = layer * 3.5;
          final layerWidth = liquidTopWidth - layer * 4;
          final layerOpacity = 1.0 - (layer * 0.12);
          
          final foamPaint = Paint()
            ..style = PaintingStyle.fill
            ..shader = RadialGradient(
              colors: [
                Colors.white.withOpacity(layerOpacity),
                Color(0xFFFFFDF7).withOpacity(layerOpacity * 0.92),
                Color(0xFFFFF8DC).withOpacity(layerOpacity * 0.8),
              ],
              stops: [0.0, 0.6, 1.0],
            ).createShader(Rect.fromCenter(
              center: Offset(centerX, topY - layerOffset),
              width: layerWidth,
              height: foamHeight - layer * 2,
            ));
          
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(centerX, topY - layerOffset),
              width: layerWidth,
              height: (foamHeight - layer * 2) * 0.75,
            ),
            foamPaint,
          );
        }
        
        // Individual foam bubbles on top
        final random = math.Random(123);
        for (int i = 0; i < 25; i++) {
          final angle = (i / 25) * math.pi * 2;
          final radius = (liquidTopWidth / 2) * (0.25 + random.nextDouble() * 0.65);
          final bubbleX = centerX + math.cos(angle) * radius;
          final bubbleY = topY - 12 - random.nextDouble() * 14;
          final bubbleSize = 2.0 + random.nextDouble() * 4.0;
          
          canvas.drawCircle(
            Offset(bubbleX, bubbleY),
            bubbleSize,
            Paint()
              ..style = PaintingStyle.fill
              ..shader = RadialGradient(colors: [Colors.white, Color(0xFFFFFDF7)])
                  .createShader(Rect.fromCircle(center: Offset(bubbleX, bubbleY), radius: bubbleSize)),
          );
          canvas.drawCircle(
            Offset(bubbleX - bubbleSize * 0.3, bubbleY - bubbleSize * 0.3),
            bubbleSize * 0.4,
            Paint()..color = Colors.white,
          );
        }
      }

      // === BEER LIQUID SHINE (3D curved reflection) ===
      final leftShinePaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.45),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTRB(glassLeft, topY, centerX, bottomY));

      final leftShinePath = Path();
      leftShinePath.moveTo(leftEdgeAtTop + 8, topY + 5);
      leftShinePath.quadraticBezierTo(
        glassLeft + glassWidth * 0.08, (topY + bottomY) / 2,
        glassLeft + glassWidth * 0.06, bottomY,
      );
      leftShinePath.lineTo(glassLeft + glassWidth * 0.18, bottomY);
      leftShinePath.quadraticBezierTo(
        glassLeft + glassWidth * 0.2, (topY + bottomY) / 2,
        leftEdgeAtTop + glassWidth * 0.15, topY + 5,
      );
      leftShinePath.close();
      canvas.drawPath(leftShinePath, leftShinePaint);
    }

    // === 3D GLASS BODY WITH THICKNESS ===
    // Glass inner dark edge (creates thickness illusion)
    final glassInnerEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = LinearGradient(
        colors: [
          Color(0xFF424242).withOpacity(0.35),
          Color(0xFF616161).withOpacity(0.45),
          Color(0xFF424242).withOpacity(0.35),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(glassLeft, 0, glassWidth, size.height));

    final innerPath = Path();
    innerPath.moveTo(glassLeft + glassWidth * 0.17, 4);
    innerPath.lineTo(glassLeft + glassWidth * 0.03, size.height - 3);
    innerPath.lineTo(glassRight - glassWidth * 0.03, size.height - 3);
    innerPath.lineTo(glassRight - glassWidth * 0.17, 4);
    innerPath.close();
    canvas.drawPath(innerPath, glassInnerEdge);

    // Main glass outline with 3D gradient
    final glassPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = LinearGradient(
        colors: [
          Color(0xFFE0E0E0),
          Color(0xFFBDBDBD),
          Color(0xFF9E9E9E),
          Color(0xFFBDBDBD),
          Color(0xFFE0E0E0),
        ],
        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(glassLeft, 0, glassWidth, size.height));

    final glassPath = Path();
    glassPath.moveTo(glassLeft + glassWidth * 0.15, 0);
    glassPath.lineTo(glassLeft, size.height);
    glassPath.lineTo(glassRight, size.height);
    glassPath.lineTo(glassRight - glassWidth * 0.15, 0);
    glassPath.close();
    canvas.drawPath(glassPath, glassPaint);

    // === GLASS HIGHLIGHTS (Multiple curved reflections for 3D) ===
    // Primary curved highlight
    final primaryHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.0),
        ],
        stops: [0.0, 0.15, 0.5, 0.85, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final primaryHighlightPath = Path();
    primaryHighlightPath.moveTo(glassLeft + glassWidth * 0.18, 18);
    primaryHighlightPath.quadraticBezierTo(
      glassLeft + glassWidth * 0.08, size.height / 2,
      glassLeft + glassWidth * 0.04, size.height - 25,
    );
    canvas.drawPath(primaryHighlightPath, primaryHighlight);
    
    // Secondary wider highlight
    final secondaryHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..color = Colors.white.withOpacity(0.25);
    
    final secondaryHighlightPath = Path();
    secondaryHighlightPath.moveTo(glassLeft + glassWidth * 0.22, 25);
    secondaryHighlightPath.quadraticBezierTo(
      glassLeft + glassWidth * 0.12, size.height / 2,
      glassLeft + glassWidth * 0.08, size.height - 35,
    );
    canvas.drawPath(secondaryHighlightPath, secondaryHighlight);

    // Right side subtle reflection
    final rightReflection = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..color = Colors.white.withOpacity(0.25);
    
    final rightReflectionPath = Path();
    rightReflectionPath.moveTo(glassRight - glassWidth * 0.18, 22);
    rightReflectionPath.quadraticBezierTo(
      glassRight - glassWidth * 0.08, size.height / 2,
      glassRight - glassWidth * 0.04, size.height - 30,
    );
    canvas.drawPath(rightReflectionPath, rightReflection);

    // === CONDENSATION DROPLETS ===
    final random = math.Random(789);
    for (int i = 0; i < 14; i++) {
      final dropletX = glassLeft + glassWidth * 0.25 + random.nextDouble() * glassWidth * 0.5;
      final dropletY = size.height * 0.2 + random.nextDouble() * size.height * 0.55;
      final dropletSize = 1.5 + random.nextDouble() * 2.8;
      
      canvas.drawCircle(
        Offset(dropletX, dropletY),
        dropletSize,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [Colors.white.withOpacity(0.65), Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)],
          ).createShader(Rect.fromCircle(center: Offset(dropletX, dropletY), radius: dropletSize)),
      );
      canvas.drawCircle(
        Offset(dropletX - dropletSize * 0.3, dropletY - dropletSize * 0.3),
        dropletSize * 0.4,
        Paint()..color = Colors.white.withOpacity(0.85),
      );
    }

    // === GLASS RIM (3D thick top edge) ===
    // Rim shadow
    canvas.drawLine(
      Offset(glassLeft + glassWidth * 0.15 + 2, 3),
      Offset(glassRight - glassWidth * 0.15 + 2, 3),
      Paint()
        ..strokeWidth = 3
        ..color = Colors.black.withOpacity(0.1),
    );
    // Rim highlight
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = LinearGradient(
        colors: [Color(0xFFBDBDBD), Colors.white, Color(0xFFE0E0E0), Colors.white, Color(0xFFBDBDBD)],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(glassLeft + glassWidth * 0.15, 0, glassWidth * 0.7, 5));
    canvas.drawLine(
      Offset(glassLeft + glassWidth * 0.15, 0),
      Offset(glassRight - glassWidth * 0.15, 0),
      rimPaint,
    );
    
    // === GLASS BOTTOM (3D thick base) ===
    canvas.drawLine(
      Offset(glassLeft + 2, size.height),
      Offset(glassRight + 2, size.height),
      Paint()
        ..strokeWidth = 5
        ..color = Colors.black.withOpacity(0.15),
    );
    final bottomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = LinearGradient(
        colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD), Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
      ).createShader(Rect.fromLTWH(glassLeft, size.height - 4, glassWidth, 4));
    canvas.drawLine(
      Offset(glassLeft, size.height),
      Offset(glassRight, size.height),
      bottomPaint,
    );
  }

  void _drawHandle(Canvas canvas, Size size, double glassRight) {
    final handleStartX = glassRight - 8;
    final handleEndX = handleStartX + size.width * 0.28;
    final handleTopY = size.height * 0.12;
    final handleBottomY = size.height * 0.58;
    final handleCenterY = (handleTopY + handleBottomY) / 2;
    
    // === HANDLE SHADOW (Far) ===
    final handleFarShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = Colors.black.withOpacity(0.15);
    
    final handleShadowPath = Path();
    handleShadowPath.moveTo(handleStartX + 5, handleTopY + 5);
    handleShadowPath.cubicTo(
      handleEndX + 5, handleTopY + 5,
      handleEndX + 5, handleBottomY + 5,
      handleStartX + 5, handleBottomY + 5,
    );
    canvas.drawPath(handleShadowPath, handleFarShadow);
    
    // === HANDLE OUTER EDGE (3D volume) ===
    final handleOuterPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF9E9E9E),
          Color(0xFFBDBDBD),
          Color(0xFF9E9E9E),
          Color(0xFF757575),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(handleStartX, handleTopY, handleEndX, handleBottomY));
    
    final handlePath = Path();
    handlePath.moveTo(handleStartX, handleTopY);
    handlePath.cubicTo(
      handleEndX, handleTopY,
      handleEndX, handleBottomY,
      handleStartX, handleBottomY,
    );
    canvas.drawPath(handlePath, handleOuterPaint);
    
    // === HANDLE INNER HIGHLIGHT (3D curved surface) ===
    final handleHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.0),
        ],
        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(handleStartX, handleTopY, handleEndX, handleBottomY));
    
    final handleHighlightPath = Path();
    handleHighlightPath.moveTo(handleStartX + 3, handleTopY + 4);
    handleHighlightPath.cubicTo(
      handleEndX - 6, handleTopY + 4,
      handleEndX - 6, handleBottomY - 4,
      handleStartX + 3, handleBottomY - 4,
    );
    canvas.drawPath(handleHighlightPath, handleHighlightPaint);
    
    // === HANDLE INNER SHADOW (depth) ===
    final handleInnerShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.12);
    
    final handleInnerShadowPath = Path();
    handleInnerShadowPath.moveTo(handleStartX - 2, handleTopY + 8);
    handleInnerShadowPath.cubicTo(
      handleEndX - 12, handleTopY + 8,
      handleEndX - 12, handleBottomY - 8,
      handleStartX - 2, handleBottomY - 8,
    );
    canvas.drawPath(handleInnerShadowPath, handleInnerShadow);
    
    // === HANDLE ATTACHMENT POINTS (where it connects to glass) ===
    // Top attachment
    canvas.drawCircle(
      Offset(handleStartX, handleTopY),
      5,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
        ).createShader(Rect.fromCircle(center: Offset(handleStartX, handleTopY), radius: 5)),
    );
    canvas.drawCircle(
      Offset(handleStartX - 1, handleTopY - 1),
      2,
      Paint()..color = Colors.white.withOpacity(0.7),
    );
    
    // Bottom attachment
    canvas.drawCircle(
      Offset(handleStartX, handleBottomY),
      5,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
        ).createShader(Rect.fromCircle(center: Offset(handleStartX, handleBottomY), radius: 5)),
    );
    canvas.drawCircle(
      Offset(handleStartX - 1, handleBottomY - 1),
      2,
      Paint()..color = Colors.white.withOpacity(0.7),
    );
  }

  @override
  bool shouldRepaint(BeerGlassPainter oldDelegate) {
    return fillLevel != oldDelegate.fillLevel ||
        bubbleOffset != oldDelegate.bubbleOffset ||
        liquidSwoshOffset != oldDelegate.liquidSwoshOffset;
  }
}

// Animated star/particle for background
class _AnimatedStar {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double twinklePhase;
  Color color;

  _AnimatedStar({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.twinklePhase,
    required this.color,
  });
}

// Confetti particle
class _ConfettiParticle {
  double x;
  double y;
  double size;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;
  Color color;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
  });
}

class CompletionScreen extends StatefulWidget {
  final String userCode;
  final int correctAnswers;
  final int totalQuestions;
  final bool isCupFull;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const CompletionScreen({
    super.key,
    required this.userCode,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.isCupFull,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color get _lightGreen => const Color(0xFFBEEBC6);
  Color get _accentGreen => const Color(0xFF7FD08B);
  Color get _lightOrange => const Color(0xFFFFE0B2);
  Color get _accentOrange => const Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Animated badge with ribbons
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glowing halo
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final t = Curves.easeInOut.transform(_glowController.value);
                        final blur = 24.0 + (12.0 * t);
                        final opacity = 0.18 + (0.12 * t);
                        return Container(
                          width: size.width * 0.68 + 40 * t,
                          height: size.width * 0.68 + 40 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _lightGreen.withOpacity(opacity),
                            boxShadow: [
                              BoxShadow(
                                color: _accentOrange.withOpacity(opacity),
                                blurRadius: blur,
                                spreadRadius: 6 * t,
                              ),
                              BoxShadow(
                                color: _accentGreen.withOpacity(opacity * 0.7),
                                blurRadius: blur * 0.7,
                                spreadRadius: 4 * t,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Ribbons
                    Positioned(
                      left: 28,
                      top: size.width * 0.12,
                      child: Transform.rotate(
                        angle: -0.6,
                        child: _ribbonWidget(_accentOrange, _accentGreen),
                      ),
                    ),
                    Positioned(
                      right: 28,
                      top: size.width * 0.12,
                      child: Transform.rotate(
                        angle: 0.6,
                        child: _ribbonWidget(_accentGreen, _accentOrange),
                      ),
                    ),

                    // Main badge / cup with pulsing scale
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.06)
                          .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                      child: Container(
                        width: size.width * 0.58,
                        height: size.width * 0.58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_lightGreen, _lightOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _accentGreen.withOpacity(0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: _accentOrange.withOpacity(0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bulging score circle
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: widget.correctAnswers.toDouble()),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeOutCubic,
                                builder: (context, val, child) {
                                  final display = val.round();
                                  final percent = widget.totalQuestions > 0
                                      ? (widget.correctAnswers / widget.totalQuestions)
                                      : 0.0;
                                  return Container(
                                    width: size.width * 0.28 + (8 * (val / (widget.totalQuestions == 0 ? 1 : widget.totalQuestions))),
                                    height: size.width * 0.28 + (8 * (val / (widget.totalQuestions == 0 ? 1 : widget.totalQuestions))),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accentGreen.withOpacity(0.18 + percent * 0.18),
                                          blurRadius: 18 + percent * 12,
                                          spreadRadius: 4 * percent,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            display.toString(),
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              color: _darken(_accentGreen, 0.08),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '/ ${widget.totalQuestions}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black.withOpacity(0.65),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.isCupFull ? 'Cup Full — Well Done!' : 'Great Effort!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _darken(_accentGreen, 0.02),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Congratulations ${widget.userCode.isNotEmpty ? widget.userCode : ''}! You scored ${widget.correctAnswers} out of ${widget.totalQuestions}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.78),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onPlayAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      onPressed: widget.onExit,
                        style: OutlinedButton.styleFrom(
                        foregroundColor: _darken(_accentOrange, 0.02),
                        side: BorderSide(color: _accentOrange.withOpacity(0.9)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Exit'),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Simple ribbon widget built from containers
  Widget _ribbonWidget(Color a, Color b) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [a, b]),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: a.withOpacity(0.14), blurRadius: 6, offset: const Offset(0,3))],
          ),
        ),
        Container(
          width: 22,
          height: 36,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [b.withOpacity(0.98), a.withOpacity(0.98)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            boxShadow: [BoxShadow(color: b.withOpacity(0.12), blurRadius: 6, offset: const Offset(0,3))],
          ),
        ),
      ],
    );
  }

  // Utility to darken a color by [amount] (0.0 - 1.0)
  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final adjusted = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return adjusted.toColor();
  }
}

// Star field painter
class _StarFieldPainter extends CustomPainter {
  final List<_AnimatedStar> stars;
  final double time;

  _StarFieldPainter({required this.stars, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final twinkle = (math.sin(time * star.speed * 5 + star.twinklePhase) + 1) / 2;
      final paint = Paint()
        ..color = star.color.withOpacity(star.opacity * twinkle)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size * (0.8 + twinkle * 0.4),
        paint,
      );
      
      // Add glow for larger stars
      if (star.size > 2) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity(star.opacity * twinkle * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => true;
}

// Confetti painter
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> confetti;

  _ConfettiPainter({required this.confetti});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in confetti) {
      final paint = Paint()..color = particle.color;
      
      canvas.save();
      canvas.translate(
        particle.x * size.width,
        particle.y * size.height,
      );
      canvas.rotate(particle.rotation);
      
      // Draw confetti as rectangles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
          Radius.circular(2),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
