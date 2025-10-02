#!/usr/bin/env python3
"""
Simple Core ML Model Creator for Montreal Monuments

This creates a basic Core ML model that can be used for testing the integration
while you collect training data for the full model.
"""

import coremltools as ct
import numpy as np
from pathlib import Path

def create_simple_classifier():
    """Create a simple Core ML classifier for testing"""
    print("🎯 Creating simple Core ML model for testing...")
    
    # Define the landmarks
    landmarks = [
        "notre_dame_basilica",
        "olympic_stadium_tower", 
        "mount_royal_cross",
        "old_port_clock_tower",
        "saint_josephs_oratory",
        "background"
    ]
    
    # Create a simple neural network specification
    from coremltools.models.neural_network import NeuralNetworkBuilder
    from coremltools.models import datatypes
    
    # Input shape: 224x224x3 RGB image
    input_features = [('image', datatypes.Array(3, 224, 224))]
    output_features = [('classLabel', datatypes.String()), 
                      ('classProbability', datatypes.Dictionary(str))]
    
    builder = NeuralNetworkBuilder(input_features, output_features)
    
    # Add a simple convolution layer
    builder.add_convolution(name='conv1',
                           kernel_channels=3,
                           output_channels=32,
                           height=3,
                           width=3,
                           stride_height=1,
                           stride_width=1,
                           border_mode='valid',
                           groups=1,
                           W=np.random.rand(32, 3, 3, 3),
                           b=np.random.rand(32),
                           has_bias=True,
                           input_name='image',
                           output_name='conv1_output')
    
    # Add ReLU activation
    builder.add_activation(name='relu1',
                          non_linearity='RELU',
                          input_name='conv1_output',
                          output_name='relu1_output')
    
    # Add pooling layer
    builder.add_pooling(name='pool1',
                       height=2,
                       width=2,
                       stride_height=2,
                       stride_width=2,
                       layer_type='MAX',
                       padding_type='VALID',
                       input_name='relu1_output',
                       output_name='pool1_output')
    
    # Add flatten layer
    builder.add_flatten(name='flatten',
                       mode=1,
                       input_name='pool1_output',
                       output_name='flatten_output')
    
    # Add dense layer for classification
    builder.add_inner_product(name='dense1',
                             W=np.random.rand(len(landmarks), 32 * 111 * 111),
                             b=np.random.rand(len(landmarks)),
                             input_name='flatten_output',
                             output_name='dense1_output')
    
    # Add softmax for probabilities
    builder.add_softmax(name='softmax',
                       input_name='dense1_output',
                       output_name='softmax_output')
    
    # Set class labels
    builder.set_class_labels(class_labels=landmarks,
                            predicted_feature_name='classLabel',
                            prediction_blob='softmax_output')
    
    # Create the model
    model = ct.models.MLModel(builder.spec)
    
    # Add metadata
    model.short_description = "Simple Montreal Monument Classifier (Demo)"
    model.author = "MonuMentAR App"
    model.license = "MIT"
    model.version = "1.0-demo"
    
    return model

def main():
    """Create and save the simple model"""
    try:
        # Create the model
        model = create_simple_classifier()
        
        # Save the model
        output_path = Path("models/MontrealMonuments.mlmodel")
        output_path.parent.mkdir(exist_ok=True)
        
        model.save(str(output_path))
        
        print(f"✅ Simple Core ML model created: {output_path}")
        print("📝 This is a demo model for testing integration.")
        print("   It will give random predictions until you train with real data.")
        
        return True
        
    except Exception as e:
        print(f"❌ Error creating simple model: {e}")
        print("💡 This is likely due to Core ML version compatibility.")
        print("   You can create a model using Create ML in Xcode instead.")
        return False

if __name__ == "__main__":
    success = main()
    if not success:
        print("\n🔧 Alternative: Use Create ML in Xcode")
        print("1. Open Xcode and create a new playground")
        print("2. Import CreateML framework")
        print("3. Create an image classifier with your landmark categories")
        print("4. Export as MontrealMonuments.mlmodel")

