import Foundation
import ARKit
import CoreLocation
import RealityKit
import Combine

@available(iOS 14.0, *)
class ARGeoAnchorService: ObservableObject {
    @Published var geoAnchors: [ARGeoAnchor] = []
    @Published var isGeoTrackingAvailable: Bool = false
    @Published var geoTrackingStatus: ARGeoTrackingStatus.State = .notAvailable
    @Published var anchorError: Error?
    
    private weak var arSession: ARSession?
    private var landmarkAnchors: [UUID: ARGeoAnchor] = [:]
    private var anchorNames: [UUID: String] = [:] // Map anchor identifiers to landmark names
    
    init() {
        checkGeoTrackingAvailability()
    }
    
    func configure(with arSession: ARSession) {
        self.arSession = arSession
    }
    
    private func checkGeoTrackingAvailability() {
        ARGeoTrackingConfiguration.checkAvailability { [weak self] available, error in
            DispatchQueue.main.async {
                self?.isGeoTrackingAvailable = available
                if let error = error {
                    self?.anchorError = error
                    print("❌ Geo tracking not available: \(error.localizedDescription)")
                } else if available {
                    print("✅ Geo tracking is available")
                } else {
                    print("⚠️ Geo tracking is not available on this device")
                }
            }
        }
    }
    
    func startGeoTracking() {
        guard let arSession = arSession else {
            anchorError = ARGeoAnchorError.sessionNotConfigured
            return
        }
        
        guard isGeoTrackingAvailable else {
            anchorError = ARGeoAnchorError.geoTrackingUnavailable
            return
        }
        
        let configuration = ARGeoTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("🌍 Started AR geo tracking")
    }
    
    func addGeoAnchor(for landmark: MontrealLandmark) {
        guard let arSession = arSession else {
            anchorError = ARGeoAnchorError.sessionNotConfigured
            return
        }
        
        guard isGeoTrackingAvailable else {
            anchorError = ARGeoAnchorError.geoTrackingUnavailable
            return
        }
        
        // Remove existing anchor for this landmark if it exists
        removeGeoAnchor(for: landmark)
        
        // Create geo anchor at landmark's coordinates
        let coordinate = landmark.coordinates
        let altitude = landmark.elevationAboveSeaLevel + landmark.height / 2 // Place at middle height
        
        let geoAnchor = ARGeoAnchor(coordinate: coordinate, altitude: altitude)
        
        arSession.add(anchor: geoAnchor)
        
        // Store references
        landmarkAnchors[landmark.id] = geoAnchor
        anchorNames[geoAnchor.identifier] = landmark.name // Map anchor ID to landmark name
        geoAnchors.append(geoAnchor)
        
        print("📍 Added geo anchor for \(landmark.name) at \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    func removeGeoAnchor(for landmark: MontrealLandmark) {
        guard let arSession = arSession,
              let existingAnchor = landmarkAnchors[landmark.id] else {
            return
        }
        
        arSession.remove(anchor: existingAnchor)
        landmarkAnchors.removeValue(forKey: landmark.id)
        anchorNames.removeValue(forKey: existingAnchor.identifier) // Clean up name mapping
        geoAnchors.removeAll { $0.identifier == existingAnchor.identifier }
        
        print("🗑️ Removed geo anchor for \(landmark.name)")
    }
    
    func addGeoAnchors(for landmarks: [MontrealLandmark]) {
        for landmark in landmarks {
            addGeoAnchor(for: landmark)
        }
    }
    
    func removeAllGeoAnchors() {
        guard let arSession = arSession else { return }
        
        for anchor in geoAnchors {
            arSession.remove(anchor: anchor)
        }
        
        landmarkAnchors.removeAll()
        anchorNames.removeAll() // Clean up all name mappings
        geoAnchors.removeAll()
        
        print("🧹 Removed all geo anchors")
    }
    
    func getGeoAnchor(for landmark: MontrealLandmark) -> ARGeoAnchor? {
        return landmarkAnchors[landmark.id]
    }
    
    // Get the landmark name for a given anchor identifier
    func getLandmarkName(for anchorIdentifier: UUID) -> String? {
        return anchorNames[anchorIdentifier]
    }
    
    // Create a custom location-based anchor for iOS 13 compatibility
    func createLocationAnchor(for landmark: MontrealLandmark, userLocation: CLLocation) -> ARAnchor? {
        // Calculate relative position from user to landmark
        let landmarkLocation = CLLocation(
            coordinate: landmark.coordinates,
            altitude: landmark.elevationAboveSeaLevel + landmark.height / 2,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        let distance = userLocation.distance(from: landmarkLocation)
        
        // Don't create anchors for very distant landmarks
        guard distance <= 5000 else { return nil } // 5km max
        
        // Calculate bearing and create transform
        let bearing = calculateBearing(from: userLocation.coordinate, to: landmark.coordinates)
        let bearingRadians = bearing * .pi / 180
        
        // Calculate relative position (simplified projection)
        let x = Float(distance * sin(bearingRadians))
        let z = -Float(distance * cos(bearingRadians)) // Negative Z is forward in ARKit
        let y = Float(landmarkLocation.altitude - userLocation.altitude)
        
        let translation = simd_float4x4(
            simd_float4(1, 0, 0, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(x, y, z, 1)
        )
        
        let anchor = ARAnchor(transform: translation)
        // Note: Cannot set anchor.name directly as it's read-only
        // Store the name mapping separately if needed
        
        return anchor
    }
    
    private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y)
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
    
    // Handle geo tracking status updates
    @MainActor
    func updateGeoTrackingStatus(_ status: ARGeoTrackingStatus) {
        geoTrackingStatus = status.state
        
        switch status.state {
        case .notAvailable:
            print("🚫 Geo tracking not available")
        case .initializing:
            print("🔄 Geo tracking initializing...")
        case .localized:
            print("✅ Geo tracking localized")
            anchorError = nil
        case .localizing:
            print("🔍 Geo tracking localizing...")
        @unknown default:
            print("❓ Unknown geo tracking state")
        }
        
        let reason = status.stateReason
        if reason != .none {
            switch reason {
            case .none:
                break
            case .worldTrackingUnstable:
                print("⚠️ World tracking unstable")
            case .waitingForLocation:
                print("📍 Waiting for location...")
            case .geoDataNotLoaded:
                print("📊 Geo data not loaded")
            case .devicePointedTooLow:
                print("📱 Device pointed too low")
            case .visualLocalizationFailed:
                print("👁️ Visual localization failed")
            @unknown default:
                print("❓ Unknown geo tracking reason")
            }
        }
    }
}

// MARK: - AR Geo Anchor Errors

enum ARGeoAnchorError: LocalizedError {
    case sessionNotConfigured
    case geoTrackingUnavailable
    case anchorCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .sessionNotConfigured:
            return "AR session is not configured."
        case .geoTrackingUnavailable:
            return "Geo tracking is not available on this device."
        case .anchorCreationFailed:
            return "Failed to create geo anchor."
        }
    }
}

