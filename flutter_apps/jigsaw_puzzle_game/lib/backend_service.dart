import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<void> submitJigsawResult({
    required String playerCode,
    required int timeTaken,
    required bool completed,
  }) async {
    final uri = _buildUri('/gameplay/jigsaw-results/');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final payload = <String, dynamic>{
      'player_code': playerCode,
      'time_taken': timeTaken,
      'completed': completed,
    };
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to submit result: \\${response.body}');
    }
  }
}
