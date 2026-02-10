import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';
import '../widgets/animated_background.dart';

class EnablersQuizScreen extends StatefulWidget {
  const EnablersQuizScreen({super.key});

  @override
  State<EnablersQuizScreen> createState() => _EnablersQuizScreenState();
}

class _EnablersQuizScreenState extends State<EnablersQuizScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  bool _quizStarted = false;
  bool _showAnswer = false;
  int? _selectedAnswer;

  final List<QuizQuestion> _questions = [
    QuizQuestion(
      question: 'What does SOT stand for?',
      options: ['Sales Order Tool', 'System Order Terminal', 'Sales Online Terminal', 'Service Order Tool'],
      correctAnswer: 0,
      category: 'Digital Tools',
    ),
    QuizQuestion(
      question: 'Which tool helps with route optimization?',
      options: ['QuickDrinks', 'DMS', 'AIDDA', 'Asset Management'],
      correctAnswer: 2,
      category: 'Digital Tools',
    ),
    QuizQuestion(
      question: 'What is the primary benefit of HSOV?',
      options: ['Inventory tracking', 'Flexible payment terms', 'Route planning', 'Product catalog'],
      correctAnswer: 1,
      category: 'Sales Enablers',
    ),
    QuizQuestion(
      question: 'DMS stands for?',
      options: ['Digital Market System', 'Distribution Management System', 'Data Management Service', 'Direct Market Sales'],
      correctAnswer: 1,
      category: 'Digital Tools',
    ),
    QuizQuestion(
      question: 'Which platform enables instant ordering for customers?',
      options: ['SOT', 'QuickDrinks', 'AIDDA', 'SEM'],
      correctAnswer: 1,
      category: 'Digital Tools',
    ),
    QuizQuestion(
      question: 'What does SEM help manage?',
      options: ['Social media', 'Sales execution and monitoring', 'Stock emergency', 'System error messages'],
      correctAnswer: 1,
      category: 'Sales Enablers',
    ),
    QuizQuestion(
      question: 'Asset Management tools help with?',
      options: ['Employee training', 'Tracking coolers and equipment', 'Financial reporting', 'Customer service'],
      correctAnswer: 1,
      category: 'Sales Enablers',
    ),
    QuizQuestion(
      question: 'Which tool provides real-time analytics?',
      options: ['QuickDrinks', 'DMS', 'HSOV', 'Manual reports'],
      correctAnswer: 1,
      category: 'Digital Tools',
    ),
    QuizQuestion(
      question: 'AIDDA helps with?',
      options: ['Automated Intelligent Distribution and Delivery Analysis', 'Asset Inventory Data', 'AI Direct Delivery', 'All Digital Applications'],
      correctAnswer: 0,
      category: 'Digital Tools',
    ),
    QuizQuestion(
      question: 'The main purpose of sales enablers is to?',
      options: ['Replace sales teams', 'Empower sales teams to perform better', 'Reduce customer interactions', 'Eliminate manual work completely'],
      correctAnswer: 1,
      category: 'Sales Enablers',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _questions.shuffle();
  }

  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _currentQuestion = 0;
      _score = 0;
    });
  }

  void _answerQuestion(int selectedIndex) {
    setState(() {
      _selectedAnswer = selectedIndex;
      _showAnswer = true;
      
      if (selectedIndex == _questions[_currentQuestion].correctAnswer) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      var completedQuiz = false;
      setState(() {
        _showAnswer = false;
        _selectedAnswer = null;
        _currentQuestion++;

        if (_currentQuestion >= _questions.length) {
          completedQuiz = true;
        }
      });

      if (completedQuiz) {
        await _showResults();
      }
    });
  }

  Future<void> _showResults() async {
    final gameState = Provider.of<GameState>(context, listen: false);
    final synced = await gameState.recordQuizResult(
      score: _score,
      totalQuestions: _questions.length,
    );

    if (!mounted) return;

    if (!synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to reach the server. Score saved locally.'),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: AppTheme.greenGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGreen.withOpacity(0.5),
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
                'Quiz Complete!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Score: $_score/${_questions.length}',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${((_score / _questions.length) * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              if (_score >= _questions.length * 0.7)
                const Text(
                  '🏆 Growth Champion! 🏆',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn().scale(),
              const SizedBox(height: 32),
              if (gameState.leaderboard.isNotEmpty) ...[
                const Text(
                  'Live Leaderboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ...gameState.leaderboard
                    .asMap()
                    .entries
                    .take(5)
                    .map((entry) => _buildLeaderboardRow(entry.key, entry.value)),
                const SizedBox(height: 32),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _quizStarted = false;
                        _currentQuestion = 0;
                        _score = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.accentGreen,
                    ),
                    child: const Text('Play Again'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                              'How Well Do You Know Your Enablers?',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const Text(
                              'Test your knowledge of sales tools and enablers',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_quizStarted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.greenGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Score',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                '$_score/${_currentQuestion}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2000.ms),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Center(
                    child: !_quizStarted
                        ? _buildStartScreen()
                        : _buildQuizScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(int position, Map<String, dynamic> entry) {
    final rank = position + 1;
    final name = entry['name']?.toString() ?? 'Player';
    final score = entry['score'] as int? ?? 0;
    final percentage = entry['percentage'];
    final percentText = percentage is num ? '${percentage.toStringAsFixed(1)}%' : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            rank.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '$score pts',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          if (percentText.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              percentText,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      width: 800,
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.quiz,
            size: 120,
            color: AppTheme.accentGreen,
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 32),
          const Text(
            'Ready to Test Your Knowledge?',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            '10 Questions about Sales Enablers',
            style: TextStyle(
              fontSize: 24,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _startQuiz,
            icon: const Icon(Icons.play_arrow, size: 32),
            label: const Text('Start Quiz', style: TextStyle(fontSize: 24)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
            ),
          ).animate().fadeIn(delay: 500.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    if (_currentQuestion >= _questions.length) {
      return const SizedBox.shrink();
    }

    final question = _questions[_currentQuestion];

    return Container(
      width: 1000,
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question.category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Question ${_currentQuestion + 1}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 20,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrect = index == question.correctAnswer;
            final isSelected = index == _selectedAnswer;

            Color? backgroundColor;
            Color? borderColor;
            IconData? icon;

            if (_showAnswer) {
              if (isCorrect) {
                backgroundColor = AppTheme.accentGreen.withOpacity(0.2);
                borderColor = AppTheme.accentGreen;
                icon = Icons.check_circle;
              } else if (isSelected && !isCorrect) {
                backgroundColor = Colors.red.withOpacity(0.2);
                borderColor = Colors.red;
                icon = Icons.cancel;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: _showAnswer ? null : () => _answerQuestion(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor ?? AppTheme.cardBg,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(24),
                  minimumSize: const Size(double.infinity, 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: borderColor ?? Colors.white.withOpacity(0.2),
                      width: borderColor != null ? 3 : 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: borderColor != null
                            ? null
                            : AppTheme.primaryGradient,
                        color: borderColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: icon != null
                            ? Icon(icon, color: Colors.white)
                            : Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(),
            );
          }),
        ],
      ),
    ).animate().fadeIn();
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String category;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
  });
}
