"""Lotto del villaggio neolitico nello stile verosimile (24/11/2026).

Riusa materiali e forme della prova di stile (prova_stile_verosimile.py): case lunghe in tre
misure, capanne tonde in due, granaio su pali, palizzata (tratto e varco), luogo sacro,
focolare, fossa-silo, recinto per gli animali, catasta di legna, rocce; legnaia (25/11/2026).

Uso:  blender-py strumenti/blender/villaggio.py gioco/asset/villaggio

Le texture si generano prima con strumenti/blender/texture_procedurali.py.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prova_stile_verosimile as base  # noqa: E402  (legge la cartella d'uscita da sys.argv[1])
import bpy  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402

USCITA = base.USCITA


def materiali():
    m = base.M()
    m["pietra"] = base.materiale("pietra", "pietra")
    m["cenere"] = base.materiale("cenere", "pietra", tinta=(0.32, 0.3, 0.28))
    return m


def sasso(nome, dim, centro, mat, seme, appoggiato=True):
    """Sasso irregolare: icosfera deformata, base piatta se appoggiato al suolo."""
    rnd = random.Random(seme)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.5)
    for v in bm.verts:
        k = 1.0 + rnd.uniform(-0.18, 0.18)
        v.co = Vector((v.co.x * dim[0] * k, v.co.y * dim[1] * k, v.co.z * dim[2] * k))
    if appoggiato:
        for v in bm.verts:
            v.co.z = max(v.co.z, -dim[2] * 0.25)
    bmesh.ops.translate(bm, vec=Vector(centro) + Vector((0, 0, dim[2] * 0.25 if appoggiato else 0)), verts=bm.verts)
    bm.normal_update()
    return base.da_bmesh(nome, bm, mat, tile=1.2)


def palo_appuntito(parti, x, y, altezza, raggio, mat, rnd, pendenza=0.04):
    dx, dy = rnd.uniform(-pendenza, pendenza), rnd.uniform(-pendenza, pendenza)
    cima = (x + dx * altezza, y + dy * altezza, altezza)
    parti.append(base.cilindro_tra("palo", (x, y, -0.15), cima, raggio, raggio * 0.9, mat, lati=6))
    punta = (cima[0] + dx * 0.4, cima[1] + dy * 0.4, altezza + raggio * 2.2)
    parti.append(base.cilindro_tra("punta", cima, punta, raggio * 0.9, 0.01, mat, lati=6))


def palizzata_tratto(nome, seme, lungo=4.0):
    """Tratto di palizzata di pali appuntiti, con due traverse dietro."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    n = int(lungo / 0.26)
    for k in range(n):
        x = -lungo / 2 + (k + 0.5) * lungo / n + rnd.uniform(-0.03, 0.03)
        palo_appuntito(parti, x, rnd.uniform(-0.04, 0.04), rnd.uniform(2.2, 2.65), rnd.uniform(0.1, 0.13), m["corteccia"], rnd)
    for z in (0.6, 1.7):
        parti.append(base.cilindro_tra("traversa", (-lungo / 2, -0.2, z), (lungo / 2, -0.2, z + rnd.uniform(-0.06, 0.06)), 0.07, 0.07, m["legno"], lati=6, uv_tile=1.0))
    return base.unisci(nome, parti)


def palizzata_varco(nome, seme):
    """Varco nella palizzata: due pali grossi, architrave, mezzo tratto per parte."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    for x in (-1.35, 1.35):
        parti.append(base.cilindro_tra("stipite", (x, 0, -0.2), (x, 0, 3.0), 0.2, 0.18, m["corteccia"], lati=7))
    parti.append(base.cilindro_tra("architrave", (-1.7, 0, 3.0), (1.7, 0, 3.05), 0.16, 0.16, m["legno"], lati=7, uv_tile=1.0))
    for lato in (-1, 1):
        for k in range(4):
            x = lato * (1.65 + k * 0.26)
            palo_appuntito(parti, x, rnd.uniform(-0.04, 0.04), rnd.uniform(2.2, 2.6), rnd.uniform(0.1, 0.13), m["corteccia"], rnd)
    return base.unisci(nome, parti)


def luogo_sacro(nome, seme):
    """Cerchio di pali di legno attorno a una pietra eretta."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    n = 9
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.08, 0.08)
        r = 4.2 + rnd.uniform(-0.2, 0.2)
        h = rnd.uniform(2.3, 2.9)
        parti.append(base.cilindro_tra("palo", (r * math.cos(a), r * math.sin(a), -0.2), (r * math.cos(a), r * math.sin(a), h), 0.2, 0.15, m["corteccia"], lati=7))
    parti.append(sasso("stele", (0.75, 0.5, 2.6), (0, 0, 0), m["pietra"], seme + 1))
    for k in range(5):
        a = rnd.uniform(0, 2 * math.pi)
        parti.append(sasso("sasso", (0.4, 0.35, 0.25), (math.cos(a) * 1.0, math.sin(a) * 1.0, 0), m["pietra"], seme + 10 + k))
    return base.unisci(nome, parti)


def focolare(nome, seme):
    """Anello di sassi con cenere e qualche ciocco."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    for k in range(11):
        a = 2 * math.pi * k / 11 + rnd.uniform(-0.1, 0.1)
        parti.append(sasso("sasso", (0.32, 0.26, 0.22), (math.cos(a) * 0.85, math.sin(a) * 0.85, 0), m["pietra"], seme + k))
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=0.75, radius2=0.6, depth=0.08)
    bmesh.ops.translate(bm, vec=Vector((0, 0, 0.03)), verts=bm.verts)
    parti.append(base.da_bmesh("cenere", bm, m["cenere"], tile=1.0))
    for k in range(3):
        a = k * 2.1 + rnd.uniform(-0.3, 0.3)
        p0 = (math.cos(a) * 0.55, math.sin(a) * 0.55, 0.08)
        p1 = (math.cos(a + math.pi) * 0.15, math.sin(a + math.pi) * 0.15, 0.32)
        parti.append(base.cilindro_tra("ciocco", p0, p1, 0.07, 0.06, m["corteccia"], lati=6))
    return base.unisci(nome, parti)


def fossa_silo(nome, seme):
    """Fossa-silo per il grano: cupola bassa d'argilla chiusa da una lastra di pietra."""
    m = materiali()
    rnd = random.Random(seme)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=7, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.01], context="VERTS")
    for v in bm.verts:
        v.co = Vector((v.co.x * 1.05, v.co.y * 1.05, v.co.z * 0.38 + rnd.uniform(-0.02, 0.02)))
    bm.normal_update()
    parti = [base.da_bmesh("cupola", bm, m["argilla"], tile=1.5)]
    parti.append(sasso("lastra", (0.75, 0.65, 0.16), (0, 0, 0.33), m["pietra"], seme + 1, appoggiato=False))
    for k in range(3):
        a = rnd.uniform(0, 2 * math.pi)
        parti.append(sasso("sasso", (0.25, 0.22, 0.18), (math.cos(a) * 1.25, math.sin(a) * 1.25, 0), m["pietra"], seme + 5 + k))
    return base.unisci(nome, parti)


def recinto_animali(nome, seme, raggio=5.0):
    """Recinto tondo di graticcio: pali e vimini intrecciati, con un'apertura."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    n = 22
    apertura = 2  # pali mancanti all'ingresso
    pali = []
    for k in range(n - apertura):
        a = 2 * math.pi * (k + apertura / 2 + 0.5) / n
        x, y = raggio * math.cos(a), raggio * math.sin(a)
        pali.append((x, y, a))
        parti.append(base.cilindro_tra("palo", (x, y, -0.15), (x, y, rnd.uniform(1.25, 1.45)), 0.07, 0.06, m["corteccia"], lati=6))
    # Vimini: a ogni palo passano alternativamente davanti e dietro (intreccio).
    for riga in range(6):
        z = 0.2 + riga * 0.19
        for k in range(len(pali) - 1):
            (x0, y0, a0), (x1, y1, a1) = pali[k], pali[k + 1]
            s0 = 0.06 if (k + riga) % 2 == 0 else -0.06
            p0 = ((raggio + s0) * math.cos(a0), (raggio + s0) * math.sin(a0), z + rnd.uniform(-0.02, 0.02))
            p1 = ((raggio - s0) * math.cos(a1), (raggio - s0) * math.sin(a1), z + rnd.uniform(-0.02, 0.02))
            parti.append(base.cilindro_tra("vimine", p0, p1, 0.035, 0.035, m["legno"], lati=4, uv_tile=0.8))
    return base.unisci(nome, parti)


def catasta_legna(nome, seme):
    """Catasta di tronchi tagliati, tre file."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    r = 0.16
    for fila, quanti in enumerate((4, 3, 2)):
        for k in range(quanti):
            y = (k - (quanti - 1) / 2) * r * 2.05
            z = r + fila * r * 1.75
            dx = rnd.uniform(-0.12, 0.12)
            parti.append(base.cilindro_tra("tronco", (-1.1 + dx, y, z), (1.1 + dx, y, z), r * rnd.uniform(0.85, 1.05), r * rnd.uniform(0.85, 1.05), m["corteccia"], lati=7, uv_tile=1.0))
    return base.unisci(nome, parti)


def legnaia(nome, seme):
    """Legnaia (decisione di Fede del 25/11/2026): tettoia a una falda su pali, con le cataste di
    tronchi sotto, un ceppo con l'ascia e i trucioli a terra."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    lungo, largo = 4.6, 2.4
    alto_davanti, alto_dietro = 2.3, 1.6
    # Pali: tre davanti (alti) e tre dietro (bassi), appena storti.
    for fila, (y, h) in enumerate(((-largo / 2, alto_davanti), (largo / 2, alto_dietro))):
        for k in range(3):
            x = (k - 1) * lungo / 2 + rnd.uniform(-0.08, 0.08)
            parti.append(base.cilindro_tra("palo", (x, y, -0.15), (x + rnd.uniform(-0.04, 0.04), y, h), 0.09, 0.08, m["corteccia"], lati=6))
        # Trave lungo la fila.
        parti.append(base.cilindro_tra("trave", (-lungo / 2 - 0.3, y, h - 0.05), (lungo / 2 + 0.3, y, h - 0.05), 0.07, 0.07, m["corteccia"], lati=6))
    # Correnti trasversali e falda di paglia appena irregolare.
    for k in range(5):
        x = (k - 2) * lungo / 4
        parti.append(base.cilindro_tra("corrente", (x, -largo / 2 - 0.4, alto_davanti + 0.05), (x, largo / 2 + 0.4, alto_dietro + 0.05), 0.045, 0.045, m["legno"], lati=5))
    falda = base.scatola("falda", (lungo + 0.7, largo + 1.0, 0.16), (0, 0, (alto_davanti + alto_dietro) / 2 + 0.16), m["paglia"], tagli=3)
    # Davanti (y negativo) più alta: la falda scende verso il retro.
    pendenza = math.atan2(alto_davanti - alto_dietro, largo + 0.8)
    falda.rotation_euler = (-pendenza, 0, 0)
    for v in falda.data.vertices:
        v.co.z += rnd.uniform(-0.04, 0.04)
    parti.append(falda)
    # Cataste sotto la tettoia: tronchi corti accatastati su due file, a piramide.
    r = 0.14
    for blocco, x0 in enumerate((-1.2, 1.1)):
        for fila, quanti in enumerate((5, 4, 3, 2)):
            for k in range(quanti):
                y = (k - (quanti - 1) / 2) * r * 2.05
                z = r + fila * r * 1.75
                dx = rnd.uniform(-0.08, 0.08)
                parti.append(base.cilindro_tra("tronco", (x0 - 0.75 + dx, y, z), (x0 + 0.75 + dx, y, z), r * rnd.uniform(0.85, 1.05), r * rnd.uniform(0.85, 1.05), m["corteccia"], lati=7, uv_tile=1.0))
    # Fuori, di fianco alla tettoia, una catasta che si vede dall'alto.
    for fila, quanti in enumerate((4, 3, 2, 1)):
        for k in range(quanti):
            x = lungo / 2 + 1.0 + (k - (quanti - 1) / 2) * r * 2.05
            z = r + fila * r * 1.75
            dy = rnd.uniform(-0.08, 0.08)
            parti.append(base.cilindro_tra("tronco", (x, -0.8 + dy, z), (x, 0.8 + dy, z), r * rnd.uniform(0.85, 1.05), r * rnd.uniform(0.85, 1.05), m["corteccia"], lati=7, uv_tile=1.0))
    # Davanti: un ceppo con l'ascia (manico di legno, lama di pietra), tronchi interi e trucioli.
    cx, cy = 0.6, -largo / 2 - 1.3
    parti.append(base.cilindro_tra("ceppo", (cx, cy, 0.0), (cx, cy, 0.55), 0.32, 0.3, m["corteccia"], lati=9))
    parti.append(base.cilindro_tra("manico", (cx - 0.05, cy + 0.05, 0.52), (cx - 0.55, cy - 0.35, 0.95), 0.03, 0.025, m["legno"], lati=5))
    parti.append(sasso("lama", (0.22, 0.07, 0.12), (cx - 0.02, cy + 0.06, 0.5), m["pietra"], seme + 1, appoggiato=False))
    for k in range(2):
        y = cy - 0.9 - k * 0.5
        parti.append(base.cilindro_tra("tronco_intero", (-2.4, y, 0.2), (-0.2, y + rnd.uniform(-0.3, 0.3), 0.18), 0.2, 0.16, m["corteccia"], lati=7, uv_tile=1.2))
    for k in range(14):
        a = rnd.uniform(0, 2 * math.pi)
        d = rnd.uniform(0.4, 1.1)
        x, y = cx + d * math.cos(a), cy + d * math.sin(a)
        parti.append(base.scatola("truciolo", (rnd.uniform(0.12, 0.22), rnd.uniform(0.05, 0.09), 0.03), (x, y, 0.015), m["legno"]))
    return base.unisci(nome, parti)


def roccia(nome, seme, dim):
    m = materiali()
    return base.unisci(nome, [sasso("roccia", dim, (0, 0, 0), m["pietra"], seme)])


ASSET = [
    ("casa_lunga_piccola", lambda n: base.casa_lunga(n, 9.0, 5.0, 11)),
    ("casa_lunga_media", lambda n: base.casa_lunga(n, 12.0, 6.0, 1)),
    ("casa_lunga_grande", lambda n: base.casa_lunga(n, 18.0, 7.0, 13)),
    ("capanna_tonda", lambda n: base.capanna_tonda(n, 3.0, 2)),
    ("capanna_tonda_piccola", lambda n: base.capanna_tonda(n, 2.3, 14)),
    ("granaio_su_pali", lambda n: base.granaio(n, 3)),
    ("palizzata_tratto", lambda n: palizzata_tratto(n, 21)),
    ("palizzata_varco", lambda n: palizzata_varco(n, 22)),
    ("luogo_sacro", lambda n: luogo_sacro(n, 23)),
    ("focolare", lambda n: focolare(n, 24)),
    ("fossa_silo", lambda n: fossa_silo(n, 25)),
    ("recinto_animali", lambda n: recinto_animali(n, 26)),
    ("catasta_legna", lambda n: catasta_legna(n, 27)),
    ("legnaia", lambda n: legnaia(n, 31)),
    ("roccia_1", lambda n: roccia(n, 28, (1.6, 1.2, 0.9))),
    ("roccia_2", lambda n: roccia(n, 29, (2.4, 1.8, 1.3))),
    ("roccia_3", lambda n: roccia(n, 30, (0.9, 0.8, 0.6))),
]


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(USCITA, exist_ok=True)
    bpy.context.scene.world = bpy.data.worlds.new("Mondo")
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    for nome, fabbrica in ASSET:
        ob = fabbrica(nome)
        base.cuoci_occlusione(ob, 0.45)
        base.esporta(ob, os.path.join(USCITA, nome + ".glb"))
        d = ob.dimensions
        print(f"{nome}: {d.x:.1f} x {d.y:.1f} x {d.z:.1f} m, {len(ob.data.polygons)} facce")
        bpy.data.objects.remove(ob, do_unlink=True)


if __name__ == "__main__":
    main()
