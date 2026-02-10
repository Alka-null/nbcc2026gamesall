import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendException implements Exception {
  BackendException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'BackendException($statusCode): $message';
}

class LeaderboardEntry {
  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.percentage,
    required this.recordedAt,
  });

  final String name;
  final int score;
  final double percentage;
  final DateTime recordedAt;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['player_name'] as String? ?? 'Player',
      score: json['score'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class BackendService {
  BackendService({http.Client? httpClient, String? baseUrl})
      : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000/api',
            );

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<List<LeaderboardEntry>> submitQuizResult({
    required int score,
    required int totalQuestions,
    String? authToken,
    String? playerName,
  }) async {
    final uri = _buildUri('/gameplay/quiz-results/');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final payload = <String, dynamic>{
      'score': score,
      'total_questions': totalQuestions,
    };

    if (playerName != null && playerName.isNotEmpty) {
      payload['player_name'] = playerName;
    }

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    final data = _decodeResponse(response);
    final leaderboard = data['leaderboard'] as List<dynamic>? ?? <dynamic>[];
    return leaderboard
        .map((entry) => LeaderboardEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntry>> fetchQuizLeaderboard({int limit = 10}) async {
    final uri = _buildUri('/gameplay/quiz-results/', {'limit': '$limit'});
    final response = await _client.get(uri);
    final data = _decodeResponse(response);
    if (data is List) {
      return data
          .map((entry) => LeaderboardEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
    }
    return <LeaderboardEntry>[];
  }

  dynamic _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map<String, dynamic> && body['detail'] != null
        ? body['detail'].toString()
        : 'Unexpected server error';
    throw BackendException(message, statusCode: response.statusCode);
  }
}
