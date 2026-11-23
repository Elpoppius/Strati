"""Genera gli asset dell'epoca del villaggio, in stile "plastico architettonico".

Uso:  blender-py strumenti/blender/asset_villaggio.py gioco/asset/villaggio tavola.png

Regole (vedi docs/asset.md):
- 1 unità = 1 metro; origine al centro della base, a quota 0; il lato lungo sull'asse X.
- forme semplici e poligoni pochi, colori pieni per materiale, nessuna texture.
- un file .glb per asset; i materiali hanno nomi italiani condivisi tra gli asset.
"""
import math
import os
import random
import sys

import bpy  # va importato prima di bmesh
import bmesh
from mathutils import Vector

USCITA = sys.argv[1] if len(sys.argv) > 1 else "gioco/asset/villaggio"
TAVOLA = sys.argv[2] if len(sys.argv) > 2 else "tavola_villaggio.png"

PALETTE = {
    "terra_cruda": (0.62, 0.52, 0.40),
    "paglia": (0.74, 0.62, 0.38),
    "paglia_scura": (0.60, 0.49, 0.29),
    "legno": (0.47, 0.35, 0.23),
    "legno_scuro": (0.30, 0.22, 0.15),
    "pietra": (0.64, 0.63, 0.59),
    "fogliame": (0.36, 0.47, 0.27),
    "fogliame_scuro": (0.27, 0.38, 0.21),
    "canna": (0.60, 0.62, 0.38),
    "vano": (0.16, 0.12, 0.09),
}


def materiale(nome):
    if nome in bpy.data.materials:
        return bpy.data.materials[nome]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*PALETTE[nome], 1.0)
    bsdf.inputs["Roughness"].default_value = 0.9
    m.diffuse_color = (*PALETTE[nome], 1.0)
    return m


def mesh_da(nome, verts, facce, mat):
    me = bpy.data.meshes.new(nome)
    me.from_pydata([Vector(v) for v in verts], [], facce)
    me.update()
    ob = bpy.data.objects.new(nome, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(materiale(mat))
    return ob


def scatola(nome, dim, centro, mat):
    sx, sy, sz = (d / 2 for d in dim)
    cx, cy, cz = centro
    v = [(cx + x * sx, cy + y * sy, cz + z * sz) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return mesh_da(nome, v, f, mat)


def cilindro(nome, r, h, centro_base, mat, lati=8, r_alto=None):
    r_alto = r if r_alto is None else r_alto
    cx, cy, cz = centro_base
    v = []
    for k in range(lati):
        a = 2 * math.pi * k / lati
        v.append((cx + r * math.cos(a), cy + r * math.sin(a), cz))
    for k in range(lati):
        a = 2 * math.pi * k / lati
        v.append((cx + r_alto * math.cos(a), cy + r_alto * math.sin(a), cz + h))
    f = [(k, (k + 1) % lati, lati + (k + 1) % lati, lati + k) for k in range(lati)]
    f.append(tuple(range(lati - 1, -1, -1)))
    if r_alto > 0:
        f.append(tuple(range(lati, 2 * lati)))
    return mesh_da(nome, v, f, mat)


def cono(nome, r, h, centro_base, mat, lati=10):
    cx, cy, cz = centro_base
    v = [(cx + r * math.cos(2 * math.pi * k / lati), cy + r * math.sin(2 * math.pi * k / lati), cz) for k in range(lati)]
    v.append((cx, cy, cz + h))
    f = [(k, (k + 1) % lati, lati) for k in range(lati)] + [tuple(range(lati - 1, -1, -1))]
    return mesh_da(nome, v, f, mat)


def tetto_a_capanna(nome, lungo, largo, gronda, colmo, sporto, mat):
    """Tetto a due falde con il colmo lungo l'asse X."""
    L, W = lungo / 2 + sporto, largo / 2 + sporto
    v = [(-L, -W, gronda), (L, -W, gronda), (L, W, gronda), (-L, W, gronda), (-L, 0, colmo), (L, 0, colmo)]
    f = [(0, 1, 5, 4), (3, 4, 5, 2), (0, 4, 3), (1, 2, 5), (0, 3, 2, 1)]
    return mesh_da(nome, v, f, mat)


def sasso(nome, larg, prof, alto, centro_base, mat, seme):
    rnd = random.Random(seme)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for vtx in bm.verts:
        vtx.co.x *= larg * (0.85 + 0.3 * rnd.random())
        vtx.co.y *= prof * (0.85 + 0.3 * rnd.random())
        vtx.co.z = (vtx.co.z + 0.5) * alto * (0.9 + 0.2 * rnd.random())
        if vtx.co.z > alto * 0.5:
            vtx.co.x *= 0.75
            vtx.co.y *= 0.75
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nome, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = Vector(centro_base)
    ob.rotation_euler.z = rnd.random() * math.pi
    ob.data.materials.append(materiale(mat))
    return ob


def chioma(nome, raggio, centro, mat, seme, suddivisioni=1):
    rnd = random.Random(seme)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=suddivisioni, radius=raggio)
    for vtx in bm.verts:
        vtx.co *= 0.85 + 0.3 * rnd.random()
        vtx.co.z *= 0.8
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nome, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = Vector(centro)
    ob.data.materials.append(materiale(mat))
    return ob


def unisci(nome, parti):
    """Unisce le parti in un solo oggetto con origine al centro della base."""
    bpy.ops.object.select_all(action="DESELECT")
    for p in parti:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parti[0]
    if len(parti) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = nome
    ob.data.name = nome
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return ob


# ---------------- asset ----------------

def casa_lunga(nome, lungo, largo):
    gronda = 1.9
    parti = [
        scatola("muri", (lungo, largo, gronda), (0, 0, gronda / 2), "terra_cruda"),
        tetto_a_capanna("tetto", lungo, largo, gronda - 0.15, gronda + largo * 0.6, 0.45, "paglia"),
        scatola("porta", (0.08, 1.0, 1.5), (lungo / 2 + 0.03, 0, 0.75), "vano"),
    ]
    return unisci(nome, parti)


def capanna_tonda(nome, raggio):
    parti = [
        cilindro("muro", raggio, 1.6, (0, 0, 0), "terra_cruda", lati=12),
        cono("tetto", raggio + 0.4, raggio * 1.1 + 0.5, (0, 0, 1.45), "paglia", lati=12),
        scatola("porta", (0.3, 0.9, 1.3), (raggio - 0.05, 0, 0.65), "vano"),
    ]
    return unisci(nome, parti)


def granaio_su_pali(nome):
    parti = []
    for x in (-1.2, 1.2):
        for y in (-1.2, 1.2):
            parti.append(cilindro("palo", 0.12, 1.2, (x, y, 0), "legno_scuro", lati=6))
    parti.append(scatola("piano", (3.0, 3.0, 0.15), (0, 0, 1.27), "legno"))
    parti.append(scatola("cella", (2.6, 2.6, 1.6), (0, 0, 2.15), "terra_cruda"))
    tetto = tetto_a_capanna("tetto", 2.6, 2.6, 2.9, 4.1, 0.35, "paglia_scura")
    parti.append(tetto)
    return unisci(nome, parti)


def palizzata(nome, lungo=4.0, porta=False):
    parti = []
    n = int(lungo / 0.45)
    for k in range(n):
        x = -lungo / 2 + 0.225 + k * 0.45
        if porta and abs(x) < 1.0:
            continue
        h = 2.4 + 0.25 * math.sin(k * 2.7)
        parti.append(cilindro("pala", 0.13, h, (x, 0, 0), "legno", lati=6))
        parti.append(cono("punta", 0.13, 0.35, (x, 0, h), "legno", lati=6))
    if porta:
        for x in (-1.15, 1.15):
            parti.append(cilindro("stipite", 0.2, 3.2, (x, 0, 0), "legno_scuro", lati=6))
        parti.append(scatola("architrave", (2.6, 0.3, 0.25), (0, 0, 3.1), "legno_scuro"))
    else:
        parti.append(scatola("traversa", (lungo, 0.12, 0.12), (0, 0.16, 1.5), "legno_scuro"))
    return unisci(nome, parti)


def luogo_sacro(nome):
    parti = []
    for k in range(9):
        a = 2 * math.pi * k / 9
        parti.append(sasso("pietra", 0.6, 0.45, 1.6 + 0.4 * math.sin(k * 1.7), (4.2 * math.cos(a), 4.2 * math.sin(a), 0), "pietra", k))
    parti.append(sasso("stele", 0.7, 0.4, 2.8, (0, 0, 0), "pietra", 99))
    return unisci(nome, parti)


def quercia(nome, seme, alta=12.0):
    rnd = random.Random(seme)
    parti = [cilindro("tronco", 0.45, alta * 0.45, (0, 0, 0), "legno_scuro", lati=7, r_alto=0.3)]
    for k in range(4):
        a = rnd.random() * 2 * math.pi
        d = 1.2 + rnd.random() * 1.6
        r = alta * (0.2 + 0.08 * rnd.random())
        mat = "fogliame" if k % 2 == 0 else "fogliame_scuro"
        parti.append(chioma("chioma", r, (d * math.cos(a), d * math.sin(a), alta * (0.58 + 0.1 * rnd.random())), mat, seme * 10 + k))
    return unisci(nome, parti)


def canneto(nome, seme):
    rnd = random.Random(seme)
    parti = []
    for k in range(26):
        a = rnd.random() * 2 * math.pi
        d = rnd.random() * 1.6
        h = 1.6 + rnd.random() * 1.0
        parti.append(cono("canna", 0.05, h, (d * math.cos(a), d * math.sin(a), 0), "canna", lati=4))
    return unisci(nome, parti)


ASSET = [
    ("casa_lunga_piccola", lambda n: casa_lunga(n, 8.0, 5.0)),
    ("casa_lunga_media", lambda n: casa_lunga(n, 12.0, 6.0)),
    ("casa_lunga_grande", lambda n: casa_lunga(n, 18.0, 7.0)),
    ("capanna_tonda", lambda n: capanna_tonda(n, 3.0)),
    ("granaio_su_pali", granaio_su_pali),
    ("palizzata_tratto", lambda n: palizzata(n, 4.0, False)),
    ("palizzata_porta", lambda n: palizzata(n, 4.0, True)),
    ("luogo_sacro", luogo_sacro),
    ("quercia_1", lambda n: quercia(n, 1, 12.0)),
    ("quercia_2", lambda n: quercia(n, 2, 15.0)),
    ("canneto", lambda n: canneto(n, 5)),
]


def svuota_scena():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def esporta(ob, percorso):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=percorso, use_selection=True, export_apply=True)


def main():
    os.makedirs(USCITA, exist_ok=True)
    svuota_scena()
    oggetti = []
    for nome, fabbrica in ASSET:
        ob = fabbrica(nome)
        esporta(ob, os.path.join(USCITA, nome + ".glb"))
        dims = ob.dimensions
        print(f"{nome}: {dims.x:.1f} x {dims.y:.1f} x {dims.z:.1f} m, {len(ob.data.polygons)} facce")
        oggetti.append(ob)

    # Tavola di anteprima: gli asset in fila su un piano, vista come nel gioco.
    posizioni = [(-30, -6), (-17, -6), (2, -6), (19, -6), (29, -6), (-26, 9), (-19, 9), (-6, 9), (8, 9), (20, 9), (30, 9)]
    for ob, (x, y) in zip(oggetti, posizioni):
        ob.location = (x, y, 0)
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 1.5, 0))
    piano = bpy.context.object
    piano.scale = (78, 34, 1)
    m = bpy.data.materials.new("suolo")
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.62, 0.64, 0.55, 1)
    piano.data.materials.append(m)
    scn = bpy.context.scene
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = 72
    cam = bpy.data.objects.new("Cam", cam_d)
    scn.collection.objects.link(cam)
    # Stessa vista del gioco: inclinazione 30°, rotazione 45°.
    pitch, yaw, dist = math.radians(30), math.radians(45), 120
    cam.location = (dist * math.cos(pitch) * math.sin(yaw), -dist * math.cos(pitch) * math.cos(yaw), dist * math.sin(pitch))
    cam.rotation_euler = (math.radians(90) - pitch, 0, yaw)
    scn.camera = cam
    sole = bpy.data.objects.new("Sole", bpy.data.lights.new("Sole", "SUN"))
    scn.collection.objects.link(sole)
    sole.rotation_euler = (math.radians(45), math.radians(15), math.radians(-35))
    sole.data.energy = 2.2
    sole.data.angle = math.radians(8)
    mondo = bpy.data.worlds.new("Mondo")
    scn.world = mondo
    mondo.use_nodes = True
    mondo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.86, 0.88, 0.84, 1)
    mondo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
    scn.view_settings.view_transform = "Standard"
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 32
    scn.render.resolution_x = 1600
    scn.render.resolution_y = 800
    scn.render.filepath = TAVOLA
    bpy.ops.render.render(write_still=True)
    print("Tavola salvata:", TAVOLA)


main()
