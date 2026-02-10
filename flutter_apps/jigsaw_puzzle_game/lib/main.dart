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
  // static const String _baseUrl = 'http://localhost:8000/api/auth';
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
    // Don't play background music here - wait for user interaction
  }

  void _login() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter your code.');
      return;
    }
    // TODO: Re-enable API login when backend is fixed
    // Temporarily bypass login - accept any code
    _audioService.playBackgroundMusic();
    _audioService.playSound('click');
    _audioService.playSound('game_start');
    lastPlayerCode = code;
    lastPlayerName = code;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const JigsawPuzzlePage()),
    );
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
  static const Duration gameDuration = Duration(minutes: 2);

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
    
    // Glow animation for preview
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Star twinkling animation
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Pulse animation for tiles
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Float animation for tiles
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
      // If the tile is from the tray
      if (_trayTiles.contains(tileValue)) {
        _grid[gridIndex] = tileValue;
        _trayTiles.remove(tileValue);
        if (prev != null) {
          _trayTiles.add(prev);
        }
      } else {
        // The tile is from another grid cell (grid-to-grid drag)
        // Find the old position and clear it
        int oldIndex = _grid.indexOf(tileValue);
        if (oldIndex != -1) {
          _grid[oldIndex] = null;
        }
        // If the new cell had a tile, move it to the old cell
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

  void _onTileReturnedToTray(int gridIndex) {
    if (!_gameStarted || _completed || _timeUp) return;
    AudioService().playSound('click');
    setState(() {
      final tile = _grid[gridIndex];
      if (tile != null) {
        _trayTiles.add(tile);
        _grid[gridIndex] = null;
      }
    });
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
          title: const Text('Time’s up!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                // Go back to login screen
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
            onAccept: (tile) => _onTileDroppedOnGrid(tile!, index),
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
                      // Inner shadow for depth
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
                // Allow dragging back to tray or to another grid cell
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            spacing: 12,
            runSpacing: 12,
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
    // Images are named assets/jigsaw/jigsaw_piece_1.png ... jigsaw_piece_16.png
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
          // Main shadow (furthest/softest)
          BoxShadow(
            color: Colors.black.withOpacity(dragging ? 0.4 : 0.25),
            blurRadius: dragging ? 20 : 12,
            spreadRadius: dragging ? 4 : 1,
            offset: Offset(0, dragging ? 8 : 4),
          ),
          // Mid shadow
          BoxShadow(
            color: Colors.black.withOpacity(dragging ? 0.3 : 0.15),
            blurRadius: dragging ? 12 : 6,
            spreadRadius: dragging ? 2 : 0,
            offset: Offset(0, dragging ? 4 : 2),
          ),
          // Close shadow (sharpest)
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
            // Main image
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
            // Glossy overlay effect (top-left highlight)
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
            // Subtle edge highlight (left edge)
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
            // Subtle edge highlight (top edge)
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
              // Animated stars
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
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with bounce animation
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
                    
                    const SizedBox(height: 40),
                    
                    // Glowing image preview
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 300,
                          height: 300,
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
                    
                    const SizedBox(height: 40),
                    
                    // Animated instruction text
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
                                  '⏱️ You have 2 minutes! ⏱️',
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
                    
                    const SizedBox(height: 40),
                    
                    // Start button with pulse animation
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
    
    final media = MediaQuery.of(context);
    // Set grid cell size to match image size (e.g., 100x100). Adjust if your images are a different size.
    const double pieceWidth = 100;
    const double pieceHeight = 100;
    final double puzzleSize = pieceWidth * gridCols;
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final timerColor = _secondsLeft < 20 ? Colors.red : (_secondsLeft < 40 ? Colors.orange : Colors.green);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evergreen 2030 Jigsaw Challenge'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPuzzle,
            tooltip: 'Restart',
          ),
        ],
      ),
      body: StyledBackground(
        child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: timerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: timerColor, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, color: timerColor),
                            const SizedBox(width: 8),
                            Text('$minutes:$seconds',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: timerColor)),
                          ],
                        ),
                      ),
                    ),
                    if (!_gameStarted)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 12,
                            shadowColor: Colors.green.shade900,
                          ),
                          onPressed: () {
                            setState(() => _gameStarted = true);
                            _startTimer();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.play_arrow, size: 32),
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
                        border: Border.all(
                          color: Colors.purple.shade300,
                          width: 4,
                        ),
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
                        child: _buildPuzzleGrid(pieceWidth, pieceHeight),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade100,
                            Colors.cyan.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.blue.shade700, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Drag these tiles into the grid:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: pieceHeight + 24,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildTray(pieceWidth, pieceHeight),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_completed && _showCelebration)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          children: const [
                            Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                            SizedBox(height: 8),
                            Text('Level 2 Qualified!', style: TextStyle(fontSize: 20, color: Colors.green)),
                            SizedBox(height: 8),
                            Text('You win Heineken Merch!', style: TextStyle(fontSize: 18, color: Colors.black)),
                          ],
                        ),
                      ),
                    if (_timeUp)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          children: const [
                            Icon(Icons.timer_off, color: Colors.red, size: 48),
                            SizedBox(height: 8),
                            Text('Time’s up!', style: TextStyle(fontSize: 20, color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}
