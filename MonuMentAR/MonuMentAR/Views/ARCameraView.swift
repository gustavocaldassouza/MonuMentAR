import SwiftUI
import ARKit
import RealityKit
import AVFoundation
import CoreLocation
import CoreMotion

struct ARCameraView: UIViewRepresentable {
    @ObservedObject var gpsDetectionService: GPSBasedDetectionService
    @Binding var isSessionRunning: Bool
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        
        // Enable camera feed display
        arView.automaticallyUpdatesLighting = true
        arView.showsStatistics = false
        
        print("🎥 Setting up AR camera view...")
        
        // Configure AR session for geo tracking if available
        if #available(iOS 14.0, *) {
            print("📱 iOS 14+ detected, attempting geo tracking setup...")
            context.coordinator.setupGeoTracking(arView: arView)
        } else {
            // Fallback to world tracking for iOS 13
            print("📱 iOS 13 detected, using world tracking...")
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
            arView.session.run(configuration)
            print("✅ World tracking configuration started")
        }
        
        isSessionRunning = true
        print("✅ AR session marked as running")
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update view if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        var parent: ARCameraView
        private var geoAnchorService: ARGeoAnchorService?
        private var landmarkNodes: [UUID: SCNNode] = [:]
        
        init(_ parent: ARCameraView) {
            self.parent = parent
            super.init()
            
            if #available(iOS 14.0, *) {
                self.geoAnchorService = ARGeoAnchorService()
            }
        }
        
        // MARK: - Setup Methods
        
        @available(iOS 14.0, *)
        func setupGeoTracking(arView: ARSCNView) {
            print("🌍 Configuring geo tracking...")
            geoAnchorService?.configure(with: arView.session)
            
            // Check if geo tracking is available before starting
            if geoAnchorService?.isGeoTrackingAvailable == true {
                print("✅ Geo tracking available, starting...")
                geoAnchorService?.startGeoTracking()
            } else {
                print("⚠️ Geo tracking not available, falling back to world tracking...")
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = [.horizontal, .vertical]
                configuration.environmentTexturing = .automatic
                arView.session.run(configuration)
            }
        }
        
        // MARK: - ARSCNViewDelegate
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if #available(iOS 14.0, *), let geoAnchor = anchor as? ARGeoAnchor {
                handleGeoAnchor(node: node, geoAnchor: geoAnchor)
        } else {
            // For non-geo anchors, we can't reliably get the landmark name
            // since anchor.name is read-only and we can't set it
            print("⚠️ Non-geo anchor detected but no name mapping available")
        }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
            // Update landmark visibility based on GPS detection
            Task { @MainActor in
                updateLandmarkVisibility()
            }
        }
        
        @available(iOS 14.0, *)
        private func handleGeoAnchor(node: SCNNode, geoAnchor: ARGeoAnchor) {
            // Get landmark name from our service's mapping
            guard let landmarkName = geoAnchorService?.getLandmarkName(for: geoAnchor.identifier),
                  let landmark = MontrealLandmark.landmarks.first(where: { $0.name == landmarkName }) else {
                return
            }
            
            let labelNode = createLandmarkLabel(for: landmark)
            node.addChildNode(labelNode)
            landmarkNodes[landmark.id] = node
            
            print("📍 Added AR content for \(landmark.name)")
        }
        
        private func handleLandmarkAnchor(node: SCNNode, anchorName: String) {
            guard let landmark = MontrealLandmark.landmarks.first(where: { $0.name == anchorName }) else {
                return
            }
            
            let labelNode = createLandmarkLabel(for: landmark)
            node.addChildNode(labelNode)
            landmarkNodes[landmark.id] = node
        }
        
        private func updateLandmarkVisibility() {
            let detectedLandmarks = parent.gpsDetectionService.detectedLandmarks
            
            // Add geo anchors for newly detected landmarks
            for detection in detectedLandmarks {
                if landmarkNodes[detection.landmark.id] == nil {
                    if #available(iOS 14.0, *) {
                        geoAnchorService?.addGeoAnchor(for: detection.landmark)
                    }
                }
            }
            
            // Update existing nodes with detection info
            for detection in detectedLandmarks {
                if let node = landmarkNodes[detection.landmark.id] {
                    updateLandmarkNode(node: node, detection: detection)
                }
            }
        }
        
        private func createLandmarkLabel(for landmark: MontrealLandmark) -> SCNNode {
            // Create text geometry
            let text = SCNText(string: landmark.name, extrusionDepth: 0.1)
            text.font = UIFont.systemFont(ofSize: 2.0, weight: .bold)
            text.firstMaterial?.diffuse.contents = UIColor.white
            text.firstMaterial?.specular.contents = UIColor.white
            text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            
            // Create text node
            let textNode = SCNNode(geometry: text)
            textNode.scale = SCNVector3(0.02, 0.02, 0.02)
            textNode.position = SCNVector3(0, 2, 0) // Position above the landmark
            
            // Create background plane
            let plane = SCNPlane(width: 4, height: 1)
            plane.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.8)
            plane.cornerRadius = 0.2
            
            let backgroundNode = SCNNode(geometry: plane)
            backgroundNode.position = SCNVector3(0, 1.5, -0.1)
            
            // Container node
            let containerNode = SCNNode()
            containerNode.addChildNode(backgroundNode)
            containerNode.addChildNode(textNode)
            
            // Make it always face the camera
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            containerNode.constraints = [billboardConstraint]
            
            return containerNode
        }
        
        private func updateLandmarkNode(node: SCNNode, detection: GPSDetectedLandmark) {
            // Update opacity based on confidence
            node.opacity = CGFloat(detection.confidence)
            
            // You could add more dynamic updates here, like distance info
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session failed: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("AR Session was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("AR Session interruption ended")
        }
        
        @available(iOS 14.0, *)
        func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
            geoAnchorService?.updateGeoTrackingStatus(geoTrackingStatus)
        }
    }
}

// MARK: - AR Camera View with Overlay

struct ARCameraViewWithOverlay: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var motionService = MotionService()
    @StateObject private var gpsDetectionService: GPSBasedDetectionService
    @State private var isSessionRunning = false
    @State private var showLandmarkInfo = false
    @State private var selectedLandmark: MontrealLandmark?
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
        ZStack {
            // AR Camera View
            ARCameraView(gpsDetectionService: gpsDetectionService, isSessionRunning: $isSessionRunning)
                .ignoresSafeArea()
            
            // Overlay for detected landmarks
            if !gpsDetectionService.detectedLandmarks.isEmpty {
                ForEach(gpsDetectionService.detectedLandmarks) { detectedLandmark in
                    GPSLandmarkOverlayView(detectedLandmark: detectedLandmark) {
                        selectedLandmark = detectedLandmark.landmark
                        showLandmarkInfo = true
                    }
                }
            }
            
            // Detection indicator
            if gpsDetectionService.isDetecting {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("GPS Detecting...")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
                }
            }
            
            // Back button and Detection count
            VStack {
                HStack {
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Back")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(25)
                    }
                    
                    Spacer()
                    
                    // Detection count and status
                    VStack {
                        Text("GPS Detected")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("\(gpsDetectionService.detectedLandmarks.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Location status
                        if locationService.isLocationAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                                    .font(.caption2)
                                Text("GPS")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "location.slash")
                                    .foregroundColor(.red)
                                    .font(.caption2)
                                Text("No GPS")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
                .padding()
                Spacer()
            }
        }
        .sheet(isPresented: $showLandmarkInfo) {
            if let landmark = selectedLandmark {
                LandmarkDetailView(landmark: landmark)
            }
        }
        .onAppear {
            // Start GPS-based detection
            gpsDetectionService.startDetection()
        }
        .onDisappear {
            // Stop GPS-based detection
            gpsDetectionService.stopDetection()
        }
    }
}

// MARK: - GPS Landmark Overlay View

struct GPSLandmarkOverlayView: View {
    let detectedLandmark: GPSDetectedLandmark
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detectedLandmark.landmark.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("📍 \(detectedLandmark.formattedDistance)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("🧭 \(detectedLandmark.formattedBearing)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("Confidence: \(Int(detectedLandmark.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Tap for details")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Legacy Landmark Overlay View (for backward compatibility)

struct LandmarkOverlayView: View {
    let detectedLandmark: DetectedLandmark
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detectedLandmark.landmark.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Text("Confidence: \(Int(detectedLandmark.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Tap for details")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Landmark Detail View

struct LandmarkDetailView: View {
    let landmark: MontrealLandmark
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(landmark.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(landmark.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Historical Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Historical Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(landmark.historicalInfo)
                            .font(.body)
                    }
                    
                    // Architectural Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Architectural Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("Style:")
                                .fontWeight(.medium)
                            Text(landmark.architecturalStyle)
                        }
                        
                        HStack {
                            Text("Year Built:")
                                .fontWeight(.medium)
                            Text(landmark.yearBuilt)
                        }
                    }
                    
                    // Coordinates
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Latitude: \(landmark.coordinates.latitude, specifier: "%.4f")")
                        Text("Longitude: \(landmark.coordinates.longitude, specifier: "%.4f")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Landmark Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ARCameraViewWithOverlay()
}

