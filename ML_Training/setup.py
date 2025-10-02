#!/usr/bin/env python3
"""
Setup script for Montreal Monument Detection Model Training

This script sets up the complete environment for training a Core ML model
to detect Montreal landmarks.
"""

import os
import sys
import subprocess
from pathlib import Path

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 or higher is required")
        print(f"Current version: {sys.version}")
        return False
    print(f"✅ Python version: {sys.version}")
    return True

def install_requirements():
    """Install required Python packages"""
    print("📦 Installing required packages...")
    
    requirements_file = Path(__file__).parent / "requirements.txt"
    if not requirements_file.exists():
        print("❌ requirements.txt not found")
        return False
    
    try:
        subprocess.check_call([
            sys.executable, "-m", "pip", "install", "-r", str(requirements_file)
        ])
        print("✅ All packages installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error installing packages: {e}")
        return False

def setup_directories():
    """Create necessary directories"""
    print("📁 Setting up directory structure...")
    
    base_dir = Path(__file__).parent
    directories = [
        "training_data/train/notre_dame_basilica",
        "training_data/train/olympic_stadium_tower",
        "training_data/train/mount_royal_cross",
        "training_data/train/old_port_clock_tower",
        "training_data/train/saint_josephs_oratory",
        "training_data/train/background",
        "training_data/validation/notre_dame_basilica",
        "training_data/validation/olympic_stadium_tower",
        "training_data/validation/mount_royal_cross",
        "training_data/validation/old_port_clock_tower",
        "training_data/validation/saint_josephs_oratory",
        "training_data/validation/background",
        "models"
    ]
    
    for directory in directories:
        dir_path = base_dir / directory
        dir_path.mkdir(parents=True, exist_ok=True)
    
    print("✅ Directory structure created")
    return True

def check_system_requirements():
    """Check system requirements for Core ML training"""
    print("🔍 Checking system requirements...")
    
    # Check if running on macOS (recommended for Core ML)
    if sys.platform == "darwin":
        print("✅ Running on macOS - optimal for Core ML development")
    else:
        print("⚠️ Not running on macOS - Core ML models can still be created but testing will be limited")
    
    # Check available disk space (rough estimate)
    try:
        import shutil
        total, used, free = shutil.disk_usage(Path.home())
        free_gb = free // (1024**3)
        if free_gb < 5:
            print(f"⚠️ Low disk space: {free_gb}GB free (recommend 5GB+ for training data)")
        else:
            print(f"✅ Sufficient disk space: {free_gb}GB free")
    except:
        print("⚠️ Could not check disk space")
    
    return True

def create_quick_start_guide():
    """Create a quick start guide"""
    guide_content = """# Quick Start Guide - Montreal Monument Detection

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
"""
    
    guide_path = Path(__file__).parent / "QUICK_START.md"
    with open(guide_path, 'w') as f:
        f.write(guide_content)
    
    print(f"📖 Quick start guide created: {guide_path}")

def main():
    """Main setup function"""
    print("🏛️ Montreal Monument Detection - Setup")
    print("=" * 50)
    
    success = True
    
    # Check Python version
    if not check_python_version():
        success = False
    
    # Check system requirements
    if not check_system_requirements():
        success = False
    
    # Install requirements
    if success and not install_requirements():
        success = False
    
    # Setup directories
    if success and not setup_directories():
        success = False
    
    # Create guides
    if success:
        create_quick_start_guide()
    
    print("\n" + "=" * 50)
    if success:
        print("🎉 Setup completed successfully!")
        print("\nNext steps:")
        print("1. 📖 Read: QUICK_START.md")
        print("2. 📸 Collect training data")
        print("3. 🧠 Run: python train_monument_model.py")
        print("4. 📱 Integrate with your iOS app")
    else:
        print("❌ Setup encountered errors")
        print("Please resolve the issues above and run setup again")
    
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

