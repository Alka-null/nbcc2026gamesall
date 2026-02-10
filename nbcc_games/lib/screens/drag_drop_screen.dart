import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';
import '../widgets/animated_background.dart';

class DragDropScreen extends StatefulWidget {
  const DragDropScreen({super.key});

  @override
  State<DragDropScreen> createState() => _DragDropScreenState();
}

class _DragDropScreenState extends State<DragDropScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _evergreen2030Score = 0;
  int _performanceScore = 0;

  final Map<String, String?> _evergreenAnswers = {};
  final Map<String, String?> _performanceAnswers = {};

  // Evergreen 2030 Categories
  final List<String> evergreenCategories = ['Growth', 'Productivity', 'Future-Fit'];
  
  // Performance Drivers Categories
  final List<String> performanceCategories = ['Winning', 'Delivering', 'Transforming'];

  final List<DragDropQuestion> evergreenQuestions = [
    DragDropQuestion(
      id: '1',
      statement: 'Expand market share in emerging markets',
      correctAnswer: 'Growth',
    ),
    DragDropQuestion(
      id: '2',
      statement: 'Optimize supply chain efficiency',
      correctAnswer: 'Productivity',
    ),
    DragDropQuestion(
      id: '3',
      statement: 'Invest in sustainable packaging solutions',
      correctAnswer: 'Future-Fit',
    ),
    DragDropQuestion(
      id: '4',
      statement: 'Launch new product innovations',
      correctAnswer: 'Growth',
    ),
    DragDropQuestion(
      id: '5',
      statement: 'Reduce operational costs',
      correctAnswer: 'Productivity',
    ),
    DragDropQuestion(
      id: '6',
      statement: 'Implement digital transformation initiatives',
      correctAnswer: 'Future-Fit',
    ),
    DragDropQuestion(
      id: '7',
      statement: 'Increase revenue per outlet',
      correctAnswer: 'Growth',
    ),
    DragDropQuestion(
      id: '8',
      statement: 'Improve asset utilization',
      correctAnswer: 'Productivity',
    ),
  ];

  final List<DragDropQuestion> performanceQuestions = [
    DragDropQuestion(
      id: 'p1',
      statement: 'Achieve sales targets consistently',
      correctAnswer: 'Winning',
    ),
    DragDropQuestion(
      id: 'p2',
      statement: 'Execute orders with 100% accuracy',
      correctAnswer: 'Delivering',
    ),
    DragDropQuestion(
      id: 'p3',
      statement: 'Adopt new digital tools and processes',
      correctAnswer: 'Transforming',
    ),
    DragDropQuestion(
      id: 'p4',
      statement: 'Outperform competitors in market share',
      correctAnswer: 'Winning',
    ),
    DragDropQuestion(
      id: 'p5',
      statement: 'Meet customer expectations on time',
      correctAnswer: 'Delivering',
    ),
    DragDropQuestion(
      id: 'p6',
      statement: 'Implement AI-driven insights',
      correctAnswer: 'Transforming',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    evergreenQuestions.shuffle();
    performanceQuestions.shuffle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkAnswer(String questionId, String answer, bool isEvergreen) {
    final questions = isEvergreen ? evergreenQuestions : performanceQuestions;
    final answers = isEvergreen ? _evergreenAnswers : _performanceAnswers;
    
    final question = questions.firstWhere((q) => q.id == questionId);
    
    setState(() {
      answers[questionId] = answer;
      
      if (answer == question.correctAnswer) {
        if (isEvergreen) {
          _evergreen2030Score++;
        } else {
          _performanceScore++;
        }
      }
    });

    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.updateDragDrop(_evergreen2030Score + _performanceScore);
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
                              'Drag & Drop Challenge',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const Text(
                              'Match statements to the correct category',
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
                          gradient: AppTheme.goldGradient,
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
                              '${_evergreen2030Score + _performanceScore}',
                              style: const TextStyle(
                                fontSize: 36,
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

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryGold,
                  labelColor: AppTheme.primaryGold,
                  unselectedLabelColor: AppTheme.textGray,
                  labelStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: 'Evergreen 2030'),
                    Tab(text: 'Performance Drivers'),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDragDropArea(
                        evergreenCategories,
                        evergreenQuestions,
                        _evergreenAnswers,
                        true,
                      ),
                      _buildDragDropArea(
                        performanceCategories,
                        performanceQuestions,
                        _performanceAnswers,
                        false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragDropArea(
    List<String> categories,
    List<DragDropQuestion> questions,
    Map<String, String?> answers,
    bool isEvergreen,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drop Zones (Categories)
          Expanded(
            flex: 2,
            child: Row(
              children: categories.map((category) {
                final categoryQuestions = questions
                    .where((q) =>
                        answers[q.id] == category &&
                        q.correctAnswer == category)
                    .toList();

                return Expanded(
                  child: DragTarget<DragDropQuestion>(
                    onWillAcceptWithDetails: (details) => true,
                    onAcceptWithDetails: (details) {
                      _checkAnswer(details.data.id, category, isEvergreen);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovered = candidateData.isNotEmpty;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: isHovered
                              ? AppTheme.primaryGradient
                              : LinearGradient(
                                  colors: [
                                    AppTheme.cardBg,
                                    AppTheme.cardBg.withOpacity(0.7),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isHovered
                                ? AppTheme.primaryGold
                                : Colors.white.withOpacity(0.2),
                            width: isHovered ? 3 : 1,
                          ),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: ListView.builder(
                                itemCount: categoryQuestions.length,
                                itemBuilder: (context, index) {
                                  final question = categoryQuestions[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            question.statement,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn().slideX();
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 32),

          // Draggable Questions
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statements',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        final isAnswered = answers[question.id] != null;

                        if (isAnswered &&
                            answers[question.id] == question.correctAnswer) {
                          return const SizedBox.shrink();
                        }

                        return Draggable<DragDropQuestion>(
                          data: question,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 300,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Text(
                                question.statement,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),

                              ),
                            ),
                            child: Text(
                              question.statement,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF6366F1).withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.drag_indicator,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.statement,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (index * 100).ms).slideX(),
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
    );
  }
}

class DragDropQuestion {
  final String id;
  final String statement;
  final String correctAnswer;

  DragDropQuestion({
    required this.id,
    required this.statement,
    required this.correctAnswer,
  });
}
