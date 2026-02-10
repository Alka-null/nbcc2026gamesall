import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../utils/game_state.dart';
import '../widgets/animated_background.dart';

class BeerCupScreen extends StatefulWidget {
  const BeerCupScreen({super.key});

  @override
  State<BeerCupScreen> createState() => _BeerCupScreenState();
}

class _BeerCupScreenState extends State<BeerCupScreen> with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  double _beerLevel = 0.0;
  bool _showFeedback = false;
  bool _isCorrect = false;

  final List<ScenarioQuestion> _questions = [
    ScenarioQuestion(
      scenario: 'A customer wants to increase order frequency but has cash flow concerns',
      options: [
        'Offer extended payment terms through HSOV',
        'Reduce product selection',
        'Decline the request',
        'Only accept cash payments',
      ],
      correctAnswer: 0,
      explanation: 'HSOV provides flexible payment terms to address cash flow concerns while growing orders',
    ),
    ScenarioQuestion(
      scenario: 'You notice declining sales in a territory with high potential',
      options: [
        'Use DMS analytics to identify underperforming outlets',
        'Ignore it and focus on high performers',
        'Reduce visits to the territory',
        'Lower prices across the board',
      ],
      correctAnswer: 0,
      explanation: 'DMS analytics help identify specific issues and opportunities for targeted interventions',
    ),
    ScenarioQuestion(
      scenario: 'A new customer wants to onboard quickly with minimal paperwork',
      options: [
        'Use QuickDrinks for instant ordering',
        'Tell them to wait for traditional process',
        'Manually process everything',
        'Reject the customer',
      ],
      correctAnswer: 0,
      explanation: 'QuickDrinks streamlines onboarding and ordering for faster customer acquisition',
    ),
    ScenarioQuestion(
      scenario: 'You need to track real-time inventory across multiple outlets',
      options: [
        'Use digital tools for live inventory tracking',
        'Call each outlet individually',
        'Wait for monthly reports',
        'Estimate based on past data',
      ],
      correctAnswer: 0,
      explanation: 'Digital tools provide real-time visibility for better inventory management',
    ),
    ScenarioQuestion(
      scenario: 'A customer has questions about product availability and pricing',
      options: [
        'Use SOT to show live catalog and prices',
        'Promise to call back tomorrow',
        'Guess the information',
        'Refer them to someone else',
      ],
      correctAnswer: 0,
      explanation: 'SOT provides instant access to current product information and pricing',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _questions.shuffle();
  }

  void _answerQuestion(int selectedIndex) {
    final isCorrect = selectedIndex == _questions[_currentQuestion].correctAnswer;
    
    setState(() {
      _showFeedback = true;
      _isCorrect = isCorrect;
      
      if (isCorrect) {
        _correctAnswers++;
        _beerLevel = math.min(1.0, (_correctAnswers / _questions.length));
        
        final gameState = Provider.of<GameState>(context, listen: false);
        gameState.updateBeerCup(((_beerLevel * 100).toInt()), _correctAnswers);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          _currentQuestion++;
          
          if (_currentQuestion >= _questions.length) {
            _showCompletionDialog();
          }
        });
      }
    });
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
            gradient: const LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBBF24).withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_bar,
                size: 120,
                color: Colors.white,
              ).animate().scale(duration: 600.ms).then().shake(),
              const SizedBox(height: 24),
              Text(
                _beerLevel >= 1.0 ? 'Beer Cup Full!' : 'Challenge Complete!',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Correct Answers: $_correctAnswers/${_questions.length}',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF59E0B),
                ),
                child: const Text('Continue'),
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
                              'Filling A Beer Cup',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const Text(
                              'Choose the right action for each scenario',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentQuestion + 1}/${_questions.length}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Game Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      children: [
                        // Beer Cup Visualization
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Your Progress',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: 300,
                                  height: 500,
                                  child: CustomPaint(
                                    painter: BeerCupPainter(_beerLevel),
                                  ).animate(target: _beerLevel > 0 ? 1 : 0)
                                      .shimmer(duration: 1000.ms),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '${(_beerLevel * 100).toInt()}% Full',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 48),

                        // Question and Options
                        Expanded(
                          flex: 2,
                          child: _currentQuestion < _questions.length
                              ? Container(
                                  padding: const EdgeInsets.all(48),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Scenario',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: AppTheme.textGray,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _questions[_currentQuestion].scenario,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 48),
                                      if (!_showFeedback)
                                        ..._questions[_currentQuestion]
                                            .options
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: _buildOptionButton(
                                              entry.value,
                                              entry.key,
                                            ).animate().fadeIn(delay: (entry.key * 100).ms).slideX(),
                                          );
                                        })
                                      else
                                        _buildFeedback(),
                                    ],
                                  ),
                                ).animate().fadeIn()
                              : const SizedBox.shrink(),
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

  Widget _buildOptionButton(String text, int index) {
    return ElevatedButton(
      onPressed: () => _answerQuestion(index),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.cardBg,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(24),
        minimumSize: const Size(double.infinity, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppTheme.accentGreen.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCorrect ? AppTheme.accentGreen : Colors.red,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? AppTheme.accentGreen : Colors.red,
                size: 48,
              ),
              const SizedBox(width: 16),
              Text(
                _isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect ? AppTheme.accentGreen : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _questions[_currentQuestion].explanation,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}

class BeerCupPainter extends CustomPainter {
  final double fillLevel;

  BeerCupPainter(this.fillLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final cupPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw cup outline (trapezoid shape)
    final cupPath = Path();
    cupPath.moveTo(size.width * 0.2, 0);
    cupPath.lineTo(size.width * 0.8, 0);
    cupPath.lineTo(size.width * 0.9, size.height);
    cupPath.lineTo(size.width * 0.1, size.height);
    cupPath.close();

    canvas.drawPath(cupPath, cupPaint);

    // Draw beer fill
    if (fillLevel > 0) {
      final beerPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      final fillHeight = size.height * fillLevel;
      final topY = size.height - fillHeight;

      final beerPath = Path();
      final topWidth = size.width * 0.2 + (size.width * 0.7) * (topY / size.height);
      final bottomWidth = size.width * 0.8;

      beerPath.moveTo(size.width * 0.5 - topWidth / 2, topY);
      beerPath.lineTo(size.width * 0.5 + topWidth / 2, topY);
      beerPath.lineTo(size.width * 0.9, size.height);
      beerPath.lineTo(size.width * 0.1, size.height);
      beerPath.close();

      canvas.drawPath(beerPath, beerPaint);

      // Draw foam/bubbles
      final foamPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 5; i++) {
        canvas.drawCircle(
          Offset(
            size.width * (0.3 + i * 0.1),
            topY - 10,
          ),
          8,
          foamPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BeerCupPainter oldDelegate) =>
      fillLevel != oldDelegate.fillLevel;
}

class ScenarioQuestion {
  final String scenario;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  ScenarioQuestion({
    required this.scenario,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}
