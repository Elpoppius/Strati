"""Lotto del villaggio neolitico nello stile verosimile (24/11/2026).

Riusa materiali e forme della prova di stile (prova_stile_verosimile.py): case lunghe in tre
misure, capanne tonde in due, granaio su pali, palizzata (tratto e varco), luogo sacro,
focolare, fossa-silo, recinto per gli animali, catasta di legna, rocce; legnaia, capanno da pesca e posta di caccia (25/11/2026);
i cantieri di granaio, legnaia, capanno, posta e luogo sacro (scheletri, 25/11/2026 sera);
lo stabbio del pascolo (26/11/2026). Gli animali: strumenti/blender/animali.py.

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
    falda = base.scatola("falda", (lungo + 0.7, largo + 1.0, 0.16), (0, 0, 0), m["paglia"], tagli=3)
    for v in falda.data.vertices:
        v.co.z += rnd.uniform(-0.04, 0.04)
    # Davanti (y negativo) più alta: la falda scende verso il retro; si inclina nell'origine e poi
    # si mette al suo posto.
    pendenza = math.atan2(alto_davanti - alto_dietro, largo + 0.8)
    falda.rotation_euler = (-pendenza, 0, 0)
    falda.location = (0, 0, (alto_davanti + alto_dietro) / 2 + 0.16)
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


def capanno_pesca(nome, seme):
    """Capanno da pesca (decisione di Fede del 25/11/2026): capanno di canne e legno sulla riva,
    rastrelliere con reti e pesce a seccare, una piroga scavata in un tronco tirata a riva e
    qualche nassa di vimini. L'acqua è verso y positivo."""
    m = materiali()
    m["canne"] = base.materiale("canne", "paglia", tinta=(0.78, 0.74, 0.6))
    m["pesce"] = base.materiale("pesce", "pietra", tinta=(0.72, 0.74, 0.76))
    m["rete"] = base.materiale("rete", "legno", tinta=(0.55, 0.5, 0.42))
    rnd = random.Random(seme)
    parti = []
    # Capanno: telaio di pali, pareti di canne in fasci verticali, tetto a due falde di canne.
    lungo, largo, alto = 3.2, 2.4, 1.6
    for x in (-lungo / 2, lungo / 2):
        for y in (-largo / 2, largo / 2):
            parti.append(base.cilindro_tra("palo", (x, y, -0.1), (x, y, alto), 0.07, 0.06, m["corteccia"], lati=6))
    for lato in range(4):
        n = 14 if lato % 2 == 0 else 10
        for k in range(n):
            t = (k + 0.5) / n
            if lato == 0:
                x, y = -lungo / 2 + t * lungo, -largo / 2
            elif lato == 1:
                x, y = lungo / 2, -largo / 2 + t * largo
            elif lato == 2:
                x, y = lungo / 2 - t * lungo, largo / 2
            else:
                x, y = -lungo / 2, largo / 2 - t * largo
            # Una porta sul lato dell'acqua (lato 2, al centro).
            if lato == 2 and 0.4 < t < 0.6:
                continue
            h = alto + rnd.uniform(-0.08, 0.06)
            parti.append(base.cilindro_tra("canne", (x, y, 0.0), (x + rnd.uniform(-0.03, 0.03), y + rnd.uniform(-0.03, 0.03), h), 0.075, 0.06, m["canne"], lati=5, uv_tile=0.8))
    colmo = alto + 0.95
    for verso in (-1, 1):
        # La falda nasce nell'origine, si inclina e poi si mette al suo posto (la rotazione è
        # attorno all'origine dell'oggetto).
        falda = base.scatola("falda", (lungo + 0.6, 1.75, 0.14), (0, 0, 0), m["canne"], tagli=3)
        for v in falda.data.vertices:
            v.co.z += rnd.uniform(-0.03, 0.03)
        falda.rotation_euler = (-verso * math.atan2(colmo - alto, largo / 2 + 0.2), 0, 0)
        falda.location = (0, verso * 0.72, (alto + colmo) / 2 + 0.05)
        parti.append(falda)
    parti.append(base.cilindro_tra("colmo", (-lungo / 2 - 0.35, 0, colmo), (lungo / 2 + 0.35, 0, colmo), 0.06, 0.06, m["corteccia"], lati=6))
    # Rastrelliera: due cavalletti e due pertiche, con reti appese e pesci a seccare.
    rx0, rx1, ry = -lungo / 2 - 2.6, -lungo / 2 - 0.6, 0.8
    for x in (rx0, rx1):
        parti.append(base.cilindro_tra("cavalletto", (x, ry - 0.5, 0.0), (x, ry, 1.6), 0.05, 0.045, m["corteccia"], lati=5))
        parti.append(base.cilindro_tra("cavalletto", (x, ry + 0.5, 0.0), (x, ry, 1.6), 0.05, 0.045, m["corteccia"], lati=5))
    for z in (1.55, 1.1):
        parti.append(base.cilindro_tra("pertica", (rx0 - 0.2, ry, z), (rx1 + 0.2, ry, z), 0.035, 0.035, m["legno"], lati=5))
    # Rete: una maglia di fili sottili che pende dalla pertica alta.
    for k in range(9):
        x = rx0 + 0.15 + k * (rx1 - rx0 - 0.3) / 8
        parti.append(base.cilindro_tra("rete", (x, ry, 1.55), (x + rnd.uniform(-0.05, 0.05), ry + 0.04, 0.6), 0.012, 0.012, m["rete"], lati=3))
    for z in (1.35, 1.1, 0.85, 0.62):
        parti.append(base.cilindro_tra("rete", (rx0 + 0.15, ry + 0.02, z), (rx1 - 0.15, ry + 0.02, z - 0.03), 0.012, 0.012, m["rete"], lati=3))
    # Pesci appesi per la coda alla pertica bassa.
    for k in range(7):
        x = rx0 + 0.2 + k * (rx1 - rx0 - 0.4) / 6
        lung = rnd.uniform(0.28, 0.4)
        parti.append(sasso("pesce", (0.06, 0.12, lung), (x, ry - 0.06, 1.1 - lung * 0.7), m["pesce"], seme + 10 + k, appoggiato=False))
    # Piroga scavata in un tronco, tirata a riva verso l'acqua.
    px, py = 1.0, largo / 2 + 2.2
    scafo = sasso("piroga", (4.2, 0.62, 0.42), (px, py, 0.0), m["corteccia"], seme + 3)
    for v in scafo.data.vertices:
        # Punte affusolate e fondo appiattito.
        f = 1.0 - min(1.0, abs(v.co.x - px) / 2.1) ** 2
        v.co.y = py + (v.co.y - py) * (0.35 + 0.65 * f)
        v.co.z = max(v.co.z, 0.02) * (0.6 + 0.4 * f)
    parti.append(scafo)
    parti.append(base.scatola("cavo", (3.2, 0.36, 0.06), (px, py, 0.36), m["vano"]))
    parti.append(base.cilindro_tra("pagaia", (px - 1.0, py + 0.6, 0.05), (px + 0.6, py + 0.9, 0.08), 0.025, 0.025, m["legno"], lati=4))
    parti.append(base.scatola("pala", (0.35, 0.14, 0.03), (px + 0.75, py + 0.93, 0.08), m["legno"]))
    # Nasse di vimini: coni intrecciati appoggiati a terra.
    for k in range(3):
        nx, ny = lungo / 2 + 0.8 + k * 0.7, -0.6 + rnd.uniform(-0.3, 0.3)
        a = rnd.uniform(0, 2 * math.pi)
        fine = (nx + 0.9 * math.cos(a), ny + 0.9 * math.sin(a), 0.22)
        parti.append(base.cilindro_tra("nassa", (nx, ny, 0.24), fine, 0.24, 0.05, m["legno"], lati=8, uv_tile=0.5))
    return base.unisci(nome, parti)


def posta_caccia(nome, seme):
    """Posta di caccia (decisione di Fede del 25/11/2026): riparo basso di frasche al margine del
    bosco, una rastrelliera con le pelli a seccare, un piccolo focolare e un palo con un palco di
    corna. Il riparo ha la schiena al bosco (verso y positivo) e si apre verso la radura."""
    m = materiali()
    m["pelle"] = base.materiale("pelle", "argilla", tinta=(0.56, 0.4, 0.27))
    m["corno"] = base.materiale("corno", "legno", tinta=(0.82, 0.77, 0.66))
    m["frasche"] = base.materiale("frasche", "paglia", tinta=(0.42, 0.42, 0.26))
    m["laccio"] = base.materiale("laccio", "legno", tinta=(0.45, 0.36, 0.26))
    rnd = random.Random(seme)
    parti = []
    # Riparo a una falda appoggiata a terra: due pali a forcella davanti, un colmo, i correnti
    # che scendono fino al suolo dietro, coperti di frasche.
    lungo, alto, fondo = 3.4, 1.45, 2.3
    y0 = -0.9
    for x in (-lungo / 2 + 0.2, lungo / 2 - 0.2):
        parti.append(base.cilindro_tra("forcella", (x, y0, -0.15), (x, y0, alto + 0.05), 0.08, 0.07, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("forca", (x, y0, alto - 0.15), (x + 0.15, y0 - 0.05, alto + 0.25), 0.04, 0.03, m["corteccia"], lati=5))
    parti.append(base.cilindro_tra("colmo", (-lungo / 2 - 0.2, y0, alto + 0.08), (lungo / 2 + 0.2, y0, alto + 0.08), 0.07, 0.06, m["corteccia"], lati=6))
    for k in range(6):
        x = -lungo / 2 + 0.1 + k * (lungo - 0.2) / 5 + rnd.uniform(-0.06, 0.06)
        parti.append(base.cilindro_tra("corrente", (x, y0 - 0.25, alto + 0.22), (x + rnd.uniform(-0.1, 0.1), y0 + fondo + 0.15, -0.05), 0.04, 0.035, m["corteccia"], lati=5))
    # Falda di frasche secche: nasce nell'origine, si inclina e poi si mette al suo posto.
    pend = math.atan2(alto, fondo)
    lung_falda = math.hypot(alto, fondo) + 0.2
    falda = base.scatola("falda", (lungo + 0.3, lung_falda, 0.12), (0, 0, 0), m["frasche"], tagli=3)
    for v in falda.data.vertices:
        v.co.z += rnd.uniform(-0.04, 0.04)
    falda.rotation_euler = (-pend, 0, 0)
    falda.location = (0, y0 + fondo / 2, alto / 2 + 0.12)
    parti.append(falda)
    # Rami con le foglie sopra la falda: ciuffi di carte di foglie come le chiome degli alberi,
    # freschi (quercia) e già secchi (foglie d'autunno).
    normale = Vector((0, math.sin(pend), math.cos(pend)))
    for foglie, quanti in (("foglie_quercia", 9), ("foglie_autunno", 6)):
        lobi = []
        for k in range(quanti):
            t = rnd.uniform(0.08, 0.92)
            x = rnd.uniform(-lungo / 2 + 0.2, lungo / 2 - 0.2)
            c = Vector((x, y0 + t * fondo, alto * (1 - t) + 0.12)) + normale * 0.12
            lobi.append((c, rnd.uniform(0.38, 0.5)))
        centro = Vector((0, y0 + fondo / 2, alto / 2))
        ciuffo = base.chioma("frasche_" + foglie, lobi, centro, lungo / 2, 0.6, rnd, m[foglie])
        # Le carte più basse si appoggiano a terra, come rami caduti.
        for v in ciuffo.data.vertices:
            v.co.z = max(v.co.z, 0.03)
        parti.append(ciuffo)
    # Fianchi chiusi da qualche frasca appoggiata di sbieco.
    for lato in (-1, 1):
        for k in range(4):
            t = (k + 0.5) / 4
            y = y0 + t * fondo
            h = alto * (1 - t) + 0.1
            x = lato * (lungo / 2 + 0.05)
            parti.append(base.cilindro_tra("frasca", (x + lato * 0.25, y + rnd.uniform(-0.15, 0.15), 0.0), (x, y, h), 0.05, 0.02, m["corteccia"], lati=4))
    # Giaciglio di frasche sotto il riparo.
    parti.append(base.scatola("giaciglio", (lungo - 0.6, 1.0, 0.1), (0, y0 + 0.75, 0.05), m["frasche"]))
    # Davanti, un piccolo focolare.
    fx, fy = -0.3, y0 - 1.5
    for k in range(8):
        a = 2 * math.pi * k / 8 + rnd.uniform(-0.12, 0.12)
        parti.append(sasso("sasso", (0.24, 0.2, 0.17), (fx + math.cos(a) * 0.55, fy + math.sin(a) * 0.55, 0), m["pietra"], seme + 20 + k))
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.45, radius2=0.38, depth=0.06)
    bmesh.ops.translate(bm, vec=Vector((fx, fy, 0.03)), verts=bm.verts)
    parti.append(base.da_bmesh("cenere", bm, m["cenere"], tile=1.0))
    for k in range(3):
        a = k * 2.1 + rnd.uniform(-0.3, 0.3)
        parti.append(base.cilindro_tra("ciocco", (fx + math.cos(a) * 0.35, fy + math.sin(a) * 0.35, 0.06), (fx - math.cos(a) * 0.08, fy - math.sin(a) * 0.08, 0.24), 0.05, 0.045, m["corteccia"], lati=5))
    # Rastrelliera con le pelli: telaio di pali con una pelle tesa, legata ai lati.
    rx, ry = lungo / 2 + 1.5, y0 - 0.6
    larg, h = 1.5, 1.7
    for dx in (-larg / 2, larg / 2):
        parti.append(base.cilindro_tra("montante", (rx + dx, ry, -0.15), (rx + dx, ry, h), 0.05, 0.045, m["corteccia"], lati=5))
    for z in (h - 0.1, 0.25):
        parti.append(base.cilindro_tra("traversa", (rx - larg / 2 - 0.1, ry, z), (rx + larg / 2 + 0.1, ry, z), 0.04, 0.04, m["corteccia"], lati=5))
    zc = (h - 0.1 + 0.25) / 2
    parti.append(sasso("pelle", (larg - 0.35, 0.05, h - 0.75), (rx, ry, zc), m["pelle"], seme + 3, appoggiato=False))
    for k in range(6):
        a = 2 * math.pi * k / 6 + 0.3
        px, pz = rx + math.cos(a) * (larg / 2 - 0.2), zc + math.sin(a) * (h / 2 - 0.4)
        bx = rx + (larg / 2 if math.cos(a) > 0 else -larg / 2)
        parti.append(base.cilindro_tra("laccio", (px, ry, pz), (bx, ry, pz + rnd.uniform(-0.05, 0.05)), 0.01, 0.01, m["laccio"], lati=3))
    # Una seconda pelle stesa a terra, fermata da picchetti.
    gx, gy = rx - 0.2, ry - 1.6
    parti.append(sasso("pelle_a_terra", (1.3, 0.95, 0.04), (gx, gy, 0.0), m["pelle"], seme + 4))
    for k in range(6):
        a = 2 * math.pi * k / 6
        x, y = gx + math.cos(a) * 0.66, gy + math.sin(a) * 0.5
        parti.append(base.cilindro_tra("picchetto", (x, y, -0.05), (x, y, 0.14), 0.02, 0.012, m["legno"], lati=4))
    # Palo con un palco di corna, segno della posta.
    cx, cy = -lungo / 2 - 0.9, y0 - 0.8
    parti.append(base.cilindro_tra("palo", (cx, cy, -0.15), (cx, cy, 2.1), 0.06, 0.05, m["corteccia"], lati=6))
    for lato in (-1, 1):
        p0 = Vector((cx, cy, 2.05))
        p1 = p0 + Vector((lato * 0.25, -0.05, 0.3))
        p2 = p1 + Vector((lato * 0.15, 0.05, 0.35))
        parti.append(base.cilindro_tra("corno", p0, p1, 0.035, 0.03, m["corno"], lati=5))
        parti.append(base.cilindro_tra("corno", p1, p2, 0.03, 0.012, m["corno"], lati=5))
        for k, t in enumerate((0.45, 0.85)):
            q = p0 + (p1 - p0) * t if k == 0 else p1 + (p2 - p1) * 0.4
            parti.append(base.cilindro_tra("punta", q, q + Vector((lato * 0.05, -0.18, 0.15)), 0.02, 0.008, m["corno"], lati=4))
    # Due lance appoggiate al colmo.
    for k, x in enumerate((0.6, 0.9)):
        piede = (x, y0 - 0.9, 0.0)
        cima = (x + 0.1, y0 + 0.05, alto + 0.6)
        parti.append(base.cilindro_tra("lancia", piede, cima, 0.022, 0.02, m["legno"], lati=4))
        parti.append(sasso("punta_lancia", (0.05, 0.05, 0.16), (cima[0] + 0.02, cima[1] + 0.03, cima[2] + 0.06), m["pietra"], seme + 30 + k, appoggiato=False))
    return base.unisci(nome, parti)


# ---------- cantieri (decisione di Fede del 25/11/2026 sera) ----------
# Lo scheletro di ogni edificio mentre si costruisce: la stessa struttura del modello finito, solo
# pali e travi, senza tetto né pareti, con accanto i materiali e gli attrezzi. Stessa orientazione
# del modello finito, così nel gioco si sostituiscono senza girarli.

def materiali_a_terra(parti, m, rnd, x, y, seme, fasci="paglia", pali=4, lungo=3.0):
    """Mucchio di pali scortecciati stesi a terra e qualche fascio legato (paglia o canne)."""
    for k in range(pali):
        dy = (k - (pali - 1) / 2) * 0.2 + rnd.uniform(-0.03, 0.03)
        z = 0.07 + (0.12 if k in (1, 2) and pali > 3 else 0.0)
        dx = rnd.uniform(-0.25, 0.25)
        parti.append(base.cilindro_tra("palo_a_terra", (x - lungo / 2 + dx, y + dy, z), (x + lungo / 2 + dx, y + dy + rnd.uniform(-0.1, 0.1), z), 0.07, 0.06, m["corteccia"], lati=6, uv_tile=1.2))
    for k in range(3):
        fx, fy = x + rnd.uniform(-0.8, 0.8), y + 0.9 + k * 0.45
        parti.append(base.cilindro_tra("fascio", (fx - 0.7, fy, 0.18), (fx + 0.7, fy + rnd.uniform(-0.15, 0.15), 0.18), 0.18, 0.16, m[fasci], lati=8, uv_tile=0.8))
        parti.append(base.cilindro_tra("legaccio", (fx - 0.05, fy, 0.18), (fx + 0.05, fy, 0.18), 0.19, 0.19, m["legno"], lati=8))
    parti.append(sasso("pietra_lavoro", (0.4, 0.32, 0.22), (x + lungo / 2 + 0.4, y - 0.3, 0), m["pietra"], seme + 40))


def cantiere_granaio(nome, seme):
    """Granaio in costruzione: i quattro pali con i cappelli, il telaio del piano con poche assi e i
    montanti della cella; accanto la scala, i pali, i fasci di paglia e un mucchio d'argilla."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    for x in (-1.1, 1.1):
        for y in (-1.1, 1.1):
            parti.append(base.cilindro_tra("palo", (x, y, 0), (x, y, 1.05), 0.14, 0.12, m["corteccia"], lati=7))
            parti.append(base.cilindro_tra("cappello", (x, y, 1.05), (x, y, 1.13), 0.32, 0.3, m["legno"], lati=8))
            # Montanti della cella, ancora senza pareti.
            parti.append(base.cilindro_tra("montante", (x * 1.05, y * 1.05, 1.2), (x * 1.05, y * 1.05, 2.75), 0.07, 0.06, m["corteccia"], lati=6))
    for y in (-1.3, 1.3):
        parti.append(base.cilindro_tra("trave", (-1.5, y, 1.22), (1.5, y, 1.22), 0.08, 0.08, m["corteccia"], lati=6))
    for k in range(4):
        parti.append(base.scatola("asse", (0.32, 2.9, 0.06), (-1.2 + k * 0.38, 0, 1.3), m["legno"]))
    parti.append(base.cilindro_tra("architrave", (-1.25, -1.2, 2.75), (1.25, -1.2, 2.75), 0.06, 0.06, m["corteccia"], lati=6))
    # Scala a pioli appoggiata al piano.
    for dx in (-0.22, 0.22):
        parti.append(base.cilindro_tra("staggio", (1.9 + dx * 0.2, dx, 0.0), (1.4 + dx * 0.2, dx, 1.6), 0.035, 0.03, m["legno"], lati=5))
    for k in range(5):
        t = (k + 0.5) / 5
        parti.append(base.cilindro_tra("piolo", (1.9 - 0.5 * t, -0.22, 1.6 * t), (1.9 - 0.5 * t, 0.22, 1.6 * t), 0.025, 0.025, m["legno"], lati=4))
    materiali_a_terra(parti, m, rnd, -0.2, -2.7, seme)
    parti.append(sasso("argilla", (1.0, 0.8, 0.4), (-2.4, 0.6, 0), m["argilla"], seme + 50))
    return base.unisci(nome, parti)


def cantiere_legnaia(nome, seme):
    """Legnaia in costruzione: pali e travi, metà dei correnti, niente falda; accanto i pali stesi,
    i fasci di paglia e il ceppo con l'ascia."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    lungo, largo = 4.6, 2.4
    alto_davanti, alto_dietro = 2.3, 1.6
    for fila, (y, h) in enumerate(((-largo / 2, alto_davanti), (largo / 2, alto_dietro))):
        for k in range(3):
            x = (k - 1) * lungo / 2 + rnd.uniform(-0.08, 0.08)
            parti.append(base.cilindro_tra("palo", (x, y, -0.15), (x + rnd.uniform(-0.04, 0.04), y, h), 0.09, 0.08, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("trave", (-lungo / 2 - 0.3, y, h - 0.05), (lungo / 2 + 0.3, y, h - 0.05), 0.07, 0.07, m["corteccia"], lati=6))
    for k in range(3):
        x = (k - 2) * lungo / 4
        parti.append(base.cilindro_tra("corrente", (x, -largo / 2 - 0.4, alto_davanti + 0.05), (x, largo / 2 + 0.4, alto_dietro + 0.05), 0.045, 0.045, m["legno"], lati=5))
    materiali_a_terra(parti, m, rnd, 0.0, -largo / 2 - 1.6, seme)
    cx, cy = lungo / 2 + 1.0, 0.0
    parti.append(base.cilindro_tra("ceppo", (cx, cy, 0.0), (cx, cy, 0.55), 0.32, 0.3, m["corteccia"], lati=9))
    parti.append(base.cilindro_tra("manico", (cx - 0.05, cy + 0.05, 0.52), (cx - 0.55, cy - 0.35, 0.95), 0.03, 0.025, m["legno"], lati=5))
    parti.append(sasso("lama", (0.22, 0.07, 0.12), (cx - 0.02, cy + 0.06, 0.5), m["pietra"], seme + 1, appoggiato=False))
    return base.unisci(nome, parti)


def cantiere_capanno(nome, seme):
    """Capanno da pesca in costruzione: i quattro pali, le capriate e il colmo, un tratto di
    parete di canne; accanto i fasci di canne e i pali. L'acqua è verso y positivo."""
    m = materiali()
    m["canne"] = base.materiale("canne", "paglia", tinta=(0.78, 0.74, 0.6))
    rnd = random.Random(seme)
    parti = []
    lungo, largo, alto = 3.2, 2.4, 1.6
    colmo = alto + 0.95
    for x in (-lungo / 2, lungo / 2):
        for y in (-largo / 2, largo / 2):
            parti.append(base.cilindro_tra("palo", (x, y, -0.1), (x, y, alto), 0.07, 0.06, m["corteccia"], lati=6))
        # Capriata in testa: due puntoni dai pali al colmo.
        for y in (-largo / 2, largo / 2):
            parti.append(base.cilindro_tra("puntone", (x, y, alto), (x, 0, colmo), 0.05, 0.05, m["corteccia"], lati=5))
    for y in (-largo / 2, largo / 2):
        parti.append(base.cilindro_tra("corrente", (-lungo / 2, y, alto - 0.05), (lungo / 2, y, alto - 0.05), 0.05, 0.05, m["corteccia"], lati=5))
    parti.append(base.cilindro_tra("colmo", (-lungo / 2 - 0.35, 0, colmo), (lungo / 2 + 0.35, 0, colmo), 0.06, 0.06, m["corteccia"], lati=6))
    # Un tratto di parete di canne, sul lato verso terra.
    for k in range(6):
        t = (k + 0.5) / 14
        x = -lungo / 2 + t * lungo
        h = alto + rnd.uniform(-0.08, 0.06)
        parti.append(base.cilindro_tra("canne", (x, -largo / 2, 0.0), (x + rnd.uniform(-0.03, 0.03), -largo / 2, h), 0.075, 0.06, m["canne"], lati=5, uv_tile=0.8))
    materiali_a_terra(parti, m, rnd, 0.2, -largo / 2 - 1.5, seme, fasci="canne", pali=3)
    return base.unisci(nome, parti)


def cantiere_posta(nome, seme):
    """Posta di caccia in costruzione: le forcelle, il colmo e qualche corrente fino a terra,
    senza frasche; accanto un mucchio di rami e i pali. La schiena è verso y positivo."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    lungo, alto, fondo = 3.4, 1.45, 2.3
    y0 = -0.9
    for x in (-lungo / 2 + 0.2, lungo / 2 - 0.2):
        parti.append(base.cilindro_tra("forcella", (x, y0, -0.15), (x, y0, alto + 0.05), 0.08, 0.07, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("forca", (x, y0, alto - 0.15), (x + 0.15, y0 - 0.05, alto + 0.25), 0.04, 0.03, m["corteccia"], lati=5))
    parti.append(base.cilindro_tra("colmo", (-lungo / 2 - 0.2, y0, alto + 0.08), (lungo / 2 + 0.2, y0, alto + 0.08), 0.07, 0.06, m["corteccia"], lati=6))
    for k in (0, 2, 5):
        x = -lungo / 2 + 0.1 + k * (lungo - 0.2) / 5 + rnd.uniform(-0.06, 0.06)
        parti.append(base.cilindro_tra("corrente", (x, y0 - 0.25, alto + 0.22), (x + rnd.uniform(-0.1, 0.1), y0 + fondo + 0.15, -0.05), 0.04, 0.035, m["corteccia"], lati=5))
    # Mucchio di rami tagliati, da stendere sulla falda.
    for k in range(10):
        a = rnd.uniform(-0.5, 0.5)
        x, y = lungo / 2 + 1.0 + rnd.uniform(-0.4, 0.4), y0 + rnd.uniform(-0.5, 0.8)
        parti.append(base.cilindro_tra("ramo", (x - math.cos(a) * 0.8, y - math.sin(a) * 0.8, 0.05 + k * 0.02), (x + math.cos(a) * 0.8, y + math.sin(a) * 0.8, 0.08 + k * 0.02), 0.04, 0.015, m["corteccia"], lati=4))
    materiali_a_terra(parti, m, rnd, -0.3, y0 - 1.5, seme, pali=3, lungo=2.6)
    return base.unisci(nome, parti)


def cantiere_luogo_sacro(nome, seme):
    """Luogo sacro in costruzione: quattro dei nove pali già eretti nel cerchio, gli altri stesi a
    terra; la pietra ancora coricata su tre rulli, con una leva e una corda; le buche segnate."""
    m = materiali()
    m["corda"] = base.materiale("corda", "legno", tinta=(0.55, 0.48, 0.36))
    rnd = random.Random(seme)
    parti = []
    n = 9
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.08, 0.08)
        r = 4.2 + rnd.uniform(-0.2, 0.2)
        x, y = r * math.cos(a), r * math.sin(a)
        if k in (0, 1, 2, 5):
            h = rnd.uniform(2.3, 2.9)
            parti.append(base.cilindro_tra("palo", (x, y, -0.2), (x, y, h), 0.2, 0.15, m["corteccia"], lati=7))
        else:
            # Buca segnata da un anello di terra smossa.
            parti.append(sasso("buca", (0.6, 0.6, 0.08), (x, y, 0), m["argilla"], seme + 60 + k))
    # Pali ancora a terra, fuori dal cerchio.
    for k in range(3):
        y = -6.2 + k * 0.5
        parti.append(base.cilindro_tra("palo_a_terra", (-1.6, y, 0.2), (1.4, y + rnd.uniform(-0.2, 0.2), 0.18), 0.2, 0.15, m["corteccia"], lati=7, uv_tile=1.2))
    # La pietra coricata sui rulli, verso il centro del cerchio.
    for k in range(3):
        x = -0.9 + k * 0.9
        parti.append(base.cilindro_tra("rullo", (x, -0.7, 0.12), (x, 0.7, 0.12), 0.12, 0.12, m["corteccia"], lati=7))
    stele = sasso("stele", (2.6, 0.75, 0.5), (0, 0, 0.24), m["pietra"], seme + 1, appoggiato=False)
    parti.append(stele)
    parti.append(base.cilindro_tra("leva", (1.5, 0.3, 0.0), (2.6, 0.9, 1.4), 0.06, 0.05, m["legno"], lati=5))
    parti.append(base.cilindro_tra("corda", (-1.3, 0.0, 0.5), (-3.2, 0.4, 0.1), 0.03, 0.03, m["corda"], lati=4))
    return base.unisci(nome, parti)


# ---------- pascolo e animali (decisioni di Fede del 25/11/2026) ----------

def stabbio(nome, seme):
    """Stabbio: recinto basso di graticcio per la notte, con un'apertura e un abbeveratoio di tronco
    scavato accanto. Diverso dal recinto urbano dell'epoca 2: basso, ovale, fatto in fretta."""
    m = materiali()
    m["acqua"] = base.materiale("acqua_scura", "pietra", tinta=(0.16, 0.22, 0.24))
    rnd = random.Random(seme)
    parti = []
    ax, ay = 3.4, 2.4
    n = 20
    pali = []
    for k in range(n):
        if k in (0, 1):
            continue  # l'apertura
        a = 2 * math.pi * (k + 0.5) / n
        x, y = ax * math.cos(a), ay * math.sin(a)
        pali.append((x, y))
        parti.append(base.cilindro_tra("palo", (x, y, -0.1), (x, y, rnd.uniform(0.85, 1.0)), 0.06, 0.05, m["corteccia"], lati=5))
    for riga in range(4):
        z = 0.18 + riga * 0.18
        for k in range(len(pali) - 1):
            (x0, y0), (x1, y1) = pali[k], pali[k + 1]
            s0 = 1.0 + (0.02 if (k + riga) % 2 == 0 else -0.02)
            parti.append(base.cilindro_tra("vimine", (x0 * s0, y0 * s0, z), (x1 / s0, y1 / s0, z + rnd.uniform(-0.02, 0.02)), 0.03, 0.03, m["legno"], lati=4, uv_tile=0.8))
    # Abbeveratoio: un tronco scavato, con l'acqua scura dentro.
    tx, ty = ax + 0.9, -0.6
    parti.append(base.cilindro_tra("abbeveratoio", (tx, ty - 0.9, 0.22), (tx, ty + 0.9, 0.22), 0.26, 0.24, m["corteccia"], lati=8))
    parti.append(base.scatola("acqua", (0.28, 1.55, 0.04), (tx, ty, 0.44), m["acqua"]))
    # Paglia sparsa per la notte.
    for k in range(5):
        parti.append(sasso("paglia", (rnd.uniform(0.6, 1.0), rnd.uniform(0.5, 0.8), 0.12), (rnd.uniform(-2, 2), rnd.uniform(-1.3, 1.3), 0), m["paglia"], seme + 70 + k))
    return base.unisci(nome, parti)


# Gli animali del pascolo stanno in strumenti/blender/animali.py (terza versione, 26/11/2026).


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
    ("capanno_pesca", lambda n: capanno_pesca(n, 32)),
    ("posta_caccia", lambda n: posta_caccia(n, 33)),
    ("cantiere_granaio", lambda n: cantiere_granaio(n, 34)),
    ("cantiere_legnaia", lambda n: cantiere_legnaia(n, 35)),
    ("cantiere_capanno_pesca", lambda n: cantiere_capanno(n, 36)),
    ("cantiere_posta_caccia", lambda n: cantiere_posta(n, 37)),
    ("cantiere_luogo_sacro", lambda n: cantiere_luogo_sacro(n, 38)),
    ("stabbio", lambda n: stabbio(n, 39)),
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
