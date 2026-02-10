import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket service for real-time leaderboard updates
class LeaderboardWebSocketService {
  WebSocketChannel? _channel;
  Stream? _stream;
  
  final String baseUrl;
  
  LeaderboardWebSocketService({required this.baseUrl});
  
  /// Connect to the leaderboard WebSocket
  void connect() {
    try {
      // Convert http/https to ws/wss
      final wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/leaderboard/'),
      );
      _stream = _channel!.stream;
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }
  
  /// Get the stream of leaderboard updates
  Stream? get leaderboardStream => _stream;
  
  /// Disconnect from WebSocket
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _stream = null;
  }
  
  /// Send a message to the WebSocket (optional for future use)
  void send(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }
}
