"""Popolazione visibile del villaggio (26/11/2026, voce 7 del todo; decisioni di Fede del 25–26/11/2026):
3 uomini e 3 donne che si ripetono, con vesti, capelli e incarnato che variano nello shader; due
livelli di dettaglio, come gli animali; animazioni dallo shader (camminare, lavorare, stare fermi,
parlare in gruppo).

Come gli animali (`animali.py`), ogni persona è un corpo unico: un campo di distanza fatto di volumi
(ellissoidi e coni arrotondati per gambe, bacino, busto, braccia, mani, collo, testa, naso, capelli,
vesti, cintura, calzari) che si fondono morbidamente; la superficie si estrae con marching cubes e si
semplifica in due livelli:
  - completo (circa 3200 facce, con la testa che ne tiene più del resto) per le viste vicine;
  - leggero (circa 320 facce) per la media distanza.

Vesti del Neolitico (proposta di Claude): tunica di lana o di lino stretta in vita da una cintura,
al ginocchio per gli uomini e fino al polpaccio per le donne, maniche corte; qualcuno con un mantello
o una pelle sulle spalle; calzari di pelle; capelli lunghi sciolti o raccolti, una treccia, una
crocchia; barba per due uomini.

Seconda mappa UV ("Parti"): u = parte + classe / 10 + 0,05, v = peso lungo la parte.
  Parti: 0 busto e veste · 1 collo e testa · 2 braccio sinistro · 3 braccio destro ·
  4 gamba sinistra · 5 gamba destra · 6 attrezzo (nella mano destra).
  Classi (il colore lo sceglie lo shader, per ogni persona): 0 pelle · 1 capelli · 2 veste ·
  3 mantello o pelle · 4 calzari · 5 cintura · 6 legno · 7 selce · 8 vimini.
  Peso: dalla spalla alla punta delle dita per le braccia, dall'anca alla pianta per le gambe.
I colori dei vertici portano solo l'occlusione cotta (grigia). La persona guarda verso +y in Blender
(verso -z in Godot). Accanto ai modelli si scrive `persone.json` con i perni (anca, ginocchio, spalla,
gomito, collo) per lo shader, nelle coordinate di Godot.

Gli attrezzi (zappa, ascia, lancia, bastone, cesto) sono modelli a parte, già nella mano destra del
corpo a riposo e girati in modo da stare giusti con il braccio nella posa "tenere" dello shader.

Uso:  blender-py strumenti/blender/persone.py gioco/asset/persone
"""
import json
import math
import os
import random
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prova_stile_verosimile as base  # noqa: E402  (legge la cartella d'uscita da sys.argv[1])
import animali  # noqa: E402  (volumi, superficie, semplificazione, esportazione)
import bpy  # noqa: E402

Cono, Elli, esporta = animali.Cono, animali.Elli, animali.esporta
import bmesh  # noqa: E402
USCITA = base.USCITA
FACCE_COMPLETO = 3200
FACCE_LEGGERO = 320
QUOTA_TESTA = 0.4  # parte delle facce del modello completo che va alla testa e al collo
CLASSI = {"pelle": 0, "capelli": 1, "veste": 2, "mantello": 3, "calzari": 4, "cintura": 5, "legno": 6, "selce": 7, "vimini": 8, "occhi": 9}
PARTI = {"busto": 0, "testa": 1, "braccio_sx": 2, "braccio_dx": 3, "gamba_sx": 4, "gamba_dx": 5, "attrezzo": 6}


# ---------- volumi che scavano (orbite, bocca) e superficie ----------
class Scava(Elli):
    """Ellissoide che si toglie dal corpo, con un raccordo morbido (orbite degli occhi, bocca)."""
    sottrai = True


def campo(volumi, p):
    """Come animali.campo, più i volumi che scavano. I volumi si applicano nell'ordine in cui sono
    aggiunti: uno scavo toglie ciò che c'è già, e ciò che viene dopo (l'occhio nell'orbita) resta."""
    d = volumi[0].dist(p)
    for v in volumi[1:]:
        if getattr(v, "sottrai", False):
            d = -animali.unione_morbida(-d, v.dist(p), v.k)
        else:
            d = animali.unione_morbida(d, v.dist(p), v.k)
    return np.maximum(d, -p[:, 2])


def superficie(sp, passo_griglia):
    pieni = [v for v in sp.volumi if not getattr(v, "sottrai", False)]
    lo = np.min([v.limiti()[0] for v in pieni], axis=0) - 0.05
    hi = np.max([v.limiti()[1] for v in pieni], axis=0) + 0.05
    lo[2] = -passo_griglia * 2
    assi = [np.arange(lo[i], hi[i] + passo_griglia, passo_griglia) for i in range(3)]
    X, Y, Z = np.meshgrid(*assi, indexing="ij")
    p = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    d = np.empty(len(p))
    for i in range(0, len(p), 300000):
        d[i:i + 300000] = campo(sp.volumi, p[i:i + 300000])
    vol = d.reshape(X.shape)
    verts, facce, _n, _v = animali.measure.marching_cubes(vol, level=0.0, spacing=(passo_griglia,) * 3)
    return verts + lo, facce


def oggetto(nome, verts, facce, facce_volute, mat, sopra=None):
    """Come animali.oggetto; con `sopra` la testa (sopra quella quota) si semplifica a parte e tiene
    più triangoli: da vicino il viso ne ha bisogno."""
    me = bpy.data.meshes.new(nome)
    me.from_pydata(verts.tolist(), [], facce.tolist())
    me.update()
    ob = bpy.data.objects.new(nome, me)
    base.collega(ob, mat)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if sopra is None:
        mod = ob.modifiers.new("semplifica", "DECIMATE")
        mod.ratio = min(1.0, facce_volute / max(1, len(me.polygons)))
        bpy.ops.object.modifier_apply(modifier=mod.name)
    else:
        # Due semplificazioni separate in modo modifica, ognuna sulle sole facce scelte: la testa
        # tiene QUOTA_TESTA delle facce volute, il resto del corpo il rimanente. Il bordo tra le due
        # zone resta cucito perché la semplificazione non tocca i vertici fuori dalla scelta.
        for testa, quota in ((True, QUOTA_TESTA), (False, 1.0 - QUOTA_TESTA)):
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_mode(type="FACE")
            bpy.ops.mesh.select_all(action="DESELECT")
            bm = bmesh.from_edit_mesh(me)
            scelte = 0
            for f in bm.faces:
                if (f.calc_center_median().z > sopra) == testa:
                    f.select_set(True)
                    scelte += 1
            bm.select_flush_mode()
            bmesh.update_edit_mesh(me)
            bpy.ops.mesh.decimate(ratio=min(1.0, facce_volute * quota / max(1, scelte)))
            bpy.ops.object.mode_set(mode="OBJECT")
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(me)
    bm.free()
    me.validate()
    bpy.ops.object.shade_smooth()
    return ob


# ---------- scheletro ----------
class Scheletro:
    """Le misure di un corpo (uomo alto 1,70 m; la donna è la stessa figura a 0,93)."""

    def __init__(self, scala):
        s = scala
        self.s = s
        self.anca = 0.90 * s  # perno delle gambe
        self.x_anca = 0.095 * s
        self.ginocchio = 0.48 * s
        self.caviglia = 0.075 * s
        self.spalla = (0.185 * s, 0.0, 1.41 * s)  # destra (x positivo); la sinistra è a specchio
        # Braccia un po' scostate dal corpo: a riposo la mano non tocca la veste (altrimenti si
        # fondevano e, alzando il braccio, si tendeva una membrana tra la mano e il fianco).
        self.gomito = (0.228 * s, -0.015 * s, 1.12 * s)
        self.polso = (0.258 * s, 0.01 * s, 0.86 * s)
        self.mano = (0.266 * s, 0.015 * s, 0.775 * s)
        self.punta = (0.272 * s, 0.02 * s, 0.70 * s)
        self.collo = 1.47 * s  # perno della testa
        self.testa = 1.62 * s


def braccio(p, sk, lato, parte, pelle_avambraccio=True, manica=0.55):
    """Braccio in tre tratti (spalla-gomito, gomito-polso, mano). La manica corta della tunica copre
    la parte alta: `manica` è la frazione del braccio coperta."""
    m = (lambda q: (q[0] * lato, q[1], q[2]))
    s = sk.s
    sp, go, po, ma = m(sk.spalla), m(sk.gomito), m(sk.polso), m(sk.mano)
    fine_manica = tuple(np.array(sp) + (np.array(go) - np.array(sp)) * manica)
    # Braccio asciutto e manica aderente (26/11/2026, Fede: le spalle da rifinire; prima la manica
    # larga faceva uno sbuffo).
    p.add(Cono(sp, go, 0.046 * s, 0.036 * s, "pelle", parte, k=0.02))
    p.add(Cono(sp, fine_manica, 0.054 * s, 0.047 * s, "veste", parte, k=0.012))
    p.add(Cono(go, po, 0.039 * s, 0.030 * s, "pelle" if pelle_avambraccio else "veste", parte, k=0.015))
    p.add(Elli(ma, (0.030 * s, 0.022 * s, 0.055 * s), "pelle", parte, k=0.012))
    p.add(Cono(ma, m(sk.punta), 0.018 * s, 0.012 * s, "pelle", parte, k=0.01))
    # Il pollice, un po' in avanti.
    p.add(Cono((ma[0], ma[1] + 0.02 * s, ma[2] + 0.01 * s), (ma[0], ma[1] + 0.045 * s, ma[2] - 0.025 * s), 0.012 * s, 0.009 * s, "pelle", parte, k=0.008))


def gamba(p, sk, lato, parte, polpaccio_coperto=False):
    """Gamba in due tratti con il ginocchio appena avanti, piede con il calzare."""
    s = sk.s
    x = sk.x_anca * lato
    anca, gin, cav = (x, 0.0, sk.anca), (x * 1.02, 0.01 * s, sk.ginocchio), (x * 1.04, -0.01 * s, sk.caviglia)
    p.add(Cono(anca, gin, 0.082 * s, 0.056 * s, "veste", parte, k=0.03))
    p.add(Cono(gin, cav, 0.054 * s, 0.036 * s, "veste" if polpaccio_coperto else "pelle", parte, k=0.02))
    # Calzare di pelle: avvolge la caviglia e il piede (punta verso +y).
    p.add(Cono((cav[0], cav[1], cav[2] + 0.05 * s), (cav[0], cav[1], 0.03 * s), 0.044 * s, 0.05 * s, "calzari", parte, k=0.015))
    p.add(Elli((cav[0], cav[1] + 0.065 * s, 0.035 * s), (0.048 * s, 0.13 * s, 0.04 * s), "calzari", parte, k=0.02))


def corpo_base(sk, donna):
    """Busto, collo e testa comuni. Restituisce la persona (lista di volumi con parte e tinta)."""
    p = animali.Specie()
    s = sk.s
    # Bacino e busto sotto la tunica: la tunica li avvolge appena più larga.
    largo_spalle = 0.95 if donna else 1.0
    p.add(Elli((0, 0, 0.96 * s), (0.16 * s, 0.11 * s, 0.12 * s), "veste", 0, k=0.04))
    p.add(Elli((0, 0, 1.08 * s), (0.145 * s, 0.10 * s, 0.13 * s), "veste", 0, k=0.04))
    p.add(Elli((0, -0.005 * s, 1.27 * s), (0.165 * s * largo_spalle, 0.11 * s, 0.17 * s), "veste", 0, k=0.04))
    if donna:
        p.add(Elli((0.055 * s, 0.075 * s, 1.27 * s), (0.055 * s, 0.05 * s, 0.05 * s), "veste", 0, k=0.04))
        p.add(Elli((-0.055 * s, 0.075 * s, 1.27 * s), (0.055 * s, 0.05 * s, 0.05 * s), "veste", 0, k=0.04))
    # Spalle (26/11/2026, rifinite su richiesta di Fede): il trapezio scende dal collo alla spalla,
    # il deltoide è piccolo e raccordato; niente sfere che gonfiano la manica.
    for lato in (1, -1):
        x_sp = sk.spalla[0] * lato * largo_spalle
        p.add(Cono((0.03 * s * lato, -0.01 * s, 1.465 * s), (x_sp * 0.92, -0.005 * s, 1.405 * s), 0.045 * s, 0.05 * s, "veste", 0, k=0.035))
        p.add(Elli((x_sp * 0.95, 0.0, 1.385 * s), (0.05 * s, 0.055 * s, 0.05 * s), "veste", 0, k=0.03))
    if not donna:  # petto un po' più marcato
        p.add(Elli((0, 0.035 * s, 1.31 * s), (0.14 * s, 0.07 * s, 0.075 * s), "veste", 0, k=0.04))
    # Scollo, collo e testa.
    p.add(Cono((0, 0.0, 1.43 * s), (0, 0.005 * s, sk.testa - 0.05 * s), 0.05 * s, 0.045 * s, "pelle", 1, k=0.03))
    p.add(Elli((0, 0.005 * s, sk.testa), (0.078 * s, 0.092 * s, 0.108 * s), "pelle", 1, k=0.03))
    viso(p, sk, donna)
    # Cintura di cuoio in vita.
    p.add(Elli((0, 0.004 * s, 1.01 * s), (0.158 * s, 0.112 * s, 0.022 * s), "cintura", 0, k=0.006))
    return p


def viso(p, sk, donna):
    """Il viso (26/11/2026, rifinito su richiesta di Fede: da vicino era una sfera senza lineamenti):
    mascella e mento, zigomi, arcate, orbite scavate con gli occhi scuri dentro, naso con il dorso e
    le ali, bocca incisa con le labbra, sopracciglia, orecchie."""
    s, t = sk.s, sk.testa
    m = 0.85 if donna else 1.0  # mascella e mento più delicati
    p.add(Elli((0, 0.03 * s, t - 0.055 * s), (0.062 * s * m, 0.066 * s, 0.05 * s), "pelle", 1, k=0.03))
    p.add(Elli((0, 0.074 * s, t - 0.083 * s), (0.03 * s * m, 0.026 * s, 0.022 * s), "pelle", 1, k=0.02))
    for lato in (1, -1):
        p.add(Elli((0.046 * s * lato, 0.07 * s, t - 0.008 * s), (0.026 * s, 0.022 * s, 0.02 * s), "pelle", 1, k=0.015))
    p.add(Elli((0, 0.077 * s, t + 0.03 * s), (0.056 * s, 0.024 * s, 0.014 * s * m), "pelle", 1, k=0.02))
    for lato in (1, -1):
        p.add(Scava((0.031 * s * lato, 0.094 * s, t + 0.012 * s), (0.019 * s, 0.016 * s, 0.012 * s), "pelle", 1, k=0.01))
    for lato in (1, -1):
        p.add(Elli((0.031 * s * lato, 0.079 * s, t + 0.011 * s), (0.0125 * s, 0.012 * s, 0.009 * s), "occhi", 1, k=0.003))
        p.add(Elli((0.031 * s * lato, 0.094 * s, t + 0.029 * s), (0.019 * s, 0.006 * s, 0.0045 * s), "capelli", 1, k=0.004))
        p.add(Elli((0.079 * s * lato, -0.005 * s, t), (0.011 * s, 0.022 * s, 0.03 * s), "pelle", 1, k=0.012))
        p.add(Elli((0.012 * s * lato, 0.1 * s, t - 0.026 * s), (0.01 * s, 0.01 * s, 0.008 * s), "pelle", 1, k=0.006))  # ali del naso
    p.add(Cono((0, 0.094 * s, t + 0.016 * s), (0, 0.113 * s, t - 0.022 * s), 0.009 * s, 0.014 * s, "pelle", 1, k=0.01))
    p.add(Elli((0, 0.088 * s, t - 0.047 * s), (0.022 * s, 0.013 * s, 0.011 * s), "pelle", 1, k=0.008))  # labbra
    p.add(Scava((0, 0.1 * s, t - 0.047 * s), (0.02 * s, 0.008 * s, 0.0025 * s), "pelle", 1, k=0.004))  # bocca


def capelli(p, sk, stile):
    """Capelli sopra la testa e, secondo lo stile, giù sulle spalle o raccolti."""
    s, t = sk.s, sk.testa
    # La calotta lascia libere fronte e tempie: l'attaccatura è netta sopra le sopracciglia.
    p.add(Elli((0, -0.026 * s, t + 0.036 * s), (0.084 * s, 0.094 * s, 0.092 * s), "capelli", 1, k=0.015))
    if stile in ("lunghi", "sciolti"):
        p.add(Elli((0, -0.05 * s, t - 0.08 * s), (0.09 * s, 0.06 * s, 0.13 * s), "capelli", 1, k=0.04))
    if stile == "sciolti":  # fino a metà schiena
        p.add(Elli((0, -0.08 * s, 1.37 * s), (0.085 * s, 0.05 * s, 0.13 * s), "capelli", 0, k=0.045))
    if stile == "treccia":
        p.add(Elli((0, -0.06 * s, t - 0.05 * s), (0.075 * s, 0.05 * s, 0.07 * s), "capelli", 1, k=0.03))
        for k in range(6):
            z = t - 0.11 * s - k * 0.055 * s
            p.add(Elli((0.004 * s * (1 if k % 2 else -1), -0.105 * s - 0.004 * s * k, z), (0.026 * s, 0.022 * s, 0.032 * s), "capelli", 1 if k < 2 else 0, k=0.01))
    if stile == "crocchia":
        p.add(Elli((0, -0.1 * s, t + 0.0), (0.05 * s, 0.045 * s, 0.05 * s), "capelli", 1, k=0.02))
    if stile == "corti":
        p.add(Elli((0, -0.04 * s, t - 0.04 * s), (0.08 * s, 0.07 * s, 0.07 * s), "capelli", 1, k=0.03))


def barba(p, sk, lunga):
    s, t = sk.s, sk.testa
    p.add(Elli((0, 0.062 * s, t - 0.078 * s), (0.056 * s, 0.04 * s, 0.045 * s if not lunga else 0.07 * s), "capelli", 1, k=0.02))
    for lato in (1, -1):
        p.add(Elli((0.055 * s * lato, 0.04 * s, t - 0.045 * s), (0.016 * s, 0.03 * s, 0.035 * s), "capelli", 1, k=0.012))  # basette
    p.add(Elli((0, 0.098 * s, t - 0.036 * s), (0.03 * s, 0.01 * s, 0.007 * s), "capelli", 1, k=0.006))  # baffi


def gonna(p, sk, orlo, largo):
    """La tunica sotto la cintura: si allarga verso l'orlo (al ginocchio o al polpaccio)."""
    s = sk.s
    p.add(Cono((0, 0, 1.0 * s), (0, 0.0, orlo), 0.165 * s, largo * s, "veste", 0, k=0.03))


def mantello(p, sk, lungo, pelle):
    """Mantello di lana o pelle sulle spalle, sulla schiena."""
    s = sk.s
    tinta = "mantello"
    p.add(Elli((0, -0.07 * s, 1.36 * s), (0.215 * s, 0.11 * s, 0.09 * s), tinta, 0, k=0.03))
    if lungo:
        p.add(Elli((0, -0.11 * s, 1.0 * s), (0.2 * s, 0.05 * s, 0.38 * s), tinta, 0, k=0.04))
    if pelle:  # una pelle a tracolla: scende dalla spalla sinistra e si annoda sul fianco destro
        p.add(Cono((-0.12 * s, 0.035 * s, 1.43 * s), (0.11 * s, 0.1 * s, 1.17 * s), 0.035 * s, 0.03 * s, tinta, 0, k=0.02))
        p.add(Elli((0.12 * s, 0.1 * s, 1.15 * s), (0.03 * s, 0.022 * s, 0.03 * s), tinta, 0, k=0.012))


# Le sei persone (proposta di Claude, da guardare con Fede): stile dei capelli, barba, mantello.
PERSONE = {
    "uomo_1": {"donna": False, "capelli": "lunghi", "barba": "corta", "mantello": None, "maniche": 0.5},
    "uomo_2": {"donna": False, "capelli": "corti", "barba": None, "mantello": "pelle", "maniche": 0.45},
    "uomo_3": {"donna": False, "capelli": "crocchia", "barba": "lunga", "mantello": "lungo", "maniche": 0.6},
    "donna_1": {"donna": True, "capelli": "treccia", "barba": None, "mantello": None, "maniche": 0.55},
    "donna_2": {"donna": True, "capelli": "crocchia", "barba": None, "mantello": "lungo", "maniche": 0.6},
    "donna_3": {"donna": True, "capelli": "sciolti", "barba": None, "mantello": None, "maniche": 0.5},
}
SCALA_DONNA = 0.93

# Epoca 2, età del Bronzo e del Ferro (27/11/2026, proposta di Claude: `docs/epoca2-proposte.md` § 3):
# uomini con la tunica al ginocchio, la cintura con la placca di bronzo, il mantello fermato da una
# fibula, le fasce alle gambe, qualcuno con il berretto di feltro; donne con la veste lunga alla
# caviglia, la cintura con le placchette, bracciali e collana, uno scialle. Il bronzo sul corpo ha la
# classe 7 (negli attrezzi è la selce): lo shader lo colora e lo fa lucido.
PERSONE_2 = {
    "uomo_1": {"donna": False, "capelli": "lunghi", "barba": "corta", "mantello": "lungo", "maniche": 0.5, "fibula": True, "fasce": True, "berretto": False},
    "uomo_2": {"donna": False, "capelli": "corti", "barba": None, "mantello": None, "maniche": 0.45, "fibula": False, "fasce": True, "berretto": True},
    "uomo_3": {"donna": False, "capelli": "crocchia", "barba": "lunga", "mantello": "lungo", "maniche": 0.6, "fibula": True, "fasce": False, "berretto": False},
    "donna_1": {"donna": True, "capelli": "treccia", "barba": None, "mantello": None, "maniche": 0.55, "bracciali": True, "collana": True},
    "donna_2": {"donna": True, "capelli": "crocchia", "barba": None, "mantello": "lungo", "maniche": 0.6, "fibula": True, "collana": True},
    "donna_3": {"donna": True, "capelli": "sciolti", "barba": None, "mantello": None, "maniche": 0.5, "bracciali": True},
}


def ornamenti(p, sk, d):
    """Bronzi e lane dell'epoca 2: placca della cintura, fibula, bracciali, collana, berretto."""
    s = sk.s
    donna = d["donna"]
    if donna:
        for x in (-0.07, 0.0, 0.07):
            p.add(Elli((x * s, 0.112 * s, 1.01 * s), (0.022 * s, 0.01 * s, 0.018 * s), "selce", 0, k=0.004))
    else:
        p.add(Elli((0, 0.116 * s, 1.01 * s), (0.05 * s, 0.012 * s, 0.03 * s), "selce", 0, k=0.004))
    if d.get("fibula"):
        p.add(Elli((0.11 * s, 0.085 * s, 1.37 * s), (0.026 * s, 0.014 * s, 0.018 * s), "selce", 0, k=0.004))
    if d.get("bracciali"):
        for lato, parte in ((-1, PARTI["braccio_sx"]), (1, PARTI["braccio_dx"])):
            px, py, pz = sk.polso
            gx, gy, gz = sk.gomito
            a = (lato * (px + (gx - px) * 0.12), py + (gy - py) * 0.12, pz + (gz - pz) * 0.12)
            b = (lato * (px + (gx - px) * 0.3), py + (gy - py) * 0.3, pz + (gz - pz) * 0.3)
            p.add(Cono(a, b, 0.041 * s, 0.045 * s, "selce", parte, k=0.004))
    if d.get("collana"):
        for k in range(7):
            ang = math.radians(-60 + k * 20)
            p.add(Elli((0.072 * s * math.sin(ang), 0.06 * s * math.cos(ang) + 0.02 * s, (1.405 - 0.02 * math.cos(ang)) * s), (0.013 * s,) * 3, "selce", 0, k=0.003))
    if d.get("berretto"):
        p.add(Elli((0, -0.005 * s, sk.testa + 0.07 * s), (0.098 * s, 0.108 * s, 0.06 * s), "mantello", 1, k=0.01))


def persona(nome, epoca=1):
    d = PERSONE[nome] if epoca == 1 else PERSONE_2[nome]
    donna = d["donna"]
    sk = Scheletro(SCALA_DONNA if donna else 1.0)
    p = corpo_base(sk, donna)
    if epoca == 1:
        gonna(p, sk, 0.24 * sk.s if donna else 0.52 * sk.s, 0.205 if donna else 0.195)
    else:
        gonna(p, sk, 0.09 * sk.s if donna else 0.5 * sk.s, 0.22 if donna else 0.19)
    for lato, parte in ((-1, PARTI["braccio_sx"]), (1, PARTI["braccio_dx"])):
        braccio(p, sk, lato, parte, manica=d["maniche"])
    for lato, parte in ((-1, PARTI["gamba_sx"]), (1, PARTI["gamba_dx"])):
        gamba(p, sk, lato, parte, polpaccio_coperto=bool(d.get("fasce")))
    capelli(p, sk, d["capelli"])
    if d["barba"]:
        barba(p, sk, d["barba"] == "lunga")
    if d["mantello"]:
        mantello(p, sk, d["mantello"] == "lungo", d["mantello"] == "pelle")
    if epoca >= 2:
        ornamenti(p, sk, d)
    return p, sk


# ---------- parti, classi, pesi ----------
def _lungo_polilinea(punti, q):
    """Frazione (0–1) della lunghezza di una polilinea al punto più vicino a ciascun q."""
    punti = [np.array(x, float) for x in punti]
    lunghezze = [np.linalg.norm(b - a) for a, b in zip(punti, punti[1:])]
    totale = sum(lunghezze)
    migliore_d = np.full(len(q), np.inf)
    migliore_t = np.zeros(len(q))
    fatto = 0.0
    for (a, b), l in zip(zip(punti, punti[1:]), lunghezze):
        ba = b - a
        t = np.clip(((q - a) @ ba) / (ba @ ba), 0, 1)
        d = np.linalg.norm(q - (a + t[:, None] * ba), axis=1)
        sel = d < migliore_d
        migliore_d[sel] = d[sel]
        migliore_t[sel] = (fatto + t[sel] * l) / totale
        fatto += l
    return migliore_t


def parti_e_classi(p, sk, co):
    # I volumi che scavano (orbite, bocca) non danno colore: la parete dello scavo prende quello
    # del volume pieno più vicino (la pelle intorno, l'occhio dentro).
    dist = np.stack([v.dist(co) if not getattr(v, "sottrai", False) else np.full(len(co), 1e9) for v in p.volumi], axis=1)
    vicino = np.argmin(dist, axis=1)
    parte = np.array([p.volumi[i].parte for i in vicino])
    classe = np.array([CLASSI[p.volumi[i].tinta] for i in vicino])
    peso = np.zeros(len(co))
    for lato, k in ((-1, PARTI["braccio_sx"]), (1, PARTI["braccio_dx"])):
        sel = parte == k
        m = lambda q: (q[0] * lato, q[1], q[2])
        peso[sel] = _lungo_polilinea([m(sk.spalla), m(sk.gomito), m(sk.polso), m(sk.punta)], co[sel])
    for k in (PARTI["gamba_sx"], PARTI["gamba_dx"]):
        sel = parte == k
        peso[sel] = np.clip((sk.anca - co[sel, 2]) / sk.anca, 0, 1)
    sel = parte == PARTI["testa"]
    peso[sel] = np.clip((co[sel, 2] - sk.collo) / (sk.testa + 0.12 * sk.s - sk.collo), 0, 1)
    return parte, classe, peso


def prepara(ob, p, sk, tile):
    """UV della grana (cilindrica attorno al corpo e a ogni arto) e parti nella seconda UV."""
    me = ob.data
    me.uv_layers.new(name="UVMap")
    me.uv_layers.new(name="Parti")
    me.uv_layers["UVMap"].active_render = True
    me.uv_layers.active = me.uv_layers["UVMap"]
    co = np.array([v.co[:] for v in me.vertices])
    parte, classe, peso = parti_e_classi(p, sk, co)
    uv = me.uv_layers["UVMap"].data
    uv2 = me.uv_layers["Parti"].data
    for li, lo in enumerate(me.loops):
        vi = lo.vertex_index
        x, y, z = co[vi]
        k = int(parte[vi])
        cx = {2: -sk.spalla[0], 3: sk.spalla[0], 4: -sk.x_anca, 5: sk.x_anca}.get(k, 0.0)
        a = math.atan2(x - cx, y)  # la cucitura della grana sta dietro, non sulla spalla
        r = max(0.03, math.hypot(x - cx, y))
        uv[li].uv = (a * r / tile, z / tile)
        uv2[li].uv = (k + classe[vi] / 10.0 + 0.05, float(peso[vi]))
    return parte, classe


def grigio(ob):
    """I colori dei vertici restano la sola occlusione (grigia): il colore lo sceglie lo shader."""
    attr = ob.data.color_attributes["Occlusione"]
    for d in attr.data:
        o = d.color[0]
        d.color = (o, o, o, 1.0)


# ---------- attrezzi ----------
# Ogni attrezzo nella mano destra, girato di `riposo` gradi sopra l'orizzontale in avanti: con il
# braccio nella posa "tenere" dello shader (spalla + gomito = `tieni` radianti) sta come deve.
TENERE = {"zappa": 1.2, "ascia": 1.2, "lancia": 1.2, "bastone": 0.5, "cesto": 0.15}
VOLUTO = {"zappa": 40.0, "ascia": 85.0, "lancia": 80.0, "bastone": -80.0}  # gradi, nella posa "tenere"


def attrezzo(nome, sk):
    s = sk.s
    h = np.array(sk.mano, float)
    p = animali.Specie()
    k6 = PARTI["attrezzo"]
    if nome == "cesto":
        c = h + np.array([0.0, 0.02, -0.17]) * s
        p.add(Cono(c + np.array([0, 0, -0.1]) * s, c + np.array([0, 0, 0.08]) * s, 0.12 * s, 0.16 * s, "vimini", k6, k=0.02))
        p.add(Cono(c + np.array([-0.13, 0, 0.08]) * s, h + np.array([0, 0, 0.02]) * s, 0.012 * s, 0.012 * s, "vimini", k6, k=0.01))
        p.add(Cono(c + np.array([0.13, 0, 0.08]) * s, h + np.array([0, 0, 0.02]) * s, 0.012 * s, 0.012 * s, "vimini", k6, k=0.01))
        return p
    a = math.radians(VOLUTO[nome]) - TENERE[nome]
    d = np.array([0.0, math.cos(a), math.sin(a)])  # avanti e in alto, nel piano y-z
    su = np.array([0.0, -math.sin(a), math.cos(a)])  # perpendicolare al manico, verso l'alto
    misure = {"zappa": (0.18, 0.95), "ascia": (0.1, 0.55), "lancia": (0.8, 1.2), "bastone": (0.25, 0.9)}
    dietro, avanti = misure[nome]
    calcio, testa = h - d * dietro * s, h + d * avanti * s
    r = 0.016 if nome != "lancia" else 0.013
    p.add(Cono(calcio, testa, r * s, r * 0.9 * s, "legno", k6, k=0.005))
    if nome == "zappa":  # lama di corno o di pietra, di traverso in fondo al manico
        p.add(Cono(testa - su * 0.02 * s, testa - su * 0.2 * s - d * 0.05 * s, 0.03 * s, 0.018 * s, "selce", k6, k=0.01))
    if nome == "ascia":  # testa di pietra levigata, legata al manico
        p.add(Elli(testa - d * 0.04 * s, (0.03 * s, 0.03 * s, 0.03 * s), "legno", k6, k=0.01))
        p.add(Cono(testa - d * 0.04 * s, testa - d * 0.04 * s - su * 0.13 * s, 0.022 * s, 0.035 * s, "selce", k6, k=0.008))
    if nome == "lancia":  # punta di selce
        p.add(Cono(testa, testa + d * 0.14 * s, 0.022 * s, 0.003 * s, "selce", k6, k=0.006))
    return p


def prepara_attrezzo(ob, p, tile):
    me = ob.data
    me.uv_layers.new(name="UVMap")
    me.uv_layers.new(name="Parti")
    me.uv_layers["UVMap"].active_render = True
    co = np.array([v.co[:] for v in me.vertices])
    dist = np.stack([v.dist(co) for v in p.volumi], axis=1)
    vicino = np.argmin(dist, axis=1)
    classe = np.array([CLASSI[p.volumi[i].tinta] for i in vicino])
    uv = me.uv_layers["UVMap"].data
    uv2 = me.uv_layers["Parti"].data
    for li, lo in enumerate(me.loops):
        vi = lo.vertex_index
        x, y, z = co[vi]
        uv[li].uv = ((x + y) / tile, z / tile)
        uv2[li].uv = (PARTI["attrezzo"] + classe[vi] / 10.0 + 0.05, 1.0)


def g(v):
    """Da Blender a Godot: (x, y, z) → (x, z, -y)."""
    return [float(v[0]), float(v[2]), float(-v[1])]


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(USCITA, exist_ok=True)
    bpy.context.scene.world = bpy.data.worlds.new("Mondo")
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    mat = base.materiale("persona", "lana", ruvidezza=0.9)
    dati = {}
    # "e2" come secondo argomento: solo le persone dell'epoca 2 (persona_<nome>_e2[_leggero]).
    solo_e2 = len(sys.argv) > 2 and sys.argv[2] == "e2"
    lista = [(n, 2) for n in PERSONE_2] if solo_e2 else [(n, 1) for n in PERSONE] + [(n, 2) for n in PERSONE_2]
    for nome, epoca in lista:
        p, sk = persona(nome, epoca)
        verts, facce = superficie(p, 0.0055)
        for livello, facce_volute in (("", FACCE_COMPLETO), ("_leggero", FACCE_LEGGERO)):
            n = f"persona_{nome}{'_e2' if epoca == 2 else ''}{livello}"
            ob = oggetto(n, verts, facce, facce_volute, mat, sopra=sk.collo if livello == "" else None)
            prepara(ob, p, sk, 0.35)
            base.cuoci_occlusione(ob, 0.55)
            grigio(ob)
            ob.data.color_attributes.active_color = ob.data.color_attributes["Occlusione"]
            esporta(ob, os.path.join(USCITA, n + ".glb"))
            dm = ob.dimensions
            print(f"{n}: {dm.x:.2f} x {dm.y:.2f} x {dm.z:.2f} m, {len(ob.data.polygons)} facce")
            bpy.data.objects.remove(ob, do_unlink=True)
    if solo_e2:
        return
    for sesso, scala in (("uomo", 1.0), ("donna", SCALA_DONNA)):
        sk = Scheletro(scala)
        dati[sesso] = {
            "anca": sk.anca * 1.0, "x_anca": sk.x_anca, "ginocchio": sk.ginocchio,
            "spalla": g(sk.spalla), "gomito": g(sk.gomito), "collo": sk.collo,
            "peso_gomito": float(_lungo_polilinea([sk.spalla, sk.gomito, sk.polso, sk.punta], np.array([sk.gomito], float))[0]),
            "peso_ginocchio": float((sk.anca - sk.ginocchio) / sk.anca),
            "passo": 1.35 * scala,  # metri per ciclo (due passi)
        }
        for att in TENERE:
            p = attrezzo(att, sk)
            verts, facce = superficie(p, 0.006)
            n = f"attrezzo_{att}_{sesso}"
            ob = oggetto(n, verts, facce, 220 if att != "cesto" else 300, mat)
            prepara_attrezzo(ob, p, 0.35)
            base.cuoci_occlusione(ob, 0.6)
            grigio(ob)
            ob.data.color_attributes.active_color = ob.data.color_attributes["Occlusione"]
            esporta(ob, os.path.join(USCITA, n + ".glb"))
            print(f"{n}: {len(ob.data.polygons)} facce")
            bpy.data.objects.remove(ob, do_unlink=True)
    dati["tenere"] = TENERE
    with open(os.path.join(USCITA, "persone.json"), "w") as f:
        json.dump(dati, f, indent=1)


if __name__ == "__main__":
    main()
