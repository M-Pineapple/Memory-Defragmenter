#!/usr/bin/env python3
"""
Generate app icon sizes for macOS from SVG
"""

import subprocess
import os
import sys

def generate_icon(svg_path, size, scale, output_path):
    """Generate a PNG icon from SVG at specified size and scale."""
    actual_size = size * scale
    output_filename = f"icon_{size}x{size}@{scale}x.png"
    output_file = os.path.join(output_path, output_filename)
    
    # Use rsvg-convert if available, otherwise try inkscape
    try:
        # Try rsvg-convert first (faster)
        subprocess.run([
            'rsvg-convert',
            '-w', str(actual_size),
            '-h', str(actual_size),
            svg_path,
            '-o', output_file
        ], check=True, capture_output=True)
        print(f"✓ Generated {output_filename} ({actual_size}x{actual_size})")
    except (subprocess.CalledProcessError, FileNotFoundError):
        try:
            # Fallback to inkscape
            subprocess.run([
                'inkscape',
                '--export-type=png',
                f'--export-width={actual_size}',
                f'--export-height={actual_size}',
                f'--export-filename={output_file}',
                svg_path
            ], check=True, capture_output=True)
            print(f"✓ Generated {output_filename} ({actual_size}x{actual_size})")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(f"✗ Failed to generate {output_filename} - install rsvg-convert or inkscape")
            return False
    return True

def main():
    # Icon sizes needed for macOS
    sizes = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2)
    ]
    
    # Get the script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Paths
    svg_file = os.path.join(script_dir, "AppIcon_Unified.svg")
    if not os.path.exists(svg_file):
        # Try other versions if unified doesn't exist
        svg_file = os.path.join(script_dir, "AppIcon_New.svg")
        if not os.path.exists(svg_file):
            svg_file = os.path.join(script_dir, "AppIcon.svg")
    
    output_dir = os.path.join(script_dir, "Memory Defragmenter", "Assets.xcassets", "AppIcon.appiconset")
    
    if not os.path.exists(svg_file):
        print(f"Error: SVG file not found at {svg_file}")
        sys.exit(1)
    
    if not os.path.exists(output_dir):
        print(f"Error: Output directory not found at {output_dir}")
        sys.exit(1)
    
    print(f"Using SVG: {svg_file}")
    print(f"Output directory: {output_dir}")
    print()
    
    # Check for required tools
    has_tool = False
    try:
        subprocess.run(['rsvg-convert', '--version'], capture_output=True, check=True)
        print("Found rsvg-convert")
        has_tool = True
    except:
        try:
            subprocess.run(['inkscape', '--version'], capture_output=True, check=True)
            print("Found inkscape")
            has_tool = True
        except:
            print("Error: Neither rsvg-convert nor inkscape found.")
            print("Install one of them:")
            print("  brew install librsvg")
            print("  brew install inkscape")
            sys.exit(1)
    
    print("\nGenerating icons...")
    success_count = 0
    
    for size, scale in sizes:
        if generate_icon(svg_file, size, scale, output_dir):
            success_count += 1
    
    print(f"\nGenerated {success_count}/{len(sizes)} icons successfully!")
    
    if success_count == len(sizes):
        print("\n✅ All icons generated successfully!")
        print("The Assets.xcassets has been updated with the new icon.")
    else:
        print("\n⚠️  Some icons failed to generate.")

if __name__ == "__main__":
    main()
