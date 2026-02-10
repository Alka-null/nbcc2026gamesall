import 'dart:convert';
import 'package:flutter/material.dart';
import 'leaderboard_websocket_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String baseUrl;
  
  const LeaderboardScreen({
    Key? key,
    required this.baseUrl,
  }) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> 
    with SingleTickerProviderStateMixin {
  late LeaderboardWebSocketService _wsService;
  List<dynamic> _leaderboard = [];
  int? _challengeId;
  String _message = 'Connecting...';
  bool _isConnected = false;
  
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _wsService = LeaderboardWebSocketService(baseUrl: widget.baseUrl);
    _wsService.connect();
    
    _wsService.leaderboardStream?.listen((data) {
      try {
        final Map<String, dynamic> message = jsonDecode(data);
        
        if (message['type'] == 'leaderboard_update') {
          setState(() {
            _isConnected = true;
            _challengeId = message['challenge_id'];
            _leaderboard = message['leaderboard'] ?? [];
            _message = message['message'] ?? '';
            
            // Trigger animation when leaderboard updates
            _animationController.forward(from: 0.0);
          });
        } else if (message['type'] == 'error') {
          setState(() {
            _message = message['message'] ?? 'An error occurred';
          });
        }
      } catch (e) {
        print('Error parsing WebSocket data: $e');
      }
    }, onError: (error) {
      setState(() {
        _isConnected = false;
        _message = 'Connection error';
      });
    });
  }
  
  @override
  void dispose() {
    _wsService.disconnect();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[700]!, Colors.deepPurple[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Leaderboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_challengeId != null)
              Text(
                'Challenge #$_challengeId',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnected ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[50]!, Colors.blue[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _leaderboard.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _message,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!_isConnected) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _leaderboard.length,
                itemBuilder: (context, index) {
                  return _buildLeaderboardItem(
                    _leaderboard[index],
                    index,
                  );
                },
              ),
      ),
    );
  }
  
  Widget _buildLeaderboardItem(Map<String, dynamic> entry, int index) {
    final rank = entry['rank'] ?? (index + 1);
    final name = entry['name'] ?? 'Player';
    final uniqueCode = entry['unique_code'] ?? '';
    final totalCorrect = entry['total_correct'] ?? 0;
    final totalAnswered = entry['total_answered'] ?? 0;
    final totalTime = entry['total_time'] ?? 0.0;
    
    // Different colors for top 3
    Color rankColor;
    IconData? medalIcon;
    
    switch (rank) {
      case 1:
        rankColor = Colors.amber[700]!;
        medalIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey[400]!;
        medalIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.orange[700]!;
        medalIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.blue[700]!;
    }
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.1,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: rank <= 3 ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: rank <= 3
                ? BorderSide(color: rankColor, width: 2)
                : BorderSide.none,
          ),
          child: Container(
            decoration: rank <= 3
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        rankColor.withOpacity(0.1),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: rankColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: medalIcon != null
                          ? Icon(medalIcon, color: Colors.white, size: 28)
                          : Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
  // Player info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalCorrect/$totalAnswered',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.blue[600],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${totalTime.toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
