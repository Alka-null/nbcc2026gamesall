import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';
import '../widgets/animated_background.dart';

class ChallengeModeScreen extends StatefulWidget {
  const ChallengeModeScreen({super.key});

  @override
  State<ChallengeModeScreen> createState() => _ChallengeModeScreenState();
}

class _ChallengeModeScreenState extends State<ChallengeModeScreen> {
  final CountDownController _controller = CountDownController();
  String? _selectedChallenge;
  List<ChallengeStep> _currentSteps = [];
  List<ChallengeStep> _userOrder = [];
  bool _isPlaying = false;
  bool _challengeComplete = false;

  final Map<String, List<ChallengeStep>> challenges = {
    'dms_po': [
      ChallengeStep(id: '1', title: 'Login to DMS', icon: Icons.login),
      ChallengeStep(id: '2', title: 'Navigate to Purchase Orders', icon: Icons.receipt_long),
      ChallengeStep(id: '3', title: 'Click Create New PO', icon: Icons.add_circle),
      ChallengeStep(id: '4', title: 'Select Supplier', icon: Icons.business),
      ChallengeStep(id: '5', title: 'Add Products', icon: Icons.inventory),
      ChallengeStep(id: '6', title: 'Set Quantities', icon: Icons.numbers),
      ChallengeStep(id: '7', title: 'Review Order', icon: Icons.preview),
      ChallengeStep(id: '8', title: 'Submit PO', icon: Icons.send),
    ],
    'sot_order': [
      ChallengeStep(id: '1', title: 'Open SOT App', icon: Icons.smartphone),
      ChallengeStep(id: '2', title: 'Select Customer', icon: Icons.person),
      ChallengeStep(id: '3', title: 'Choose Products', icon: Icons.shopping_cart),
      ChallengeStep(id: '4', title: 'Enter Quantities', icon: Icons.add_shopping_cart),
      ChallengeStep(id: '5', title: 'Apply Discounts', icon: Icons.local_offer),
      ChallengeStep(id: '6', title: 'Review Order Summary', icon: Icons.summarize),
      ChallengeStep(id: '7', title: 'Confirm Order', icon: Icons.check_circle),
    ],
    'quickdrinks_order': [
      ChallengeStep(id: '1', title: 'Launch QuickDrinks', icon: Icons.local_drink),
      ChallengeStep(id: '2', title: 'Select Outlet', icon: Icons.store),
      ChallengeStep(id: '3', title: 'Browse Catalog', icon: Icons.menu_book),
      ChallengeStep(id: '4', title: 'Add to Cart', icon: Icons.add_box),
      ChallengeStep(id: '5', title: 'Check Availability', icon: Icons.inventory_2),
      ChallengeStep(id: '6', title: 'Confirm Delivery Date', icon: Icons.calendar_today),
      ChallengeStep(id: '7', title: 'Place Order', icon: Icons.done_all),
    ],
  };

  void _startChallenge(String challengeId) {
    setState(() {
      _selectedChallenge = challengeId;
      _currentSteps = List.from(challenges[challengeId]!);
      _userOrder = [];
      _isPlaying = true;
      _challengeComplete = false;
      _currentSteps.shuffle();
    });
    _controller.start();
  }

  void _checkOrder() {
    final correctOrder = challenges[_selectedChallenge]!;
    bool isCorrect = true;

    if (_userOrder.length != correctOrder.length) {
      isCorrect = false;
    } else {
      for (int i = 0; i < correctOrder.length; i++) {
        if (_userOrder[i].id != correctOrder[i].id) {
          isCorrect = false;
          break;
        }
      }
    }

    if (isCorrect) {
      setState(() {
        _challengeComplete = true;
        _isPlaying = false;
      });
      _controller.pause();
      
      final gameState = Provider.of<GameState>(context, listen: false);
      gameState.completeChallenge(_selectedChallenge!);
      
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Incorrect order! Try again.',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessDialog() {
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
                'Challenge Complete!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You completed the task in under 60 seconds!',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedChallenge = null;
                    _isPlaying = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.accentGreen,
                ),
                child: const Text('Back to Challenges'),
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
            child: _selectedChallenge == null
                ? _buildChallengeSelection()
                : _buildChallengeScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeSelection() {
    return Column(
      children: [
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
                      'Challenge Mode',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const Text(
                      'Rearrange steps in under 60 seconds',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 1200,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                padding: const EdgeInsets.all(32),
                children: [
                  _buildChallengeCard(
                    'Create a PO on DMS',
                    Icons.description,
                    'dms_po',
                    const Color(0xFF6366F1),
                  ).animate().fadeIn(delay: 100.ms).scale(),
                  _buildChallengeCard(
                    'Place an order on SOT',
                    Icons.point_of_sale,
                    'sot_order',
                    const Color(0xFFEF4444),
                  ).animate().fadeIn(delay: 200.ms).scale(),
                  _buildChallengeCard(
                    'Place an order on QuickDrinks',
                    Icons.local_bar,
                    'quickdrinks_order',
                    const Color(0xFFF59E0B),
                  ).animate().fadeIn(delay: 300.ms).scale(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(String title, IconData icon, String challengeId, Color color) {
    return GestureDetector(
      onTap: () => _startChallenge(challengeId),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Start Challenge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 32),
                onPressed: () {
                  setState(() {
                    _selectedChallenge = null;
                    _isPlaying = false;
                  });
                  _controller.reset();
                },
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getChallengeTitle(_selectedChallenge!),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              CircularCountDownTimer(
                width: 120,
                height: 120,
                duration: 60,
                controller: _controller,
                fillColor: AppTheme.accentGreen,
                ringColor: Colors.white.withOpacity(0.2),
                backgroundColor: AppTheme.cardBg,
                strokeWidth: 12,
                isReverse: true,
                isReverseAnimation: true,
                textStyle: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                onComplete: () {
                  if (!_challengeComplete) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Time\'s up! Try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setState(() {
                      _isPlaying = false;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                // Your Order
                Expanded(
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
                          'Your Order',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: _userOrder.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) {
                                  newIndex--;
                                }
                                final item = _userOrder.removeAt(oldIndex);
                                _userOrder.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final step = _userOrder[index];
                              return ReorderableDragStartListener(
                                key: ValueKey(step.id),
                                index: index,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(step.icon, color: Colors.white, size: 28),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          step.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.drag_indicator,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_userOrder.length == challenges[_selectedChallenge]!.length)
                          ElevatedButton.icon(
                            onPressed: _checkOrder,
                            icon: const Icon(Icons.check, size: 28),
                            label: const Text('Submit'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 60),
                            ),
                          ).animate().fadeIn().scale(),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 32),
                
                // Available Steps
                Expanded(
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
                          'Available Steps',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentSteps.length,
                            itemBuilder: (context, index) {
                              final step = _currentSteps[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _userOrder.add(step);
                                    _currentSteps.removeAt(index);
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF475569),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(step.icon, color: Colors.white, size: 28),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          step.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: (index * 50).ms),
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
    );
  }

  String _getChallengeTitle(String challengeId) {
    switch (challengeId) {
      case 'dms_po':
        return 'Create a PO on DMS';
      case 'sot_order':
        return 'Place an order on SOT';
      case 'quickdrinks_order':
        return 'Place an order on QuickDrinks';
      default:
        return '';
    }
  }
}

class ChallengeStep {
  final String id;
  final String title;
  final IconData icon;

  ChallengeStep({
    required this.id,
    required this.title,
    required this.icon,
  });
}
