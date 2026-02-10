# Assets Setup Instructions

## Required Assets for All Games

### 1. Background Image
- **File**: Save the Heineken beer bottle image as `heineken_bg.jpg`
- **Location**: Copy to each game's `assets/images/` folder:
  - `beer_cup_game/assets/images/heineken_bg.jpg`
  - `drag_drop_game/assets/images/heineken_bg.jpg`
  - `jigsaw_puzzle_game/assets/images/heineken_bg.jpg`

### 2. Audio Files
Download and place the following audio files in each game's `assets/audio/` folder:

#### Background Music (Looping)
- **File**: `background_music.mp3` (upbeat, modern, instrumental)
- **Recommendation**: Download from freesound.org or incompetech.com
- **Duration**: 2-3 minutes
- **Volume**: Moderate, not distracting

#### Sound Effects
- **File**: `click.mp3` - Button click sound
- **File**: `correct.mp3` - Correct answer/action sound
- **File**: `wrong.mp3` - Wrong answer sound
- **File**: `success.mp3` - Level completion/success sound
- **File**: `game_start.mp3` - Game start sound

**Recommended Sources for Free Audio**:
- https://freesound.org/
- https://incompetech.com/music/royalty-free/
- https://www.zapsplat.com/

### 3. After Adding Files
Run `flutter pub get` in each game directory to refresh assets.
