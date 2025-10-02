# Montreal Monument Training Data

## Required Directory Structure:
```

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
