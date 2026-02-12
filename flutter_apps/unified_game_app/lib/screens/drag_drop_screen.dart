import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/audio_service.dart';
import '../widgets/styled_background.dart';

class DragDropGamePage extends StatefulWidget {
  final String playerCode;
  final String playerName;

  const DragDropGamePage({
    super.key,
    required this.playerCode,
    required this.playerName,
  });

  @override
  State<DragDropGamePage> createState() => _DragDropGamePageState();
}

class _DragDropGamePageState extends State<DragDropGamePage> with TickerProviderStateMixin {
    static const int _setATimeLimitSeconds = 180; // 3 minutes per set
    int _secondsLeft = 180;
    bool _timerRunning = false;
    Timer? _timer;
    
    // Animation controllers for 3D pillar effects
    late AnimationController _shimmerController;
    late AnimationController _pulseController;
    late Animation<double> _shimmerAnimation;
    late Animation<double> _pulseAnimation;
    
    @override
    void initState() {
      super.initState();
      // Very slow shimmer animation for gentle glistening effect
      _shimmerController = AnimationController(
        duration: const Duration(seconds: 20),
        vsync: this,
      )..repeat();
      
      _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
      );
      
      // Very subtle, slow pulse animation
      _pulseController = AnimationController(
        duration: const Duration(seconds: 16),
        vsync: this,
      )..repeat(reverse: true);
      
      _pulseAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
      
      // Initialize pillar drop maps
      for (var p in setAPillars) { droppedA[p] = []; }
      for (var p in setBPillars) { droppedB[p] = []; }
      
      // Initialize with first batch of visible statements
      _loadInitialStatements();
    }
    
    @override
    void dispose() {
      _shimmerController.dispose();
      _pulseController.dispose();
      _timer?.cancel();
      super.dispose();
    }

    void _startSetATimer() {
      setState(() {
        _secondsLeft = _setATimeLimitSeconds;
        _timerRunning = true;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_timerRunning) {
          timer.cancel();
          return;
        }
        setState(() {
          _secondsLeft--;
        });
        if (_secondsLeft <= 0) {
          _timerRunning = false;
          timer.cancel();
          _unlockSetBByTimeout();
        }
      });
    }

    void _stopTimer() {
      setState(() {
        _timerRunning = false;
      });
      _timer?.cancel();
    }

    void _unlockSetBByTimeout() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Time is up!'),
          content: const Text('Set B is now unlocked. You can continue to the next set.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _setACompleted = true;
                  _setBUnlocked = true;
                  _currentSet = 1;
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    void _retrySetA() {
      setState(() {
        _secondsLeft = _setATimeLimitSeconds;
        _timerRunning = false;
        for (var p in setAPillars) { droppedA[p] = []; }
        _loadInitialStatements();
      });
      _startSetATimer();
    }

  // Drag & Drop Game State
  int _currentSet = 0; // 0 = Set A, 1 = Set B
  bool _setACompleted = false;
  bool _setBUnlocked = false;
  bool _showReward = false;

  // Pillars and statements for Set A and Set B
  final List<String> setAPillars = ['Growth', 'Productivity', 'Future-Fit'];
  
  // Store all statements separately for progressive streaming
  final List<String> allStatementsA = [
    // GROWTH - Set A (27 items)
    'Prioritizing resources in outlets delivering 80% volume',
    'Leveraging PICOS for customer experiences',
    'Acquiring new outlets monthly',
    'Establishing outlets in new growth areas',
    'Improving product availability to enhance share of throat',
    'Expanding growth beyond trade channels',
    'Activating NPD, events, and programs',
    'Setting up smart infrastructure in stores',
    'Building partnership roadmaps',
    'Selecting channel partners for future alignment',
    'Expanding premium brands into luxury spaces',
    'Mapping new geographic areas for activation',
    'Premiumizing experiences in key outlets',
    'Prioritizing resource allocation in high-impact outlets',
    'Pursuing 100% numeric distribution for key brands',
    'Ensuring outlet availability and convenience',
    'Focusing on portfolio strength in key areas',
    'Expanding reach of consumer marketing programs',
    'Win new exclusive dispensers in new outlets',
    'Focusing on 8020 distribution by geography',
    'Leveraging data insights for customer segmentation',
    'Leadership through continuous improvement',
    'Balancing short-term actions with long-term goals',
    'Connecting with customers on their terms',
    'Leading in consumer data and actionable insights',
    'Invest in growing product categories',
    'Partner with advanced digital platforms',
    // PRODUCTIVITY - Set A (21 items)
    'Leveraging smarter tools with less resources',
    'Achieving more with less',
    'Be effective not busy',
    'Simplify and automate',
    'Scale efficient processes',
    'Deploying frontline technology',
    'Using insights to prioritize time and resources',
    'Empowering teams with digital tools',
    'Digitizing field operations',
    'Pursuing fast track projects',
    'Optimizing resource allocation',
    'Achieving quality right the first time',
    'Adopting leaner processes',
    'Reducing complexity in workflows',
    'Managing by exception',
    'Building on successes not reinvent',
    'Conducting pilots before scaling projects',
    'Integrating planning cycles for efficiency',
    'Enabling data-driven decisions with analytics',
    'Take risks while aiming to fail fast',
    'Co-create customer solutions',
    // FUTURE FIT - Set A (7 items)
    'Developing AI assistant chatbot in SEM',
    'Exploring digital tools and e-commerce',
    'Equipping frontline with digital capabilities',
    'Embracing future business models',
    'Building digital expertise and capabilities',
    'Adapting to changing consumer behaviors',
    'Driving digital commerce innovations',
  ];
  
  final List<String> allStatementsB = [
    // GROWTH - Set B (15 items)
    'Increasing penetration with new customers',
    'Growing market share in untapped areas',
    'Conducting competitive brand analysis',
    'Learning from successes at speed',
    'Increasing visibility of top movers in stores',
    'Aligning on growth vision and strategy',
    'Putting bold plans into action',
    'Differentiating from competitors',
    'Focusing efforts on high-impact areas',
    'Making data-driven decisions',
    'Identify and activate whitespace opportunities',
    'Winning in On Premise and new channels',
    'Prioritize resource allocation based on return',
    'Upselling occasions and pack sizes',
    'Premiumise outlet experiences and visibility',
    // PRODUCTIVITY - Set B (21 items)
    'Focusing on highest value priorities',
    'Gaining insights to win',
    'Running smart pilots before scaling',
    'Building on success stories',
    'Keep it simple',
    'Using the right KPIs to drive actions',
    'Standardizing processes across markets',
    'Eliminating low-value activities',
    'Automating customer engagement',
    'Designing frictionless customer experiences',
    'Training  sales teams on productivity tools',
    'Deploying route optimization technology',
    'Streamlining administrative tasks',
    'Reducing time to market for initiatives',
    'Leveraging partnerships to scale faster',
    'Using analytics to predict demand',
    'Continuously improving operational efficiency',
    'Connecting KPIs to strategic priorities',
    'Optimizing inventory with real-time data',
    'Using zero-based thinking to challenge norms',
    'Adopting agile delivery models',
    // FUTURE FIT - Set B (19 items)
    'Creating digital-first customer experiences',
    'Building innovation pipelines',
    'Adopting machine learning for forecasting',
    'Engaging consumers via social media platforms',
    'Piloting virtual reality in marketing',
    'Leveraging influencer marketing',
    'Partnering with tech startups',
    'Selling products via e-commerce platforms',
    'Testing AI-driven customer support',
    'Upskilling teams in digital marketing',
    'Tracking consumer trends via social listening',
    'Implementing blockchain for transparency',
    'Adopting cloud-based collaboration tools',
    'Developing subscription-based models',
    'Creating personalized customer journeys',
    'Using augmented reality for brand engagement',
    'Building platforms for direct-to-consumer sales',
    'Leveraging IoT devices in merchandising',
    'Testing new revenue models',
  ];
  
  // Visible statements for progressive streaming
  final List<String> setAStatements = [];
  final List<String> setBPillars = ['Growth', 'Productivity', 'Future-Fit'];
  final List<String> setBStatements = [];
  
  // Randomized selection of 30 statements per set
  List<String> _selectedStatementsA = [];
  List<String> _selectedStatementsB = [];
  static const int _questionsPerSet = 30;
  
  // Track indices for progressive streaming
  int _setANextIndex = 0;
  int _setBNextIndex = 0;
  static const int _initialVisibleCount = 6;

  // Track dropped statements for each pillar
  Map<String, List<String>> droppedA = {};
  Map<String, List<String>> droppedB = {};

  // Correct pillar mapping for each statement
  Map<String, String> get _correctPillarA {
    final map = <String, String>{};
    // GROWTH - Set A (27 items)
    for (final s in allStatementsA.sublist(0, 27)) { map[s] = 'Growth'; }
    // PRODUCTIVITY - Set A (21 items)
    for (final s in allStatementsA.sublist(27, 48)) { map[s] = 'Productivity'; }
    // FUTURE FIT - Set A (7 items)
    for (final s in allStatementsA.sublist(48)) { map[s] = 'Future-Fit'; }
    return map;
  }

  Map<String, String> get _correctPillarB {
    final map = <String, String>{};
    // GROWTH - Set B (15 items)
    for (final s in allStatementsB.sublist(0, 15)) { map[s] = 'Growth'; }
    // PRODUCTIVITY - Set B (21 items)
    for (final s in allStatementsB.sublist(15, 36)) { map[s] = 'Productivity'; }
    // FUTURE FIT - Set B (19 items)
    for (final s in allStatementsB.sublist(36)) { map[s] = 'Future-Fit'; }
    return map;
  }

  int _countCorrect(Map<String, List<String>> dropped, Map<String, String> correctMap) {
    int correct = 0;
    for (final pillar in dropped.keys) {
      for (final statement in dropped[pillar]!) {
        if (correctMap[statement] == pillar) correct++;
      }
    }
    return correct;
  }
  
  void _loadInitialStatements() {
    setAStatements.clear();
    setBStatements.clear();
    _setANextIndex = 0;
    _setBNextIndex = 0;
    
    // Shuffle and select 30 random questions per set
    final shuffledA = List<String>.from(allStatementsA)..shuffle(math.Random());
    _selectedStatementsA = shuffledA.take(_questionsPerSet).toList();
    
    final shuffledB = List<String>.from(allStatementsB)..shuffle(math.Random());
    _selectedStatementsB = shuffledB.take(_questionsPerSet).toList();
    
    // Load initial visible statements from selected pool
    for (int i = 0; i < _initialVisibleCount && i < _selectedStatementsA.length; i++) {
      setAStatements.add(_selectedStatementsA[i]);
      _setANextIndex++;
    }
    
    for (int i = 0; i < _initialVisibleCount && i < _selectedStatementsB.length; i++) {
      setBStatements.add(_selectedStatementsB[i]);
      _setBNextIndex++;
    }
  }
  
  void _revealNextStatement(bool isSetA) {
    setState(() {
      if (isSetA && _setANextIndex < _selectedStatementsA.length) {
        setAStatements.add(_selectedStatementsA[_setANextIndex]);
        _setANextIndex++;
      } else if (!isSetA && _setBNextIndex < _selectedStatementsB.length) {
        setBStatements.add(_selectedStatementsB[_setBNextIndex]);
        _setBNextIndex++;
      }
    });
  }

  Widget _buildRewardScreen() {
    // Calculate scores - only count correctly placed statements
    final setATotal = _selectedStatementsA.length;
    final setBTotal = _selectedStatementsB.length;
    final setACorrect = _countCorrect(droppedA, _correctPillarA);
    final setBCorrect = _countCorrect(droppedB, _correctPillarB);
    final totalScore = setACorrect + setBCorrect;
    final maxScore = setATotal + setBTotal;
    final percentage = maxScore > 0 ? ((totalScore / maxScore) * 100).round() : 0;

    final stars = List.generate(20, (i) {
      final random = math.Random(i);
      return {
        'left': random.nextDouble(),
        'top': random.nextDouble(),
        'size': 8.0 + random.nextDouble() * 20,
        'delay': random.nextInt(2000),
        'duration': 1000 + random.nextInt(2000),
      };
    });

    return SizedBox.expand(
      key: const ValueKey('reward'),
      child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        ...stars.map((star) {
          return Positioned(
            left: (star['left'] as double) * MediaQuery.of(context).size.width,
            top: (star['top'] as double) * MediaQuery.of(context).size.height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: (star['duration'] as int)),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                final pulse = (math.sin(value * math.pi * 2) + 1) / 2;
                return Opacity(
                  opacity: 0.4 + pulse * 0.5,
                  child: Transform.scale(
                    scale: 0.7 + pulse * 0.3,
                    child: Transform.rotate(
                      angle: value * math.pi * 2,
                      child: child,
                    ),
                  ),
                );
              },
              child: Icon(
                Icons.star,
                color: [Colors.amber, Colors.yellow, Colors.orange, Colors.white][stars.indexOf(star) % 4],
                size: star['size'] as double,
              ),
            ),
          );
        }),
        ...List.generate(12, (i) {
          final random = math.Random(i + 100);
          return Positioned(
            left: random.nextDouble() * MediaQuery.of(context).size.width,
            top: random.nextDouble() * MediaQuery.of(context).size.height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 1500 + random.nextInt(1500)),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                final twinkle = (math.sin(value * math.pi * 6) + 1) / 2;
                return Opacity(
                  opacity: twinkle * 0.7,
                  child: Transform.scale(
                    scale: twinkle,
                    child: child,
                  ),
                );
              },
              child: Icon(
                Icons.auto_awesome,
                color: Colors.amber.shade200,
                size: 12 + random.nextDouble() * 10,
              ),
            ),
          );
        }),
        Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade100,
                Colors.amber.shade200,
                Colors.orange.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
            border: Border.all(color: Colors.amber.shade400, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.bounceOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + value * 0.5,
                    child: Transform.rotate(
                      angle: (1 - value) * 0.5,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.shade300,
                        Colors.amber.shade600,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.white, size: 80),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.amber.shade800,
                    Colors.orange.shade600,
                    Colors.amber.shade800,
                  ],
                ).createShader(bounds),
                child: const Text(
                  '🎉 CONGRATULATIONS! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Well done, ${widget.playerName}!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📊 FINAL SCORE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildScoreCard('Set A', setACorrect, setATotal, Colors.blue),
                        _buildScoreCard('Set B', setBCorrect, setBTotal, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: percentage.toDouble()),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Column(
                          children: [
                            Text(
                              '${value.round()}%',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: value / 100,
                                minHeight: 20,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation(
                                  value > 80 ? Colors.green : value > 50 ? Colors.amber : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalScore / $maxScore statements matched',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, size: 24),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: Colors.amber.withOpacity(0.5),
                  ),
                  onPressed: () {
                    AudioService().playSound('click');
                    // Go back to the main menu
                    Navigator.of(context).pop();
                  },
                  label: const Text('Back to Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
      ],
    ),
    );
  }

  Widget _buildScoreCard(String title, int score, int total, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text('$score / $total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameScreen(context);
  }

  Widget _buildGameScreen(BuildContext context) {
    final isSetA = _currentSet == 0;
    final pillars = isSetA ? setAPillars : setBPillars;
    final statements = isSetA ? setAStatements : setBStatements;
    final dropped = isSetA ? droppedA : droppedB;

    // Start timer for Set A if not running
    if (isSetA && !_timerRunning) {
      _startSetATimer();
    }

    final List<Color> pillarColors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        title: Text(isSetA ? 'Set A: Growth/Productivity/Future-Fit' : 'Set B: Winning/Delivering/Transforming'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _stopTimer();
              Navigator.of(context).pop();
            },
            tooltip: 'Back to Menu',
          ),
        ],
      ),
      body: StyledBackground(
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showReward
            ? _buildRewardScreen()
            : Padding(
                key: ValueKey('game_$_currentSet'),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (isSetA)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade700, Colors.indigo.shade900],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.indigo.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 4, offset: const Offset(-2, -2)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('⚡ Drag statements to the correct pillar (Set A)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      final draggedCount = droppedA.values.fold<int>(0, (sum, list) => sum + list.length);
                                      final totalCount = _selectedStatementsA.length;
                                      final leftCount = totalCount - draggedCount;
                                      return Text(
                                        'Dragged: $draggedCount | Left: $leftCount | Total: $totalCount',
                                        style: TextStyle(fontSize: 13, color: Colors.green.shade300, fontWeight: FontWeight.w600),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                key: ValueKey(_secondsLeft),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _secondsLeft < 60 ? Colors.red.shade700 : Colors.red.shade900,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    if (_secondsLeft < 60) BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 10),
                                  ],
                                ),
                                child: Text('⏱ ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade700, Colors.teal.shade900],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.teal.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 4, offset: const Offset(-2, -2)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('⚡ Drag statements to the correct pillar (Set B)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      final draggedCount = droppedB.values.fold<int>(0, (sum, list) => sum + list.length);
                                      final totalCount = _selectedStatementsB.length;
                                      final leftCount = totalCount - draggedCount;
                                      return Text(
                                        'Dragged: $draggedCount | Left: $leftCount | Total: $totalCount',
                                        style: TextStyle(fontSize: 13, color: Colors.green.shade300, fontWeight: FontWeight.w600),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pillars - plain for Set A, animated for Set B
                          ...pillars.asMap().entries.map((entry) {
                            final i = entry.key;
                            final pillar = entry.value;
                            
                            // Shared drag target content builder
                            Widget buildPillarContent() {
                              return DragTarget<String>(
                                builder: (context, candidateData, rejectedData) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 300),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: candidateData.isNotEmpty ? Colors.blueAccent : Colors.black,
                                        ),
                                        child: Text(pillar),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: dropped[pillar]!.map((s) => AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                              margin: const EdgeInsets.symmetric(vertical: 2),
                                              child: Card(
                                                color: Colors.white,
                                                elevation: 2,
                                                child: Padding(padding: const EdgeInsets.all(4), child: Text(s, style: const TextStyle(fontSize: 12))),
                                              ),
                                            )).toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onWillAccept: (data) => true,
                                onAccept: (data) {
                                  AudioService().playSound('correct');
                                  setState(() {
                                    dropped[pillar]!.add(data);
                                    if (isSetA) {
                                      setAStatements.remove(data);
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        _revealNextStatement(true);
                                      });
                                    } else {
                                      setBStatements.remove(data);
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        _revealNextStatement(false);
                                      });
                                    }
                                  });
                                },
                              );
                            }
                            
                            if (isSetA) {
                              // Set A: plain pillars, no shimmer/pulse animations
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        pillarColors[i % pillarColors.length].withOpacity(0.9),
                                        pillarColors[i % pillarColors.length],
                                        pillarColors[i % pillarColors.length].withOpacity(0.85),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 15,
                                        offset: const Offset(4, 8),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: buildPillarContent(),
                                ),
                              );
                            } else {
                              // Set B: animated pillars with shimmer only (pulse removed)
                              return Expanded(
                                child: AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    final shimmerValue = _shimmerAnimation.value;
                                    
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            pillarColors[i % pillarColors.length].withOpacity(0.9),
                                            pillarColors[i % pillarColors.length],
                                            pillarColors[i % pillarColors.length].withOpacity(0.85),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.25),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.25),
                                            blurRadius: 15,
                                            offset: const Offset(4, 8),
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: CustomPaint(
                                                painter: _ShimmerEdgePainter(
                                                  shimmerValue: shimmerValue,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          buildPillarContent(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          }),
                          // Draggable statements
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.grey.shade900.withOpacity(0.85),
                                    Colors.grey.shade800.withOpacity(0.9),
                                    Colors.grey.shade900.withOpacity(0.85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(4, 8),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(-2, -2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.amber.shade700, Colors.orange.shade700],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
                                          ],
                                        ),
                                        child: const Text('📋 Statements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                      ),
                                      const SizedBox(height: 10),
                                  ...statements.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final s = entry.value;
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(milliseconds: 300 + index * 50),
                                      curve: Curves.easeOutBack,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Opacity(
                                            opacity: value.clamp(0.0, 1.0),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Draggable<String>(
                                          data: s,
                                          feedback: Material(
                                            color: Colors.transparent,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.amber.withOpacity(0.35),
                                                    blurRadius: 15,
                                                    spreadRadius: 1,
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.orange.withOpacity(0.2),
                                                    blurRadius: 20,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              child: Card(
                                                color: Colors.amber.shade200,
                                                elevation: 8,
                                                shadowColor: Colors.amber.withOpacity(0.3),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(color: Colors.amber.shade400, width: 2),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Text(s, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.3,
                                            child: Card(
                                              child: Padding(padding: const EdgeInsets.all(8), child: Text(s)),
                                            ),
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber.withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Card(
                                              color: Colors.amber.shade50,
                                              elevation: 4,
                                              shadowColor: Colors.amber.withOpacity(0.3),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: Colors.amber.shade200, width: 1),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: Text(s, style: const TextStyle(fontSize: 16)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSetA && setAStatements.isEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() {
                            _setACompleted = true;
                            _setBUnlocked = true;
                            _currentSet = 1;
                            _stopTimer();
                          });
                        },
                        child: const Text('Proceed to Set B'),
                      ),
                    if (isSetA && _secondsLeft <= 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() {
                            _setACompleted = true;
                            _setBUnlocked = true;
                            _currentSet = 1;
                          });
                        },
                        child: const Text('Proceed to Set B'),
                      ),
                    if (!isSetA && setBStatements.isEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              AudioService().playSound('success');
                              setState(() {
                                _showReward = true;
                              });
                            },
                            child: const Text('Finish & Claim Reward'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              setState(() {
                                _currentSet = 0;
                                _setACompleted = false;
                                _setBUnlocked = false;
                                for (var p in setAPillars) { droppedA[p] = []; }
                                for (var p in setBPillars) { droppedB[p] = []; }
                                _loadInitialStatements();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

// Custom painter for shimmer effect on pillar edges
class _ShimmerEdgePainter extends CustomPainter {
  final double shimmerValue;
  final Color color;

  _ShimmerEdgePainter({
    required this.shimmerValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final angle = shimmerValue * 2 * math.pi;

    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: angle,
      endAngle: angle + math.pi / 2,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.1),
        color.withOpacity(0.2),
        color.withOpacity(0.1),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    );

    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, paint);
    
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final perimeter = 2 * (size.width + size.height - 40);
    final glowPosition = shimmerValue * perimeter;
    
    double glowX, glowY;
    if (glowPosition < size.width - 20) {
      glowX = glowPosition + 10;
      glowY = 10;
    } else if (glowPosition < size.width + size.height - 40) {
      glowX = size.width - 10;
      glowY = glowPosition - size.width + 30;
    } else if (glowPosition < 2 * size.width + size.height - 60) {
      glowX = size.width - (glowPosition - size.width - size.height + 50);
      glowY = size.height - 10;
    } else {
      glowX = 10;
      glowY = size.height - (glowPosition - 2 * size.width - size.height + 70);
    }
    
    canvas.drawCircle(Offset(glowX, glowY), 4, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerEdgePainter oldDelegate) {
    return oldDelegate.shimmerValue != shimmerValue;
  }
}
