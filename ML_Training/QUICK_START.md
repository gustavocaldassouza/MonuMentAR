# Quick Start Guide - Montreal Monument Detection

## 🚀 Getting Started

### 1. Environment Setup ✅
You've successfully set up the training environment!

### 2. Collect Training Data 📸
Choose one of these approaches:

#### Option A: Manual Collection (Recommended)
```bash
# Read the collection guide
open training_data/MANUAL_COLLECTION_GUIDE.md

# Collect 100+ images per landmark in the training directories
# Collect 20+ images per landmark in the validation directories
```

#### Option B: Automated Collection (Requires API Keys)
```bash
# Set up Flickr API credentials in collect_from_flickr.py
python collect_from_flickr.py
```

### 3. Train the Model 🧠
```bash
# Once you have training data:
python train_monument_model.py

# This will create: models/MontrealMonuments.mlmodel
```

### 4. Integrate with iOS App 📱
```bash
# Follow the integration guide:
open models/INTEGRATION_GUIDE.md

# Key steps:
# 1. Drag MontrealMonuments.mlmodel into Xcode project
# 2. Ensure it's added to your app target
# 3. The updated MonumentRecognitionService will automatically use it
```

## 📊 Monitoring Progress

### Check Data Collection Status
```bash
python collect_training_data.py  # Shows current dataset status
```

### Validate Your Dataset
```bash
python -c "
from train_monument_model import MontrealMonumentModelTrainer
trainer = MontrealMonumentModelTrainer()
trainer.validate_dataset()
"
```

## 🎯 Success Metrics

### Minimum Requirements:
- ✅ 100+ training images per landmark (5 landmarks = 500+ images)
- ✅ 20+ validation images per landmark (5 landmarks = 100+ images)  
- ✅ 200+ background images for training
- ✅ 40+ background images for validation

### Recommended:
- 🎖️ 200+ training images per landmark for better accuracy
- 🎖️ Diverse angles, lighting, and conditions
- 🎖️ High-quality, clear images (minimum 224x224 pixels)

## 🔧 Troubleshooting

### Common Issues:
1. **Import errors**: Run `pip install -r requirements.txt`
2. **No training data**: Follow MANUAL_COLLECTION_GUIDE.md
3. **Model not loading in iOS**: Check Xcode project target membership
4. **Low accuracy**: Collect more diverse training data

### Getting Help:
- Check the detailed guides in each directory
- Review console output for specific error messages
- Ensure all file paths and permissions are correct

## 📁 Project Structure
```
ML_Training/
├── train_monument_model.py      # Main training script
├── collect_training_data.py     # Data collection utilities
├── requirements.txt             # Python dependencies
├── setup.py                     # This setup script
├── training_data/              # Your training images go here
│   ├── train/                  # Training set
│   └── validation/             # Validation set
└── models/                     # Generated models
    └── MontrealMonuments.mlmodel  # Final Core ML model
```

Happy training! 🏛️✨
