import bpy
import math
import os
import random

# Reset scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderEngine.__subclasses__() else 'BLENDER_EEVEE'
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'

# Create Materials
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

# Architectural Library Materials (Realistic Woods & Classical Stone)
mat_oak_floor = create_material("ParquetFloor", (0.32, 0.20, 0.12, 1.0), roughness=0.25, metallic=0.03)
mat_white_wall = create_material("AlabasterWall", (0.94, 0.94, 0.95, 1.0), roughness=0.6)
mat_rich_oak_shelf = create_material("RichOakWood", (0.28, 0.16, 0.08, 1.0), roughness=0.38)
mat_dark_walnut_shelf = create_material("DarkWalnutWood", (0.16, 0.09, 0.04, 1.0), roughness=0.42)
mat_brass_gold = create_material("BrassPlaque", (0.88, 0.72, 0.25, 1.0), roughness=0.22, metallic=0.92)
mat_vault_ceiling = create_material("VaultCeiling", (0.96, 0.96, 0.97, 1.0), roughness=0.5)
mat_warm_chandelier = create_material("WarmChandelier", (1.0, 0.92, 0.75, 1.0), roughness=0.1, emission_color=(1.0, 0.90, 0.70, 1.0), emission_strength=14.0)
mat_skylight = create_material("DaylightSkylight", (0.95, 0.98, 1.0, 1.0), roughness=0.05, emission_color=(0.95, 0.98, 1.0, 1.0), emission_strength=5.0)

# Book Spines Materials
book_mats = [
    create_material("SpineNavy", (0.10, 0.20, 0.45, 1.0), roughness=0.35),
    create_material("SpineCrimson", (0.52, 0.08, 0.10, 1.0), roughness=0.35),
    create_material("SpineEmerald", (0.08, 0.32, 0.16, 1.0), roughness=0.35),
    create_material("SpineGoldLeaf", (0.82, 0.65, 0.22, 1.0), roughness=0.25, metallic=0.4),
    create_material("SpineAmber", (0.58, 0.38, 0.12, 1.0), roughness=0.45),
    create_material("SpineLeatherBrown", (0.26, 0.14, 0.06, 1.0), roughness=0.5),
    create_material("SpineParchment", (0.90, 0.86, 0.78, 1.0), roughness=0.4),
    create_material("SpineRoyalBlue", (0.06, 0.15, 0.52, 1.0), roughness=0.35),
]

# 1. Main Grand Library Room Structure (Cross-Rotunda & 6 Corners, 24m x 24m, Height = 5.2m)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.1))
floor = bpy.context.active_object
floor.name = "LibraryFloor"
floor.scale = (24.0, 24.0, 0.2)
floor.data.materials.append(mat_oak_floor)

bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 5.3))
ceiling = bpy.context.active_object
ceiling.name = "LibraryCeiling"
ceiling.scale = (24.0, 24.0, 0.2)
ceiling.data.materials.append(mat_vault_ceiling)

# Outer Room Walls (North, South, East, West)
walls = [
    ("NorthWall", (0, 12.0, 2.6), (24.0, 0.2, 5.2)),
    ("SouthWall", (0, -12.0, 2.6), (24.0, 0.2, 5.2)),
    ("EastWall", (12.0, 0, 2.6), (0.2, 24.0, 5.2)),
    ("WestWall", (-12.0, 0, 2.6), (0.2, 24.0, 5.2)),
]
for w_name, loc, sc in walls:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    w = bpy.context.active_object
    w.name = w_name
    w.scale = sc
    w.data.materials.append(mat_white_wall)

# Skylight Glass Dome in Center
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 5.28))
skylight = bpy.context.active_object
skylight.name = "CenterSkylight"
skylight.scale = (8.0, 8.0, 0.05)
skylight.data.materials.append(mat_skylight)

# 2. Builder function for authentic Multi-Tier Realistic Wooden Bookcases
def build_multi_tier_wooden_bookcase(x, y, z_rot_deg, cat_id, title, width=5.2, height=4.4, is_dark_wood=False):
    wood_mat = mat_dark_walnut_shelf if is_dark_wood else mat_rich_oak_shelf
    
    # Base Box for positioning
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(x, y, 0.0))
    parent_obj = bpy.context.active_object
    parent_obj.name = f"BookcaseGroup_{cat_id}"
    parent_obj.rotation_euler = (0, 0, math.radians(z_rot_deg))
    
    # Outer Wooden Carved Frame (Backing & Pillars)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, height / 2.0))
    frame = bpy.context.active_object
    frame.name = f"BookcaseFrame_{cat_id}"
    frame.scale = (width, 0.6, height)
    frame.data.materials.append(wood_mat)
    frame.parent = parent_obj
    
    # Left & Right Decorative Fluted Wooden Pilasters
    for p_x in [-width / 2.0 + 0.15, width / 2.0 - 0.15]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(p_x, 0.15, height / 2.0))
        p = bpy.context.active_object
        p.name = f"Pilaster_{cat_id}_{p_x}"
        p.scale = (0.3, 0.35, height)
        p.data.materials.append(wood_mat)
        p.parent = parent_obj
    
    # 5 Horizontal Wooden Shelf Planks & Rows of 3D Books
    tier_count = 5
    tier_height = (height - 0.8) / tier_count
    
    for t_idx in range(tier_count):
        tz = 0.4 + (t_idx * tier_height)
        # Shelf Plank
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.1, tz))
        plank = bpy.context.active_object
        plank.name = f"Plank_{cat_id}_{t_idx}"
        plank.scale = (width - 0.5, 0.55, 0.06)
        plank.data.materials.append(wood_mat)
        plank.parent = parent_obj
        
        # Brass Lip Trim
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.38, tz))
        trim = bpy.context.active_object
        trim.name = f"BrassTrim_{cat_id}_{t_idx}"
        trim.scale = (width - 0.5, 0.02, 0.06)
        trim.data.materials.append(mat_brass_gold)
        trim.parent = parent_obj
        
        # Books standing on this shelf tier
        book_count = 24
        book_avail_width = width - 0.8
        spacing = book_avail_width / book_count
        start_bx = -book_avail_width / 2.0
        
        for b_idx in range(book_count):
            bx = start_bx + (b_idx + 0.5) * spacing + random.uniform(-0.01, 0.01)
            bh = random.uniform(0.38, 0.54)
            bd = random.uniform(0.24, 0.30)
            bw = random.uniform(0.045, 0.075)
            by = 0.12
            bz = tz + 0.03 + (bh / 2.0)
            
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx, by, bz))
            book = bpy.context.active_object
            book.name = f"Book_{cat_id}_{t_idx}_{b_idx}"
            book.scale = (bw, bd, bh)
            book.data.materials.append(random.choice(book_mats))
            book.parent = parent_obj

    # Engraved Gold Category Nameplate Plaque atop the bookcase arch
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.28, height - 0.2))
    plaque = bpy.context.active_object
    plaque.name = f"CategoryPlaque_{cat_id}"
    plaque.scale = (2.6, 0.04, 0.28)
    plaque.data.materials.append(mat_brass_gold)
    plaque.parent = parent_obj
    
    # Warm Sconce Lighting illuminating the wooden bookcase
    light_data = bpy.data.lights.new(name=f"BookcaseLamp_{cat_id}", type='POINT')
    light_data.energy = 140.0
    light_data.color = (1.0, 0.92, 0.78)
    light_data.shadow_soft_size = 0.25
    
    light_obj = bpy.data.objects.new(name=f"BookcaseLampObj_{cat_id}", object_data=light_data)
    light_obj.location = (x, y + 1.2 if z_rot_deg == 0 else (y - 1.2 if z_rot_deg == 180 else y), height - 0.3)
    scene.collection.objects.link(light_obj)

# 3. Place Realistic Wooden Bookcases in all 6 Room Sections/Corners:
# 1. North Grand Hall: History & Lore
build_multi_tier_wooden_bookcase(0.0, 11.5, 180, "cat_history", "HISTORY & LORE", width=5.6, is_dark_wood=False)

# 2. East Observatory Wing: Sci-Fi & Cosmos
build_multi_tier_wooden_bookcase(11.5, 0.0, 90, "cat_scifi", "SCI-FI & COSMOS", width=5.6, is_dark_wood=False)

# 3. South Gothic Study: Mystery & Crime
build_multi_tier_wooden_bookcase(0.0, -11.5, 0, "cat_mystery", "MYSTERY & CRIME", width=5.6, is_dark_wood=True)

# 4. West Heritage Pavilion: Malayalam Classics
build_multi_tier_wooden_bookcase(-11.5, 0.0, -90, "cat_malayalam", "MALAYALAM CLASSICS", width=5.6, is_dark_wood=False)

# 5. Upper Arcane Balcony: Fantasy & Wonder
build_multi_tier_wooden_bookcase(-7.5, 7.5, 135, "cat_fantasy", "FANTASY & WONDER", width=4.8, is_dark_wood=False)

# 6. Nocturne Reading Nook: Sleep & Ambient
build_multi_tier_wooden_bookcase(7.5, -7.5, -45, "cat_sleep", "SLEEP & AMBIENT", width=4.8, is_dark_wood=True)

# 4. Central Grand Chandelier & Ambient Lighting
central_light = bpy.data.lights.new(name="GrandChandelier", type='POINT')
central_light.energy = 280.0
central_light.color = (1.0, 0.94, 0.82)
central_obj = bpy.data.objects.new(name="GrandChandelierObj", object_data=central_light)
central_obj.location = (0.0, 0.0, 4.4)
scene.collection.objects.link(central_obj)

# Save .blend file
blend_path = os.path.abspath("assets/library_corridor.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(f"Saved Multi-Corner Grand Library 3D Model to: {blend_path}")

# 5. Render First-Person Room Corner Viewpoints & In-Shelf Views
cam_data = bpy.data.cameras.new(name="LibraryCam")
cam_data.lens = 19
cam_data.clip_start = 0.1
cam_data.clip_end = 60.0
cam_obj = bpy.data.objects.new(name="LibraryCamObj", object_data=cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

def render_pass(output_path, loc, rot_deg, lens=19):
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

# 6 Distinct First-Person Room Corner Walking Viewpoints (looking toward the wooden bookcases)
# 1. North Hall (History & Lore)
render_pass(os.path.abspath("assets/blender_room_north_hall.png"), loc=(0.0, 6.0, 1.65), rot_deg=(90.0, 0.0, 0.0), lens=19)
render_pass(os.path.abspath("assets/blender_hall_walk_1.png"), loc=(0.0, 6.0, 1.65), rot_deg=(90.0, 0.0, 0.0), lens=19)

# 2. East Wing (Sci-Fi & Cosmos)
render_pass(os.path.abspath("assets/blender_room_east_wing.png"), loc=(6.0, 0.0, 1.65), rot_deg=(90.0, 0.0, -90.0), lens=19)
render_pass(os.path.abspath("assets/blender_hall_walk_2.png"), loc=(6.0, 0.0, 1.65), rot_deg=(90.0, 0.0, -90.0), lens=19)

# 3. South Study (Mystery & Crime)
render_pass(os.path.abspath("assets/blender_room_south_study.png"), loc=(0.0, -6.0, 1.65), rot_deg=(90.0, 0.0, 180.0), lens=19)
render_pass(os.path.abspath("assets/blender_hall_walk_3.png"), loc=(0.0, -6.0, 1.65), rot_deg=(90.0, 0.0, 180.0), lens=19)

# 4. West Pavilion (Malayalam Classics)
render_pass(os.path.abspath("assets/blender_room_west_pavilion.png"), loc=(-6.0, 0.0, 1.65), rot_deg=(90.0, 0.0, 90.0), lens=19)

# 5. Upper Balcony (Fantasy & Wonder)
render_pass(os.path.abspath("assets/blender_room_balcony.png"), loc=(-4.0, 4.0, 1.65), rot_deg=(90.0, 0.0, 45.0), lens=19)

# 6. Nocturne Reading Nook (Sleep & Ambient)
render_pass(os.path.abspath("assets/blender_room_reading_nook.png"), loc=(4.0, -4.0, 1.65), rot_deg=(90.0, 0.0, -135.0), lens=19)

# Direct Shelf Close-Up Views for in-shelf horizontal book scrolling
render_pass(os.path.abspath("assets/blender_shelf_history.png"), loc=(0.0, 9.8, 1.55), rot_deg=(90.0, 0.0, 0.0), lens=28)
render_pass(os.path.abspath("assets/blender_shelf_scifi.png"), loc=(9.8, 0.0, 1.55), rot_deg=(90.0, 0.0, -90.0), lens=28)
render_pass(os.path.abspath("assets/blender_shelf_mystery.png"), loc=(0.0, -9.8, 1.55), rot_deg=(90.0, 0.0, 180.0), lens=28)
render_pass(os.path.abspath("assets/blender_shelf_malayalam.png"), loc=(-9.8, 0.0, 1.55), rot_deg=(90.0, 0.0, 90.0), lens=28)
# Top-Down Isometric / Plan View for Interactive Library Map
render_pass(os.path.abspath("assets/library_top_down_map.png"), loc=(0.0, 0.0, 15.0), rot_deg=(0.0, 0.0, 0.0), lens=22)

print("=== ALL MULTI-CORNER REALISTIC WOODEN LIBRARY PASSES RENDERED SUCCESSFULLY ===")
