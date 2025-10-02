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
        private var discoveredLandmarks: Set<UUID> = [] // Track first-time discoveries
        private var celebrationNodes: [UUID: SCNNode] = [:] // Track celebration effects
        
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
            // Check if this is a first-time discovery
            let isFirstDiscovery = !discoveredLandmarks.contains(landmark.id)
            if isFirstDiscovery {
                discoveredLandmarks.insert(landmark.id)
            }
            
            // Create main container
            let containerNode = SCNNode()
            
            // Create the landmark display
            let landmarkDisplay = createLandmarkDisplay(for: landmark)
            containerNode.addChildNode(landmarkDisplay)
            
            // Add cool AR effects
            let effectsNode = createAREffects(for: landmark, isFirstDiscovery: isFirstDiscovery)
            containerNode.addChildNode(effectsNode)
            
            // Add discovery celebration if first time
            if isFirstDiscovery {
                let celebrationNode = createDiscoveryCelebration(for: landmark)
                containerNode.addChildNode(celebrationNode)
                celebrationNodes[landmark.id] = celebrationNode
                
                // Remove celebration after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    celebrationNode.removeFromParentNode()
                    self.celebrationNodes.removeValue(forKey: landmark.id)
                }
            }
            
            // Make it always face the camera
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            containerNode.constraints = [billboardConstraint]
            
            return containerNode
        }
        
        private func createLandmarkDisplay(for landmark: MontrealLandmark) -> SCNNode {
            let displayNode = SCNNode()
            
            // Create text geometry with glow effect
            let text = SCNText(string: landmark.name, extrusionDepth: 0.15)
            text.font = UIFont.systemFont(ofSize: 2.0, weight: .bold)
            text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            
            // Add materials for glow effect
            let textMaterial = SCNMaterial()
            textMaterial.diffuse.contents = UIColor.white
            textMaterial.emission.contents = UIColor.cyan.withAlphaComponent(0.3)
            textMaterial.specular.contents = UIColor.white
            text.materials = [textMaterial]
            
            // Create text node
            let textNode = SCNNode(geometry: text)
            textNode.scale = SCNVector3(0.02, 0.02, 0.02)
            textNode.position = SCNVector3(0, 2.5, 0)
            
            // Add pulsing animation to text
            let pulseAnimation = CABasicAnimation(keyPath: "scale")
            pulseAnimation.fromValue = SCNVector3(0.02, 0.02, 0.02)
            pulseAnimation.toValue = SCNVector3(0.025, 0.025, 0.025)
            pulseAnimation.duration = 2.0
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            textNode.addAnimation(pulseAnimation, forKey: "pulse")
            
            // Create enhanced background with gradient
            let backgroundPlane = SCNPlane(width: 5, height: 1.2)
            let backgroundMaterial = SCNMaterial()
            backgroundMaterial.diffuse.contents = createGradientImage()
            backgroundMaterial.transparency = 0.9
            backgroundPlane.materials = [backgroundMaterial]
            backgroundPlane.cornerRadius = 0.3
            
            let backgroundNode = SCNNode(geometry: backgroundPlane)
            backgroundNode.position = SCNVector3(0, 2.0, -0.1)
            
            // Create info text
            let infoText = SCNText(string: landmark.architecturalStyle, extrusionDepth: 0.05)
            infoText.font = UIFont.systemFont(ofSize: 1.0, weight: .medium)
            infoText.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            
            let infoMaterial = SCNMaterial()
            infoMaterial.diffuse.contents = UIColor.lightGray
            infoText.materials = [infoMaterial]
            
            let infoNode = SCNNode(geometry: infoText)
            infoNode.scale = SCNVector3(0.015, 0.015, 0.015)
            infoNode.position = SCNVector3(0, 1.5, 0)
            
            displayNode.addChildNode(backgroundNode)
            displayNode.addChildNode(textNode)
            displayNode.addChildNode(infoNode)
            
            return displayNode
        }
        
        private func createAREffects(for landmark: MontrealLandmark, isFirstDiscovery: Bool) -> SCNNode {
            let effectsNode = SCNNode()
            
            // Create floating particles around the landmark
            let particleSystem = createParticleSystem(for: landmark)
            let particleNode = SCNNode()
            particleNode.addParticleSystem(particleSystem)
            particleNode.position = SCNVector3(0, 1, 0)
            effectsNode.addChildNode(particleNode)
            
            // Create rotating ring effect
            let ringNode = createRotatingRing(for: landmark)
            effectsNode.addChildNode(ringNode)
            
            // Create beacon light effect
            let beaconNode = createBeaconLight(for: landmark)
            effectsNode.addChildNode(beaconNode)
            
            return effectsNode
        }
        
        private func createParticleSystem(for landmark: MontrealLandmark) -> SCNParticleSystem {
            let particleSystem = SCNParticleSystem()
            
            // Configure particles based on landmark type
            let landmarkColor = getLandmarkColor(for: landmark)
            
            particleSystem.birthRate = 20
            particleSystem.particleLifeSpan = 3.0
            particleSystem.particleSize = 0.05
            particleSystem.particleColor = landmarkColor
            
            // Set emission properties
            particleSystem.emissionDuration = 0
            particleSystem.emitterShape = SCNSphere(radius: 0.5)
            
            // Set particle behavior
            particleSystem.particleVelocity = 0.2
            particleSystem.particleVelocityVariation = 0.1
            particleSystem.spreadingAngle = 45
            
            // Add some sparkle
            particleSystem.particleImage = createSparkleImage()
            
            return particleSystem
        }
        
        private func createRotatingRing(for landmark: MontrealLandmark) -> SCNNode {
            let ringGeometry = SCNTorus(ringRadius: 1.0, pipeRadius: 0.02)
            let ringMaterial = SCNMaterial()
            ringMaterial.diffuse.contents = getLandmarkColor(for: landmark)
            ringMaterial.emission.contents = getLandmarkColor(for: landmark).withAlphaComponent(0.5)
            ringGeometry.materials = [ringMaterial]
            
            let ringNode = SCNNode(geometry: ringGeometry)
            ringNode.position = SCNVector3(0, 0.5, 0)
            
            // Add rotation animation
            let rotationAnimation = CABasicAnimation(keyPath: "rotation")
            rotationAnimation.fromValue = SCNVector4(0, 1, 0, 0)
            rotationAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
            rotationAnimation.duration = 4.0
            rotationAnimation.repeatCount = .infinity
            ringNode.addAnimation(rotationAnimation, forKey: "rotation")
            
            return ringNode
        }
        
        private func createBeaconLight(for landmark: MontrealLandmark) -> SCNNode {
            let lightNode = SCNNode()
            let light = SCNLight()
            light.type = .spot
            light.color = getLandmarkColor(for: landmark)
            light.intensity = 500
            light.spotInnerAngle = 30
            light.spotOuterAngle = 60
            lightNode.light = light
            lightNode.position = SCNVector3(0, 3, 0)
            lightNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
            
            // Add pulsing animation to light
            let pulseAnimation = CABasicAnimation(keyPath: "light.intensity")
            pulseAnimation.fromValue = 200
            pulseAnimation.toValue = 800
            pulseAnimation.duration = 1.5
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            lightNode.addAnimation(pulseAnimation, forKey: "lightPulse")
            
            return lightNode
        }
        
        private func createDiscoveryCelebration(for landmark: MontrealLandmark) -> SCNNode {
            let celebrationNode = SCNNode()
            
            // Create burst particle effect
            let burstParticles = SCNParticleSystem()
            burstParticles.birthRate = 100
            burstParticles.particleLifeSpan = 2.0
            burstParticles.particleSize = 0.1
            burstParticles.particleColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold color
            burstParticles.emissionDuration = 0.5
            burstParticles.particleVelocity = 2.0
            burstParticles.particleVelocityVariation = 1.0
            burstParticles.spreadingAngle = 180
            burstParticles.particleImage = createStarImage()
            
            let burstNode = SCNNode()
            burstNode.addParticleSystem(burstParticles)
            burstNode.position = SCNVector3(0, 2, 0)
            celebrationNode.addChildNode(burstNode)
            
            // Create "DISCOVERED!" text
            let discoveryText = SCNText(string: "DISCOVERED!", extrusionDepth: 0.1)
            discoveryText.font = UIFont.systemFont(ofSize: 1.5, weight: .black)
            discoveryText.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            
            let discoveryMaterial = SCNMaterial()
            discoveryMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold color
            discoveryMaterial.emission.contents = UIColor.orange
            discoveryText.materials = [discoveryMaterial]
            
            let discoveryTextNode = SCNNode(geometry: discoveryText)
            discoveryTextNode.scale = SCNVector3(0.03, 0.03, 0.03)
            discoveryTextNode.position = SCNVector3(0, 4, 0)
            
            // Add bounce animation
            let bounceAnimation = CAKeyframeAnimation(keyPath: "position.y")
            bounceAnimation.values = [4, 4.5, 4, 4.3, 4, 4.1, 4]
            bounceAnimation.duration = 1.5
            bounceAnimation.repeatCount = 2
            discoveryTextNode.addAnimation(bounceAnimation, forKey: "bounce")
            
            // Add fade out animation
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.fromValue = 1.0
            fadeAnimation.toValue = 0.0
            fadeAnimation.beginTime = CACurrentMediaTime() + 2.0
            fadeAnimation.duration = 1.0
            discoveryTextNode.addAnimation(fadeAnimation, forKey: "fadeOut")
            
            celebrationNode.addChildNode(discoveryTextNode)
            
            return celebrationNode
        }
        
        // Helper functions for visual effects
        private func getLandmarkColor(for landmark: MontrealLandmark) -> UIColor {
            switch landmark.name {
            case "Notre-Dame Basilica":
                return UIColor.blue
            case "Olympic Stadium & Tower":
                return UIColor.red
            case "Mount Royal Cross":
                return UIColor.purple
            case "Old Port Clock Tower":
                return UIColor.orange
            case "Saint Joseph's Oratory":
                return UIColor.green
            case "Collège de La Salle":
                return UIColor.cyan
            default:
                return UIColor.white
            }
        }
        
        private func createGradientImage() -> UIImage {
            let size = CGSize(width: 100, height: 100)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                let colors = [UIColor.black.withAlphaComponent(0.8).cgColor,
                             UIColor.blue.withAlphaComponent(0.3).cgColor]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors as CFArray,
                                        locations: nil)!
                context.cgContext.drawLinearGradient(gradient,
                                                   start: CGPoint(x: 0, y: 0),
                                                   end: CGPoint(x: size.width, y: size.height),
                                                   options: [])
            }
        }
        
        private func createSparkleImage() -> UIImage {
            let size = CGSize(width: 20, height: 20)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            }
        }
        
        private func createStarImage() -> UIImage {
            let size = CGSize(width: 20, height: 20)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                let path = UIBezierPath()
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let radius: CGFloat = 8
                
                for i in 0..<10 {
                    let angle = CGFloat(i) * .pi / 5
                    let r = (i % 2 == 0) ? radius : radius * 0.5
                    let x = center.x + r * cos(angle - .pi/2)
                    let y = center.y + r * sin(angle - .pi/2)
                    
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.close()
                
                context.cgContext.setFillColor(UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor) // Gold color
                context.cgContext.addPath(path.cgPath)
                context.cgContext.fillPath()
            }
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

