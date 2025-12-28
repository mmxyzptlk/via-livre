#!/usr/bin/env python3
"""
Generate VIA LIVRE logo in various sizes for web app
"""
try:
    from PIL import Image, ImageDraw, ImageFont
    import os
except ImportError:
    print("PIL/Pillow not installed. Install with: pip install Pillow")
    exit(1)

def create_logo(size):
    """Create logo at specified size"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = int(size * 0.47)
    
    # Background circle with gradient effect
    # Draw multiple circles for gradient effect
    for i in range(radius, radius - 20, -2):
        alpha = int(255 * (1 - (radius - i) / 20))
        color = (1, 117, 194, alpha)  # #0175C2
        draw.ellipse(
            [center - i, center - i, center + i, center + i],
            fill=color
        )
    
    # Main background circle
    draw.ellipse(
        [center - radius, center - radius, center + radius, center + radius],
        fill=(1, 117, 194, 255)  # #0175C2
    )
    
    # Road/highway symbol
    road_width = int(size * 0.47)
    road_height = int(size * 0.16)
    road_x = center - road_width // 2
    road_y = center - road_height // 2
    
    # Road rectangle
    draw.rectangle(
        [road_x, road_y, road_x + road_width, road_y + road_height],
        fill=(255, 255, 255, 230)
    )
    
    # Road center line (dashed)
    line_y = center
    dash_length = int(size * 0.04)
    gap_length = int(size * 0.02)
    x = road_x + dash_length
    while x < road_x + road_width - dash_length:
        draw.line([x, line_y, x + dash_length, line_y], fill=(1, 117, 194, 255), width=max(2, size // 128))
        x += dash_length + gap_length
    
    # Road markings (circles)
    mark_size = max(3, size // 64)
    for offset in [-int(size * 0.31), 0, int(size * 0.31)]:
        draw.ellipse(
            [center + offset - mark_size, line_y - mark_size, 
             center + offset + mark_size, line_y + mark_size],
            fill=(1, 117, 194, 255)
        )
    
    # Location pin
    pin_top_y = int(size * 0.39)
    pin_bottom_y = int(size * 0.59)
    pin_width = int(size * 0.16)
    pin_center_x = center
    
    # Pin shadow
    shadow_y = pin_bottom_y + int(size * 0.05)
    shadow_width = int(size * 0.1)
    shadow_height = int(size * 0.03)
    draw.ellipse(
        [pin_center_x - shadow_width, shadow_y - shadow_height,
         pin_center_x + shadow_width, shadow_y + shadow_height],
        fill=(0, 0, 0, 50)
    )
    
    # Pin body (triangle)
    pin_points = [
        (pin_center_x, pin_top_y),  # Top
        (pin_center_x - pin_width // 2, pin_bottom_y - int(size * 0.06)),  # Left
        (pin_center_x, pin_bottom_y),  # Bottom center
        (pin_center_x + pin_width // 2, pin_bottom_y - int(size * 0.06)),  # Right
    ]
    draw.polygon(pin_points, fill=(255, 107, 53, 255))  # #FF6B35
    
    # Pin highlight
    highlight_size = int(size * 0.06)
    draw.ellipse(
        [pin_center_x - int(size * 0.03) - highlight_size // 2, 
         pin_top_y + int(size * 0.02) - highlight_size // 2,
         pin_center_x - int(size * 0.03) + highlight_size // 2,
         pin_top_y + int(size * 0.02) + highlight_size // 2],
        fill=(255, 255, 255, 80)
    )
    
    # Warning exclamation mark on pin
    exclam_width = max(2, size // 128)
    exclam_top_y = pin_top_y + int(size * 0.05)
    # Exclamation dot (triangle)
    dot_size = int(size * 0.02)
    draw.polygon([
        (pin_center_x, exclam_top_y),
        (pin_center_x - dot_size, exclam_top_y + dot_size * 2),
        (pin_center_x + dot_size, exclam_top_y + dot_size * 2),
    ], fill=(255, 255, 255, 255))
    # Exclamation line
    line_height = int(size * 0.04)
    draw.rectangle(
        [pin_center_x - exclam_width, exclam_top_y + dot_size * 2 + 2,
         pin_center_x + exclam_width, exclam_top_y + dot_size * 2 + 2 + line_height],
        fill=(255, 255, 255, 255)
    )
    
    return img

def main():
    sizes = [192, 512]
    maskable_sizes = [192, 512]
    
    # Create icons directory if it doesn't exist
    os.makedirs('icons', exist_ok=True)
    
    # Generate regular icons
    for size in sizes:
        logo = create_logo(size)
        filename = f'icons/Icon-{size}.png'
        logo.save(filename, 'PNG')
        print(f"Generated {filename}")
    
    # Generate maskable icons (with padding for safe zone)
    for size in maskable_sizes:
        # Create larger canvas for maskable (80% of size is safe zone)
        canvas_size = int(size * 1.25)  # Add padding
        logo = create_logo(size)
        
        # Create new image with padding
        maskable = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        paste_x = (canvas_size - size) // 2
        paste_y = (canvas_size - size) // 2
        maskable.paste(logo, (paste_x, paste_y), logo)
        
        filename = f'icons/Icon-maskable-{size}.png'
        maskable.save(filename, 'PNG')
        print(f"Generated {filename}")
    
    # Generate favicon (use 64px for better quality, browsers will scale it)
    try:
        favicon = create_logo(64)
        favicon.save('favicon.png', 'PNG')
        print("Generated favicon.png")
    except Exception as e:
        print(f"Warning: Could not generate favicon: {e}")
        # Create a simple favicon as fallback
        try:
            simple_favicon = Image.new('RGBA', (64, 64), (1, 117, 194, 255))
            simple_favicon.save('favicon.png', 'PNG')
            print("Generated simple favicon.png")
        except:
            pass
    
    print("\nAll logos generated successfully!")

if __name__ == '__main__':
    main()

