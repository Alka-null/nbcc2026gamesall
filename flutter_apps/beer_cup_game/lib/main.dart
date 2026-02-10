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

    // TODO: Re-enable API login when backend is fixed
    // Temporarily bypass login - accept any code
    _audioService.playSound('game_start');
    setState(() {
      _userCode = _codeController.text.trim();
      _playerName = _codeController.text.trim();
      _isLoading = false;
    });
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

  void _showCompletionScreen() {
    final percentage = (_correctAnswers / QuestionBank.allQuestions.length * 100).round();
    final isCupFull = percentage >= 80;

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
        title: Text('Question ${_currentQuestionIndex + 1}/80'),
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
    final centerX = size.width * 0.5;
    
    // === MULTI-LAYER SHADOW FOR DEPTH ===
    // Soft outer shadow
    final outerShadow = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15)
      ..color = Colors.black.withOpacity(0.2);
    final outerShadowPath = Path();
    outerShadowPath.moveTo(size.width * 0.3 + 5, 5);
    outerShadowPath.lineTo(size.width * 0.2 + 5, size.height + 5);
    outerShadowPath.lineTo(size.width * 0.8 + 5, size.height + 5);
    outerShadowPath.lineTo(size.width * 0.7 + 5, 5);
    outerShadowPath.close();
    canvas.drawPath(outerShadowPath, outerShadow);
    
    // Sharp inner shadow
    final innerShadow = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5)
      ..color = Colors.black.withOpacity(0.15);
    final innerShadowPath = Path();
    innerShadowPath.moveTo(size.width * 0.3 + 2, 2);
    innerShadowPath.lineTo(size.width * 0.2 + 2, size.height + 2);
    innerShadowPath.lineTo(size.width * 0.8 + 2, size.height + 2);
    innerShadowPath.lineTo(size.width * 0.7 + 2, 2);
    innerShadowPath.close();
    canvas.drawPath(innerShadowPath, innerShadow);

    // === BEER LIQUID WITH ADVANCED GRADIENTS ===
    if (fillLevel > 0) {
      final fillHeight = size.height * fillLevel;
      final bottomY = size.height;
      final topY = size.height - fillHeight;
      
      // Calculate liquid width at top based on glass trapezoid shape
      // Glass goes from 0.3-0.7 at top to 0.2-0.8 at bottom
      // Interpolate based on Y position
      final topRatio = topY / size.height; // 0 at top, 1 at bottom
      final leftEdgeAtTop = size.width * (0.3 - (0.3 - 0.2) * topRatio);
      final rightEdgeAtTop = size.width * (0.7 + (0.8 - 0.7) * topRatio);
      final liquidTopWidth = rightEdgeAtTop - leftEdgeAtTop;
      
      // Calculate liquid swosh wave effect
      final swoshWave = math.sin(liquidSwoshOffset * math.pi * 2) * 3;
      final swoshTilt = math.cos(liquidSwoshOffset * math.pi * 2) * 2;
      
      // Main beer body with rich gradient
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            Color(0xFFFFF176), // Lighter top
            Color(0xFFFFD54F),
            Color(0xFFFFB300),
            Color(0xFFFF8F00), // Darker bottom
            Color(0xFFE65100), // Deep amber
          ],
          stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(
          size.width * 0.2, topY, size.width * 0.8, bottomY
        ));

      final fillPath = Path();
      // Start at bottom left edge of glass
      fillPath.moveTo(size.width * 0.2, bottomY);
      // Go to top left edge (aligned with glass)
      fillPath.lineTo(leftEdgeAtTop + swoshTilt, topY + swoshWave);
      // Go to top right edge (aligned with glass)
      fillPath.lineTo(rightEdgeAtTop - swoshTilt, topY - swoshWave);
      // Go to bottom right edge of glass
      fillPath.lineTo(size.width * 0.8, bottomY);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);

      // === ADVANCED BUBBLES WITH PHYSICS ===
      if (fillLevel > 0.1) {
        final random = math.Random(42); // Fixed seed for consistency
        
        for (int i = 0; i < 15; i++) {
          // Calculate bubble position with realistic physics
          final bubbleProgress = (bubbleOffset + i * 0.15) % 1.0;
          final bubbleY = bottomY - (fillHeight * 0.1) - (bubbleProgress * fillHeight * 0.85);
          final xOffset = math.sin(bubbleProgress * math.pi * 4 + i) * 15;
          final bubbleX = size.width * 0.3 + (i * 3.5) + xOffset;
          final bubbleSize = 2.5 + (i % 4) * 1.5 * (1 - bubbleProgress * 0.5);
          
          // Skip bubbles outside glass bounds
          if (bubbleX < size.width * 0.2 || bubbleX > size.width * 0.8) continue;
          
          // Main bubble with gradient
          final bubbleGradient = Paint()
            ..style = PaintingStyle.fill
            ..shader = RadialGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.3),
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(Rect.fromCircle(
              center: Offset(bubbleX, bubbleY),
              radius: bubbleSize,
            ));
          
          canvas.drawCircle(
            Offset(bubbleX, bubbleY),
            bubbleSize,
            bubbleGradient,
          );
          
          // Bubble highlight (top-left)
          final highlightPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.white.withOpacity(0.95);
          canvas.drawCircle(
            Offset(bubbleX - bubbleSize * 0.35, bubbleY - bubbleSize * 0.35),
            bubbleSize * 0.35,
            highlightPaint,
          );
          
          // Bubble shadow (bottom-right)
          final shadowBubble = Paint()
            ..style = PaintingStyle.fill
            ..color = Color(0xFFE65100).withOpacity(0.2);
          canvas.drawCircle(
            Offset(bubbleX + bubbleSize * 0.3, bubbleY + bubbleSize * 0.3),
            bubbleSize * 0.25,
            shadowBubble,
          );
        }
      }

      // === REALISTIC FOAM WITH 3D TEXTURE ===
      if (fillLevel > 0.3) {
        final foamHeight = fillLevel > 0.8 ? 25.0 : 20.0;
        
        // Foam base shadow
        final foamShadow = Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3)
          ..color = Color(0xFFFF8F00).withOpacity(0.3);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, topY),
            width: liquidTopWidth + 2,
            height: 8,
          ),
          foamShadow,
        );
        
        // Multiple foam layers for 3D effect
        for (int layer = 4; layer >= 0; layer--) {
          final layerOffset = layer * 4.0;
          final layerWidth = liquidTopWidth - layer * 3;
          final layerOpacity = 1.0 - (layer * 0.15);
          
          final foamPaint = Paint()
            ..style = PaintingStyle.fill
            ..shader = RadialGradient(
              colors: [
                Colors.white.withOpacity(layerOpacity),
                Color(0xFFFFFDF7).withOpacity(layerOpacity * 0.95),
                Color(0xFFFFF8DC).withOpacity(layerOpacity * 0.85),
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
              height: (foamHeight - layer * 2) * 0.8,
            ),
            foamPaint,
          );
        }
        
        // Individual foam bubbles on top
        final random = math.Random(123);
        for (int i = 0; i < 20; i++) {
          final angle = (i / 20) * math.pi * 2;
          final radius = (liquidTopWidth / 2) * (0.3 + random.nextDouble() * 0.6);
          final bubbleX = centerX + math.cos(angle) * radius;
          final bubbleY = topY - 15 + random.nextDouble() * 15;
          final bubbleSize = 2.0 + random.nextDouble() * 3.5;
          
          // Bubble body
          final foamBubblePaint = Paint()
            ..style = PaintingStyle.fill
            ..shader = RadialGradient(
              colors: [
                Colors.white,
                Color(0xFFFFFDF7),
              ],
            ).createShader(Rect.fromCircle(
              center: Offset(bubbleX, bubbleY),
              radius: bubbleSize,
            ));
          canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleSize, foamBubblePaint);
          
          // Bubble highlight
          canvas.drawCircle(
            Offset(bubbleX - bubbleSize * 0.3, bubbleY - bubbleSize * 0.3),
            bubbleSize * 0.4,
            Paint()..color = Colors.white,
          );
          
          // Bubble outline for definition
          canvas.drawCircle(
            Offset(bubbleX, bubbleY),
            bubbleSize,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5
              ..color = Color(0xFFFFE082).withOpacity(0.4),
          );
        }
      }

      // === BEER LIQUID SHINE (Left side light reflection) ===
      final leftShinePaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTRB(
          size.width * 0.2, topY, size.width * 0.45, bottomY
        ));

      final leftShinePath = Path();
      // Align shine with actual liquid edges
      leftShinePath.moveTo(leftEdgeAtTop + (liquidTopWidth * 0.08), topY + 5);
      leftShinePath.lineTo(size.width * 0.21, bottomY);
      leftShinePath.lineTo(size.width * 0.32, bottomY);
      leftShinePath.lineTo(leftEdgeAtTop + (liquidTopWidth * 0.3), topY + 5);
      leftShinePath.close();
      canvas.drawPath(leftShinePath, leftShinePaint);
      
      // === BEER SURFACE TENSION WITH SWOSH ===
      final surfacePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          colors: [
            Color(0xFFFFB300).withOpacity(0.8),
            Color(0xFFFFD54F).withOpacity(0.6),
            Color(0xFFFFB300).withOpacity(0.8),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset(centerX, topY),
          width: liquidTopWidth,
          height: 2,
        ));
      // Draw wavy surface line with swosh effect
      final wavePath = Path();
      wavePath.moveTo(leftEdgeAtTop + swoshTilt, topY + swoshWave);
      for (double i = 0; i <= 10; i++) {
        final t = i / 10;
        final x = leftEdgeAtTop + liquidTopWidth * t;
        final waveY = topY + math.sin((t + liquidSwoshOffset) * math.pi * 4) * 2;
        wavePath.lineTo(x, waveY);
      }
      canvas.drawPath(wavePath, surfacePaint);
    }

    // === GLASS BODY WITH REALISTIC MATERIAL ===
    // Glass thickness (inner dark edge)
    final glassInnerEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = LinearGradient(
        colors: [
          Color(0xFF424242).withOpacity(0.3),
          Color(0xFF616161).withOpacity(0.4),
          Color(0xFF424242).withOpacity(0.3),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final innerPath = Path();
    innerPath.moveTo(size.width * 0.31, 2);
    innerPath.lineTo(size.width * 0.21, size.height - 2);
    innerPath.lineTo(size.width * 0.79, size.height - 2);
    innerPath.lineTo(size.width * 0.69, 2);
    innerPath.close();
    canvas.drawPath(innerPath, glassInnerEdge);

    // Main glass outline with gradient
    final glassPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = LinearGradient(
        colors: [
          Color(0xFFBDBDBD),
          Color(0xFF757575),
          Color(0xFF616161),
          Color(0xFF757575),
          Color(0xFFBDBDBD),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final glassPath = Path();
    glassPath.moveTo(size.width * 0.3, 0);
    glassPath.lineTo(size.width * 0.2, size.height);
    glassPath.lineTo(size.width * 0.8, size.height);
    glassPath.lineTo(size.width * 0.7, 0);
    glassPath.close();
    canvas.drawPath(glassPath, glassPaint);

    // === GLASS HIGHLIGHTS (Multiple reflection layers) ===
    // Primary highlight (bright white streak)
    final primaryHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2)
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.0),
        ],
        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final primaryHighlightPath = Path();
    primaryHighlightPath.moveTo(size.width * 0.32, 15);
    primaryHighlightPath.lineTo(size.width * 0.24, size.height - 25);
    canvas.drawPath(primaryHighlightPath, primaryHighlight);
    
    // Secondary highlight (wider, softer)
    final secondaryHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.0),
        ],
        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final secondaryHighlightPath = Path();
    secondaryHighlightPath.moveTo(size.width * 0.35, 20);
    secondaryHighlightPath.lineTo(size.width * 0.27, size.height - 30);
    canvas.drawPath(secondaryHighlightPath, secondaryHighlight);

    // Right side subtle reflection
    final rightReflection = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5)
      ..color = Colors.white.withOpacity(0.2);
    
    final rightReflectionPath = Path();
    rightReflectionPath.moveTo(size.width * 0.68, 20);
    rightReflectionPath.lineTo(size.width * 0.76, size.height - 30);
    canvas.drawPath(rightReflectionPath, rightReflection);

    // === CONDENSATION DROPLETS ===
    final random = math.Random(789);
    for (int i = 0; i < 12; i++) {
      final dropletX = size.width * 0.4 + random.nextDouble() * size.width * 0.35;
      final dropletY = size.height * 0.2 + random.nextDouble() * size.height * 0.6;
      final dropletSize = 1.5 + random.nextDouble() * 2.5;
      
      // Droplet body
      final dropletPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(dropletX, dropletY),
          radius: dropletSize,
        ));
      canvas.drawCircle(Offset(dropletX, dropletY), dropletSize, dropletPaint);
      
      // Droplet highlight
      canvas.drawCircle(
        Offset(dropletX - dropletSize * 0.3, dropletY - dropletSize * 0.3),
        dropletSize * 0.4,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
      
      // Droplet shadow
      canvas.drawCircle(
        Offset(dropletX + dropletSize * 0.2, dropletY + dropletSize * 0.2),
        dropletSize * 0.3,
        Paint()..color = Colors.black.withOpacity(0.1),
      );
    }

    // === GLASS RIM (Top edge highlight) ===
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        colors: [
          Color(0xFFE0E0E0),
          Colors.white,
          Color(0xFFE0E0E0),
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, 5));
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.7, 0),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(BeerGlassPainter oldDelegate) {
    return fillLevel != oldDelegate.fillLevel ||
        bubbleOffset != oldDelegate.bubbleOffset ||
        liquidSwoshOffset != oldDelegate.liquidSwoshOffset;
  }
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
  late AnimationController _trophyController;
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Entrance animation
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    // Continuous rotation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Floating motion
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Pulsing scale
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // Glow intensity
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    // Sparkle effect
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi * 2).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _floatAnimation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _trophyController.dispose();
    _rotationController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.correctAnswers / widget.totalQuestions * 100).round();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isCupFull
                ? [Color(0xFF2E7D32), Color(0xFF1B5E20)]
                : [Color(0xFF424242), Color(0xFF212121)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isCupFull)
                    // Enhanced 3D Trophy with Glow and Glossy Effects
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.elasticOut,
                      builder: (context, entranceValue, child) {
                        return Transform.translate(
                          offset: Offset(0, -200 * (1 - entranceValue)),
                          child: Transform.scale(
                            scale: entranceValue,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _rotationController,
                                _floatController,
                                _pulseController,
                                _glowController,
                                _sparkleController,
                              ]),
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001) // Perspective
                                        ..rotateY(_rotationAnimation.value)
                                        ..rotateZ(math.sin(_floatController.value * math.pi) * 0.1),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outermost glow - yellow
                                          Container(
                                            width: 250 * _pulseAnimation.value,
                                            height: 250 * _pulseAnimation.value,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.yellow.withOpacity(0.3 * _glowAnimation.value),
                                                  Colors.yellow.withOpacity(0.1 * _glowAnimation.value),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Middle glow - orange
                                          Container(
                                            width: 200 * _pulseAnimation.value,
                                            height: 200 * _pulseAnimation.value,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.orange.withOpacity(0.4 * _glowAnimation.value),
                                                  Colors.orange.withOpacity(0.2 * _glowAnimation.value),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Inner glow - amber
                                          Container(
                                            width: 150 * _pulseAnimation.value,
                                            height: 150 * _pulseAnimation.value,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber.withOpacity(0.8 * _glowAnimation.value),
                                                  blurRadius: 60 * _glowAnimation.value,
                                                  spreadRadius: 30 * _glowAnimation.value,
                                                ),
                                                BoxShadow(
                                                  color: Colors.yellow.withOpacity(0.6 * _glowAnimation.value),
                                                  blurRadius: 40 * _glowAnimation.value,
                                                  spreadRadius: 20 * _glowAnimation.value,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Glossy base circle
                                          Container(
                                            width: 140,
                                            height: 140,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                center: Alignment(-0.3, -0.5),
                                                colors: [
                                                  Colors.amber.shade100,
                                                  Colors.amber.shade400,
                                                  Colors.amber.shade700,
                                                  Colors.amber.shade900,
                                                ],
                                                stops: [0.0, 0.3, 0.7, 1.0],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 20,
                                                  offset: Offset(10, 10),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Trophy icon with glossy overlay
                                          Container(
                                            width: 140,
                                            height: 140,
                                            child: ShaderMask(
                                              shaderCallback: (bounds) => LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withOpacity(0.9),
                                                  Colors.amber.shade100,
                                                  Colors.amber.shade300,
                                                  Colors.amber.shade600,
                                                ],
                                                stops: [0.0, 0.3, 0.6, 1.0],
                                              ).createShader(bounds),
                                              child: Icon(
                                                Icons.emoji_events,
                                                size: 110,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.5),
                                                    blurRadius: 15,
                                                    offset: Offset(5, 5),
                                                  ),
                                                  Shadow(
                                                    color: Colors.amber.withOpacity(0.8),
                                                    blurRadius: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Glossy highlight overlay
                                          Positioned(
                                            top: 20,
                                            left: 30,
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0.6),
                                                    Colors.white.withOpacity(0.3),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Sparkle effects
                                          ...List.generate(8, (index) {
                                            final angle = (index * math.pi / 4) + (_sparkleAnimation.value * math.pi * 2);
                                            final distance = 70.0 + (math.sin(_sparkleAnimation.value * math.pi * 2) * 10);
                                            return Positioned(
                                              left: 70 + math.cos(angle) * distance - 5,
                                              top: 70 + math.sin(angle) * distance - 5,
                                              child: Opacity(
                                                opacity: (math.sin(_sparkleAnimation.value * math.pi * 2 + index) + 1) / 2,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.yellow,
                                                        blurRadius: 8,
                                                        spreadRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    )
                  else
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.local_bar,
                            size: 120,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        );
                      },
                    ),
                  SizedBox(height: 24),
                  
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.isCupFull ? 'Congratulations!' : 'Game Complete!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: Text(
                      widget.isCupFull
                          ? '🎉 Beer Cup Full - Prize Unlocked! 🎉'
                          : 'Keep trying to fill the cup!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 48),
                  
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Text(
                              'Your Score',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            Text(
                              '${widget.correctAnswers} / ${widget.totalQuestions}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                            Text(
                              '$percentage% Correct',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 48),
                  
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 1400),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        SizedBox(
                          width: 250,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: widget.onPlayAgain,
                            icon: Icon(Icons.replay),
                            label: Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        SizedBox(
                          width: 250,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: widget.onExit,
                            icon: Icon(Icons.exit_to_app, color: Colors.white),
                            label: Text('Exit', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
          ),
        ),
      ),
    );
  }
}
