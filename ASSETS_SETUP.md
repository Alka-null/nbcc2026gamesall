# Assets Setup Guide

## 📁 Asset Directory Structure

All asset directories have been created. Follow the instructions below to add the required files.

---

## 🖼️ Image Assets

### 1. Heineken Background (All Games)
**File:** `heineken_bg.jpg`  
**Locations:**
- `flutter_apps/beer_cup_game/assets/images/heineken_bg.jpg`
- `flutter_apps/jigsaw_puzzle_game/assets/images/heineken_bg.jpg`
- `flutter_apps/drag_drop_game/assets/images/heineken_bg.jpg`

**Instructions:**  
Copy the Heineken bottle background image you provided to all three locations above.

---

### 2. Evergreen 2030 Logo (Jigsaw Puzzle Only)
**File:** `evergreen_preview.png`  
**Location:**
- `flutter_apps/jigsaw_puzzle_game/assets/images/evergreen_preview.png`

**Instructions:**  
Save the Evergreen 2030 logo (circular design with Growth/Future-Fit/Productivity segments) to this location.

---

## 🎵 Audio Assets

### Required Audio Files (All Games)

Add these audio files to the `assets/audio/` folder in each game:

#### Beer Cup Game
`flutter_apps/beer_cup_game/assets/audio/`
- `background_music.mp3` - Upbeat instrumental loop (2-3 minutes)
- `click.mp3` - Button click sound
- `correct.mp3` - Success chime for correct answers
- `wrong.mp3` - Error buzz for incorrect answers
- `success.mp3` - Level complete fanfare
- `game_start.mp3` - Game start jingle

#### Jigsaw Puzzle Game
`flutter_apps/jigsaw_puzzle_game/assets/audio/`
- `background_music.mp3` - Upbeat instrumental loop (2-3 minutes)
- `click.mp3` - Piece pick/drop sound
- `correct.mp3` - Piece snaps into place
- `success.mp3` - Puzzle completion fanfare
- `game_start.mp3` - Game start jingle

#### Drag & Drop Game
`flutter_apps/drag_drop_game/assets/audio/`
- `background_music.mp3` - Upbeat instrumental loop (2-3 minutes)
- `click.mp3` - Item drag sound
- `correct.mp3` - Correct pillar placement
- `wrong.mp3` - Wrong pillar placement
- `success.mp3` - Game completion fanfare
- `game_start.mp3` - Game start jingle

---

## 🎨 Audio Recommendations

### Free Audio Resources:
1. **Pixabay** (https://pixabay.com/music/) - Free royalty-free music
2. **FreeSounds** (https://freesound.org/) - Community sound effects
3. **Incompetech** (https://incompetech.com/) - Kevin MacLeod's music library
4. **Zapsplat** (https://www.zapsplat.com/) - Sound effects library

### Suggested Characteristics:
- **Background Music**: 120-140 BPM, kid-friendly, upbeat, instrumental
- **Click Sound**: Short (50-100ms), crisp, friendly
- **Correct Sound**: Cheerful chime or bell (200-300ms)
- **Wrong Sound**: Gentle buzz or error tone (200-300ms)
- **Success Sound**: Celebration fanfare (1-2 seconds)
- **Game Start**: Short intro jingle (500ms-1s)

---

## ✅ After Adding Assets

Once you've added the assets, run these commands for each game:

```powershell
# Beer Cup Game
cd flutter_apps/beer_cup_game
flutter pub get
flutter run -d chrome

# Jigsaw Puzzle Game
cd flutter_apps/jigsaw_puzzle_game
flutter pub get
flutter run -d chrome

# Drag & Drop Game
cd flutter_apps/drag_drop_game
flutter pub get
flutter run -d chrome
```

---

## 🔧 Troubleshooting

### Assets Not Loading?
1. Verify file names match exactly (case-sensitive)
2. Run `flutter clean` then `flutter pub get`
3. Check file formats (JPG for images, MP3 for audio)
4. Restart the Flutter app

### Fallback Behavior
All games have graceful fallbacks:
- **Missing Images**: Shows gradient background instead
- **Missing Audio**: Silently fails with console log (game continues)

---

## 📝 Quick Checklist

- [ ] Heineken background added to all 3 games
- [ ] Evergreen logo added to jigsaw puzzle
- [ ] Background music added to all 3 games
- [ ] Click sounds added to all 3 games
- [ ] Correct/wrong sounds added to all 3 games
- [ ] Success sounds added to all 3 games
- [ ] Game start sounds added to all 3 games
- [ ] Ran `flutter pub get` for each game
- [ ] Tested each game to verify assets load

---

**Note:** The games will work without assets but will use fallback gradients and no audio. For the best kid-friendly experience, add all assets listed above.
