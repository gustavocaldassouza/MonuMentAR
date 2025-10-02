# Core ML Model Integration Guide

## 1. Add Model to Xcode Project
1. Drag `MontrealMonuments.mlmodel` into your Xcode project
2. Make sure "Add to target" is checked for your app target
3. Xcode will automatically generate the model class

## 2. Update MonumentRecognitionService.swift

The MonumentRecognitionService has already been updated to load the model automatically.
When you add the MontrealMonuments.mlmodel file to your Xcode project, it will be loaded automatically.

## 3. Update Model Identifiers

Make sure your MontrealLandmark model identifiers match the Core ML model output:
- "notre_dame_basilica"
- "olympic_stadium_tower" 
- "mount_royal_cross"
- "old_port_clock_tower"
- "saint_josephs_oratory"
- "background" (for non-monument images)

## 4. Test the Integration

The model should now work with your existing AR camera setup. The `analyzeImage` method will use the trained model instead of mock detection.

## 5. Performance Optimization

Consider these optimizations:
- Reduce image size before processing (224x224 is optimal)
- Implement confidence thresholding (currently set to 0.75)
- Add temporal smoothing to reduce flickering detections (already implemented)
- Cache model predictions for similar frames
