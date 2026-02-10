import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../utils/game_state.dart';
import '../widgets/animated_background.dart';

class JigsawPuzzleScreen extends StatefulWidget {
  const JigsawPuzzleScreen({super.key});

  @override
  State<JigsawPuzzleScreen> createState() => _JigsawPuzzleScreenState();
}

class _JigsawPuzzleScreenState extends State<JigsawPuzzleScreen> {
  final StopWatchTimer _timer = StopWatchTimer();
  final List<PuzzlePiece> _pieces = [];
  final List<PuzzlePiece?> _board = List.filled(16, null);
  PuzzlePiece? _draggedPiece;
  bool _gameStarted = false;
  bool _gameCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
  }

  void _initializePuzzle() {
    // Create 16 puzzle pieces with Evergreen 2030 labels
    final labels = [
      'Growth', 'Productivity', 'Future-Fit', 'Innovation',
      'Customer\nFocus', 'Efficiency', 'Sustainability', 'Quality',
      'Market\nExpansion', 'Cost\nManagement', 'Digital\nTransform', 'Excellence',
      'Revenue\nGrowth', 'Operational\nExcellence', 'Agility', 'Leadership'
    ];

    for (int i = 0; i < 16; i++) {
      _pieces.add(PuzzlePiece(
        id: i,
        correctPosition: i,
        label: labels[i],
        color: _getColorForIndex(i),
      ));
    }
    _pieces.shuffle();
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];
    return colors[index % colors.length];
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _timer.onStartTimer();
    });
  }

  void _checkCompletion() {
    bool isComplete = true;
    for (int i = 0; i < _board.length; i++) {
      if (_board[i] == null || _board[i]!.correctPosition != i) {
        isComplete = false;
        break;
      }
    }

    if (isComplete && !_gameCompleted) {
      setState(() {
        _gameCompleted = true;
        _timer.onStopTimer();
      });

      final gameState = Provider.of<GameState>(context, listen: false);
      gameState.completeJigsaw(_timer.secondTime.value);

      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 120,
                color: Colors.white,
              ).animate().scale(duration: 600.ms).then().shake(),
              const SizedBox(height: 24),
              const Text(
                'Puzzle Completed!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<int>(
                stream: _timer.secondTime,
                builder: (context, snapshot) {
                  final value = snapshot.data ?? 0;
                  return Text(
                    'Time: ${value}s',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryGold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64,
                    vertical: 24,
                  ),
                ),
                child: const Text(
                  'Continue to Next Challenge',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 32),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jigsaw Puzzle Challenge',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const Text(
                              'Build the 2030 Evergreen Drivers',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timer
                      if (_gameStarted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: StreamBuilder<int>(
                            stream: _timer.secondTime,
                            builder: (context, snapshot) {
                              final value = snapshot.data ?? 0;
                              return Text(
                                '${value}s',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2000.ms),
                    ],
                  ),
                ),

                // Game Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      children: [
                        // Puzzle Board (4x4 grid)
                        Expanded(
                          flex: 3,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppTheme.primaryGold.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                                itemCount: 16,
                                itemBuilder: (context, index) {
                                  return DragTarget<PuzzlePiece>(
                                    onWillAcceptWithDetails: (details) => true,
                                    onAcceptWithDetails: (details) {
                                      setState(() {
                                        _board[index] = details.data;
                                        _pieces.remove(details.data);
                                      });
                                      _checkCompletion();
                                    },
                                    builder: (context, candidateData, rejectedData) {
                                      final piece = _board[index];
                                      final isCorrect = piece?.correctPosition == index;

                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: piece != null
                                              ? LinearGradient(
                                                  colors: [
                                                    piece.color,
                                                    piece.color.withOpacity(0.7),
                                                  ],
                                                )
                                              : null,
                                          color: piece == null
                                              ? Colors.white.withOpacity(0.05)
                                              : null,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isCorrect
                                                ? AppTheme.accentGreen
                                                : Colors.white.withOpacity(0.2),
                                            width: isCorrect ? 3 : 1,
                                          ),
                                        ),
                                        child: piece != null
                                            ? Center(
                                                child: Text(
                                                  piece.label,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        // Pieces Bank
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Puzzle Pieces',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 24),
                                if (!_gameStarted)
                                  Expanded(
                                    child: Center(
                                      child: ElevatedButton.icon(
                                        onPressed: _startGame,
                                        icon: const Icon(Icons.play_arrow, size: 32),
                                        label: const Text('Start Game'),
                                      ).animate().scale(delay: 500.ms),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                      ),
                                      itemCount: _pieces.length,
                                      itemBuilder: (context, index) {
                                        final piece = _pieces[index];
                                        return Draggable<PuzzlePiece>(
                                          data: piece,
                                          feedback: Material(
                                            color: Colors.transparent,
                                            child: Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    piece.color,
                                                    piece.color.withOpacity(0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: piece.color.withOpacity(0.5),
                                                    blurRadius: 20,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  piece.label,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                style: BorderStyle.solid,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  piece.color,
                                                  piece.color.withOpacity(0.7),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                piece.label,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzlePiece {
  final int id;
  final int correctPosition;
  final String label;
  final Color color;

  PuzzlePiece({
    required this.id,
    required this.correctPosition,
    required this.label,
    required this.color,
  });
}
