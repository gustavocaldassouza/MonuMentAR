# GPS-Based Monument Detection System

## Overview

MonuMentAR now uses a GPS and orientation-based detection system instead of on-device machine learning for monument recognition. This approach provides instant, accurate landmark identification by combining:

- **GPS location data** from Core Location
- **Device orientation** from Core Motion (magnetometer + gyroscope)  
- **Precise landmark coordinates** stored in the app
- **AR geo-anchoring** for world-locked overlays

## How It Works

### 1. Landmark Database

Each Montreal landmark is stored with:

- Precise GPS coordinates (latitude/longitude)
- Height above ground level
- Footprint radius for detection range
- Elevation above sea level

### 2. Real-time Tracking

The system continuously monitors:

- **User location** via Core Location (GPS)
- **Device heading** via magnetometer (0-360°)
- **Device pitch/roll** via gyroscope
- **Viewing direction** calculated as 3D vector

### 3. Detection Algorithm

For each landmark, the system:

1. Calculates **bearing** from user to landmark
2. Computes **elevation angle** based on height difference and distance
3. Compares device orientation to expected angles
4. Matches within tolerance (±8° bearing, ±10° elevation)
5. Assigns **confidence score** based on accuracy

### 4. AR Anchoring

Detected landmarks are displayed using:

- **ARGeoAnchor** (iOS 14+) for precise world positioning
- **Custom location anchors** (iOS 13 fallback)
- **Billboard constraints** so labels always face camera
- **Dynamic opacity** based on detection confidence

## Key Components

### Services

#### `LocationService`

- Manages Core Location permissions and updates
- Calculates distances and bearings between coordinates
- Provides elevation angle calculations
- Handles location accuracy and error states

#### `MotionService`

- Manages Core Motion device orientation
- Smooths sensor readings to reduce jitter
- Provides heading, pitch, and roll values
- Handles circular averaging for compass headings

#### `GPSBasedDetectionService`

- Combines location and motion data
- Performs landmark visibility calculations
- Manages detection timing and confidence scoring
- Filters results by distance and angular accuracy

#### `ARGeoAnchorService`

- Creates and manages AR geo anchors
- Handles geo tracking status updates
- Provides fallback for older iOS versions
- Manages anchor lifecycle and cleanup

### Models

#### `MontrealLandmark` (Enhanced)

```swift
struct MontrealLandmark {
    let coordinates: CLLocationCoordinate2D
    let height: Double // Height above ground
    let footprintRadius: Double // Detection radius
    let elevationAboveSeaLevel: Double // Base elevation
    // ... other properties
}
```

#### `GPSDetectedLandmark`

```swift
struct GPSDetectedLandmark {
    let landmark: MontrealLandmark
    let confidence: Float // 0.0 - 1.0
    let distance: Double // Meters
    let bearing: Double // Degrees
    let elevationAngle: Double // Degrees
    let bearingAccuracy: Double // Match accuracy
    let elevationAccuracy: Double // Match accuracy
}
```

## Detection Parameters

### Tolerances

- **Bearing tolerance**: ±8° (adjustable)
- **Elevation tolerance**: ±10° (adjustable)
- **Detection range**: 50m - 10km
- **Update frequency**: 2Hz (500ms intervals)

### Confidence Calculation

```swift
confidence = (bearingAccuracy * 0.4) + 
             (elevationAccuracy * 0.4) + 
             (distanceScore * 0.2)
```

Where:

- `bearingAccuracy` = 1.0 - (bearingError / tolerance)
- `elevationAccuracy` = 1.0 - (elevationError / tolerance)  
- `distanceScore` = optimal distance curve based on landmark size

## Advantages Over ML Approach

### Performance

- ⚡ **Instant detection** (no model inference time)
- 🔋 **Lower battery usage** (no continuous image processing)
- 📱 **Works on older devices** (no ML hardware requirements)
- 🌐 **Works in any lighting** (no camera dependency)

### Accuracy

- 🎯 **Precise positioning** using GPS coordinates
- 📏 **Distance awareness** for better UX
- 🧭 **Direction-aware** detection
- 🏔️ **Elevation-aware** for mountainous landmarks

### Reliability

- 🌙 **Works day and night** (no visual recognition needed)
- 🌫️ **Weather independent** (fog, rain, snow)
- 👓 **Occlusion tolerant** (works even if landmark is hidden)
- 📶 **Offline capable** (no network required after initial load)

## Usage

### Basic Implementation

```swift
// Initialize services
let locationService = LocationService()
let motionService = MotionService()
let gpsDetection = GPSBasedDetectionService(
    locationService: locationService,
    motionService: motionService
)

// Start detection
gpsDetection.startDetection()

// Monitor results
gpsDetection.detectedLandmarks // [GPSDetectedLandmark]
```

### AR Integration

```swift
// Setup AR with geo tracking
let arGeoService = ARGeoAnchorService()
arGeoService.configure(with: arSession)
arGeoService.startGeoTracking()

// Add anchors for detected landmarks
for detection in detectedLandmarks {
    arGeoService.addGeoAnchor(for: detection.landmark)
}
```

## Testing

### GPS Test View

The app includes a comprehensive test view (`GPSTestView`) showing:

- Real-time location and motion data
- Detection status and errors
- Live landmark detection results
- Distance and bearing calculations
- Confidence scores and accuracy metrics

### Debug Information

Enable detailed logging to see:

```
🧭 GPS Detected: Notre-Dame Basilica (87%), Olympic Stadium (72%)
📍 Added geo anchor for Notre-Dame Basilica at 45.5017, -73.5563
✅ Geo tracking localized
```

## Permissions Required

Add to `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MonuMentAR needs location access for landmark detection</string>

<key>NSMotionUsageDescription</key>
<string>MonuMentAR uses motion sensors for device orientation</string>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arkit</string>
    <string>location-services</string>
    <string>gyroscope</string>
    <string>magnetometer</string>
</array>
```

## Limitations

### GPS Accuracy

- Requires GPS signal (poor performance indoors)
- Accuracy depends on satellite visibility
- Urban canyons may affect precision

### Motion Sensors

- Magnetometer affected by metal structures
- Requires device calibration
- May drift over time

### Detection Range

- Limited to pre-defined landmarks
- Requires accurate coordinate data
- Distance-dependent accuracy

## Future Enhancements

### Possible Improvements

1. **Sensor fusion** with visual-inertial odometry
2. **Machine learning** for confidence refinement
3. **Crowd-sourced** landmark coordinate verification
4. **Indoor positioning** using WiFi/Bluetooth beacons
5. **Multi-modal detection** combining GPS + visual recognition

### Scalability

- **Dynamic landmark loading** from server
- **Regional landmark databases**
- **User-contributed landmarks**
- **Real-time coordinate updates**

## Conclusion

The GPS-based detection system provides a robust, efficient alternative to machine learning for landmark recognition. It offers instant results, works in all conditions, and provides precise AR anchoring for an excellent user experience.

The system is particularly well-suited for outdoor landmark detection where GPS accuracy is high and provides a foundation for future enhancements combining multiple detection modalities.

