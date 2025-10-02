import Foundation
import CoreMotion
import Combine

@MainActor
class MotionService: ObservableObject {
    @Published var deviceHeading: Double = 0.0 // Magnetic heading in degrees (0-360)
    @Published var devicePitch: Double = 0.0   // Pitch in degrees (-90 to 90)
    @Published var deviceRoll: Double = 0.0    // Roll in degrees (-180 to 180)
    @Published var isMotionAvailable: Bool = false
    @Published var motionError: Error?
    
    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 0.1 // 10 Hz updates
    
    // Smoothing for stable readings
    private var headingHistory: [Double] = []
    private var pitchHistory: [Double] = []
    private var rollHistory: [Double] = []
    private let smoothingWindowSize = 5
    
    init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        guard motionManager.isDeviceMotionAvailable else {
            motionError = MotionError.deviceMotionUnavailable
            isMotionAvailable = false
            return
        }
        
        isMotionAvailable = true
    }
    
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            motionError = MotionError.deviceMotionUnavailable
            return
        }
        
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, error in
            Task { @MainActor in
                self?.handleMotionUpdate(motion: motion, error: error)
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func handleMotionUpdate(motion: CMDeviceMotion?, error: Error?) {
        guard let motion = motion else {
            if let error = error {
                motionError = error
            }
            return
        }
        
        motionError = nil
        
        // Get raw values
        let rawHeading = motion.heading * 180 / .pi
        let rawPitch = motion.attitude.pitch * 180 / .pi
        let rawRoll = motion.attitude.roll * 180 / .pi
        
        // Apply smoothing
        let smoothedHeading = applySmoothingToHeading(rawHeading)
        let smoothedPitch = applySmoothing(to: rawPitch, history: &pitchHistory)
        let smoothedRoll = applySmoothing(to: rawRoll, history: &rollHistory)
        
        // Update published values
        deviceHeading = smoothedHeading
        devicePitch = smoothedPitch
        deviceRoll = smoothedRoll
    }
    
    // Special smoothing for heading to handle 0/360 degree wraparound
    private func applySmoothingToHeading(_ newHeading: Double) -> Double {
        let normalizedHeading = (newHeading + 360).truncatingRemainder(dividingBy: 360)
        
        headingHistory.append(normalizedHeading)
        if headingHistory.count > smoothingWindowSize {
            headingHistory.removeFirst()
        }
        
        // Handle circular averaging for angles
        var sinSum: Double = 0
        var cosSum: Double = 0
        
        for heading in headingHistory {
            let radians = heading * .pi / 180
            sinSum += sin(radians)
            cosSum += cos(radians)
        }
        
        let avgRadians = atan2(sinSum / Double(headingHistory.count), cosSum / Double(headingHistory.count))
        let avgHeading = (avgRadians * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        
        return avgHeading
    }
    
    // Regular smoothing for pitch and roll
    private func applySmoothing(to newValue: Double, history: inout [Double]) -> Double {
        history.append(newValue)
        if history.count > smoothingWindowSize {
            history.removeFirst()
        }
        
        return history.reduce(0, +) / Double(history.count)
    }
    
    // Get the camera's viewing direction as a 3D vector
    func getCameraDirection() -> (x: Double, y: Double, z: Double) {
        let headingRad = deviceHeading * .pi / 180
        let pitchRad = devicePitch * .pi / 180
        
        // Calculate 3D direction vector
        let x = cos(pitchRad) * sin(headingRad)
        let y = sin(pitchRad)
        let z = cos(pitchRad) * cos(headingRad)
        
        return (x: x, y: y, z: z)
    }
    
    // Calculate angular difference between two headings
    func angularDifference(heading1: Double, heading2: Double) -> Double {
        let diff = abs(heading1 - heading2)
        return min(diff, 360 - diff)
    }
    
    // Check if the device is pointing towards a specific bearing within tolerance
    func isPointingTowards(bearing: Double, tolerance: Double = 5.0) -> Bool {
        return angularDifference(heading1: deviceHeading, heading2: bearing) <= tolerance
    }
    
    // Check if the device pitch matches expected elevation angle within tolerance
    func isPitchMatching(elevationAngle: Double, tolerance: Double = 5.0) -> Bool {
        return abs(devicePitch - elevationAngle) <= tolerance
    }
}

// MARK: - Motion Errors

enum MotionError: LocalizedError {
    case deviceMotionUnavailable
    case motionDataUnavailable
    
    var errorDescription: String? {
        switch self {
        case .deviceMotionUnavailable:
            return "Device motion sensors are not available on this device."
        case .motionDataUnavailable:
            return "Motion data is currently unavailable."
        }
    }
}

