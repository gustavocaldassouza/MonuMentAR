import Foundation
import CoreLocation
import Combine

@MainActor
class GPSBasedDetectionService: ObservableObject {
    @Published var detectedLandmarks: [GPSDetectedLandmark] = []
    @Published var isDetecting: Bool = false
    @Published var detectionError: Error?
    
    private let locationService: LocationService
    private let motionService: MotionService
    
    // Detection parameters - More realistic values
    private let bearingTolerance: Double = 5.0 // ±5 degrees for bearing match (tighter)
    private let elevationTolerance: Double = 8.0 // ±8 degrees for elevation match (tighter)
    private let maxDetectionDistance: Double = 3000.0 // 3km max detection range (more realistic)
    private let minDetectionDistance: Double = 50.0 // 50m minimum distance
    private let minConfidenceThreshold: Double = 0.3 // Minimum 30% confidence to report detection
    
    // Detection timing
    private var detectionTimer: Timer?
    private let detectionInterval: TimeInterval = 0.5 // Detect every 500ms
    
    init(locationService: LocationService, motionService: MotionService) {
        self.locationService = locationService
        self.motionService = motionService
    }
    
    func startDetection() {
        guard !isDetecting else { return }
        
        isDetecting = true
        detectionError = nil
        
        // Start location and motion services
        locationService.startLocationUpdates()
        motionService.startMotionUpdates()
        
        // Start detection timer
        detectionTimer = Timer.scheduledTimer(withTimeInterval: detectionInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performDetection()
            }
        }
    }
    
    func stopDetection() {
        isDetecting = false
        detectionTimer?.invalidate()
        detectionTimer = nil
        
        locationService.stopLocationUpdates()
        motionService.stopMotionUpdates()
        
        detectedLandmarks.removeAll()
    }
    
    private func performDetection() async {
        guard let currentLocation = locationService.currentLocation else {
            detectionError = GPSDetectionError.locationUnavailable
            return
        }
        
        guard locationService.isLocationAvailable && motionService.isMotionAvailable else {
            detectionError = GPSDetectionError.sensorsUnavailable
            return
        }
        
        detectionError = nil
        var newDetections: [GPSDetectedLandmark] = []
        
        // Check each landmark
        for landmark in MontrealLandmark.landmarks {
            if let detection = checkLandmarkVisibility(landmark: landmark, userLocation: currentLocation) {
                newDetections.append(detection)
            }
        }
        
        // Sort by confidence (distance and angular accuracy)
        newDetections.sort { $0.confidence > $1.confidence }
        
        // Update detected landmarks
        detectedLandmarks = newDetections
        
        // Log detections for debugging
        if !newDetections.isEmpty {
            let detectionNames = newDetections.map { detection in
                let distance = detection.formattedDistance
                let confidence = Int(detection.confidence * 100)
                return "\(detection.landmark.name) (\(confidence)% @ \(distance))"
            }
            print("🧭 GPS Detected: \(detectionNames.joined(separator: ", "))")
        }
    }
    
    private func checkLandmarkVisibility(landmark: MontrealLandmark, userLocation: CLLocation) -> GPSDetectedLandmark? {
        // Calculate distance to landmark
        let distance = locationService.distance(from: userLocation.coordinate, to: landmark.coordinates)
        
        // Check if landmark is within detection range
        guard distance >= minDetectionDistance && distance <= maxDetectionDistance else {
            if distance > maxDetectionDistance {
                print("🚫 \(landmark.name) too far: \(Int(distance))m (max: \(Int(maxDetectionDistance))m)")
            }
            return nil
        }
        
        // Calculate bearing to landmark
        guard let bearingToLandmark = locationService.bearing(to: landmark.coordinates) else {
            return nil
        }
        
        // Check if device is pointing towards the landmark
        let bearingDifference = motionService.angularDifference(
            heading1: motionService.deviceHeading, 
            heading2: bearingToLandmark
        )
        
        guard bearingDifference <= bearingTolerance else {
            print("🚫 \(landmark.name) bearing mismatch: \(String(format: "%.1f", bearingDifference))° (max: \(bearingTolerance)°)")
            return nil
        }
        
        // Calculate expected elevation angle to landmark
        guard let expectedElevation = locationService.elevationAngle(to: landmark) else {
            return nil
        }
        
        // Check if device pitch matches expected elevation
        let elevationDifference = abs(motionService.devicePitch - expectedElevation)
        
        guard elevationDifference <= elevationTolerance else {
            print("🚫 \(landmark.name) elevation mismatch: \(String(format: "%.1f", elevationDifference))° (max: \(elevationTolerance)°)")
            return nil
        }
        
        // Calculate confidence based on accuracy of bearing and elevation match
        let bearingAccuracy = 1.0 - (bearingDifference / bearingTolerance)
        let elevationAccuracy = 1.0 - (elevationDifference / elevationTolerance)
        let distanceScore = calculateDistanceScore(distance: distance, landmark: landmark)
        
        let confidence = (bearingAccuracy * 0.4 + elevationAccuracy * 0.4 + distanceScore * 0.2)
        
        // Filter out low-confidence detections
        guard confidence >= minConfidenceThreshold else {
            print("🚫 \(landmark.name) low confidence: \(Int(confidence * 100))% (min: \(Int(minConfidenceThreshold * 100))%)")
            return nil
        }
        
        print("✅ \(landmark.name) detected: \(Int(confidence * 100))% @ \(Int(distance))m")
        
        return GPSDetectedLandmark(
            landmark: landmark,
            confidence: Float(confidence),
            distance: distance,
            bearing: bearingToLandmark,
            elevationAngle: expectedElevation,
            bearingAccuracy: bearingAccuracy,
            elevationAccuracy: elevationAccuracy
        )
    }
    
    private func calculateDistanceScore(distance: Double, landmark: MontrealLandmark) -> Double {
        // More realistic optimal viewing distances
        let optimalDistance = max(landmark.footprintRadius * 2, 100.0) // At least 100m optimal
        let maxGoodDistance = max(landmark.footprintRadius * 8, 500.0) // At least 500m max good
        let absoluteMaxDistance = min(maxDetectionDistance, 2000.0) // Never more than 2km
        
        if distance <= optimalDistance {
            return 1.0
        } else if distance <= maxGoodDistance {
            // Linear decay from optimal to max good distance
            return 1.0 - ((distance - optimalDistance) / (maxGoodDistance - optimalDistance)) * 0.6
        } else if distance <= absoluteMaxDistance {
            // Steep decay beyond max good distance
            return 0.4 * (1.0 - ((distance - maxGoodDistance) / (absoluteMaxDistance - maxGoodDistance)))
        } else {
            return 0.0 // No detection beyond absolute max
        }
    }
    
    // Get the landmark with highest confidence
    var primaryDetection: GPSDetectedLandmark? {
        return detectedLandmarks.first
    }
    
    // Check if a specific landmark is currently visible
    func isLandmarkVisible(_ landmark: MontrealLandmark) -> Bool {
        return detectedLandmarks.contains { $0.landmark.id == landmark.id }
    }
    
    // Get detection info for a specific landmark
    func getDetection(for landmark: MontrealLandmark) -> GPSDetectedLandmark? {
        return detectedLandmarks.first { $0.landmark.id == landmark.id }
    }
}

// MARK: - GPS Detected Landmark

struct GPSDetectedLandmark: Identifiable {
    let id = UUID()
    let landmark: MontrealLandmark
    let confidence: Float
    let distance: Double // Distance in meters
    let bearing: Double // Bearing in degrees
    let elevationAngle: Double // Elevation angle in degrees
    let bearingAccuracy: Double // How accurate the bearing match is (0-1)
    let elevationAccuracy: Double // How accurate the elevation match is (0-1)
    let timestamp = Date()
    
    // Formatted distance string
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    // Formatted bearing string
    var formattedBearing: String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", 
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((bearing + 11.25) / 22.5) % 16
        return directions[index]
    }
}

// MARK: - GPS Detection Errors

enum GPSDetectionError: LocalizedError {
    case locationUnavailable
    case sensorsUnavailable
    case noLandmarksInRange
    
    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "Current location is not available for landmark detection."
        case .sensorsUnavailable:
            return "Location or motion sensors are not available."
        case .noLandmarksInRange:
            return "No landmarks are currently in detection range."
        }
    }
}

