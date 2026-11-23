"""Prova di stile verosimile per gli asset del villaggio.

Uso:  blender-py strumenti/blender/prova_stile_verosimile.py gioco/asset/prove_stile tavola.png [vicino|gioco]

Rispetto al primo lotto: texture procedurali (paglia, argilla, legno, corteccia, foglie),
tetti spessi e irregolari, pali a vista. Alberi (terza versione): chioma a lobi fatta di carte
con foglie singole, normali sferiche per la luce sul volume, cinque specie compresi gli arbusti.
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
def materiale(nome, immagine, ruvidezza=0.9, ritaglio=False, tinta=None, due_facce=True):
    if nome in bpy.data.materials:
        return bpy.data.materials[nome]
    m = bpy.data.materials.new(nome)
    # Le carte di foglie hanno già fronte e retro come facce distinte: niente doppia faccia nel materiale.
    m.use_backface_culling = not due_facce
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
        **{f: materiale(f, f, ruvidezza=0.8, ritaglio=True, due_facce=False) for f in
           ("foglie_quercia", "foglie_carpino", "foglie_pioppo", "foglie_nocciolo", "foglie_autunno")},
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


# ---------- alberi ----------
# Parametri per specie (misure in frazioni dell'altezza): tronco visibile, raggi della chioma,
# numero e grandezza dei lobi, texture delle foglie.
SPECIE = {
    "quercia":   dict(tronco=0.32, r_tronco=0.034, rx=0.42, rz=0.32, lobi=(6, 8), lobo=0.42, foglie="foglie_quercia"),
    "carpino":   dict(tronco=0.30, r_tronco=0.028, rx=0.32, rz=0.36, lobi=(5, 6), lobo=0.5, foglie="foglie_carpino"),
    "pioppo":    dict(tronco=0.18, r_tronco=0.028, rx=0.16, rz=0.42, lobi=(7, 8), lobo=0.85, foglie="foglie_pioppo"),
    "acero":     dict(tronco=0.30, r_tronco=0.03, rx=0.36, rz=0.33, lobi=(5, 7), lobo=0.45, foglie="foglie_autunno"),
    "cespuglio": dict(tronco=0.0, r_tronco=0.0, rx=0.6, rz=0.45, lobi=(4, 5), lobo=0.55, foglie="foglie_nocciolo"),
}


def punto_sfera(rnd, z_min=-1.0):
    while True:
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1)))
        if 0.05 < d.length <= 1.0 and d.normalized().z >= z_min:
            return d.normalized()


def chioma(nome, lobi, centro, rx, rz, rnd, mat, leggero=False):
    """Fogliame fatto di carte rivolte verso l'esterno dei lobi, ognuna in due facce (fronte e retro).

    Le normali non sono quelle delle carte ma quelle di una sfera attorno alla chioma:
    la luce scorre sul volume intero, chiara in alto e verso il sole, scura sotto.
    leggero: versione per la distanza, con poche carte grandi e senza riempimento interno.
    """
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    normali = []

    def normale_volume(p, lobo_c):
        q = p - centro
        n_chioma = Vector((q.x / rx, q.y / rx, q.z / rz)).normalized()
        n_lobo = (p - lobo_c).normalized()
        return (n_chioma * 0.65 + n_lobo * 0.35 + Vector((0, 0, 0.12))).normalized()

    def carta(p, verso, dim, lobo_c):
        verso = (verso + Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))) * 0.28).normalized()
        a = verso.orthogonal().normalized()
        a = Matrix.Rotation(rnd.uniform(0, 2 * math.pi), 3, verso) @ a
        b = verso.cross(a)
        h = dim / 2
        angoli = [p - a * h - b * h, p + a * h - b * h, p + a * h + b * h, p - a * h + b * h]
        uv = [(0, 0), (1, 0), (1, 1), (0, 1)]
        for ordine in ((0, 1, 2, 3), (3, 2, 1, 0)):
            vs = [bm.verts.new(angoli[i]) for i in ordine]
            for v in vs:
                normali.append(normale_volume(v.co.copy(), lobo_c))
            f = bm.faces.new(vs)
            for loop, i in zip(f.loops, ordine):
                loop[uvl].uv = uv[i]

    for lobo_c, r_l in lobi:
        dim_media = max(r_l * 1.3, 1.2)
        area = 4 * math.pi * r_l * r_l
        n = int(min(70, max(12, area / (dim_media * dim_media * 0.33))))
        if leggero:
            # Poche carte grandi: da lontano la chioma resta piena con un quinto delle facce.
            dim_media *= 1.9
            n = max(4, int(n * 0.17))
        for _ in range(n):
            d = punto_sfera(rnd, -0.75)
            # Le carte grandi della versione leggera stanno più dentro, per tenere la stessa sagoma.
            p = lobo_c + d * r_l * (rnd.uniform(0.3, 0.65) if leggero else rnd.uniform(0.6, 1.0))
            carta(p, d, dim_media * rnd.uniform(0.85, 1.2), lobo_c)
        # Riempimento interno: chiude i buchi tra una carta e l'altra (l'occlusione lo scurisce).
        for _ in range(0 if leggero else max(3, n // 8)):
            d = punto_sfera(rnd)
            carta(lobo_c + d * r_l * rnd.uniform(0.0, 0.4), d, dim_media * 1.2, lobo_c)
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    me.normals_split_custom_set_from_vertices(normali)
    ob = bpy.data.objects.new(nome, me)
    return collega(ob, mat)


def albero(nome, seme, alta, specie, leggero=False):
    """Albero o arbusto: tronco, rami verso i lobi della chioma, fogliame a carte."""
    m = M()
    s = SPECIE[specie]
    rnd = random.Random(seme)
    parti = []
    rx = alta * s["rx"] * rnd.uniform(0.9, 1.1)
    rz = alta * s["rz"] * rnd.uniform(0.92, 1.08)
    centro = Vector((rnd.uniform(-0.3, 0.3), rnd.uniform(-0.3, 0.3), alta - rz))
    # Lobi: sfere minori sul guscio della chioma, più una in cima; danno il contorno a nuvola.
    lobi = []
    n_lobi = rnd.randint(*s["lobi"])
    r_base = min(rx, rz) * s["lobo"] if specie != "pioppo" else rx * s["lobo"]
    for k in range(n_lobi):
        if specie == "pioppo":
            # Colonnare: lobi impilati lungo il fusto.
            t = k / (n_lobi - 1)
            off = Vector((rnd.uniform(-0.25, 0.25) * rx, rnd.uniform(-0.25, 0.25) * rx, (t * 2 - 1) * rz * 0.75))
            r_l = r_base * (1.05 - 0.45 * abs(t - 0.4))
        else:
            a = 2 * math.pi * k / n_lobi + rnd.uniform(-0.3, 0.3)
            el = rnd.uniform(-0.35, 0.45)
            off = Vector((math.cos(a) * math.cos(el) * rx * 0.55, math.sin(a) * math.cos(el) * rx * 0.55, math.sin(el) * rz * 0.55))
            r_l = r_base * rnd.uniform(0.85, 1.12)
        lobi.append((centro + off, r_l))
    if specie != "pioppo":
        lobi.append((centro + Vector((0, 0, rz * 0.4)), r_base * 1.05))
    # Tronco e rami.
    if s["tronco"] > 0:
        r_t = alta * s["r_tronco"]
        h_t = alta * s["tronco"]
        cima = alta * 0.85 if specie == "pioppo" else centro.z
        parti.append(cilindro_tra("tronco", (0, 0, -0.25), (centro.x * 0.5, centro.y * 0.5, cima), r_t, r_t * 0.35, m["corteccia"], lati=5 if leggero else 9))
        for lobo_c, r_l in ([] if leggero else lobi):
            if lobo_c.z < h_t:
                continue
            p0 = Vector((centro.x * 0.3, centro.y * 0.3, rnd.uniform(h_t * 0.9, min(lobo_c.z, centro.z) * 0.95)))
            p1 = p0.lerp(lobo_c, 0.85)
            parti.append(cilindro_tra("ramo", p0, p1, r_t * 0.45, r_t * 0.15, m["corteccia"], lati=6))
    else:
        # Arbusto: alcuni fusti sottili dal suolo.
        for k in range(2 if leggero else 5):
            a = rnd.uniform(0, 2 * math.pi)
            p1 = centro + Vector((math.cos(a) * rx * 0.4, math.sin(a) * rx * 0.4, rnd.uniform(-0.2, 0.3) * rz))
            parti.append(cilindro_tra("fusto", (0, 0, -0.1), p1, 0.05, 0.025, m["corteccia"], lati=5))
    parti.append(chioma("chioma", lobi, centro, rx, rz, rnd, m[s["foglie"]], leggero))
    ob = unisci(nome, parti)
    # Servono a calcolare l'ombra interna della chioma (vedi occlusione_chioma).
    ob["chioma"] = (centro.x, centro.y, centro.z, rx, rz)
    return ob


ASSET = [
    ("casa_lunga_media", lambda n: casa_lunga(n, 12.0, 6.0, 1), (-9, -2)),
    ("capanna_tonda", lambda n: capanna_tonda(n, 3.0, 2), (9, -7)),
    ("granaio_su_pali", lambda n: granaio(n, 3), (5, 3)),
    ("quercia_1", lambda n: albero(n, 1, 12.0, "quercia"), (-6, 13)),
    ("quercia_2", lambda n: albero(n, 2, 15.0, "quercia"), (14, 11)),
    ("carpino_1", lambda n: albero(n, 3, 10.0, "carpino"), (-16, 6)),
    ("pioppo_1", lambda n: albero(n, 4, 16.0, "pioppo"), (24, -2)),
    ("acero_autunno", lambda n: albero(n, 5, 11.0, "acero"), (3, 18)),
    ("cespuglio_1", lambda n: albero(n, 6, 2.6, "cespuglio"), (-2, 4)),
    ("cespuglio_2", lambda n: albero(n, 7, 3.4, "cespuglio"), (-14, -9)),
]
ALBERI = ("quercia", "carpino", "pioppo", "acero", "cespuglio")


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


def occlusione_chioma(ob, minimo=0.42):
    """Ombra interna delle chiome, calcolata e non cotta: con le carte così fitte la cottura
    darebbe nero ovunque. Scuro al centro e sotto, pieno sul guscio e in cima."""
    cx, cy, cz, rx, rz = ob["chioma"]
    me = ob.data
    attr = me.color_attributes["Occlusione"]
    for poly in me.polygons:
        if not me.materials[poly.material_index].name.startswith("foglie"):
            continue
        for li in poly.loop_indices:
            p = me.vertices[me.loops[li].vertex_index].co
            q = Vector(((p.x - cx) / rx, (p.y - cy) / rx, (p.z - cz) / rz))
            r = q.length
            guscio = min(max((r - 0.3) / 0.75, 0.0), 1.0)
            guscio = guscio * guscio * (3 - 2 * guscio)
            alto = 0.72 + 0.28 * min(max(q.z * 0.6 + 0.5, 0.0), 1.0)
            k = minimo + (1 - minimo) * guscio * alto
            attr.data[li].color = (k, k, k, 1.0)


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
        cuoci_occlusione(ob, 0.5 if nome.startswith(ALBERI) else 0.45)
        if "chioma" in ob:
            occlusione_chioma(ob)
        esporta(ob, os.path.join(USCITA, nome + ".glb"))
        d = ob.dimensions
        print(f"{nome}: {d.x:.1f} x {d.y:.1f} x {d.z:.1f} m, {len(ob.data.polygons)} facce")
        ob.location = (pos[0], pos[1], 0)
        ob.hide_render = True  # non deve ombreggiare gli asset cotti dopo
        oggetti.append(ob)
    bpy.data.objects.remove(suolo_ao, do_unlink=True)
    for ob in oggetti:
        ob.hide_render = False
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
    cam_d.ortho_scale = 56 if INQUADRATURA == "vicino" else 160
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


if __name__ == "__main__":
    main()
