# Core ML Model Setup Guide for MonuMentAR

## 🎯 Overview

I've successfully created a complete Core ML training infrastructure for your Montreal monument detection app. Your `MonumentRecognitionService` has been updated to automatically load and use a Core ML model when available.

## 📁 What's Been Created

### 1. ML Training Infrastructure (`ML_Training/`)

- **`train_monument_model.py`** - Complete training pipeline with transfer learning
- **`collect_training_data.py`** - Data collection utilities and validation
- **`setup.py`** - Environment setup script
- **`requirements.txt`** - Python dependencies
- **Directory structure** for training data organization
- **Comprehensive documentation** and guides

### 2. Updated iOS Integration

- **`MonumentRecognitionService.swift`** - Enhanced with:
  - Automatic Core ML model loading
  - Temporal smoothing for stable detections
  - Better error handling and logging
  - Model status tracking
  - Improved confidence thresholding (0.75)

## 🚀 Quick Start Options

### Option A: Create Model with Create ML (Recommended)

Since there are version compatibility issues with the current Core ML tools, the easiest approach is to use Xcode's Create ML:

1. **Open Xcode** and create a new playground
2. **Import CreateML**:

   ```swift
   import CreateML
   import Foundation
   ```

3. **Create the classifier**:

   ```swift
   // Create training data directory structure first
   let trainingData = try MLImageClassifier.DataSource.labeledDirectories(at: trainingDataURL)
   
   // Create the classifier
   let classifier = try MLImageClassifier(trainingData: trainingData)
   
   // Save the model
   try classifier.write(to: URL(fileURLWithPath: "MontrealMonuments.mlmodel"))
   ```

4. **Training data structure**:

   ```
   TrainingData/
   ├── notre_dame_basilica/     # 50+ images
   ├── olympic_stadium_tower/   # 50+ images  
   ├── mount_royal_cross/       # 50+ images
   ├── old_port_clock_tower/    # 50+ images
   ├── saint_josephs_oratory/   # 50+ images
   └── background/              # 100+ images
   ```

### Option B: Use Python Training Pipeline

1. **Collect training data** following `ML_Training/README_DATA_COLLECTION.md`
2. **Run the training script**:

   ```bash
   cd ML_Training
   python3 train_monument_model.py
   ```

3. **The script will generate** `MontrealMonuments.mlmodel`

### Option C: Use a Pre-trained Model (Quick Test)

For immediate testing, you can use any image classification Core ML model:

1. Download a model from [Apple's Core ML Gallery](https://developer.apple.com/machine-learning/models/)
2. Rename it to `MontrealMonuments.mlmodel`
3. Add to your Xcode project

## 📱 iOS Integration Steps

### 1. Add Model to Xcode Project

1. Drag `MontrealMonuments.mlmodel` into your Xcode project
2. Ensure "Add to target" is checked for your app target
3. Xcode will automatically generate the model class

### 2. Verify Model Integration

Your `MonumentRecognitionService` is already configured to:

- ✅ Automatically detect and load the model
- ✅ Provide helpful console messages if model is missing
- ✅ Fall back to mock detection for testing
- ✅ Apply temporal smoothing for stable detections

### 3. Test the Integration

1. **Build and run** your app
2. **Check console logs** for model loading status:
   - `✅ Successfully loaded MontrealMonuments.mlmodel` = Success
   - `⚠️ MontrealMonuments.mlmodel not found` = Add model to project
3. **Point camera at landmarks** to test detection

## 🎯 Model Requirements

### Class Labels (must match exactly)

- `"notre_dame_basilica"`
- `"olympic_stadium_tower"`
- `"mount_royal_cross"`
- `"old_port_clock_tower"`
- `"saint_josephs_oratory"`
- `"background"` (optional, for non-monument images)

### Input Requirements

- **Image size**: 224x224 pixels (recommended)
- **Format**: RGB color images
- **Preprocessing**: Automatic in your app

## 🔧 Current App Features

Your `MonumentRecognitionService` now includes:

### Enhanced Detection

- **Temporal smoothing** - Reduces flickering detections
- **Confidence thresholding** - Filters low-confidence predictions (75%)
- **Background filtering** - Ignores non-landmark detections
- **Real-time processing** - Analyzes camera frames every second

### Better UX

- **Model status tracking** - Shows loading/error states
- **Detailed logging** - Helpful console messages
- **Graceful fallbacks** - Mock detection when model unavailable
- **Performance optimization** - Efficient frame processing

## 📊 Testing Your Model

### Console Output Examples

```
✅ Successfully loaded MontrealMonuments.mlmodel
✅ Vision requests configured successfully
🏛️ Detected: Notre-Dame Basilica (87%)
```

### Performance Monitoring

- Watch for detection confidence scores
- Monitor frame processing speed
- Check for memory usage

## 🎨 Next Steps

### Immediate

1. **Create a basic model** using one of the options above
2. **Test integration** in your app
3. **Verify detection pipeline** works

### Long-term

1. **Collect training data** (100+ images per landmark)
2. **Train custom model** with your data
3. **Optimize performance** based on real usage
4. **Add more landmarks** as needed

## 🆘 Troubleshooting

### Model Not Loading

- Check file is in Xcode project bundle
- Verify target membership
- Check file name is exactly `MontrealMonuments.mlmodel`

### No Detections

- Check model class labels match your landmark identifiers
- Verify confidence threshold (currently 0.75)
- Test with clear, well-lit images of landmarks

### Performance Issues

- Reduce image processing frequency
- Lower confidence threshold
- Optimize model size

## 🏛️ Landmark Identifiers Reference

Your Swift model (`MontrealLandmark.swift`) uses these identifiers:

- Notre-Dame Basilica → `"notre_dame_basilica"`
- Olympic Stadium & Tower → `"olympic_stadium_tower"`
- Mount Royal Cross → `"mount_royal_cross"`
- Old Port Clock Tower → `"old_port_clock_tower"`
- Saint Joseph's Oratory → `"saint_josephs_oratory"`

Make sure your Core ML model outputs match these exactly!

---

## 🎉 Summary

You now have:

- ✅ Complete ML training infrastructure
- ✅ Enhanced iOS integration with Core ML support
- ✅ Temporal smoothing and performance optimizations
- ✅ Comprehensive documentation and guides
- ✅ Multiple paths to create your model

Your app is ready to use a Core ML model as soon as you add the `MontrealMonuments.mlmodel` file to your Xcode project!
