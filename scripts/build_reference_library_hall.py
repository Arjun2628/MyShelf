import bpy
import math
import os
import random

# -------------------------------------------------------------
# 1. Scene Reset & High-Quality EEVEE Setup
# -------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderEngine.__subclasses__() else 'BLENDER_EEVEE'
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGB'

# Setup Bright Ambient Daylight World
world = bpy.data.worlds.new("BrightDaylightLibraryWorld")
scene.world = world
world.use_nodes = True
bg_node = world.node_tree.nodes.get("Background")
if bg_node:
    bg_node.inputs['Color'].default_value = (0.94, 0.92, 0.88, 1.0)
    bg_node.inputs['Strength'].default_value = 1.6

# Add Warm Sunlight pouring through the arched windows
sun_data = bpy.data.lights.new(name="SunlightThroughWindow", type='SUN')
sun_data.energy = 4.5
sun_data.color = (1.0, 0.96, 0.88)
sun_obj = bpy.data.objects.new(name="SunlightObj", object_data=sun_data)
sun_obj.rotation_euler = (math.radians(45.0), math.radians(-15.0), math.radians(25.0))
scene.collection.objects.link(sun_obj)

# -------------------------------------------------------------
# 2. Photorealistic Architectural Materials
# -------------------------------------------------------------
def create_material(name, color, roughness=0.5, metallic=0.0, emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
        if emission_color:
            if 'Emission Color' in bsdf.inputs:
                bsdf.inputs['Emission Color'].default_value = emission_color
                bsdf.inputs['Emission Strength'].default_value = emission_strength
            elif 'Emission' in bsdf.inputs:
                bsdf.inputs['Emission'].default_value = emission_color
    return mat

# Polished light cream/beige marble floor with soft specular reflections (Matching reference)
mat_marble_floor = create_material("PolishedMarbleFloor", (0.88, 0.85, 0.80, 1.0), roughness=0.12, metallic=0.08)

# Warm sandstone / alabaster walls & pillars
mat_alabaster_wall = create_material("AlabasterStone", (0.94, 0.92, 0.88, 1.0), roughness=0.55)
mat_coffered_ceiling = create_material("CofferedCeiling", (0.90, 0.88, 0.85, 1.0), roughness=0.6)

# Rich medium-dark oak wood for bookcases
mat_oak_wood = create_material("OakBookcaseWood", (0.28, 0.16, 0.08, 1.0), roughness=0.35)
mat_dark_signboard = create_material("DarkSignboardWood", (0.10, 0.10, 0.10, 1.0), roughness=0.45)
mat_signboard_text = create_material("SignboardWhiteText", (0.98, 0.98, 0.98, 1.0), roughness=0.2, emission_color=(1.0, 1.0, 1.0, 1.0), emission_strength=2.5)

# Plant materials (green foliage & ceramic white pot)
mat_plant_leaf = create_material("PlantLeaf", (0.12, 0.42, 0.14, 1.0), roughness=0.3)
mat_plant_pot = create_material("WhiteCeramicPot", (0.96, 0.96, 0.94, 1.0), roughness=0.18)

# Brass / Bronze for lamps
mat_brass_metal = create_material("BronzeLamp", (0.88, 0.72, 0.30, 1.0), roughness=0.25, metallic=0.9)
mat_warm_glow = create_material("WarmPendantGlow", (1.0, 0.90, 0.70, 1.0), roughness=0.1, emission_color=(1.0, 0.90, 0.70, 1.0), emission_strength=16.0)

# Window daylight material
mat_daylight_window = create_material("DaylightGlass", (0.96, 0.98, 1.0, 1.0), roughness=0.05, emission_color=(0.96, 0.98, 1.0, 1.0), emission_strength=8.0)

# Realistic Multi-Colored Book Spines
book_mats = [
    create_material("SpineNavy", (0.10, 0.20, 0.42, 1.0), roughness=0.35),
    create_material("SpineCrimson", (0.48, 0.08, 0.10, 1.0), roughness=0.35),
    create_material("SpineEmerald", (0.08, 0.30, 0.16, 1.0), roughness=0.35),
    create_material("SpineGoldLeaf", (0.78, 0.62, 0.22, 1.0), roughness=0.25, metallic=0.3),
    create_material("SpineAmber", (0.55, 0.35, 0.12, 1.0), roughness=0.45),
    create_material("SpineLeatherBrown", (0.24, 0.12, 0.05, 1.0), roughness=0.5),
    create_material("SpineParchment", (0.88, 0.84, 0.76, 1.0), roughness=0.4),
    create_material("SpineRoyalBlue", (0.08, 0.16, 0.50, 1.0), roughness=0.35),
]

# -------------------------------------------------------------
# 3. Main Grand Library Hall Architecture (Width=14m, Length=32m, Height=6.0m)
# -------------------------------------------------------------
# 1. Polished Marble Floor
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.1))
floor = bpy.context.active_object
floor.name = "MarbleFloor"
floor.scale = (16.0, 36.0, 0.2)
floor.data.materials.append(mat_marble_floor)

# 2. High Coffered Ceiling
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 6.1))
ceiling = bpy.context.active_object
ceiling.name = "VaultCeiling"
ceiling.scale = (16.0, 36.0, 0.2)
ceiling.data.materials.append(mat_coffered_ceiling)

# 3. Side Walls
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-7.0, 0, 3.0))
wall_left = bpy.context.active_object
wall_left.name = "WallLeft"
wall_left.scale = (0.2, 36.0, 6.0)
wall_left.data.materials.append(mat_alabaster_wall)

bpy.ops.mesh.primitive_cube_add(size=1.0, location=(7.0, 0, 3.0))
wall_right = bpy.context.active_object
wall_right.name = "WallRight"
wall_right.scale = (0.2, 36.0, 6.0)
wall_right.data.materials.append(mat_alabaster_wall)

# 4. Far End Wall with Large Arched Window (Y = 16.0)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 16.0, 3.0))
wall_end = bpy.context.active_object
wall_end.name = "WallEnd"
wall_end.scale = (16.0, 0.2, 6.0)
wall_end.data.materials.append(mat_alabaster_wall)

# Arched Window Pane in the center of the far wall
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 15.9, 3.4))
window = bpy.context.active_object
window.name = "ArchedDaylightWindow"
window.scale = (4.8, 0.1, 4.2)
window.data.materials.append(mat_daylight_window)

# 5. Far End Study Desk & Chairs in front of the window
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 13.5, 0.45))
desk = bpy.context.active_object
desk.name = "StudyDesk"
desk.scale = (3.2, 1.4, 0.9)
desk.data.materials.append(mat_oak_wood)

# -------------------------------------------------------------
# 4. Classical Pillars & Symmetrical Arches Along the Walkway
# -------------------------------------------------------------
for y_pos in [-8.0, -2.0, 4.0, 10.0]:
    for x_pos in [-4.2, 4.2]:
        # Square Pillar
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x_pos, y_pos, 3.0))
        pillar = bpy.context.active_object
        pillar.name = f"Pillar_{x_pos}_{y_pos}"
        pillar.scale = (0.7, 0.7, 6.0)
        pillar.data.materials.append(mat_alabaster_wall)

# -------------------------------------------------------------
# 5. Warm Hanging Bronze Pendant Dome Lamps Along Central Walkway
# -------------------------------------------------------------
for y_pos in [-6.0, 0.0, 6.0, 12.0]:
    # Brass hanging rod
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, y_pos, 4.8))
    rod = bpy.context.active_object
    rod.scale = (0.04, 0.04, 1.6)
    rod.data.materials.append(mat_brass_metal)

    # Bronze Dome Shade
    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=0.25, location=(0, y_pos, 4.0))
    dome = bpy.context.active_object
    dome.data.materials.append(mat_brass_metal)

    # Warm Light Bulb
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.18, location=(0, y_pos, 3.85))
    bulb = bpy.context.active_object
    bulb.data.materials.append(mat_warm_glow)

    # Point Light
    lamp_data = bpy.data.lights.new(name=f"PendantLight_{y_pos}", type='POINT')
    lamp_data.energy = 160.0
    lamp_data.color = (1.0, 0.90, 0.74)
    lamp_data.shadow_soft_size = 0.35
    lamp_obj = bpy.data.objects.new(name=f"PendantLightObj_{y_pos}", object_data=lamp_data)
    lamp_obj.location = (0, y_pos, 3.75)
    scene.collection.objects.link(lamp_obj)

# -------------------------------------------------------------
# 6. Builder for Authentic Wooden Bookcase Units with Dark Signboards & Plants
# -------------------------------------------------------------
def build_reference_bookcase_unit(x, y, z_rot_deg, title, width=3.4, height=2.8, depth=0.85):
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(x, y, 0.0))
    parent = bpy.context.active_object
    parent.name = f"BookcaseUnit_{title}"
    parent.rotation_euler = (0, 0, math.radians(z_rot_deg))

    # 1. Main Oak Wooden Body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, height / 2.0))
    body = bpy.context.active_object
    body.name = f"Body_{title}"
    body.scale = (width, depth, height)
    body.data.materials.append(mat_oak_wood)
    body.parent = parent

    # 2. Dark Header Signboard with Title
    sign_h = 0.48
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, depth / 2.0 + 0.02, height - sign_h / 2.0 - 0.06))
    signboard = bpy.context.active_object
    signboard.name = f"Signboard_{title}"
    signboard.scale = (width - 0.3, 0.06, sign_h)
    signboard.data.materials.append(mat_dark_signboard)
    signboard.parent = parent

    # White Title Text Bar on the Signboard
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, depth / 2.0 + 0.06, height - sign_h / 2.0 - 0.06))
    title_bar = bpy.context.active_object
    title_bar.name = f"TitleBar_{title}"
    title_bar.scale = (width * 0.5, 0.02, 0.16)
    title_bar.data.materials.append(mat_signboard_text)
    title_bar.parent = parent

    # 3. Shelf Compartments & Realistic Book Rows (3 main visible tiers)
    tier_count = 3
    tier_h = (height - sign_h - 0.4) / tier_count

    for t in range(tier_count):
        tz = 0.25 + t * tier_h

        # Shelf divider plank
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, depth / 4.0, tz))
        shelf_plank = bpy.context.active_object
        shelf_plank.scale = (width - 0.3, depth * 0.75, 0.05)
        shelf_plank.data.materials.append(mat_oak_wood)
        shelf_plank.parent = parent

        # Row of Books on this tier
        book_count = 20
        start_x = -(width - 0.5) / 2.0
        spacing = (width - 0.5) / book_count

        for b in range(book_count):
            bx = start_x + (b + 0.5) * spacing
            bh = random.uniform(0.36, 0.48)
            bw = random.uniform(0.045, 0.065)
            bd = random.uniform(0.32, 0.38)
            bz = tz + 0.025 + bh / 2.0

            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx, depth / 4.0 + 0.05, bz))
            book = bpy.context.active_object
            book.scale = (bw, bd, bh)
            book.data.materials.append(random.choice(book_mats))
            book.parent = parent

    # 4. Green Potted Plant on top of the bookcase (Matching reference image)
    # White ceramic pot
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.22, location=(-width / 3.0, 0, height + 0.11))
    pot = bpy.context.active_object
    pot.data.materials.append(mat_plant_pot)
    pot.parent = parent

    # Green foliage sphere cluster
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.28, location=(-width / 3.0, 0, height + 0.32))
    foliage = bpy.context.active_object
    foliage.scale = (1.0, 1.0, 0.7)
    foliage.data.materials.append(mat_plant_leaf)
    foliage.parent = parent

    return parent

# -------------------------------------------------------------
# 7. Symmetrical Hallway Bookcase Placement (Matching Reference Screen 1 & Screen 6)
# -------------------------------------------------------------
# Left Side Bookcases:
# 1. Fiction (Aisle 1 Left)
build_reference_bookcase_unit(x=-2.6, y=2.0, z_rot_deg=0, title="Fiction")
# 2. Technology (Aisle 2 Left)
build_reference_bookcase_unit(x=-2.6, y=-4.0, z_rot_deg=0, title="Technology")
# 3. History (Aisle 3 Left - Near Entrance)
build_reference_bookcase_unit(x=-2.6, y=8.0, z_rot_deg=0, title="History")

# Right Side Bookcases:
# 1. Science (Aisle 1 Right)
build_reference_bookcase_unit(x=2.6, y=2.0, z_rot_deg=0, title="Science")
# 2. Comics (Aisle 2 Right)
build_reference_bookcase_unit(x=2.6, y=-4.0, z_rot_deg=0, title="Comics")
# 3. Arts (Aisle 3 Right - Near Entrance)
build_reference_bookcase_unit(x=2.6, y=8.0, z_rot_deg=0, title="Arts")

# -------------------------------------------------------------
# 8. Render Cameras & Passes (Matching Reference Image Views)
# -------------------------------------------------------------
cam_data = bpy.data.cameras.new(name="MainHallwayCam")
cam_data.lens = 20
cam_data.clip_start = 0.1
cam_data.clip_end = 100.0
cam_obj = bpy.data.objects.new(name="MainHallwayCamObj", object_data=cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

def render_pass(output_path, loc, rot_deg, lens=20):
    cam_data.lens = lens
    cam_obj.location = loc
    cam_obj.rotation_euler = (
        math.radians(rot_deg[0]),
        math.radians(rot_deg[1]),
        math.radians(rot_deg[2])
    )
    scene.render.filepath = output_path
    print(f"Rendering {output_path} at loc={loc}, rot={rot_deg}, lens={lens}")
    bpy.ops.render.render(write_still=True)

# 1. Main Central Hallway View (Screen 1 & 5: Looking down walkway with Fiction on left, Science on right, window ahead)
render_pass(os.path.abspath("assets/blender_room_north_hall.png"), loc=(0.0, -1.5, 1.55), rot_deg=(90.0, 0.0, 0.0), lens=20)
render_pass(os.path.abspath("assets/blender_hall_walk_1.png"), loc=(0.0, -1.5, 1.55), rot_deg=(90.0, 0.0, 0.0), lens=20)

# 2. Facing Science Bookcase (Screen 2: Close-up facing the Science shelf with plant on top)
render_pass(os.path.abspath("assets/blender_room_east_wing.png"), loc=(2.6, -0.6, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=24)
render_pass(os.path.abspath("assets/blender_shelf_scifi.png"), loc=(2.6, 0.5, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=32)

# 3. Facing Fiction Bookcase (Close-up)
render_pass(os.path.abspath("assets/blender_room_south_study.png"), loc=(-2.6, -0.6, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=24)
render_pass(os.path.abspath("assets/blender_shelf_mystery.png"), loc=(-2.6, 0.5, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=32)

# 4. Facing History Bookcase
render_pass(os.path.abspath("assets/blender_room_west_pavilion.png"), loc=(-2.6, 5.4, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=24)
render_pass(os.path.abspath("assets/blender_shelf_history.png"), loc=(-2.6, 6.5, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=32)

# 5. Facing Comics Bookcase
render_pass(os.path.abspath("assets/blender_room_balcony.png"), loc=(2.6, -6.6, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=24)
render_pass(os.path.abspath("assets/blender_shelf_fantasy.png"), loc=(2.6, -5.5, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=32)

# 6. Facing Technology Bookcase
render_pass(os.path.abspath("assets/blender_room_reading_nook.png"), loc=(-2.6, -6.6, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=24)
render_pass(os.path.abspath("assets/blender_shelf_sleep.png"), loc=(-2.6, -5.5, 1.50), rot_deg=(90.0, 0.0, 0.0), lens=32)

# 7. Top-Down Library Map (Screen 6: Top-down floor view showing symmetrical aisles & sections)
render_pass(os.path.abspath("assets/library_top_down_map.png"), loc=(0.0, 2.0, 18.0), rot_deg=(0.0, 0.0, 0.0), lens=20)

# Save .blend file
blend_path = os.path.abspath("assets/library_corridor.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(f"=== REFERENCE LIBRARY ROOM MODEL RENDERED TO {blend_path} ===")
