import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:drag_drop_game/services/audio_service.dart';
import 'package:drag_drop_game/widgets/styled_background.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pillar Match Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Match Actions to Pillars'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
    static const int _setATimeLimitSeconds = 900; // 15 minutes for 55 items
    int _secondsLeft = 900;
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
      // Slow shimmer animation for light glistening effect
      _shimmerController = AnimationController(
        duration: const Duration(seconds: 10),
        vsync: this,
      )..repeat();
      
      _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
      );
      
      // Subtle pulse animation
      _pulseController = AnimationController(
        duration: const Duration(seconds: 8),
        vsync: this,
      )..repeat(reverse: true);
      
      _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
      
      // Initialize audio
      _initAudio();
      
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
      _codeController.dispose();
      super.dispose();
    }

    // (Removed duplicate initState)

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

  String? _userCode;
  String? _playerName;
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  static const String _baseUrl = 'https://nbcc2026gamesbackend.onrender.com/api/auth';
  // static const String _baseUrl = 'http://localhost:8000/api/auth';

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
  final List<String> setAStatements = [
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
  final List<String> setBPillars = ['Growth', 'Productivity', 'Future-Fit'];
  final List<String> setBStatements = [];
  
  // Track indices for progressive streaming
  int _setANextIndex = 0;
  int _setBNextIndex = 0;
  static const int _initialVisibleCount = 6; // Show 6 statements initially

  // Track dropped statements for each pillar
  Map<String, List<String>> droppedA = {};
  Map<String, List<String>> droppedB = {};

  Future<void> _initAudio() async {
    await AudioService().initialize();
    // Don't auto-play - wait for user interaction
  }
  
  void _loadInitialStatements() {
    setAStatements.clear();
    setBStatements.clear();
    _setANextIndex = 0;
    _setBNextIndex = 0;
    
    // Load initial statements for Set A
    for (int i = 0; i < _initialVisibleCount && i < allStatementsA.length; i++) {
      setAStatements.add(allStatementsA[i]);
      _setANextIndex++;
    }
    
    // Load initial statements for Set B
    for (int i = 0; i < _initialVisibleCount && i < allStatementsB.length; i++) {
      setBStatements.add(allStatementsB[i]);
      _setBNextIndex++;
    }
  }
  
  void _revealNextStatement(bool isSetA) {
    setState(() {
      if (isSetA && _setANextIndex < allStatementsA.length) {
        setAStatements.add(allStatementsA[_setANextIndex]);
        _setANextIndex++;
      } else if (!isSetA && _setBNextIndex < allStatementsB.length) {
        setBStatements.add(allStatementsB[_setBNextIndex]);
        _setBNextIndex++;
      }
    });
  }

  Widget _buildRewardScreen() {
    // Calculate scores
    final setATotal = allStatementsA.length;
    final setBTotal = allStatementsB.length;
    final setACompleted = droppedA.values.fold<int>(0, (sum, list) => sum + list.length);
    final setBCompleted = droppedB.values.fold<int>(0, (sum, list) => sum + list.length);
    final totalScore = setACompleted + setBCompleted;
    final maxScore = setATotal + setBTotal;
    final percentage = ((totalScore / maxScore) * 100).round();

    // Generate random star positions
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
        // Animated stars background
        ...stars.map((star) {
          return Positioned(
            left: (star['left'] as double) * MediaQuery.of(context).size.width,
            top: (star['top'] as double) * MediaQuery.of(context).size.height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: (star['duration'] as int)),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                // Pulsing star effect
                final pulse = (math.sin(value * math.pi * 4) + 1) / 2;
                return Opacity(
                  opacity: pulse * 0.9,
                  child: Transform.scale(
                    scale: 0.5 + pulse * 0.5,
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
        // Sparkle particles
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
        // Main content
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
              // Animated trophy
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
              // Congratulations text with shimmer
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
                _playerName != null ? 'Well done, $_playerName!' : 'You win a premium reward!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 32),
              // Score breakdown
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
                        _buildScoreCard('Set A', setACompleted, setATotal, Colors.blue),
                        _buildScoreCard('Set B', setBCompleted, setBTotal, Colors.green),
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
              // Logout button with animation
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
                    setState(() {
                      _showReward = false;
                      _userCode = null;
                      _codeController.clear();
                      _currentSet = 0;
                      _setACompleted = false;
                      _setBUnlocked = false;
                      for (var p in setAPillars) { droppedA[p] = []; }
                      for (var p in setBPillars) { droppedB[p] = []; }
                      _stopTimer();
                    });
                  },
                  label: const Text('Play Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    // (Removed duplicate dispose)

  Widget _buildLoginScreen(BuildContext context) {
    return StyledBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter Game Code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        AudioService().playSound('click');
                        // Start background music on user interaction
                        AudioService().playBackgroundMusic();
                        if (_codeController.text.trim().isEmpty) {
                          setState(() {
                            _errorMessage = 'Please enter your code.';
                          });
                          return;
                        }
                        // TODO: Re-enable API login when backend is fixed
                        // Temporarily bypass login - accept any code
                        AudioService().playSound('game_start');
                        setState(() {
                          _userCode = _codeController.text.trim();
                          _playerName = _codeController.text.trim();
                          _errorMessage = null;
                          _isLoading = false;
                        });
                      },
                child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
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

    // Colorful pillar backgrounds
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
              setState(() {
                _userCode = null;
                _codeController.clear();
                _stopTimer();
              });
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StyledBackground(
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showReward
            ? _buildRewardScreen()
            : Padding(
                key: ValueKey('game_${_currentSet}_$_secondsLeft'),
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
                                      final totalCount = allStatementsA.length;
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
                                      final totalCount = allStatementsB.length;
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
                          // Pillars with 3D effects
                          ...pillars.asMap().entries.map((entry) {
                            final i = entry.key;
                            final pillar = entry.value;
                            return Expanded(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([_shimmerController, _pulseController]),
                                builder: (context, child) {
                                  final shimmerValue = _shimmerAnimation.value;
                                  final pulseValue = _pulseAnimation.value;
                                  
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
                                        stops: [0.0, 0.5, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25 + pulseValue * 0.05),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        // Main depth shadow
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 15,
                                          offset: const Offset(4, 8),
                                          spreadRadius: 2,
                                        ),
                                        // Inner glow
                                        BoxShadow(
                                          color: pillarColors[i % pillarColors.length].withOpacity(0.3 + pulseValue * 0.05),
                                          blurRadius: 20,
                                          offset: const Offset(0, 0),
                                          spreadRadius: -5,
                                        ),
                                        // Edge highlight
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.15 + pulseValue * 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(-2, -2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Shimmer/Glistening effect on edges
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
                                        // Main content
                                        DragTarget<String>(
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
                                                // Reveal next statement with delay for animation
                                                Future.delayed(const Duration(milliseconds: 300), () {
                                                  _revealNextStatement(true);
                                                });
                                              } else {
                                                setBStatements.remove(data);
                                                // Reveal next statement with delay for animation
                                                Future.delayed(const Duration(milliseconds: 300), () {
                                                  _revealNextStatement(false);
                                                });
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
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
                    // Show Proceed to Set B only when ALL Set A statements are exhausted
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
                    // Show Finish & Retry only when ALL Set B statements are exhausted (end of game)
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
                                // Reset both sets
                                _currentSet = 0;
                                _setACompleted = false;
                                _setBUnlocked = false;
                                for (var p in setAPillars) { droppedA[p] = []; }
                                for (var p in setBPillars) { droppedB[p] = []; }
                                setAStatements.clear();
                                setAStatements.addAll(allStatementsA);
                                setBStatements.clear();
                                setBStatements.addAll(allStatementsB);
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

  @override
  Widget build(BuildContext context) {
    if (_userCode == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          title: Text(widget.title),
        ),
        body: _buildLoginScreen(context),
      );
    } else {
      return _buildGameScreen(context);
    }
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

    // Calculate position based on shimmer value (0 to 1)
    final angle = shimmerValue * 2 * math.pi;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Create moving gradient along the edges
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

    // Draw rounded rectangle border with shimmer
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, paint);
    
    // Add a subtle glow dot that moves along the edge
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    // Position the glow dot along the perimeter
    final perimeter = 2 * (size.width + size.height - 40);
    final glowPosition = shimmerValue * perimeter;
    
    double glowX, glowY;
    if (glowPosition < size.width - 20) {
      // Top edge
      glowX = glowPosition + 10;
      glowY = 10;
    } else if (glowPosition < size.width + size.height - 40) {
      // Right edge
      glowX = size.width - 10;
      glowY = glowPosition - size.width + 30;
    } else if (glowPosition < 2 * size.width + size.height - 60) {
      // Bottom edge
      glowX = size.width - (glowPosition - size.width - size.height + 50);
      glowY = size.height - 10;
    } else {
      // Left edge
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
