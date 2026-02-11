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
    static const int _setATimeLimitSeconds = 480; // 8 minutes for 30 items
    int _secondsLeft = 480;
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

    // Mapping of statements to correct pillars (uses source arrays, not shuffled)
    Map<String, String> get _statementToPillar {
      final map = <String, String>{};
      // Set A mappings from source category arrays
      for (var stmt in _allGrowthA) {
        map[stmt] = 'Growth';
      }
      for (var stmt in _allProductivityA) {
        map[stmt] = 'Productivity';
      }
      for (var stmt in _allFutureFitA) {
        map[stmt] = 'Future-Fit';
      }
      // Set B mappings from source category arrays
      for (var stmt in _allWinningB) {
        map[stmt] = 'Winning';
      }
      for (var stmt in _allDeliveringB) {
        map[stmt] = 'Delivering';
      }
      for (var stmt in _allTransformingB) {
        map[stmt] = 'Transforming';
      }
      return map;
    }

    static const String _gameplayApiUrl = 'https://nbcc2026gamesbackend.onrender.com/api/gameplay';

    Future<void> _saveGameAnswers() async {
      if (_userCode == null) return;
      
      final mapping = _statementToPillar;
      final answers = <Map<String, dynamic>>[];
      int questionId = 1;
      
      // Process Set A answers
      for (var pillar in setAPillars) {
        for (var statement in droppedA[pillar] ?? []) {
          final correctPillar = mapping[statement] ?? 'Unknown';
          answers.add({
            'question_id': questionId++,
            'question_text': statement,
            'selected_answer': pillar,
            'correct_answer': correctPillar,
            'is_correct': pillar == correctPillar,
            'time_taken_seconds': 0.0,
          });
        }
      }
      
      // Process Set B answers
      for (var pillar in setBPillars) {
        for (var statement in droppedB[pillar] ?? []) {
          final correctPillar = mapping[statement] ?? 'Unknown';
          answers.add({
            'question_id': questionId++,
            'question_text': statement,
            'selected_answer': pillar,
            'correct_answer': correctPillar,
            'is_correct': pillar == correctPillar,
            'time_taken_seconds': 0.0,
          });
        }
      }
      
      if (answers.isEmpty) return;
      
      try {
        await http.post(
          Uri.parse('$_gameplayApiUrl/game-answers/bulk/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_code': _userCode,
            'game_type': 'drag_drop',
            'answers': answers,
            'total_time_seconds': (_setATimeLimitSeconds - _secondsLeft).toDouble(),
          }),
        );
      } catch (e) {
        // Silently fail - don't block game completion for API errors
        debugPrint('Failed to save game answers: $e');
      }
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
  
  // Full question pools - 10 will be randomly selected from each category
  // Set A: GROWTH (39 items)
  final List<String> _allGrowthA = [
    'Prioritizing resources and assets in the few outlets that deliver 80% of my territory\'s volume',
    'Leveraging PICOS to create memorable customer and shopper experiences that drive repeated sales',
    'Acquiring new outlets every month and generating sales into these outlets',
    'Driving innovative brand penetration into new outlets within the sales territory',
    'Executing impactful activations in covered outlets to accelerate the rate of sales for mainstream brands',
    'Excellent execution of PICOS standards consistently in every outlet deliver the experience that bring customers back',
    'Activating party service across events in the territory',
    'Break barrier, build better',
    'Rise beyond limit',
    'Taking ownership of personal development without waiting to be told',
    'Small step, big impact',
    'Building strong relationships with key customers to drive loyalty',
    'Innovating product offerings based on customer feedback',
    'Developing leadership skills to inspire the team',
    'Fostering a culture of continuous improvement',
    'Encouraging innovation through team brainstorming sessions',
    'Creating engaging sales presentations',
    'Equipping the sales team with the right objection handling skills',
    'Encouraging feedback from customers to improve service',
    'Aligning sales strategies with company values',
    'Sustaining sub-distributor retention rate',
    'Using storytelling to connect with customers',
    'Encouraging mentorship within the sales team',
    'Building partnerships with complementary businesses',
    'Creating loyalty programs to reward repeated purchases',
    'Prioritizing customer feedback in product development',
    'Building a diverse sales team',
    'Focusing on value-based selling',
    'Developing emotional intelligence for better customer relations',
    'Building trust with key customer',
    'Celebrating team successes to boost motivation',
    'Building emotional resilience to handle rejection',
    'Developing strategic partnerships to enter new markets',
    'Building a feedback-rich environment for continuous improvement',
    'Investing in people to multiply performance',
    'Empowering individuals to grow beyond their comfort zones',
    'Learning from results to improve future performance',
    'Encouraging feedback to accelerate personal development',
    'Nurturing talent through coaching and mentoring',
  ];
  
  // Set A: PRODUCTIVITY (38 items)
  final List<String> _allProductivityA = [
    'Leveraging smarter tools and processes (less resources) to achieve more result',
    'Upgrading CRM systems to strengthen sales efficiency and accelerate revenue growth',
    'Achieving more with less',
    'Be effective not busy',
    'Ensuring every call visit has a clear purpose and outcome',
    'Optimizing time spent per outlet to enable greater value delivery in priority outlets',
    'Output over input',
    'Action Drives Result',
    'Time is a KPI',
    'Plan. Act. Deliver',
    'Discipline equals performance',
    'Using data analytics to optimize sales strategies',
    'Encouraging cross-functional collaboration to enhance results',
    'Streamlining sales processes for more efficiency',
    'Setting clear, measurable goals for sales targets',
    'Managing time effectively to maximize sales calls',
    'Using customer segmentation to tailor sales approaches',
    'Prioritizing high-margin products in sales pitches',
    'Developing negotiation skills to close deals effectively',
    'Utilizing CRM data to track customer interactions',
    'Automating routine tasks to free up time',
    'Measuring sales performance with KPIs',
    'Managing stress to maintain effectiveness',
    'Setting up automated follow-up emails',
    'Analyzing sales data to identify growth opportunities',
    'Using gamification to motivate the sales team',
    'Tracking competitor pricing strategies',
    'Encouraging work-life balance to boost morale',
    'Conducting regular sales training sessions',
    'Using data visualization tools to present sales results',
    'Encouraging transparency in sales reporting',
    'Using customer journey mapping to improve sales tactics',
    'Encouraging proactive problem-solving in sales challenges',
    'Building a culture of accountability within the team',
    'Implementing time-blocking techniques to improve focus',
    'Prioritizing mental health for sustained productivity',
    'Using data-driven decision making in sales planning',
    'Setting SMART goals for personal and team growth',
  ];
  
  // Set A: FUTURE-FIT (33 items)
  final List<String> _allFutureFitA = [
    'Developing an AI assistant chatbot in SEM that provides real-time execution support to frontline team',
    'Exploring digital tools and e-commerce opportunities',
    'Equipping the frontline team with the digital capabilities required to deliver on the 2030 ambition',
    'Embracing change and preparing for tomorrow',
    'Using AI-driven insights to personalize customer engagement',
    'Having a focus of Sustainability and innovation',
    'Quick adaptation to new tools or processes',
    'If our ways of working change tomorrow, I will adapt quickly',
    'I see technology as an enabler of my performance',
    'Identifying emerging market trends to stay ahead',
    'Implementing sustainable practices in sales operations',
    'Utilizing mobile technology for real-time sales updates',
    'Embracing digital transformation in sales',
    'Exploring new distribution channels',
    'Using AI to predict customer buying behavior',
    'Training the team on new sales technologies',
    'Using video content to engage prospects',
    'Developing cross-cultural communication skills',
    'Implementing chatbots for customer service',
    'Using predictive analytics for inventory management',
    'Using mobile apps to enhance customer engagement',
    'Developing a mobile-first sales strategy',
    'Utilizing AI to enhance customer insights',
    'Developing flexible sales strategies for changing markets',
    'Encouraging continuous learning through online courses',
    'Using chatbots to handle routine customer inquiries',
    'Creating immersive customer experiences through technology',
    'Using virtual assistants to manage administrative tasks',
    'Today\'s actions, tomorrow\'s advantage',
    'Building capabilities today for tomorrow\'s demands',
    'Developing frontline skills that match the need of the future',
    'Aligning today\'s execution with tomorrow\'s realities',
    'Transforming mindset to match tomorrow\'s opportunities',
  ];
  
  // Set B: WINNING (46 items)
  final List<String> _allWinningB = [
    'Conduct outlet execution checks to ensure brand visibility and compliance with execution standards',
    'Build strong relationships with key customers to secure adequate share of shelf space',
    'Track competitor promotions in the territory and counter with tactical offers',
    'Organize in-store sampling events to drive trial and conversion',
    'Identify and onboard new outlets',
    'Leverage retail staff persuasiveness to strengthen brand advocacy',
    'Excellently execute promotions to grow mainstream brands market share',
    'Grow premium brand volume within the territory to maximize gross margin',
    'Collaborate with sub-distributors to expand reach into rural or underserved markets',
    'Expand distribution in white spaces',
    'Making sales into new outlets monthly',
    'Launch targeted promotions to grow market share',
    'Strengthen relationships with key accounts to prevent churn',
    'Drive penetration in priority channels',
    'Implement territory mapping to identify white-space opportunities',
    'Increase frequency of customer visits to boost loyalty',
    'Execute brand activation events in high-traffic areas',
    'Train sales teams to deliver consistent brand messaging',
    'Partner with influencers to amplify brand visibility',
    'Ensuring execution excellence at point-of-sale',
    'Collect customer feedback to refine brand positioning',
    'Promote sustainability credentials as part of brand story',
    'Align promotions with brand equity goals, not just volume',
    'Showcase success stories from customers to build trust',
    'Invest in premium packaging to elevate perception',
    'Drive advocacy programs with loyal customers',
    'Negotiate better trade terms with distributors to drive gross margin',
    'Optimize product mix to focus on high-margin SKUs',
    'Reduce promotion leakage through tighter controls',
    'Train sales teams in value-selling',
    'Implement incentive schemes tied to margin improvement',
    'Building strong brand presence in high-potential markets',
    'Leveraging customer insights to enhance brand loyalty',
    'Expanding market share through targeted promotions and campaigns',
    'Collaborating with marketing to strengthen brand messaging',
    'Negotiating better terms with suppliers to improve gross margin',
    'Monitoring market trends to anticipate shifts and adapt strategies',
    'Enhancing product visibility through strategic merchandising',
    'Building partnerships that increase brand reach and influence',
    'Training sales teams on brand values to ensure consistent messaging',
    'Implementing pricing strategies that protect margin while driving volume',
    'Creating compelling brand stories that resonate with customers',
    'Focusing on premium product lines to boost gross margin',
    'Conducting regular margin analysis to identify improvement opportunities',
    'Aligning sales incentives with market share and margin goals',
    'Prioritizing high-margin products in sales pitches to maximize profitability',
  ];

  // Set B: DELIVERING (34 items)
  final List<String> _allDeliveringB = [
    'Introducing upselling strategies for premium products to grow revenue',
    'Delivering monthly revenue targets by territory',
    'Focus on repeat purchase programs to grow revenue',
    'Leverage data analytics to identify top-performing SKUs to increase revenue',
    'Align pricing strategies with market demand elasticity',
    'Implement cost-to-serve analysis per customer',
    'Rationalize trade spend to focus on ROI-positive activities',
    'Optimize promotional spending with post-campaign reviews',
    'Focus on premiumization strategies to grow revenue',
    'Track order volumes per outlet and follow up to increase repeat purchases',
    'Negotiate with retailers to secure larger order sizes and better replenishment cycles',
    'Monitor territory sales pipeline weekly to ensure revenue targets are on track',
    'Upsell complementary products during customer visits to boost revenue',
    'Review territory profitability reports and adjust focus to the right product mix',
    'Reduce cost-to-serve by optimizing travel routes and visit frequency',
    'Discourage credit sales to improve cash flow',
    'Work closely with finance to resolve overdue accounts in the territory',
    'Align promotional spending with outlets that deliver the highest ROI',
    'Accelerate receivables collection through tighter credit checks',
    'Setting clear revenue targets aligned with business objectives',
    'Managing sales pipelines to ensure consistent revenue flow',
    'Optimizing pricing to balance volume and profitability',
    'Controlling costs to maximize profit margins',
    'Monitoring key financial metrics to track business health',
    'Collaborating with finance to forecast revenue and cash flow',
    'Implementing cost-saving initiatives without compromising quality',
    'Prioritizing high-return sales activities to maximize profit',
    'Streamlining order fulfillment to reduce operational expenses',
    'Managing credit risk to protect cash flow',
    'Using sales data to identify revenue growth opportunities',
    'Aligning sales strategies with profit improvement plans',
    'Driving upsell and cross-sell initiatives to increase revenue',
    'Implementing performance metrics focused on profit and cash generation',
    'Negotiating contracts that support favorable payment terms',
  ];

  // Set B: TRANSFORMING (20 items)
  final List<String> _allTransformingB = [
    'Using technology to automate billing and collections',
    'Investing in digital tools to enhance sales efficiency',
    'Developing talent through continuous learning programs',
    'Using data analytics to drive digital transformation',
    'Building a culture that embraces change and innovation',
    'Enhancing employee skills to meet future business needs',
    'Leveraging AI to optimize sales processes',
    'Creating leadership development programs focused on digital skills',
    'Using digital platforms to improve customer engagement',
    'Using virtual training to upskill sales teams',
    'Automating sales processes for better sales force efficiency',
    'Automate reporting to reduce manual workload',
    'Use AI-driven insights for territory planning',
    'Leverage e-commerce platforms for direct sales',
    'Leverage digital for predictive analytics in demand forecasting',
    'Digitize customer feedback collection',
    'Develop leadership coaching for territory managers',
    'Implement mentorship programs across sales teams',
    'Build cross-functional collaboration skills',
    'Strengthen succession planning for key roles',
  ];
  
  // Selected statements for current game (30 total - randomly selected 10 per category)
  List<String> allStatementsA = [];
  List<String> allStatementsB = [];
  
  // Visible statements for progressive streaming (populated dynamically)
  final List<String> setAStatements = [];
  final List<String> setBPillars = ['Winning', 'Delivering', 'Transforming'];
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
    // Randomly select 30 questions (10 per category) for each set
    final random = math.Random();
    
    // Set A: randomly select 10 Growth, 10 Productivity, 10 Future-Fit
    allStatementsA.clear();
    final selectedGrowthA = (_allGrowthA.toList()..shuffle(random)).take(10).toList();
    final selectedProductivityA = (_allProductivityA.toList()..shuffle(random)).take(10).toList();
    final selectedFutureFitA = (_allFutureFitA.toList()..shuffle(random)).take(10).toList();
    allStatementsA.addAll(selectedGrowthA);
    allStatementsA.addAll(selectedProductivityA);
    allStatementsA.addAll(selectedFutureFitA);
    allStatementsA.shuffle(random); // Shuffle the final list for display
    
    // Set B: randomly select 10 Winning, 10 Delivering, 10 Transforming
    allStatementsB.clear();
    final selectedWinningB = (_allWinningB.toList()..shuffle(random)).take(10).toList();
    final selectedDeliveringB = (_allDeliveringB.toList()..shuffle(random)).take(10).toList();
    final selectedTransformingB = (_allTransformingB.toList()..shuffle(random)).take(10).toList();
    allStatementsB.addAll(selectedWinningB);
    allStatementsB.addAll(selectedDeliveringB);
    allStatementsB.addAll(selectedTransformingB);
    allStatementsB.shuffle(random); // Shuffle the final list for display
    
    setAStatements.clear();
    setBStatements.clear();
    _setANextIndex = 0;
    _setBNextIndex = 0;
    
    // Load initial visible statements for Set A
    for (int i = 0; i < _initialVisibleCount && i < allStatementsA.length; i++) {
      setAStatements.add(allStatementsA[i]);
      _setANextIndex++;
    }
    
    // Load initial visible statements for Set B
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

  // Helper to count correct answers in a dropped map
  int _countCorrectAnswers(Map<String, List<String>> dropped) {
    final mapping = _statementToPillar;
    int correct = 0;
    for (var pillar in dropped.keys) {
      for (var statement in dropped[pillar]!) {
        if (mapping[statement] == pillar) {
          correct++;
        }
      }
    }
    return correct;
  }

  Widget _buildRewardScreen() {
    // Calculate scores - count only CORRECT answers
    final setATotal = allStatementsA.length;
    final setBTotal = allStatementsB.length;
    final setACorrect = _countCorrectAnswers(droppedA);
    final setBCorrect = _countCorrectAnswers(droppedB);
    final totalScore = setACorrect + setBCorrect;
    final maxScore = setATotal + setBTotal;
    final percentage = maxScore > 0 ? ((totalScore / maxScore) * 100).round() : 0;

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
              // Animated trophy with bulge and glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue = _pulseAnimation.value;
                  final scale = 1.0 + pulseValue * 0.05;
                  return Transform.scale(
                    scale: scale,
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
                            color: Colors.amber.withOpacity(0.6 + pulseValue * 0.2),
                            blurRadius: 20 + pulseValue * 15,
                            spreadRadius: 5 + pulseValue * 5,
                          ),
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3 + pulseValue * 0.2),
                            blurRadius: 30 + pulseValue * 10,
                            spreadRadius: pulseValue * 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.white, size: 80),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Congratulations text with bulge and glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue = _pulseAnimation.value;
                  final scale = 1.0 + pulseValue * 0.03;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3 + pulseValue * 0.2),
                            blurRadius: 15 + pulseValue * 10,
                            spreadRadius: pulseValue * 3,
                          ),
                        ],
                      ),
                      child: ShaderMask(
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
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Player name with soft glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue = _pulseAnimation.value;
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2 + pulseValue * 0.15),
                          blurRadius: 10 + pulseValue * 8,
                          spreadRadius: pulseValue * 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _playerName != null ? 'Well done, $_playerName!' : 'You win a premium reward!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Score breakdown with bulge and glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue = _pulseAnimation.value;
                  final scale = 1.0 + pulseValue * 0.02;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.2 + pulseValue * 0.15),
                            blurRadius: 12 + pulseValue * 10,
                            spreadRadius: pulseValue * 3,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
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
                            AudioService().playSound('game_start');
                            setState(() {
                              _userCode = _codeController.text.trim();
                              _playerName = data['player']['name'];
                              _errorMessage = null;
                            });
                          } else {
                            setState(() {
                              _errorMessage = data['detail'] ?? data['message'] ?? 'Invalid code.';
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = 'Network error. Please try again.';
                          });
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
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
                                          child: _GentleGlowCard(
                                            index: index,
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
                            onPressed: () async {
                              AudioService().playSound('success');
                              // Save game answers to backend
                              await _saveGameAnswers();
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

// Gentle glow card widget with random animation phase for each card
class _GentleGlowCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _GentleGlowCard({
    required this.index,
    required this.child,
  });

  @override
  State<_GentleGlowCard> createState() => _GentleGlowCardState();
}

class _GentleGlowCardState extends State<_GentleGlowCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _phaseOffset;

  @override
  void initState() {
    super.initState();
    // Create random phase offset so cards don't all pulse together
    final random = math.Random(widget.index);
    _phaseOffset = random.nextDouble() * math.pi * 2;
    
    // Very slow, gentle animation (12-18 seconds per cycle, random per card)
    final duration = Duration(seconds: 12 + random.nextInt(6));
    
    _controller = AnimationController(
      duration: duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Use sine wave with phase offset for gentle, organic feel
        final t = _animation.value;
        // Very subtle bulge: scale between 1.0 and 1.015 (barely noticeable)
        final scale = 1.0 + t * 0.015;
        // Very subtle glow
        final glowIntensity = t * 0.08;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.1 + glowIntensity),
                  blurRadius: 4 + t * 4,
                  spreadRadius: t * 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
