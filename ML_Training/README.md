# Montreal Monument Detection - Core ML Training

This directory contains everything needed to train a custom Core ML model for detecting Montreal landmarks in your AR app.

## 🎯 Overview

The training pipeline creates a Core ML model that can recognize these Montreal landmarks:

- **Notre-Dame Basilica** (`notre_dame_basilica`)
- **Olympic Stadium & Tower** (`olympic_stadium_tower`)
- **Mount Royal Cross** (`mount_royal_cross`)
- **Old Port Clock Tower** (`old_port_clock_tower`)
- **Saint Joseph's Oratory** (`saint_josephs_oratory`)

## 🚀 Quick Start

### 1. Run Setup

```bash
cd ML_Training
python setup.py
```

This will:

- ✅ Check system requirements
- ✅ Install Python dependencies
- ✅ Create directory structure
- ✅ Generate guides and documentation

### 2. Collect Training Data

Follow one of these approaches:

#### Option A: Manual Collection (Recommended)

```bash
# Read the detailed guide
open training_data/MANUAL_COLLECTION_GUIDE.md

# Collect images and organize them in:
# training_data/train/[landmark_name]/
# training_data/validation/[landmark_name]/
```

#### Option B: Automated Collection

```bash
# Configure Flickr API in collect_from_flickr.py
python collect_from_flickr.py
```

### 3. Train the Model

```bash
# Once you have sufficient training data:
python train_monument_model.py

# Output: models/MontrealMonuments.mlmodel
```

### 4. Integrate with iOS App

```bash
# Follow the integration guide:
open models/INTEGRATION_GUIDE.md

# Key steps:
# 1. Drag MontrealMonuments.mlmodel into Xcode
# 2. Add to app target
# 3. Your MonumentRecognitionService is already updated!
```

## 📁 File Structure

```
ML_Training/
├── README.md                    # This file
├── setup.py                     # Environment setup script
├── requirements.txt             # Python dependencies
├── train_monument_model.py      # Main training script
├── collect_training_data.py     # Data collection utilities
├── training_data/              # Training images directory
│   ├── train/                  # Training set (80% of data)
│   │   ├── notre_dame_basilica/
│   │   ├── olympic_stadium_tower/
│   │   ├── mount_royal_cross/
│   │   ├── old_port_clock_tower/
│   │   ├── saint_josephs_oratory/
│   │   └── background/          # Non-monument images
│   └── validation/             # Validation set (20% of data)
│       ├── notre_dame_basilica/
│       ├── olympic_stadium_tower/
│       ├── mount_royal_cross/
│       ├── old_port_clock_tower/
│       ├── saint_josephs_oratory/
│       └── background/
└── models/                     # Generated models
    ├── MontrealMonuments.mlmodel  # Final Core ML model
    └── INTEGRATION_GUIDE.md       # iOS integration instructions
```

## 🎯 Training Requirements

### Minimum Dataset Size

- **100+ images per landmark** for training (500+ total)
- **20+ images per landmark** for validation (100+ total)
- **200+ background images** for training
- **40+ background images** for validation

### Image Quality Guidelines

- **Resolution**: Minimum 224x224 pixels
- **Format**: JPG or PNG
- **Quality**: Clear, well-lit, sharp images
- **Variety**: Different angles, lighting, seasons, weather

### Diversity Requirements

- 📸 Multiple viewing angles (close-up, wide, aerial)
- 🌅 Various lighting conditions (day, night, golden hour)
- 🌦️ Different weather conditions (clear, cloudy, rainy)
- 👥 With and without people/crowds
- 📅 Different seasons if possible

## 🔧 Technical Details

### Model Architecture

- **Base Model**: ResNet50 (pre-trained on ImageNet)
- **Transfer Learning**: Fine-tuned on Montreal landmarks
- **Input Size**: 224x224x3 RGB images
- **Output**: 6 classes (5 landmarks + background)
- **Framework**: TensorFlow/Keras → Core ML conversion

### Training Configuration

- **Optimizer**: Adam with learning rate scheduling
- **Augmentation**: Rotation, shifts, zoom, flip
- **Validation Split**: 20% of data
- **Early Stopping**: Prevents overfitting
- **Batch Size**: 32 (adjustable based on memory)

### Performance Optimization

- **Temporal Smoothing**: Reduces detection flickering
- **Confidence Thresholding**: Filters low-confidence predictions
- **Model Quantization**: Optimized for mobile deployment

## 📊 Monitoring Training

### Check Dataset Status

```bash
python collect_training_data.py
```

### Validate Training Progress

```bash
# Monitor training logs for:
# - Training/validation accuracy
# - Loss reduction over epochs
# - Early stopping triggers
```

### Test Model Performance

```bash
# After training, test in iOS simulator or device
# Monitor console logs for detection confidence scores
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Import Errors

```bash
# Solution: Install requirements
pip install -r requirements.txt
```

#### 2. Insufficient Training Data

```bash
# Solution: Collect more images
python collect_training_data.py  # Check current status
# Follow MANUAL_COLLECTION_GUIDE.md
```

#### 3. Model Not Loading in iOS

```bash
# Solutions:
# 1. Check Xcode project target membership
# 2. Verify model file is in app bundle
# 3. Check iOS version compatibility
```

#### 4. Low Detection Accuracy

```bash
# Solutions:
# 1. Collect more diverse training data
# 2. Increase training epochs
# 3. Adjust confidence threshold in iOS app
# 4. Add more data augmentation
```

#### 5. Memory Issues During Training

```bash
# Solutions:
# 1. Reduce batch size in train_monument_model.py
# 2. Resize images to smaller dimensions
# 3. Use gradient checkpointing
```

## 🎓 Advanced Usage

### Custom Model Architecture

Edit `train_monument_model.py` to:

- Change base model (ResNet50 → MobileNet, EfficientNet)
- Adjust layer sizes and dropout rates
- Modify data augmentation parameters

### Additional Landmarks

To add new landmarks:

1. Update `landmarks` list in training scripts
2. Add corresponding directories
3. Update iOS `MontrealLandmark.swift` model
4. Collect training data for new landmarks

### Model Optimization

- **Quantization**: Reduce model size for faster inference
- **Pruning**: Remove unnecessary model weights
- **Knowledge Distillation**: Create smaller student models

## 📚 Resources

### Documentation

- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Vision Framework Guide](https://developer.apple.com/documentation/vision)
- [TensorFlow Core ML Tools](https://github.com/apple/coremltools)

### Datasets

- [Flickr API](https://www.flickr.com/services/api/) - Creative Commons images
- [Wikimedia Commons](https://commons.wikimedia.org/) - Free-use images
- [Montreal Tourism](https://www.mtl.org/) - Official tourism photos

### Training Resources

- [Transfer Learning Guide](https://www.tensorflow.org/tutorials/images/transfer_learning)
- [Data Augmentation Best Practices](https://www.tensorflow.org/tutorials/images/data_augmentation)
- [Core ML Model Optimization](https://developer.apple.com/videos/play/wwdc2019/704/)

## 🤝 Contributing

To improve the model:

1. Collect higher quality training data
2. Experiment with different architectures
3. Add data augmentation techniques
4. Optimize for mobile performance
5. Test on various iOS devices

## 📄 License

This training code is provided under the same license as the main MonuMentAR project.

---

**Happy Training!** 🏛️✨

For questions or issues, check the troubleshooting section above or review the detailed guides in each directory.

