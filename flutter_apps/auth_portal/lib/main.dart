import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthPortalScreen(),
    );
  }
}

class AuthPortalScreen extends StatefulWidget {
  const AuthPortalScreen({super.key});

  @override
  State<AuthPortalScreen> createState() => _AuthPortalScreenState();
}

class _AuthPortalScreenState extends State<AuthPortalScreen> {
    
  Widget _dashboardStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 18, color: Colors.blue)),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _authToken;
  String? _uniqueCode;
  String? _playerName;
  String? _playerEmail;
  String? _playerLocation;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _gameData;

  static const String _baseUrl = 'https://nbcc2026gamesbackend.onrender.com/api/auth';
  static const String _gameBaseUrl = 'https://nbcc2026gamesbackend.onrender.com/api/gameplay';
  // static const String _baseUrl = 'http://localhost:8000/api/auth';
  // static const String _gameBaseUrl = 'http://localhost:8000/api/gameplay';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'organization': _locationController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        setState(() {
          _uniqueCode = data['player']['unique_code'];
          _playerName = data['player']['name'];
          _isRegistering = true; // Stay on register form to show code
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Registration failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProfileAndGameData() async {
    if (_authToken == null) return;
    try {
      // Fetch profile
      final profileResp = await http.get(
        Uri.parse('$_baseUrl/me/'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      if (profileResp.statusCode == 200) {
        _profileData = jsonDecode(profileResp.body);
      }
      // Fetch game data (quiz results as example)
      final gameResp = await http.get(
        Uri.parse('$_gameBaseUrl/quiz-results/?leaderboard=false'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      if (gameResp.statusCode == 200) {
        _gameData = jsonDecode(gameResp.body);
      }
    } catch (_) {}
  }

  Future<void> _loginWithCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/code-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'unique_code': _codeController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['access'] != null) {
        _authToken = data['access'];
        _playerName = data['player']['name'];
        _playerEmail = data['player']['email'];
        _playerLocation = data['player']['organization'];
        await _fetchProfileAndGameData();
        setState(() {});
      } else {
        setState(() {
          _errorMessage = data['detail'] ?? 'Login failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Portal'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _authToken != null
              ? _buildSuccessScreen()
              : _isRegistering
                  ? _buildRegisterForm()
                  : _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Login with Unique Code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Unique Code',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Enter your code' : null,
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      _loginWithCode();
                    }
                  },
            child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : () => setState(() => _isRegistering = true),
            child: const Text('Register New Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Register New Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (_uniqueCode == null) ...[
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location/Organization',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter your location' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter your email' : null,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _register();
                      }
                    },
              child: _isLoading ? const CircularProgressIndicator() : const Text('Register'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : () => setState(() => _isRegistering = false),
              child: const Text('Back to Login'),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  const Text('Your Unique Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(_uniqueCode!, style: const TextStyle(fontSize: 20, color: Colors.green)),
                  const SizedBox(height: 8),
                  const Text('Copy and save this code to login later.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _uniqueCode = null;
                      _isRegistering = false;
                    }),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    // Dashboard calculations
    final List<dynamic> games = (_gameData is List) ? _gameData as List : [];
    int totalGames = games.length;
    int totalAttempts = games.fold(0, (sum, g) => sum + 1);
    double avgScore = games.isNotEmpty
        ? games.map((g) => (g['percentage'] ?? 0.0) as num).reduce((a, b) => a + b) / games.length
        : 0.0;
    int bestScore = games.isNotEmpty
        ? games.map((g) => (g['score'] ?? 0) as int).reduce((a, b) => a > b ? a : b)
        : 0;
    String lastPlayed = games.isNotEmpty ? (games.first['created_at'] ?? '') : '';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          Text('Welcome, $_playerName!', style: const TextStyle(fontSize: 24)),
          if (_playerEmail != null) ...[
            const SizedBox(height: 8),
            Text('Email: $_playerEmail'),
          ],
          if (_playerLocation != null) ...[
            const SizedBox(height: 8),
            Text('Location: $_playerLocation'),
          ],
          const SizedBox(height: 24),
          Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dashboardStat('Games Played', totalGames.toString()),
              _dashboardStat('Best Score', bestScore.toString()),
              _dashboardStat('Avg. %', avgScore.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dashboardStat('Attempts', totalAttempts.toString()),
              _dashboardStat('Last Played', lastPlayed.isNotEmpty ? lastPlayed.split('T').first : '-'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent Games', style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          if (games.isEmpty)
            const Text('No games played yet.'),
          if (games.isNotEmpty)
            ...games.take(5).map((g) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.videogame_asset),
                    title: Text('Score: ${g['score']}/${g['total_questions']}  (${g['percentage']}%)'),
                    subtitle: Text('Played: ${g['created_at']?.replaceFirst('T', ' ').split('.').first ?? ''}\nDuration: ${g['duration_seconds'] ?? '-'}s'),
                  ),
                )),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: () => setState(() {
                _authToken = null;
                _codeController.clear();
              }),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
