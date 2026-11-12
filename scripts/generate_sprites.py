import os
from PIL import Image, ImageDraw

WIDTH, HEIGHT = 48, 48
SCALE = 4  # 48x48 -> 192x192

# Palette
C_CLEAR = (0, 0, 0, 0)
C_HAIR_DARK = (52, 33, 19, 255)
C_HAIR_MID = (92, 58, 33, 255)
C_HAIR_LIGHT = (130, 84, 48, 255)

C_SKIN = (255, 218, 178, 255)
C_SKIN_SHADOW = (226, 175, 131, 255)
C_BLUSH = (248, 155, 142, 255)

C_GLASSES = (24, 24, 32, 255)
C_GLASSES_LENS = (165, 240, 255, 200)
C_EYE = (18, 18, 24, 255)

C_HOODIE_BLUE = (37, 99, 235, 255)      # Tech Royal Blue
C_HOODIE_DARK = (29, 78, 216, 255)      # Shadow
C_HOODIE_LIGHT = (96, 165, 250, 255)    # Highlight
C_HOODIE_STRING = (224, 231, 255, 255)
C_BADGE = (34, 197, 94, 255)            # Green terminal badge

C_PANTS = (30, 41, 59, 255)             # Slate 800
C_PANTS_DARK = (15, 23, 42, 255)
C_SHOES_WHITE = (248, 250, 252, 255)
C_SHOES_ORANGE = (249, 115, 22, 255)

C_MUG_BODY = (241, 245, 249, 255)
C_MUG_LOGO = (16, 185, 129, 255)
C_COFFEE = (120, 53, 15, 255)
C_STEAM = (226, 232, 240, 180)

C_LAPTOP = (71, 85, 105, 255)
C_LAPTOP_SCREEN = (15, 23, 42, 255)
C_CYAN_CODE = (56, 189, 248, 255)
C_GREEN_CODE = (74, 222, 128, 255)

C_RED_BUG = (239, 68, 68, 255)
C_YELLOW_WARN = (250, 204, 21, 255)
C_ZZZ = (147, 197, 253, 255)


def create_canvas():
    return Image.new("RGBA", (48, 48), C_CLEAR)


def draw_pixel(draw, x, y, color):
    draw.point((x, y), fill=color)


def draw_rect(draw, x1, y1, x2, y2, color):
    draw.rectangle([x1, y1, x2, y2], fill=color)


def draw_head(draw, offset_y=0, eyes_state="open", tilt_x=0):
    """Draws Dave's head, messy hair, glasses, face"""
    base_x = 24 + tilt_x
    base_y = 15 + offset_y

    # Face base (skin)
    draw_rect(draw, base_x - 5, base_y - 2, base_x + 5, base_y + 6, C_SKIN)
    draw_rect(draw, base_x - 4, base_y + 7, base_x + 4, base_y + 7, C_SKIN_SHADOW)  # Chin shadow

    # Hair back / top
    draw_rect(draw, base_x - 6, base_y - 6, base_x + 6, base_y - 3, C_HAIR_MID)
    draw_rect(draw, base_x - 5, base_y - 7, base_x + 5, base_y - 6, C_HAIR_DARK)
    # Messy tufts
    draw_pixel(draw, base_x - 6, base_y - 7, C_HAIR_LIGHT)
    draw_pixel(draw, base_x - 2, base_y - 8, C_HAIR_LIGHT)
    draw_pixel(draw, base_x + 3, base_y - 8, C_HAIR_MID)
    draw_pixel(draw, base_x + 6, base_y - 6, C_HAIR_DARK)

    # Hair bangs & sides
    draw_rect(draw, base_x - 7, base_y - 3, base_x - 6, base_y + 3, C_HAIR_DARK)
    draw_rect(draw, base_x + 6, base_y - 3, base_x + 7, base_y + 3, C_HAIR_MID)
    # Bangs over forehead
    draw_rect(draw, base_x - 5, base_y - 3, base_x - 3, base_y - 1, C_HAIR_MID)
    draw_rect(draw, base_x - 1, base_y - 3, base_x + 1, base_y, C_HAIR_DARK)
    draw_rect(draw, base_x + 2, base_y - 3, base_x + 4, base_y - 1, C_HAIR_LIGHT)

    # Glasses frames (classic rectangular thick frame)
    # Left eye frame: [base_x - 4, base_y, base_x - 1, base_y + 3]
    # Bridge: [base_x - 1, base_y + 1, base_x, base_y + 1]
    # Right eye frame: [base_x + 1, base_y, base_x + 4, base_y + 3]
    draw_rect(draw, base_x - 5, base_y + 1, base_x - 1, base_y + 3, C_GLASSES)
    draw_rect(draw, base_x + 1, base_y + 1, base_x + 5, base_y + 3, C_GLASSES)
    draw_rect(draw, base_x - 1, base_y + 1, base_x + 1, base_y + 1, C_GLASSES)

    if eyes_state == "open":
        # Lens glint
        draw_pixel(draw, base_x - 4, base_y + 2, C_GLASSES_LENS)
        draw_pixel(draw, base_x - 2, base_y + 2, C_EYE)
        draw_pixel(draw, base_x + 2, base_y + 2, C_GLASSES_LENS)
        draw_pixel(draw, base_x + 4, base_y + 2, C_EYE)
    elif eyes_state == "blink":
        # Eyelids shut
        draw_rect(draw, base_x - 4, base_y + 2, base_x - 2, base_y + 2, C_EYE)
        draw_rect(draw, base_x + 2, base_y + 2, base_x + 4, base_y + 2, C_EYE)
    elif eyes_state == "happy":
        # Cute ^ ^ eyes
        draw_pixel(draw, base_x - 4, base_y + 2, C_EYE)
        draw_pixel(draw, base_x - 3, base_y + 1, C_EYE)
        draw_pixel(draw, base_x - 2, base_y + 2, C_EYE)
        draw_pixel(draw, base_x + 2, base_y + 2, C_EYE)
        draw_pixel(draw, base_x + 3, base_y + 1, C_EYE)
        draw_pixel(draw, base_x + 4, base_y + 2, C_EYE)
    elif eyes_state == "wide":
        # Surprised O O eyes
        draw_rect(draw, base_x - 4, base_y + 1, base_x - 2, base_y + 3, C_EYE)
        draw_rect(draw, base_x + 2, base_y + 1, base_x + 4, base_y + 3, C_EYE)
        draw_pixel(draw, base_x - 3, base_y + 2, C_SHOES_WHITE)
        draw_pixel(draw, base_x + 3, base_y + 2, C_SHOES_WHITE)
    elif eyes_state == "sleep":
        # Flat sleep line
        draw_rect(draw, base_x - 4, base_y + 2, base_x - 2, base_y + 2, C_EYE)
        draw_rect(draw, base_x + 2, base_y + 2, base_x + 4, base_y + 2, C_EYE)

    # Cheeks / Blush
    draw_pixel(draw, base_x - 4, base_y + 4, C_BLUSH)
    draw_pixel(draw, base_x + 4, base_y + 4, C_BLUSH)

    # Mouth
    if eyes_state == "happy":
        draw_rect(draw, base_x - 1, base_y + 5, base_x + 1, base_y + 5, C_SKIN_SHADOW)
    elif eyes_state == "wide":
        draw_rect(draw, base_x - 1, base_y + 5, base_x + 1, base_y + 6, C_EYE)
    else:
        draw_pixel(draw, base_x, base_y + 5, C_SKIN_SHADOW)


def draw_body(draw, offset_y=0, breathe=0):
    """Draws hoodie, badge, strings"""
    by = 23 + offset_y - breathe

    # Neck
    draw_rect(draw, 22, by, 26, by + 1, C_SKIN_SHADOW)

    # Hoodie Main Torso
    draw_rect(draw, 17, by + 1, 31, by + 10, C_HOODIE_BLUE)
    # Hoodie Shadow (bottom & right)
    draw_rect(draw, 17, by + 9, 31, by + 10, C_HOODIE_DARK)
    draw_rect(draw, 30, by + 2, 31, by + 9, C_HOODIE_DARK)
    # Hoodie Light (top left)
    draw_rect(draw, 17, by + 1, 18, by + 8, C_HOODIE_LIGHT)

    # Drawstrings
    draw_pixel(draw, 21, by + 2, C_HOODIE_STRING)
    draw_pixel(draw, 21, by + 3, C_HOODIE_STRING)
    draw_pixel(draw, 27, by + 2, C_HOODIE_STRING)
    draw_pixel(draw, 27, by + 3, C_HOODIE_STRING)

    # Tech badge (Terminal >_)
    draw_pixel(draw, 20, by + 5, C_BADGE)
    draw_pixel(draw, 21, by + 6, C_BADGE)
    draw_pixel(draw, 20, by + 7, C_BADGE)
    draw_pixel(draw, 23, by + 7, C_BADGE)

    # Front Kangaroo Pocket
    draw_rect(draw, 20, by + 7, 28, by + 9, C_HOODIE_DARK)
    draw_rect(draw, 21, by + 7, 27, by + 8, C_HOODIE_BLUE)


def draw_legs(draw, offset_y=0, dangling=False, leg_frame=0):
    ly = 34 + offset_y
    if not dangling:
        # Standing legs
        draw_rect(draw, 19, ly, 22, ly + 6, C_PANTS)
        draw_rect(draw, 26, ly, 29, ly + 6, C_PANTS)
        # Shoes
        draw_rect(draw, 18, ly + 7, 22, ly + 8, C_SHOES_WHITE)
        draw_pixel(draw, 19, ly + 7, C_SHOES_ORANGE)
        draw_rect(draw, 26, ly + 7, 30, ly + 8, C_SHOES_WHITE)
        draw_pixel(draw, 29, ly + 7, C_SHOES_ORANGE)
    else:
        # Dangling/kicking legs
        if leg_frame == 0:
            draw_rect(draw, 18, ly, 21, ly + 5, C_PANTS)
            draw_rect(draw, 27, ly, 30, ly + 5, C_PANTS)
            draw_rect(draw, 17, ly + 6, 21, ly + 7, C_SHOES_WHITE)
            draw_rect(draw, 27, ly + 6, 31, ly + 7, C_SHOES_WHITE)
        elif leg_frame == 1:
            # Kick left
            draw_rect(draw, 16, ly, 19, ly + 5, C_PANTS)
            draw_rect(draw, 26, ly, 29, ly + 5, C_PANTS)
            draw_rect(draw, 14, ly + 5, 18, ly + 6, C_SHOES_WHITE)
            draw_rect(draw, 26, ly + 6, 30, ly + 7, C_SHOES_WHITE)
        elif leg_frame == 2:
            # Kick right
            draw_rect(draw, 19, ly, 22, ly + 5, C_PANTS)
            draw_rect(draw, 29, ly, 32, ly + 5, C_PANTS)
            draw_rect(draw, 19, ly + 6, 23, ly + 7, C_SHOES_WHITE)
            draw_rect(draw, 30, ly + 5, 34, ly + 6, C_SHOES_WHITE)
        else:
            # Tucked
            draw_rect(draw, 19, ly, 22, ly + 4, C_PANTS)
            draw_rect(draw, 26, ly, 29, ly + 4, C_PANTS)
            draw_rect(draw, 18, ly + 5, 22, ly + 6, C_SHOES_WHITE)
            draw_rect(draw, 26, ly + 5, 30, ly + 6, C_SHOES_WHITE)


def save_sprite(img, path):
    # Upscale 4x using NEAREST filter for crisp pixel art
    scaled = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
    scaled.save(path, "PNG")


def generate_all():
    # ---------------- IDLE (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)
        breathe = 1 if i in (1, 2) else 0
        eyes = "blink" if i == 2 else "open"

        draw_legs(draw, offset_y=0)
        draw_body(draw, offset_y=0, breathe=breathe)
        draw_head(draw, offset_y=-breathe, eyes_state=eyes)

        # Arms holding a small mug at side
        # Left arm
        draw_rect(draw, 15, 24 - breathe, 16, 29 - breathe, C_HOODIE_DARK)
        draw_rect(draw, 15, 30 - breathe, 16, 31 - breathe, C_SKIN)

        # Right arm holding mug
        draw_rect(draw, 32, 24 - breathe, 33, 28 - breathe, C_HOODIE_BLUE)
        draw_rect(draw, 31, 28 - breathe, 32, 29 - breathe, C_SKIN)
        # Mug
        draw_rect(draw, 33, 27 - breathe, 36, 31 - breathe, C_MUG_BODY)
        draw_pixel(draw, 34, 29 - breathe, C_MUG_LOGO)
        draw_pixel(draw, 37, 28 - breathe, C_MUG_BODY)  # Mug handle

        save_sprite(img, f"Assets/Sprites/idle/frame_{i}.png")

    # ---------------- CODING (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        # Sitting slightly lower
        draw_legs(draw, offset_y=1)
        draw_body(draw, offset_y=1, breathe=0)
        draw_head(draw, offset_y=1, eyes_state="open")

        # Cyber Laptop & Stand
        draw_rect(draw, 14, 28, 34, 30, C_LAPTOP)
        # Screen angled
        draw_rect(draw, 15, 21, 33, 27, C_LAPTOP_SCREEN)
        draw_rect(draw, 16, 22, 32, 26, (15, 23, 42, 255))

        # Dynamic Code on screen
        if i % 2 == 0:
            draw_rect(draw, 17, 23, 23, 23, C_CYAN_CODE)
            draw_rect(draw, 17, 25, 28, 25, C_GREEN_CODE)
            draw_pixel(draw, 30, 25, C_SHOES_WHITE)  # Cursor
        else:
            draw_rect(draw, 17, 23, 27, 23, C_GREEN_CODE)
            draw_rect(draw, 17, 25, 22, 25, C_CYAN_CODE)
            draw_pixel(draw, 24, 25, C_SHOES_WHITE)

        # Hands typing furiously (alternating)
        if i == 0:
            draw_rect(draw, 17, 29, 19, 30, C_SKIN)
            draw_rect(draw, 28, 28, 30, 29, C_SKIN)
        elif i == 1:
            draw_rect(draw, 17, 28, 19, 29, C_SKIN)
            draw_rect(draw, 28, 29, 30, 30, C_SKIN)
        elif i == 2:
            draw_rect(draw, 18, 29, 20, 30, C_SKIN)
            draw_rect(draw, 27, 29, 29, 30, C_SKIN)
        else:
            draw_rect(draw, 17, 28, 19, 29, C_SKIN)
            draw_rect(draw, 28, 28, 30, 29, C_SKIN)

        # Code sparkles floating above
        if i == 1:
            draw_pixel(draw, 12, 16, C_CYAN_CODE)
            draw_pixel(draw, 13, 15, C_CYAN_CODE)
        elif i == 2:
            draw_pixel(draw, 35, 14, C_GREEN_CODE)
            draw_pixel(draw, 36, 15, C_GREEN_CODE)
        elif i == 3:
            draw_pixel(draw, 11, 14, C_GREEN_CODE)
            draw_pixel(draw, 37, 16, C_CYAN_CODE)

        save_sprite(img, f"Assets/Sprites/coding/frame_{i}.png")

    # ---------------- DEBUGGING / THINKING (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        tilt = 1 if i in (1, 2) else 0
        draw_legs(draw, offset_y=0)
        draw_body(draw, offset_y=0, breathe=0)
        draw_head(draw, offset_y=0, eyes_state="open", tilt_x=tilt)

        # Left hand on hip
        draw_rect(draw, 15, 24, 16, 28, C_HOODIE_DARK)
        draw_rect(draw, 17, 28, 18, 29, C_SKIN)

        # Right hand scratching head
        draw_rect(draw, 32, 23, 33, 27, C_HOODIE_BLUE)
        draw_rect(draw, 31, 17, 32, 22, C_HOODIE_LIGHT)
        draw_rect(draw, 29, 14, 31, 16, C_SKIN)

        # Floating Question Mark or Red Bug
        if i == 0 or i == 1:
            # Yellow '?'
            qy = 4 if i == 0 else 3
            draw_rect(draw, 11, qy, 14, qy, C_YELLOW_WARN)
            draw_pixel(draw, 14, qy + 1, C_YELLOW_WARN)
            draw_rect(draw, 12, qy + 2, 13, qy + 2, C_YELLOW_WARN)
            draw_pixel(draw, 12, qy + 4, C_YELLOW_WARN)
        else:
            # Red Pixel Bug flying near
            bx = 38
            by = 7 if i == 2 else 6
            # Bug body
            draw_rect(draw, bx, by, bx + 3, by + 3, C_RED_BUG)
            # Legs
            draw_pixel(draw, bx - 1, by, C_GLASSES)
            draw_pixel(draw, bx - 1, by + 2, C_GLASSES)
            draw_pixel(draw, bx + 4, by, C_GLASSES)
            draw_pixel(draw, bx + 4, by + 2, C_GLASSES)
            # Exclamation above bug
            draw_pixel(draw, bx + 1, by - 3, C_RED_BUG)
            draw_pixel(draw, bx + 1, by - 2, C_RED_BUG)

        save_sprite(img, f"Assets/Sprites/debugging/frame_{i}.png")

    # ---------------- COFFEE (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        eyes = "happy" if i in (1, 2) else "open"
        draw_legs(draw, offset_y=0)
        draw_body(draw, offset_y=0, breathe=0)
        draw_head(draw, offset_y=0, eyes_state=eyes)

        # Left arm relaxed
        draw_rect(draw, 15, 24, 16, 29, C_HOODIE_DARK)
        draw_rect(draw, 15, 30, 16, 31, C_SKIN)

        # Right arm raising mug to mouth
        if i == 0:
            # Low mug
            draw_rect(draw, 32, 24, 33, 28, C_HOODIE_BLUE)
            draw_rect(draw, 29, 27, 31, 28, C_SKIN)
            draw_rect(draw, 26, 26, 29, 30, C_MUG_BODY)
            draw_pixel(draw, 25, 27, C_MUG_BODY)
        elif i == 1 or i == 2:
            # Mug at lips drinking!
            draw_rect(draw, 30, 23, 33, 25, C_HOODIE_BLUE)
            draw_rect(draw, 27, 21, 29, 23, C_SKIN)
            draw_rect(draw, 23, 20, 27, 24, C_MUG_BODY)
            draw_pixel(draw, 22, 21, C_MUG_BODY)
            # Rising Steam
            sy = 14 if i == 1 else 13
            draw_pixel(draw, 24, sy, C_STEAM)
            draw_pixel(draw, 25, sy - 2, C_STEAM)
            draw_pixel(draw, 27, sy - 1, C_STEAM)
            draw_pixel(draw, 28, sy - 3, C_STEAM)
        else:
            # Savoring coffee, lowered mug, heart / +HP
            draw_rect(draw, 32, 24, 33, 28, C_HOODIE_BLUE)
            draw_rect(draw, 29, 27, 31, 28, C_SKIN)
            draw_rect(draw, 26, 26, 29, 30, C_MUG_BODY)
            # Little pixel heart
            draw_pixel(draw, 11, 10, C_RED_BUG)
            draw_pixel(draw, 13, 10, C_RED_BUG)
            draw_rect(draw, 10, 11, 14, 11, C_RED_BUG)
            draw_rect(draw, 11, 12, 13, 12, C_RED_BUG)
            draw_pixel(draw, 12, 13, C_RED_BUG)

        save_sprite(img, f"Assets/Sprites/coffee/frame_{i}.png")

    # ---------------- SLEEPING (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        # Curled up sleeping pose
        breathe = 1 if i in (1, 2) else 0

        # Dave slouched forward
        draw_legs(draw, offset_y=3)
        draw_body(draw, offset_y=3, breathe=-breathe)
        draw_head(draw, offset_y=3 + breathe, eyes_state="sleep")

        # Arms crossed resting on knees
        draw_rect(draw, 18, 29, 30, 31, C_HOODIE_DARK)
        draw_rect(draw, 21, 30, 27, 31, C_SKIN)

        # Floating 'Zzz'
        zx = 34 + (i * 2)
        zy = 12 - (i * 2)
        # Small 'z'
        draw_rect(draw, zx, zy, zx + 3, zy, C_ZZZ)
        draw_pixel(draw, zx + 2, zy + 1, C_ZZZ)
        draw_pixel(draw, zx + 1, zy + 2, C_ZZZ)
        draw_rect(draw, zx, zy + 3, zx + 3, zy + 3, C_ZZZ)

        if i >= 2:
            # Smaller second 'z'
            sx = zx - 4
            sy = zy + 6
            draw_rect(draw, sx, sy, sx + 2, sy, C_ZZZ)
            draw_pixel(draw, sx + 1, sy + 1, C_ZZZ)
            draw_rect(draw, sx, sy + 2, sx + 2, sy + 2, C_ZZZ)

        save_sprite(img, f"Assets/Sprites/sleeping/frame_{i}.png")

    # ---------------- DRAGGED (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        # Held aloft, stretched hoodie, kicking legs
        draw_legs(draw, offset_y=-2, dangling=True, leg_frame=i)

        # Stretched hoodie
        draw_rect(draw, 17, 18, 31, 30, C_HOODIE_BLUE)
        draw_rect(draw, 17, 28, 31, 30, C_HOODIE_DARK)
        # Flailing arms (upwards)
        draw_rect(draw, 13, 16, 16, 22, C_HOODIE_BLUE)
        draw_rect(draw, 12, 14, 14, 16, C_SKIN)

        draw_rect(draw, 32, 16, 35, 22, C_HOODIE_BLUE)
        draw_rect(draw, 34, 14, 36, 16, C_SKIN)

        # Surprised head
        draw_head(draw, offset_y=-4, eyes_state="wide")

        # Sweat drop
        if i in (1, 2):
            draw_pixel(draw, 33, 12, C_CYAN_CODE)
            draw_pixel(draw, 33, 13, C_CYAN_CODE)

        save_sprite(img, f"Assets/Sprites/dragged/frame_{i}.png")

    print("Successfully generated all sprite frames!")


if __name__ == "__main__":
    generate_all()
