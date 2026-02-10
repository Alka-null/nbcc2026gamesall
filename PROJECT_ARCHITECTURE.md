# NBCC Strategy Games - Project Architecture Breakdown

## System Overview
This document outlines the complete architecture for splitting the monolithic Flutter app into separate microservices and standalone applications.

---

## 1. PROJECT STRUCTURE

### 1.1 Backend (Python Django REST API)
**Repository:** `nbcc-games-backend`
**Purpose:** Core API serving all games and user management
**Technology Stack:** Python 3.11, Django 4.2, Django REST Framework, PostgreSQL

#### Key Features:
- User authentication & authorization
- Unique code generation & validation
- Game questions & answers management
- Game play tracking & statistics
- User profile management
- Admin endpoints

#### Database Schema:
```
Users Table:
  - id (PK)
  - email (Unique)
  - name
  - unique_code (Unique, 8 chars alphanumeric)
  - created_at
  - last_login
  - is_active

Games Table:
  - id (PK)
  - name
  - description
  - slug
  - type (JIGSAW, BEER_CUP, QUIZ, DRAG_DROP, etc.)

Questions Table:
  - id (PK)
  - game_id (FK)
  - content
  - question_number
  - difficulty

Answers Table:
  - id (PK)
  - question_id (FK)
  - answer_text
  - is_correct
  - explanation

GamePlaySession Table:
  - id (PK)
  - user_id (FK)
  - game_id (FK)
  - started_at
  - completed_at
  - duration_seconds
  - score
  - difficulty_level

UserProgress Table:
  - id (PK)
  - user_id (FK)
  - game_id (FK)
  - current_level
  - current_question (for quiz)
  - last_played_at
  - total_plays
  - best_score
```

#### API Endpoints:

**Authentication:**
- `POST /api/auth/register/` - Register new user
- `POST /api/auth/validate-code/` - Validate unique code
- `POST /api/auth/login/` - Login with code

**Games:**
- `GET /api/games/` - List all games
- `GET /api/games/{game_id}/` - Get game details
- `GET /api/games/{game_id}/questions/` - Get all questions for a game

**User Progress:**
- `GET /api/users/{user_id}/progress/` - Get user progress
- `POST /api/gameplay/session/start/` - Start a game session
- `POST /api/gameplay/session/{session_id}/complete/` - Complete session
- `GET /api/gameplay/stats/` - Get user statistics

---

### 1.2 Flutter Auth App
**Repository:** `nbcc-games-auth`
**Purpose:** Standalone authentication application
**Technology Stack:** Flutter 3.x, Provider/GetX for state management, Dio for HTTP client

#### Key Screens:
1. **Registration Screen**
   - Name & Email input
   - Submit to backend
   - Display generated unique code
   - Option to copy/share code

2. **Login Screen**
   - Code input field
   - Validation against backend
   - Redirect to games app on success

3. **Profile Management**
   - View user info
   - Edit name
   - View unique code
   - Logout functionality

#### Features:
- Secure token storage (using flutter_secure_storage)
- Deep linking to games app (passing auth token)
- Biometric authentication (optional)
- Offline state management
- Error handling & retry logic

---

### 1.3 Flutter Games App
**Repository:** `nbcc-games-main`
**Purpose:** Central games hub with all game implementations
**Technology Stack:** Flutter 3.x, Provider/GetX, Dio, SQLite for offline support

#### Games to Include:

1. **Jigsaw Puzzle Game** ⭐
   - Custom puzzle pieces in jigsaw shape
   - Draggable pieces that snap into place
   - Statement/sentence forms when completed correctly
   - Difficulty levels by piece count
   - Time tracking & scoring

2. **Beer Cup Guessing Game**
   - Ball location tracking
   - Animation & transitions
   - Win/loss tracking

3. **Drag & Drop Game**
   - Match concepts to definitions
   - Multi-level progression

4. **Challenge Mode**
   - Timed challenges
   - Leaderboard integration (optional)

5. **Enablers Quiz**
   - MCQ format
   - Questions fetched from backend
   - Real-time answer validation
   - Score calculation

#### Features:
- Authentication integration
- User event tracking (using Mixpanel/Firebase Analytics)
- Offline mode with sync capabilities
- Game state persistence
- Beautiful UI/UX with animations

---

### 1.4 NextJS Admin Dashboard
**Repository:** `nbcc-games-admin`
**Purpose:** Administrator interface for system management
**Technology Stack:** Next.js 14, React, TypeScript, TailwindCSS, PostgreSQL

#### Admin Features:

**User Management:**
- View all users list
- Filter by registration date, last login, active status
- Edit user profile
- Deactivate/reactivate users
- View user statistics & progress
- Export user data (CSV)

**Game Management:**
- Create/Edit/Delete games
- Manage questions and answers
- Set difficulty levels
- View game statistics
- Track play frequency

**Analytics Dashboard:**
- User growth charts
- Game popularity charts
- Average completion time per game
- User retention metrics
- Platform usage (iOS, Android, Web)

**Content Management:**
- CRUD for game content
- Bulk upload questions (CSV)
- Version control for questions
- Publish/unpublish games

---

## 2. SYSTEM ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Devices                              │
├──────────────────┬──────────────────┬──────────────────┐
│                  │                  │                  │
│  Flutter Auth    │  Flutter Games   │   Web Browser    │
│  (Mobile App)    │  (Mobile App)    │  (Admin Panel)   │
└────────┬─────────┴────────┬─────────┴────────┬─────────┘
         │                  │                  │
         ├──────────────────┼──────────────────┤
         │                  │                  │
         ▼                  ▼                  ▼
    ┌────────────────────────────────────────────────┐
    │        API Gateway / Load Balancer              │
    │          (AWS ALB / Nginx Reverse Proxy)       │
    └───────────────────────┬────────────────────────┘
                            │
    ┌───────────────────────┴────────────────────────┐
    │                                                │
    ▼                                                ▼
┌──────────────────────────┐              ┌──────────────────────┐
│  Django REST API         │              │ NextJS Admin App     │
│  - Auth Service          │              │ - User Dashboard    │
│  - Game Service          │              │ - Analytics         │
│  - Progress Tracking     │              │ - Content Manager   │
│  - Question Service      │              │ - Reports           │
└──────────────┬───────────┘              └──────────────────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
    ▼          ▼          ▼
┌────────┐ ┌──────────┐ ┌────────┐
│ Redis  │ │PostgreSQL│ │  S3    │
│ Cache  │ │ Database │ │ Storage│
└────────┘ └──────────┘ └────────┘
```

---

## 3. DEPLOYMENT ARCHITECTURE

### Backend (Django)
- **Compute:** AWS EC2 (t3.medium) OR Heroku Dyno (Standard-2x)
- **Database:** AWS RDS PostgreSQL (db.t3.small)
- **Cache:** AWS ElastiCache Redis (cache.t3.micro)
- **Storage:** AWS S3 for images/media
- **Container:** Docker on ECS OR App Runner

### Flutter Apps
- **iOS:** TestFlight (beta) → App Store
- **Android:** Internal testing → Google Play Store
- **Hosting:** Firebase Hosting (web version optional)

### NextJS Admin
- **Hosting:** Vercel (recommended) OR AWS Amplify
- **Database:** AWS RDS (shared with backend)
- **CI/CD:** GitHub Actions

---

## 4. AUTHENTICATION & AUTHORIZATION FLOW

```
User Registration Flow:
1. User opens Flutter Auth app
2. Enters: Name, Email
3. Backend validates & creates user
4. Backend generates unique 8-char code (e.g., "ABC123XY")
5. Code displayed to user
6. User can copy/share code

Game Access Flow:
1. User opens Games app
2. App prompts for unique code
3. User enters code
4. Backend validates code & returns JWT token
5. Token stored securely on device
6. All game API calls include token
7. User can play games & progress tracked
```

---

## 5. DATA FLOW - JIGSAW PUZZLE EXAMPLE

```
Frontend (Flutter):
1. User selects "Jigsaw Puzzle"
2. App fetches puzzle data from backend:
   GET /api/games/jigsaw/questions/{level}
3. Response includes:
   - Statement to form
   - Number of pieces
   - Piece positions (shuffle order)
   - Correct answer arrangement

4. Game renders draggable puzzle pieces
5. User arranges pieces
6. On completion, submit arrangement:
   POST /api/gameplay/session/{session_id}/answer
   Body: { pieces_arrangement: [...] }

7. Backend validates arrangement against database
8. If correct, returns score & next level
9. Backend logs: time_taken, attempts, completion status
10. Updates UserProgress table

Backend stores:
- Question content & correct arrangement
- All user attempts & timing data
- Completion status & score
```

---

## 6. DEVELOPMENT TIMELINE

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 1** | 2-3 weeks | Django backend setup, DB schema, Auth APIs |
| **Phase 2** | 2 weeks | Flutter Auth app, secure storage, deep linking |
| **Phase 3** | 3-4 weeks | Flutter Games app, Jigsaw puzzle implementation |
| **Phase 4** | 2 weeks | NextJS admin dashboard, user management |
| **Phase 5** | 1 week | Integration testing, API optimization |
| **Phase 6** | 1 week | Deployment setup, CI/CD pipelines |
| **Phase 7** | 1 week | Load testing, security audit, bug fixes |

**Total:** 12-15 weeks (3-4 months) for full development

---

## 7. SECURITY CONSIDERATIONS

✅ **Implemented Features:**
- JWT token-based authentication
- HTTPS/TLS encryption for all API calls
- Secure token storage on mobile (flutter_secure_storage)
- Rate limiting on auth endpoints
- CORS configuration
- Input validation & sanitization
- SQL injection prevention (ORM usage)
- XSS protection
- CSRF tokens for admin panel

✅ **Additional Recommendations:**
- Implement 2FA for admin accounts
- API key rotation policy
- Regular security audits
- Implement OWASP guidelines
- Database encryption at rest
- VPC isolation for backend

---

