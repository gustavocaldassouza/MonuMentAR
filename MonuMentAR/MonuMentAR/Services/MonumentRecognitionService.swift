import Foundation
import CoreML
import Vision
import UIKit
import AVFoundation
import Combine

@MainActor
class MonumentRecognitionService: ObservableObject {
    @Published var detectedLandmarks: [DetectedLandmark] = []
    @Published var isAnalyzing = false
    @Published var modelStatus: ModelStatus = .notLoaded
    
    private let confidenceThreshold: Float = 0.75  // Lowered for better detection
    private var visionRequests: [VNRequest] = []
    private var coreMLModel: VNCoreMLModel?
    
    // Temporal smoothing for stable detections
    private var recentDetections: [String: [Float]] = [:]
    private let smoothingWindowSize = 3
    
    enum ModelStatus {
        case notLoaded
        case loading
        case loaded
        case error(String)
    }
    
    init() {
        setupVisionRequests()
    }
    
    private func setupVisionRequests() {
        modelStatus = .loading
        
        guard let model = createGenericModel() else {
            modelStatus = .error("Model file not found")
            print("❌ No Core ML model available - using mock detection")
            return
        }
        
        do {
            let coreMLModel = try VNCoreMLModel(for: model)
            self.coreMLModel = coreMLModel
            
            let classificationRequest = VNCoreMLRequest(model: coreMLModel) { [weak self] request, error in
                Task { @MainActor in
                    self?.handleClassificationResults(request: request, error: error)
                }
            }
            
            classificationRequest.imageCropAndScaleOption = .centerCrop
            visionRequests = [classificationRequest]
            modelStatus = .loaded
            
            print("✅ Vision requests configured successfully")
            
        } catch {
            modelStatus = .error("Failed to create VNCoreMLModel: \(error.localizedDescription)")
            print("❌ Error creating VNCoreMLModel: \(error)")
        }
    }
    
    // Load the trained Core ML model for Montreal monuments
    private func createGenericModel() -> MLModel? {
        // Try to load the custom Montreal monuments model
        guard let modelURL = Bundle.main.url(forResource: "MontrealMonuments", withExtension: "mlmodel") else {
            print("⚠️ MontrealMonuments.mlmodel not found in bundle")
            print("📝 To add the model:")
            print("   1. Train the model using ML_Training/train_monument_model.py")
            print("   2. Drag MontrealMonuments.mlmodel into your Xcode project")
            print("   3. Ensure it's added to your app target")
            return nil
        }
        
        do {
            let model = try MLModel(contentsOf: modelURL)
            print("✅ Successfully loaded MontrealMonuments.mlmodel")
            return model
        } catch {
            print("❌ Error loading Core ML model: \(error.localizedDescription)")
            print("💡 Make sure the model file is valid and compatible with this iOS version")
            return nil
        }
    }
    
    func analyzeImage(_ image: UIImage) {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        
        // If no Core ML model is available, use mock detection
        guard !visionRequests.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isAnalyzing = false
                self.simulateDetection()
            }
            return
        }
        
        guard let cgImage = image.cgImage else {
            isAnalyzing = false
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try imageRequestHandler.perform(visionRequests)
        } catch {
            print("Error performing vision request: \(error)")
            isAnalyzing = false
        }
    }
    
    private func handleClassificationResults(request: VNRequest, error: Error?) {
        isAnalyzing = false
        
        guard error == nil,
              let observations = request.results as? [VNClassificationObservation] else {
            print("❌ Error in classification: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        // Convert to detected landmarks with temporal smoothing, excluding background class
        let newDetections = observations.compactMap { observation -> DetectedLandmark? in
            // Skip background class
            guard observation.identifier != "background",
                  let landmark = findLandmarkByIdentifier(observation.identifier) else { 
                return nil 
            }
            
            // Apply temporal smoothing to this observation's confidence
            let smoothedConfidence = applyTemporalSmoothing(for: observation.identifier, confidence: observation.confidence)
            
            // Filter by confidence threshold after smoothing
            guard smoothedConfidence >= confidenceThreshold else {
                return nil
            }
            
            return DetectedLandmark(
                landmark: landmark,
                confidence: smoothedConfidence,
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8) // Placeholder bounding box
            )
        }
        
        // Update detected landmarks
        detectedLandmarks = newDetections
        
        // Log detection for debugging
        if !newDetections.isEmpty {
            let detectionNames = newDetections.map { "\($0.landmark.name) (\(Int($0.confidence * 100))%)" }
            print("🏛️ Detected: \(detectionNames.joined(separator: ", "))")
        }
    }
    
    private func applyTemporalSmoothing(for identifier: String, confidence: Float) -> Float {
        // Add current confidence to recent detections
        if recentDetections[identifier] == nil {
            recentDetections[identifier] = []
        }
        recentDetections[identifier]?.append(confidence)
        
        // Keep only recent detections within window
        if let detections = recentDetections[identifier], detections.count > smoothingWindowSize {
            recentDetections[identifier] = Array(detections.suffix(smoothingWindowSize))
        }
        
        // Calculate smoothed confidence
        if let detections = recentDetections[identifier], !detections.isEmpty {
            return detections.reduce(0, +) / Float(detections.count)
        }
        
        return confidence
    }
    
    private func findLandmarkByIdentifier(_ identifier: String) -> MontrealLandmark? {
        return MontrealLandmark.landmarks.first { $0.modelIdentifier == identifier }
    }
    
    // Mock detection for demonstration purposes
    func simulateDetection() {
        // This is for testing - in real implementation, this would be called by camera analysis
        let randomLandmark = MontrealLandmark.landmarks.randomElement()!
        let mockConfidence = Float.random(in: 0.85...0.98)
        
        let detectedLandmark = DetectedLandmark(
            landmark: randomLandmark,
            confidence: mockConfidence,
            boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        )
        
        detectedLandmarks = [detectedLandmark]
    }
}

struct DetectedLandmark: Identifiable {
    let id = UUID()
    let landmark: MontrealLandmark
    let confidence: Float
    let boundingBox: CGRect
    let timestamp = Date()
}
