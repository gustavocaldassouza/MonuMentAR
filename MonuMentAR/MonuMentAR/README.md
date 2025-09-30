# MonuMentAR

MonuMentAR is an iOS augmented reality app that recognizes and displays information about Montreal monuments when the user points their device camera at them. It combines geolocation, computer vision, and AR to provide a rich, on-site tourism experience.

## Key Features

- **Real-Time Monument Recognition**: Uses Core ML and Vision to identify 5 major Montreal landmarks.
- **AR Information Overlays**: Displays monument name, history, architectural details, and distance in AR.
- **Location Awareness**: Integrates Core Location to trigger AR overlays when within proximity.
- **Offline Capability**: Core ML models and monument data run entirely on-device.
- **SwiftUI & RealityKit**: Modern UI framework and AR rendering engine.

## Project Structure

```text
MonuMentAR/
├── AppDelegate.swift
├── ContentView.swift
├── Assets/
├── Assets.xcassets/
├── Models/
├── Views/
├── ViewModels/
├── Services/
├── Utils/
└── Resources/
```

## Getting Started

### Prerequisites

- Xcode 16.5 or later
- iOS 14.0+ device with A12 Bionic or later
- Apple Developer account

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/gustavocaldasdesouza/MonuMentAR.git
   cd MonuMentAR
   ```

2. Open the project in Xcode:

   ```bash
   open MonuMentAR.xcodeproj
   ```

3. Select your development team under **Signing & Capabilities**.
4. Connect a compatible iOS device and set it as the run destination.
5. Build and run (⌘R).

## Folder Overview

- **Models**: Core ML models and monument data JSON.
- **Views**: SwiftUI views, including ARView container and overlay/detail views.
- **ViewModels**: Logic for AR session and monument recognition.
- **Services**: Handlers for location, AR session configuration, and ML inference.
- **Utils**: Helper extensions and constants.
- **Resources**: USDZ assets and Info.plist.

## Next Steps

1. Implement AR session setup in `ARService.swift`.
2. Integrate Core Location in `LocationService.swift`.
3. Add monument recognition logic in `MLService.swift`.
4. Build SwiftUI views for AR overlays and details.

## License

This project is released under the MIT License.
