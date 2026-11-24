"""Genera i dati della mappa 1 (archetipo pedecollinare) per il gioco Godot.

Usa la stessa logica del Prototipo 0 (prototipi/prototipo0/index.html), ma a risoluzione
più fine: 256 x 256 pixel da 40 m, cioè circa 10 x 10 km. Le funzioni del prototipo
sono continue, quindi la mappa fine ricalca quella a 64 x 64 celle da 160 m.

Uso:  python3 strumenti/mappe/genera_pedecollinare.py gioco/mappe/pedecollinare

Produce nella cartella indicata:
  grezzi/altezze.f32         quote in metri, float32 little endian, riga per riga (nord in alto)
  grezzi/tipo.u8             0 terra, 1 fiume, 2 torrente, 3 torrente orientale, 4 palude, 5 gessi
  grezzi/zona.u8             0 bassa pianura, 1 alta pianura, 2 fascia pedecollinare, 3 colline
  grezzi/fertilita.u8        0-255 (255 = fertilità 1,2)
  grezzi/piena.u8            0-255 (255 = rischio massimo)
  grezzi/acqua.u8            vicinanza ad acqua affidabile (fiume, sorgenti), 0-255
  grezzi/acqua_stagionale.u8 vicinanza a qualunque acqua (anche torrenti e paludi), 0-255
  grezzi/copertura.u8        255 bosco, 0 aperto
  grezzi/bosco_fine.u8       (1024 x 1024, 10 m) quanto un punto è dentro il bosco: 128 = margine,
                             sopra è bosco. Lo usano sia lo shader (volta dipinta, sottobosco) sia
                             la posa degli alberi, così il bordo dipinto e gli alberi coincidono.
  grezzi/palude_fine.u8      (1024 x 1024, 10 m) quanto un punto è dentro la palude: 128 = margine.
  grezzi/pozze_fine.u8       (1024 x 1024, 10 m) acqua ferma nella palude: sopra 128 c'è acqua.
                             Li usano lo shader (pozze, erba umida) e la posa dei canneti.
  grezzi/distanza_acqua.u8   (1024 x 1024) distanza dal bordo del corso d'acqua più vicino: 128 = riva,
                             ogni unità vale 2 m (sotto 128 si è in acqua). Serve a disegnare
                             fiumi e torrenti con bordi morbidi a qualunque zoom.
  grezzi/velocita.u8         velocità media della corrente lungo fiumi e torrenti (0-255 = 0-4 m/s),
                             0 fuori dall'acqua. La usa lo shader per rapide e schiuma.
  grezzi/potenza.u8          potenza idraulica media ogni 100 m di corso (scala logaritmica:
                             0 = niente, 255 = 1000 kW), 0 fuori dall'acqua. Mappa tematica
                             dell'energia dell'acqua (mulini, turbine).
  meta.json                  dimensioni, quote, sorgenti, siti di fondazione, corsi d'acqua
                             (portate, dislivelli, profilo) e siti adatti alle dighe
  anteprima.png              immagine a colori per controllo umano
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt, gaussian_filter, label, map_coordinates

CELLE = 64            # celle del prototipo
SCALA = 4             # pixel per cella
LATO = CELLE * SCALA  # 256
METRI_PER_PX = 160 / SCALA  # 40 m

# ---------- rumore identico al prototipo ----------
def mulberry32(a):
    stato = [a & 0xFFFFFFFF]
    def imul(x, y):
        return (x * y) & 0xFFFFFFFF
    def rnd():
        stato[0] = (stato[0] + 0x6D2B79F5) & 0xFFFFFFFF
        t = stato[0]
        t = imul(t ^ (t >> 15), 1 | t)
        t = ((t + imul(t ^ (t >> 7), 61 | t)) & 0xFFFFFFFF) ^ t
        return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296
    return rnd

LAT = 72
_r = mulberry32(1847)
LATTICE = np.array([_r() for _ in range(LAT * LAT)], dtype=np.float32).astype(np.float64)

def vnoise(x, y):
    xi = np.floor(x).astype(np.int64); yi = np.floor(y).astype(np.int64)
    xf = x - xi; yf = y - yi
    L = lambda i, j: LATTICE[(np.mod(j, LAT)) * LAT + np.mod(i, LAT)]
    s = lambda t: t * t * (3 - 2 * t)
    a, b, c, d = L(xi, yi), L(xi + 1, yi), L(xi, yi + 1), L(xi + 1, yi + 1)
    u, v = s(xf), s(yf)
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v

def fbm(x, y):
    return 0.6 * vnoise(x / 8, y / 8) + 0.3 * vnoise(x / 4 + 17, y / 4 + 9) + 0.1 * vnoise(x / 2 + 31, y / 2 + 5)

rx = lambda y: 9 + 3 * np.sin(y / 7) + 2 * np.sin(y / 3.1)
tx = lambda y: 33 + 2 * np.sin(y / 5)
ex = lambda y: 53 + 2.5 * np.sin(y / 6 + 1)

SORGENTI = [(17, 46), (22, 47), (30, 46), (38, 47), (43, 46), (48, 47)]
SITI = [
    (1, "Terrazzo centrale", 35, 45), (2, "Sbocco del fiume", 15, 47), (3, "Sperone collinare", 25, 45),
    (4, "Dosso nelle paludi", 24, 6), (5, "Area dei gessi", 48, 53), (6, "Pianura aperta", 26, 30),
]

def morbido(a, b, t):
    """Passaggio graduale tra a e b: 0 sotto a, 1 sopra b (come smoothstep)."""
    k = np.clip((t - a) / (b - a), 0, 1)
    return k * k * (3 - 2 * k)

def fasce(d, nodi):
    """Valore che scende per fasce di distanza, con passaggi graduali invece di gradini.
    nodi: coppie (distanza in celle, valore)."""
    return np.interp(d, [a for a, _ in nodi], [v for _, v in nodi])

def distanza_euclidea(sorgenti_mask):
    """Distanza in pixel dalla sorgente più vicina, in linea d'aria: dà cerchi, non quadrati."""
    return distance_transform_edt(~sorgenti_mask)

# ---------- idraulica: corrente, potenza, dislivelli per le dighe ----------
# Corsi d'acqua della mappa: linea di mezzeria (in celle del prototipo), tratto, larghezza
# dell'alveo in celle, portate in m³/s (proposta di Claude, verosimili per l'appennino bolognese:
# un fiume come il Reno o il Savena e due torrenti). Scorrono verso nord (y che diminuisce).
CORSI = [
    {"nome": "Fiume maggiore", "linea": rx, "y_min": 0.0, "mezza_larghezza": 1.5,
     "portata_media": 15.0, "portata_magra": 2.0, "portata_piena": 600.0, "regime": "perenne"},
    {"nome": "Torrente stagionale", "linea": tx, "y_min": 20.0, "mezza_larghezza": 0.3,
     "portata_media": 0.4, "portata_magra": 0.0, "portata_piena": 60.0, "regime": "stagionale (secco d'estate)"},
    {"nome": "Torrente orientale", "linea": ex, "y_min": 10.0, "mezza_larghezza": 0.3,
     "portata_media": 1.5, "portata_magra": 0.1, "portata_piena": 150.0, "regime": "irregolare"},
]
RHO_G = 1000.0 * 9.81
MANNING_N = 0.035     # alveo naturale con ghiaie e vegetazione
PASSO_PROFILO = 1.0 / 16.0   # 10 m in celle
ALTEZZE_DIGA = [10.0, 20.0]  # metri sopra il letto


def _quota_in(e, xc, y):
    """Quota bilineare nel punto (xc, y) in celle del prototipo (xc = centro del pixel)."""
    return map_coordinates(e, [np.atleast_1d(y) * SCALA, np.atleast_1d(xc) * SCALA - 0.5], order=1, mode="nearest")


def idraulica(e, x, y, dR, dT, dE):
    """Profilo di ogni corso d'acqua (letto, pendenza, velocità, potenza), strati a 40 m per
    il gioco e siti adatti alle dighe (valli strette con un buon invaso)."""
    M = 160.0
    vel = np.zeros((LATO, LATO)); pot = np.zeros((LATO, LATO))
    corsi_meta = []; siti = []
    for corso, d_corso in zip(CORSI, [dR, dT, dE]):
        ys = np.arange(CELLE - 1e-3, corso["y_min"], -PASSO_PROFILO)          # da monte (sud) a valle
        xs = corso["linea"](ys)
        letto = _quota_in(e, xs, ys)
        # Il letto scende sempre verso valle: si toglie il rumore che lo farebbe risalire.
        letto = np.minimum.accumulate(letto)
        s = np.concatenate([[0.0], np.cumsum(np.hypot(np.diff(xs), np.diff(ys)) * M)])
        # Pendenza su 200 m, ammorbidita.
        pend = -np.gradient(letto, s)
        pend = np.maximum(gaussian_filter(pend, 10), 0.0004)
        # La portata cresce verso valle con il bacino (dal 60% al 100% della media allo sbocco).
        frazione = 0.6 + 0.4 * (1.0 - ys / CELLE)
        q = corso["portata_media"] * frazione
        # Alveo: larghezza dalla geometria idraulica, profondità e velocità da Manning.
        larg = np.maximum(3.5 * np.sqrt(q), 1.0)
        prof = (q * MANNING_N / (larg * np.sqrt(pend))) ** 0.6
        v = np.clip(q / np.maximum(larg * prof, 1e-6), 0.0, 4.0)
        kw100 = RHO_G * q * pend * 100.0 / 1000.0      # potenza ogni 100 m di corso, in kW
        # Strati a 40 m: ogni pixel vicino all'alveo prende i valori del corso alla sua y.
        ordine = np.argsort(ys)
        v_y = np.interp(y, ys[ordine], v[ordine]); p_y = np.interp(y, ys[ordine], kw100[ordine])
        # Fascia larga attorno all'alveo: lo shader legge questi valori a 40 m e ne disegna la
        # forma con la distanza fine dall'acqua, quindi qui non devono esserci buchi vicino alla riva.
        vicino = (d_corso <= corso["mezza_larghezza"] + 3.0) & (y >= corso["y_min"])
        vel = np.where(vicino, np.maximum(vel, v_y), vel)
        pot = np.where(vicino, np.maximum(pot, p_y), pot)
        # Dighe: ogni 100 m si misura quanto è larga la valle a 10 e 20 m sopra il letto e quanta
        # acqua tratterrebbe (area e volume dell'invaso a monte, collegato all'alveo).
        candidati = []
        for k in range(0, len(ys), 10):
            yk, xk, zb = ys[k], xs[k], letto[k]
            riga = int(round(yk * SCALA))
            if riga <= 2 or riga >= LATO - 2:
                continue
            for h in ALTEZZE_DIGA:
                lim = zb + h
                c = int(np.clip(round(xk * SCALA - 0.5), 0, LATO - 1))
                sx = c; dx = c
                while sx > 0 and e[riga, sx] < lim:
                    sx -= 1
                while dx < LATO - 1 and e[riga, dx] < lim:
                    dx += 1
                if e[riga, sx] < lim or e[riga, dx] < lim:
                    continue                     # la valle non si chiude: niente diga
                lunghezza = (dx - sx) * METRI_PER_PX
                if lunghezza > 1500:
                    continue
                sotto = (e < lim)
                sotto[:riga + 1, :] = False      # solo a monte (sud) della diga
                etichette, _ = label(sotto)
                semi = etichette[riga + 1, sx + 1:dx]
                semi = semi[semi > 0]
                if semi.size == 0:
                    continue
                invaso = np.isin(etichette, np.unique(semi))
                area = invaso.sum() * METRI_PER_PX ** 2
                volume = float(((lim - e) * invaso).sum() * METRI_PER_PX ** 2)
                candidati.append({"corso": corso["nome"], "px": [int(round(xk * SCALA - 0.5)), riga],
                                  "altezza_m": h, "lunghezza_m": round(lunghezza),
                                  "area_ha": round(area / 1e4, 1), "volume_milioni_m3": round(volume / 1e6, 2),
                                  "salto_m": h, "potenza_media_kw": round(RHO_G * float(q[k]) * h * 0.8 / 1000.0, 1),
                                  "resa": volume / max(lunghezza * h, 1.0)})
        # Si tengono i tre migliori per corso (acqua trattenuta per metro cubo di diga), almeno a
        # 1 km l'uno dall'altro; in ogni luogo l'altezza che rende di più.
        scelti = []
        for cand in sorted(candidati, key=lambda c: -c["resa"]):
            if all(np.hypot(cand["px"][0] - o["px"][0], cand["px"][1] - o["px"][1]) * METRI_PER_PX >= 1000 for o in scelti):
                scelti.append(cand)
            if len(scelti) == 3:
                break
        for c in scelti:
            c["resa"] = round(c["resa"], 1)
        siti += scelti
        corsi_meta.append({
            "nome": corso["nome"], "regime": corso["regime"],
            "portata_media_m3s": corso["portata_media"], "portata_magra_m3s": corso["portata_magra"],
            "portata_piena_m3s": corso["portata_piena"],
            "lunghezza_km": round(float(s[-1]) / 1000.0, 2),
            "quota_monte_m": round(float(letto[0]), 1), "quota_valle_m": round(float(letto[-1]), 1),
            "pendenza_max_per_mille": round(float(pend.max()) * 1000.0, 1),
            "velocita_max_ms": round(float(v.max()), 2),
            "potenza_max_kw_100m": round(float(kw100.max()), 1),
        })
    vel_u8 = (np.clip(vel / 4.0, 0, 1) * 255).round().astype(np.uint8)
    # Potenza in scala logaritmica: 1 kW = 1, 1000 kW = 255 (0 = niente acqua).
    pot_u8 = np.where(pot > 0, np.clip(np.log10(np.maximum(pot, 1.0)) / 3.0 * 254 + 1, 1, 255), 0).round().astype(np.uint8)
    return corsi_meta, vel_u8, pot_u8, siti


def genera(uscita):
    py, px = np.mgrid[0:LATO, 0:LATO].astype(np.float64)
    x = px / SCALA; y = py / SCALA                    # coordinate in celle del prototipo
    xc = (px + 0.5) / SCALA                           # centro del pixel
    n = fbm(x, y)

    e = np.where(y < 16, 15 + y / 16 * 15 + (n - .5) * 6,
        np.where(y < 44, 30 + (y - 16) / 28 * 30 + (n - .5) * 8,
        np.where(y < 49, 60 + (y - 44) / 5 * 40 + (n - .5) * 10,
                 100 + ((y - 49) / 14) * 300 * (0.55 + 0.6 * n) + (n - .5) * 40)))
    zona = np.where(y < 16, 0, np.where(y < 44, 1, np.where(y < 49, 2, 3))).astype(np.uint8)
    dS = np.hypot(x - 25, y - 45)
    e = e + np.where(dS < 4.5, 55 * (1 - dS / 4.5), 0)
    zona = np.where(dS < 3, 3, zona).astype(np.uint8)
    dR = np.abs(xc - rx(y)); dT = np.abs(xc - tx(y)); dE = np.abs(xc - ex(y))
    valle = y >= 44
    e = e - np.where(valle, np.maximum(0, e - 60) * np.maximum(0, 1 - dR / 7) * 0.85, 0)
    e = e - np.where(valle, np.maximum(0, e - 70) * np.maximum(0, 1 - dT / 4) * 0.6, 0)
    e = e - np.where(valle, np.maximum(0, e - 70) * np.maximum(0, 1 - dE / 4) * 0.6, 0)
    dD = np.hypot(x - 24, y - 6)
    e = e + np.where(dD < 2.5, 3, 0)

    tipo = np.zeros((LATO, LATO), dtype=np.uint8)
    palude = (y < 14) & (fbm(x + 40, y + 40) > 0.53) & (dD >= 2.5)
    tipo[palude] = 4
    tipo[(y >= 10) & (dE <= 0.3)] = 3
    tipo[(y >= 20) & (dT <= 0.3)] = 2
    tipo[dR <= 1.5] = 1
    # Affioramento dei gessi: una macchia irregolare (prima era un rettangolo segnaposto).
    # forza_gessi va da 0 (fuori) a 1 (pieno affioramento), con un bordo frastagliato dal rumore.
    dG = np.hypot((x - 49.0) / 4.3, (y - 53.6) / 3.3) + (fbm(x * 2.3 + 11, y * 2.3 + 5) - 0.5) * 0.9
    forza_gessi = 1 - morbido(0.75, 1.15, dG)
    gessi = (tipo == 0) & (dG < 1.0)
    tipo[gessi] = 5
    terra = (tipo == 0) | (tipo == 5)

    fn = fbm(x + 7, y + 3)
    bosco = np.where(zona == 3, fn > 0.36, np.where(zona == 0, fn > 0.66, fn > 0.63)) & (tipo == 0)

    # Fertilità per fascia, con passaggi graduali di circa una cella (160 m) ai confini:
    # prima i confini erano linee nette e le mappe tematiche risultavano squadrettate.
    f_bassa = 1.0 + (n - .5) * 0.2
    f_alta = 0.62 + (n - .5) * 0.3
    f_pede = np.full_like(n, 0.8)
    f_coll = 0.4 + (n - .5) * 0.2
    f = f_bassa + (f_alta - f_bassa) * morbido(15.5, 16.5, y)
    f = f + (f_pede - f) * morbido(43.5, 44.5, y)
    f = f + (f_coll - f) * morbido(48.5, 49.5, y)
    f = f + (f_coll - f) * (1 - morbido(2.5, 3.5, dS))     # sperone collinare
    f = f + (0.15 - f) * forza_gessi
    f = np.where((y < 49) & (dR <= 5), np.maximum(f, 1.05 - dR * 0.03), f)
    fert = np.where(terra, np.clip(f, 0.05, 1.2), 0)

    # Rischio di piena: stesse fasce di prima, ma con passaggi graduali sia lungo la distanza
    # dal corso d'acqua sia tra pianura, fascia pedecollinare e valli (niente gradini).
    r_pianura = fasce(dR, [(2.0, 0.85), (3.0, 0.55), (4.0, 0.55), (5.0, 0.3), (6.0, 0.3), (7.0, 0.0)])
    r_alta = fasce(dR, [(2.0, 0.85), (3.0, 0.55), (4.0, 0.55), (5.0, 0.0)])
    r_valle = fasce(dR, [(2.0, 0.6), (3.0, 0.0)])
    r = r_pianura + (r_alta - r_pianura) * morbido(29, 31, y)
    r = r + (r_valle - r) * morbido(48, 50, y)
    r = np.where(terra, np.maximum(r, 0.25 * (1 - morbido(15, 17, y))), r)
    rt = (fasce(dT, [(1.0, 0.55), (2.0, 0.25), (3.0, 0.0)]) * (1 - morbido(48, 50, y))
          + fasce(dT, [(1.0, 0.4), (2.0, 0.0)]) * morbido(48, 50, y)) * morbido(19, 21, y)
    re = fasce(dE, [(1.0, 0.5), (2.0, 0.3), (3.0, 0.0)]) * morbido(9, 11, y)
    piena = np.where(terra, np.maximum(np.maximum(r, rt), re), 1.0)

    sorg = np.zeros((LATO, LATO), dtype=bool)
    sorgenti_px = []
    for sx, sy in SORGENTI:
        cx, cy = int((sx + 0.5) * SCALA), int((sy + 0.5) * SCALA)
        sorg[cy - 1:cy + 1, cx - 1:cx + 1] = True
        sorgenti_px.append([cx, cy])
    # Distanze in linea d'aria (prima a scacchiera: attorno alle sorgenti venivano quadrati).
    d_aff = distanza_euclidea((tipo == 1) | sorg) / SCALA
    d_tutte = distanza_euclidea((~terra) | sorg) / SCALA
    # Portata 9 celle invece di 8: il cerchio copre la stessa area del vecchio quadrato,
    # così la vicinanza all'acqua dei siti resta quella del Prototipo 0.
    acqua = np.clip(1 - d_aff / 9, 0, 1)
    acqua_st = np.clip(1 - d_tutte / 9, 0, 1)

    # Distanza in metri dal bordo dell'acqua (negativa dentro l'alveo), calcolata dalle funzioni
    # continue a risoluzione quadrupla (1024 x 1024, 10 m), per bordi morbidi a ogni zoom.
    FINE = 4
    k = np.arange(LATO * FINE)
    pf = (k + 0.5) / FINE - 0.5                     # coordinate in pixel della maglia del terreno
    PY, PX = np.meshgrid(pf, pf, indexing="ij")
    xcf = (PX + 0.5) / SCALA; yqf = PY / SCALA
    M = 160.0
    big = 1e4
    d_fiume = np.abs(xcf - rx(yqf)) * M - 1.5 * M
    d_torr = np.where(yqf >= 20, np.abs(xcf - tx(yqf)) * M - 22.0, big)
    d_torr_e = np.where(yqf >= 10, np.abs(xcf - ex(yqf)) * M - 28.0, big)
    dist_acqua = np.minimum(np.minimum(d_fiume, d_torr), d_torr_e)
    dist_u8 = np.clip(128 + dist_acqua / 2.0, 0, 255).round().astype(np.uint8)

    # Bosco a 10 m: la copertura a celle da 40 m, ammorbidita e frastagliata da rumori a 80 e 27 m.
    # Valore 0,5 = margine del bosco; niente bosco nell'acqua e a meno di 4 m dalla riva.
    cop = map_coordinates(bosco.astype(np.float64), [PY, PX], order=1, mode="nearest")
    cop = gaussian_filter(cop, 1.6)
    v_bosco = cop + (vnoise(xcf * 2.0 + 13, yqf * 2.0 + 7) - 0.5) * 0.38 + (vnoise(xcf * 6.0 + 3, yqf * 6.0 + 29) - 0.5) * 0.2
    v_bosco = np.where(dist_acqua < 4.0, np.minimum(v_bosco, 0.3), v_bosco)
    bosco_u8 = (np.clip(v_bosco, 0, 1) * 255).round().astype(np.uint8)

    # Palude a 10 m: celle di palude ammorbidite e frastagliate. Le pozze vengono da un rumore
    # senza periodo (campo casuale filtrato a tre scale, 20-120 m), più fitte verso l'interno.
    rng = np.random.default_rng(1847)
    def rumore(sigma):
        r = gaussian_filter(rng.standard_normal((LATO * FINE, LATO * FINE)), sigma)
        return (r - r.mean()) / (r.std() + 1e-9)
    pal = map_coordinates((tipo == 4).astype(np.float64), [PY, PX], order=1, mode="nearest")
    pal = gaussian_filter(pal, 1.4)
    v_pal = pal + (vnoise(xcf * 2.0 + 41, yqf * 2.0 + 17) - 0.5) * 0.35 + rumore(3.0) * 0.06
    interno = np.clip((gaussian_filter(pal, 4.0) - 0.5) / 0.4, 0, 1)
    n_pozze = rumore(2.0) * 0.28 + rumore(5.0) * 0.45 + rumore(12.0) * 0.35
    v_pozze = 0.5 + (n_pozze + interno * 0.9 - 0.95) * 0.25
    v_pozze = np.where(v_pal > 0.55, v_pozze, np.minimum(v_pozze, 0.35))
    palude_u8 = (np.clip(v_pal, 0, 1) * 255).round().astype(np.uint8)
    pozze_u8 = (np.clip(v_pozze, 0, 1) * 255).round().astype(np.uint8)

    corsi, velocita_u8, potenza_u8, siti_diga = idraulica(e, x, y, dR, dT, dE)

    g = os.path.join(uscita, "grezzi"); os.makedirs(g, exist_ok=True)
    velocita_u8.tofile(os.path.join(g, "velocita.u8"))
    potenza_u8.tofile(os.path.join(g, "potenza.u8"))
    dist_u8.tofile(os.path.join(g, "distanza_acqua.u8"))
    bosco_u8.tofile(os.path.join(g, "bosco_fine.u8"))
    palude_u8.tofile(os.path.join(g, "palude_fine.u8"))
    pozze_u8.tofile(os.path.join(g, "pozze_fine.u8"))
    e.astype("<f4").tofile(os.path.join(g, "altezze.f32"))
    tipo.tofile(os.path.join(g, "tipo.u8"))
    zona.tofile(os.path.join(g, "zona.u8"))
    (np.clip(fert / 1.2, 0, 1) * 255).round().astype(np.uint8).tofile(os.path.join(g, "fertilita.u8"))
    (np.clip(piena, 0, 1) * 255).round().astype(np.uint8).tofile(os.path.join(g, "piena.u8"))
    (acqua * 255).round().astype(np.uint8).tofile(os.path.join(g, "acqua.u8"))
    (acqua_st * 255).round().astype(np.uint8).tofile(os.path.join(g, "acqua_stagionale.u8"))
    (bosco.astype(np.uint8) * 255).tofile(os.path.join(g, "copertura.u8"))

    meta = {
        "nome": "Pedecollinare",
        "fonte": "Generata con la logica del Prototipo 0 (strumenti/mappe/genera_pedecollinare.py)",
        "lato_px": LATO, "metri_per_px": METRI_PER_PX, "lato_acqua_px": LATO * FINE,
        "quota_min": float(e.min()), "quota_max": float(e.max()),
        "nord": "in alto (riga 0)",
        "sorgenti_px": sorgenti_px,
        "siti": [{"n": nn, "nome": nome, "px": [int((sx + 0.5) * SCALA), int((sy + 0.5) * SCALA)]} for nn, nome, sx, sy in SITI],
        "corsi_acqua": corsi,
        "siti_diga": siti_diga,
    }
    with open(os.path.join(uscita, "meta.json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, ensure_ascii=False, indent=2)

    # anteprima per controllo umano
    stops = [(15, (199, 212, 182)), (35, (206, 214, 178)), (60, (216, 213, 170)), (100, (214, 196, 150)),
             (200, (196, 172, 128)), (350, (174, 150, 112)), (500, (156, 134, 102))]
    img = np.zeros((LATO, LATO, 3))
    for k in range(len(stops) - 1):
        e0, c0 = stops[k]; e1, c1 = stops[k + 1]
        t = np.clip((e - e0) / (e1 - e0), 0, 1)[..., None]
        m = ((e >= e0) | (k == 0)) & ((e < e1) | (k == len(stops) - 2))
        img[m] = (np.array(c0) + (np.array(c1) - np.array(c0)) * t)[m]
    img[bosco] = img[bosco] * 0.82
    img[tipo == 4] = (170, 196, 186); img[tipo == 5] = (222, 218, 206)
    img[(tipo == 1) | (tipo == 2) | (tipo == 3)] = (76, 130, 164)
    Image.fromarray(img.astype(np.uint8)).resize((LATO * 2, LATO * 2), Image.NEAREST).save(os.path.join(uscita, "anteprima.png"))
    return meta, e, tipo

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "gioco/mappe/pedecollinare"
    meta, e, tipo = genera(out)
    print(f"Mappa scritta in {out}: {meta['lato_px']}x{meta['lato_px']} px, quote {meta['quota_min']:.0f}-{meta['quota_max']:.0f} m")
    for s in meta["siti"]:
        x, y = s["px"]
        print(f"  sito {s['n']} {s['nome']}: quota {e[y, x]:.0f} m, tipo {tipo[y, x]}")
