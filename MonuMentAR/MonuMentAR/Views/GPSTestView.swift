import SwiftUI
import CoreLocation

struct GPSTestView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var motionService = MotionService()
    @StateObject private var gpsDetectionService: GPSBasedDetectionService
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let locationService = LocationService()
        let motionService = MotionService()
        let gpsDetectionService = GPSBasedDetectionService(
            locationService: locationService,
            motionService: motionService
        )
        
        self._locationService = StateObject(wrappedValue: locationService)
        self._motionService = StateObject(wrappedValue: motionService)
        self._gpsDetectionService = StateObject(wrappedValue: gpsDetectionService)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Location Status
                    GroupBox("Location Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Authorization:")
                                Spacer()
                                Text(authorizationStatusText)
                                    .foregroundColor(locationService.authorizationStatus == .authorizedWhenInUse ? .green : .red)
                            }
                            
                            if let location = locationService.currentLocation {
                                HStack {
                                    Text("Latitude:")
                                    Spacer()
                                    Text(String(format: "%.6f", location.coordinate.latitude))
                                        .font(.monospaced(.body)())
                                }
                                
                                HStack {
                                    Text("Longitude:")
                                    Spacer()
                                    Text(String(format: "%.6f", location.coordinate.longitude))
                                        .font(.monospaced(.body)())
                                }
                                
                                HStack {
                                    Text("Altitude:")
                                    Spacer()
                                    Text(String(format: "%.1fm", location.altitude))
                                        .font(.monospaced(.body)())
                                }
                                
                                HStack {
                                    Text("Accuracy:")
                                    Spacer()
                                    Text(String(format: "±%.1fm", location.horizontalAccuracy))
                                        .font(.monospaced(.body)())
                                }
                            } else {
                                Text("Location not available")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Motion Status
                    GroupBox("Motion Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Motion Available:")
                                Spacer()
                                Text(motionService.isMotionAvailable ? "Yes" : "No")
                                    .foregroundColor(motionService.isMotionAvailable ? .green : .red)
                            }
                            
                            HStack {
                                Text("Heading:")
                                Spacer()
                                Text(String(format: "%.1f°", motionService.deviceHeading))
                                    .font(.monospaced(.body)())
                            }
                            
                            HStack {
                                Text("Pitch:")
                                Spacer()
                                Text(String(format: "%.1f°", motionService.devicePitch))
                                    .font(.monospaced(.body)())
                            }
                            
                            HStack {
                                Text("Roll:")
                                Spacer()
                                Text(String(format: "%.1f°", motionService.deviceRoll))
                                    .font(.monospaced(.body)())
                            }
                        }
                    }
                    
                    // Detection Status
                    GroupBox("Detection Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Detecting:")
                                Spacer()
                                Text(gpsDetectionService.isDetecting ? "Active" : "Inactive")
                                    .foregroundColor(gpsDetectionService.isDetecting ? .green : .red)
                            }
                            
                            HStack {
                                Text("Landmarks Found:")
                                Spacer()
                                Text("\(gpsDetectionService.detectedLandmarks.count)")
                                    .font(.monospaced(.body)())
                            }
                            
                            if let error = gpsDetectionService.detectionError {
                                Text("Error: \(error.localizedDescription)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // Detected Landmarks
                    if !gpsDetectionService.detectedLandmarks.isEmpty {
                        GroupBox("Detected Landmarks") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(gpsDetectionService.detectedLandmarks) { detection in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(detection.landmark.name)
                                            .font(.headline)
                                        
                                        HStack {
                                            Text("Distance:")
                                            Spacer()
                                            Text(detection.formattedDistance)
                                        }
                                        .font(.caption)
                                        
                                        HStack {
                                            Text("Bearing:")
                                            Spacer()
                                            Text("\(String(format: "%.1f", detection.bearing))° (\(detection.formattedBearing))")
                                        }
                                        .font(.caption)
                                        
                                        HStack {
                                            Text("Confidence:")
                                            Spacer()
                                            Text("\(Int(detection.confidence * 100))%")
                                        }
                                        .font(.caption)
                                        
                                        HStack {
                                            Text("Elevation:")
                                            Spacer()
                                            Text(String(format: "%.1f°", detection.elevationAngle))
                                        }
                                        .font(.caption)
                                    }
                                    .padding(.vertical, 4)
                                    
                                    if detection.id != gpsDetectionService.detectedLandmarks.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    
                    // All Landmarks (for reference)
                    GroupBox("All Montreal Landmarks") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(MontrealLandmark.landmarks) { landmark in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(landmark.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("Lat: \(String(format: "%.4f", landmark.coordinates.latitude)), Lon: \(String(format: "%.4f", landmark.coordinates.longitude))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let currentLocation = locationService.currentLocation {
                                        let distance = locationService.distance(from: currentLocation.coordinate, to: landmark.coordinates)
                                        let bearing = locationService.bearing(to: landmark.coordinates) ?? 0
                                        
                                        Text("Distance: \(String(format: "%.0fm", distance)), Bearing: \(String(format: "%.1f°", bearing))")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 2)
                                
                                if landmark.id != MontrealLandmark.landmarks.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("GPS Detection Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(gpsDetectionService.isDetecting ? "Stop" : "Start") {
                        if gpsDetectionService.isDetecting {
                            gpsDetectionService.stopDetection()
                        } else {
                            gpsDetectionService.startDetection()
                        }
                    }
                }
            }
        }
        .onAppear {
            gpsDetectionService.startDetection()
        }
        .onDisappear {
            gpsDetectionService.stopDetection()
        }
    }
    
    private var authorizationStatusText: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }
}

#Preview {
    GPSTestView()
}

