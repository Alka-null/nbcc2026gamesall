import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'backend_service.dart';
import 'package:jigsaw_puzzle_game/services/audio_service.dart';
import 'package:jigsaw_puzzle_game/widgets/styled_background.dart';

void main() => runApp(const JigsawPuzzleApp());

class JigsawPuzzleApp extends StatelessWidget {
  const JigsawPuzzleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _baseUrl = 'https://nbcc2026gamesbackend.onrender.com/api/auth';
  final TextEditingController _codeController = TextEditingController();
  final AudioService _audioService = AudioService();
  String? _error;
  bool _isLoading = false;
  static String? lastPlayerCode;
  static String? lastPlayerName;

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/code-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'unique_code': code}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final playerName = data['player']?['name'] ?? code;
        _audioService.playBackgroundMusic();
        _audioService.playSound('click');
        _audioService.playSound('game_start');
        lastPlayerCode = code;
        lastPlayerName = playerName;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JigsawPuzzlePage()),
        );
      } else {
        setState(() => _error = 'Invalid code. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: StyledBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Enter your code to play:', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
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
                child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JigsawPuzzlePage extends StatefulWidget {
  const JigsawPuzzlePage({super.key});
  @override
  State<JigsawPuzzlePage> createState() => _JigsawPuzzlePageState();
}

class _JigsawPuzzlePageState extends State<JigsawPuzzlePage> with TickerProviderStateMixin {
  static const int gridRows = 4;
  static const int gridCols = 4;
  static const int totalPieces = gridRows * gridCols;
  static const Duration gameDuration = Duration(minutes: 1);

  final BackendService _backendService = BackendService();
  late List<int?> _grid;
  late List<int> _trayTiles;
  late List<int> _solution;
  bool _completed = false;
  bool _timeUp = false;
  Timer? _timer;
  int _secondsLeft = gameDuration.inSeconds;
  bool _showCelebration = false;
  bool _gameStarted = false;
  bool _submittingResult = false;
  bool _showPreview = true;
  
  late AnimationController _glowController;
  late AnimationController _starController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _solution = List.generate(totalPieces, (i) => i);
    _resetPuzzle();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _starController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _resetPuzzle() {
    _grid = List<int?>.filled(totalPieces, null);
    _trayTiles = List<int>.from(_solution);
    _trayTiles.shuffle(Random());
    setState(() {
      _completed = false;
      _showCelebration = false;
      _timeUp = false;
      _gameStarted = false;
      _secondsLeft = gameDuration.inSeconds;
    });
    _timer?.cancel();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = gameDuration.inSeconds;
    _timeUp = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_completed || !_gameStarted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _timeUp = true;
          timer.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  void _startGame() {
    AudioService().playSound('click');
    setState(() {
      _gameStarted = true;
    });
    _startTimer();
  }

  void _onTileDroppedOnGrid(int tileValue, int gridIndex) {
    if (!_gameStarted || _completed || _timeUp) return;
    AudioService().playSound('click');
    setState(() {
      final prev = _grid[gridIndex];
      if (_trayTiles.contains(tileValue)) {
        _grid[gridIndex] = tileValue;
        _trayTiles.remove(tileValue);
        if (prev != null) {
          _trayTiles.add(prev);
        }
      } else {
        int oldIndex = _grid.indexOf(tileValue);
        if (oldIndex != -1) {
          _grid[oldIndex] = null;
        }
        if (prev != null && oldIndex != -1) {
          _grid[oldIndex] = prev;
        }
        _grid[gridIndex] = tileValue;
      }
    });
    if (_trayTiles.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), _showCompletionCheckDialog);
    }
  }

  void _showCompletionCheckDialog() async {
    bool correct = _isSolved();
    if (correct) {
      AudioService().playSound('success');
    } else {
      AudioService().playSound('error');
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(correct ? 'Puzzle Complete!' : 'Incorrect Solution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(correct ? Icons.check_circle : Icons.error,
                color: correct ? Colors.green : Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(correct
                ? 'Congratulations! You solved the puzzle.'
                : 'Some pieces are not in the correct place.'),
          ],
        ),
        actions: [
          if (correct)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _completed = true;
                  _showCelebration = true;
                });
                _timer?.cancel();
                Future.delayed(const Duration(milliseconds: 500), _showSuccessDialog);
              },
              child: const Text('OK'),
            ),
          if (!correct)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Keep Trying'),
            ),
        ],
      ),
    );
  }

  bool _isSolved() {
    for (int i = 0; i < totalPieces; i++) {
      if (_grid[i] != _solution[i]) return false;
    }
    return true;
  }

  void _showSuccessDialog() async {
    setState(() { _submittingResult = true; });
    String? error;
    try {
      final code = _LoginScreenState.lastPlayerCode ?? '';
      final timeTaken = gameDuration.inSeconds - _secondsLeft;
      await _backendService.submitJigsawResult(
        playerCode: code,
        timeTaken: timeTaken,
        completed: true,
      );
    } catch (e) {
      error = e.toString();
    }
    setState(() { _submittingResult = false; });
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 400),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            error == null ? 'Congratulations!' : 'Result Saved Error',
            style: TextStyle(
              color: error == null ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                error == null ? Icons.emoji_events : Icons.error,
                color: error == null ? Colors.amber : Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(error == null
                  ? 'Puzzle completed in time!\nLevel 2 Qualified!\nYou win Heineken Merch! 🎁'
                  : 'Could not save your result. Please check your connection.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetPuzzle();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeUpDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 400),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Time''s up!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.timer_off, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text('You did not finish in time.'),
              SizedBox(height: 8),
              Text('Try again!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleGrid(double pieceWidth, double pieceHeight) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCols,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: totalPieces,
      itemBuilder: (context, index) {
        final tileValue = _grid[index];
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          child: DragTarget<int>(
            onWillAccept: (tile) =>
                tile != null && tile != tileValue && !_completed && !_timeUp && (_trayTiles.contains(tile) || _grid.contains(tile)),
            onAccept: (tile) => _onTileDroppedOnGrid(tile, index),
            builder: (context, candidateData, rejectedData) {
              if (tileValue == null) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: pieceWidth,
                  height: pieceHeight,
                  decoration: BoxDecoration(
                    gradient: candidateData.isNotEmpty
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade100,
                              Colors.blue.shade200,
                              Colors.blue.shade300,
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: candidateData.isNotEmpty ? Colors.blue.shade400 : Colors.grey.shade400,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(-1, -1),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Draggable<int>(
                  data: tileValue,
                  feedback: _buildPuzzlePiece(tileValue, pieceWidth, pieceHeight, dragging: true),
                  childWhenDragging: Container(
                    width: pieceWidth,
                    height: pieceHeight,
                    color: Colors.grey[100],
                  ),
                  child: _buildPuzzlePiece(tileValue, pieceWidth, pieceHeight),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildTray(double pieceWidth, double pieceHeight) {
    return DragTarget<int>(
      onWillAccept: (tileValue) => tileValue != null && !_trayTiles.contains(tileValue),
      onAccept: (tileValue) {
        int gridIndex = _grid.indexOf(tileValue);
        if (gridIndex != -1) {
          setState(() {
            _grid[gridIndex] = null;
            _trayTiles.add(tileValue);
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.green.shade100,
                Colors.green.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.shade300,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trayTiles
                .map(
                  (tileValue) => AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, _floatController]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Draggable<int>(
                          data: tileValue,
                          feedback: _buildPuzzlePiece(tileValue, pieceWidth, pieceHeight, dragging: true),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: Transform.scale(
                              scale: 0.9,
                              child: _buildPuzzlePiece(tileValue, pieceWidth, pieceHeight),
                            ),
                          ),
                          child: _buildPuzzlePiece(tileValue, pieceWidth, pieceHeight),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildPuzzlePiece(int tileValue, double width, double height, {bool dragging = false}) {
    final imagePath = 'assets/jigsaw/jigsaw_piece_${tileValue + 1}.png';
    
    Widget pieceContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dragging
              ? [
                  Colors.white.withOpacity(0.95),
                  Colors.blue.shade50.withOpacity(0.9),
                  Colors.blue.shade100.withOpacity(0.85),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dragging ? 0.4 : 0.25),
            blurRadius: dragging ? 20 : 12,
            spreadRadius: dragging ? 4 : 1,
            offset: Offset(0, dragging ? 8 : 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(dragging ? 0.3 : 0.15),
            blurRadius: dragging ? 12 : 6,
            spreadRadius: dragging ? 2 : 0,
            offset: Offset(0, dragging ? 4 : 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(dragging ? 0.2 : 0.1),
            blurRadius: dragging ? 4 : 2,
            spreadRadius: 0,
            offset: Offset(0, dragging ? 2 : 1),
          ),
        ],
        border: Border.all(
          color: dragging ? Colors.blue.shade400 : Colors.grey.shade300,
          width: dragging ? 3 : 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            SizedBox(
              width: width,
              height: height,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blueAccent.shade100,
                          Colors.blueAccent.shade200,
                          Colors.blueAccent.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${tileValue + 1}',
                        style: TextStyle(
                          fontSize: width * 0.4,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: width * 0.5,
              bottom: height * 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(dragging ? 0.4 : 0.3),
                      Colors.white.withOpacity(dragging ? 0.2 : 0.15),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.1,
              left: 0,
              bottom: height * 0.3,
              width: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: width * 0.1,
              right: width * 0.3,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    if (dragging) {
      return Transform.scale(
        scale: 1.1,
        child: pieceContent,
      );
    }
    
    return pieceContent;
  }

  Widget _buildPreviewScreen(BuildContext context) {
    return Scaffold(
      body: StyledBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.purple.shade900.withOpacity(0.3),
                Colors.blue.shade900.withOpacity(0.4),
                Colors.indigo.shade900.withOpacity(0.5),
              ],
              center: Alignment.center,
              radius: 1.5,
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(30, (index) {
                final random = Random(index);
                return AnimatedBuilder(
                  animation: _starController,
                  builder: (context, child) {
                    final offset = (_starController.value + random.nextDouble()) % 1.0;
                    final opacity = (sin(offset * 2 * pi) + 1) / 2;
                    return Positioned(
                      left: random.nextDouble() * MediaQuery.of(context).size.width,
                      top: random.nextDouble() * MediaQuery.of(context).size.height,
                      child: Icon(
                        Icons.star,
                        color: [Colors.yellow, Colors.amber, Colors.orange, Colors.pink, Colors.purple][random.nextInt(5)]
                            .withOpacity(opacity * 0.8),
                        size: 15 + random.nextDouble() * 20,
                      ),
                    );
                  },
                );
              }),
              
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Text(
                                '🎯 Complete the Puzzle! 🎯',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [Colors.yellow, Colors.orange, Colors.pink],
                                ).createShader(Rect.fromLTWH(0, 0, 500, 70)),
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.purple.withOpacity(0.5),
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(_glowAnimation.value * 0.6),
                                blurRadius: 30 * _glowAnimation.value,
                                spreadRadius: 10 * _glowAnimation.value,
                              ),
                              BoxShadow(
                                color: Colors.orange.withOpacity(_glowAnimation.value * 0.4),
                                blurRadius: 40 * _glowAnimation.value,
                                spreadRadius: 15 * _glowAnimation.value,
                              ),
                              BoxShadow(
                                color: Colors.pink.withOpacity(_glowAnimation.value * 0.3),
                                blurRadius: 50 * _glowAnimation.value,
                                spreadRadius: 20 * _glowAnimation.value,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(_glowAnimation.value),
                                  width: 4,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                'assets/jigsaw_image.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                          Colors.green.shade800,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.extension, size: 80, color: Colors.white.withOpacity(0.8)),
                                          const SizedBox(height: 16),
                                          Text(
                                            'EVERGREEN 2030',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Growth • Productivity • Future-Fit',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade700.withOpacity(0.8),
                                  Colors.indigo.shade700.withOpacity(0.8),
                                  Colors.purple.shade700.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '🧩 Arrange the puzzle pieces to match this image! 🧩',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '⏱️ You have 1 minute! ⏱️',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.amber.shade200,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(_glowAnimation.value * 0.6),
                                      blurRadius: 30 * _glowAnimation.value,
                                      spreadRadius: 8 * _glowAnimation.value,
                                    ),
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(_glowAnimation.value * 0.4),
                                      blurRadius: 40 * _glowAnimation.value,
                                      spreadRadius: 12 * _glowAnimation.value,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    AudioService().playSound('click');
                                    setState(() {
                                      _showPreview = false;
                                      _startGame();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 12,
                                    shadowColor: Colors.green.shade900,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.play_arrow, size: 36),
                                      SizedBox(width: 12),
                                      Text('START PUZZLE!'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showPreview) {
      return _buildPreviewScreen(context);
    }

    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final timerColor = _secondsLeft < 20 ? Colors.red : (_secondsLeft < 40 ? Colors.orange : Colors.green);

    return Scaffold(
      body: StyledBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              const topBarH = 48.0;
              const spacing = 6.0;
              final startBtnH = !_gameStarted ? 52.0 : 0.0;
              final bottomH = screenH * 0.30;
              final puzzleAreaH = screenH - topBarH - spacing * 3 - bottomH - startBtnH;
              final maxPuzzleSize = min(screenW - 32.0, puzzleAreaH);
              final pieceSize = maxPuzzleSize / gridCols;
              final puzzleSize = pieceSize * gridCols;
              final trayPieceSize = min(pieceSize * 0.85, (bottomH - 32) / 3.5);
              final previewSize = min(bottomH - 28, screenW * 0.25);

              return Column(
                children: [
                  Container(
                    height: topBarH,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: timerColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: timerColor, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer, color: timerColor, size: 20),
                              const SizedBox(width: 6),
                              Text('$minutes:$seconds',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: timerColor)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text('Jigsaw Challenge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
                        const Spacer(),
                        IconButton(icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.9)), onPressed: _resetPuzzle, tooltip: 'Restart', iconSize: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: spacing),
                  if (!_gameStarted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                          shadowColor: Colors.green.shade900,
                        ),
                        onPressed: () {
                          setState(() => _gameStarted = true);
                          _startTimer();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_arrow, size: 28),
                            SizedBox(width: 8),
                            Text('Start Puzzle'),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    width: puzzleSize + 16,
                    height: puzzleSize + 16,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.indigo.shade100,
                          Colors.purple.shade100,
                          Colors.pink.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.shade300, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: puzzleSize,
                      height: puzzleSize,
                      child: _buildPuzzleGrid(pieceSize, pieceSize),
                    ),
                  ),
                  const SizedBox(height: spacing),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Reference', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade200)),
                              const SizedBox(height: 4),
                              Container(
                                width: previewSize,
                                height: previewSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade400, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/jigsaw_image.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.green.shade700,
                                        child: const Center(
                                          child: Icon(Icons.extension, size: 40, color: Colors.white),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTray(trayPieceSize, trayPieceSize),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
