#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw

SIZE = 1024
OUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Toolbox",
    "Assets.xcassets",
    "AppIcon.appiconset",
    "AppIcon-1024.png",
)

os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)

SCALE = 2
W = SIZE * SCALE
H = SIZE * SCALE

img = Image.new("RGB", (W, H), (15, 23, 42))
draw = ImageDraw.Draw(img)

# Deep slate-blue radial gradient background
cx, cy = W // 2, H // 2
for r in range(W, 0, -16):
    t = 1.0 - (r / W)
    col = (
        int(15 + 20 * t),
        int(23 + 30 * t),
        int(42 + 48 * t),
    )
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)

# Outer subtle frame card
card_margin = 280
card_rect = [card_margin, card_margin + 80, W - card_margin, H - card_margin + 80]
# Toolbox handle
handle_w = 560
handle_h = 220
handle_rect = [
    cx - handle_w // 2,
    card_rect[1] - 150,
    cx + handle_w // 2,
    card_rect[1] + 90,
]
draw.rounded_rectangle(handle_rect, radius=90, outline=(148, 163, 184), width=56)

# Toolbox main body
draw.rounded_rectangle(card_rect, radius=160, fill=(30, 41, 59), outline=(71, 85, 105), width=16)

# Center divider / latch band
band_y = card_rect[1] + 290
draw.rectangle([card_rect[0] + 16, band_y - 12, card_rect[2] - 16, band_y + 12], fill=(51, 65, 85))

# 2x2 Grid of vibrant utility modules inside the toolbox
pad_x = 120
pad_top = 85
gap = 72
grid_left = card_rect[0] + pad_x
grid_right = card_rect[2] - pad_x
grid_top = card_rect[1] + pad_top
grid_bottom = card_rect[3] - 95

tile_w = (grid_right - grid_left - gap) // 2
tile_h = (grid_bottom - grid_top - gap) // 2

tiles = [
    # Top-left: Stirling-PDF (Coral Red)
    (grid_left, grid_top, (239, 68, 68), (254, 202, 202)),
    # Top-right: OpenCut (Electric Violet)
    (grid_left + tile_w + gap, grid_top, (139, 92, 246), (221, 214, 254)),
    # Bottom-left: n8n (Amber Orange)
    (grid_left, grid_top + tile_h + gap, (245, 158, 11), (254, 243, 199)),
    # Bottom-right: Tools / Settings (Sky Blue)
    (grid_left + tile_w + gap, grid_top + tile_h + gap, (59, 130, 246), (219, 234, 254)),
]

for idx, (x, y, fill_col, icon_col) in enumerate(tiles):
    draw.rounded_rectangle([x, y, x + tile_w, y + tile_h], radius=92, fill=fill_col)
    tx, ty = x + tile_w // 2, y + tile_h // 2
    if idx == 0:
        # Document lines glyph
        draw.rounded_rectangle([tx - 95, ty - 115, tx + 95, ty + 115], radius=24, fill=icon_col)
        draw.rounded_rectangle([tx - 55, ty - 55, tx + 55, ty - 30], radius=12, fill=fill_col)
        draw.rounded_rectangle([tx - 55, ty - 5, tx + 55, ty + 20], radius=12, fill=fill_col)
        draw.rounded_rectangle([tx - 55, ty + 45, tx + 25, ty + 70], radius=12, fill=fill_col)
    elif idx == 1:
        # Play / Video cut triangle
        pts = [(tx - 65, ty - 85), (tx - 65, ty + 85), (tx + 90, ty)]
        draw.polygon(pts, fill=icon_col)
    elif idx == 2:
        # Connected workflow nodes
        n1 = (tx - 80, ty + 45)
        n2 = (tx, ty - 55)
        n3 = (tx + 80, ty + 45)
        draw.line([n1, n2, n3], fill=icon_col, width=28)
        for nx, ny in [n1, n2, n3]:
            draw.ellipse([nx - 36, ny - 36, nx + 36, ny + 36], fill=icon_col)
    else:
        # Gear / Settings ring
        draw.ellipse([tx - 88, ty - 88, tx + 88, ty + 88], outline=icon_col, width=36)
        draw.ellipse([tx - 32, ty - 32, tx + 32, ty + 32], fill=icon_col)

final = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
final.save(OUT_PATH, "PNG")
print(f"Generated icon at {OUT_PATH} ({SIZE}x{SIZE})")
