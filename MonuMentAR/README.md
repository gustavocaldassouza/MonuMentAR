# MonuMentAR

An augmented reality iOS app that recognizes and provides information about major Montreal landmarks using Core ML and ARKit.

## Features

- **Real-time camera feed analysis** using Core ML models
- **Recognition of 5 major Montreal landmarks**:
  - Notre-Dame Basilica
  - Olympic Stadium & Tower
  - Mount Royal Cross
  - Old Port Clock Tower
  - Saint Joseph's Oratory
- **Confidence threshold system** (only displays info above 85% confidence)
- **Visual feedback** when monuments are detected (overlay borders/highlights)
- **Detailed landmark information** including historical facts and architectural details

## Architecture

### Models

- `MontrealLandmark.swift` - Data model for landmark information including coordinates, historical data, and Core ML identifiers

### Services

- `MonumentRecognitionService.swift` - Core ML integration for real-time landmark recognition with confidence filtering

### Views

- `ContentView.swift` - Main app interface with navigation to AR experience and landmark list
- `ARCameraView.swift` - AR camera implementation with real-time analysis and visual overlays

## Setup Instructions

### 1. Prerequisites

- Xcode 15.0+
- iOS 17.0+ device with ARKit support
- Camera and location permissions

### 2. Adding a Real Core ML Model

Currently, the app uses mock detection for demonstration. To add real landmark recognition:

1. **Train a Core ML Model**:
   - Collect images of each Montreal landmark from various angles and lighting conditions
   - Use Create ML or Turi Create to train a custom image classification model
   - Export the model as a `.mlmodel` file

2. **Add Model to Project**:
   - Drag the `.mlmodel` file into your Xcode project
   - Update the `createGenericModel()` method in `MonumentRecognitionService.swift`:

   ```swift
   private func createGenericModel() -> MLModel? {
       guard let modelURL = Bundle.main.url(forResource: "MontrealLandmarks", withExtension: "mlmodel") else {
           return nil
       }
       return try? MLModel(contentsOf: modelURL)
   }
   ```

3. **Update Model Identifiers**:
   - Ensure the model's output class identifiers match the `modelIdentifier` values in `MontrealLandmark.swift`

### 3. Permissions

The app requires the following permissions (already configured in Info.plist):

- Camera access for AR functionality
- Location access for landmark proximity

## Usage

1. **Launch the app** and tap "Start AR Experience"
2. **Point your camera** at Montreal landmarks
3. **View detected landmarks** with confidence scores and detailed information
4. **Tap on detected landmarks** for more detailed historical and architectural information

## Technical Details

### Core ML Integration

- Uses Vision framework for image analysis
- Implements confidence threshold filtering (85% minimum)
- Supports both real-time camera analysis and mock detection for testing

### AR Implementation

- ARKit for camera tracking and world mapping
- RealityKit for 3D content rendering
- Real-time frame capture and analysis

### Performance Considerations

- Analysis runs every 1 second to balance accuracy and performance
- Confidence threshold prevents false positives
- Mock detection available for testing without trained model

## Future Enhancements

- **3D AR overlays** with 3D models of landmarks
- **Location-based filtering** to show only nearby landmarks
- **Historical timeline** showing landmark evolution
- **Social features** for sharing discoveries
- **Offline mode** with cached landmark data

## Development Notes

The current implementation includes:

- Complete data models for all 5 Montreal landmarks
- AR camera view with real-time analysis framework
- Visual feedback system with overlays and highlights
- Confidence threshold system (85% minimum)
- Mock detection for testing without trained model
- Modern SwiftUI interface with navigation

To make this production-ready, you'll need to:

1. Train and integrate a real Core ML model
2. Test on physical devices with real landmark images
3. Fine-tune confidence thresholds based on real-world performance
4. Add proper error handling and edge cases

