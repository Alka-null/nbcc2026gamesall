import 'package:flutter/material.dart';
import 'dart:async';
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

class _MyHomePageState extends State<MyHomePage> {
    static const int _setATimeLimitSeconds = 900; // 15 minutes for 55 items
    int _secondsLeft = 900;
    bool _timerRunning = false;
    Timer? _timer;

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

    @override
    void dispose() {
      _timer?.cancel();
      _codeController.dispose();
      super.dispose();
    }
  String? _userCode;
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

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

  @override
  void initState() {
    super.initState();
    _initAudio();
    for (var p in setAPillars) { droppedA[p] = []; }
    for (var p in setBPillars) { droppedB[p] = []; }
    
    // Initialize with first batch of visible statements
    _loadInitialStatements();
  }

  Future<void> _initAudio() async {
    await AudioService().initialize();
    await AudioService().playBackgroundMusic();
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
                    : () {
                        AudioService().playSound('click');
                        if (_codeController.text.trim().isEmpty) {
                          setState(() {
                            _errorMessage = 'Please enter your code.';
                          });
                          return;
                        }
                        AudioService().playSound('game_start');
                        setState(() {
                          _userCode = _codeController.text.trim();
                          _errorMessage = null;
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
        backgroundColor: isSetA ? Colors.blueAccent : Colors.deepPurpleAccent,
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
            ? Center(child: Column(
                key: const ValueKey('reward'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
                  const SizedBox(height: 16),
                  const Text('Congratulations! You win a premium reward!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
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
                    label: const Text('Logout'),
                  ),
                ],
              ))
            : Padding(
                key: ValueKey('game_${_currentSet}_$_secondsLeft'),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (isSetA)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Drag statements to the correct pillar (Set A)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final draggedCount = droppedA.values.fold<int>(0, (sum, list) => sum + list.length);
                                    final totalCount = allStatementsA.length;
                                    final leftCount = totalCount - draggedCount;
                                    return Text(
                                      'Dragged: $draggedCount | Left: $leftCount | Total: $totalCount',
                                      style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text('Time: ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                              key: ValueKey(_secondsLeft),
                              style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Drag statements to the correct pillar (Set B)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final draggedCount = droppedB.values.fold<int>(0, (sum, list) => sum + list.length);
                                    final totalCount = allStatementsB.length;
                                    final leftCount = totalCount - draggedCount;
                                    return Text(
                                      'Dragged: $draggedCount | Left: $leftCount | Total: $totalCount',
                                      style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pillars
                          ...pillars.asMap().entries.map((entry) {
                            final i = entry.key;
                            final pillar = entry.value;
                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: pillarColors[i % pillarColors.length],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: DragTarget<String>(
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
                              ),
                            );
                          }),
                          // Draggable statements
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Statements', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ...statements.map((s) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Draggable<String>(
                                      data: s,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: AnimatedScale(
                                          scale: 1.1,
                                          duration: const Duration(milliseconds: 200),
                                          child: Card(
                                            color: Colors.amber.shade100,
                                            elevation: 6,
                                            child: Padding(padding: const EdgeInsets.all(8), child: Text(s, style: const TextStyle(fontSize: 16))),
                                          ),
                                        ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: Card(child: Padding(padding: const EdgeInsets.all(8), child: Text(s))),
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: Card(
                                        color: Colors.amber.shade50,
                                        elevation: 2,
                                        child: Padding(padding: const EdgeInsets.all(8), child: Text(s, style: const TextStyle(fontSize: 16))),
                                      ),
                                    ),
                                  ),
                                )).toList(),
                              ],
                            ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSetA && setAPillars.every((p) => droppedA[p]!.isNotEmpty))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _retrySetA,
                            child: const Text('Retry'),
                          ),
                        ],
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
                    if (!isSetA && setBPillars.every((p) => droppedB[p]!.isNotEmpty))
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
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
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: _buildLoginScreen(context),
      );
    } else {
      return _buildGameScreen(context);
    }
  }
}
