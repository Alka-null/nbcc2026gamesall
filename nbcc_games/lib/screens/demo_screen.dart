import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_background.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int _selectedDemo = 0;
  final _feedbackController = TextEditingController();

  final List<DemoApp> _apps = [
    DemoApp(
      name: 'SEM - SOT & AIDDA',
      description: 'Sales Execution & Monitoring with Smart Order Taking and AI-Driven Distribution Analysis',
      features: [
        'Real-time sales tracking',
        'Automated route optimization',
        'Performance analytics',
        'Instant order processing',
        'Customer insights',
      ],
      icon: Icons.analytics,
      color: Color(0xFF6366F1),
    ),
    DemoApp(
      name: 'QuickDrinks',
      description: 'Fast and easy ordering platform for customers',
      features: [
        'Instant catalog browsing',
        'One-tap ordering',
        'Real-time inventory check',
        'Flexible delivery scheduling',
        'Order history tracking',
      ],
      icon: Icons.local_drink,
      color: Color(0xFFF59E0B),
    ),
    DemoApp(
      name: 'DMS',
      description: 'Distribution Management System for end-to-end operations',
      features: [
        'Purchase order creation',
        'Inventory management',
        'Supplier coordination',
        'Analytics dashboard',
        'Automated reporting',
      ],
      icon: Icons.inventory_2,
      color: Color(0xFF10B981),
    ),
    DemoApp(
      name: 'Asset Management',
      description: 'Track and manage coolers, fridges, and equipment',
      features: [
        'Equipment tracking',
        'Maintenance scheduling',
        'Location monitoring',
        'Performance metrics',
        'Asset allocation',
      ],
      icon: Icons.kitchen,
      color: Color(0xFFEC4899),
    ),
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your feedback'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // In a real app, this would send to a backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thank you for your feedback!'),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    _feedbackController.clear();
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
                              'Application Demo & Knowledge Transfer',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const Text(
                              'Learn about digital solutions to unlock growth',
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

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      children: [
                        // App Selection
                        SizedBox(
                          width: 300,
                          child: ListView.builder(
                            itemCount: _apps.length,
                            itemBuilder: (context, index) {
                              final app = _apps[index];
                              final isSelected = index == _selectedDemo;

                              return GestureDetector(
                                onTap: () => setState(() => _selectedDemo = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [app.color, app.color.withOpacity(0.7)],
                                          )
                                        : null,
                                    color: isSelected ? null : AppTheme.cardBg.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? app.color
                                          : Colors.white.withOpacity(0.2),
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        app.icon,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          app.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: (index * 100).ms).slideX();
                            },
                          ),
                        ),

                        const SizedBox(width: 32),

                        // App Details
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(48),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _apps[_selectedDemo].color,
                                            _apps[_selectedDemo].color.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        _apps[_selectedDemo].icon,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _apps[_selectedDemo].name,
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _apps[_selectedDemo].description,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: AppTheme.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn().slideY(),

                                const SizedBox(height: 48),

                                const Text(
                                  'Key Features',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _apps[_selectedDemo].features.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _apps[_selectedDemo].color.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: _apps[_selectedDemo].color,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                _apps[_selectedDemo].features[index],
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn(delay: (index * 100).ms).slideX();
                                    },
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Feedback Section
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _apps[_selectedDemo].color.withOpacity(0.2),
                                        _apps[_selectedDemo].color.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Share Your Feedback',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: _feedbackController,
                                        maxLines: 3,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'How can we better support you with ${_apps[_selectedDemo].name}?',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _submitFeedback,
                                        icon: const Icon(Icons.send),
                                        label: const Text('Submit Feedback'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _apps[_selectedDemo].color,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate(key: ValueKey(_selectedDemo)).fadeIn().scale(),
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

class DemoApp {
  final String name;
  final String description;
  final List<String> features;
  final IconData icon;
  final Color color;

  DemoApp({
    required this.name,
    required this.description,
    required this.features,
    required this.icon,
    required this.color,
  });
}
