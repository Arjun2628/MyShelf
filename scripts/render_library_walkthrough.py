import bpy
import math
import os

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderEngine.__subclasses__() else 'BLENDER_EEVEE'

# Set render settings for high quality & crispness
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'

# Create or reuse a camera
cam_data = bpy.data.cameras.new(name="WalkthroughCamera")
cam_data.lens = 24  # Wide-angle 24mm for immersive first-person POV
cam_data.clip_start = 0.1
cam_data.clip_end = 100.0

cam_obj = bpy.data.objects.new(name="WalkthroughCameraObj", object_data=cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

def render_pass(output_path, loc, rot_deg):
    cam_obj.location = loc
    cam_obj.rotation_euler = (
        math.radians(rot_deg[0]),
        math.radians(rot_deg[1]),
        math.radians(rot_deg[2])
    )
    scene.render.filepath = output_path
    print(f"Rendering pass: {output_path} at loc={loc}, rot={rot_deg}")
    bpy.ops.render.render(write_still=True)

# 1. First-Person Grand Walkway Corridor (Central aisle looking down the library)
render_pass(
    os.path.abspath("assets/blender_walkway_corridor.png"),
    loc=(0.0, -5.2, 1.65),
    rot_deg=(85.0, 0.0, 0.0)
)

# 2. Left Aisle Perspective (Looking towards the flanking reading nook & mahogany bookshelves)
render_pass(
    os.path.abspath("assets/blender_aisle_classic.png"),
    loc=(-2.8, -3.5, 1.65),
    rot_deg=(80.0, 0.0, 45.0)
)

# 3. Right Aisle Perspective (Looking towards the warm lamplit alcove)
render_pass(
    os.path.abspath("assets/blender_aisle_scifi.png"),
    loc=(2.8, -3.5, 1.65),
    rot_deg=(80.0, 0.0, -45.0)
)

# 4. Approaching the Grand Center Rotunda & Tiered Mezzanine
render_pass(
    os.path.abspath("assets/blender_aisle_history.png"),
    loc=(0.0, -1.8, 1.65),
    rot_deg=(92.0, 0.0, 0.0)
)

# 5. Mystery & Noir Vault Perspective
render_pass(
    os.path.abspath("assets/blender_aisle_mystery.png"),
    loc=(-3.5, 1.2, 1.65),
    rot_deg=(78.0, 0.0, 115.0)
)

# 6. Heritage Archive Perspective
render_pass(
    os.path.abspath("assets/blender_aisle_malayalam.png"),
    loc=(3.5, 1.2, 1.65),
    rot_deg=(78.0, 0.0, -115.0)
)

print("=== ALL BLENDER WALKTHROUGH PASSES RENDERED SUCCESSFULLY ===")
