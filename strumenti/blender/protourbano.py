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
def casa(nome, lungo, largo, seme, capo=False, annessi=None):
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
    if annessi is not None:
        annessi(parti, m, rnd, lungo, largo, ballatoio)
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
def _materiale_speciale(nome, immagine, tinta, metallo=0.0, ruvidezza=0.9, luce=None, forza=0.0):
    """Materiale con la tinta e, se serve, metallo (il bronzo) o luce propria (le braci)."""
    nuovo = nome not in bpy.data.materials
    mat = base.materiale(nome, immagine, ruvidezza=ruvidezza, tinta=tinta)
    if nuovo:
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Metallic"].default_value = metallo
        if luce is not None:
            bsdf.inputs["Emission Color"].default_value = (*luce, 1.0)
            bsdf.inputs["Emission Strength"].default_value = forza
    return mat


def materiali_fabbro():
    m = materiali()
    m["bronzo"] = _materiale_speciale("bronzo", "pietra", (1.45, 0.95, 0.42), metallo=0.25, ruvidezza=0.4)
    m["brace"] = _materiale_speciale("brace", "argilla", (0.55, 0.16, 0.04), luce=(1.0, 0.3, 0.04), forza=0.8)
    m["bruciata"] = base.materiale("argilla_bruciata", "argilla", tinta=(0.38, 0.3, 0.26))
    m["fuliggine"] = base.materiale("fuliggine", "argilla", tinta=(0.13, 0.12, 0.11))
    m["pietra_chiara"] = base.materiale("pietra_chiara", "pietra", tinta=(1.25, 1.22, 1.15))
    m["acqua_vasca"] = base.materiale("acqua_vasca", "pietra", ruvidezza=0.15, tinta=(0.16, 0.2, 0.2))
    m["vimini"] = base.materiale("vimini", "paglia", tinta=(0.72, 0.58, 0.4))
    return m


def _disco(nome, centro, raggio, mat, rnd, lati=16, irregolare=0.15, z=0.02):
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=lati, radius=raggio)
    for v in bm.verts:
        k = 1.0 + rnd.uniform(-irregolare, irregolare)
        v.co.x *= k
        v.co.y *= k
    bmesh.ops.translate(bm, vec=Vector((centro[0], centro[1], z)), verts=bm.verts)
    bm.normal_update()
    return base.da_bmesh(nome, bm, mat, tile=1.0)


def _cupola(nome, centro, raggio, z0, mat, schiaccia=0.85):
    """Mezza sfera d'argilla appoggiata a quota z0 (la volta della fornace)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=8, radius=raggio)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.01], context="VERTS")
    for v in bm.verts:
        v.co.z *= schiaccia
    bmesh.ops.translate(bm, vec=Vector((centro[0], centro[1], z0)), verts=bm.verts)
    bm.normal_update()
    return base.da_bmesh(nome, bm, mat, tile=1.0)


def _incudine(parti, m, rnd, x, y, seme):
    """Incudine di pietra chiara, piatta sopra, su un ceppo grosso; il martello col bronzo, le
    scaglie attorno. Sta fuori dalla tettoia perché dall'alto si veda."""
    parti.append(base.cilindro_tra("ceppo", (x, y, 0), (x, y, 0.58), 0.46, 0.42, m["corteccia"], lati=11))
    parti.append(_disco("taglio", (x, y), 0.41, m["legno"], rnd, lati=11, irregolare=0.02, z=0.585))
    s = villaggio.sasso("incudine", (0.9, 0.56, 0.38), (x, y, 0.5), m["pietra_chiara"], seme + 5)
    alto = max(v.co.z for v in s.data.vertices) - 0.09
    for v in s.data.vertices:
        v.co.z = min(v.co.z, alto)
    parti.append(s)
    parti.append(base.cilindro_tra("manico", (x + 0.25, y - 0.32, alto + 0.03), (x + 0.75, y - 0.55, 0.62), 0.028, 0.026, m["legno"], lati=5))
    parti.append(base.cilindro_tra("martello", (x + 0.2, y - 0.38, alto + 0.03), (x + 0.32, y - 0.24, alto + 0.03), 0.06, 0.05, m["bronzo"], lati=6))
    parti.append(base.cilindro_tra("pinza", (x - 0.15, y + 0.1, alto + 0.02), (x - 0.75, y + 0.3, alto - 0.05), 0.018, 0.018, m["bronzo"], lati=4))
    parti.append(base.cilindro_tra("pinza", (x - 0.15, y + 0.14, alto + 0.02), (x - 0.74, y + 0.42, alto - 0.05), 0.018, 0.018, m["bronzo"], lati=4))
    for k in range(10):
        a = rnd.uniform(0, 2 * math.pi)
        d = rnd.uniform(0.55, 1.1)
        parti.append(base.scatola("scaglia", (0.08, 0.06, 0.02), (x + d * math.cos(a), y + d * math.sin(a), 0.03), m["fuliggine"]))


def _fornace(parti, m, rnd, fx, fy, seme, cantiere=False):
    """Fornace a cupola d'argilla su un piede di pietre: in basso argilla chiara, in alto annerita;
    camino con le colature di fuliggine; la bocca accesa verso chi guarda (-y) con le braci davanti;
    i due mantici di fianco, con i becchi nella parete. Restituisce la cima del camino."""
    # Piede di pietre.
    for k in range(13):
        a = 2 * math.pi * k / 13 + rnd.uniform(-0.08, 0.08)
        if not cantiere and abs(a - 1.5 * math.pi) < 0.35:
            continue  # davanti alla bocca le pietre si aprono
        parti.append(villaggio.sasso("piede", (0.38, 0.3, 0.3), (fx + 0.95 * math.cos(a), fy + 0.95 * math.sin(a), 0), m["pietra"], seme + 60 + k))
    alto_corpo = 0.55 if cantiere else 0.95
    parti.append(base.cilindro_tra("corpo", (fx, fy, 0), (fx, fy, alto_corpo), 0.86, 0.8, m["argilla"], lati=14, uv_tile=1.0))
    if cantiere:
        return None
    parti.append(_cupola("volta", (fx, fy), 0.8, alto_corpo - 0.02, m["bruciata"]))
    cima = 2.55
    parti.append(base.cilindro_tra("camino", (fx, fy, alto_corpo + 0.5), (fx + 0.05, fy + 0.03, cima), 0.27, 0.17, m["bruciata"], lati=10))
    parti.append(base.cilindro_tra("bocca_camino", (fx + 0.05, fy + 0.03, cima - 0.25), (fx + 0.05, fy + 0.03, cima + 0.02), 0.19, 0.2, m["fuliggine"], lati=10))
    for k in range(4):
        a = rnd.uniform(0, 2 * math.pi)
        z1 = rnd.uniform(1.5, 2.0)
        parti.append(base.cilindro_tra("colatura", (fx + 0.2 * math.cos(a), fy + 0.2 * math.sin(a), cima - 0.1),
                                       (fx + 0.25 * math.cos(a), fy + 0.25 * math.sin(a), z1), 0.07, 0.05, m["fuliggine"], lati=5))
    # Bocca accesa: arco annerito attorno, fuoco dentro, braci davanti.
    # La cornice annerita sporge dalla parete; il fuoco sta dentro, rientrato, così si legge come una
    # bocca e non come un riquadro.
    for dx in (-0.36, 0.36):
        parti.append(base.scatola("stipite", (0.16, 0.26, 0.62), (fx + dx, fy - 0.84, 0.31), m["fuliggine"]))
    parti.append(base.scatola("architrave", (0.88, 0.26, 0.16), (fx, fy - 0.84, 0.66), m["fuliggine"]))
    parti.append(base.scatola("soglia", (0.6, 0.3, 0.06), (fx, fy - 0.9, 0.03), m["fuliggine"]))
    parti.append(base.scatola("bocca", (0.56, 0.1, 0.52), (fx, fy - 0.74, 0.32), m["brace"]))
    for k in range(9):
        parti.append(villaggio.sasso("brace", (0.14, 0.12, 0.07), (fx + rnd.uniform(-0.35, 0.35), fy - 1.05 - rnd.uniform(0, 0.35), 0), m["brace"], seme + 80 + k))
    # Mantici: due sacchi di pelle a sinistra, i becchi d'argilla nella parete.
    for dy in (-0.32, 0.38):
        mx, my = fx - 1.55, fy + dy
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.5)
        for v in bm.verts:
            v.co = Vector((v.co.x * 0.6, v.co.y * 0.4, v.co.z * 0.32))
        bmesh.ops.translate(bm, vec=Vector((mx, my, 0.3)), verts=bm.verts)
        bm.normal_update()
        parti.append(base.da_bmesh("mantice", bm, m["pelle"], tile=1.0))
        parti.append(base.cilindro_tra("bastone", (mx - 0.1, my, 0.45), (mx - 0.15, my, 1.0), 0.025, 0.025, m["legno"], lati=4))
        parti.append(base.cilindro_tra("becco", (mx + 0.3, my, 0.3), (fx - 0.82, fy + dy * 0.3, 0.32), 0.06, 0.045, m["bruciata"], lati=6))
    return Vector((fx + 0.05, fy + 0.03, cima))


# Dove nasce il fumo dei camini, in coordinate del modello di Blender (x, y, z); in Godot (x, z, −y).
CAMINI = {}


def officina_fabbro(nome, seme, cantiere=False):
    """Officina del fabbro (rifatta il 27/11/2026, richiesta di Fede: "più personalizzazione, legno e
    roccia; la fornace non si distingue, l'incudine non si vede"). Nell'età del Bronzo il fabbro è
    soprattutto un fonditore: stampi di pietra, crogioli, panelle di metallo.
    - Tettoia a una falda di 5 × 3,2 m, aperta davanti (y negativo, il lato della via), pali grossi su
      uno zoccolo di sassi, trave davanti che sporge; dietro metà muretto a secco e metà graticcio.
    - A sinistra, fuori dalla paglia, la fornace a cupola sul piede di pietre, bocca accesa verso la
      via, mantici di fianco, camino annerito (il fumo animato nasce lì: `CAMINI`).
    - Davanti, nello spiazzo di terra battuta, l'incudine di pietra chiara sul ceppo, fuori dal tetto.
    - Sotto la tettoia il banco di tavole con stampi, crogioli e panelle; contro il fondo la
      rastrelliera con asce, punte di lancia e una spada di bronzo; sgabello, cassa, cesti di carbone.
    - Attorno legna, minerale, vasca per temprare in un tronco scavato."""
    m = materiali_fabbro()
    rnd = random.Random(seme)
    parti = []
    lungo, largo = 5.0, 3.2
    alto_davanti, alto_dietro = 2.75, 1.95
    fx, fy = -lungo / 2 - 1.5, -0.7
    # Spiazzo di terra battuta davanti e terra bruciata attorno alla fornace.
    parti.append(_disco("spiazzo", (-0.6, -largo / 2 - 1.0), 2.6, m["terra"], rnd, lati=18, z=0.07))
    parti.append(_disco("bruciato", (fx + 0.2, fy - 0.4), 1.8, m["carbone"], rnd, lati=16, z=0.08))
    # Pali su zoccoli di sassi, travi; davanti più grossi, con la trave che sporge.
    for y, h, r in ((-largo / 2, alto_davanti, 0.16), (largo / 2, alto_dietro, 0.12)):
        for k in range(3):
            x = (k - 1) * lungo / 2 + rnd.uniform(-0.06, 0.06)
            parti.append(villaggio.sasso("zoccolo", (0.48, 0.44, 0.3), (x, y, 0), m["pietra"], seme + 10 + k + int(y * 10)))
            parti.append(base.cilindro_tra("palo", (x, y, 0.1), (x + rnd.uniform(-0.04, 0.04), y, h), r, r * 0.85, m["corteccia"], lati=7))
        sporge = 0.75 if y < 0 else 0.3
        if cantiere and y > 0:
            continue
        parti.append(base.cilindro_tra("trave", (-lungo / 2 - sporge, y, h - 0.06), (lungo / 2 + sporge, y, h - 0.06), r * 0.75, r * 0.75, m["corteccia"], lati=7))
    correnti = 3 if cantiere else 5
    for k in range(correnti):
        x = (k - 2) * lungo / 4
        parti.append(base.cilindro_tra("corrente", (x, -largo / 2 - 0.4, alto_davanti + 0.06), (x, largo / 2 + 0.4, alto_dietro + 0.06), 0.055, 0.05, m["legno"], lati=5))
    if not cantiere:
        falda = base.scatola("falda", (lungo + 0.6, largo + 0.9, 0.2), (0, 0, 0), m["paglia"], tagli=3)
        for v in falda.data.vertices:
            v.co.z += rnd.uniform(-0.04, 0.04)
        falda.rotation_euler = (-math.atan2(alto_davanti - alto_dietro, largo + 0.8), 0, 0)
        falda.location = (0, 0.1, (alto_davanti + alto_dietro) / 2 + 0.2)
        parti.append(falda)
    # Dietro: metà muretto a secco (verso la fornace), metà graticcio.
    for fila in range(3):
        n = 7 - fila
        for k in range(n):
            x = -lungo / 2 + 0.2 + (k + 0.5 * (fila % 2)) * (lungo / 2) / 7
            parti.append(villaggio.sasso("muretto", (0.42, 0.34, 0.24), (x, largo / 2 + 0.1, fila * 0.2), m["pietra"], seme + 100 + fila * 10 + k))
    if not cantiere:
        villaggio._graticcio_dritto(parti, m, rnd, (0.1, largo / 2 + 0.08), (lungo / 2, largo / 2 + 0.08), 0.1, 6)
    cima = _fornace(parti, m, rnd, fx, fy, seme, cantiere)
    if cantiere:
        villaggio.materiali_a_terra(parti, m, rnd, 0.6, -largo / 2 - 1.7, seme)
        parti.append(villaggio.sasso("argilla", (1.0, 0.8, 0.4), (fx - 0.3, fy + 2.0, 0), m["argilla"], seme + 50))
        for k in range(5):
            parti.append(villaggio.sasso("sasso", (0.36, 0.3, 0.26), (fx + 0.5 + rnd.uniform(-0.4, 0.4), fy + 1.9 + rnd.uniform(-0.3, 0.3), 0), m["pietra"], seme + 150 + k))
        return base.unisci(nome, parti)
    # Il fumo nasce poco sotto l'orlo del camino: così la colonna parte attaccata alla bocca.
    CAMINI[nome] = (cima.x, cima.y, cima.z - 0.2)
    _incudine(parti, m, rnd, -0.9, -largo / 2 - 1.25, seme)
    # Banco di tavole sotto la tettoia, con stampi, crogioli, panelle.
    bx, by = 1.2, -0.55
    for dx in (-0.8, 0.8):
        for dy in (-0.28, 0.28):
            parti.append(base.cilindro_tra("gamba", (bx + dx, by + dy, 0), (bx + dx, by + dy, 0.78), 0.045, 0.04, m["legno"], lati=5))
    parti.append(base.scatola("piano", (1.9, 0.78, 0.08), (bx, by, 0.82), m["legno"]))
    for k, dx in enumerate((-0.6, -0.15)):
        parti.append(base.scatola("stampo", (0.34, 0.22, 0.08), (bx + dx, by + 0.1, 0.9), m["pietra_chiara"]))
        parti.append(base.scatola("incavo", (0.24, 0.06, 0.012), (bx + dx, by + 0.1, 0.945), m["fuliggine"]))
    for k, dx in enumerate((0.3, 0.52)):
        parti.append(base.cilindro_tra("crogiolo", (bx + dx, by - 0.12, 0.86), (bx + dx, by - 0.12, 1.0), 0.07, 0.1, m["bruciata"], lati=8))
    for k in range(3):
        parti.append(base.cilindro_tra("panella", (bx + 0.75, by + 0.2, 0.86 + k * 0.035), (bx + 0.75, by + 0.2, 0.89 + k * 0.035), 0.14, 0.13, m["bronzo"], lati=9))
    # Rastrelliera contro il fondo: asce, punte di lancia, una spada.
    rx0, rx1, ry = 0.4, 2.3, largo / 2 - 0.25
    for x in (rx0, rx1):
        parti.append(base.cilindro_tra("ritto", (x, ry, 0), (x, ry, 1.55), 0.045, 0.04, m["legno"], lati=5))
    parti.append(base.cilindro_tra("traversa", (rx0, ry, 1.45), (rx1, ry, 1.45), 0.04, 0.04, m["legno"], lati=5))
    for k in range(5):
        x = rx0 + 0.25 + k * 0.36
        if k % 2 == 0:  # lancia: asta e punta a foglia
            parti.append(base.cilindro_tra("asta", (x, ry - 0.2, 0), (x, ry - 0.05, 1.5), 0.022, 0.02, m["legno"], lati=4))
            parti.append(base.cilindro_tra("punta", (x, ry - 0.05, 1.5), (x, ry - 0.03, 1.9), 0.075, 0.005, m["bronzo"], lati=4))
        else:  # ascia appesa per il manico
            parti.append(base.cilindro_tra("manico", (x, ry - 0.1, 0.75), (x, ry - 0.05, 1.45), 0.024, 0.022, m["legno"], lati=4))
            parti.append(base.scatola("ascia", (0.09, 0.06, 0.26), (x + 0.07, ry - 0.08, 0.82), m["bronzo"]))
    parti.append(base.scatola("spada", (0.6, 0.05, 0.012), (bx - 0.2, by - 0.2, 0.87), m["bronzo"]))
    parti.append(base.scatola("elsa", (0.16, 0.06, 0.03), (bx - 0.55, by - 0.2, 0.875), m["legno"]))
    # Sgabello, cassa, cesti di carbone.
    parti.append(base.cilindro_tra("sgabello", (-0.2, -0.1, 0), (-0.2, -0.1, 0.42), 0.2, 0.18, m["corteccia"], lati=8))
    parti.append(base.scatola("cassa", (0.8, 0.5, 0.45), (-1.6, 0.9, 0.23), m["legno"]))
    for k, (cx, cy) in enumerate(((fx + 0.9, fy + 1.35), (fx + 1.45, fy + 1.1), (fx + 1.2, fy + 1.75))):
        parti.append(base.cilindro_tra("cesto", (cx, cy, 0), (cx, cy, 0.42), 0.24, 0.29, m["vimini"], lati=9))
        parti.append(_disco("carbone", (cx, cy), 0.26, m["carbone"], rnd, lati=9, irregolare=0.05, z=0.4))
    # Fuori: legna, minerale, vasca per temprare in un tronco scavato.
    villaggio._catasta(parti, m, rnd, fx - 0.2, fy + 2.4, lungo=1.6, file=(4, 3, 2))
    for k in range(6):
        parti.append(villaggio.sasso("minerale", (0.3, 0.25, 0.2), (fx - 1.0 + rnd.uniform(-0.35, 0.35), fy - 1.6 + rnd.uniform(-0.3, 0.3), 0), m["minerale"], seme + 20 + k))
    vx, vy = 1.4, -largo / 2 - 1.35
    tronco = base.cilindro_tra("vasca", (vx - 0.7, vy, 0.26), (vx + 0.7, vy, 0.26), 0.3, 0.3, m["corteccia"], lati=10)
    for v in tronco.data.vertices:
        v.co.z = min(v.co.z, 0.44)
    parti.append(tronco)
    parti.append(base.scatola("acqua", (1.3, 0.42, 0.02), (vx, vy, 0.445), m["acqua_vasca"]))
    return base.unisci(nome, parti)


def cantiere_officina_fabbro(nome, seme):
    """Officina del fabbro in costruzione: pali sugli zoccoli, la trave davanti e metà dei correnti,
    niente paglia; il muretto a secco già su, la fornace col piede di pietre e il corpo a metà, senza
    volta né camino; accanto pali stesi, fasci di paglia, argilla e sassi."""
    return officina_fabbro(nome, seme, cantiere=True)


# ---------- secondo lotto (27/11/2026) ----------
# Decisione di Fede del 27/11/2026: con l'abitato le strade contano di più e le case si sviluppano
# lungo la via. La casa su impalcato dà la testata con la porta e la scaletta (+x) sulla strada: le
# varianti hanno davanti un banco o un telaio (le prime botteghe), dietro l'orto o le cataste, e sui
# fianchi quasi niente, perché in fila le case sono vicine.


def _banco_vasi(parti, m, rnd, x, y):
    """Banco di tavole basso con vasi, ciotole e un cesto: la merce sulla via."""
    for dx in (-0.6, 0.6):
        for dy in (-0.25, 0.25):
            parti.append(base.cilindro_tra("gamba", (x + dy, y + dx, 0), (x + dy, y + dx, 0.6), 0.04, 0.04, m["legno"], lati=5))
    parti.append(base.scatola("banco", (0.7, 1.5, 0.07), (x, y, 0.63), m["legno"]))
    for k in range(4):
        vy = y - 0.55 + k * 0.37
        r = rnd.uniform(0.11, 0.16)
        parti.append(base.cilindro_tra("vaso", (x, vy, 0.66), (x, vy, 0.66 + r * 2.0), r, r * 0.6, m["argilla"], lati=9))
    vimini = base.materiale("vimini", "paglia", tinta=(0.72, 0.58, 0.4))
    parti.append(base.cilindro_tra("cesto", (x + 0.75, y + 0.3, 0), (x + 0.75, y + 0.3, 0.38), 0.24, 0.3, vimini, lati=9))
    parti.append(base.cilindro_tra("dolio", (x + 0.8, y - 0.55, 0), (x + 0.8, y - 0.55, 0.75), 0.28, 0.2, m["argilla"], lati=10))


def _telaio(parti, m, rnd, x, y, z0):
    """Telaio verticale a pesi sul ballatoio: due ritti, il subbio, l'ordito e i pesi d'argilla."""
    for dy in (-0.7, 0.7):
        parti.append(base.cilindro_tra("ritto", (x, y + dy, z0), (x - 0.25, y + dy, z0 + 1.9), 0.05, 0.045, m["legno"], lati=5))
    parti.append(base.cilindro_tra("subbio", (x - 0.22, y - 0.85, z0 + 1.78), (x - 0.22, y + 0.85, z0 + 1.78), 0.05, 0.05, m["legno"], lati=6))
    tela = base.materiale("tela", "intonaco", tinta=(0.78, 0.4, 0.26))
    parti.append(base.scatola("tela", (0.03, 1.3, 1.0), (x - 0.17, y, z0 + 1.25), tela))
    for k in range(7):
        py = y - 0.6 + k * 0.2
        parti.append(base.cilindro_tra("peso", (x - 0.08, py, z0 + 0.35), (x - 0.08, py, z0 + 0.5), 0.06, 0.05, m["argilla"], lati=6))


def annessi_piccola(parti, m, rnd, lungo, largo, ballatoio):
    # Davanti, di fianco alla scaletta: il banco con i vasi. Dietro: l'orto.
    xf = lungo / 2 + ballatoio
    _banco_vasi(parti, m, rnd, xf + 1.0, -largo / 2 + 0.2)
    villaggio._orto(parti, m, rnd, -lungo / 2 - 4.6, -largo / 2, -lungo / 2 - 0.8, largo / 2)


def annessi_media(parti, m, rnd, lungo, largo, ballatoio):
    # Davanti: il telaio sul ballatoio e un dolio ai piedi della scaletta. Dietro: cataste e fieno.
    xf = lungo / 2 + ballatoio
    _telaio(parti, m, rnd, xf - 0.35, largo / 2 - 1.0, ALTO_IMPALCATO + 0.05)
    parti.append(base.cilindro_tra("dolio", (xf + 1.3, largo / 2 - 0.4, 0), (xf + 1.3, largo / 2 - 0.4, 0.8), 0.3, 0.22, m["argilla"], lati=10))
    villaggio._catasta(parti, m, rnd, -lungo / 2 - 1.3, -largo / 4, lungo=1.8, file=(4, 3, 2), lungo_y=True)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=1.1, radius2=0.15, depth=1.9)
    bmesh.ops.translate(bm, vec=Vector((-lungo / 2 - 1.6, largo / 4 + 0.4, 0.95)), verts=bm.verts)
    for v in bm.verts:
        v.co.x += rnd.uniform(-0.06, 0.06)
    bm.normal_update()
    parti.append(base.da_bmesh("pagliaio", bm, m["paglia"], tile=1.0))
    parti.append(base.cilindro_tra("stollo", (-lungo / 2 - 1.6, largo / 4 + 0.4, 0), (-lungo / 2 - 1.6, largo / 4 + 0.4, 2.3), 0.04, 0.035, m["legno"], lati=4))


def _materiali_lotto2():
    m = materiali_fabbro()
    m["erba_tumulo"] = base.materiale("erba_tumulo", "erba", tinta=(0.56, 0.55, 0.4))
    m["assi"] = base.materiale("assi", "legno", tinta=(0.86, 0.8, 0.72))
    return m


def _recinto_pali(parti, m, rnd, angoli, alto, varco_lato=None, varco=1.6, graticcio=True, passo=1.3):
    """Recinto di pali sui lati di un poligono, con il graticcio fra i pali e un varco a metà di un lato."""
    for k in range(len(angoli)):
        a, b = angoli[k], angoli[(k + 1) % len(angoli)]
        lato = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(lato / passo))
        punti = [(a[0] + (b[0] - a[0]) * j / n, a[1] + (b[1] - a[1]) * j / n) for j in range(n + 1)]
        mezzo = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        def nel_varco(p):
            return k == varco_lato and math.hypot(p[0] - mezzo[0], p[1] - mezzo[1]) < varco / 2
        for p in punti:
            if not nel_varco(p):
                parti.append(base.cilindro_tra("palo", (p[0], p[1], -0.15), (p[0], p[1], alto + rnd.uniform(-0.05, 0.05)), 0.07, 0.06, m["corteccia"], lati=5))
        if graticcio:
            for j in range(n):
                if nel_varco(punti[j]) or nel_varco(punti[j + 1]):
                    continue
                villaggio._graticcio_dritto(parti, m, rnd, punti[j], punti[j + 1], 0.12, max(3, int(alto / 0.2)))


def santuario(nome, seme, cantiere=False):
    """Santuario (proposta di Claude, epoca2-proposte § 3): recinto sacro quadrato di pali con il
    graticcio, l'ingresso verso +x (la via); dentro un'edicola su un basamento di pietre, a due falde
    con le corna, e davanti l'altare di pietre e argilla con il fuoco (il fumo nasce lì: proposta,
    il santuario è un edificio comunitario). Pali votivi con le corna, vasi delle offerte, una fossa."""
    m = _materiali_lotto2()
    rnd = random.Random(seme)
    parti = []
    L = 5.0
    if not cantiere:
        _recinto_pali(parti, m, rnd, [(-L, -L), (L, -L), (L, L), (-L, L)], 1.5, varco_lato=1, varco=2.0)
    else:
        for p in ((-L, -L), (L, -L), (L, L), (-L, L)):
            parti.append(base.cilindro_tra("palo", (p[0], p[1], -0.15), (p[0], p[1], 1.5), 0.07, 0.06, m["corteccia"], lati=5))
    parti.append(_disco("battuto", (0, 0), L * 0.95, m["terra"], rnd, lati=20, irregolare=0.05, z=0.05))
    # Basamento di pietre e edicola.
    ex = -2.2
    for k in range(14):
        a = 2 * math.pi * k / 14
        parti.append(villaggio.sasso("basamento", (0.5, 0.4, 0.35), (ex + 1.9 * math.cos(a), 1.5 * math.sin(a), 0), m["pietra"], seme + 10 + k))
    parti.append(base.scatola("piano", (3.6, 2.8, 0.35), (ex, 0, 0.2), m["terra"]))
    alto_parete = 1.5
    if cantiere:
        for dx in (-1.3, 1.3):
            for dy in (-0.9, 0.9):
                parti.append(base.cilindro_tra("palo", (ex + dx, dy, 0.3), (ex + dx, dy, 0.3 + alto_parete), 0.09, 0.08, m["corteccia"], lati=6))
        villaggio.materiali_a_terra(parti, m, rnd, 1.5, -2.5, seme)
        return base.unisci(nome, parti)
    parti.append(base.scatola("pareti", (2.6, 1.8, alto_parete), (ex, 0, 0.37 + alto_parete / 2), m["intonaco"], tagli=3))
    parti.append(base.scatola("porta", (0.12, 0.8, 1.2), (ex + 1.33, 0, 0.37 + 0.6), m["vano"]))
    gronda = 0.37 + alto_parete - 0.05
    colmo = gronda + 1.4
    tetto = tetto_a_capanna("tetto", 2.6, 1.8, gronda, colmo, 0.5, 0.45, 0.3, m["paglia"], seme)
    tetto.location.x += ex
    bpy.context.view_layer.objects.active = tetto
    bpy.ops.object.select_all(action="DESELECT")
    tetto.select_set(True)
    bpy.ops.object.transform_apply(location=True)
    parti.append(tetto)
    for x in (ex + 1.8, ex - 1.8):
        corna(parti, m, x, colmo, 2.8, 0.7)
    # Le corna del colmo di corna() vanno da -x a x: qui l'edicola non è centrata, si rifà il colmo.
    parti[-1] = base.cilindro_tra("colmo", (ex - 1.8, 0, colmo + 0.08), (ex + 1.8, 0, colmo + 0.08), 0.07, 0.07, m["corteccia"], lati=6)
    # Altare davanti all'edicola: pietre, piano d'argilla, il fuoco.
    ax = 0.9
    for k in range(9):
        a = 2 * math.pi * k / 9
        parti.append(villaggio.sasso("altare", (0.42, 0.36, 0.5), (ax + 0.75 * math.cos(a), 0.75 * math.sin(a), 0), m["pietra"], seme + 40 + k))
    parti.append(base.cilindro_tra("piano_altare", (ax, 0, 0), (ax, 0, 0.62), 0.78, 0.7, m["argilla"], lati=12))
    parti.append(_disco("fuoco", (ax, 0), 0.42, m["brace"], rnd, lati=10, irregolare=0.1, z=0.64))
    for k in range(4):
        a = rnd.uniform(0, 2 * math.pi)
        parti.append(base.cilindro_tra("tizzone", (ax + 0.1 * math.cos(a), 0.1 * math.sin(a), 0.66), (ax + 0.45 * math.cos(a), 0.45 * math.sin(a), 0.7), 0.05, 0.04, m["fuliggine"], lati=5))
    CAMINI[nome] = (ax, 0.0, 0.75)
    # Pali votivi con le corna di bue, ai lati dell'ingresso; vasi delle offerte; la fossa.
    for y in (-1.8, 1.8):
        parti.append(base.cilindro_tra("palo_votivo", (L - 1.2, y, -0.1), (L - 1.2, y, 2.6), 0.1, 0.08, m["legno"], lati=6))
        for s in (-1, 1):
            parti.append(base.cilindro_tra("corno", (L - 1.2, y, 2.5), (L - 1.2, y + s * 0.4, 2.85), 0.06, 0.02, m["pietra_chiara"], lati=5))
    for k in range(6):
        a = rnd.uniform(0, 2 * math.pi)
        d = rnd.uniform(1.2, 1.6)
        r = rnd.uniform(0.1, 0.16)
        parti.append(base.cilindro_tra("vaso_offerta", (ax + d * math.cos(a), d * math.sin(a), 0.05), (ax + d * math.cos(a), d * math.sin(a), 0.05 + r * 2), r, r * 0.65, m["argilla"], lati=8))
    parti.append(_disco("fossa", (2.6, 2.8), 0.6, m["fuliggine"], rnd, lati=10, z=0.06))
    return base.unisci(nome, parti)


def tumulo(nome, seme):
    """Tumulo (proposta di Claude): monte di terra coperto d'erba, largo 11 m e alto 2,4, con il
    cerchio di pietre alla base e una stele di pietra in cima."""
    m = _materiali_lotto2()
    rnd = random.Random(seme)
    parti = []
    R, H = 5.5, 2.4
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=10, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.01], context="VERTS")
    for v in bm.verts:
        k = 1.0 + rnd.uniform(-0.03, 0.03)
        z = v.co.z
        # Profilo schiacciato: più ripido ai piedi, tondo in cima.
        v.co = Vector((v.co.x * R * k, v.co.y * R * k, (z ** 0.8) * H * (1.0 + rnd.uniform(-0.04, 0.04))))
    bm.normal_update()
    parti.append(base.da_bmesh("monte", bm, m["erba_tumulo"], tile=3.0))
    n = 28
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.03, 0.03)
        parti.append(villaggio.sasso("crepidine", (0.6, 0.45, 0.45), ((R + 0.15) * math.cos(a), (R + 0.15) * math.sin(a), 0), m["pietra"], seme + k))
    s = base.scatola("stele", (0.22, 0.5, 1.3), (0, 0, H + 0.55), m["pietra_chiara"])
    s.rotation_euler = (0.05, 0.04, 0.4)
    parti.append(s)
    return base.unisci(nome, parti)


def granaio_comune(nome, seme, cantiere=False):
    """Granaio comune (proposta di Claude): 6 × 4 m su pali alti 1,6 m con i dischi di pietra contro i
    topi, pareti di assi, tetto a due falde di paglia con le corna; una scala a pioli mobile, i sacchi
    e le giare all'ingresso (+x)."""
    m = _materiali_lotto2()
    rnd = random.Random(seme)
    parti = []
    lungo, largo, alto_pali = 6.0, 4.0, 1.6
    for i in range(4):
        x = -lungo / 2 + i * lungo / 3
        for y in (-largo / 2, 0.0, largo / 2):
            parti.append(base.cilindro_tra("pilastro", (x, y, -0.2), (x, y, alto_pali - 0.25), 0.15, 0.13, m["corteccia"], lati=7))
            parti.append(base.cilindro_tra("disco", (x, y, alto_pali - 0.25), (x, y, alto_pali - 0.13), 0.38, 0.34, m["pietra"], lati=10))
    if cantiere:
        parti.append(base.scatola("tavolato", (lungo + 0.3, largo + 0.3, 0.12), (0, 0, alto_pali), m["legno"], tagli=2))
        villaggio.materiali_a_terra(parti, m, rnd, 0.0, -largo / 2 - 2.0, seme)
        return base.unisci(nome, parti)
    parti.append(base.scatola("tavolato", (lungo + 0.3, largo + 0.3, 0.12), (0, 0, alto_pali), m["legno"], tagli=2))
    z0, alto = alto_pali + 0.06, 1.8
    parti.append(base.scatola("pareti", (lungo, largo, alto), (0, 0, z0 + alto / 2), m["assi"], tagli=3))
    for x in (-lungo / 2, lungo / 2):
        for y in (-largo / 2, largo / 2):
            parti.append(base.cilindro_tra("palo", (x, y, z0), (x, y, z0 + alto), 0.11, 0.1, m["corteccia"], lati=6))
    parti.append(base.scatola("porta", (0.12, 1.0, 1.3), (lungo / 2 + 0.03, 0, z0 + 0.65), m["vano"]))
    gronda = z0 + alto - 0.05
    colmo = gronda + largo * 0.6
    parti.append(tetto_a_capanna("tetto", lungo, largo, gronda, colmo, 0.6, 0.6, 0.35, m["paglia"], seme))
    corna(parti, m, lungo / 2 + 0.6, colmo, largo + 1.2, 0.7)
    corna(parti, m, -(lungo / 2 + 0.6), colmo, largo + 1.2, 0.7)
    # Scala a pioli appoggiata alla porta.
    for dy in (-0.25, 0.25):
        parti.append(base.cilindro_tra("staggio", (lungo / 2 + 1.1, dy, 0), (lungo / 2 + 0.1, dy, z0 + 0.1), 0.04, 0.04, m["legno"], lati=5))
    for k in range(1, 5):
        t = k / 5
        x = lungo / 2 + 1.1 - t
        parti.append(base.cilindro_tra("piolo", (x, -0.27, t * (z0 + 0.1)), (x, 0.27, t * (z0 + 0.1)), 0.025, 0.025, m["legno"], lati=4))
    sacco = base.materiale("sacco", "intonaco", tinta=(0.82, 0.74, 0.6))
    for k in range(4):
        sx, sy = lungo / 2 + 1.6 + rnd.uniform(-0.2, 0.3), -1.4 + k * 0.45
        parti.append(villaggio.sasso("sacco", (0.45, 0.4, 0.5), (sx, sy, 0), sacco, seme + 30 + k))
    for k in range(2):
        parti.append(base.cilindro_tra("giara", (lungo / 2 + 1.5, 1.3 + k * 0.6, 0), (lungo / 2 + 1.5, 1.3 + k * 0.6, 0.85), 0.3, 0.2, m["argilla"], lati=10))
    return base.unisci(nome, parti)


def pozzo(nome, seme, cantiere=False):
    """Pozzo (proposta di Claude; alle terramare i pozzi erano foderati di tavole): vera quadrata di
    tavole incastrate, il bilanciere con il contrappeso di pietra e il secchio, un selciato di
    sassi attorno e un abbeveratoio scavato in un tronco."""
    m = _materiali_lotto2()
    rnd = random.Random(seme)
    parti = []
    parti.append(_disco("selciato", (0, 0), 2.4, m["pietra"], rnd, lati=16, irregolare=0.1, z=0.04))
    for k in range(18):
        a = rnd.uniform(0, 2 * math.pi)
        d = rnd.uniform(1.2, 2.3)
        parti.append(villaggio.sasso("ciottolo", (0.3, 0.26, 0.1), (d * math.cos(a), d * math.sin(a), 0), m["pietra"], seme + k))
    lato, alto = 1.5, 0.0 if cantiere else 0.8
    parti.append(base.scatola("acqua", (lato - 0.2, lato - 0.2, 0.02), (0, 0, 0.06), m["acqua_vasca"]))
    righe = 2 if cantiere else 5
    for r in range(righe):
        z = 0.08 + r * 0.17
        for s in (-1, 1):
            parti.append(base.scatola("asse", (lato + 0.2, 0.12, 0.16), (0, s * lato / 2, z + 0.08), m["assi"]))
            parti.append(base.scatola("asse", (0.12, lato + 0.2, 0.16), (s * lato / 2, 0, z + 0.08), m["assi"]))
    if cantiere:
        villaggio.materiali_a_terra(parti, m, rnd, 0.0, 2.8, seme, pali=3, lungo=2.4)
        return base.unisci(nome, parti)
    # Bilanciere: forcella piantata, stanga lunga, contrappeso, corda e secchio.
    fx, fy = 0.0, 2.0
    for dx in (-0.12, 0.12):
        parti.append(base.cilindro_tra("forcella", (fx + dx, fy, -0.1), (fx + dx * 1.6, fy, 2.6), 0.1, 0.07, m["corteccia"], lati=6))
    perno = Vector((fx, fy, 2.5))
    testa = Vector((0.0, -0.1, 3.3))
    coda = perno + (perno - testa) * 0.55
    parti.append(base.cilindro_tra("stanga", tuple(testa), tuple(coda), 0.06, 0.08, m["legno"], lati=6))
    parti.append(villaggio.sasso("contrappeso", (0.5, 0.45, 0.45), (coda.x, coda.y, coda.z - 0.4), m["pietra"], seme + 50, appoggiato=False))
    parti.append(base.cilindro_tra("corda", (testa.x, testa.y, testa.z), (0.0, -0.1, 1.2), 0.012, 0.012, m["legno"], lati=4))
    parti.append(base.cilindro_tra("secchio", (0.0, -0.1, 0.9), (0.0, -0.1, 1.2), 0.15, 0.18, m["legno"], lati=8))
    tronco = base.cilindro_tra("abbeveratoio", (1.7, -0.9, 0.24), (1.7, 0.9, 0.24), 0.28, 0.28, m["corteccia"], lati=10)
    for v in tronco.data.vertices:
        v.co.z = min(v.co.z, 0.4)
    parti.append(tronco)
    parti.append(base.scatola("acqua_abbeveratoio", (0.36, 1.7, 0.02), (1.7, 0, 0.405), m["acqua_vasca"]))
    return base.unisci(nome, parti)


def recinto_bestiame(nome, seme):
    """Recinto del bestiame (proposta di Claude): 16 × 10 m di pali e graticcio alto 1,3 m, il cancello
    di traverse verso +x, una tettoia di paglia lungo il lato di fondo, l'abbeveratoio, il fieno e il
    letame. Più grande e regolare dello stabbio del villaggio: sta fuori dal recinto dell'abitato."""
    m = _materiali_lotto2()
    rnd = random.Random(seme)
    parti = []
    X, Y = 8.0, 5.0
    _recinto_pali(parti, m, rnd, [(-X, -Y), (X, -Y), (X, Y), (-X, Y)], 1.3, varco_lato=1, varco=2.6, passo=1.6)
    # Cancello aperto: traverse su due ritti, girato verso l'esterno.
    for k in range(3):
        z = 0.35 + k * 0.4
        parti.append(base.cilindro_tra("traversa", (X, -1.3, z), (X + 1.9, -1.9, z), 0.05, 0.05, m["legno"], lati=5))
    parti.append(base.cilindro_tra("ritto", (X + 1.9, -1.9, 0), (X + 1.9, -1.9, 1.3), 0.05, 0.05, m["legno"], lati=5))
    # Tettoia lungo il lato di fondo (-x).
    prof = 3.0
    for y in (-Y + 0.3, 0.0, Y - 0.3):
        parti.append(base.cilindro_tra("palo_tettoia", (-X + prof, y, -0.1), (-X + prof, y, 2.1), 0.1, 0.09, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("palo_tettoia", (-X + 0.15, y, -0.1), (-X + 0.15, y, 2.6), 0.1, 0.09, m["corteccia"], lati=6))
    falda = base.scatola("falda", (prof + 0.8, 2 * Y + 0.4, 0.18), (0, 0, 0), m["paglia"], tagli=3)
    falda.rotation_euler = (0, math.atan2(0.5, prof), 0)
    falda.location = (-X + prof / 2, 0, 2.5)
    parti.append(falda)
    terra_calpestata = base.materiale("calpestato", "terra", tinta=(0.78, 0.7, 0.62))
    parti.append(_disco("calpestato", (0.5, 0), 4.2, terra_calpestata, rnd, lati=18, irregolare=0.2, z=0.04))
    tronco = base.cilindro_tra("abbeveratoio", (2.0, Y - 1.0, 0.24), (4.6, Y - 1.0, 0.24), 0.3, 0.3, m["corteccia"], lati=10)
    for v in tronco.data.vertices:
        v.co.z = min(v.co.z, 0.42)
    parti.append(tronco)
    parti.append(base.scatola("acqua", (2.4, 0.4, 0.02), (3.3, Y - 1.0, 0.425), m["acqua_vasca"]))
    for k in range(3):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.9, radius2=0.3, depth=0.9)
        bmesh.ops.translate(bm, vec=Vector((-X + 1.4, -Y + 1.4 + k * 1.6, 0.45)), verts=bm.verts)
        bm.normal_update()
        parti.append(base.da_bmesh("fieno", bm, m["paglia"], tile=1.0))
    letame = base.materiale("letame", "terra", tinta=(0.45, 0.36, 0.28))
    parti.append(villaggio.sasso("letame", (1.8, 1.2, 0.5), (X - 1.8, Y - 1.4, 0), letame, seme + 60))
    return base.unisci(nome, parti)


LUNGO_PONTE = 16.0


def ponte(nome, seme, cantiere=False):
    """Ponte di legno sui torrenti larghi (decisione di Fede del 26/11/2026: nel villaggio la strada si
    fermava al guado). Lungo 16 m (asse x), largo 3: impalcato di tavole a 1,4 m sull'origine, su
    coppie di pali ogni 4 m con le sbadacchiature, parapetto di stanghe, rampe di terra ai due capi.
    I pali si piantano nel letto: nel gioco il ponte si posa alla quota delle sponde."""
    m = _materiali_lotto2()
    rnd = random.Random(seme)
    parti = []
    L, W, z = LUNGO_PONTE / 2, 1.5, 1.4
    campate = 4
    for i in range(campate + 1):
        x = -L + 2.0 + i * (2 * L - 4.0) / campate
        for y in (-W + 0.1, W - 0.1):
            parti.append(base.cilindro_tra("palo", (x + rnd.uniform(-0.05, 0.05), y, -0.25), (x, y, z - 0.1), 0.16, 0.14, m["corteccia"], lati=7))
        parti.append(base.cilindro_tra("traverso", (x, -W - 0.2, z - 0.15), (x, W + 0.2, z - 0.15), 0.12, 0.12, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("sbadacchio", (x, -W + 0.1, 0.1), (x, W - 0.1, z - 0.3), 0.06, 0.06, m["legno"], lati=5))
    for y in (-W + 0.3, 0.0, W - 0.3):
        parti.append(base.cilindro_tra("longherone", (-L + 1.6, y, z - 0.02), (L - 1.6, y, z - 0.02), 0.11, 0.11, m["corteccia"], lati=6))
    if cantiere:
        villaggio.materiali_a_terra(parti, m, rnd, -L + 1.0, W + 1.5, seme, pali=5, lungo=4.0)
        return base.unisci(nome, parti)
    # Tavole di traverso, una per una, appena disuguali.
    x = -L + 1.6
    while x < L - 1.6:
        larga = rnd.uniform(0.28, 0.36)
        parti.append(base.scatola("tavola", (larga - 0.02, 2 * W + rnd.uniform(-0.1, 0.1), 0.08), (x + larga / 2, rnd.uniform(-0.04, 0.04), z + 0.1 + rnd.uniform(-0.01, 0.01)), m["assi"]))
        x += larga
    # Parapetto.
    for y in (-W, W):
        for i in range(5):
            xp = -L + 1.8 + i * (2 * L - 3.6) / 4
            parti.append(base.cilindro_tra("ritto", (xp, y, z), (xp, y, z + 1.0), 0.06, 0.05, m["legno"], lati=5))
        parti.append(base.cilindro_tra("corrimano", (-L + 1.8, y, z + 0.95), (L - 1.8, y, z + 0.95), 0.05, 0.05, m["legno"], lati=5))
    # Rampe di terra ai capi.
    for s in (-1, 1):
        bm = bmesh.new()
        x0, x1 = s * (L - 1.7), s * L
        pts = [(x0, -W - 0.3, 0.0), (x0, W + 0.3, 0.0), (x0, W + 0.1, z + 0.12), (x0, -W - 0.1, z + 0.12),
               (x1, -W - 0.6, 0.0), (x1, W + 0.6, 0.0)]
        v = [bm.verts.new(p) for p in pts]
        facce = [[v[3], v[2], v[5], v[4]], [v[0], v[3], v[4]], [v[1], v[5], v[2]], [v[0], v[1], v[2], v[3]]]
        for f in facce:
            bm.faces.new(f if s > 0 else f[::-1])
        bm.normal_update()
        parti.append(base.da_bmesh("rampa", bm, m["terra"], tile=2.0))
    return base.unisci(nome, parti)


# ---------- cantieri del secondo lotto ----------
def cantiere_casa(nome, lungo, largo, seme, capo=False):
    """Casa su impalcato in costruzione: l'impalcato finito, i pali delle pareti, metà dei correnti del
    tetto; accanto i pali stesi, i fasci di paglia e l'argilla per l'intonaco."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    z0 = ALTO_IMPALCATO + 0.05
    alto = 1.75 if not capo else 2.0
    ballatoio = 1.6 if not capo else 3.2
    impalcato(parti, m, rnd, -lungo / 2 - 0.3, lungo / 2 + ballatoio, -largo / 2 - 0.3, largo / 2 + 0.3)
    n = max(2, int(lungo / 1.6))
    for k in range(n + 1):
        x = -lungo / 2 + k * lungo / n
        for y in (-largo / 2, largo / 2):
            parti.append(base.cilindro_tra("palo", (x, y, z0 - 0.05), (x, y, z0 + alto - 0.08), 0.11, 0.1, m["corteccia"], lati=6))
    # Graticcio ancora senza intonaco su un lato lungo, a metà.
    villaggio._graticcio_dritto(parti, m, rnd, (-lungo / 2, largo / 2), (0.0, largo / 2), z0 + 0.1, 6)
    gronda = z0 + alto - 0.05
    colmo = gronda + largo * 0.62
    for y in (-largo / 2, largo / 2):
        parti.append(base.cilindro_tra("trave", (-lungo / 2 - 0.3, y, gronda), (lungo / 2 + 0.3, y, gronda), 0.09, 0.09, m["corteccia"], lati=6))
    for x in (-lungo / 2, lungo / 2):
        for s in (-1, 1):
            parti.append(base.cilindro_tra("puntone", (x, s * largo / 2, gronda), (x, 0, colmo), 0.07, 0.07, m["corteccia"], lati=6))
    parti.append(base.cilindro_tra("colmo", (-lungo / 2, 0, colmo), (lungo / 2, 0, colmo), 0.08, 0.08, m["corteccia"], lati=6))
    for k in range(1, n, 2):
        x = -lungo / 2 + k * lungo / n
        for s in (-1, 1):
            parti.append(base.cilindro_tra("corrente", (x, s * (largo / 2 + 0.4), gronda - 0.2), (x, 0, colmo), 0.05, 0.05, m["legno"], lati=5))
    scaletta(parti, m, lungo / 2 + ballatoio + 0.2, 0.0)
    villaggio.materiali_a_terra(parti, m, rnd, 0.0, -largo / 2 - 1.8, seme)
    parti.append(villaggio.sasso("argilla", (0.9, 0.7, 0.35), (-lungo / 2 - 1.0, largo / 2 + 1.2, 0), m["argilla"], seme + 50))
    return base.unisci(nome, parti)


def cantiere_recinto(nome, seme):
    """Tratto di recinto in costruzione: il terrapieno a metà altezza, i primi pali della palizzata,
    gli altri stesi a terra con le ceste della terra."""
    m = materiali()
    rnd = random.Random(seme)
    parti = []
    L = LUNGO_TRATTO / 2 + 0.05
    alto, base_lato, cima = 0.8, 2.6, 1.5
    bm = bmesh.new()
    sezione = [(-base_lato, 0.0), (-cima, alto), (cima, alto), (base_lato, 0.0)]
    davanti = [bm.verts.new((-L, y, z)) for y, z in sezione]
    dietro = [bm.verts.new((L, y, z)) for y, z in sezione]
    for k in range(3):
        bm.faces.new([davanti[k], dietro[k], dietro[k + 1], davanti[k + 1]])
    bm.faces.new(davanti[::-1])
    bm.faces.new(dietro)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=4, use_grid_fill=True)
    for v in bm.verts:
        if 0.05 < v.co.z:
            v.co.z += rnd.uniform(-0.12, 0.08)
    bm.normal_update()
    parti.append(base.da_bmesh("terrapieno", bm, m["terra"], tile=2.0))
    y_pal = -cima + 0.4
    x = -L + 0.12
    while x < -L + 3.5:
        r = rnd.uniform(0.1, 0.14)
        h = alto + rnd.uniform(2.0, 2.4)
        parti.append(base.cilindro_tra("palo", (x, y_pal, alto - 0.4), (x, y_pal, h), r, r * 0.95, m["corteccia"], lati=6))
        parti.append(base.cilindro_tra("punta", (x, y_pal, h), (x, y_pal, h + 0.35), r * 0.95, 0.02, m["legno"], lati=6))
        x += r * 2.05
    villaggio.materiali_a_terra(parti, m, rnd, 1.5, 2.2, seme, pali=6, lungo=3.4)
    vimini = base.materiale("vimini", "paglia", tinta=(0.72, 0.58, 0.4))
    for k in range(3):
        cx, cy = 3.6 + k * 0.6, -2.4
        parti.append(base.cilindro_tra("cesta", (cx, cy, 0), (cx, cy, 0.4), 0.25, 0.3, vimini, lati=9))
    return base.unisci(nome, parti)


ASSET = [
    ("casa_impalcato_piccola", lambda n: casa(n, 7.5, 4.6, 61)),
    ("casa_impalcato_media", lambda n: casa(n, 10.5, 5.6, 62)),
    ("casa_del_capo", lambda n: casa(n, 15.0, 7.5, 63, capo=True)),
    ("recinto_tratto", lambda n: tratto_recinto(n, 64)),
    ("recinto_porta", lambda n: porta(n, 65)),
    ("officina_fabbro", lambda n: officina_fabbro(n, 66)),
    ("cantiere_officina_fabbro", lambda n: cantiere_officina_fabbro(n, 67)),
    # Secondo lotto (27/11/2026).
    ("casa_impalcato_piccola_b", lambda n: casa(n, 7.5, 4.6, 61, annessi=annessi_piccola)),
    ("casa_impalcato_media_b", lambda n: casa(n, 10.5, 5.6, 62, annessi=annessi_media)),
    ("santuario", lambda n: santuario(n, 68)),
    ("tumulo", lambda n: tumulo(n, 69)),
    ("granaio_comune", lambda n: granaio_comune(n, 70)),
    ("pozzo", lambda n: pozzo(n, 71)),
    ("recinto_bestiame", lambda n: recinto_bestiame(n, 72)),
    ("ponte", lambda n: ponte(n, 73)),
    ("cantiere_casa_impalcato_piccola", lambda n: cantiere_casa(n, 7.5, 4.6, 74)),
    ("cantiere_casa_impalcato_media", lambda n: cantiere_casa(n, 10.5, 5.6, 75)),
    ("cantiere_casa_del_capo", lambda n: cantiere_casa(n, 15.0, 7.5, 76, capo=True)),
    ("cantiere_recinto_tratto", lambda n: cantiere_recinto(n, 77)),
    ("cantiere_santuario", lambda n: santuario(n, 78, cantiere=True)),
    ("cantiere_granaio_comune", lambda n: granaio_comune(n, 79, cantiere=True)),
    ("cantiere_pozzo", lambda n: pozzo(n, 80, cantiere=True)),
    ("cantiere_ponte", lambda n: ponte(n, 81, cantiere=True)),
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
    _salva_camini()


def _salva_camini():
    """Scrive in `camini.json`, accanto ai modelli, dove nasce il fumo di ogni edificio con un
    camino (coordinate di Godot: x, y in alto, z = −y di Blender). Si fondono con quelle già scritte,
    così rifare un solo modello non cancella le altre."""
    import json
    percorso = os.path.join(USCITA, "camini.json")
    dati = {}
    if os.path.exists(percorso):
        with open(percorso) as f:
            dati = json.load(f)
    for nome, (x, y, z) in CAMINI.items():
        dati[nome] = [round(x, 3), round(z, 3), round(-y, 3)]
    if dati:
        with open(percorso, "w") as f:
            json.dump(dati, f, indent=1, sort_keys=True)


if __name__ == "__main__":
    main()
