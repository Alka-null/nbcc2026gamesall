import 'package:flutter/material.dart';

import 'package:nbcc_games/services/backend_service.dart';

class GameState extends ChangeNotifier {
  final BackendService _backendService = BackendService();

  // User Profile
  String _playerName = 'Player';
  int _totalScore = 0;
  String? _authToken;
  
  // Jigsaw Puzzle State
  bool _jigsawCompleted = false;
  int _jigsawTime = 0;
  
  // Drag & Drop State
  int _dragDropScore = 0;
  int _dragDropCorrect = 0;
  
  // Challenge Mode State
  Map<String, bool> _challengesCompleted = {
    'dms_po': false,
    'sot_order': false,
    'quickdrinks_order': false,
  };
  
  // Beer Cup State
  int _beerCupLevel = 0;
  int _beerCupCorrect = 0;
  
  // Enablers Quiz State
  int _quizScore = 0;
  List<Map<String, dynamic>> _leaderboard = [];
  
  // Getters
  String get playerName => _playerName;
  int get totalScore => _totalScore;
  String? get authToken => _authToken;
  bool get jigsawCompleted => _jigsawCompleted;
  int get jigsawTime => _jigsawTime;
  int get dragDropScore => _dragDropScore;
  int get dragDropCorrect => _dragDropCorrect;
  Map<String, bool> get challengesCompleted => _challengesCompleted;
  int get beerCupLevel => _beerCupLevel;
  int get beerCupCorrect => _beerCupCorrect;
  int get quizScore => _quizScore;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  
  // Setters
  void setPlayerName(String name) {
    _playerName = name;
    notifyListeners();
  }

  void setAuthToken(String? token) {
    _authToken = token;
    notifyListeners();
  }
  
  void addScore(int points) {
    _totalScore += points;
    notifyListeners();
  }
  
  void completeJigsaw(int timeInSeconds) {
    _jigsawCompleted = true;
    _jigsawTime = timeInSeconds;
    addScore(500);
    notifyListeners();
  }
  
  void updateDragDrop(int correct) {
    _dragDropCorrect = correct;
    _dragDropScore = correct * 10;
    addScore(correct * 10);
    notifyListeners();
  }
  
  void completeChallenge(String challengeId) {
    _challengesCompleted[challengeId] = true;
    addScore(300);
    notifyListeners();
  }
  
  void updateBeerCup(int level, int correct) {
    _beerCupLevel = level;
    _beerCupCorrect = correct;
    addScore(50);
    notifyListeners();
  }
  
  void updateQuizScore(int score) {
    _quizScore = score;
    addScore(score * 5);
    notifyListeners();
  }
  
  void addToLeaderboard(String name, int score, {int? totalQuestions}) {
    double? percentage;
    if (totalQuestions != null && totalQuestions > 0) {
      percentage = (score / totalQuestions) * 100;
    }

    _leaderboard.add(
      {
        'name': name,
        'score': score,
        if (percentage != null) 'percentage': double.parse(percentage.toStringAsFixed(1)),
      },
    );
    _leaderboard.sort((a, b) => b['score'].compareTo(a['score']));
    if (_leaderboard.length > 10) {
      _leaderboard = _leaderboard.sublist(0, 10);
    }
    notifyListeners();
  }

  Future<bool> recordQuizResult({required int score, required int totalQuestions}) async {
    updateQuizScore(score);
    try {
      final leaderboardEntries = await _backendService.submitQuizResult(
        score: score,
        totalQuestions: totalQuestions,
        authToken: _authToken,
        playerName: _playerName,
      );
      _leaderboard = leaderboardEntries
          .map(
            (entry) => {
              'name': entry.name,
              'score': entry.score,
              'percentage': entry.percentage,
            },
          )
          .toList();
      notifyListeners();
      return true;
    } catch (_) {
      addToLeaderboard(_playerName, score, totalQuestions: totalQuestions);
      return false;
    }
  }

  Future<void> refreshLeaderboard({int limit = 10}) async {
    try {
      final leaderboardEntries = await _backendService.fetchQuizLeaderboard(limit: limit);
      _leaderboard = leaderboardEntries
          .map(
            (entry) => {
              'name': entry.name,
              'score': entry.score,
              'percentage': entry.percentage,
            },
          )
          .toList();
      notifyListeners();
    } catch (_) {
      // Ignore connectivity issues; UI can fall back to last known leaderboard data.
    }
  }
  
  void resetGame() {
    _totalScore = 0;
    _jigsawCompleted = false;
    _jigsawTime = 0;
    _dragDropScore = 0;
    _dragDropCorrect = 0;
    _challengesCompleted = {
      'dms_po': false,
      'sot_order': false,
      'quickdrinks_order': false,
    };
    _beerCupLevel = 0;
    _beerCupCorrect = 0;
    _quizScore = 0;
    _leaderboard = [];
    notifyListeners();
  }
}
