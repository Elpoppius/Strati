"""Alberi da posare sulla mappa: varianti per specie, in versione completa e leggera.

Riusa il generatore della prova di stile (prova_stile_verosimile.py, funzione albero).
La versione completa si usa da vicino; quella leggera (poche carte grandi, senza rami)
a media distanza; da lontano il terreno dipinge la volta delle chiome.

Uso:  blender-py strumenti/blender/alberi_mappa.py gioco/asset/alberi

L'acero autunnale non c'è: le stagioni nel gioco non sono ancora decise e un acero
giallo in un bosco estivo stonerebbe.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prova_stile_verosimile as base  # noqa: E402  (legge la cartella d'uscita da sys.argv[1])
import bpy  # noqa: E402
import bmesh  # noqa: E402
import math  # noqa: E402
import random  # noqa: E402
from mathutils import Vector  # noqa: E402

USCITA = base.USCITA

# (specie, numero della variante, altezza in metri)
# Canneti (cannuccia di palude): ciuffi di foglie lunghe e fusti con il pennacchio.
CANNE = [("canna", 1, 2.6), ("canna", 2, 3.1)]

VARIANTI = [
    ("quercia", 1, 12.0), ("quercia", 2, 14.5), ("quercia", 3, 10.5),
    ("carpino", 1, 10.0), ("carpino", 2, 11.5),
    ("pioppo", 1, 16.0), ("pioppo", 2, 18.5),
    ("cespuglio", 1, 2.8), ("cespuglio", 2, 3.5),
]


def canna(nome, seme, alta, leggero=False):
    """Ciuffo di canne: lame strette e arcuate (fronte e retro), colore nei vertici dal verde
    scuro alla base al giallo-paglia in cima, e qualche pennacchio bruno. Niente texture."""
    rnd = random.Random(seme)
    bm = bmesh.new()
    colori = []  # un colore per angolo di faccia, nell'ordine di creazione
    n_lame = 14 if leggero else 64
    larg = 0.24 if leggero else 0.12

    def lama(base, verso, h, w, segmenti, c0, c1, curva):
        lato = Vector((-verso.y, verso.x, 0.0)).normalized()
        punti = []
        for k in range(segmenti + 1):
            t = k / segmenti
            p = base + Vector((verso.x * curva * t * t * h, verso.y * curva * t * t * h, t * h))
            punti.append((p, w * (1.0 - 0.85 * t), t))
        for k in range(segmenti):
            (p0, w0, t0), (p1, w1, t1) = punti[k], punti[k + 1]
            q = [p0 - lato * w0 / 2, p0 + lato * w0 / 2, p1 + lato * w1 / 2, p1 - lato * w1 / 2]
            tt = [t0, t0, t1, t1]
            for ordine in ((0, 1, 2, 3), (3, 2, 1, 0)):
                bm.faces.new([bm.verts.new(q[i]) for i in ordine])
                for i in ordine:
                    c = c0.lerp(c1, tt[i])
                    # Ombra alla base del ciuffo.
                    k_ao = 0.45 + 0.55 * min(1.0, tt[i] * 1.6)
                    colori.append((c.x * k_ao, c.y * k_ao, c.z * k_ao, 1.0))

    # Valori lineari (come arrivano a Godot): verde vivo alla base, paglia chiara in cima.
    verde = Vector((0.27, 0.36, 0.1))
    paglia = Vector((0.74, 0.66, 0.36))
    for _ in range(n_lame):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(0, 0.55)
        base = Vector((math.cos(a) * r, math.sin(a) * r, -0.05))
        verso = Vector((math.cos(a), math.sin(a), 0.0))
        h = alta * rnd.uniform(0.55, 0.95)
        lama(base, verso, h, larg * rnd.uniform(0.8, 1.3), 2 if leggero else 3, verde, verde.lerp(paglia, rnd.uniform(0.3, 0.8)), rnd.uniform(0.25, 0.7))
    # Fusti con il pennacchio in cima.
    for _ in range(3 if leggero else 9):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(0, 0.4)
        base = Vector((math.cos(a) * r, math.sin(a) * r, -0.05))
        verso = Vector((math.cos(a), math.sin(a), 0.0))
        h = alta * rnd.uniform(0.95, 1.1)
        lama(base, verso, h, 0.03 if not leggero else 0.06, 1, verde, paglia, 0.08)
        cima = base + Vector((verso.x * 0.08 * h, verso.y * 0.08 * h, h))
        lama(cima - Vector((0, 0, 0.05)), verso, 0.38, 0.12, 1, Vector((0.46, 0.35, 0.22)), Vector((0.58, 0.47, 0.32)), 0.6)
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    # Colori come attributo a byte per angolo, l'unico del modello: è quello che arriva a Godot
    # (un attributo creato da bmesh finiva in un secondo canale e le canne risultavano bianche).
    attr = me.color_attributes.new("Occlusione", "BYTE_COLOR", "CORNER")
    for li, c in enumerate(colori):
        attr.data[li].color = c
    # Normali verso l'alto e verso l'esterno: il ciuffo prende luce come un volume.
    normali = []
    for poly in me.polygons:
        for li in poly.loop_indices:
            p = me.vertices[me.loops[li].vertex_index].co
            normali.append(Vector((p.x * 0.6, p.y * 0.6, 1.0)).normalized())
    me.normals_split_custom_set(normali)
    ob = bpy.data.objects.new(nome, me)
    bpy.context.scene.collection.objects.link(ob)
    mat = bpy.data.materials.get("canne") or bpy.data.materials.new("canne")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Roughness"].default_value = 0.85
    mat.use_backface_culling = True
    ob.data.materials.append(mat)
    ob.data.color_attributes.active_color = attr
    ob.data.color_attributes.render_color_index = 0
    return ob


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(USCITA, exist_ok=True)
    bpy.context.scene.world = bpy.data.worlds.new("Mondo")
    # Suolo temporaneo per l'occlusione alla base dei tronchi.
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    for i, (specie, n, alta) in enumerate(VARIANTI):
        seme = 100 + i * 7
        for leggero in (False, True):
            nome = f"{specie}_{n}" + ("_leggero" if leggero else "")
            ob = base.albero(nome, seme, alta, specie, leggero)
            base.cuoci_occlusione(ob, 0.5)
            base.occlusione_chioma(ob)
            base.esporta(ob, os.path.join(USCITA, nome + ".glb"))
            d = ob.dimensions
            print(f"{nome}: {d.x:.1f} x {d.y:.1f} x {d.z:.1f} m, {len(ob.data.polygons)} facce")
            bpy.data.objects.remove(ob, do_unlink=True)
    for i, (specie, n, alta) in enumerate(CANNE):
        for leggero in (False, True):
            nome = f"{specie}_{n}" + ("_leggero" if leggero else "")
            ob = canna(nome, 500 + i * 11, alta, leggero)
            base.esporta(ob, os.path.join(USCITA, nome + ".glb"))
            d = ob.dimensions
            print(f"{nome}: {d.x:.1f} x {d.y:.1f} x {d.z:.1f} m, {len(ob.data.polygons)} facce")
            bpy.data.objects.remove(ob, do_unlink=True)


if __name__ == "__main__":
    main()
