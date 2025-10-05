# WikiWings

An iOS game that transforms Wikipedia navigation into an exhilarating motion-controlled flight simulator. Dive through Wikipedia pages, steer with your device's accelerometer, and try to reach the legendary Philosophy page!

## Overview

WikiWings puts you in control of a rocket-powered dive through Wikipedia. Using your iPhone or iPad's motion sensors, you'll navigate through an ever-zooming view of Wikipedia pages, steering towards links to continue your journey. The game combines the famous "Getting to Philosophy" Wikipedia phenomenon with skill-based gameplay requiring precise motion control.

## Features

### Core Gameplay
- **Motion Controls**: Tilt your device to steer through Wikipedia pages
- **Zoom Dive Mechanic**: Pages continuously zoom in, creating a thrilling descent effect
- **Turbo Boost**: Hold the screen to double your dive speed
- **Progressive Difficulty**: Dive speed increases with each successful link navigation
- **Link Avoidance**: Previously visited links are marked with an X and won't count - avoid getting stuck in loops!

### Game Modes
- **Philosophy Quest**: Try to reach the Philosophy page (the legendary Wikipedia endpoint)
- **Hop Counter**: Track how many links you successfully navigate before crashing
- **Link History**: See your complete navigation path through Wikipedia

### Technical Features
- **External Display Support**: Connect to an external display for an immersive viewing experience while controlling from your device
- **High-Quality Rendering**: 4x content scale factor for crisp text at all zoom levels
- **Desktop Wikipedia Layout**: Renders the full desktop version of Wikipedia for better link visibility
- **Audio Effects**:
  - Rocket engine sound during flight
  - Link hit confirmation sounds
  - Special "Philosophy" achievement sound
  - Crash sound on game over
  - Text-to-speech announcements of page titles

### Visual Effects
- **Animated Start Screen**: Rocket animation with WikiWings branding
- **Game Over Display**: Shows your hop count and complete link journey
- **Philosophy Celebration**: Special visual effect when reaching the Philosophy page
- **Debug Mode**: Optional visualization of link hitboxes and control inputs

## How to Play

1. **Start**: Launch the app and tap "START"
2. **Control**: Tilt your device to steer your view
   - Pitch (banking left/right) controls horizontal movement
   - Roll (tilting forward/back) controls vertical movement
3. **Navigate**: Steer to completely contain a Wikipedia link within your screen
4. **Boost**: Press and hold anywhere on the screen to activate turbo boost (2x speed)
5. **Survive**: Keep navigating links without running out of options
6. **Win**: Try to reach the Philosophy page!

## Game Over Conditions

The game ends when you can no longer navigate to any new links on the current page - this happens when:
- All visible links have already been visited
- You've zoomed past all available links
- No links intersect with your viewport

## Requirements

- iOS 18.4+
- iPhone or iPad
- Device with accelerometer support
- Landscape orientation (left) required

## Installation

1. Clone this repository
2. Open `WikiLander.xcodeproj` in Xcode 16.3+
3. Build and run on your iOS device (simulator won't have motion controls)

## Technical Architecture

### Main Components

- **ViewController.swift**: Core game logic, motion control, and Wikipedia navigation
- **StartScreenSceneView.swift**: Animated rocket start screen
- **GameOverScreenView.swift**: End-game statistics display
- **RestartScreenView.swift**: Restart button UI
- **StartScreenControllerView.swift**: Start button UI

### Key Technologies

- **WKWebView**: Renders Wikipedia pages with desktop layout
- **CoreMotion**: Captures device orientation for control input
- **AVFoundation**: Audio playback and text-to-speech
- **SwiftUI**: Modern UI components for overlays and screens
- **CADisplayLink**: 60Hz animation loop for smooth gameplay

### Game Mechanics

The game uses a transform-based zoom system that:
1. Exponentially scales the web view at a rate determined by `scalePower`
2. Adjusts control sensitivity inversely with zoom level for consistent feel
3. Detects link containment by converting screen bounds to web view coordinate space
4. Tracks visited URLs to prevent navigation loops

## External Display Support

WikiWings supports external displays (via AirPlay or physical connection):
- Game view automatically transfers to external display
- Control interface remains on your device
- Separate visual content optimized for large screens
- "Yolk" image placeholder on device screen during gameplay

## Development Notes

### Debug Flags

The following debug flags can be toggled in `ViewController.swift`:
- `showDebugRectangles`: Visualize all link boundaries
- `showControlLines`: Display control input indicators

### Initial URL

The game starts at Wikipedia's Main Page by default. You can modify `originalURL` in `ViewController.swift` to start from a different page.

## Credits

Created by David Stolarsky

## License

[License information to be added]
