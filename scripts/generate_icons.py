#!/usr/bin/env python3
"""
Generate macOS app icons from SVG source
Creates all required sizes for AppIcon.appiconset
"""

import os
import subprocess
import json

# Icon sizes required for macOS
ICON_SIZES = [
    (16, 1), (16, 2),      # 16pt (16x16@1x, 32x32@2x)
    (32, 1), (32, 2),      # 32pt (32x32@1x, 64x64@2x)
    (128, 1), (128, 2),    # 128pt (128x128@1x, 256x256@2x)
    (256, 1), (256, 2),    # 256pt (256x256@1x, 512x512@2x)
    (512, 1), (512, 2),    # 512pt (512x512@1x, 1024x1024@2x)
]

def create_icon_set():
    # Create AppIcon.appiconset directory
    iconset_path = "Memory Defragmenter/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(iconset_path, exist_ok=True)
    
    # Generate each icon size
    for size, scale in ICON_SIZES:
        actual_size = size * scale
        filename = f"icon_{size}x{size}@{scale}x.png"
        output_path = os.path.join(iconset_path, filename)
        
        # Convert SVG to PNG using ImageMagick or rsvg-convert
        try:
            # Try rsvg-convert first (better quality)
            subprocess.run([
                "rsvg-convert",
                "-w", str(actual_size),
                "-h", str(actual_size),
                "AppIcon.svg",
                "-o", output_path
            ], check=True)
            print(f"✓ Generated {filename} ({actual_size}x{actual_size})")
        except (subprocess.CalledProcessError, FileNotFoundError):
            try:
                # Fallback to ImageMagick
                subprocess.run([
                    "convert",
                    "-background", "none",
                    "-resize", f"{actual_size}x{actual_size}",
                    "AppIcon.svg",
                    output_path
                ], check=True)
                print(f"✓ Generated {filename} ({actual_size}x{actual_size})")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"✗ Failed to generate {filename} - Install rsvg-convert or ImageMagick")
                continue
    
    # Create Contents.json
    contents = {
        "images": [
            {
                "filename": f"icon_{size}x{size}@{scale}x.png",
                "idiom": "mac",
                "scale": f"{scale}x",
                "size": f"{size}x{size}"
            }
            for size, scale in ICON_SIZES
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    contents_path = os.path.join(iconset_path, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"✓ Created Contents.json")
    print(f"\nApp icons generated successfully in {iconset_path}")
    print("\nTo use these icons:")
    print("1. Open your Xcode project")
    print("2. Navigate to Assets.xcassets")
    print("3. The AppIcon should now show all the generated icons")

if __name__ == "__main__":
    if not os.path.exists("AppIcon.svg"):
        print("Error: AppIcon.svg not found in current directory")
        exit(1)
    
    create_icon_set()
