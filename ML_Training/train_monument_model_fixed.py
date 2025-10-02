#!/usr/bin/env python3
"""
Montreal Monument Detection Model Training Script

This script creates a Core ML model for detecting Montreal landmarks using transfer learning.
It uses a pre-trained ResNet50 model and fine-tunes it on Montreal monument images.
"""

import os
import sys
import json
from pathlib import Path
import numpy as np
from PIL import Image
import requests
from io import BytesIO

# Core ML and machine learning imports
try:
    import coremltools as ct
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers, applications
    from tensorflow.keras.preprocessing.image import ImageDataGenerator
    print("✅ All required packages imported successfully")
except ImportError as e:
    print(f"❌ Missing required package: {e}")
    print("Please install required packages:")
    print("pip install coremltools tensorflow pillow requests")
    sys.exit(1)

class MontrealMonumentModelTrainer:
    def __init__(self, data_dir="training_data", model_output_dir="models"):
        self.data_dir = Path(data_dir)
        self.model_output_dir = Path(model_output_dir)
        self.img_size = (224, 224)
        self.batch_size = 32
        self.epochs = 50
        
        # Montreal landmarks from your Swift code
        self.landmarks = [
            "notre_dame_basilica",
            "olympic_stadium_tower", 
            "mount_royal_cross",
            "old_port_clock_tower",
            "saint_josephs_oratory"
        ]
        
        # Create directories
        self.data_dir.mkdir(exist_ok=True)
        self.model_output_dir.mkdir(exist_ok=True)
        
        print(f"📁 Data directory: {self.data_dir}")
        print(f"📁 Model output directory: {self.model_output_dir}")

    def setup_data_structure(self):
        """Create the directory structure for training data"""
        print("🏗️  Setting up data directory structure...")
        
        # Create train/validation splits for each landmark
        for split in ['train', 'validation']:
            split_dir = self.data_dir / split
            split_dir.mkdir(exist_ok=True)
            
            for landmark in self.landmarks:
                landmark_dir = split_dir / landmark
                landmark_dir.mkdir(exist_ok=True)
                print(f"   Created: {landmark_dir}")
        
        # Create a "background" class for non-monument images
        for split in ['train', 'validation']:
            bg_dir = self.data_dir / split / 'background'
            bg_dir.mkdir(exist_ok=True)
            print(f"   Created: {bg_dir}")

    def download_sample_images(self):
        """Download sample images for demonstration (you'll need to replace with real data)"""
        print("🖼️  Setting up sample data structure...")
        print("⚠️  Note: You'll need to add real images of Montreal landmarks to train the model")
        
        # Create placeholder files to show the expected structure
        sample_structure = """
        training_data/
        ├── train/
        │   ├── notre_dame_basilica/          # 100+ images of Notre-Dame Basilica
        │   ├── olympic_stadium_tower/        # 100+ images of Olympic Stadium
        │   ├── mount_royal_cross/           # 100+ images of Mount Royal Cross
        │   ├── old_port_clock_tower/        # 100+ images of Clock Tower
        │   ├── saint_josephs_oratory/       # 100+ images of Saint Joseph's Oratory
        │   └── background/                  # 200+ images of other Montreal scenes
        └── validation/
            ├── notre_dame_basilica/          # 20+ validation images
            ├── olympic_stadium_tower/        # 20+ validation images
            ├── mount_royal_cross/           # 20+ validation images
            ├── old_port_clock_tower/        # 20+ validation images
            ├── saint_josephs_oratory/       # 20+ validation images
            └── background/                  # 40+ validation images
        """
        
        readme_path = self.data_dir / "README_DATA_COLLECTION.md"
        with open(readme_path, 'w') as f:
            f.write(f"""# Montreal Monument Training Data

## Required Directory Structure:
```
{sample_structure}
```

## Data Collection Guidelines:

### For each landmark, collect images with:
- Different angles and perspectives
- Various lighting conditions (day/night/golden hour)
- Different weather conditions
- Different seasons
- Close-up and wide shots
- Images with people and without people

### Image Requirements:
- Minimum 100 images per landmark for training
- Minimum 20 images per landmark for validation
- Images should be at least 224x224 pixels
- JPG or PNG format
- Clear, high-quality images

### Sources for Images:
1. **Personal Photography**: Take photos yourself
2. **Flickr API**: Use Flickr's API to download Creative Commons images
3. **Google Images**: Use with proper licensing considerations
4. **Tourism Websites**: Montreal tourism sites (with permission)
5. **Wikipedia Commons**: Free-use images

### Background Images:
Include images of Montreal that don't contain the target landmarks:
- Street scenes
- Other buildings
- Parks and nature
- People and crowds
- Interior shots

## Next Steps:
1. Collect and organize images according to the structure above
2. Run the training script: `python train_monument_model.py`
3. The script will create a Core ML model ready for your iOS app
""")
        
        print(f"📝 Created data collection guide: {readme_path}")

    def create_model(self):
        """Create the neural network model using transfer learning"""
        print("🧠 Creating model architecture...")
        
        # Use pre-trained ResNet50 as base
        base_model = applications.ResNet50(
            weights='imagenet',
            include_top=False,
            input_shape=(*self.img_size, 3)
        )
        
        # Freeze base model layers initially
        base_model.trainable = False
        
        # Add custom classification head
        model = keras.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dropout(0.3),
            layers.Dense(128, activation='relu'),
            layers.Dropout(0.2),
            layers.Dense(len(self.landmarks) + 1, activation='softmax')  # +1 for background class
        ])
        
        # Compile model
        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        print(f"✅ Model created with {len(self.landmarks) + 1} classes")
        return model

    def prepare_data_generators(self):
        """Create data generators for training and validation"""
        print("📊 Preparing data generators...")
        
        # Data augmentation for training
        train_datagen = ImageDataGenerator(
            rescale=1./255,
            rotation_range=20,
            width_shift_range=0.2,
            height_shift_range=0.2,
            shear_range=0.2,
            zoom_range=0.2,
            horizontal_flip=True,
            fill_mode='nearest'
        )
        
        # Only rescaling for validation
        val_datagen = ImageDataGenerator(rescale=1./255)
        
        # Create generators
        train_generator = train_datagen.flow_from_directory(
            self.data_dir / 'train',
            target_size=self.img_size,
            batch_size=self.batch_size,
            class_mode='categorical'
        )
        
        validation_generator = val_datagen.flow_from_directory(
            self.data_dir / 'validation',
            target_size=self.img_size,
            batch_size=self.batch_size,
            class_mode='categorical'
        )
        
        return train_generator, validation_generator

    def train_model(self):
        """Train the model (requires actual image data)"""
        print("🚀 Starting model training...")
        
        # Check if we have actual training data
        train_dir = self.data_dir / 'train'
        if not any(train_dir.iterdir()):
            print("❌ No training data found!")
            print("Please add images to the training_data directory structure.")
            print("See README_DATA_COLLECTION.md for instructions.")
            return None
        
        # Create model
        model = self.create_model()
        
        # Prepare data
        train_gen, val_gen = self.prepare_data_generators()
        
        # Callbacks
        callbacks = [
            keras.callbacks.EarlyStopping(patience=10, restore_best_weights=True),
            keras.callbacks.ReduceLROnPlateau(factor=0.2, patience=5),
            keras.callbacks.ModelCheckpoint(
                str(self.model_output_dir / 'best_model.h5'),
                save_best_only=True
            )
        ]
        
        # Train model
        history = model.fit(
            train_gen,
            epochs=self.epochs,
            validation_data=val_gen,
            callbacks=callbacks
        )
        
        return model, history

    def convert_to_coreml(self, model):
        """Convert trained Keras model to Core ML format"""
        print("🔄 Converting to Core ML format...")
        
        # Create class labels
        class_labels = self.landmarks + ['background']
        
        # Convert to Core ML
        coreml_model = ct.convert(
            model,
            inputs=[ct.ImageType(
                name="image",
                shape=(1, *self.img_size, 3),
                bias=[-1, -1, -1],
                scale=1/127.5
            )],
            classifier_config=ct.ClassifierConfig(class_labels)
        )
        
        # Add metadata
        coreml_model.short_description = "Montreal Monument Recognition Model"
        coreml_model.author = "MonuMentAR App"
        coreml_model.license = "MIT"
        coreml_model.version = "1.0"
        
        # Save model
        model_path = self.model_output_dir / "MontrealMonuments.mlmodel"
        coreml_model.save(str(model_path))
        
        print(f"✅ Core ML model saved to: {model_path}")
        return model_path

    def create_demo_model(self):
        """Create a demo model for testing (without actual training data)"""
        print("🎯 Creating demo model for testing...")
        
        # Create a simple model for demonstration
        model = keras.Sequential([
            layers.Input(shape=(*self.img_size, 3)),
            layers.Conv2D(32, 3, activation='relu'),
            layers.MaxPooling2D(),
            layers.Conv2D(64, 3, activation='relu'),
            layers.MaxPooling2D(),
            layers.Conv2D(64, 3, activation='relu'),
            layers.GlobalAveragePooling2D(),
            layers.Dense(64, activation='relu'),
            layers.Dense(len(self.landmarks) + 1, activation='softmax')
        ])
        
        model.compile(
            optimizer='adam',
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        # Convert to Core ML
        model_path = self.convert_to_coreml(model)
        
        # Create integration instructions
        self.create_integration_guide(model_path)
        
        return model_path

    def create_integration_guide(self, model_path):
        """Create integration guide for the iOS app"""
        guide_path = self.model_output_dir / "INTEGRATION_GUIDE.md"
        
        integration_code = """# Core ML Model Integration Guide

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
"""
        
        with open(guide_path, 'w') as f:
            f.write(integration_code)
        
        print(f"📖 Integration guide created: {guide_path}")

def main():
    """Main training pipeline"""
    print("🏛️  Montreal Monument Detection Model Trainer")
    print("=" * 50)
    
    trainer = MontrealMonumentModelTrainer()
    
    # Setup directory structure
    trainer.setup_data_structure()
    
    # Create data collection guide
    trainer.download_sample_images()
    
    # Check if we have training data
    train_dirs = list((trainer.data_dir / 'train').iterdir())
    has_data = any(len(list(d.glob('*'))) > 0 for d in train_dirs if d.is_dir())
    
    if has_data:
        print("📸 Found training data, starting full training...")
        model, history = trainer.train_model()
        if model:
            trainer.convert_to_coreml(model)
    else:
        print("📝 No training data found, creating demo model...")
        print("This demo model won't be accurate but shows the integration process.")
        trainer.create_demo_model()
    
    print("\n🎉 Setup complete!")
    print("\nNext steps:")
    print("1. Collect training images (see README_DATA_COLLECTION.md)")
    print("2. Run this script again to train with real data")
    print("3. Follow INTEGRATION_GUIDE.md to add the model to your iOS app")

if __name__ == "__main__":
    main()

