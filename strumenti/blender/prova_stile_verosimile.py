"""Prova di stile verosimile per gli asset del villaggio.

Uso:  blender-py strumenti/blender/prova_stile_verosimile.py gioco/asset/prove_stile tavola.png [vicino|gioco]

Rispetto al primo lotto: texture procedurali (paglia, argilla, legno, corteccia, foglie),
tetti spessi e irregolari, pali a vista, alberi con tronco, rami e chiome di foglie.
Le texture si generano prima con strumenti/blender/texture_procedurali.py.
"""
import math
import os
import random
import sys

import bpy  # va importato prima di bmesh
import bmesh
from mathutils import Matrix, Vector

USCITA = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "gioco/asset/prove_stile")
TAVOLA = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else "tavola_verosimile.png")
INQUADRATURA = sys.argv[3] if len(sys.argv) > 3 else "vicino"
TEXTURE = os.path.join(os.path.dirname(os.path.dirname(USCITA)), "asset", "texture") \
    if not os.path.isdir(os.path.join(os.path.dirname(USCITA), "texture")) else os.path.join(os.path.dirname(USCITA), "texture")
TILE = 2.5  # metri coperti da una ripetizione della texture


# ---------- materiali ----------
def materiale(nome, immagine, ruvidezza=0.9, ritaglio=False, tinta=None):
    if nome in bpy.data.materials:
        return bpy.data.materials[nome]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = ruvidezza
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(TEXTURE, immagine + ".png"), check_existing=True)
    if tinta is not None:
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        mix.inputs["B"].default_value = (*tinta, 1.0)
        nt.links.new(tex.outputs["Color"], mix.inputs["A"])
        nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    else:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if ritaglio:
        soglia = nt.nodes.new("ShaderNodeMath")
        soglia.operation = "GREATER_THAN"
        soglia.inputs[1].default_value = 0.5
        nt.links.new(tex.outputs["Alpha"], soglia.inputs[0])
        nt.links.new(soglia.outputs["Value"], bsdf.inputs["Alpha"])
    return m


def proiezione_box(ob, tile=TILE):
    """UV a proiezione per facce: la paglia scorre lungo la pendenza delle falde."""
    me = ob.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    uv = me.uv_layers.active.data
    mw = ob.matrix_world
    for poly in me.polygons:
        n = (mw.to_3x3() @ poly.normal).normalized()
        for li in poly.loop_indices:
            p = mw @ me.vertices[me.loops[li].vertex_index].co
            if abs(n.z) >= max(abs(n.x), abs(n.y)):
                # Falda: v lungo la direzione di massima pendenza.
                uv[li].uv = (p.y / tile, p.x / tile) if abs(n.x) > abs(n.y) else (p.x / tile, p.y / tile)
            elif abs(n.x) >= abs(n.y):
                uv[li].uv = (p.y / tile, p.z / tile)
            else:
                uv[li].uv = (p.x / tile, p.z / tile)


def collega(ob, mat):
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(mat)
    return ob


def da_bmesh(nome, bm, mat, uv=True, tile=TILE):
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nome, me)
    collega(ob, mat)
    if uv:
        proiezione_box(ob, tile)
    return ob


# ---------- forme ----------
def scatola(nome, dim, centro, mat, tagli=0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    if tagli:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=tagli, use_grid_fill=True)
    bmesh.ops.scale(bm, vec=Vector(dim), verts=bm.verts)
    bmesh.ops.translate(bm, vec=Vector(centro), verts=bm.verts)
    return da_bmesh(nome, bm, mat)


def cilindro_tra(nome, p0, p1, r0, r1, mat, lati=8, uv_tile=1.2):
    p0, p1 = Vector(p0), Vector(p1)
    asse = p1 - p0
    lung = asse.length
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=lati, radius1=r0, radius2=r1, depth=lung)
    bmesh.ops.translate(bm, vec=Vector((0, 0, lung / 2)), verts=bm.verts)
    rot = Vector((0, 0, 1)).rotation_difference(asse.normalized()).to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation(p0) @ rot, verts=bm.verts)
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nome, me)
    collega(ob, mat)
    # UV cilindriche: u attorno, v lungo l'asse (venature e solchi seguono il ramo).
    me.uv_layers.new(name="UVMap")
    uvd = me.uv_layers.active.data
    perp = asse.orthogonal().normalized()
    perp2 = asse.normalized().cross(perp)
    for poly in me.polygons:
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co - p0
            ang = math.atan2(co.dot(perp2), co.dot(perp))
            uvd[li].uv = ((ang / (2 * math.pi)) * 2, co.dot(asse.normalized()) / uv_tile)
    return ob


def tetto_a_padiglione(nome, lungo, largo, gronda, inclinazione, sporto, spessore, mat, seme):
    """Tetto di paglia a quattro falde, spesso e appena irregolare."""
    rnd = random.Random(seme)
    L, W = lungo / 2 + sporto, largo / 2 + sporto
    colmo_z = gronda + W * math.tan(math.radians(inclinazione))
    rc = max(L - W * 0.75, 0.3)
    bm = bmesh.new()
    v = [bm.verts.new(p) for p in [(-L, -W, gronda), (L, -W, gronda), (L, W, gronda), (-L, W, gronda),
                                   (-rc, 0, colmo_z), (rc, 0, colmo_z)]]
    for f in [(0, 1, 5, 4), (2, 3, 4, 5), (1, 2, 5), (3, 0, 4)]:
        bm.faces.new([v[i] for i in f])
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=5, use_grid_fill=True)
    for vert in bm.verts:
        if vert.co.z > gronda + 0.05:
            vert.co.z += rnd.uniform(-0.07, 0.07)
        else:
            vert.co.x += rnd.uniform(-0.1, 0.1)
            vert.co.y += rnd.uniform(-0.1, 0.1)
            vert.co.z += rnd.uniform(-0.12, 0.05)
    bm.normal_update()
    ob = da_bmesh(nome, bm, mat)
    mod = ob.modifiers.new("spessore", "SOLIDIFY")
    mod.thickness = spessore
    mod.offset = -1
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    proiezione_box(ob)
    return ob


def tetto_conico(nome, raggio, gronda, altezza, spessore, mat, seme, lati=16):
    rnd = random.Random(seme)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=lati, radius1=raggio, radius2=0.05, depth=altezza)
    bmesh.ops.translate(bm, vec=Vector((0, 0, gronda + altezza / 2)), verts=bm.verts)
    bmesh.ops.subdivide_edges(bm, edges=[e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 0.1], cuts=4)
    for vert in bm.verts:
        vert.co.x += rnd.uniform(-0.06, 0.06)
        vert.co.y += rnd.uniform(-0.06, 0.06)
        if vert.co.z < gronda + 0.1:
            vert.co.z += rnd.uniform(-0.15, 0.05)
    bm.normal_update()
    ob = da_bmesh(nome, bm, mat)
    mod = ob.modifiers.new("spessore", "SOLIDIFY")
    mod.thickness = spessore
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    proiezione_box(ob)
    return ob


def unisci(nome, parti):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parti:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parti[0]
    if len(parti) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = nome
    ob.data.name = nome
    return ob


# ---------- materiali condivisi ----------
def M():
    return {
        "paglia": materiale("paglia", "paglia"),
        "argilla": materiale("argilla", "argilla"),
        "legno": materiale("legno", "legno"),
        "corteccia": materiale("corteccia", "corteccia"),
        "foglie": materiale("foglie", "foglie", ruvidezza=0.8, ritaglio=True),
        "foglie_chiare": materiale("foglie_chiare", "foglie_chiare", ruvidezza=0.8, ritaglio=True),
        "foglie_scure": materiale("foglie_scure", "foglie_scure", ruvidezza=0.8, ritaglio=True),
        "vano": materiale("vano", "legno", tinta=(0.15, 0.12, 0.1)),
    }


# ---------- asset ----------
def casa_lunga(nome, lungo, largo, seme):
    m = M()
    altezza_muro = 1.45
    parti = [scatola("muri", (lungo, largo, altezza_muro), (0, 0, altezza_muro / 2), m["argilla"], tagli=4)]
    passo = 2.0
    n = int(lungo / passo)
    for k in range(n + 1):
        x = -lungo / 2 + k * lungo / n
        for y in (-largo / 2, largo / 2):
            parti.append(cilindro_tra("palo", (x, y, -0.1), (x, y, altezza_muro + 0.15), 0.16, 0.13, m["corteccia"], lati=6))
    parti.append(scatola("porta", (0.14, 1.2, 1.4), (lungo / 2 + 0.03, 0, 0.7), m["vano"]))
    parti.append(tetto_a_padiglione("tetto", lungo, largo, altezza_muro - 0.1, 56, 0.85, 0.45, m["paglia"], seme))
    return unisci(nome, parti)


def capanna_tonda(nome, raggio, seme):
    m = M()
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=18, radius1=raggio, radius2=raggio, depth=1.4)
    bmesh.ops.subdivide_edges(bm, edges=[e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 0.5], cuts=3)
    bmesh.ops.translate(bm, vec=Vector((0, 0, 0.7)), verts=bm.verts)
    parti = [da_bmesh("muro", bm, m["argilla"])]
    parti.append(scatola("porta", (0.3, 1.0, 1.3), (raggio - 0.05, 0, 0.65), m["vano"]))
    parti.append(tetto_conico("tetto", raggio + 0.8, 1.25, raggio * 1.45, 0.4, m["paglia"], seme))
    return unisci(nome, parti)


def granaio(nome, seme):
    m = M()
    parti = []
    for x in (-1.1, 1.1):
        for y in (-1.1, 1.1):
            parti.append(cilindro_tra("palo", (x, y, 0), (x, y, 1.05), 0.14, 0.12, m["corteccia"], lati=7))
            # Cappello contro i roditori.
            parti.append(cilindro_tra("cappello", (x, y, 1.05), (x, y, 1.13), 0.32, 0.3, m["legno"], lati=8))
    parti.append(scatola("piano", (3.0, 3.0, 0.14), (0, 0, 1.2), m["legno"]))
    parti.append(scatola("cella", (2.5, 2.5, 1.5), (0, 0, 2.02), m["argilla"], tagli=3))
    parti.append(scatola("porta", (0.1, 0.7, 0.9), (1.27, 0, 1.8), m["vano"]))
    parti.append(tetto_a_padiglione("tetto", 2.5, 2.5, 2.65, 56, 0.6, 0.32, m["paglia"], seme))
    return unisci(nome, parti)


def carta_foglie(centro, dim, rnd, mat):
    """Tre carte incrociate con la texture delle foglie."""
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    for k in range(3):
        a = k * math.pi / 3 + rnd.uniform(0, 0.5)
        incl = rnd.uniform(-1.0, 1.0)
        d = Vector((math.cos(a), math.sin(a), 0)) * dim / 2
        su = Vector((0, 0, 1)) * dim / 2
        su = Matrix.Rotation(incl, 3, d.normalized()) @ su
        c = Vector(centro)
        vs = [bm.verts.new(c - d - su), bm.verts.new(c + d - su), bm.verts.new(c + d + su), bm.verts.new(c - d + su)]
        f = bm.faces.new(vs)
        for loop, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
            loop[uvl].uv = uv
    me = bpy.data.meshes.new("chioma")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("chioma", me)
    return collega(ob, mat)


def quercia(nome, seme, alta=12.0):
    """Quercia: tronco, rami principali e una chioma tondeggiante fatta di carte di foglie."""
    m = M()
    rnd = random.Random(seme)
    parti = []
    h_tronco = alta * 0.3
    base_r = alta * 0.04
    parti.append(cilindro_tra("tronco", (0, 0, -0.2), (0, 0, h_tronco), base_r, base_r * 0.75, m["corteccia"], lati=9))
    # Chioma: ellissoide largo e un po' schiacciato, come nelle querce isolate.
    rx, rz = alta * rnd.uniform(0.38, 0.45), alta * rnd.uniform(0.3, 0.35)
    centro = Vector((rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), alta - rz))
    n_rami = rnd.randint(4, 6)
    for k in range(n_rami):
        a = 2 * math.pi * k / n_rami + rnd.uniform(-0.3, 0.3)
        meta = centro + Vector((math.cos(a) * rx * 0.6, math.sin(a) * rx * 0.6, rnd.uniform(-0.3, 0.2) * rz))
        p0 = Vector((0, 0, h_tronco * rnd.uniform(0.85, 1.0)))
        parti.append(cilindro_tra("ramo", p0, meta, base_r * 0.55, base_r * 0.25, m["corteccia"], lati=6))
    n_carte = int(60 + alta * 2.5)
    for _ in range(n_carte):
        while True:
            d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1)))
            if d.length <= 1.0:
                break
        r = d.length ** 0.35  # più carte verso la superficie della chioma
        d = d.normalized() * r if d.length > 0 else d
        p = centro + Vector((d.x * rx, d.y * rx, d.z * rz))
        dim = alta * rnd.uniform(0.17, 0.25)
        # Sopra foglie illuminate, sotto e dentro foglie in ombra: volume "dipinto".
        mat = m["foglie_chiare"] if d.z > 0.15 and r > 0.7 else (m["foglie_scure"] if d.z < -0.2 or r < 0.55 else m["foglie"])
        parti.append(carta_foglie(p, dim, rnd, mat))
    return unisci(nome, parti)


ASSET = [
    ("casa_lunga_media", lambda n: casa_lunga(n, 12.0, 6.0, 1), (-9, -2)),
    ("capanna_tonda", lambda n: capanna_tonda(n, 3.0, 2), (9, -7)),
    ("granaio_su_pali", lambda n: granaio(n, 3), (5, 3)),
    ("quercia_1", lambda n: quercia(n, 1, 12.0), (-4, 12)),
    ("quercia_2", lambda n: quercia(n, 2, 15.0), (14, 9)),
]


def cuoci_occlusione(ob, minimo=0.45):
    """Occlusione ambientale nei colori dei vertici: scurisce incavi, basi e interno delle chiome."""
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 64
    scn.world.light_settings.distance = 2.5
    attr = ob.data.color_attributes.new("Occlusione", "BYTE_COLOR", "CORNER")
    ob.data.color_attributes.active_color = attr
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.bake(type="AO", target="VERTEX_COLORS")
    # Ammorbidisce: l'occlusione piena è troppo scura per una vista dall'alto.
    for c in attr.data:
        v = c.color
        k = minimo + (1 - minimo) * v[0]
        c.color = (k, k, k, 1.0)


def esporta(ob, percorso):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=percorso, use_selection=True, export_apply=True, export_image_format="AUTO",
                              export_vertex_color="ACTIVE")


def mostra_occlusione_nei_materiali():
    """Per l'anteprima di Blender: moltiplica la texture per l'occlusione dei vertici."""
    for m in bpy.data.materials:
        if not m.use_nodes or "Principled BSDF" not in m.node_tree.nodes:
            continue
        nt = m.node_tree
        bsdf = nt.nodes["Principled BSDF"]
        if not bsdf.inputs["Base Color"].links:
            continue
        sorgente = bsdf.inputs["Base Color"].links[0].from_socket
        attr = nt.nodes.new("ShaderNodeVertexColor")
        attr.layer_name = "Occlusione"
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        nt.links.new(sorgente, mix.inputs["A"])
        nt.links.new(attr.outputs["Color"], mix.inputs["B"])
        nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(USCITA, exist_ok=True)
    bpy.context.scene.world = bpy.data.worlds.new("Mondo")
    # Suolo temporaneo per l'occlusione alla base degli asset.
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    suolo_ao = bpy.context.object
    oggetti = []
    for nome, fabbrica, pos in ASSET:
        ob = fabbrica(nome)
        cuoci_occlusione(ob, 0.72 if nome.startswith("quercia") else 0.45)
        esporta(ob, os.path.join(USCITA, nome + ".glb"))
        d = ob.dimensions
        print(f"{nome}: {d.x:.1f} x {d.y:.1f} x {d.z:.1f} m, {len(ob.data.polygons)} facce")
        ob.location = (pos[0], pos[1], 0)
        oggetti.append(ob)
    bpy.data.objects.remove(suolo_ao, do_unlink=True)
    mostra_occlusione_nei_materiali()
    # Suolo d'erba.
    bpy.ops.mesh.primitive_plane_add(size=1, location=(2, 2, 0))
    suolo = bpy.context.object
    suolo.scale = (90, 90, 1)
    bpy.ops.object.transform_apply(scale=True)
    suolo.data.materials.append(materiale("erba", "erba"))
    proiezione_box(suolo, tile=6.0)
    scn = bpy.context.scene
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = 48 if INQUADRATURA == "vicino" else 160
    cam = bpy.data.objects.new("Cam", cam_d)
    scn.collection.objects.link(cam)
    pitch, yaw, dist = math.radians(30), math.radians(45), 150
    cx, cy = 3, 5
    cam.location = (cx + dist * math.cos(pitch) * math.sin(yaw), cy - dist * math.cos(pitch) * math.cos(yaw), dist * math.sin(pitch))
    cam.rotation_euler = (math.radians(90) - pitch, 0, yaw)
    scn.camera = cam
    sole = bpy.data.objects.new("Sole", bpy.data.lights.new("Sole", "SUN"))
    scn.collection.objects.link(sole)
    sole.rotation_euler = (math.radians(50), math.radians(10), math.radians(-40))
    sole.data.energy = 4.5
    sole.data.angle = math.radians(3)
    sole.data.color = (1.0, 0.93, 0.82)
    mondo = scn.world
    mondo.use_nodes = True
    bg = mondo.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.55, 0.65, 0.8, 1)
    bg.inputs["Strength"].default_value = 0.6
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 48
    try:
        scn.cycles.use_denoising = True
    except Exception:
        pass
    scn.render.resolution_x = 1600
    scn.render.resolution_y = 900
    scn.render.filepath = TAVOLA
    bpy.ops.render.render(write_still=True)
    print("Tavola salvata:", TAVOLA)


main()
