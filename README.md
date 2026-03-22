# 🎧 WaveMixer - MultiTrack Audio Engine

A professional-grade Swift Package for multi-track, gapless, sample-accurate audio playback using `AVAudioEngine`.

## ✨ Features

- **Multi-track playback** - Play multiple audio tracks simultaneously in perfect sync
- **Gapless playback** - No silence between audio segments
- **Sample-accurate** - Precise synchronization across all tracks
- **Timeline-based** - All tracks follow a shared global timeline
- **Seeking support** - Jump to any point in the timeline with proper segment scheduling
- **Per-track volume control** - Independent volume adjustment for each track
- **Combine integration** - Reactive playback time observation
- **Clean architecture** - SOLID principles, loosely coupled components
- **Extensible design** - Ready for effects, automation, and more

## 📋 Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## 📦 Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/alimadhoun/WaveMixer.git", branch: "main")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version/branch

## 🚀 Quick Start

### Basic Usage

```swift
import MultiTrackAudioEngine

// Create the player
let player = MultiTrackPlayer()

// Create a track with audio segments
let segment1 = AudioSegment(
    fileURL: URL(fileURLWithPath: "/path/to/audio1.mp3"),
    startTime: 0,
    duration: 10.0
)

let segment2 = AudioSegment(
    fileURL: URL(fileURLWithPath: "/path/to/audio2.mp3"),
    startTime: 10.0,
    duration: 15.0
)

let track = Track(segments: [segment1, segment2])
track.volume = 0.8

// Add the track
player.addTrack(track)

// Control playback
player.play()
player.pause()
player.seek(to: 5.0)
player.skipForward(10)
```

### Observing Playback Time

```swift
import Combine

var cancellables = Set<AnyCancellable>()

player.currentTimePublisher
    .sink { time in
        print("Current time: \(time)")
    }
    .store(in: &cancellables)
```

### Multiple Tracks

```swift
// Track 1: Vocals
let vocalsTrack = Track(segments: [
    AudioSegment(fileURL: vocalsURL, startTime: 0, duration: 30)
])

// Track 2: Instruments
let instrumentsTrack = Track(segments: [
    AudioSegment(fileURL: instrumentsURL, startTime: 0, duration: 30)
])

// Track 3: Drums
let drumsTrack = Track(segments: [
    AudioSegment(fileURL: drumsURL, startTime: 0, duration: 30)
])

player.addTrack(vocalsTrack)
player.addTrack(instrumentsTrack)
player.addTrack(drumsTrack)

// Control individual volumes
player.setVolume(0.9, for: vocalsTrack.id)
player.setVolume(0.7, for: instrumentsTrack.id)
player.setVolume(0.6, for: drumsTrack.id)

player.play()
```

## 🏗 Architecture

The library follows a clean, modular architecture:

### Core Components

```
┌─────────────────────────────────────┐
│      MultiTrackPlayer (API)         │
└────────────┬────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐    ┌──────▼─────┐
│ Track  │    │ Transport  │
│ Models │    │ Controller │
└────────┘    └──────┬─────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
    ┌────▼──┐   ┌───▼────┐  ┌──▼─────┐
    │Engine │   │ Master │  │Scheduler│
    │Manager│   │ Clock  │  │         │
    └───────┘   └────────┘  └─────────┘
```

### Key Layers

1. **Public API** (`MultiTrackPlayer`)
   - High-level interface for end users
   - Track management, playback control, volume adjustment

2. **Engine Layer**
   - `AudioEngineManager` - AVAudioEngine lifecycle and node management
   - `TransportController` - Orchestrates playback across all tracks
   - `MasterClock` - Accurate time tracking using render time

3. **Scheduling Layer**
   - `Scheduler` - Handles gapless segment scheduling with sample accuracy

4. **Models**
   - `Track` - Represents an audio track with segments
   - `AudioSegment` - Defines a portion of audio in the timeline
   - `Timeline` - Global timeline representation

## 🎯 How It Works

### Timeline-Based Playback

All tracks follow a **shared global timeline** measured in seconds:

```
Timeline:  0s────────10s────────20s────────30s

Track 1:   [Segment A──────][Segment B──────]
Track 2:   [────Segment C─────────────────]
Track 3:        [Segment D][Segment E─────]
```

### Sample-Accurate Synchronization

- Uses `AVAudioPlayerNode.scheduleSegment()` for precise scheduling
- All tracks start at the same `AVAudioTime`
- Render time-based clock ensures sample-accurate playback position

### Gapless Playback

Segments are pre-scheduled before the current one finishes, ensuring no silence between segments.

### Seeking Implementation

When seeking to a new time:
1. Stop all player nodes
2. Calculate which segments should be playing at the target time
3. Schedule segments with proper offsets
4. Start all players at the same `AVAudioTime`
5. Update the master clock

## 📱 Example App

The package includes a complete iOS demo app showing:
- Multi-track playback
- Play/pause/stop controls
- Seek slider with time display
- Skip forward/backward (±10s)
- Per-track volume sliders
- Real-time playback time updates

See `Examples/iOSDemoApp/` for the full implementation.

## 🎛 API Reference

### MultiTrackPlayer

#### Track Management
```swift
func addTrack(_ track: Track)
func removeTrack(id: UUID)
func removeAllTracks()
```

#### Playback Control
```swift
func play()
func pause()
func stop()
```

#### Seeking
```swift
func seek(to time: TimeInterval)
func skipForward(_ seconds: TimeInterval = 10)
func skipBackward(_ seconds: TimeInterval = 10)
```

#### Properties
```swift
var currentTime: TimeInterval { get }
var duration: TimeInterval { get }
var isPlaying: Bool { get }
var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
```

#### Volume Control
```swift
func setVolume(_ value: Float, for trackID: UUID)
func getVolume(for trackID: UUID) -> Float?
```

### Track

```swift
class Track {
    let id: UUID
    var segments: [AudioSegment]
    var volume: Float
    var duration: TimeInterval { get }
}
```

### AudioSegment

```swift
struct AudioSegment {
    let fileURL: URL
    let startTime: TimeInterval
    let duration: TimeInterval
    var endTime: TimeInterval { get }
}
```

## 🔧 Advanced Usage

### Custom Timeline Duration

```swift
// Get the actual duration from audio files
import AVFoundation

func getDuration(of url: URL) -> TimeInterval {
    let asset = AVAsset(url: url)
    return asset.duration.seconds
}

let actualDuration = getDuration(of: audioURL)
let segment = AudioSegment(
    fileURL: audioURL,
    startTime: 0,
    duration: actualDuration
)
```

### Monitoring Playback

```swift
player.currentTimePublisher
    .receive(on: DispatchQueue.main)
    .sink { time in
        // Update UI
        let progress = time / player.duration
        progressView.progress = Float(progress)
    }
    .store(in: &cancellables)
```

## 🧪 Testing

The architecture is designed to be testable:
- Small, focused components with single responsibilities
- Protocol-based dependencies (can be added for DI)
- Deterministic scheduling logic

## 🚀 Future Extensions

The architecture supports future enhancements:

- **Audio Effects** - EQ, reverb, compression per track
- **Volume Automation** - Time-based volume curves
- **Crossfade** - Smooth transitions between segments
- **Recording** - Capture multi-track output
- **Streaming** - Remote audio file support
- **Waveform Rendering** - Visual representation

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is available under the MIT License.

## 🙏 Acknowledgments

Built with:
- AVAudioEngine
- Combine
- SwiftUI (demo app)

## 💡 Use Cases

Perfect for:
- Music production apps
- Audio editors
- Podcast tools
- Language learning apps
- Karaoke applications
- DJ mixing software
- Audio composition tools

---

**Happy mixing! 🎵**
