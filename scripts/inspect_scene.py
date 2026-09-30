import bpy

print("=== OBJECTS IN SCENE ===")
for obj in bpy.data.objects:
    print(f"- {obj.name} (type: {obj.type}, location: {obj.location})")

print("\n=== MATERIALS IN SCENE ===")
for mat in bpy.data.materials:
    print(f"- {mat.name}")
