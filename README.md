# Rhythm Game

A simple rhythm game built with [LÖVE (Love2D)](https://love2d.org/). Hit notes in time with the music, customize your experience, and even create your own charts!

## Features

- Play custom songs with chart files
- Chart editor for creating your own note charts
- Multiple skins and backgrounds
- Adjustable note speed, size, and scroll velocity
- Character reactions and rating effects
- Settings for audio, display, and gameplay
- Health and combo system
- Score breakdown and grading

## Getting Started

### Prerequisites

- [LÖVE 11.5](https://love2d.org/) installed

### Running the Game

1. Download or clone this repository.
2. Place your songs in the `songs/` folder. Each song should have its own subfolder with a `music.mp3` or `music.ogg` and a `chart.txt`.
3. Run the game with LÖVE:
   ```sh
   love .
   ```

### Folder Structure

- `assets/` - Game assets (images, sounds)
- `skins/` - Note and effect skins
- `songs/` - Your songs and charts
- `menuBackgrounds/` - Menu background images
- `Fonts/` - Fonts for different languages
- `Translations/` - JSON translation files

### Controls

- **Menu Navigation:** Arrow keys / Mouse
- **Hit Notes:** Any key
- **Pause/Resume:** ESC
- **Chart Editor:**  
  - `N` - Place normal note  
  - `H` - Place hold note  
  - `[` / `]` - Adjust scroll velocity (SV)  
  - `S` - Save chart  
  - `P` - Play/Pause preview  
  - Arrow keys - Scroll chart  
  - Enter song name and press Enter to confirm

## Creating Songs

1. Add a new folder in `songs/` with your song name.
2. Add `music.mp3` or `music.ogg` and a `chart.txt` (use the chart editor to create charts).
3. Optionally, add a background image.

## Settings

Accessible from the main menu. Adjust audio, gameplay, display, and language options. Settings are saved automatically.

## Credits

- Virus - Lead Programmer, Polish Translator, Artist
- Jake Whittaker - Programmer, German Translator, Charter
- KenneyNL - Cursor Icon
- Special thanks to contributors and the LÖVE2D community!

## License

See [LICENSE](LICENSE) for details.

---

Enjoy the game! For bug reports or suggestions, open an issue or contact