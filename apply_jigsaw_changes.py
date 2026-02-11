"""
Apply all jigsaw_puzzle_game changes:
1. Re-enable API login (undo bypass)
2. Change game duration from 2 minutes to 1 minute
3. Update preview text "2 minutes" to "1 minute"
4. Rewrite build method for fullscreen layout with reference image + all tiles visible
"""
import re

path = r'c:\Users\HomePC\Desktop\AK\Projects\MyPersonal\NBCCStrategyGames\flutter_apps\jigsaw_puzzle_game\lib\main.dart'

with open(path, 'rb') as f:
    raw = f.read()

text = raw.decode('utf-8', errors='replace')
# Normalize line endings for matching, then restore
text = text.replace('\r\n', '\n')
lines = text.split('\n')
print(f"Original line count: {len(lines)}")

# ============ CHANGE 1: Re-enable API login ============
# Find the login method and replace the bypass with real API call
old_login = '''  void _login() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter your code.');
      return;
    }
    // TODO: Re-enable API login when backend is fixed
    // Temporarily bypass login - accept any code
    _audioService.playBackgroundMusic();
    _audioService.playSound('click');
    _audioService.playSound('game_start');
    lastPlayerCode = code;
    lastPlayerName = code;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const JigsawPuzzlePage()),
    );
  }'''

new_login = '''  void _login() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter your code.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/code-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'unique_code': code}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final player = data['player'];
        _audioService.playBackgroundMusic();
        _audioService.playSound('click');
        _audioService.playSound('game_start');
        lastPlayerCode = code;
        lastPlayerName = player?['name'] ?? code;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JigsawPuzzlePage()),
        );
      } else {
        setState(() => _error = 'Invalid code. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }'''

if old_login in text:
    text = text.replace(old_login, new_login)
    print("OK: Login re-enabled")
else:
    print("WARN: Could not find login bypass to replace")

# ============ CHANGE 2: Game duration 2 min -> 1 min ============
text = text.replace(
    'static const Duration gameDuration = Duration(minutes: 2);',
    'static const Duration gameDuration = Duration(minutes: 1);'
)
print("OK: Duration changed to 1 minute")

# ============ CHANGE 3: Preview text "2 minutes" -> "1 minute" ============
text = text.replace('2 minutes!', '1 minute!')
print("OK: Preview text updated")

# ============ CHANGE 4: Rewrite build method ============
# Find the build method start and end
build_start_marker = '  @override\n  Widget build(BuildContext context) {\n    if (_showPreview) {'
build_start_idx = text.find(build_start_marker)

if build_start_idx == -1:
    # Try with \r\n
    build_start_marker = '  @override\r\n  Widget build(BuildContext context) {\r\n    if (_showPreview) {'
    build_start_idx = text.find(build_start_marker)

if build_start_idx >= 0:
    # Find the end - the last closing brace of the class
    # The build method ends at the last `}` in the file (which closes the class)
    # We need to find where the build method starts and replace everything from there to end of class
    
    # Detect line ending style - we normalized to \n above
    nl = '\n'
    
    new_build = f'''  @override{nl}  Widget build(BuildContext context) {{{nl}    if (_showPreview) {{{nl}      return _buildPreviewScreen(context);{nl}    }}{nl}{nl}    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');{nl}    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');{nl}    final timerColor = _secondsLeft < 20 ? Colors.red : (_secondsLeft < 40 ? Colors.orange : Colors.green);{nl}{nl}    return Scaffold({nl}      body: StyledBackground({nl}        child: SafeArea({nl}          child: LayoutBuilder({nl}            builder: (context, constraints) {{{nl}              final screenW = constraints.maxWidth;{nl}              final screenH = constraints.maxHeight;{nl}              const topBarH = 48.0;{nl}              const spacing = 6.0;{nl}              final startBtnH = !_gameStarted ? 52.0 : 0.0;{nl}              final bottomH = screenH * 0.30;{nl}              final puzzleAreaH = screenH - topBarH - spacing * 3 - bottomH - startBtnH;{nl}              final maxPuzzleSize = screenW - 32.0 < puzzleAreaH ? screenW - 32.0 : puzzleAreaH;{nl}              final pieceSize = maxPuzzleSize / gridCols;{nl}              final puzzleSize = pieceSize * gridCols;{nl}              final trayPieceSize = pieceSize * 0.55 < (bottomH - 24) / 4.5 ? pieceSize * 0.55 : (bottomH - 24) / 4.5;{nl}              final previewSize = bottomH - 16 < screenW * 0.28 ? bottomH - 16 : screenW * 0.28;{nl}              return Column({nl}                children: [{nl}                  // Top bar: timer + title + restart{nl}                  Container({nl}                    height: topBarH,{nl}                    padding: const EdgeInsets.symmetric(horizontal: 12),{nl}                    child: Row({nl}                      children: [{nl}                        AnimatedContainer({nl}                          duration: const Duration(milliseconds: 500),{nl}                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),{nl}                          decoration: BoxDecoration({nl}                            color: timerColor.withOpacity(0.15),{nl}                            borderRadius: BorderRadius.circular(14),{nl}                            border: Border.all(color: timerColor, width: 2),{nl}                          ),{nl}                          child: Row({nl}                            mainAxisSize: MainAxisSize.min,{nl}                            children: [{nl}                              Icon(Icons.timer, color: timerColor, size: 20),{nl}                              const SizedBox(width: 6),{nl}                              Text('$minutes:$seconds',{nl}                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: timerColor)),{nl}                            ],{nl}                          ),{nl}                        ),{nl}                        const Spacer(),{nl}                        Text({nl}                          'Jigsaw Challenge',{nl}                          style: TextStyle({nl}                            fontSize: 16,{nl}                            fontWeight: FontWeight.bold,{nl}                            color: Colors.white.withOpacity(0.9),{nl}                          ),{nl}                        ),{nl}                        const Spacer(),{nl}                        IconButton({nl}                          icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.9)),{nl}                          onPressed: _resetPuzzle,{nl}                          tooltip: 'Restart',{nl}                          iconSize: 22,{nl}                        ),{nl}                      ],{nl}                    ),{nl}                  ),{nl}                  const SizedBox(height: spacing),{nl}                  // Start button{nl}                  if (!_gameStarted){nl}                    Padding({nl}                      padding: const EdgeInsets.only(bottom: 6.0),{nl}                      child: ElevatedButton({nl}                        style: ElevatedButton.styleFrom({nl}                          backgroundColor: Colors.green.shade600,{nl}                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),{nl}                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),{nl}                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),{nl}                          elevation: 8,{nl}                          shadowColor: Colors.green.shade900,{nl}                        ),{nl}                        onPressed: () {{{nl}                          setState(() => _gameStarted = true);{nl}                          _startTimer();{nl}                        }},{nl}                        child: Row({nl}                          mainAxisSize: MainAxisSize.min,{nl}                          children: const [{nl}                            Icon(Icons.play_arrow, size: 28),{nl}                            SizedBox(width: 8),{nl}                            Text('Start Puzzle'),{nl}                          ],{nl}                        ),{nl}                      ),{nl}                    ),{nl}                  // Puzzle grid{nl}                  Container({nl}                    width: puzzleSize + 16,{nl}                    height: puzzleSize + 16,{nl}                    padding: const EdgeInsets.all(8),{nl}                    decoration: BoxDecoration({nl}                      gradient: LinearGradient({nl}                        begin: Alignment.topLeft,{nl}                        end: Alignment.bottomRight,{nl}                        colors: [{nl}                          Colors.indigo.shade100,{nl}                          Colors.purple.shade100,{nl}                          Colors.pink.shade50,{nl}                        ],{nl}                      ),{nl}                      borderRadius: BorderRadius.circular(20),{nl}                      border: Border.all({nl}                        color: Colors.purple.shade300,{nl}                        width: 4,{nl}                      ),{nl}                      boxShadow: [{nl}                        BoxShadow({nl}                          color: Colors.purple.withOpacity(0.3),{nl}                          blurRadius: 20,{nl}                          spreadRadius: 4,{nl}                          offset: const Offset(0, 8),{nl}                        ),{nl}                        BoxShadow({nl}                          color: Colors.black.withOpacity(0.2),{nl}                          blurRadius: 10,{nl}                          offset: const Offset(0, 4),{nl}                        ),{nl}                      ],{nl}                    ),{nl}                    child: SizedBox({nl}                      width: puzzleSize,{nl}                      height: puzzleSize,{nl}                      child: _buildPuzzleGrid(pieceSize, pieceSize),{nl}                    ),{nl}                  ),{nl}                  const SizedBox(height: spacing),{nl}                  // Bottom panel: reference image + tiles side by side{nl}                  Expanded({nl}                    child: Padding({nl}                      padding: const EdgeInsets.symmetric(horizontal: 8),{nl}                      child: Row({nl}                        crossAxisAlignment: CrossAxisAlignment.start,{nl}                        children: [{nl}                          // Reference image{nl}                          Column({nl}                            mainAxisSize: MainAxisSize.min,{nl}                            children: [{nl}                              Text({nl}                                'Reference',{nl}                                style: TextStyle({nl}                                  fontSize: 11,{nl}                                  fontWeight: FontWeight.bold,{nl}                                  color: Colors.amber.shade200,{nl}                                ),{nl}                              ),{nl}                              const SizedBox(height: 4),{nl}                              Container({nl}                                width: previewSize,{nl}                                height: previewSize,{nl}                                decoration: BoxDecoration({nl}                                  borderRadius: BorderRadius.circular(12),{nl}                                  border: Border.all(color: Colors.amber.shade400, width: 2),{nl}                                  boxShadow: [{nl}                                    BoxShadow({nl}                                      color: Colors.amber.withOpacity(0.3),{nl}                                      blurRadius: 10,{nl}                                      spreadRadius: 2,{nl}                                    ),{nl}                                  ],{nl}                                ),{nl}                                child: ClipRRect({nl}                                  borderRadius: BorderRadius.circular(10),{nl}                                  child: Image.asset({nl}                                    'assets/jigsaw_image.png',{nl}                                    fit: BoxFit.contain,{nl}                                    errorBuilder: (context, error, stackTrace) {{{nl}                                      return Container({nl}                                        color: Colors.green.shade700,{nl}                                        child: const Center({nl}                                          child: Icon(Icons.extension, size: 40, color: Colors.white),{nl}                                        ),{nl}                                      );{nl}                                    }},{nl}                                  ),{nl}                                ),{nl}                              ),{nl}                            ],{nl}                          ),{nl}                          const SizedBox(width: 8),{nl}                          // All tiles visible at once{nl}                          Expanded({nl}                            child: _buildTray(trayPieceSize, trayPieceSize),{nl}                          ),{nl}                        ],{nl}                      ),{nl}                    ),{nl}                  ),{nl}                ],{nl}              );{nl}            }},{nl}          ),{nl}        ),{nl}      ),{nl}    );{nl}  }}{nl}}}{nl}'''

    # Replace from build_start_idx to end of file
    text = text[:build_start_idx] + new_build
    print("OK: Build method rewritten for fullscreen layout")
else:
    print(f"ERROR: Could not find build method start marker")

# Write result - restore \r\n line endings
text = text.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(text.encode('utf-8'))

# Verify
with open(path, 'rb') as f:
    verify = f.read().decode('utf-8', errors='replace')
final_lines = verify.split('\n')
print(f"Final line count: {len(final_lines)}")
print("All changes applied successfully!")
