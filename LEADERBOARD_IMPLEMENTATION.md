# Real-time Leaderboard Implementation

## Overview
This implementation provides a real-time leaderboard system using Django Channels WebSockets for the backend and Flutter for the frontend with beautiful animations.

## Backend (Django)

### Components Created:

1. **WebSocket Consumer** (`backend/apps/gameplay/consumers.py`)
   - `LeaderboardConsumer`: Handles WebSocket connections and sends real-time leaderboard updates
   - Background task polls every 2 seconds for rank changes
   - Only sends updates when rankings actually change (optimized for bandwidth)
   - Includes connection status tracking

2. **Model Updates**:
   - Added `time_taken` field to `QuizStat` model to track answer time
   - Migration: `0005_quizstat_time_taken.py`

3. **API Updates**:
   - Updated `submit_answer` endpoint to accept `time_taken` parameter
   - Field is optional with default value of 0.0 seconds

4. **WebSocket Routing** (`backend/apps/gameplay/routing.py`)
   - WebSocket URL: `ws://localhost:8000/ws/leaderboard/`

### Ranking Logic:
- Participants ranked by:
  1. Total correct answers (DESC) - more correct answers = higher rank
  2. Total time taken (ASC) - faster completion = higher rank for ties

### WebSocket Message Format:
```json
{
  "type": "leaderboard_update",
  "challenge_id": 1,
  "leaderboard": [
    {
      "rank": 1,
      "user_id": 123,
      "unique_code": "ABC123",
      "name": "John Doe",
      "total_answered": 10,
      "total_correct": 9,
      "total_time": 45.5
    }
  ],
  "timestamp": 1234567890.123
}
```

## Frontend (Flutter)

### Components Created:

1. **WebSocket Service** (`nbcc_games/lib/services/leaderboard_websocket_service.dart`)
   - Manages WebSocket connection lifecycle
   - Provides stream of leaderboard updates
   - Auto-reconnection support

2. **Leaderboard Screen** (`nbcc_games/lib/screens/leaderboard_screen.dart`)
   - Beautiful gradient UI with purple/blue theme
   - Animated list items with slide and fade effects
   - Top 3 ranks highlighted with medals and special styling
   - Live connection indicator
   - Real-time stats display (correct answers, time taken)

### Visual Features:
- **Gradient backgrounds** - Purple to blue gradient
- **Rank badges** - Circular badges with different colors for top 3
- **Medals** - Trophy icons for 1st, 2nd, and 3rd place
- **Card elevation** - Higher elevation for top 3 ranks
- **Smooth animations** - Staggered fade-in and slide-in effects
- **Live indicator** - Green/red badge showing connection status
- **Stats icons** - Check circle for correct answers, timer for time

### Dependencies Added:
- `web_socket_channel: ^2.4.0`

## Usage

### Backend Setup:

1. **Start Django server**:
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

2. **WebSocket endpoint**: 
   - `ws://localhost:8000/ws/leaderboard/`
   - For production: `wss://your-domain.com/ws/leaderboard/`

### Flutter Integration:

```dart
import 'package:nbcc_games/screens/leaderboard_screen.dart';

// Navigate to leaderboard
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LeaderboardScreen(
      baseUrl: 'http://localhost:8000',  // or your API URL
    ),
  ),
);
```

### Submitting Answers with Time:

```json
POST /api/gameplay/submit_answer/
{
  "user_id": "ABC123",  // unique_code
  "question_id": 1,
  "answer": "Option A",
  "time_taken": 5.5  // seconds (optional)
}
```

## Performance Optimizations:

1. **Selective Updates**: Only sends WebSocket messages when rankings change
2. **Polling Interval**: 2-second polling interval balances real-time feel with server load
3. **Efficient Queries**: Uses Django ORM aggregations for fast calculations
4. **Connection Management**: Auto-cleanup on disconnect
5. **Animation Throttling**: Staggered animations prevent UI lag

## Customization:

### Adjust Polling Frequency:
In `consumers.py`, change the sleep duration:
```python
await asyncio.sleep(2)  # Change to desired seconds
```

### Change Ranking Colors:
In `leaderboard_screen.dart`, modify the `rankColor` switch statement:
```dart
case 1:
  rankColor = Colors.amber[700]!;  // Gold
  break;
```

### Modify Animation Speed:
In `leaderboard_screen.dart`:
```dart
_animationController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 500),  // Adjust duration
);
```

## Testing:

1. **Create active challenge**:
```bash
POST http://localhost:8000/api/gameplay/start_challenge/
{
  "name": "Test Challenge"
}
```

2. **Submit answers** for multiple users with different times
3. **Open leaderboard** in Flutter app
4. **Watch real-time updates** as users answer questions

## Notes:

- Ensure Django Channels is properly configured in your project
- WebSocket connections require ASGI server (Daphne/Uvicorn) for production
- Development server includes ASGI support for testing
- For production, use reverse proxy (nginx) with WebSocket support
