# OnFiNtY Music Player 🎵

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.6-purple)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Platform](https://img.shields.io/badge/platform-Android-green)
![License](https://img.shields.io/badge/license-MIT-orange)

*A lightweight, beautiful, and smooth music player built with Flutter*

</div>

---

## ✨ Features

### 🎨 Beautiful UI
- **Glassmorphism Design** - Modern frosted glass effects throughout the app
- **Smooth Animations** - Fluid transitions and micro-interactions
- **Dark Theme** - Easy on the eyes with a stunning violet accent color
- **Rotating Album Art** - Dynamic album artwork that rotates while playing
- **Gradient Overlays** - Beautiful gradient effects on album and player screens

### 🎵 Music Management
- **Automatic Library Scanning** - Discovers all music files on your device
- **Album Organization** - Browse music by albums with beautiful grid layouts
- **Favorite Songs** - Mark your favorite tracks for quick access
- **Favorite Albums** - Create a collection of your favorite albums
- **Hide Songs** - Hide unwanted tracks or songs under 1 minute
- **Smart Filtering** - Search across songs, artists, and albums instantly
- **Newest First** - Songs automatically sorted by date added

### 🎧 Playback Features
- **Background Playback** - Listen to music while using other apps
- **Notification Controls** - Control playback from your notification shade
- **Lock Screen Controls** - Full media controls on your lock screen
- **Loop Modes** - Off, Loop One, or Loop All
- **Playback Speed Control** - Adjust speed from 0.5x to 2.0x
- **Swipe Gestures** - Swipe left/right on player to skip tracks
- **Mini Player** - Persistent mini player at the bottom of the screen
- **Queue Management** - Automatic playlist creation and navigation

### 🎭 User Experience
- **Multiple Tabs** - Songs, Albums, and Hidden tabs for easy navigation
- **Drag-to-Scroll** - Professional scrollbar with smooth scrolling
- **Long Press Options** - Long press songs for quick actions
- **Pull-up Player** - Swipe up mini player to open full player
- **Swipe Down to Close** - Natural gesture to exit player screen
- **Fast Search** - Dedicated search with real-time filtering
- **Smooth Transitions** - Custom page transitions between screens

### 🚀 Performance & Optimization
- **Memory Optimized** - 50MB cache limit with automatic cleanup
- **Cached Artwork** - High-quality album art with intelligent caching
- **RepaintBoundary** - Optimized rendering for smooth scrolling
- **Lazy Loading** - Efficient loading of large music libraries
- **Background Service** - Efficient audio playback service
- **Minimal Battery Drain** - Optimized for long listening sessions

### ⚙️ Settings & Customization
- **Library Scanning** - Manual refresh of music library
- **Cache Management** - View and clear cached artwork
- **Hidden Songs Manager** - View and unhide songs
- **Audio Quality Settings** - Choose playback quality (coming soon)
- **Equalizer** - Audio equalizer controls (coming soon)
- **Clear All Data** - Reset app to factory state

---

## 📸 Screenshots

### Home Screen
- Clean, organized list of all your songs
- Tabs for Songs, Albums, and Hidden tracks
- Mini player at the bottom for quick access
- Professional drag-to-scroll functionality

### Player Screen
- Full-screen album artwork with rotation animation
- Glassmorphic controls and information cards
- Progress bar with time indicators
- Playback controls with gradient effects
- Swipe gestures for navigation

### Albums View
- Grid layout of favorite albums
- Beautiful album artwork
- Quick album details
- Long press to favorite/unfavorite

### Settings Screen
- Library management options
- Cache size monitoring
- Privacy controls
- App information

---

## 🛠️ Technical Stack

### Core Technologies
- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management solution
- **GoRouter** - Declarative routing
- **Just Audio** - Audio playback engine
- **Audio Service** - Background audio handling

### Key Packages
```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  just_audio: ^0.9.42
  audio_service: ^0.18.16
  on_audio_query: ^2.9.0
  shared_preferences: ^2.3.3
  permission_handler: ^11.3.1
  draggable_scrollbar: ^0.1.0
  skeletonizer: ^1.4.2
```

### Architecture
- **Provider Pattern** - Clean separation of business logic
- **Service Layer** - Dedicated services for audio and preferences
- **Model Classes** - Type-safe data models
- **Widget Composition** - Reusable, modular widgets
- **Cached Widgets** - Performance-optimized components

---

## 📱 Installation

### Prerequisites
- Flutter SDK 3.0 or higher
- Android SDK (for Android builds)
- Dart 3.0+

### Steps

1. **Clone the repository**
```bash
git clone https://github.com/Onfinty/OnFiNtY-Music.git
cd OnFiNtY-Music
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

4. **Build for release**
```bash
flutter build apk --release
```

---

## 🎯 Usage

### First Launch
1. Grant audio/storage permissions when prompted
2. App automatically scans your music library
3. Start exploring and playing your music!

### Navigation
- **Home Tab** - View all your songs
- **Albums Tab** - Browse your favorite albums
- **Hidden Tab** - Manage hidden songs
- **Search Icon** - Quick search across your library
- **Settings Icon** - Access app settings

### Playing Music
1. Tap any song to start playing
2. Swipe up on mini player for full player screen
3. Use playback controls to manage playback
4. Swipe left/right on player to skip tracks
5. Long press songs for additional options

### Managing Library
1. Go to Settings > Scan Music to refresh library
2. Long press songs to hide/unhide them
3. Tap heart icon to favorite songs
4. Long press albums to add to favorites
5. Use search to quickly find tracks

---

## ⚡ Key Features Explained

### Artwork Caching
- Automatically caches album artwork for faster loading
- Intelligent cache management with 50MB limit
- High-quality images (up to 500x500 for large displays)
- Automatic cleanup of old cache entries

### Background Playback
- Continues playing when app is minimized
- Full notification controls
- Lock screen integration
- Battery-optimized service

### Smart Filtering
- Real-time search across title, artist, and album
- Filters out songs under 1 minute automatically
- Separate hidden songs management
- Maintains playback context during search

### Memory Optimization
- RepaintBoundary widgets for efficient rendering
- Lazy loading of artwork
- Efficient state management with Riverpod
- Minimal widget rebuilds

---

## 🔧 Configuration

### Customizing Theme
Edit `main.dart` to customize colors:
```dart
theme: ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF8B5CF6), // Change primary color
  scaffoldBackgroundColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8B5CF6),
    secondary: Color(0xFFA78BFA),
    surface: Color(0xFF1A1A1A),
  ),
)
```

### Cache Settings
Modify cache limit in `cached_artwork_widget.dart`:
```dart
static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas for Contribution
- Equalizer implementation
- Playlist creation and management
- Lyrics display
- Audio visualization
- Theme customization
- iOS support
- Additional language support

---

## 🐛 Known Issues

- Equalizer feature is under development
- Audio quality selector is UI-only (functional implementation pending)
- Share feature is a placeholder

---

## 📋 Roadmap

### Version 2.0
- [ ] Equalizer with presets
- [ ] Custom playlists
- [ ] Lyrics support
- [ ] Audio visualization
- [ ] Sleep timer
- [ ] Crossfade between tracks

### Version 3.0
- [ ] iOS support
- [ ] Online streaming support
- [ ] Podcast support
- [ ] Multiple theme options
- [ ] Backup & restore



---

## 👨‍💻 Developer

**Kyrillos Sameh**

- Created with ❤️ using Flutter
- Focus on performance, beauty, and user experience

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Just Audio & Audio Service packages
- OnAudioQuery for media scanning
- The Flutter community for inspiration

---

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact via email (onfinty@gmail.com)

---

<div align="center">

**Enjoy your music with OnFiNtY! 🎵**

*Made with Flutter* 💙

</div>
