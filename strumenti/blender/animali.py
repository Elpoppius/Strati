"""Animali del pascolo, terza versione (26/11/2026, richiesta di Fede: i modelli di prima erano
"grossolani e molto poligonali"; definizione simile a quella degli alberi).

Ogni animale è un corpo unico e continuo: lo descrive un campo di distanza fatto di volumi
(ellissoidi e coni arrotondati per tronco, collo, testa, zampe, corna, orecchie, coda) che si
fondono morbidamente, così spalle, anche, ginocchia e garretti si raccordano senza giunture.
La superficie si estrae dal campo (marching cubes, scikit-image), poi si semplifica in due
livelli, come gli alberi:
  - completo (circa 1800-2600 facce) per le viste vicine;
  - leggero (circa 260 facce) per la media distanza.

Il manto sta nei colori dei vertici (moltiplicati per l'occlusione cotta): tre manti per specie.
La texture (pelo o lana, quasi grigia) dà solo la grana.

Parti per l'animazione (seconda mappa UV, "Parti"): u = parte, v = peso lungo la parte.
  0 corpo · 1 collo e testa (peso dalla base del collo al muso) · 2 zampa anteriore sinistra ·
  3 anteriore destra · 4 posteriore sinistra · 5 posteriore destra (peso dalla spalla o
  dall'anca allo zoccolo) · 6 orecchie · 7 coda (peso dalla radice alla punta).
Il muso guarda verso +y in Blender (verso -z in Godot). Accanto ai modelli si scrive
`animali.json` con il perno del collo e il passo di ogni specie, letti dallo shader.

Uso:  blender-py strumenti/blender/animali.py gioco/asset/villaggio
(prima: python3 strumenti/blender/texture_procedurali.py gioco/asset/texture animali)
"""
import json
import math
import os
import random
import sys

import numpy as np
from skimage import measure

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prova_stile_verosimile as base  # noqa: E402  (legge la cartella d'uscita da sys.argv[1])
import bpy  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402

USCITA = base.USCITA
FACCE_COMPLETO = {"pecora": 3200, "capra": 3000, "maiale": 2600, "bue": 3600}
FACCE_LEGGERO = 260
MEDIA_TEXTURE = 1.0  # la grana la normalizza lo shader (media_grana): qui i colori veri del manto


# ---------- volumi del campo di distanza ----------
class Cono:
    """Cono arrotondato da `a` a `b`, raggio da r0 a r1."""

    def __init__(self, a, b, r0, r1, tinta, parte=0, k=0.04):
        self.a, self.b = np.array(a, float), np.array(b, float)
        self.r0, self.r1, self.tinta, self.parte, self.k = r0, r1, tinta, parte, k

    def dist(self, p):
        ba = self.b - self.a
        t = np.clip(((p - self.a) @ ba) / (ba @ ba), 0.0, 1.0)
        q = self.a + t[:, None] * ba
        return np.linalg.norm(p - q, axis=1) - (self.r0 + (self.r1 - self.r0) * t)

    def limiti(self):
        r = max(self.r0, self.r1)
        return np.minimum(self.a, self.b) - r, np.maximum(self.a, self.b) + r


class Disco:
    """Cilindro a facce piatte da `a` a `b` (il grugno del maiale: un disco tagliato netto)."""

    def __init__(self, a, b, r, tinta, parte=0, k=0.01):
        self.a, self.b = np.array(a, float), np.array(b, float)
        self.r, self.tinta, self.parte, self.k = r, tinta, parte, k

    def dist(self, p):
        ba = self.b - self.a
        l = np.linalg.norm(ba)
        asse = ba / l
        t = (p - self.a) @ asse
        q = p - self.a - t[:, None] * asse
        dx = np.linalg.norm(q, axis=1) - self.r
        dy = np.abs(t - l / 2) - l / 2
        fuori = np.sqrt(np.maximum(dx, 0) ** 2 + np.maximum(dy, 0) ** 2)
        return np.minimum(np.maximum(dx, dy), 0) + fuori

    def limiti(self):
        return np.minimum(self.a, self.b) - self.r, np.maximum(self.a, self.b) + self.r


class Elli:
    """Ellissoide di centro `c` e semiassi `r`."""

    def __init__(self, c, r, tinta, parte=0, k=0.04):
        self.c, self.r = np.array(c, float), np.array(r, float)
        self.tinta, self.parte, self.k = tinta, parte, k

    def dist(self, p):
        q = (p - self.c) / self.r
        k0 = np.linalg.norm(q, axis=1)
        k1 = np.linalg.norm(q / self.r, axis=1) + 1e-9
        return k0 * (k0 - 1.0) / k1

    def limiti(self):
        return self.c - self.r, self.c + self.r


def unione_morbida(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


def campo(volumi, p):
    d = volumi[0].dist(p)
    for v in volumi[1:]:
        d = unione_morbida(d, v.dist(p), v.k)
    # Taglio al suolo: gli zoccoli poggiano piatti.
    return np.maximum(d, -p[:, 2])


# ---------- le quattro specie ----------
class Specie:
    def __init__(self):
        self.volumi = []
        self.zampe = {}  # parte -> quota della spalla o dell'anca
        self.centri = {}  # parte -> (x, y) della zampa, per le UV cilindriche
        self.collo = None  # (base, punta del muso)
        self.coda = None  # (radice, punta)

    def add(self, v):
        self.volumi.append(v)
        return v

    def zampa(self, parte, x, y, spalla, ginocchio, r, avanti, tinta="zampa"):
        """Zampa in tre tratti (braccio, stinco, zoccolo) con il ginocchio in avanti per le
        anteriori e il garretto all'indietro per le posteriori."""
        self.zampe[parte] = spalla
        self.centri[parte] = (x, y)
        g = (x, y + (0.015 if avanti else -0.07 * spalla), ginocchio)
        nocca = (x, y + (0.02 if avanti else 0.0), spalla * 0.09)
        self.add(Cono((x, y, spalla), g, r * 1.9, r * 1.05, "pelo", parte, k=0.05 * spalla))
        self.add(Cono(g, nocca, r * 1.0, r * 0.8, tinta, parte, k=0.02))
        self.add(Cono(nocca, (x, y + 0.02 * spalla, 0.0), r * 0.85, r * 1.0, "zoccolo", parte, k=0.01))

    def corno(self, punti, r0, r1, k=0.01):
        n = len(punti) - 1
        for i in range(n):
            t0, t1 = i / n, (i + 1) / n
            self.add(Cono(punti[i], punti[i + 1], r0 + (r1 - r0) * t0, r0 + (r1 - r0) * t1, "corno", 1, k=k))


def pecora():
    s = Specie()
    s.add(Elli((0, -0.02, 0.6), (0.25, 0.5, 0.24), "pelo", k=0.08))
    s.add(Elli((0, -0.3, 0.62), (0.24, 0.24, 0.23), "pelo", k=0.08))
    s.add(Elli((0, 0.3, 0.6), (0.22, 0.22, 0.24), "pelo", k=0.08))
    rnd = random.Random(40)
    for _ in range(80):  # bioccoli di lana sulla schiena e sui fianchi
        a = rnd.uniform(-math.pi * 0.95, math.pi * 0.95) + math.pi / 2
        y = rnd.uniform(-0.48, 0.42)
        x, z = 0.24 * math.cos(a), 0.6 + 0.23 * math.sin(a)
        r = rnd.uniform(0.045, 0.075)
        s.add(Elli((x, y, z), (r, r, r * 0.85), "pelo", k=0.03))
    s.add(Cono((0, 0.36, 0.66), (0, 0.52, 0.82), 0.13, 0.085, "pelo", 1, k=0.06))
    s.add(Cono((0, 0.5, 0.87), (0, 0.69, 0.76), 0.085, 0.048, "muso", 1, k=0.04))
    s.add(Elli((0, 0.49, 0.93), (0.085, 0.08, 0.06), "pelo", 1, k=0.03))  # ciuffo sulla fronte
    s.add(Elli((0, 0.7, 0.755), (0.042, 0.03, 0.036), "naso", 1, k=0.015))
    for sx in (-1, 1):
        s.add(Elli((sx * 0.066, 0.58, 0.86), (0.016, 0.016, 0.016), "occhio", 1, k=0.004))
        s.add(Elli((sx * 0.13, 0.52, 0.86), (0.075, 0.03, 0.022), "muso", 6, k=0.015))
    s.zampa(2, -0.12, 0.3, 0.52, 0.27, 0.027, True)
    s.zampa(3, 0.12, 0.3, 0.52, 0.27, 0.027, True)
    s.zampa(4, -0.12, -0.33, 0.52, 0.29, 0.027, False)
    s.zampa(5, 0.12, -0.33, 0.52, 0.29, 0.027, False)
    s.add(Cono((0, -0.5, 0.64), (0, -0.6, 0.42), 0.06, 0.04, "pelo", 7, k=0.04))
    s.collo = ((0, 0.34, 0.66), (0, 0.72, 0.76))
    s.coda = ((0, -0.5, 0.64), (0, -0.6, 0.42))
    s.passo = 0.6
    s.bruca = 1.1
    return s


def capra():
    s = Specie()
    s.add(Elli((0, 0.0, 0.68), (0.165, 0.42, 0.18), "pelo", k=0.06))
    s.add(Elli((0, 0.18, 0.66), (0.165, 0.2, 0.21), "pelo", k=0.06))
    s.add(Elli((0, -0.26, 0.7), (0.15, 0.17, 0.16), "pelo", k=0.06))
    s.add(Elli((0, 0.02, 0.57), (0.13, 0.3, 0.1), "pancia", k=0.05))
    s.add(Cono((0, 0.28, 0.74), (0, 0.43, 0.96), 0.09, 0.062, "pelo", 1, k=0.05))
    s.add(Cono((0, 0.42, 1.0), (0, 0.61, 0.9), 0.072, 0.038, "muso", 1, k=0.04))
    s.add(Elli((0, 0.62, 0.89), (0.034, 0.028, 0.03), "naso", 1, k=0.012))
    s.add(Cono((0, 0.55, 0.87), (0, 0.53, 0.75), 0.03, 0.008, "barba", 1, k=0.012))
    for sx in (-1, 1):
        s.corno([(sx * 0.035, 0.46, 1.06), (sx * 0.06, 0.4, 1.17), (sx * 0.08, 0.3, 1.22), (sx * 0.09, 0.22, 1.18)], 0.024, 0.006)
        s.add(Elli((sx * 0.055, 0.5, 1.0), (0.014, 0.014, 0.014), "occhio", 1, k=0.004))
        s.add(Elli((sx * 0.11, 0.44, 0.99), (0.075, 0.022, 0.028), "muso", 6, k=0.012))
    s.zampa(2, -0.09, 0.24, 0.6, 0.3, 0.022, True)
    s.zampa(3, 0.09, 0.24, 0.6, 0.3, 0.022, True)
    s.zampa(4, -0.09, -0.27, 0.62, 0.32, 0.022, False)
    s.zampa(5, 0.09, -0.27, 0.62, 0.32, 0.022, False)
    s.add(Cono((0, -0.4, 0.78), (0, -0.46, 0.9), 0.03, 0.012, "pelo", 7, k=0.02))
    s.collo = ((0, 0.27, 0.74), (0, 0.63, 0.89))
    s.coda = ((0, -0.4, 0.78), (0, -0.46, 0.9))
    s.passo = 0.65
    s.bruca = 1.0
    return s


def maiale():
    """Maiale del Neolitico, vicino al cinghiale (rifatto il 26/11/2026: Fede, "sembra un tapiro").
    Corpo corto e alto davanti, spalle robuste e prosciutti pieni, pancia profonda; testa grande a
    cuneo attaccata alle spalle quasi senza collo, con le guance piene; grugno a disco largo e
    piatto; orecchie grandi e dritte; zampe corte e sottili; cresta di setole scure sul dorso."""
    s = Specie()
    s.add(Elli((0, -0.04, 0.44), (0.19, 0.36, 0.19), "pelo", k=0.07))
    s.add(Elli((0, 0.15, 0.48), (0.2, 0.2, 0.23), "pelo", k=0.07))  # spalle alte
    s.add(Elli((0, -0.27, 0.43), (0.19, 0.17, 0.19), "pelo", k=0.07))  # prosciutti
    s.add(Elli((0, 0.0, 0.32), (0.15, 0.28, 0.1), "pancia", k=0.06))
    s.add(Elli((0, 0.08, 0.67), (0.05, 0.28, 0.06), "scuro", k=0.05))  # cresta
    # Testa a cuneo: alta dietro (guance e mascella), la fronte scende dritta fino al grugno, la
    # mascella resta quasi orizzontale; il grugno è un disco tagliato netto.
    s.add(Elli((0, 0.31, 0.42), (0.15, 0.13, 0.14), "pelo", 1, k=0.07))
    s.add(Cono((0, 0.3, 0.5), (0, 0.55, 0.375), 0.14, 0.072, "pelo", 1, k=0.05))
    s.add(Elli((0, 0.42, 0.34), (0.1, 0.15, 0.065), "pelo", 1, k=0.05))  # mascella
    s.add(Disco((0, 0.545, 0.36), (0, 0.6, 0.352), 0.072, "naso", 1, k=0.01))
    for sx in (-1, 1):
        s.add(Elli((sx * 0.08, 0.41, 0.47), (0.013, 0.013, 0.013), "occhio", 1, k=0.004))
        # Orecchie grandi e dritte, lamine appena rivolte in avanti.
        s.add(Elli((sx * 0.09, 0.36, 0.61), (0.06, 0.024, 0.095), "scuro", 6, k=0.012))
    s.zampa(2, -0.11, 0.19, 0.36, 0.18, 0.024, True)
    s.zampa(3, 0.11, 0.19, 0.36, 0.18, 0.024, True)
    s.zampa(4, -0.11, -0.29, 0.36, 0.19, 0.024, False)
    s.zampa(5, 0.11, -0.29, 0.36, 0.19, 0.024, False)
    s.add(Cono((0, -0.43, 0.52), (0.03, -0.49, 0.38), 0.014, 0.008, "pelo", 7, k=0.012))
    s.add(Elli((0.03, -0.495, 0.36), (0.025, 0.025, 0.04), "scuro", 7, k=0.01))  # ciuffo
    s.collo = ((0, 0.28, 0.48), (0, 0.6, 0.35))
    s.coda = ((0, -0.43, 0.52), (0.03, -0.5, 0.34))
    s.passo = 0.42
    s.bruca = 0.35  # la testa è già bassa: grufola appena
    return s


def bue():
    s = Specie()
    s.add(Elli((0, 0.0, 1.05), (0.36, 0.85, 0.4), "pelo", k=0.12))
    s.add(Elli((0, 0.45, 1.02), (0.36, 0.42, 0.44), "pelo", k=0.12))
    s.add(Elli((0, -0.6, 1.08), (0.32, 0.35, 0.34), "pelo", k=0.12))
    s.add(Elli((0, 0.5, 1.32), (0.2, 0.3, 0.14), "pelo", k=0.1))  # gobba
    s.add(Elli((0, 0.0, 0.8), (0.27, 0.6, 0.16), "pancia", k=0.1))
    s.add(Elli((0, 0.86, 0.8), (0.07, 0.24, 0.24), "pelo", 1, k=0.08))  # giogaia
    s.add(Cono((0, 0.7, 1.12), (0, 1.02, 1.08), 0.3, 0.2, "pelo", 1, k=0.1))
    s.add(Cono((0, 1.05, 1.12), (0, 1.42, 0.86), 0.17, 0.11, "muso", 1, k=0.07))
    s.add(Elli((0, 1.45, 0.84), (0.12, 0.08, 0.1), "naso", 1, k=0.04))
    for sx in (-1, 1):
        s.corno([(sx * 0.12, 1.03, 1.2), (sx * 0.3, 1.05, 1.24), (sx * 0.4, 1.08, 1.38), (sx * 0.36, 1.06, 1.52)], 0.045, 0.01)
        s.add(Elli((sx * 0.15, 1.13, 1.07), (0.022, 0.022, 0.022), "occhio", 1, k=0.005))
        s.add(Elli((sx * 0.23, 1.02, 1.1), (0.1, 0.035, 0.05), "muso", 6, k=0.02))
    s.zampa(2, -0.22, 0.6, 0.95, 0.44, 0.052, True)
    s.zampa(3, 0.22, 0.6, 0.95, 0.44, 0.052, True)
    s.zampa(4, -0.22, -0.68, 0.95, 0.47, 0.052, False)
    s.zampa(5, 0.22, -0.68, 0.95, 0.47, 0.052, False)
    s.add(Cono((0, -0.93, 1.25), (0, -0.98, 0.5), 0.04, 0.022, "pelo", 7, k=0.04))
    s.add(Elli((0, -0.98, 0.44), (0.05, 0.05, 0.1), "scuro", 7, k=0.03))
    s.collo = ((0, 0.68, 1.12), (0, 1.47, 0.84))
    s.coda = ((0, -0.93, 1.25), (0, -0.98, 0.36))
    s.passo = 1.1
    s.bruca = 1.25
    return s


SPECIE = {"pecora": pecora, "capra": capra, "maiale": maiale, "bue": bue}

# ---------- manti (colori lineari, come arrivano a Godot) ----------
# Ogni manto dà un colore per tinta; "macchie" e "fascia" disegnano chiazze e cinture sul pelo.
MANTI = {
    "pecora": [
        {"pelo": (0.6, 0.55, 0.44), "muso": (0.05, 0.045, 0.04), "zampa": (0.06, 0.05, 0.045), "naso": (0.03, 0.025, 0.022)},
        {"pelo": (0.64, 0.58, 0.46), "muso": (0.46, 0.38, 0.29), "zampa": (0.4, 0.33, 0.26), "naso": (0.22, 0.16, 0.13)},
        {"pelo": (0.13, 0.085, 0.06), "muso": (0.05, 0.04, 0.035), "zampa": (0.06, 0.045, 0.035), "naso": (0.03, 0.025, 0.02)},
    ],
    "capra": [
        {"pelo": (0.24, 0.155, 0.09), "pancia": (0.46, 0.38, 0.28), "muso": (0.18, 0.12, 0.07), "zampa": (0.1, 0.07, 0.05), "barba": (0.08, 0.06, 0.045)},
        {"pelo": (0.035, 0.032, 0.03), "pancia": (0.07, 0.055, 0.045), "muso": (0.035, 0.03, 0.028), "zampa": (0.03, 0.028, 0.025), "barba": (0.03, 0.028, 0.025)},
        {"pelo": (0.6, 0.56, 0.48), "pancia": (0.62, 0.58, 0.5), "muso": (0.55, 0.5, 0.42), "zampa": (0.5, 0.46, 0.4), "barba": (0.5, 0.46, 0.4),
         "macchie": ((0.17, 0.1, 0.06), 6.0, 0.15)},
    ],
    "maiale": [
        {"pelo": (0.075, 0.05, 0.038), "pancia": (0.1, 0.07, 0.05), "scuro": (0.03, 0.025, 0.02), "naso": (0.13, 0.08, 0.07), "zampa": (0.04, 0.03, 0.025)},
        {"pelo": (0.16, 0.1, 0.06), "pancia": (0.21, 0.14, 0.09), "scuro": (0.07, 0.045, 0.03), "naso": (0.18, 0.11, 0.09), "zampa": (0.08, 0.05, 0.03)},
        {"pelo": (0.045, 0.04, 0.036), "pancia": (0.06, 0.05, 0.045), "scuro": (0.03, 0.026, 0.024), "naso": (0.12, 0.08, 0.07), "zampa": (0.035, 0.03, 0.028),
         "fascia": ((0.45, 0.4, 0.34), 0.2, 0.13)},
    ],
    "bue": [
        {"pelo": (0.19, 0.12, 0.07), "pancia": (0.27, 0.19, 0.12), "muso": (0.15, 0.095, 0.055), "naso": (0.05, 0.04, 0.035), "scuro": (0.06, 0.04, 0.03), "zampa": (0.15, 0.095, 0.06)},
        {"pelo": (0.4, 0.38, 0.34), "pancia": (0.48, 0.46, 0.42), "muso": (0.16, 0.15, 0.135), "naso": (0.03, 0.028, 0.026), "scuro": (0.04, 0.035, 0.03), "zampa": (0.14, 0.13, 0.12),
         "spalle": (0.2, 0.19, 0.17)},
        {"pelo": (0.09, 0.055, 0.035), "pancia": (0.13, 0.085, 0.055), "muso": (0.07, 0.045, 0.03), "naso": (0.03, 0.025, 0.02), "scuro": (0.03, 0.025, 0.02), "zampa": (0.05, 0.035, 0.025)},
    ],
}
FISSI = {"occhio": (0.012, 0.01, 0.009), "zoccolo": (0.035, 0.03, 0.026), "corno": (0.5, 0.44, 0.33)}


def rumore(p, scala, seme):
    """Rumore liscio deterministico (somma di onde), valori circa -1..1."""
    rnd = random.Random(seme)
    tot = np.zeros(len(p))
    for _ in range(5):
        d = np.array([rnd.uniform(-1, 1) for _ in range(3)])
        d /= np.linalg.norm(d)
        tot += np.sin((p @ d) * scala * rnd.uniform(0.7, 1.4) + rnd.uniform(0, 6.3))
    return tot / 2.2


def colori(sp, specie, manto, p):
    """Colore del manto per ogni punto: miscela morbida delle tinte dei volumi più vicini."""
    m = MANTI[specie][manto]
    dist = np.stack([v.dist(p) for v in sp.volumi], axis=1)
    pesi = np.exp(-(dist - dist.min(axis=1, keepdims=True)) / 0.012)
    tinte = []
    for v in sp.volumi:
        t = v.tinta
        if t == "corno":
            tinte.append(FISSI["corno"])
        elif t in FISSI:
            tinte.append(FISSI[t])
        else:
            tinte.append(m.get(t, m["pelo"]))
    tinte = np.array(tinte)
    col = (pesi @ tinte) / pesi.sum(axis=1, keepdims=True)
    pelo = np.array([1.0 if v.tinta in ("pelo", "pancia") else 0.0 for v in sp.volumi])
    sul_pelo = ((pesi @ pelo) / pesi.sum(axis=1))[:, None]
    if "macchie" in m:
        c2, scala, soglia = m["macchie"]
        n = rumore(p, scala, 7)
        k = np.clip((n - soglia) * 8, 0, 1)[:, None] * sul_pelo
        col = col * (1 - k) + np.array(c2) * k
    if "fascia" in m:
        c2, y0, mezza = m["fascia"]
        k = np.clip((mezza - np.abs(p[:, 1] - y0)) * 25, 0, 1)[:, None] * sul_pelo
        col = col * (1 - k) + np.array(c2) * k
    if "spalle" in m:
        # Manto grigio con spalle e collo più scuri.
        y_max = max(v.limiti()[1][1] for v in sp.volumi)
        k = np.clip((p[:, 1] / y_max - 0.15) * 2.2, 0, 1)[:, None] * sul_pelo * 0.8
        col = col * (1 - k) + np.array(m["spalle"]) * k
    # Corna più scure in punta, pelo un po' irregolare.
    corno = np.array([1.0 if v.tinta == "corno" else 0.0 for v in sp.volumi])
    sul_corno = ((pesi @ corno) / pesi.sum(axis=1))[:, None]
    if sul_corno.max() > 0:
        alto = np.clip((p[:, 2:3] - p[:, 2].max() * 0.82) / (p[:, 2].max() * 0.18), 0, 1)
        col = col * (1 - sul_corno * alto * 0.85)
    col = col * (1 + 0.08 * rumore(p, 9.0, 3)[:, None] * sul_pelo)
    dominante = [sp.volumi[i].tinta for i in np.argmin(dist, axis=1)]
    return np.clip(col / MEDIA_TEXTURE, 0, 1), sul_pelo[:, 0], dominante


def parti(sp, p):
    """Parte e peso di ogni punto, per l'animazione nello shader."""
    dist = np.stack([v.dist(p) for v in sp.volumi], axis=1)
    parte_vol = np.array([v.parte for v in sp.volumi])
    parte = parte_vol[np.argmin(dist, axis=1)]
    peso = np.zeros(len(p))
    for k, spalla in sp.zampe.items():
        sel = parte == k
        peso[sel] = np.clip((spalla - p[sel, 2]) / spalla, 0, 1)
    for k, (a, b) in ((1, sp.collo), (6, sp.collo), (7, sp.coda)):
        a, b = np.array(a), np.array(b)
        sel = parte == k
        ba = b - a
        peso[sel] = np.clip(((p[sel] - a) @ ba) / (ba @ ba), 0, 1)
    # Il corpo vicino all'attaccatura delle zampe si muove appena con loro? No: resta fermo,
    # il raccordo assorbe il movimento (peso 0 in cima alla zampa).
    return parte, peso


# ---------- superficie ----------
def superficie(sp, passo_griglia):
    lo = np.min([v.limiti()[0] for v in sp.volumi], axis=0) - 0.05
    hi = np.max([v.limiti()[1] for v in sp.volumi], axis=0) + 0.05
    lo[2] = -passo_griglia * 2
    assi = [np.arange(lo[i], hi[i] + passo_griglia, passo_griglia) for i in range(3)]
    X, Y, Z = np.meshgrid(*assi, indexing="ij")
    p = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    d = np.empty(len(p))
    for i in range(0, len(p), 400000):
        d[i:i + 400000] = campo(sp.volumi, p[i:i + 400000])
    vol = d.reshape(X.shape)
    verts, facce, _n, _v = measure.marching_cubes(vol, level=0.0, spacing=(passo_griglia,) * 3)
    return verts + lo, facce


def oggetto(nome, verts, facce, facce_volute, mat):
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
    mod = ob.modifiers.new("semplifica", "DECIMATE")
    mod.ratio = min(1.0, facce_volute / max(1, len(me.polygons)))
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Pulizia: la semplificazione può lasciare facce degeneri dove le corna sono sottili.
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(me)
    bm.free()
    me.validate()
    bpy.ops.object.shade_smooth()
    return ob


def uv_pelo(me, sp, parte, tile):
    """UV della grana (26/11/2026, sui riferimenti di Fede): sul corpo, sul collo e sulla testa il
    pelo scorre dal dorso verso la pancia (v = arco dalla linea del dorso, u lungo il corpo); sulle
    zampe scende lungo la zampa (u attorno, v in altezza). La cucitura sta sulla linea del dorso,
    dove le due metà si specchiano."""
    zc = np.mean([v.c[2] for v in sp.volumi if isinstance(v, Elli) and v.parte == 0])
    uv = me.uv_layers["UVMap"].data
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            x, y, z = me.vertices[vi].co
            k = int(parte[vi])
            if 2 <= k <= 5:
                cx, cy = sp.centri[k]
                a = math.atan2(y - cy, x - cx)
                r = max(0.02, math.hypot(x - cx, y - cy))
                uv[li].uv = (a * r / tile, z / tile)
            else:
                a = math.atan2(abs(x), z - zc)  # 0 sul dorso, π sotto la pancia
                r = max(0.05, math.hypot(x, z - zc))
                uv[li].uv = (y / tile, -a * r / tile)


def prepara(ob, sp, specie, manto, tile):
    """UV della grana, colori del manto per vertice, parti nella seconda UV."""
    me = ob.data
    me.uv_layers.new(name="UVMap")
    me.uv_layers.new(name="Parti")
    me.uv_layers["UVMap"].active_render = True
    me.uv_layers.active = me.uv_layers["UVMap"]
    co = np.array([v.co[:] for v in me.vertices])
    col, sul_pelo, dominante = colori(sp, specie, manto, co)
    parte, peso = parti(sp, co)
    uv_pelo(me, sp, parte, tile)
    uv2 = me.uv_layers["Parti"].data
    angoli_vert = [lo.vertex_index for lo in me.loops]
    for li, vi in enumerate(angoli_vert):
        uv2[li].uv = (float(parte[vi]), float(peso[vi]))
    return col, angoli_vert, {"sul_pelo": sul_pelo, "dominante": dominante, "parte": parte, "peso": peso, "co": co}


# ---------- carte di pelo (26/11/2026, sui riferimenti di Fede) ----------
# Come le foglie degli alberi: piccole carte con il ritaglio (texture ciocche.png o ciocche_lana.png,
# quattro ciocche affiancate) piantate sul corpo, che seguono il verso del pelo e rompono la
# sagoma. Prendono il colore del corpo dove nascono e si muovono con la parte a cui appartengono.
CIOCCHE = {
    #         carte (completo, leggero), lunghezza, larghezza, sollevamento (gradi), frangia sotto la pancia
    "pecora": ((700, 70), 0.085, 0.075, 55.0, 1.2),
    "capra": ((700, 70), 0.075, 0.05, 18.0, 1.9),
    "maiale": ((520, 50), 0.045, 0.035, 20.0, 1.2),
    "bue": ((1000, 90), 0.085, 0.065, 15.0, 1.6),
}


def carte_pelo(nome, sp, specie, ob, col_vert, info, leggero, mat, seme):
    rnd = random.Random(seme)
    numero, lung, larg, solleva, frangia = CIOCCHE[specie]
    n_carte = numero[1] if leggero else numero[0]
    if leggero:
        lung, larg = lung * 1.9, larg * 2.2
    me = ob.data
    sul_pelo, dominante, parte, peso, co = info["sul_pelo"], info["dominante"], info["parte"], info["peso"], info["co"]
    # Colore finale del corpo per vertice (manto per occlusione), per tingere le carte.
    occ = me.color_attributes["Occlusione"]
    col_fin = np.zeros((len(me.vertices), 3))
    for li, lo in enumerate(me.loops):
        col_fin[lo.vertex_index] = occ.data[li].color[:3]
    # Facce candidate: pelo, niente muso e zoccoli, zampe solo in alto.
    facce, pesi = [], []
    for poly in me.polygons:
        vs = list(poly.vertices)
        k = int(parte[vs[0]])
        w = float(np.mean(peso[vs]))
        pelo = float(np.mean(sul_pelo[vs]))
        cresta = specie == "maiale" and dominante[vs[0]] == "scuro" and k == 0
        if pelo < 0.6 and not cresta:
            continue
        if k in (2, 3, 4, 5) and w > (0.45 if specie != "pecora" else 0.3):
            continue
        if k == 1 and w > 0.75:
            continue  # il muso resta nudo
        if k == 6:
            continue
        facce.append((poly, vs, cresta))
        pesi.append(poly.area * (3.0 if cresta else 1.0))
    scelte = rnd.choices(facce, weights=pesi, k=n_carte)
    bm = bmesh.new()
    uv_l = bm.loops.layers.uv.new("UVMap")
    parti_l = bm.loops.layers.uv.new("Parti")
    colori_carte = []  # un colore per angolo, scritto dopo nello stesso tipo del corpo (byte)
    normali = []
    for poly, vs, cresta in scelte:
        # Un punto a caso nella faccia (sul primo triangolo del ventaglio) e la sua normale.
        a, b, c = (Vector(co[vs[0]]), Vector(co[vs[1]]), Vector(co[vs[2]]))
        r1, r2 = rnd.random(), rnd.random()
        if r1 + r2 > 1:
            r1, r2 = 1 - r1, 1 - r2
        p = a + (b - a) * r1 + (c - a) * r2
        n = Vector(poly.normal)
        if cresta:
            g = Vector((0, -0.6, 1.0))
        else:
            g = Vector((rnd.uniform(-0.1, 0.1), -0.35, -1.0))
        d = g - n * n.dot(g)
        if d.length < 0.2:
            d = Vector((0, -1, 0)) - n * n.dot(Vector((0, -1, 0)))
        d.normalize()
        alzo = math.radians(solleva * rnd.uniform(0.7, 1.3)) if not cresta else math.radians(55)
        verso = (d * math.cos(alzo) + n * math.sin(alzo)).normalized()
        l = lung * rnd.uniform(0.7, 1.25)
        if n.z < -0.25 and not cresta:
            # Sotto la pancia e il collo il pelo pende: frangia più lunga che scende.
            l *= frangia
            verso = (verso + Vector((0, 0, -1.2))).normalized()
        if cresta:
            l *= 1.6
        if int(parte[vs[0]]) == 1:
            l *= 0.55  # pelo corto su collo e fronte
        w = larg * rnd.uniform(0.8, 1.2)
        t = n.cross(verso)
        if t.length < 1e-4:
            continue
        t.normalize()
        radice = p - n * 0.006
        punta = radice + verso * l
        q = [radice - t * w / 2, radice + t * w / 2, punta + t * w * 0.35, punta - t * w * 0.35]
        f = bm.faces.new([bm.verts.new(v) for v in q])
        kk = rnd.randrange(4)
        u0, u1 = kk / 4 + 0.015, (kk + 1) / 4 - 0.015
        vi = vs[0]
        cc = col_fin[vi] * rnd.uniform(0.85, 1.08)
        for lo, uv in zip(f.loops, ((u0, 0.0), (u1, 0.0), (u1, 1.0), (u0, 1.0))):
            lo[uv_l].uv = uv
            lo[parti_l].uv = (float(parte[vi]), float(peso[vi]))
            colori_carte.append((*cc, 1.0))
            normali.append(n.normalized())
    m = bpy.data.meshes.new(nome + "_ciocche")
    bm.to_mesh(m)
    bm.free()
    # Stesso tipo di attributo del corpo (colori in byte, valori lineari): con un tipo diverso
    # l'unione dei due oggetti convertiva i colori e le carte venivano quasi nere.
    attr = m.color_attributes.new("Occlusione", "BYTE_COLOR", "CORNER")
    for li, c in enumerate(colori_carte):
        attr.data[li].color = c
    ob_c = bpy.data.objects.new(nome + "_ciocche", m)
    base.collega(ob_c, mat)
    m.uv_layers["UVMap"].active_render = True
    # Normali del corpo sulle carte: la luce le tratta come la pelle sotto (come le chiome).
    m.normals_split_custom_set(normali)
    return ob_c


def colora(ob, col, angoli_vert):
    """Moltiplica il manto per l'occlusione già cotta nei colori dei vertici."""
    attr = ob.data.color_attributes["Occlusione"]
    for li, vi in enumerate(angoli_vert):
        o = attr.data[li].color[0]
        c = col[vi]
        attr.data[li].color = (c[0] * o, c[1] * o, c[2] * o, 1.0)


def esporta(ob, percorso):
    """Come base.esporta, ma senza immagini: nel gioco la grana (pelo.png, lana.png) la mette lo
    shader degli animali, e così Godot non estrae una copia della texture per ogni modello."""
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=percorso, use_selection=True, export_apply=True, export_image_format="NONE",
                              export_vertex_color="ACTIVE")


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(USCITA, exist_ok=True)
    bpy.context.scene.world = bpy.data.worlds.new("Mondo")
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    dati = {}
    for specie, fabbrica in SPECIE.items():
        sp = fabbrica()
        h = 0.02 if specie == "bue" else 0.011
        verts, facce = superficie(sp, h)
        mat = base.materiale("lana" if specie == "pecora" else "pelo", "lana" if specie == "pecora" else "pelo", ruvidezza=0.95)
        tile = 0.5 if specie == "bue" else 0.35
        mat_c = base.materiale("ciocche_lana" if specie == "pecora" else "ciocche", "ciocche_lana" if specie == "pecora" else "ciocche",
                               ruvidezza=0.95, ritaglio=True)
        for livello, facce_volute in (("", FACCE_COMPLETO[specie]), ("_leggero", FACCE_LEGGERO)):
            for manto in range(3):
                nome = f"animale_{specie}_{manto + 1}{livello}"
                ob = oggetto(nome, verts, facce, facce_volute, mat)
                col, angoli, info = prepara(ob, sp, specie, manto, tile)
                base.cuoci_occlusione(ob, 0.5)
                colora(ob, col, angoli)
                corpo = len(ob.data.polygons)
                carte = carte_pelo(nome, sp, specie, ob, col, info, livello != "", mat_c, 100 + manto)
                ob = base.unisci(nome, [ob, carte])
                ob.data.color_attributes.active_color = ob.data.color_attributes["Occlusione"]
                esporta(ob, os.path.join(USCITA, nome + ".glb"))
                d = ob.dimensions
                print(f"{nome}: {d.x:.2f} x {d.y:.2f} x {d.z:.2f} m, {corpo} facce del corpo, {len(ob.data.polygons) - corpo} carte di pelo")
                bpy.data.objects.remove(ob, do_unlink=True)
        a, b = sp.collo
        # Quanto deve scendere ancora il collo, dopo la rotazione della testa, perché il muso tocchi
        # l'erba (a 8 cm da terra): lo shader abbassa testa e collo di questa misura brucando.
        dy, dz = b[1] - a[1], b[2] - a[2]
        punta_z = a[2] - dy * math.sin(sp.bruca) + dz * math.cos(sp.bruca)
        abbassa = max(0.0, punta_z - 0.08)
        # Coordinate di Godot: x, z di Blender in alto, -y di Blender.
        dati[specie] = {"perno_collo": [a[0], a[2], -a[1]], "lunghezza_collo": float(np.linalg.norm(np.array(b) - np.array(a))),
                        "passo": sp.passo, "spalla": max(sp.zampe.values()), "angolo_bruca": sp.bruca, "abbassa_bruca": abbassa}
    with open(os.path.join(USCITA, "animali.json"), "w") as f:
        json.dump(dati, f, indent=1)


if __name__ == "__main__":
    main()
