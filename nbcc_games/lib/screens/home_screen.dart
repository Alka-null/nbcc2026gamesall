import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_card.dart';
import 'jigsaw_puzzle_screen.dart';
import 'drag_drop_screen.dart';
import 'challenge_mode_screen.dart';
import 'beer_cup_screen.dart';
import 'enablers_quiz_screen.dart';
import 'demo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NBCC Strategy Games',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            foreground: Paint()
                              ..shader = AppTheme.goldGradient.createShader(
                                const Rect.fromLTWH(0, 0, 500, 100),
                              ),
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideX(),
                        const SizedBox(height: 8),
                        Text(
                          'Master the Evergreen 2030 Strategy',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textGray,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ),
                
                // Games Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildListDelegate([
                      GameCard(
                        title: 'Jigsaw Puzzle',
                        subtitle: 'Build 2030 Evergreen Drivers',
                        icon: Icons.extension,
                        gradient: AppTheme.primaryGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const JigsawPuzzleScreen()),
                        ),
                      ).animate().fadeIn(delay: 100.ms).scale(),
                      
                      GameCard(
                        title: 'Drag & Drop',
                        subtitle: 'Match Statements',
                        icon: Icons.touch_app,
                        gradient: AppTheme.goldGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DragDropScreen()),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(),
                      
                      GameCard(
                        title: 'Challenge Mode',
                        subtitle: 'Complete Tasks in 60s',
                        icon: Icons.timer,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChallengeModeScreen()),
                        ),
                      ).animate().fadeIn(delay: 300.ms).scale(),
                      
                      GameCard(
                        title: 'Beer Cup Challenge',
                        subtitle: 'Fill the Cup',
                        icon: Icons.sports_bar,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BeerCupScreen()),
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                      
                      GameCard(
                        title: 'Know Your Enablers',
                        subtitle: 'Quiz Challenge',
                        icon: Icons.quiz,
                        gradient: AppTheme.greenGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EnablersQuizScreen()),
                        ),
                      ).animate().fadeIn(delay: 500.ms).scale(),
                      
                      GameCard(
                        title: 'App Demos',
                        subtitle: 'Learn Digital Tools',
                        icon: Icons.apps,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DemoScreen()),
                        ),
                      ).animate().fadeIn(delay: 600.ms).scale(),
                    ]),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
