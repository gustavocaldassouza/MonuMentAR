import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct ARCameraView: UIViewRepresentable {
    @ObservedObject var recognitionService: MonumentRecognitionService
    @Binding var isSessionRunning: Bool
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        isSessionRunning = true
        
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
        private var lastAnalysisTime: Date = Date()
        private let analysisInterval: TimeInterval = 1.0 // Analyze every second
        
        init(_ parent: ARCameraView) {
            self.parent = parent
        }
        
        // MARK: - ARSCNViewDelegate
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // Handle new anchors if needed
        }
        
        func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
            // Capture frame for analysis
            guard let arView = renderer as? ARSCNView else { return }
            
            let currentTime = Date()
            if currentTime.timeIntervalSince(lastAnalysisTime) >= analysisInterval {
                lastAnalysisTime = currentTime
                captureFrameForAnalysis(arView: arView)
            }
        }
        
        private func captureFrameForAnalysis(arView: ARSCNView) {
            guard let pixelBuffer = arView.session.currentFrame?.capturedImage else { return }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            
            let uiImage = UIImage(cgImage: cgImage)
            
            // Analyze the captured frame
            Task { @MainActor in
                parent.recognitionService.analyzeImage(uiImage)
            }
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
    }
}

// MARK: - AR Camera View with Overlay

struct ARCameraViewWithOverlay: View {
    @StateObject private var recognitionService = MonumentRecognitionService()
    @State private var isSessionRunning = false
    @State private var showLandmarkInfo = false
    @State private var selectedLandmark: MontrealLandmark?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // AR Camera View
            ARCameraView(recognitionService: recognitionService, isSessionRunning: $isSessionRunning)
                .ignoresSafeArea()
            
            // Overlay for detected landmarks
            if !recognitionService.detectedLandmarks.isEmpty {
                ForEach(recognitionService.detectedLandmarks) { detectedLandmark in
                    LandmarkOverlayView(detectedLandmark: detectedLandmark) {
                        selectedLandmark = detectedLandmark.landmark
                        showLandmarkInfo = true
                    }
                }
            }
            
            // Analysis indicator
            if recognitionService.isAnalyzing {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Analyzing...")
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
                    
                    // Detection count
                    VStack {
                        Text("Detected")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("\(recognitionService.detectedLandmarks.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
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
            // For demonstration, simulate some detections
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                recognitionService.simulateDetection()
            }
        }
    }
}

// MARK: - Landmark Overlay View

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

