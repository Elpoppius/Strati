import bpy, math, sys
out_glb, out_png = sys.argv[1], sys.argv[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
scn = bpy.context.scene
def mat(name, rgb):
    m = bpy.data.materials.new(name); m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb, 1); return m
# muri: casa lunga neolitica 12 x 6 m, muri 2 m
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1)); muri = bpy.context.object
muri.scale = (12, 6, 2); muri.name = "Muri"; muri.data.materials.append(mat("Intonaco", (0.55, 0.45, 0.32)))
# tetto a due falde
verts = [(-6.3,-3.4,2), (6.3,-3.4,2), (6.3,3.4,2), (-6.3,3.4,2), (-6.3,0,4.6), (6.3,0,4.6)]
faces = [(0,1,5,4), (3,4,5,2), (0,4,3), (1,2,5)]
me = bpy.data.meshes.new("Tetto"); me.from_pydata(verts, [], faces); me.update()
tetto = bpy.data.objects.new("Tetto", me); scn.collection.objects.link(tetto)
tetto.data.materials.append(mat("Paglia", (0.62, 0.48, 0.25)))
# terreno
bpy.ops.mesh.primitive_plane_add(size=30, location=(0,0,0)); bpy.context.object.data.materials.append(mat("Terra", (0.42, 0.47, 0.30)))
bpy.ops.export_scene.gltf(filepath=out_glb, use_selection=False)
# anteprima isometrica
cam_data = bpy.data.cameras.new("Cam"); cam_data.type = "ORTHO"; cam_data.ortho_scale = 22
cam = bpy.data.objects.new("Cam", cam_data); scn.collection.objects.link(cam)
cam.location = (16, -16, 14); cam.rotation_euler = (math.radians(60), 0, math.radians(45)); scn.camera = cam
sun = bpy.data.objects.new("Sole", bpy.data.lights.new("Sole", "SUN")); scn.collection.objects.link(sun)
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30)); sun.data.energy = 3
world = bpy.data.worlds.new("W"); scn.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.85, 0.87, 0.82, 1)
scn.render.engine = "CYCLES"; scn.cycles.device = "CPU"; scn.cycles.samples = 16
scn.render.resolution_x = 480; scn.render.resolution_y = 320; scn.render.filepath = out_png
bpy.ops.render.render(write_still=True)
print("OK", out_glb, out_png)
