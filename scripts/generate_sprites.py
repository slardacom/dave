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

# File document palette
C_DOC_WHITE = (255, 255, 255, 255)
C_DOC_SHADOW = (203, 213, 225, 255)
C_DOC_LINE = (59, 130, 246, 255)
C_DOC_CORNER = (226, 232, 240, 255)

# Office Desk & Chair Palette
C_DESK_WOOD = (194, 137, 88, 255)
C_DESK_WOOD_LIGHT = (217, 166, 122, 255)
C_DESK_WOOD_DARK = (146, 96, 55, 255)
C_DESK_LEG = (51, 65, 85, 255)
C_DESK_LEG_DARK = (30, 41, 59, 255)

C_CHAIR_BACK = (47, 54, 64, 255)
C_CHAIR_FRAME = (24, 28, 36, 255)
C_CHAIR_CUSHION = (53, 59, 72, 255)
C_CHAIR_BASE = (30, 39, 46, 255)


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

    # Glasses frames
    draw_rect(draw, base_x - 5, base_y + 1, base_x - 1, base_y + 3, C_GLASSES)
    draw_rect(draw, base_x + 1, base_y + 1, base_x + 5, base_y + 3, C_GLASSES)
    draw_rect(draw, base_x - 1, base_y + 1, base_x + 1, base_y + 1, C_GLASSES)

    if eyes_state == "open":
        draw_pixel(draw, base_x - 4, base_y + 2, C_GLASSES_LENS)
        draw_pixel(draw, base_x - 2, base_y + 2, C_EYE)
        draw_pixel(draw, base_x + 2, base_y + 2, C_GLASSES_LENS)
        draw_pixel(draw, base_x + 4, base_y + 2, C_EYE)
    elif eyes_state == "blink":
        draw_rect(draw, base_x - 4, base_y + 2, base_x - 2, base_y + 2, C_EYE)
        draw_rect(draw, base_x + 2, base_y + 2, base_x + 4, base_y + 2, C_EYE)
    elif eyes_state == "happy":
        draw_pixel(draw, base_x - 4, base_y + 2, C_EYE)
        draw_pixel(draw, base_x - 3, base_y + 1, C_EYE)
        draw_pixel(draw, base_x - 2, base_y + 2, C_EYE)
        draw_pixel(draw, base_x + 2, base_y + 2, C_EYE)
        draw_pixel(draw, base_x + 3, base_y + 1, C_EYE)
        draw_pixel(draw, base_x + 4, base_y + 2, C_EYE)
    elif eyes_state == "wide":
        draw_rect(draw, base_x - 4, base_y + 1, base_x - 2, base_y + 3, C_EYE)
        draw_rect(draw, base_x + 2, base_y + 1, base_x + 4, base_y + 3, C_EYE)
        draw_pixel(draw, base_x - 3, base_y + 2, C_SHOES_WHITE)
        draw_pixel(draw, base_x + 3, base_y + 2, C_SHOES_WHITE)
    elif eyes_state == "sleep":
        draw_rect(draw, base_x - 4, base_y + 2, base_x - 2, base_y + 2, C_EYE)
        draw_rect(draw, base_x + 2, base_y + 2, base_x + 4, base_y + 2, C_EYE)

    # Cheeks / Blush
    draw_pixel(draw, base_x - 4, base_y + 4, C_BLUSH)
    draw_pixel(draw, base_x + 4, base_y + 4, C_BLUSH)

    # Mouth
    if eyes_state in ("happy", "wide"):
        draw_rect(draw, base_x - 1, base_y + 5, base_x + 1, base_y + 6, C_EYE)
    else:
        draw_pixel(draw, base_x, base_y + 5, C_SKIN_SHADOW)


def draw_body(draw, offset_y=0, breathe=0, lean_x=0):
    """Draws hoodie, badge, strings"""
    by = 23 + offset_y - breathe

    # Neck
    draw_rect(draw, 22 + lean_x, by, 26 + lean_x, by + 1, C_SKIN_SHADOW)

    # Hoodie Main Torso
    draw_rect(draw, 17 + lean_x, by + 1, 31 + lean_x, by + 10, C_HOODIE_BLUE)
    draw_rect(draw, 17 + lean_x, by + 9, 31 + lean_x, by + 10, C_HOODIE_DARK)
    draw_rect(draw, 30 + lean_x, by + 2, 31 + lean_x, by + 9, C_HOODIE_DARK)
    draw_rect(draw, 17 + lean_x, by + 1, 18 + lean_x, by + 8, C_HOODIE_LIGHT)

    # Drawstrings
    draw_pixel(draw, 21 + lean_x, by + 2, C_HOODIE_STRING)
    draw_pixel(draw, 21 + lean_x, by + 3, C_HOODIE_STRING)
    draw_pixel(draw, 27 + lean_x, by + 2, C_HOODIE_STRING)
    draw_pixel(draw, 27 + lean_x, by + 3, C_HOODIE_STRING)

    # Tech badge (Terminal >_)
    draw_pixel(draw, 20 + lean_x, by + 5, C_BADGE)
    draw_pixel(draw, 21 + lean_x, by + 6, C_BADGE)
    draw_pixel(draw, 20 + lean_x, by + 7, C_BADGE)
    draw_pixel(draw, 23 + lean_x, by + 7, C_BADGE)

    # Front Kangaroo Pocket
    draw_rect(draw, 20 + lean_x, by + 7, 28 + lean_x, by + 9, C_HOODIE_DARK)


def draw_legs(draw, offset_y=0, dangling=False, leg_frame=0):
    ly = 34 + offset_y
    if not dangling:
        draw_rect(draw, 19, ly, 22, ly + 6, C_PANTS)
        draw_rect(draw, 26, ly, 29, ly + 6, C_PANTS)
        draw_rect(draw, 18, ly + 7, 22, ly + 8, C_SHOES_WHITE)
        draw_pixel(draw, 19, ly + 7, C_SHOES_ORANGE)
        draw_rect(draw, 26, ly + 7, 30, ly + 8, C_SHOES_WHITE)
        draw_pixel(draw, 29, ly + 7, C_SHOES_ORANGE)
    else:
        if leg_frame == 0:
            draw_rect(draw, 18, ly, 21, ly + 5, C_PANTS)
            draw_rect(draw, 27, ly, 30, ly + 5, C_PANTS)
            draw_rect(draw, 17, ly + 6, 21, ly + 7, C_SHOES_WHITE)
            draw_rect(draw, 27, ly + 6, 31, ly + 7, C_SHOES_WHITE)
        elif leg_frame == 1:
            draw_rect(draw, 16, ly, 19, ly + 5, C_PANTS)
            draw_rect(draw, 26, ly, 29, ly + 5, C_PANTS)
            draw_rect(draw, 14, ly + 5, 18, ly + 6, C_SHOES_WHITE)
            draw_rect(draw, 26, ly + 6, 30, ly + 7, C_SHOES_WHITE)
        elif leg_frame == 2:
            draw_rect(draw, 19, ly, 22, ly + 5, C_PANTS)
            draw_rect(draw, 29, ly, 32, ly + 5, C_PANTS)
            draw_rect(draw, 19, ly + 6, 23, ly + 7, C_SHOES_WHITE)
            draw_rect(draw, 30, ly + 5, 34, ly + 6, C_SHOES_WHITE)
        else:
            draw_rect(draw, 19, ly, 22, ly + 4, C_PANTS)
            draw_rect(draw, 26, ly, 29, ly + 4, C_PANTS)
            draw_rect(draw, 18, ly + 5, 22, ly + 6, C_SHOES_WHITE)
            draw_rect(draw, 26, ly + 5, 30, ly + 6, C_SHOES_WHITE)


def draw_running_legs(draw, frame=0, offset_y=0):
    ly = 34 + offset_y
    if frame == 0:
        # Left leg back, right leg forward
        draw_rect(draw, 16, ly, 19, ly + 5, C_PANTS)
        draw_rect(draw, 14, ly + 6, 18, ly + 7, C_SHOES_WHITE)
        draw_pixel(draw, 15, ly + 6, C_SHOES_ORANGE)

        draw_rect(draw, 28, ly, 31, ly + 5, C_PANTS)
        draw_rect(draw, 29, ly + 6, 33, ly + 7, C_SHOES_WHITE)
        draw_pixel(draw, 32, ly + 6, C_SHOES_ORANGE)
    elif frame == 1:
        # Hop passing legs
        draw_rect(draw, 20, ly - 1, 23, ly + 4, C_PANTS)
        draw_rect(draw, 19, ly + 5, 23, ly + 6, C_SHOES_WHITE)

        draw_rect(draw, 26, ly - 1, 29, ly + 4, C_PANTS)
        draw_rect(draw, 26, ly + 5, 30, ly + 6, C_SHOES_WHITE)
    elif frame == 2:
        # Left leg forward, right leg back
        draw_rect(draw, 28, ly, 31, ly + 5, C_PANTS)
        draw_rect(draw, 29, ly + 6, 33, ly + 7, C_SHOES_WHITE)
        draw_pixel(draw, 31, ly + 6, C_SHOES_ORANGE)

        draw_rect(draw, 17, ly, 20, ly + 5, C_PANTS)
        draw_rect(draw, 15, ly + 6, 19, ly + 7, C_SHOES_WHITE)
        draw_pixel(draw, 16, ly + 6, C_SHOES_ORANGE)
    else:
        # Hop passing
        draw_rect(draw, 21, ly - 1, 24, ly + 4, C_PANTS)
        draw_rect(draw, 20, ly + 5, 24, ly + 6, C_SHOES_WHITE)

        draw_rect(draw, 25, ly - 1, 28, ly + 4, C_PANTS)
        draw_rect(draw, 25, ly + 5, 29, ly + 6, C_SHOES_WHITE)


def draw_file_document(draw, x, y):
    """Draws a cute pixel document/file icon"""
    # 10x12 pixel paper
    draw_rect(draw, x, y, x + 9, y + 11, C_DOC_WHITE)
    # Folded corner
    draw_pixel(draw, x + 9, y, C_CLEAR)
    draw_pixel(draw, x + 8, y, C_CLEAR)
    draw_pixel(draw, x + 9, y + 1, C_CLEAR)
    draw_pixel(draw, x + 7, y + 1, C_DOC_CORNER)
    draw_pixel(draw, x + 8, y + 2, C_DOC_CORNER)

    # Document text lines
    draw_rect(draw, x + 2, y + 3, x + 6, y + 3, C_DOC_LINE)
    draw_rect(draw, x + 2, y + 5, x + 7, y + 5, C_DOC_LINE)
    draw_rect(draw, x + 2, y + 7, x + 5, y + 7, C_DOC_LINE)
    draw_rect(draw, x + 2, y + 9, x + 7, y + 9, (239, 68, 68, 255))  # Red deletion accent


def save_sprite(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
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

        # Arms holding mug
        draw_rect(draw, 15, 24 - breathe, 16, 29 - breathe, C_HOODIE_DARK)
        draw_rect(draw, 15, 30 - breathe, 16, 31 - breathe, C_SKIN)

        draw_rect(draw, 32, 24 - breathe, 33, 28 - breathe, C_HOODIE_BLUE)
        draw_rect(draw, 31, 28 - breathe, 32, 29 - breathe, C_SKIN)
        draw_rect(draw, 33, 27 - breathe, 36, 31 - breathe, C_MUG_BODY)
        draw_pixel(draw, 34, 29 - breathe, C_MUG_LOGO)
        draw_pixel(draw, 37, 28 - breathe, C_MUG_BODY)

        save_sprite(img, f"Assets/Sprites/idle/frame_{i}.png")

    # ---------------- CODING (4 frames: Sitting at Office Desk) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        # 1. Chair backrest (behind Dave)
        draw_rect(draw, 14, 16, 34, 33, C_CHAIR_FRAME)
        draw_rect(draw, 15, 17, 33, 32, C_CHAIR_BACK)
        draw_rect(draw, 15, 17, 16, 32, (60, 68, 80, 255))

        # 2. Dave sitting body & head
        draw_body(draw, offset_y=1, breathe=0)
        draw_head(draw, offset_y=1, eyes_state="open")

        # 3. Chair seat & Dave sitting legs
        draw_rect(draw, 14, 34, 34, 36, C_CHAIR_CUSHION)
        draw_rect(draw, 23, 37, 25, 41, C_CHAIR_BASE)
        draw_rect(draw, 20, 41, 28, 42, C_CHAIR_FRAME)

        draw_rect(draw, 18, 33, 30, 36, C_PANTS)
        draw_rect(draw, 19, 36, 22, 40, C_PANTS)
        draw_rect(draw, 26, 36, 29, 40, C_PANTS)
        draw_rect(draw, 18, 41, 22, 42, C_SHOES_WHITE)
        draw_pixel(draw, 19, 41, C_SHOES_ORANGE)
        draw_rect(draw, 26, 41, 30, 42, C_SHOES_WHITE)
        draw_pixel(draw, 29, 41, C_SHOES_ORANGE)

        # 4. Office Desk (Wood surface + metal legs)
        draw_rect(draw, 7, 34, 9, 41, C_DESK_LEG)
        draw_rect(draw, 6, 42, 10, 42, C_DESK_LEG_DARK)
        draw_rect(draw, 39, 34, 41, 41, C_DESK_LEG)
        draw_rect(draw, 38, 42, 42, 42, C_DESK_LEG_DARK)

        draw_rect(draw, 6, 31, 42, 31, C_DESK_WOOD_LIGHT)
        draw_rect(draw, 5, 32, 43, 33, C_DESK_WOOD)
        draw_rect(draw, 6, 34, 42, 34, C_DESK_WOOD_DARK)

        # 5. Accessories on desk: Coffee mug & Sticky note
        draw_rect(draw, 36, 27, 39, 30, C_MUG_BODY)
        draw_pixel(draw, 37, 28, C_MUG_LOGO)
        draw_pixel(draw, 40, 28, C_MUG_BODY)
        if i % 2 == 0:
            draw_pixel(draw, 37, 25, C_STEAM)
            draw_pixel(draw, 38, 24, C_STEAM)
        else:
            draw_pixel(draw, 38, 25, C_STEAM)
            draw_pixel(draw, 39, 24, C_STEAM)

        draw_rect(draw, 9, 28, 12, 30, C_YELLOW_WARN)
        draw_pixel(draw, 10, 29, (202, 138, 4, 255))

        # 6. Laptop on Desk
        draw_rect(draw, 15, 31, 33, 32, C_LAPTOP)
        draw_rect(draw, 18, 31, 30, 31, (30, 41, 59, 255))
        draw_rect(draw, 16, 21, 32, 30, C_LAPTOP)
        draw_rect(draw, 17, 22, 31, 29, C_LAPTOP_SCREEN)

        # Animated code on screen
        if i % 2 == 0:
            draw_rect(draw, 18, 23, 24, 23, C_CYAN_CODE)
            draw_rect(draw, 18, 25, 29, 25, C_GREEN_CODE)
            draw_rect(draw, 18, 27, 22, 27, C_CYAN_CODE)
            draw_pixel(draw, 24, 27, C_SHOES_WHITE)
        else:
            draw_rect(draw, 18, 23, 28, 23, C_GREEN_CODE)
            draw_rect(draw, 18, 25, 23, 25, C_CYAN_CODE)
            draw_rect(draw, 18, 27, 26, 27, C_GREEN_CODE)
            draw_pixel(draw, 28, 27, C_SHOES_WHITE)

        # 7. Dave typing hands & arms on keyboard
        if i == 0:
            draw_rect(draw, 15, 26, 17, 30, C_HOODIE_DARK)
            draw_rect(draw, 17, 30, 19, 31, C_SKIN)
            draw_rect(draw, 31, 26, 33, 29, C_HOODIE_BLUE)
            draw_rect(draw, 29, 29, 31, 30, C_SKIN)
        elif i == 1:
            draw_rect(draw, 15, 26, 17, 29, C_HOODIE_DARK)
            draw_rect(draw, 17, 29, 19, 30, C_SKIN)
            draw_rect(draw, 31, 26, 33, 30, C_HOODIE_BLUE)
            draw_rect(draw, 29, 30, 31, 31, C_SKIN)
        elif i == 2:
            draw_rect(draw, 15, 26, 17, 30, C_HOODIE_DARK)
            draw_rect(draw, 18, 30, 20, 31, C_SKIN)
            draw_rect(draw, 31, 26, 33, 30, C_HOODIE_BLUE)
            draw_rect(draw, 28, 30, 30, 31, C_SKIN)
            draw_pixel(draw, 12, 17, C_CYAN_CODE)
        else:
            draw_rect(draw, 15, 26, 17, 29, C_HOODIE_DARK)
            draw_rect(draw, 17, 29, 19, 30, C_SKIN)
            draw_rect(draw, 31, 26, 33, 29, C_HOODIE_BLUE)
            draw_rect(draw, 29, 29, 31, 30, C_SKIN)
            draw_pixel(draw, 36, 17, C_GREEN_CODE)

        save_sprite(img, f"Assets/Sprites/coding/frame_{i}.png")

    # ---------------- DEBUGGING (4 frames: Sitting at Office Desk Thinking) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        # 1. Chair backrest
        draw_rect(draw, 14, 16, 34, 33, C_CHAIR_FRAME)
        draw_rect(draw, 15, 17, 33, 32, C_CHAIR_BACK)
        draw_rect(draw, 15, 17, 16, 32, (60, 68, 80, 255))

        # 2. Dave sitting body & head (head tilts on frames 1 & 2)
        tilt = 1 if i in (1, 2) else 0
        draw_body(draw, offset_y=1, breathe=0)
        draw_head(draw, offset_y=1, eyes_state="open", tilt_x=tilt)

        # 3. Chair seat & legs
        draw_rect(draw, 14, 34, 34, 36, C_CHAIR_CUSHION)
        draw_rect(draw, 23, 37, 25, 41, C_CHAIR_BASE)
        draw_rect(draw, 20, 41, 28, 42, C_CHAIR_FRAME)

        draw_rect(draw, 18, 33, 30, 36, C_PANTS)
        draw_rect(draw, 19, 36, 22, 40, C_PANTS)
        draw_rect(draw, 26, 36, 29, 40, C_PANTS)
        draw_rect(draw, 18, 41, 22, 42, C_SHOES_WHITE)
        draw_pixel(draw, 19, 41, C_SHOES_ORANGE)
        draw_rect(draw, 26, 41, 30, 42, C_SHOES_WHITE)
        draw_pixel(draw, 29, 41, C_SHOES_ORANGE)

        # 4. Office Desk
        draw_rect(draw, 7, 34, 9, 41, C_DESK_LEG)
        draw_rect(draw, 6, 42, 10, 42, C_DESK_LEG_DARK)
        draw_rect(draw, 39, 34, 41, 41, C_DESK_LEG)
        draw_rect(draw, 38, 42, 42, 42, C_DESK_LEG_DARK)

        draw_rect(draw, 6, 31, 42, 31, C_DESK_WOOD_LIGHT)
        draw_rect(draw, 5, 32, 43, 33, C_DESK_WOOD)
        draw_rect(draw, 6, 34, 42, 34, C_DESK_WOOD_DARK)

        # 5. Accessories on desk
        draw_rect(draw, 36, 27, 39, 30, C_MUG_BODY)
        draw_pixel(draw, 37, 28, C_MUG_LOGO)
        draw_pixel(draw, 40, 28, C_MUG_BODY)
        if i % 2 == 0:
            draw_pixel(draw, 37, 25, C_STEAM)
            draw_pixel(draw, 38, 24, C_STEAM)
        else:
            draw_pixel(draw, 38, 25, C_STEAM)
            draw_pixel(draw, 39, 24, C_STEAM)

        draw_rect(draw, 9, 28, 12, 30, C_YELLOW_WARN)
        draw_pixel(draw, 10, 29, (202, 138, 4, 255))

        # 6. Laptop on Desk (displaying Bug or Warning)
        draw_rect(draw, 15, 31, 33, 32, C_LAPTOP)
        draw_rect(draw, 18, 31, 30, 31, (30, 41, 59, 255))
        draw_rect(draw, 16, 21, 32, 30, C_LAPTOP)
        draw_rect(draw, 17, 22, 31, 29, C_LAPTOP_SCREEN)

        draw_rect(draw, 18, 23, 22, 23, C_CYAN_CODE)
        if i in (0, 1):
            draw_rect(draw, 24, 24, 26, 26, C_RED_BUG)
            draw_pixel(draw, 23, 24, C_GLASSES)
            draw_pixel(draw, 27, 24, C_GLASSES)
            draw_pixel(draw, 23, 26, C_GLASSES)
            draw_pixel(draw, 27, 26, C_GLASSES)
        else:
            draw_rect(draw, 24, 24, 26, 26, C_YELLOW_WARN)
            draw_pixel(draw, 25, 25, (0, 0, 0, 255))

        draw_rect(draw, 18, 28, 27, 28, C_CYAN_CODE)

        # 7. Hands: left hand on desk, right hand scratching hair!
        draw_rect(draw, 15, 26, 17, 30, C_HOODIE_DARK)
        draw_rect(draw, 17, 30, 19, 31, C_SKIN)

        draw_rect(draw, 31, 24, 33, 28, C_HOODIE_BLUE)
        draw_rect(draw, 30, 18, 32, 23, C_HOODIE_LIGHT)
        draw_rect(draw, 28, 14, 30, 17, C_SKIN)

        # 8. Floating Question Mark / Sparkle
        if i in (0, 1):
            qy = 4 if i == 0 else 3
            draw_rect(draw, 11, qy, 14, qy, C_YELLOW_WARN)
            draw_pixel(draw, 14, qy + 1, C_YELLOW_WARN)
            draw_rect(draw, 12, qy + 2, 13, qy + 2, C_YELLOW_WARN)
            draw_pixel(draw, 12, qy + 4, C_YELLOW_WARN)
        else:
            qy = 4 if i == 2 else 5
            draw_rect(draw, 38, qy, 41, qy, C_YELLOW_WARN)
            draw_pixel(draw, 41, qy + 1, C_YELLOW_WARN)
            draw_rect(draw, 39, qy + 2, 40, qy + 2, C_YELLOW_WARN)
            draw_pixel(draw, 39, qy + 4, C_YELLOW_WARN)

        save_sprite(img, f"Assets/Sprites/debugging/frame_{i}.png")

    # ---------------- COFFEE (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        eyes = "happy" if i in (1, 2) else "open"
        draw_legs(draw, offset_y=0)
        draw_body(draw, offset_y=0, breathe=0)
        draw_head(draw, offset_y=0, eyes_state=eyes)

        draw_rect(draw, 15, 24, 16, 29, C_HOODIE_DARK)
        draw_rect(draw, 15, 30, 16, 31, C_SKIN)

        if i == 0:
            draw_rect(draw, 32, 24, 33, 28, C_HOODIE_BLUE)
            draw_rect(draw, 29, 27, 31, 28, C_SKIN)
            draw_rect(draw, 26, 26, 29, 30, C_MUG_BODY)
            draw_pixel(draw, 25, 27, C_MUG_BODY)
        elif i in (1, 2):
            draw_rect(draw, 30, 23, 33, 25, C_HOODIE_BLUE)
            draw_rect(draw, 27, 21, 29, 23, C_SKIN)
            draw_rect(draw, 23, 20, 27, 24, C_MUG_BODY)
            draw_pixel(draw, 22, 21, C_MUG_BODY)
            sy = 14 if i == 1 else 13
            draw_pixel(draw, 24, sy, C_STEAM)
            draw_pixel(draw, 25, sy - 2, C_STEAM)
            draw_pixel(draw, 27, sy - 1, C_STEAM)
            draw_pixel(draw, 28, sy - 3, C_STEAM)
        else:
            draw_rect(draw, 32, 24, 33, 28, C_HOODIE_BLUE)
            draw_rect(draw, 29, 27, 31, 28, C_SKIN)
            draw_rect(draw, 26, 26, 29, 30, C_MUG_BODY)
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

        breathe = 1 if i in (1, 2) else 0
        draw_legs(draw, offset_y=3)
        draw_body(draw, offset_y=3, breathe=-breathe)
        draw_head(draw, offset_y=3 + breathe, eyes_state="sleep")

        draw_rect(draw, 18, 29, 30, 31, C_HOODIE_DARK)
        draw_rect(draw, 21, 30, 27, 31, C_SKIN)

        zx, zy = 34 + (i * 2), 12 - (i * 2)
        draw_rect(draw, zx, zy, zx + 3, zy, C_ZZZ)
        draw_pixel(draw, zx + 2, zy + 1, C_ZZZ)
        draw_pixel(draw, zx + 1, zy + 2, C_ZZZ)
        draw_rect(draw, zx, zy + 3, zx + 3, zy + 3, C_ZZZ)

        save_sprite(img, f"Assets/Sprites/sleeping/frame_{i}.png")

    # ---------------- DRAGGED (4 frames) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        draw_legs(draw, offset_y=-2, dangling=True, leg_frame=i)
        draw_rect(draw, 17, 18, 31, 30, C_HOODIE_BLUE)
        draw_rect(draw, 17, 28, 31, 30, C_HOODIE_DARK)

        draw_rect(draw, 13, 16, 16, 22, C_HOODIE_BLUE)
        draw_rect(draw, 12, 14, 14, 16, C_SKIN)

        draw_rect(draw, 32, 16, 35, 22, C_HOODIE_BLUE)
        draw_rect(draw, 34, 14, 36, 16, C_SKIN)

        draw_head(draw, offset_y=-4, eyes_state="wide")

        if i in (1, 2):
            draw_pixel(draw, 33, 12, C_CYAN_CODE)
            draw_pixel(draw, 33, 13, C_CYAN_CODE)

        save_sprite(img, f"Assets/Sprites/dragged/frame_{i}.png")

    # ---------------- RUNNING (4 frames) - Dave running to fetch file ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        hop = 1 if i in (1, 3) else 0
        lean = 1  # Leaning forward

        draw_running_legs(draw, frame=i, offset_y=-hop)
        draw_body(draw, offset_y=-hop, breathe=0, lean_x=lean)
        draw_head(draw, offset_y=-hop, eyes_state="open", tilt_x=lean)

        # Swinging arms (runner pose)
        if i == 0:
            # Left arm forward, right arm back
            draw_rect(draw, 13, 24 - hop, 15, 28 - hop, C_HOODIE_DARK)
            draw_rect(draw, 12, 27 - hop, 14, 29 - hop, C_SKIN)
            draw_rect(draw, 32, 23 - hop, 34, 27 - hop, C_HOODIE_BLUE)
            draw_rect(draw, 34, 25 - hop, 36, 27 - hop, C_SKIN)
        elif i == 1:
            draw_rect(draw, 15, 23 - hop, 17, 27 - hop, C_HOODIE_DARK)
            draw_rect(draw, 31, 23 - hop, 33, 27 - hop, C_HOODIE_BLUE)
        elif i == 2:
            # Right arm forward, left arm back
            draw_rect(draw, 14, 23 - hop, 16, 27 - hop, C_HOODIE_DARK)
            draw_rect(draw, 13, 25 - hop, 15, 27 - hop, C_SKIN)
            draw_rect(draw, 33, 24 - hop, 35, 28 - hop, C_HOODIE_BLUE)
            draw_rect(draw, 34, 27 - hop, 36, 29 - hop, C_SKIN)
        else:
            draw_rect(draw, 15, 23 - hop, 17, 27 - hop, C_HOODIE_DARK)
            draw_rect(draw, 31, 23 - hop, 33, 27 - hop, C_HOODIE_BLUE)

        # Sweat/speed lines
        if i in (0, 2):
            draw_pixel(draw, 9, 26, C_CYAN_CODE)
            draw_pixel(draw, 10, 26, C_CYAN_CODE)

        save_sprite(img, f"Assets/Sprites/running/frame_{i}.png")

    # ---------------- CARRYING (4 frames) - Carrying file above head to Trash ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        hop = 1 if i in (1, 3) else 0

        draw_running_legs(draw, frame=i, offset_y=-hop)
        draw_body(draw, offset_y=-hop, breathe=0)
        draw_head(draw, offset_y=-hop, eyes_state="wide")

        # Both arms raised high holding the file!
        draw_rect(draw, 14, 15 - hop, 17, 23 - hop, C_HOODIE_BLUE)
        draw_rect(draw, 14, 13 - hop, 17, 15 - hop, C_SKIN)

        draw_rect(draw, 31, 15 - hop, 34, 23 - hop, C_HOODIE_BLUE)
        draw_rect(draw, 31, 13 - hop, 34, 15 - hop, C_SKIN)

        # File held aloft above head
        draw_file_document(draw, 19, 4 - hop)

        save_sprite(img, f"Assets/Sprites/carrying/frame_{i}.png")

    # ---------------- THROWING (4 frames) - Slam dunk into Dock Trash ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        if i == 0:
            # Windup: leaning back, file cocked
            draw_legs(draw, offset_y=0)
            draw_body(draw, offset_y=0, breathe=0, lean_x=-1)
            draw_head(draw, offset_y=0, eyes_state="wide", tilt_x=-1)

            draw_rect(draw, 13, 14, 16, 21, C_HOODIE_BLUE)
            draw_rect(draw, 13, 12, 15, 14, C_SKIN)
            draw_rect(draw, 30, 16, 33, 23, C_HOODIE_BLUE)
            draw_rect(draw, 30, 14, 32, 16, C_SKIN)
            draw_file_document(draw, 15, 3)
        elif i == 1:
            # Leaping throw: in air, hands hurled forward/down!
            draw_legs(draw, offset_y=-3, dangling=True, leg_frame=0)
            draw_body(draw, offset_y=-3, breathe=0, lean_x=2)
            draw_head(draw, offset_y=-3, eyes_state="happy", tilt_x=2)

            draw_rect(draw, 29, 17, 33, 24, C_HOODIE_BLUE)
            draw_rect(draw, 33, 21, 36, 24, C_SKIN)
            # File mid-air sailing down
            draw_file_document(draw, 35, 15)
        elif i == 2:
            # Follow through, file falling into trash
            draw_legs(draw, offset_y=0)
            draw_body(draw, offset_y=1, breathe=0, lean_x=1)
            draw_head(draw, offset_y=1, eyes_state="happy", tilt_x=1)

            draw_rect(draw, 28, 24, 32, 30, C_HOODIE_BLUE)
            draw_rect(draw, 30, 29, 33, 31, C_SKIN)
            # File lower down
            draw_file_document(draw, 37, 28)
            # Trash sparkle / splash
            draw_pixel(draw, 40, 25, C_CYAN_CODE)
            draw_pixel(draw, 43, 24, C_GREEN_CODE)
        else:
            # Swish! Dunk done!
            draw_legs(draw, offset_y=0)
            draw_body(draw, offset_y=0, breathe=0)
            draw_head(draw, offset_y=0, eyes_state="happy")

            draw_rect(draw, 15, 24, 17, 29, C_HOODIE_DARK)
            draw_rect(draw, 31, 24, 33, 29, C_HOODIE_BLUE)
            # Stars/sparkles above trash
            draw_pixel(draw, 39, 30, (250, 204, 21, 255))
            draw_pixel(draw, 42, 28, (250, 204, 21, 255))
            draw_pixel(draw, 40, 26, (59, 130, 246, 255))

        save_sprite(img, f"Assets/Sprites/throwing/frame_{i}.png")

    # ---------------- CELEBRATING (4 frames) - Happy victory ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        bounce = 2 if i in (1, 2) else 0

        draw_legs(draw, offset_y=-bounce)
        draw_body(draw, offset_y=-bounce, breathe=0)
        draw_head(draw, offset_y=-bounce, eyes_state="happy")

        # Hands raised in victory V
        draw_rect(draw, 13, 14 - bounce, 16, 22 - bounce, C_HOODIE_BLUE)
        draw_rect(draw, 12, 12 - bounce, 15, 14 - bounce, C_SKIN)

        draw_rect(draw, 32, 14 - bounce, 35, 22 - bounce, C_HOODIE_BLUE)
        draw_rect(draw, 33, 12 - bounce, 36, 14 - bounce, C_SKIN)

        # Confetti / stars
        if i in (1, 2):
            draw_pixel(draw, 9, 8, (239, 68, 68, 255))
            draw_pixel(draw, 38, 7, (250, 204, 21, 255))
            draw_pixel(draw, 24, 4, (34, 197, 94, 255))
            draw_pixel(draw, 12, 5, (56, 189, 248, 255))

        save_sprite(img, f"Assets/Sprites/celebrating/frame_{i}.png")

    # ---------------- SWEATING (4 frames: CPU High Load / Overheating) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        # 1. Chair backrest
        draw_rect(draw, 14, 16, 34, 33, C_CHAIR_FRAME)
        draw_rect(draw, 15, 17, 33, 32, C_CHAIR_BACK)

        # 2. Dave body & head (panting mouth / sweat on face)
        draw_body(draw, offset_y=1, breathe=1 if i in (1, 3) else 0)
        draw_head(draw, offset_y=1, eyes_state="wide")

        # Panting mouth
        draw_rect(draw, 23, 20, 25, 21, (239, 68, 68, 255))
        draw_pixel(draw, 24, 21, (254, 202, 202, 255))

        # Sweat drops on face
        if i in (0, 1):
            draw_pixel(draw, 17, 13, (56, 189, 248, 255))
            draw_pixel(draw, 18, 14, (186, 230, 253, 255))
            draw_pixel(draw, 31, 14, (56, 189, 248, 255))
        else:
            draw_pixel(draw, 16, 15, (56, 189, 248, 255))
            draw_pixel(draw, 17, 16, (186, 230, 253, 255))
            draw_pixel(draw, 31, 16, (56, 189, 248, 255))
            draw_pixel(draw, 32, 17, (186, 230, 253, 255))

        # 3. Chair seat & legs
        draw_rect(draw, 14, 34, 34, 36, C_CHAIR_CUSHION)
        draw_rect(draw, 23, 37, 25, 41, C_CHAIR_BASE)
        draw_rect(draw, 20, 41, 28, 42, C_CHAIR_FRAME)
        draw_rect(draw, 18, 33, 30, 36, C_PANTS)
        draw_rect(draw, 19, 36, 22, 40, C_PANTS)
        draw_rect(draw, 26, 36, 29, 40, C_PANTS)
        draw_rect(draw, 18, 41, 22, 42, C_SHOES_WHITE)
        draw_pixel(draw, 19, 41, C_SHOES_ORANGE)
        draw_rect(draw, 26, 41, 30, 42, C_SHOES_WHITE)
        draw_pixel(draw, 29, 41, C_SHOES_ORANGE)

        # 4. Office Desk
        draw_rect(draw, 7, 34, 9, 41, C_DESK_LEG)
        draw_rect(draw, 6, 42, 10, 42, C_DESK_LEG_DARK)
        draw_rect(draw, 39, 34, 41, 41, C_DESK_LEG)
        draw_rect(draw, 38, 42, 42, 42, C_DESK_LEG_DARK)
        draw_rect(draw, 6, 31, 42, 31, C_DESK_WOOD_LIGHT)
        draw_rect(draw, 5, 32, 43, 33, C_DESK_WOOD)
        draw_rect(draw, 6, 34, 42, 34, C_DESK_WOOD_DARK)

        # 5. Overheating Laptop with red screen & fire/heat wave sparks!
        draw_rect(draw, 15, 31, 33, 32, C_LAPTOP)
        draw_rect(draw, 16, 21, 32, 30, C_LAPTOP)
        draw_rect(draw, 17, 22, 31, 29, (185, 28, 28, 255))
        if i % 2 == 0:
            draw_pixel(draw, 21, 18, (249, 115, 22, 255))
            draw_pixel(draw, 27, 17, (239, 68, 68, 255))
            draw_pixel(draw, 24, 19, (250, 204, 21, 255))
        else:
            draw_pixel(draw, 20, 19, (239, 68, 68, 255))
            draw_pixel(draw, 28, 18, (249, 115, 22, 255))
            draw_pixel(draw, 25, 17, (250, 204, 21, 255))

        # 6. Dave Waving a Hand Fan (扇子) with right hand!
        draw_rect(draw, 15, 26, 17, 30, C_HOODIE_DARK)
        draw_rect(draw, 16, 22, 18, 25, C_SKIN)

        if i in (0, 2):
            draw_rect(draw, 31, 24, 34, 27, C_HOODIE_BLUE)
            draw_rect(draw, 34, 22, 36, 25, C_SKIN)
            draw_rect(draw, 36, 17, 41, 23, (224, 242, 254, 255))
            draw_rect(draw, 37, 18, 40, 22, (56, 189, 248, 255))
            draw_pixel(draw, 33, 18, (186, 230, 253, 200))
            draw_pixel(draw, 32, 20, (186, 230, 253, 200))
        else:
            draw_rect(draw, 31, 24, 34, 27, C_HOODIE_BLUE)
            draw_rect(draw, 33, 24, 35, 27, C_SKIN)
            draw_rect(draw, 34, 20, 39, 26, (224, 242, 254, 255))
            draw_rect(draw, 35, 21, 38, 25, (56, 189, 248, 255))
            draw_pixel(draw, 30, 21, (186, 230, 253, 200))
            draw_pixel(draw, 29, 23, (186, 230, 253, 200))

        save_sprite(img, f"Assets/Sprites/sweating/frame_{i}.png")

    # ---------------- PEEKING (4 frames: Clinging to Screen Edge & Peeking) ----------------
    for i in range(4):
        img = create_canvas()
        draw = ImageDraw.Draw(img)

        bob_x = 1 if i in (1, 3) else 0
        bob_y = -1 if i == 1 else 0

        hx = 9 + bob_x
        hy = 18 + bob_y

        # Small shoulder curve tucked behind bezel
        draw_rect(draw, 0, hy + 3, hx - 1, hy + 7, C_HOODIE_BLUE)
        draw_rect(draw, 0, hy + 6, hx - 2, hy + 8, C_HOODIE_DARK)

        # Hair back
        draw_rect(draw, 0, hy - 6, hx + 4, hy - 4, C_HAIR_DARK)
        draw_rect(draw, 1, hy - 7, hx + 3, hy - 5, C_HAIR_MID)
        draw_pixel(draw, hx, hy - 7, C_HAIR_LIGHT)
        draw_pixel(draw, hx + 3, hy - 5, C_HAIR_MID)

        # Head / Skin
        draw_rect(draw, hx - 4, hy - 3, hx + 4, hy + 3, C_SKIN)
        draw_rect(draw, hx - 3, hy + 3, hx + 2, hy + 4, C_SKIN_SHADOW)
        draw_pixel(draw, hx + 3, hy + 2, C_BLUSH)

        # Hair bangs
        draw_rect(draw, hx - 3, hy - 4, hx + 2, hy - 2, C_HAIR_MID)
        draw_rect(draw, hx - 1, hy - 3, hx + 3, hy - 1, C_HAIR_DARK)
        draw_pixel(draw, hx + 1, hy, C_HAIR_DARK)

        # Big Glasses
        draw_rect(draw, hx - 1, hy - 1, hx + 5, hy - 1, C_GLASSES)
        draw_rect(draw, hx - 1, hy + 3, hx + 5, hy + 3, C_GLASSES)
        draw_rect(draw, hx - 1, hy - 1, hx - 1, hy + 3, C_GLASSES)
        draw_rect(draw, hx + 5, hy - 1, hx + 5, hy + 3, C_GLASSES)
        draw_pixel(draw, hx - 2, hy, C_GLASSES)
        draw_rect(draw, hx, hy, hx + 4, hy + 2, C_GLASSES_LENS)

        # Eye
        if i == 2:
            # Blink / wink
            draw_pixel(draw, hx + 1, hy + 1, C_EYE)
            draw_pixel(draw, hx + 2, hy + 1, C_EYE)
            draw_pixel(draw, hx + 3, hy + 1, C_EYE)
        else:
            # Looking into screen
            draw_rect(draw, hx + 1, hy, hx + 3, hy + 2, C_EYE)
            draw_pixel(draw, hx + 3, hy, (255, 255, 255, 255))

        # Mouth
        draw_pixel(draw, hx, hy + 3, (220, 38, 38, 255))
        draw_pixel(draw, hx + 1, hy + 3, (220, 38, 38, 255))

        # Two little paws gripping bezel at x=0
        draw_rect(draw, 0, hy - 2, 2, hy, C_SKIN)
        draw_pixel(draw, 2, hy - 2, C_SKIN_SHADOW)
        draw_pixel(draw, 2, hy, C_SKIN_SHADOW)

        draw_rect(draw, 0, hy + 4, 2, hy + 6, C_SKIN)
        draw_pixel(draw, 2, hy + 4, C_SKIN_SHADOW)
        draw_pixel(draw, 2, hy + 6, C_SKIN_SHADOW)

        # Sparkle on frame 3
        if i == 3:
            draw_pixel(draw, hx + 5, hy - 3, (250, 204, 21, 255))
            draw_pixel(draw, hx + 6, hy - 2, (250, 204, 21, 255))

        save_sprite(img, f"Assets/Sprites/peeking/frame_{i}.png")

    print("Successfully generated all sprite frames including running, carrying, throwing, celebrating!")


if __name__ == "__main__":
    generate_all()
