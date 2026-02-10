# NBCC Strategy Games - Technology Stack & Implementation Guide

## 1. TECHNOLOGY STACK SUMMARY

### Backend (Django REST API)
```
Language: Python 3.11+
Framework: Django 4.2 LTS + Django REST Framework 3.14
Database: PostgreSQL 14+
Cache: Redis 7+
Containerization: Docker
Container Orchestration: Docker Compose (dev), Kubernetes (prod optional)
Task Queue: Celery + Redis (for async tasks)

Key Dependencies:
- djangorestframework           # REST API
- django-cors-headers         # CORS handling
- django-filter               # Advanced filtering
- django-extensions           # Django utilities
- python-decouple             # Environment variables
- psycopg2-binary             # PostgreSQL adapter
- redis                        # Cache client
- celery                       # Async tasks
- gunicorn                     # Production WSGI server
- pytest-django               # Testing
- factory-boy                  # Test fixtures
- black                        # Code formatting
- pylint                       # Code linting
- django-ratelimit            # API rate limiting
```

### Flutter Auth App
```
Language: Dart 3.x
Framework: Flutter 3.x
State Management: Provider 6.x (recommended) or GetX 4.x
HTTP Client: Dio 5.x
Local Storage: flutter_secure_storage + shared_preferences
Authentication: Firebase Auth (optional) OR custom JWT

Key Dependencies:
- provider                     # State management
- dio                         # HTTP client
- flutter_secure_storage      # Secure credential storage
- shared_preferences          # Simple key-value storage
- go_router                   # Navigation
- freezed                     # Code generation
- json_serializable           # JSON serialization
- connectivity_plus           # Network detection
- package_info_plus           # App info
- device_info_plus            # Device info
- integration_test            # E2E testing
```

### Flutter Games App
```
Language: Dart 3.x
Framework: Flutter 3.x
State Management: Provider 6.x + Bloc (architecture)
Animation: Flutter built-in + Rive (optional)
Physics/Gesture: Flutter gesture detector + physics
Database: Hive (offline) + sqflite (alternatives)
Analytics: Firebase Analytics + Mixpanel

Key Dependencies:
- provider / bloc              # State management
- dio                         # HTTP with interceptors
- hive                        # Local database
- sqflite                     # SQLite wrapper
- animations                  # Advanced animations
- rive                        # Complex animations (optional)
- firebase_analytics          # Analytics
- firebase_messaging          # Push notifications
- video_player                # Media support
- photo_gallery               # Image/video picker
- sensors_plus                # Accelerometer (tilt)
- confetti                    # Celebration effects
- lottie                      # Lottie animations
```

### NextJS Admin Dashboard
```
Language: TypeScript 5.x
Framework: Next.js 14.x (App Router)
Styling: TailwindCSS 3.x
State Management: TanStack Query (React Query) + Zustand
UI Components: shadcn/ui or Headless UI
Charts: Recharts or Chart.js
Tables: TanStack React Table
Forms: React Hook Form + Zod validation
Authentication: NextAuth.js or custom JWT

Key Dependencies:
- next                        # Framework
- react 18.x                 # UI library
- typescript                  # Type safety
- tailwindcss                # Styling
- @tanstack/react-query      # Data fetching
- zustand                    # State management
- react-hook-form           # Forms
- zod                        # Schema validation
- recharts                   # Charts
- @tanstack/react-table     # Tables
- axios / fetch              # HTTP client
- date-fns                   # Date utilities
- clsx / tailwind-merge      # Utility classes
- prettier                   # Code formatting
- eslint                     # Linting
- jest / vitest              # Testing
- storybook                  # Component development
```

---

## 2. DETAILED BACKEND SETUP (Django)

### Project Structure
```
nbcc-games-backend/
├── .github/
│   └── workflows/
│       ├── test.yml
│       ├── deploy-staging.yml
│       └── deploy-production.yml
├── .gitignore
├── .env.example
├── docker-compose.yml
├── Dockerfile
├── manage.py
├── requirements.txt
├── README.md
├── setup.sh
│
├── config/
│   ├── __init__.py
│   ├── settings.py          # Main settings (use environment variables)
│   ├── urls.py              # Root URL config
│   ├── wsgi.py              # WSGI config
│   └── middleware.py        # Custom middleware
│
├── apps/
│   ├── users/               # User authentication & management
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── managers.py      # Custom user manager
│   │   ├── services.py      # Business logic
│   │   ├── tests/
│   │   │   ├── test_models.py
│   │   │   ├── test_views.py
│   │   │   └── test_services.py
│   │   └── admin.py
│   │
│   ├── games/               # Game metadata & questions
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── services.py
│   │   ├── tests/
│   │   └── admin.py
│   │
│   ├── gameplay/            # Game sessions & scoring
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── services.py
│   │   ├── tests/
│   │   └── admin.py
│   │
│   ├── analytics/           # Aggregate game statistics
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── tasks.py         # Celery tasks
│   │   └── services.py
│   │
│   └── api/
│       ├── permissions.py   # Custom DRF permissions
│       ├── throttles.py     # Rate limiting
│       ├── pagination.py    # Response pagination
│       ├── filters.py       # Query filters
│       └── serializers.py   # Common serializers
│
├── services/                # Shared services
│   ├── mailer.py           # Email sending
│   ├── sms.py              # SMS notifications
│   ├── cache.py            # Cache operations
│   └── storage.py          # S3/file operations
│
├── utils/                   # Utility functions
│   ├── decorators.py
│   ├── helpers.py
│   └── constants.py
│
└── tests/
    ├── conftest.py         # Pytest fixtures
    ├── factories.py        # Factory Boy factories
    └── fixtures/           # Test data
```

### Key Models Schema

#### User Model
```python
class User(AbstractUser):
    email = models.EmailField(unique=True)
    unique_code = models.CharField(max_length=8, unique=True, db_index=True)
    profile_picture = models.ImageField(upload_to='profiles/', null=True)
    bio = models.TextField(blank=True)
    
    # Tracking
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login = models.DateTimeField(null=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['unique_code']),
            models.Index(fields=['email']),
        ]
```

#### Game Model
```python
class Game(models.Model):
    GAME_TYPES = (
        ('JIGSAW', 'Jigsaw Puzzle'),
        ('BEER_CUP', 'Beer Cup Game'),
        ('QUIZ', 'Quiz'),
        ('DRAG_DROP', 'Drag & Drop'),
        ('CHALLENGE', 'Challenge Mode'),
    )
    
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(unique=True)
    description = models.TextField()
    game_type = models.CharField(choices=GAME_TYPES, max_length=20, db_index=True)
    thumbnail = models.ImageField(upload_to='games/')
    
    # Gameplay settings
    difficulty_levels = models.IntegerField(default=5)
    time_limit_seconds = models.IntegerField(null=True)
    min_players = models.IntegerField(default=1)
    max_players = models.IntegerField(default=1)
    
    # Publishing
    is_published = models.BooleanField(default=False)
    version = models.IntegerField(default=1)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

#### GameQuestion Model
```python
class GameQuestion(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='questions')
    level = models.IntegerField(db_index=True)
    question_number = models.IntegerField()
    
    # Content
    title = models.CharField(max_length=255)
    content = models.TextField()
    
    # Jigsaw specific
    puzzle_image = models.ImageField(upload_to='puzzles/', null=True)
    puzzle_pieces_count = models.IntegerField(default=9)
    correct_arrangement = models.JSONField()  # [{piece_id, row, col}, ...]
    
    # General settings
    difficulty = models.IntegerField(choices=[(1,1), (2,2), (3,3), (4,4), (5,5)])
    time_limit = models.IntegerField(null=True)
    
    class Meta:
        ordering = ['level', 'question_number']
        unique_together = ['game', 'level', 'question_number']
```

#### GameAnswer Model
```python
class GameAnswer(models.Model):
    question = models.ForeignKey(GameQuestion, on_delete=models.CASCADE, related_name='answers')
    text = models.TextField()
    explanation = models.TextField(blank=True)
    is_correct = models.BooleanField(default=False)
    order = models.IntegerField()  # For MCQ ordering
    
    class Meta:
        ordering = ['order']
        unique_together = ['question', 'order']
```

#### GamePlaySession Model
```python
class GamePlaySession(models.Model):
    STATUS_CHOICES = (
        ('STARTED', 'Started'),
        ('PAUSED', 'Paused'),
        ('COMPLETED', 'Completed'),
        ('ABANDONED', 'Abandoned'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='game_sessions')
    game = models.ForeignKey(Game, on_delete=models.PROTECT)
    level = models.IntegerField()
    
    # Timing
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True)
    
    # Status & scoring
    status = models.CharField(choices=STATUS_CHOICES, default='STARTED', max_length=20)
    score = models.IntegerField(null=True)
    time_taken_seconds = models.IntegerField(null=True)
    attempts = models.IntegerField(default=1)
    
    class Meta:
        ordering = ['-started_at']
        indexes = [
            models.Index(fields=['user', 'game']),
            models.Index(fields=['user', 'started_at']),
        ]
```

#### UserProgress Model
```python
class UserProgress(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='progress')
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    
    # Progress tracking
    current_level = models.IntegerField(default=1)
    current_question = models.ForeignKey(GameQuestion, null=True, on_delete=models.SET_NULL)
    
    # Statistics
    total_sessions = models.IntegerField(default=0)
    total_time_seconds = models.IntegerField(default=0)
    best_score = models.IntegerField(default=0)
    completion_count = models.IntegerField(default=0)
    
    # Timestamps
    first_played = models.DateTimeField(auto_now_add=True)
    last_played = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'game']
        ordering = ['-last_played']
```

---

## 3. API ENDPOINTS SPECIFICATION

### Authentication Endpoints

**Register User**
```
POST /api/v1/auth/register/
Body: {
    "name": "John Doe",
    "email": "john@example.com"
}
Response (201): {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "unique_code": "ABC123XY",
    "message": "Registration successful. Keep your code safe!"
}
```

**Validate Code**
```
POST /api/v1/auth/validate-code/
Body: {
    "code": "ABC123XY"
}
Response (200): {
    "valid": true,
    "user_id": 1,
    "message": "Code is valid"
}
```

**Login/Get Token**
```
POST /api/v1/auth/login/
Body: {
    "code": "ABC123XY"
}
Response (200): {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "expires_in": 86400,
    "token_type": "Bearer",
    "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
    }
}
```

### Game Endpoints

**List Games**
```
GET /api/v1/games/
Response (200): {
    "count": 5,
    "results": [
        {
            "id": 1,
            "name": "Jigsaw Puzzle",
            "slug": "jigsaw-puzzle",
            "game_type": "JIGSAW",
            "description": "...",
            "thumbnail": "https://...",
            "difficulty_levels": 5,
            "is_published": true
        }
    ]
}
```

**Get Game Questions**
```
GET /api/v1/games/{game_id}/questions/
Query: ?level=1
Response (200): {
    "game": {
        "id": 1,
        "name": "Jigsaw Puzzle"
    },
    "questions": [
        {
            "id": 101,
            "level": 1,
            "question_number": 1,
            "title": "Level 1 - 9 Pieces",
            "content": "Form the statement...",
            "puzzle_pieces_count": 9,
            "time_limit": 300,
            "difficulty": 1
        }
    ]
}
```

**Get Puzzle Arrangement (After Completion)**
```
GET /api/v1/games/jigsaw/questions/{question_id}/solution/
Response (200): {
    "correct_arrangement": [
        {"piece_id": 1, "row": 0, "col": 0},
        {"piece_id": 2, "row": 0, "col": 1},
        ...
    ],
    "statement": "Learn by Playing Games"
}
```

### Gameplay Endpoints

**Start Session**
```
POST /api/v1/gameplay/sessions/
Headers: Authorization: Bearer <token>
Body: {
    "game_id": 1,
    "level": 1
}
Response (201): {
    "session_id": "sess_abc123xyz",
    "user_id": 1,
    "game_id": 1,
    "level": 1,
    "started_at": "2024-01-15T10:30:00Z",
    "time_limit": 300
}
```

**Submit Answer**
```
POST /api/v1/gameplay/sessions/{session_id}/answer/
Headers: Authorization: Bearer <token>
Body: {
    "question_id": 101,
    "arrangement": [
        {"piece_id": 1, "row": 0, "col": 0},
        {"piece_id": 2, "row": 0, "col": 1},
        ...
    ]
}
Response (200): {
    "correct": true,
    "score": 100,
    "message": "Excellent! Statement formed correctly!",
    "next_level_unlocked": true,
    "time_taken": 45
}
```

**Get User Stats**
```
GET /api/v1/users/me/stats/
Headers: Authorization: Bearer <token>
Response (200): {
    "user_id": 1,
    "total_games_played": 42,
    "total_time_seconds": 3600,
    "games": [
        {
            "game_id": 1,
            "game_name": "Jigsaw Puzzle",
            "sessions": 10,
            "best_score": 100,
            "total_time": 600,
            "current_level": 3,
            "completion_percentage": 60
        }
    ]
}
```

---

## 4. FLUTTER AUTH APP - KEY FEATURES

### State Management Pattern (Provider)
```dart
// Services layer
class AuthService {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  
  Future<User> registerUser(String name, String email) async {
    // API call
    final response = await _apiClient.post('/auth/register/', data: {...});
    final uniqueCode = response['unique_code'];
    
    // Secure storage
    await _secureStorage.saveCode(uniqueCode);
    
    return User.fromJson(response);
  }
  
  Future<String> validateAndGetToken(String code) async {
    final response = await _apiClient.post('/auth/login/', data: {'code': code});
    final token = response['access_token'];
    
    // Secure storage
    await _secureStorage.saveToken(token);
    return token;
  }
}

// Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  Future<void> register(String name, String email) async {
    _isLoading = true;
    try {
      _user = await _authService.registerUser(name, email);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }
}
```

### UI Screens
- **Splash Screen** - Check if user already logged in
- **Registration Screen** - Name & email input
- **Code Display Screen** - Show unique code with copy/share
- **Login Screen** - Code input & validation
- **Profile Screen** - User info & logout

---

## 5. FLUTTER GAMES APP - JIGSAW PUZZLE IMPLEMENTATION

### Jigsaw Puzzle Logic
```dart
class JigsawPuzzle extends StatefulWidget {
  // Puzzle representation as grid
  // Each piece has: position, rotation, correct position
  
  List<PuzzlePiece> pieces;  // Current positions
  List<PuzzlePiece> correctArrangement;  // From backend
  
  // Check if two pieces align (snap to grid)
  bool canSnap(PuzzlePiece piece1, PuzzlePiece piece2) {
    // Calculate if adjacent and aligned
  }
  
  // Validate complete puzzle
  bool validateArrangement() {
    // Compare current with correctArrangement
    // Allow small tolerance for positioning
  }
}

// Custom painter for puzzle pieces
class PuzzlePiecePainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    // Draw jigsaw-shaped piece with paths
    // Include tabs/blanks for piece connectivity
  }
}
```

### Game Flow
1. Fetch puzzle data from backend
2. Generate random initial arrangement
3. Render draggable pieces
4. Handle drag, snap, and alignment logic
5. On completion, validate and submit
6. Backend returns score & feedback

---

## 6. CI/CD PIPELINE SETUP

### GitHub Actions Workflow (Backend)

```yaml
name: Deploy Django API

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
        env:
          POSTGRES_PASSWORD: postgres
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to AWS
        run: |
          # Docker build & push
          # ECS update service
          # Health check
```

---

## 7. SECURITY BEST PRACTICES

✅ **Implementation Checklist:**
- [ ] Use environment variables for all secrets
- [ ] Implement JWT with short expiration (24h) + refresh tokens
- [ ] Hash passwords with bcrypt (Django handles this)
- [ ] Validate all user input server-side
- [ ] Implement CORS strictly
- [ ] Use HTTPS everywhere
- [ ] SQL injection prevention (ORM with parameterized queries)
- [ ] Rate limiting on auth endpoints (5 attempts/minute)
- [ ] Implement audit logging for admin actions
- [ ] Regular security updates to dependencies
- [ ] Database encryption at rest
- [ ] Secure session management

---

## 8. DEVELOPMENT ROADMAP

### Week 1-2: Backend Core
- [ ] Setup Django project, Docker
- [ ] Database schema & migrations
- [ ] User authentication APIs
- [ ] Unique code generation

### Week 3-4: Backend Games
- [ ] Games CRUD endpoints
- [ ] Questions & answers management
- [ ] Test data seeding

### Week 5-7: Flutter Auth & Games
- [ ] Auth app with token storage
- [ ] Navigation & state management
- [ ] Jigsaw puzzle with piece logic
- [ ] API integration

### Week 8-9: NextJS Admin
- [ ] Dashboard setup
- [ ] User management pages
- [ ] Analytics & charts

### Week 10-12: Testing, Optimization, Deployment
- [ ] E2E testing
- [ ] Performance optimization
- [ ] App Store/Play Store submission
- [ ] Production deployment

---

