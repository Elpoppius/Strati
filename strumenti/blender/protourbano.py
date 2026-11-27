"""Modelli dell'abitato protourbano (epoca 2; richiesta di Fede del 27/11/2026: "aggiornare i modelli
degli edifici: nuova pelle e nuovi edifici"). Proposte di Claude, da guardare con Fede
(`docs/epoca2-proposte.md` § 3).

Riferimenti per la mappa pedecollinare (area emiliana): le terramare dell'età del Bronzo (case
rettangolari su un impalcato di pali, abitato quadrato con terrapieno, palizzata e fossato) e le
capanne villanoviane dell'età del Ferro (tetto a due falde di paglia con le travi del colmo che si
incrociano sopra le testate, le "corna" delle urne a capanna).

Pelle delle case: impalcato di pali alto 0,7 m con un ballatoio davanti alla porta e una scaletta;
pareti di graticcio intonacate d'argilla chiara (`intonaco`), pali agli angoli e lungo i lati; tetto a
due falde di paglia, ripido, con le corna incrociate alle due testate. Tre misure: piccola, media,
casa del capo (con il portico di pali e il cortile recintato). Edifici nuovi: tratto di recinto
(terrapieno di terra con la palizzata in cima), porta (due torri di legno con il camminamento sopra
il passaggio), officina del fabbro (tettoia aperta, forno a pozzetto d'argilla con il camino, mantici
di pelle, incudine di pietra, carbone e minerale).

Coordinate di Blender: x lungo la casa, porta verso +x, z in alto (in Godot la porta guarda +x).

Uso:  blender-py strumenti/blender/protourbano.py gioco/asset/protourbano [nomi,separati,da,virgole]
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prova_stile_verosimile as base  # noqa: E402  (legge la cartella d'uscita da sys.argv[1])
import villaggio  # noqa: E402  (sassi, graticcio, cataste, materiali del villaggio)
import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

USCITA = base.USCITA
ALTO_IMPALCATO = 0.7


def materiali():
    m = villaggio.materiali()
    m["intonaco"] = base.materiale("intonaco", "intonaco")
    m["terra"] = base.materiale("terra", "terra")
    m["pelle"] = base.materiale("pelle_mantice", "argilla", tinta=(0.62, 0.45, 0.32))
    m["carbone"] = base.materiale("carbone", "pietra", tinta=(0.16, 0.15, 0.14))
    m["minerale"] = base.materiale("minerale", "pietra", tinta=(0.62, 0.42, 0.3))
    m["fuoco"] = base.materiale("bocca_forno", "argilla", tinta=(0.35, 0.18, 0.1))
    return m


# ---------- pezzi ----------
def tetto_a_capanna(nome, lungo, largo, gronda, colmo, sporto_testate, sporto_lati, spessore, mat, seme):
    """Tetto di paglia a due falde, spesso e appena irregolare; le testate restano aperte (si vedono
    le travi e le corna)."""
    rnd = random.Random(seme)
    L = lungo / 2 + sporto_testate
    W = largo / 2 + sporto_lati
    # La gronda scende di quanto sporge il tetto oltre il muro.
    discesa = sporto_lati * (colmo - gronda) / (largo / 2)
    g = gronda - discesa
    bm = bmesh.new()
    v = [bm.verts.new(p) for p in [(-L, -W, g), (L, -W, g), (L, 0, colmo), (-L, 0, colmo), (L, W, g), (-L, W, g)]]
    bm.faces.new([v[0], v[1], v[2], v[3]])
    bm.faces.new([v[3], v[2], v[4], v[5]])
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=6, use_grid_fill=True)
    for vert in bm.verts:
        if abs(vert.co.y) < 0.05:
            vert.co.z += rnd.uniform(-0.04, 0.04)
        elif abs(abs(vert.co.y) - W) < 0.05:
            vert.co.x += rnd.uniform(-0.08, 0.08)
            vert.co.z += rnd.uniform(-0.1, 0.04)
        else:
            vert.co.z += rnd.uniform(-0.06, 0.06)
    bm.normal_update()
    ob = base.da_bmesh(nome, bm, mat)
    mod = ob.modifiers.new("spessore", "SOLIDIFY")
    mod.thickness = spessore
    mod.offset = -1
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    base.proiezione_box(ob)
    return ob


def corna(parti, m, x, colmo, largo_falda, alto=0.9):
    """Le travi del colmo che si incrociano sopra la testata, sporgendo come corna: partono poco sotto
    il colmo, sulle falde, e si incrociano appena sopra, con le punte un po' ricurve all'infuori."""
    giu = 1.1
    for s in (-1, 1):
        a = (x, s * 1.0, colmo - giu)
        mezzo = (x, -s * 0.18, colmo + alto * 0.6)
        punta = (x, -s * 0.5, colmo + alto)
        parti.append(base.cilindro_tra("corno", a, mezzo, 0.09, 0.07, m["legno"], lati=6))
        parti.append(base.cilindro_tra("punta_corno", mezzo, punta, 0.07, 0.04, m["legno"], lati=6))
    parti.append(base.cilindro_tra("colmo", (-x, 0, colmo + 0.08), (x, 0, colmo + 0.08), 0.08, 0.08, m["corteccia"], lati=6))


def impalcato(parti, m, rnd, x0, x1, y0, y1, alto=ALTO_IMPALCATO, passo=1.8):
    """Piano di tavole su pali: le tavole di traverso, i pali sotto, a file."""
    nx = max(2, int((x1 - x0) / passo) + 1)
    ny = max(2, int((y1 - y0) / passo) + 1)
    for i in range(nx):
        x = x0 + (x1 - x0) * i / (nx - 1)
        for j in range(ny):
            y = y0 + (y1 - y0) * j / (ny - 1)
            parti.append(base.cilindro_tra("palo_impalcato", (x + rnd.uniform(-0.05, 0.05), y, -0.2), (x, y, alto - 0.08), 0.11, 0.1, m["corteccia"], lati=6))
    for j in range(ny):
        y = y0 + (y1 - y0) * j / (ny - 1)
        parti.append(base.cilindro_tra("trave", (x0 - 0.15, y, alto - 0.1), (x1 + 0.15, y, alto - 0.1), 0.08, 0.08, m["corteccia"], lati=6))
    parti.append(base.scatola("tavolato", (x1 - x0 + 0.4, y1 - y0 + 0.4, 0.1), ((x0 + x1) / 2, (y0 + y1) / 2, alto), m["legno"], tagli=3))


def scaletta(parti, m, x, y, alto=ALTO_IMPALCATO, verso=1):
    """Scaletta di tronchi dal suolo al ballatoio, che scende verso +x (verso=1) o -x."""
    for s in (-0.35, 0.35):
        parti.append(base.cilindro_tra("montante", (x, y + s, alto), (x + verso * 1.3, y + s, -0.05), 0.06, 0.06, m["corteccia"], lati=5))
    for k in range(1, 4):
        t = k / 4
        parti.append(base.cilindro_tra("gradino", (x + verso * 1.3 * t, y - 0.4, alto * (1 - t) + 0.02), (x + verso * 1.3 * t, y + 0.4, alto * (1 - t) + 0.02), 0.045, 0.045, m["legno"], lati=5))


def pareti(parti, m, lungo, largo, z0, alto, passo=1.6):
    """Pareti di graticcio intonacato con i pali che le reggono (angoli e lungo i lati)."""
    parti.append(base.scatola("pareti", (lungo, largo, alto), (0, 0, z0 + alto / 2), m["intonaco"], tagli=4))
    n = max(2, int(lungo / passo))
    for k in range(n + 1):
        x = -lungo / 2 + k * lungo / n
        for y in (-largo / 2, largo / 2):
            parti.append(base.cilindro_tra("palo", (x, y, z0 - 0.05), (x, y, z0 + alto - 0.08), 0.11, 0.1, m["corteccia"], lati=6))
    for y in (-largo / 4, largo / 4):
        for x in (-lungo / 2, lungo / 2):
            parti.append(base.cilindro_tra("palo", (x, y, z0 - 0.05), (x, y, z0 + alto - 0.08), 0.11, 0.1, m["corteccia"], lati=6))


# ---------- case ----------
def casa(nome, lungo, largo, seme, capo=False):
    """Capanna rettangolare su impalcato (terramare, villanoviano). Con capo=True: più grande, con il
    portico di pali davanti alla porta sotto il tetto prolungato, e il cortile recintato."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    z0 = ALTO_IMPALCATO + 0.05
    alto = 1.75 if not capo else 2.0
    ballatoio = 1.6 if not capo else 3.2
    impalcato(parti, m, rnd, -lungo / 2 - 0.3, lungo / 2 + ballatoio, -largo / 2 - 0.3, largo / 2 + 0.3)
    pareti(parti, m, lungo, largo, z0, alto)
    parti.append(base.scatola("porta", (0.14, 1.1 if not capo else 1.5, 1.55), (lungo / 2 + 0.03, 0, z0 + 0.78), m["vano"]))
    gronda = z0 + alto - 0.05
    colmo = gronda + largo * 0.62
    sporto_fronte = ballatoio + 0.2 if capo else 0.7
    # Il tetto copre anche il ballatoio della casa del capo (portico): si sposta in avanti.
    tetto = tetto_a_capanna("tetto", lungo + (sporto_fronte - 0.7 if capo else 0), largo, gronda, colmo, 0.7, 0.65, 0.4, m["paglia"], seme)
    if capo:
        tetto.location.x += (sporto_fronte - 0.7) / 2
        bpy.context.view_layer.objects.active = tetto
        bpy.ops.object.select_all(action="DESELECT")
        tetto.select_set(True)
        bpy.ops.object.transform_apply(location=True)
        # Portico: pali che reggono la gronda davanti.
        xp = lungo / 2 + ballatoio - 0.2
        for y in (-largo / 2, -largo / 6, largo / 6, largo / 2):
            parti.append(base.cilindro_tra("palo_portico", (xp, y, z0 - 0.05), (xp, y, gronda + 0.2), 0.12, 0.11, m["legno"], lati=7))
        parti.append(base.cilindro_tra("architrave", (xp, -largo / 2 - 0.3, gronda + 0.2), (xp, largo / 2 + 0.3, gronda + 0.2), 0.1, 0.1, m["legno"], lati=6))
    parti.append(tetto)
    x_testa = lungo / 2 + 0.7 + (sporto_fronte - 0.7 if capo else 0)
    corna(parti, m, x_testa, colmo, largo + 1.3, 1.0 if capo else 0.8)
    corna(parti, m, -(lungo / 2 + 0.7), colmo, largo + 1.3, 1.0 if capo else 0.8)
    scaletta(parti, m, lungo / 2 + ballatoio + 0.2, 0.0)
    if capo:
        # Cortile del capo: palizzata bassa di graticcio attorno a un'area davanti e di lato.
        y0, y1 = -largo / 2 - 4.0, largo / 2 + 4.0
        x0, x1 = -lungo / 2 - 1.5, lungo / 2 + ballatoio + 5.0
        angoli = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
        for k in range(4):
            a, b = angoli[k], angoli[(k + 1) % 4]
            lato = math.hypot(b[0] - a[0], b[1] - a[1])
            n = max(1, int(lato / 1.4))
            punti = [(a[0] + (b[0] - a[0]) * j / n, a[1] + (b[1] - a[1]) * j / n) for j in range(n + 1)]
            for j, pt in enumerate(punti):
                if k == 1 and abs(pt[1]) < 1.2:
                    continue  # il varco davanti
                parti.append(base.cilindro_tra("palo_cortile", (pt[0], pt[1], -0.1), (pt[0], pt[1], 1.25), 0.06, 0.05, m["corteccia"], lati=5))
            for j in range(n):
                p, q = punti[j], punti[j + 1]
                if k == 1 and (abs(p[1]) < 1.2 or abs(q[1]) < 1.2):
                    continue
                villaggio._graticcio_dritto(parti, m, rnd, p, q, 0.15, 5)
        villaggio._catasta(parti, m, rnd, -1.0, y0 + 1.2, lungo=3.0)
        parti.append(villaggio.sasso("macina", (0.7, 0.5, 0.3), (x1 - 2.0, y1 - 1.5, 0), m["pietra"], seme + 7))
    return base.unisci(nome, parti)


# ---------- recinto ----------
LUNGO_TRATTO = 10.0


def tratto_recinto(nome, seme):
    """Un tratto di recinto lungo 10 m (asse x): terrapieno di terra largo 6 m alla base e 2,4 in cima,
    alto 1,6 m, con la palizzata di pali appuntiti sul ciglio esterno (verso -y) e un camminamento di
    tavole dietro. Il fossato è nel terreno, davanti (verso -y), e lo disegna il gioco."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    L = LUNGO_TRATTO / 2 + 0.05
    alto, base_lato, cima = 1.6, 3.0, 1.2
    bm = bmesh.new()
    sezione = [(-base_lato, 0.0), (-cima, alto), (cima, alto), (base_lato, 0.0)]
    davanti = [bm.verts.new((-L, y, z)) for y, z in sezione]
    dietro = [bm.verts.new((L, y, z)) for y, z in sezione]
    for k in range(3):
        bm.faces.new([davanti[k], dietro[k], dietro[k + 1], davanti[k + 1]])
    bm.faces.new(davanti[::-1])
    bm.faces.new(dietro)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=5, use_grid_fill=True)
    for v in bm.verts:
        if 0.05 < v.co.z < alto - 0.05:
            v.co.y += rnd.uniform(-0.12, 0.12)
            v.co.z += rnd.uniform(-0.08, 0.08)
        elif v.co.z >= alto - 0.05:
            v.co.z += rnd.uniform(-0.05, 0.03)
    bm.normal_update()
    parti.append(base.da_bmesh("terrapieno", bm, m["terra"], tile=2.0))
    # Palizzata sul ciglio esterno: pali fitti e appuntiti, legati da due correnti.
    y_pal = -cima + 0.25
    x = -L + 0.12
    while x < L:
        r = rnd.uniform(0.1, 0.14)
        h = alto + rnd.uniform(2.0, 2.4)
        parti.append(base.cilindro_tra("palo", (x, y_pal, alto - 0.5), (x, y_pal, h), r, r * 0.95, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("punta", (x, y_pal, h), (x, y_pal, h + 0.35), r * 0.95, 0.02, m["legno"], lati=6))
        x += r * 2.05
    for z in (alto + 0.6, alto + 1.6):
        parti.append(base.cilindro_tra("corrente", (-L, y_pal + 0.16, z), (L, y_pal + 0.16, z), 0.06, 0.06, m["legno"], lati=5))
    # Camminamento di tavole dietro la palizzata.
    parti.append(base.scatola("camminamento", (LUNGO_TRATTO, 1.0, 0.08), (0, y_pal + 0.75, alto + 0.05), m["legno"], tagli=2))
    return base.unisci(nome, parti)


def porta(nome, seme):
    """La porta del recinto: il terrapieno si interrompe per 4 m, due torri di pali (3 × 3 m, alte 5,5)
    lo fiancheggiano, un camminamento coperto passa sopra il varco; due battenti di tavole aperti.
    Larga quanto un tratto (10 m), si mette al posto di un tratto."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    varco = 4.0
    alto = 1.6
    # Terrapieno ai due lati del varco.
    for s in (-1, 1):
        x0, x1 = s * varco / 2, s * (LUNGO_TRATTO / 2 + 0.05)
        bm = bmesh.new()
        sezione = [(-3.0, 0.0), (-1.2, alto), (1.2, alto), (3.0, 0.0)]
        a = [bm.verts.new((x0, y, z)) for y, z in sezione]
        b = [bm.verts.new((x1, y, z)) for y, z in sezione]
        for k in range(3):
            f = [a[k], b[k], b[k + 1], a[k + 1]]
            bm.faces.new(f if s > 0 else f[::-1])
        bm.faces.new(a[::-1] if s > 0 else a)
        bm.faces.new(b if s > 0 else b[::-1])
        bm.normal_update()
        parti.append(base.da_bmesh("terrapieno", bm, m["terra"], tile=2.0))
    # Torri.
    for s in (-1, 1):
        cx = s * (varco / 2 + 1.5)
        for dx in (-1.4, 1.4):
            for dy in (-1.4, 1.4):
                parti.append(base.cilindro_tra("palo_torre", (cx + dx, dy, -0.2), (cx + dx * 0.95, dy * 0.95, 5.5), 0.16, 0.13, m["corteccia"], lati=6))
        parti.append(base.scatola("piano_torre", (3.2, 3.2, 0.12), (cx, 0, 4.4), m["legno"]))
        for k, (a, b) in enumerate([((-1.4, -1.4), (1.4, -1.4)), ((1.4, -1.4), (1.4, 1.4)), ((1.4, 1.4), (-1.4, 1.4)), ((-1.4, 1.4), (-1.4, -1.4))]):
            villaggio._graticcio_dritto(parti, m, rnd, (cx + a[0], a[1]), (cx + b[0], b[1]), 4.5, 6)
        parti.append(base.tetto_a_padiglione("tetto_torre", 3.0, 3.0, 5.6, 50, 0.45, 0.3, m["paglia"], seme + s))
        parti[-1].location.x += cx
        bpy.context.view_layer.objects.active = parti[-1]
        bpy.ops.object.select_all(action="DESELECT")
        parti[-1].select_set(True)
        bpy.ops.object.transform_apply(location=True)
    # Camminamento sopra il varco, con il suo parapetto e un tetto a due falde.
    parti.append(base.scatola("ponte_porta", (varco + 3.0, 2.4, 0.14), (0, 0, 3.6), m["legno"]))
    for y in (-1.1, 1.1):
        parti.append(base.cilindro_tra("trave_porta", (-varco / 2 - 1.5, y, 3.5), (varco / 2 + 1.5, y, 3.5), 0.14, 0.14, m["corteccia"], lati=6))
        villaggio._graticcio_dritto(parti, m, rnd, (-varco / 2, y), (varco / 2, y), 3.75, 5)
    tetto = tetto_a_capanna("tetto_porta", varco, 2.4, 4.9, 5.7, 0.2, 0.5, 0.3, m["paglia"], seme + 3)
    parti.append(tetto)
    # Battenti aperti verso l'interno (+y).
    for s in (-1, 1):
        cx = s * (varco / 2 - 0.05)
        parti.append(base.scatola("battente", (0.12, 1.9, 3.0), (cx, 1.0, 1.5), m["legno"], tagli=2))
    return base.unisci(nome, parti)


# ---------- fabbro ----------
def officina_fabbro(nome, seme):
    """Officina del fabbro: tettoia a una falda di 5 × 3,2 m, aperta davanti (y negativo), con l'incudine
    di pietra sul ceppo e la rastrelliera degli attrezzi; di fianco, fuori dalla paglia per il fuoco,
    il forno a pozzetto d'argilla con il camino alto, la bocca accesa e i due mantici di pelle; attorno
    la terra bruciata, il mucchio di carbone, il minerale e la vasca per temprare. Dall'alto si devono
    leggere il forno e l'incudine, quindi la tettoia è bassa dietro e lascia vedere il davanti."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    lungo, largo = 5.0, 3.2
    alto_davanti, alto_dietro = 2.7, 1.9
    for y, h in ((-largo / 2, alto_davanti), (largo / 2, alto_dietro)):
        for k in range(3):
            x = (k - 1) * lungo / 2 + rnd.uniform(-0.06, 0.06)
            parti.append(base.cilindro_tra("palo", (x, y, -0.15), (x + rnd.uniform(-0.04, 0.04), y, h), 0.12, 0.1, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("trave", (-lungo / 2 - 0.3, y, h - 0.06), (lungo / 2 + 0.3, y, h - 0.06), 0.09, 0.09, m["corteccia"], lati=6))
    for k in range(5):
        x = (k - 2) * lungo / 4
        parti.append(base.cilindro_tra("corrente", (x, -largo / 2 - 0.4, alto_davanti + 0.05), (x, largo / 2 + 0.4, alto_dietro + 0.05), 0.05, 0.05, m["legno"], lati=5))
    falda = base.scatola("falda", (lungo + 0.7, largo + 1.0, 0.2), (0, 0, 0), m["paglia"], tagli=3)
    for v in falda.data.vertices:
        v.co.z += rnd.uniform(-0.04, 0.04)
    falda.rotation_euler = (-math.atan2(alto_davanti - alto_dietro, largo + 0.8), 0, 0)
    falda.location = (0, 0, (alto_davanti + alto_dietro) / 2 + 0.18)
    parti.append(falda)
    # Parete di graticcio sul retro, mezza alta: ripara dal vento.
    for k in range(9):
        x = -lungo / 2 + (k + 0.5) * lungo / 9
        parti.append(base.cilindro_tra("graticcio", (x, largo / 2 + 0.05, 0), (x, largo / 2 + 0.05, 1.2), 0.07, 0.06, m["intonaco"], lati=5, uv_tile=0.8))
    # Terra bruciata attorno al forno.
    fx, fy = -lungo / 2 - 1.3, -0.4
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=16, radius=1.7)
    for v in bm.verts:
        v.co.x *= rnd.uniform(0.8, 1.1)
        v.co.y *= rnd.uniform(0.8, 1.1)
    bmesh.ops.translate(bm, vec=Vector((fx + 0.4, fy, 0.025)), verts=bm.verts)
    bm.normal_update()
    parti.append(base.da_bmesh("bruciato", bm, m["carbone"], tile=1.0))
    # Forno a pozzetto: tronco di cono d'argilla con il camino e la bocca accesa verso la tettoia.
    parti.append(base.cilindro_tra("forno", (fx, fy, 0), (fx, fy, 1.0), 0.65, 0.42, m["argilla"], lati=12, uv_tile=1.0))
    parti.append(base.cilindro_tra("camino", (fx, fy, 0.95), (fx + 0.04, fy, 2.0), 0.24, 0.15, m["argilla"], lati=10))
    parti.append(base.cilindro_tra("fumo", (fx + 0.04, fy, 1.98), (fx + 0.04, fy, 2.02), 0.13, 0.13, m["carbone"], lati=8))
    parti.append(base.scatola("bocca", (0.14, 0.4, 0.34), (fx + 0.6, fy, 0.28), m["fuoco"]))
    # Mantici: due sacchi di pelle con il becco d'argilla verso la bocca del forno.
    for dy in (-0.5, 0.5):
        mx, my = fx + 1.5, fy + dy
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.5)
        for v in bm.verts:
            v.co = Vector((v.co.x * 0.55, v.co.y * 0.38, v.co.z * 0.3))
        bmesh.ops.translate(bm, vec=Vector((mx, my, 0.3)), verts=bm.verts)
        bm.normal_update()
        parti.append(base.da_bmesh("mantice", bm, m["pelle"], tile=1.0))
        parti.append(base.cilindro_tra("becco", (mx - 0.25, my, 0.28), (fx + 0.6, fy + dy * 0.2, 0.25), 0.05, 0.035, m["argilla"], lati=6))
    # Incudine di pietra sul ceppo, sotto il bordo alto della tettoia, con il martello.
    ix, iy = -1.0, -largo / 2 + 0.7
    parti.append(base.cilindro_tra("ceppo", (ix, iy, 0), (ix, iy, 0.55), 0.32, 0.3, m["corteccia"], lati=9))
    parti.append(villaggio.sasso("incudine", (0.5, 0.34, 0.22), (ix, iy, 0.5), m["pietra"], seme + 5))
    parti.append(base.cilindro_tra("manico", (ix + 0.2, iy - 0.1, 0.72), (ix + 0.6, iy - 0.35, 0.75), 0.025, 0.025, m["legno"], lati=4))
    parti.append(villaggio.sasso("mazza", (0.14, 0.09, 0.09), (ix + 0.17, iy - 0.08, 0.7), m["pietra"], seme + 6, appoggiato=False))
    # Rastrelliera con gli attrezzi finiti, contro il graticcio.
    parti.append(base.cilindro_tra("rastrelliera", (0.6, largo / 2 - 0.3, 1.1), (2.2, largo / 2 - 0.3, 1.1), 0.04, 0.04, m["legno"], lati=5))
    for k in range(5):
        x = 0.75 + k * 0.33
        parti.append(base.cilindro_tra("manico", (x, largo / 2 - 0.45, 0), (x, largo / 2 - 0.3, 1.25), 0.025, 0.025, m["legno"], lati=4))
        parti.append(base.scatola("lama", (0.05, 0.03, 0.2), (x, largo / 2 - 0.3, 1.33), m["pietra"]))
    # Fuori: carbone, minerale, vasca d'acqua.
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.9, radius2=0.1, depth=0.7)
    bmesh.ops.translate(bm, vec=Vector((fx - 0.3, fy + 2.0, 0.35)), verts=bm.verts)
    for v in bm.verts:
        v.co.x += rnd.uniform(-0.05, 0.05)
        v.co.y += rnd.uniform(-0.05, 0.05)
    bm.normal_update()
    parti.append(base.da_bmesh("carbone", bm, m["carbone"], tile=1.0))
    for k in range(5):
        parti.append(villaggio.sasso("minerale", (0.3, 0.25, 0.2), (fx - 0.9 + rnd.uniform(-0.3, 0.3), fy - 1.6 + rnd.uniform(-0.3, 0.3), 0), m["minerale"], seme + 20 + k))
    parti.append(base.scatola("vasca", (1.2, 0.6, 0.35), (0.6, -largo / 2 - 0.9, 0.17), m["legno"]))
    parti.append(base.scatola("acqua", (1.05, 0.46, 0.04), (0.6, -largo / 2 - 0.9, 0.33), m["carbone"]))
    return base.unisci(nome, parti)


def cantiere_officina_fabbro(nome, seme):
    """Officina del fabbro in costruzione: i sei pali con le travi e metà dei correnti, niente paglia;
    il forno d'argilla a metà altezza, ancora senza camino; accanto i pali stesi, i fasci di paglia e
    l'argilla."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    lungo, largo = 5.0, 3.2
    alto_davanti, alto_dietro = 2.7, 1.9
    for y, h in ((-largo / 2, alto_davanti), (largo / 2, alto_dietro)):
        for k in range(3):
            x = (k - 1) * lungo / 2 + rnd.uniform(-0.06, 0.06)
            parti.append(base.cilindro_tra("palo", (x, y, -0.15), (x + rnd.uniform(-0.04, 0.04), y, h), 0.12, 0.1, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("trave", (-lungo / 2 - 0.3, y, h - 0.06), (lungo / 2 + 0.3, y, h - 0.06), 0.09, 0.09, m["corteccia"], lati=6))
    for k in range(3):
        x = (k - 2) * lungo / 4
        parti.append(base.cilindro_tra("corrente", (x, -largo / 2 - 0.4, alto_davanti + 0.05), (x, largo / 2 + 0.4, alto_dietro + 0.05), 0.05, 0.05, m["legno"], lati=5))
    fx, fy = -lungo / 2 - 1.3, -0.4
    parti.append(base.cilindro_tra("forno", (fx, fy, 0), (fx, fy, 0.5), 0.65, 0.54, m["argilla"], lati=12, uv_tile=1.0))
    villaggio.materiali_a_terra(parti, m, rnd, 0.6, -largo / 2 - 1.5, seme)
    parti.append(villaggio.sasso("argilla", (1.0, 0.8, 0.4), (fx - 0.2, fy + 1.8, 0), m["argilla"], seme + 50))
    return base.unisci(nome, parti)


ASSET = [
    ("casa_impalcato_piccola", lambda n: casa(n, 7.5, 4.6, 61)),
    ("casa_impalcato_media", lambda n: casa(n, 10.5, 5.6, 62)),
    ("casa_del_capo", lambda n: casa(n, 15.0, 7.5, 63, capo=True)),
    ("recinto_tratto", lambda n: tratto_recinto(n, 64)),
    ("recinto_porta", lambda n: porta(n, 65)),
    ("officina_fabbro", lambda n: officina_fabbro(n, 66)),
    ("cantiere_officina_fabbro", lambda n: cantiere_officina_fabbro(n, 67)),
]


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(USCITA, exist_ok=True)
    bpy.context.scene.world = bpy.data.worlds.new("Mondo")
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    solo = sys.argv[2].split(",") if len(sys.argv) > 2 and sys.argv[2] else None
    for nome, fabbrica in ASSET:
        if solo and nome not in solo:
            continue
        ob = fabbrica(nome)
        base.cuoci_occlusione(ob, 0.45)
        base.esporta(ob, os.path.join(USCITA, nome + ".glb"))
        d = ob.dimensions
        print(f"{nome}: {d.x:.1f} x {d.y:.1f} x {d.z:.1f} m, {len(ob.data.polygons)} facce")
        bpy.data.objects.remove(ob, do_unlink=True)


if __name__ == "__main__":
    main()
