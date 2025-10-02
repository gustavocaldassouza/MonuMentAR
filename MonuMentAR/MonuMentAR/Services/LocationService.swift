import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var isLocationAvailable: Bool = false
    
    private let locationManager = CLLocationManager()
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    private let distanceFilter: CLLocationDistance = 1.0 // Update every meter
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter
        
        // Request permission
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorizationStatus = locationManager.authorizationStatus
            isLocationAvailable = false
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationStatus = locationManager.authorizationStatus
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = LocationError.locationServicesDisabled
            isLocationAvailable = false
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationAvailable = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationAvailable = false
    }
    
    // Calculate distance between two coordinates
    func distance(from location1: CLLocationCoordinate2D, to location2: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
        let loc2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
        return loc1.distance(from: loc2)
    }
    
    // Calculate bearing from current location to target coordinate
    func bearing(to targetCoordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        return bearing(from: currentLocation.coordinate, to: targetCoordinate)
    }
    
    // Calculate bearing between two coordinates
    func bearing(from startCoordinate: CLLocationCoordinate2D, to endCoordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = startCoordinate.latitude * .pi / 180
        let lat2 = endCoordinate.latitude * .pi / 180
        let deltaLon = (endCoordinate.longitude - startCoordinate.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y)
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
    
    // Calculate elevation angle to a landmark
    func elevationAngle(to landmark: MontrealLandmark) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        
        let distance = distance(from: currentLocation.coordinate, to: landmark.coordinates)
        let heightDifference = (landmark.elevationAboveSeaLevel + landmark.height) - 
                              (currentLocation.altitude + 1.7) // 1.7m average eye level
        
        return atan2(heightDifference, distance) * 180 / .pi
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.currentLocation = location
            self.locationError = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.isLocationAvailable = false
                self.locationError = LocationError.locationPermissionDenied
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case locationServicesDisabled
    case locationPermissionDenied
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .locationPermissionDenied:
            return "Location permission denied. Please allow location access in Settings."
        case .locationUnavailable:
            return "Current location is unavailable."
        }
    }
}

