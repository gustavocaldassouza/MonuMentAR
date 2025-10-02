#!/usr/bin/env python3
"""
Training Data Collection Script for Montreal Monuments

This script helps collect training images for the Montreal monument detection model.
It provides utilities to download images from various sources while respecting
copyright and usage rights.
"""

import os
import sys
import json
import time
import requests
from pathlib import Path
from urllib.parse import urlparse
from PIL import Image
import hashlib

class MonumentDataCollector:
    def __init__(self, data_dir="training_data"):
        self.data_dir = Path(data_dir)
        self.landmarks = [
            "notre_dame_basilica",
            "olympic_stadium_tower", 
            "mount_royal_cross",
            "old_port_clock_tower",
            "saint_josephs_oratory"
        ]
        
        # Search terms for each landmark
        self.search_terms = {
            "notre_dame_basilica": [
                "Notre-Dame Basilica Montreal",
                "Basilique Notre-Dame Montreal",
                "Notre Dame Montreal interior",
                "Notre Dame Montreal exterior"
            ],
            "olympic_stadium_tower": [
                "Olympic Stadium Montreal",
                "Stade Olympique Montreal",
                "Montreal Olympic Tower",
                "Olympic Stadium inclined tower"
            ],
            "mount_royal_cross": [
                "Mount Royal Cross Montreal",
                "Croix du Mont-Royal",
                "Mount Royal illuminated cross",
                "Montreal cross night"
            ],
            "old_port_clock_tower": [
                "Old Port Clock Tower Montreal",
                "Tour de l'Horloge Montreal",
                "Montreal Clock Tower",
                "Vieux-Port clock tower"
            ],
            "saint_josephs_oratory": [
                "Saint Joseph's Oratory Montreal",
                "Oratoire Saint-Joseph Montreal",
                "Saint Joseph Oratory dome",
                "Montreal Oratory"
            ]
        }

    def setup_directories(self):
        """Create directory structure for training data"""
        print("📁 Setting up directory structure...")
        
        for split in ['train', 'validation']:
            split_dir = self.data_dir / split
            split_dir.mkdir(parents=True, exist_ok=True)
            
            for landmark in self.landmarks + ['background']:
                landmark_dir = split_dir / landmark
                landmark_dir.mkdir(exist_ok=True)

    def download_image(self, url, filepath, max_size=(800, 800)):
        """Download and process a single image"""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            }
            
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            # Open and process image
            image = Image.open(BytesIO(response.content))
            
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Resize if too large
            if image.size[0] > max_size[0] or image.size[1] > max_size[1]:
                image.thumbnail(max_size, Image.Resampling.LANCZOS)
            
            # Skip very small images
            if image.size[0] < 224 or image.size[1] < 224:
                return False
            
            # Save image
            image.save(filepath, 'JPEG', quality=85)
            return True
            
        except Exception as e:
            print(f"❌ Error downloading {url}: {e}")
            return False

    def create_manual_collection_guide(self):
        """Create a guide for manual image collection"""
        guide_content = """# Manual Image Collection Guide

## Recommended Sources for Montreal Monument Images

### 1. Flickr (Creative Commons)
- Search for each landmark name
- Filter by Creative Commons licenses
- Look for high-quality, diverse angles
- Download 20-30 images per landmark

### 2. Wikimedia Commons
- Search for Montreal landmarks
- All images are free to use
- Often high quality historical and recent photos
- Good source for architectural details

### 3. Personal Photography
- Visit Montreal and photograph landmarks yourself
- Take photos from multiple angles and distances
- Include different lighting conditions
- Capture seasonal variations

### 4. Tourism Websites (with permission)
- Montreal tourism official sites
- Travel blogs and guides
- Contact authors for permission if needed

## Collection Guidelines

### For Each Landmark:
- **Training set**: 100-200 images
- **Validation set**: 20-40 images
- **Variety**: Different angles, lighting, seasons, weather
- **Quality**: Minimum 224x224 pixels, clear and sharp
- **Formats**: JPG or PNG preferred

### Background Images:
- Montreal street scenes without target landmarks
- Other Montreal buildings and architecture
- Parks, people, vehicles in Montreal
- Interior shots of buildings
- 200+ training images, 40+ validation images

## File Naming Convention:
```
landmark_name_001.jpg
landmark_name_002.jpg
...
background_001.jpg
background_002.jpg
```

## Directory Structure:
```
training_data/
├── train/
│   ├── notre_dame_basilica/
│   ├── olympic_stadium_tower/
│   ├── mount_royal_cross/
│   ├── old_port_clock_tower/
│   ├── saint_josephs_oratory/
│   └── background/
└── validation/
    ├── notre_dame_basilica/
    ├── olympic_stadium_tower/
    ├── mount_royal_cross/
    ├── old_port_clock_tower/
    ├── saint_josephs_oratory/
    └── background/
```

## Tips for Good Training Data:
1. **Diversity is key**: Vary angles, distances, lighting
2. **Quality over quantity**: Better to have fewer high-quality images
3. **Real-world conditions**: Include typical tourist photos, not just professional shots
4. **Seasonal variation**: Summer and winter shots if possible
5. **Different times of day**: Morning, afternoon, evening, night shots
6. **Weather conditions**: Clear, cloudy, rainy conditions
7. **Crowd variation**: With and without people in the shots

## Legal Considerations:
- Always respect copyright and licensing
- Use Creative Commons or royalty-free images
- When in doubt, take your own photos
- Credit sources appropriately in your app
"""
        
        guide_path = self.data_dir / "MANUAL_COLLECTION_GUIDE.md"
        with open(guide_path, 'w') as f:
            f.write(guide_content)
        
        print(f"📖 Manual collection guide created: {guide_path}")

    def create_flickr_collection_script(self):
        """Create a script template for Flickr API usage"""
        flickr_script = '''#!/usr/bin/env python3
"""
Flickr Image Collection Script

This script uses the Flickr API to collect Creative Commons images.
You need to:
1. Get a Flickr API key from https://www.flickr.com/services/apps/create/apply
2. Install flickrapi: pip install flickrapi
3. Update the API_KEY and API_SECRET below
"""

import flickrapi
import requests
from pathlib import Path
import time

# TODO: Add your Flickr API credentials
API_KEY = 'YOUR_FLICKR_API_KEY'
API_SECRET = 'YOUR_FLICKR_API_SECRET'

class FlickrCollector:
    def __init__(self):
        self.flickr = flickrapi.FlickrAPI(API_KEY, API_SECRET, format='parsed-json')
        
    def search_and_download(self, search_term, landmark_name, max_images=50):
        """Search Flickr and download Creative Commons images"""
        print(f"🔍 Searching Flickr for: {search_term}")
        
        try:
            # Search for Creative Commons licensed images
            photos = self.flickr.photos.search(
                text=search_term,
                license='1,2,3,4,5,6',  # Creative Commons licenses
                media='photos',
                per_page=max_images,
                extras='url_m,url_l'  # Medium and large URLs
            )
            
            download_dir = Path(f'training_data/train/{landmark_name}')
            download_dir.mkdir(parents=True, exist_ok=True)
            
            downloaded = 0
            for photo in photos['photos']['photo']:
                if downloaded >= max_images:
                    break
                    
                # Try large image first, then medium
                image_url = photo.get('url_l') or photo.get('url_m')
                if not image_url:
                    continue
                
                filename = f"{landmark_name}_flickr_{photo['id']}.jpg"
                filepath = download_dir / filename
                
                if self.download_image(image_url, filepath):
                    downloaded += 1
                    print(f"✅ Downloaded: {filename}")
                
                time.sleep(1)  # Be respectful to the API
            
            print(f"📸 Downloaded {downloaded} images for {landmark_name}")
            
        except Exception as e:
            print(f"❌ Error searching Flickr: {e}")
    
    def download_image(self, url, filepath):
        """Download a single image"""
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            with open(filepath, 'wb') as f:
                f.write(response.content)
            return True
        except:
            return False

def main():
    if API_KEY == 'YOUR_FLICKR_API_KEY':
        print("❌ Please update the Flickr API credentials in this script")
        return
    
    collector = FlickrCollector()
    
    # Search terms for Montreal landmarks
    searches = {
        "notre_dame_basilica": ["Notre-Dame Basilica Montreal", "Basilique Notre-Dame Montreal"],
        "olympic_stadium_tower": ["Olympic Stadium Montreal", "Stade Olympique Montreal"],
        "mount_royal_cross": ["Mount Royal Cross Montreal", "Croix du Mont-Royal"],
        "old_port_clock_tower": ["Old Port Clock Tower Montreal", "Tour de l'Horloge Montreal"],
        "saint_josephs_oratory": ["Saint Joseph's Oratory Montreal", "Oratoire Saint-Joseph Montreal"]
    }
    
    for landmark, terms in searches.items():
        for term in terms:
            collector.search_and_download(term, landmark, max_images=25)

if __name__ == "__main__":
    main()
'''
        
        flickr_path = self.data_dir / "collect_from_flickr.py"
        with open(flickr_path, 'w') as f:
            f.write(flickr_script)
        
        print(f"📝 Flickr collection script created: {flickr_path}")

    def validate_dataset(self):
        """Validate the collected dataset"""
        print("🔍 Validating dataset...")
        
        total_images = 0
        for split in ['train', 'validation']:
            split_dir = self.data_dir / split
            if not split_dir.exists():
                print(f"❌ Missing directory: {split_dir}")
                continue
            
            print(f"\n📊 {split.upper()} SET:")
            split_total = 0
            
            for landmark in self.landmarks + ['background']:
                landmark_dir = split_dir / landmark
                if landmark_dir.exists():
                    image_count = len([f for f in landmark_dir.glob('*') 
                                     if f.suffix.lower() in ['.jpg', '.jpeg', '.png']])
                    print(f"   {landmark}: {image_count} images")
                    split_total += image_count
                else:
                    print(f"   {landmark}: 0 images (directory missing)")
            
            print(f"   TOTAL: {split_total} images")
            total_images += split_total
        
        print(f"\n🎯 DATASET SUMMARY: {total_images} total images")
        
        # Recommendations
        print("\n💡 RECOMMENDATIONS:")
        if total_images < 500:
            print("   - Collect more images (aim for 500+ total)")
        if total_images > 0:
            print("   - Dataset looks good for training!")
            print("   - Run: python train_monument_model.py")

def main():
    """Main data collection setup"""
    print("📸 Montreal Monument Data Collection Setup")
    print("=" * 50)
    
    collector = MonumentDataCollector()
    
    # Setup directories
    collector.setup_directories()
    
    # Create guides and scripts
    collector.create_manual_collection_guide()
    collector.create_flickr_collection_script()
    
    # Validate existing data
    collector.validate_dataset()
    
    print("\n🎉 Data collection setup complete!")
    print("\nNext steps:")
    print("1. Follow MANUAL_COLLECTION_GUIDE.md to collect images")
    print("2. Or set up Flickr API and run collect_from_flickr.py")
    print("3. Run this script again to validate your dataset")
    print("4. When you have enough images, run: python train_monument_model.py")

if __name__ == "__main__":
    main()

