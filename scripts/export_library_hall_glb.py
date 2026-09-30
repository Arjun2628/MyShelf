import bpy
import os

blend_file = os.path.abspath("assets/library_corridor.blend")
glb_output = os.path.abspath("assets/library_hall.glb")

bpy.ops.wm.open_mainfile(filepath=blend_file)

# Export complete 3D scene to GLB
bpy.ops.export_scene.gltf(
    filepath=glb_output,
    export_format='GLB',
    use_selection=False,
    export_apply=True,
    export_cameras=False,
    export_lights=True,
    export_materials='EXPORT',
    export_image_format='AUTO',
)

print(f"Successfully exported 3D Library Hall to {glb_output}")
