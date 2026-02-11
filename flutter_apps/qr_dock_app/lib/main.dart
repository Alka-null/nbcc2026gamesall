import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const QRDockApp());
}

class QRDockApp extends StatelessWidget {
  const QRDockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Dock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const QRDockScreen(),
    );
  }
}

// QR Code data model
class QRCodeItem {
  final String label;
  final String data;
  final Color color;
  final IconData icon;

  const QRCodeItem({
    required this.label,
    required this.data,
    required this.color,
    required this.icon,
  });
}

class QRDockScreen extends StatefulWidget {
  const QRDockScreen({super.key});

  @override
  State<QRDockScreen> createState() => _QRDockScreenState();
}

class _QRDockScreenState extends State<QRDockScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isDocked = true; // Start docked at edge
  late AnimationController _expandController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _slideController;
  late Animation<double> _expandAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _slideAnimation;

  // Event QR codes
  final List<QRCodeItem> _qrCodes = [
    const QRCodeItem(
      label: 'Event Check-in',
      data: 'https://nbcc2026.com/checkin',
      color: Colors.green,
      icon: Icons.login,
    ),
    const QRCodeItem(
      label: 'Beer Cup Game',
      data: 'https://nbcc2026.com/beer-cup',
      color: Colors.amber,
      icon: Icons.sports_bar,
    ),
    const QRCodeItem(
      label: 'Drag & Drop Game',
      data: 'https://nbcc2026.com/drag-drop',
      color: Colors.blue,
      icon: Icons.drag_indicator,
    ),
    const QRCodeItem(
      label: 'Jigsaw Puzzle',
      data: 'https://nbcc2026.com/jigsaw',
      color: Colors.purple,
      icon: Icons.extension,
    ),
    const QRCodeItem(
      label: 'Leaderboard',
      data: 'https://nbcc2026.com/leaderboard',
      color: Colors.orange,
      icon: Icons.leaderboard,
    ),
    const QRCodeItem(
      label: 'Event Schedule',
      data: 'https://nbcc2026.com/schedule',
      color: Colors.teal,
      icon: Icons.schedule,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
    );

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      if (_isDocked) {
        // First tap: slide in from edge
        _isDocked = false;
        _slideController.forward();
      } else if (!_isExpanded) {
        // Second tap: expand the arc
        _isExpanded = true;
        _expandController.forward();
        _rotateController.forward();
      } else {
        // Third tap: collapse and dock back
        _isExpanded = false;
        _expandController.reverse();
        _rotateController.reverse();
      }
    });
  }

  void _dockToEdge() {
    setState(() {
      _isExpanded = false;
      _isDocked = true;
      _expandController.reverse();
      _rotateController.reverse();
      _slideController.reverse();
    });
  }

  void _showQRDetail(QRCodeItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: item.color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: item.color, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: item.data,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: item.color.withOpacity(0.9),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to access',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: item.color, fontSize: 16),
                ),
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
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          if (_isExpanded || !_isDocked) {
            _dockToEdge();
          }
        },
        child: Container(
          color: _isDocked ? Colors.transparent : Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              // Floating dock positioned at bottom-right corner
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  // When docked, hide 40px off screen; when active, show fully
                  final slideOffset = 40.0 * (1 - _slideAnimation.value);
                  return Positioned(
                    bottom: 40,
                    right: -slideOffset,
                    child: _buildDock(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDock() {
    return GestureDetector(
      onTap: () {}, // Prevent tap from propagating to background
      child: SizedBox(
        width: 350,
        height: 350,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Arc of QR code items (only show when not docked)
            if (!_isDocked) ..._buildArcItems(),

            // Main dock button
            _buildMainButton(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildArcItems() {
    final items = <Widget>[];
    final itemCount = _qrCodes.length;
    const startAngle = math.pi; // Start from left
    const sweepAngle = math.pi / 2; // 90 degree arc
    const radius = 140.0;

    for (int i = 0; i < itemCount; i++) {
      final item = _qrCodes[i];
      final angle = startAngle + (sweepAngle / (itemCount - 1)) * i;

      items.add(
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final progress = _expandAnimation.value;
            final itemDelay = i / itemCount;
            final itemProgress = Curves.easeOutBack.transform(
              ((progress - itemDelay * 0.3) / (1 - itemDelay * 0.3)).clamp(0.0, 1.0),
            );

            final x = radius * math.cos(angle) * itemProgress;
            final y = radius * math.sin(angle) * itemProgress;

            return Positioned(
              bottom: 25 - y,
              right: 25 - x,
              child: Transform.scale(
                scale: itemProgress,
                child: Opacity(
                  opacity: itemProgress.clamp(0.0, 1.0),
                  child: _buildQRItem(item, i),
                ),
              ),
            );
          },
        ),
      );
    }

    return items;
  }

  Widget _buildQRItem(QRCodeItem item, int index) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = 0.3 + (_glowAnimation.value * 0.2);

        return GestureDetector(
          onTap: () => _showQRDetail(item),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.color.withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(glowIntensity),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 24),
                const SizedBox(height: 4),
                Text(
                  item.label.split(' ').first,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = 0.4 + (_glowAnimation.value * 0.3);

        return GestureDetector(
          onTap: _toggleExpand,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isDocked ? 50 : 70,
            height: _isDocked ? 100 : 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2ECC71),
                  Color(0xFF27AE60),
                ],
              ),
              borderRadius: _isDocked 
                ? const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                  )
                : BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(glowIntensity),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(glowIntensity * 0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * math.pi / 4,
                  child: Icon(
                    _isExpanded ? Icons.close : Icons.qr_code_scanner,
                    color: Colors.white,
                    size: _isDocked ? 28 : 32,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
