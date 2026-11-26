"""Genera texture procedurali ripetibili (tileable) per gli asset, senza scaricare nulla.

Uso:  python3 strumenti/blender/texture_procedurali.py gioco/asset/texture

Ogni texture è un PNG 512 x 512 in sRGB (la maschera delle chiazze 256 x 256).
Le foglie hanno il canale alfa (ritaglio): una texture per specie, foglie singole su rametti.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

LATO = 512


def rumore_valore(lato, freq, seme):
    """Rumore a valori, periodico sul bordo (ripetibile), valori 0-1."""
    rng = np.random.default_rng(seme)
    griglia = rng.random((freq, freq))
    t = np.arange(lato) / lato * freq
    i0 = np.floor(t).astype(int)
    f = t - i0
    f = f * f * (3 - 2 * f)
    i1 = (i0 + 1) % freq
    i0 = i0 % freq
    a = griglia[np.ix_(i0, i0)]; b = griglia[np.ix_(i0, i1)]
    c = griglia[np.ix_(i1, i0)]; d = griglia[np.ix_(i1, i1)]
    fy = f[:, None]; fx = f[None, :]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(lato, freq, ottave, seme, persistenza=0.5):
    tot = np.zeros((lato, lato)); amp = 1.0; somma = 0.0
    for o in range(ottave):
        tot += amp * rumore_valore(lato, freq * 2 ** o, seme + o * 101)
        somma += amp; amp *= persistenza
    return tot / somma


def rumore_anisotropo(lato, freq_x, freq_y, seme):
    """Rumore stirato: fibre verticali (freq_x alta, freq_y bassa)."""
    rng = np.random.default_rng(seme)
    griglia = rng.random((freq_y, freq_x))
    ty = np.arange(lato) / lato * freq_y; tx = np.arange(lato) / lato * freq_x
    y0 = np.floor(ty).astype(int); x0 = np.floor(tx).astype(int)
    fy = ty - y0; fx = tx - x0
    fy = fy * fy * (3 - 2 * fy); fx = fx * fx * (3 - 2 * fx)
    y1 = (y0 + 1) % freq_y; x1 = (x0 + 1) % freq_x; y0 %= freq_y; x0 %= freq_x
    a = griglia[np.ix_(y0, x0)]; b = griglia[np.ix_(y0, x1)]
    c = griglia[np.ix_(y1, x0)]; d = griglia[np.ix_(y1, x1)]
    fy = fy[:, None]; fx = fx[None, :]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def salva(arr, percorso):
    Image.fromarray(np.clip(arr * 255, 0, 255).astype(np.uint8)).save(percorso)


def colore(base, campo):
    return np.stack([base[0] * campo, base[1] * campo, base[2] * campo], axis=-1)


def paglia():
    """Tetto di paglia visto da vicino (rifatto il 24/11/2026 per lo zoom ravvicinato): corsi di
    steli sovrapposti, ogni stelo disegnato, le teste tagliate chiare in fondo a ogni corso e
    l'ombra del corso sopra; toni dal dorato al grigio della paglia invecchiata.
    Gli steli corrono lungo la verticale, che sul tetto segue la pendenza della falda."""
    rng = np.random.default_rng(1)
    s = 2
    corsi = 6
    alto = LATO / corsi
    img = Image.new("RGB", (LATO * s, LATO * s), (58, 46, 30))
    d = ImageDraw.Draw(img)
    dorati = [(186, 148, 88), (170, 132, 76), (198, 160, 98), (158, 122, 70), (176, 146, 96), (146, 116, 72)]
    grigi = [(142, 128, 104), (128, 114, 92), (152, 138, 112)]
    # Bordo inferiore di ogni corso un po' ondulato, ripetibile in orizzontale.
    onda = rumore_valore(LATO, 6, 7)[0] * alto * 0.25
    # Dal basso verso l'alto della texture: ogni corso copre la parte alta di quello sotto,
    # così si vedono le teste tagliate sopra gli steli del corso seguente.
    for c in reversed(range(corsi)):
        for _ in range(5200):
            x = rng.random() * LATO
            fondo = (c + 1) * alto + onda[int(x) % LATO] - rng.random() * alto * 0.12
            lung = alto * rng.uniform(0.75, 1.15)
            y0 = fondo - lung
            a = rng.normal(0, 0.07)
            palette = grigi if rng.random() < 0.18 else dorati
            base = palette[rng.integers(len(palette))]
            # Più scuri in alto, dove il corso sopra fa ombra; più chiari verso le teste.
            k = rng.uniform(0.85, 1.08)
            w = max(1, int(rng.uniform(0.9, 1.8) * s))
            pezzi = 4
            for j in range(pezzi):
                t0, t1 = j / pezzi, (j + 1) / pezzi
                luce = k * (0.62 + 0.42 * t1)
                col = tuple(int(min(255, ch * luce)) for ch in base)
                xa, ya = x + math.sin(a) * lung * t0, y0 + lung * t0
                xb, yb = x + math.sin(a) * lung * t1, y0 + lung * t1
                for ox in (-LATO, 0, LATO):
                    for oy in (-LATO, 0, LATO):
                        if -40 < xa + ox < LATO + 40 and -40 < ya + oy < LATO + 40:
                            d.line([((xa + ox) * s, (ya + oy) * s), ((xb + ox) * s, (yb + oy) * s)], fill=col, width=w)
            # Testa tagliata dello stelo: un punto chiaro in fondo.
            if rng.random() < 0.55:
                col = tuple(int(min(255, ch * 1.18 * k)) for ch in base)
                r = rng.uniform(0.6, 1.2) * s
                xb, yb = x + math.sin(a) * lung, fondo
                for ox in (-LATO, 0, LATO):
                    for oy in (-LATO, 0, LATO):
                        cx, cy = (xb + ox) * s, (yb + oy) * s
                        if -40 * s < cx < (LATO + 40) * s and -40 * s < cy < (LATO + 40) * s:
                            d.ellipse([cx - r, cy - r * 0.7, cx + r, cy + r * 0.7], fill=col)
    arr = np.asarray(img.resize((LATO, LATO), Image.LANCZOS)).astype(float) / 255
    # Ombra sotto le teste del corso precedente (subito sotto il bordo di ogni corso).
    y = np.arange(LATO)[:, None]
    fase = ((y - onda[None, :]) / alto) % 1.0
    ombra = 1.0 - 0.38 * np.exp(-fase / 0.08)
    arr = arr * ombra[..., None]
    # Invecchiamento a chiazze larghe: paglia ingrigita e qualche velo di muschio.
    vecchio = np.clip((fbm(LATO, 3, 4, 3) - 0.5) * 2.2, 0, 0.45)[..., None]
    arr = arr * (1 - vecchio) + (arr.mean(axis=-1, keepdims=True) * np.array([1.0, 0.97, 0.9])) * vecchio
    muschio = np.clip((fbm(LATO, 5, 3, 8) - 0.66) * 3.0, 0, 0.3)[..., None]
    arr = arr * (1 - muschio) + arr * np.array([0.72, 0.85, 0.55]) * muschio
    # Un po' più scura e calda: al sole del gioco la paglia chiara si sbiancava (prova del 24/11).
    arr = arr * np.array([0.86, 0.8, 0.7])
    return arr * (0.92 + 0.16 * fbm(LATO, 2, 3, 5))[..., None]


def argilla():
    """Muro d'argilla e paglia (incannicciato intonacato) visto da vicino (rifatto il 24/11/2026):
    stesure a mano a chiazze, crepe da ritiro, paglia tritata nell'impasto, tracce dei rami sotto."""
    rng = np.random.default_rng(10)
    n = fbm(LATO, 4, 6, 10)
    fine = fbm(LATO, 48, 3, 11)
    # Tracce dell'incannicciato sotto l'intonaco: righe orizzontali appena visibili.
    righe = 0.5 + 0.5 * np.sin(np.arange(LATO)[:, None] / LATO * 2 * math.pi * 14 + n * 3)
    campo = 0.8 + 0.28 * (n - 0.5) * 2 * 0.5 + 0.1 * (fine - 0.5) - 0.06 * righe
    base = np.array([0.60, 0.46, 0.31])
    asciutta = np.array([0.74, 0.62, 0.46])
    img = colore(base, campo)
    chiare = np.clip((fbm(LATO, 3, 3, 12) - 0.5) * 2.2, 0, 0.55)[..., None]
    img = img * (1 - chiare) + colore(asciutta, campo) * chiare
    # Stesure a mano: pennellate corte e curve, un po' più chiare o più scure dell'intorno.
    s = 2
    strato = Image.new("RGBA", (LATO * s, LATO * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(strato)
    for _ in range(900):
        x, y = rng.random() * LATO, rng.random() * LATO
        w, h = rng.uniform(14, 40), rng.uniform(5, 12)
        tono = (255, 236, 205, int(rng.uniform(8, 24))) if rng.random() < 0.65 else (70, 48, 30, int(rng.uniform(6, 16)))
        a0 = rng.uniform(0, 360)
        for ox in (-LATO, 0, LATO):
            for oy in (-LATO, 0, LATO):
                if -50 < x + ox < LATO + 50 and -50 < y + oy < LATO + 50:
                    d.arc([(x + ox - w) * s, (y + oy - h) * s, (x + ox + w) * s, (y + oy + h) * s], a0, a0 + rng.uniform(70, 160), fill=tono, width=int(h * 0.8 * s))
    strato = np.asarray(strato.resize((LATO, LATO), Image.LANCZOS)).astype(float) / 255
    img = img * (1 - strato[..., 3:]) + strato[..., :3] * strato[..., 3:]
    # Paglia tritata nell'impasto: pagliuzze chiare corte.
    pagliuzze = fili(rng, 1800, LATO, [(196, 164, 104), (178, 146, 90), (210, 182, 122)], lung=(2, 6), spessore=(0.7, 1.1),
                     luce=(0.9, 1.05), inclinazione=1.6, fondo=(0, 0, 0))
    maschera = (pagliuzze.max(axis=-1, keepdims=True) > 0.25) * 0.75
    img = img * (1 - maschera) + pagliuzze * maschera
    # Crepe da ritiro: bordi di celle irregolari (ripetibili), sottili e scure, solo a tratti.
    punti = rng.random((70, 2)) * LATO
    yy, xx = np.mgrid[0:LATO, 0:LATO].astype(float)
    d1 = np.full((LATO, LATO), 1e9); d2 = np.full((LATO, LATO), 1e9)
    for px, py in punti:
        for ox in (-LATO, 0, LATO):
            for oy in (-LATO, 0, LATO):
                dd = np.hypot(xx - px - ox, yy - py - oy)
                d2 = np.where(dd < d1, d1, np.minimum(d2, dd))
                d1 = np.minimum(d1, dd)
    bordo = np.clip(1.0 - (d2 - d1) / 1.4, 0, 1)
    a_tratti = np.clip((fbm(LATO, 6, 3, 13) - 0.55) * 4.0, 0, 1)
    crepe = (bordo * a_tratti)[..., None]
    img = img * (1 - 0.4 * crepe)
    return np.clip(img, 0, 1)


def legno():
    venature = rumore_anisotropo(LATO, 48, 4, 20)
    n = fbm(LATO, 8, 3, 21)
    campo = 0.7 + 0.4 * venature + 0.15 * n
    return colore(np.array([0.42, 0.29, 0.18]), campo)


def corteccia():
    solchi = rumore_anisotropo(LATO, 40, 5, 30)
    solchi = np.abs(solchi - 0.5) * 2
    n = fbm(LATO, 6, 4, 31)
    campo = 0.45 + 0.6 * (1 - solchi) * (0.7 + 0.5 * n)
    return colore(np.array([0.36, 0.30, 0.24]), campo)


def pietra():
    n = fbm(LATO, 4, 6, 40)
    granuli = np.random.default_rng(41).random((LATO, LATO))
    campo = 0.72 + 0.35 * n + 0.08 * granuli
    base = np.array([0.55, 0.53, 0.49])
    licheni = np.clip((fbm(LATO, 8, 3, 42) - 0.62) * 4, 0, 1)[..., None]
    return colore(base, campo) * (1 - 0.4 * licheni) + np.array([0.52, 0.55, 0.38]) * 0.4 * licheni


def fili(rng, n, lato, palette, lung=(5, 12), spessore=(1.4, 2.6), luce=(0.8, 1.15), inclinazione=0.5, fondo=(0, 0, 0)):
    """Disegna n fili d'erba (tratti corti quasi verticali) a risoluzione doppia, ripetibili sui bordi."""
    s = 2
    img = Image.new("RGB", (lato * s, lato * s), fondo)
    d = ImageDraw.Draw(img)
    for _ in range(n):
        x, y = rng.random() * lato, rng.random() * lato
        l = rng.uniform(*lung)
        a = -math.pi / 2 + rng.normal(0, inclinazione)
        base = palette[rng.integers(len(palette))]
        k = rng.uniform(*luce)
        col = tuple(int(min(255, c * k)) for c in base)
        w = max(1, int(rng.uniform(*spessore) * s))
        x2, y2 = x + l * math.cos(a), y + l * math.sin(a)
        # Il filo si ripete oltre i bordi, così la texture resta ripetibile.
        for ox in (-lato, 0, lato):
            for oy in (-lato, 0, lato):
                if -20 < x + ox < lato + 20 and -20 < y + oy < lato + 20:
                    d.line([((x + ox) * s, (y + oy) * s), ((x2 + ox) * s, (y2 + oy) * s)], fill=col, width=w)
    return np.asarray(img.resize((lato, lato), Image.LANCZOS)).astype(float) / 255


def erba():
    """Prato fine: migliaia di fili su un fondo scuro, con variazioni lente di tono."""
    rng = np.random.default_rng(50)
    verdi = [(96, 118, 52), (110, 128, 58), (84, 108, 46), (124, 134, 64), (102, 112, 50), (136, 138, 72)]
    img = fili(rng, 26000, LATO, verdi, luce=(0.9, 1.06), fondo=(78, 94, 44))
    n = fbm(LATO, 4, 4, 52)[..., None]
    img = img * (0.88 + 0.24 * n) + np.array([0.03, 0.01, -0.02]) * (n - 0.5)
    # Pochi fiori minuti.
    for col, soglia in (([0.93, 0.84, 0.38], 0.9992), ([0.92, 0.92, 0.88], 0.9994)):
        img[rng.random((LATO, LATO)) > soglia] = col
    return img


def erba_secca():
    """Erba alta secca, tra ocra e rossiccio, per le chiazze incolte (il sottobosco delle reference)."""
    rng = np.random.default_rng(55)
    secchi = [(160, 108, 62), (174, 122, 68), (142, 92, 54), (180, 138, 82), (134, 98, 58), (164, 102, 60)]
    img = fili(rng, 22000, LATO, secchi, lung=(7, 16), spessore=(1.3, 2.4), luce=(0.9, 1.06), inclinazione=0.65, fondo=(108, 74, 44))
    n = fbm(LATO, 4, 4, 56)[..., None]
    return img * (0.85 + 0.3 * n)


def macchie():
    """Maschera a bassa frequenza (grigi) che distribuisce le chiazze di erba secca sul terreno."""
    return np.repeat(fbm(256, 4, 5, 57, 0.55)[..., None], 3, axis=-1)


def foglia(d, cx, cy, lung, ang, col, s):
    """Una foglia a mandorla appuntita: bordo scuro, metà in luce più chiara, nervatura."""
    larg = lung * 0.5
    pts = []
    for k in range(16):
        t = k / 16 * 2 * math.pi
        px = lung * 0.5 * math.cos(t)
        # Più larga verso il picciolo, appuntita in cima.
        py = larg * 0.5 * math.sin(t) * (1 - 0.35 * math.cos(t))
        pts.append((px, py))

    def tr(px, py):
        return ((cx + px * math.cos(ang) - py * math.sin(ang)) * s, (cy + px * math.sin(ang) + py * math.cos(ang)) * s)

    scuro = tuple(int(c * 0.6) for c in col) + (255,)
    d.polygon([tr(px * 1.07, py * 1.18) for px, py in pts], fill=scuro)
    d.polygon([tr(px, py) for px, py in pts], fill=tuple(col) + (255,))
    chiaro = tuple(min(255, int(c * 1.17)) for c in col) + (255,)
    d.polygon([tr(px, py) for px, py in pts[8:] + [pts[0]]], fill=chiaro)
    nerv = tuple(int(c * 0.75) for c in col) + (255,)
    d.line([tr(-lung * 0.5, 0), tr(lung * 0.4, 0)], fill=nerv, width=max(1, int(lung * 0.05 * s)))


def foglie(seme, toni, rametti=(6, 7), per_rametto=(5, 6), dim=(78, 100)):
    """Ciuffo di foglie singole su rametti che partono dal centro: contorno lobato, non circolare.

    toni: colori RGB della specie; ogni foglia ne prende uno con piccole variazioni.
    """
    rng = np.random.default_rng(seme)
    s = 2  # disegno a risoluzione doppia, poi riduzione: bordi puliti
    img = Image.new("RGBA", (LATO * s, LATO * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = LATO / 2
    elenco = []
    rami = []
    n_r = int(rng.integers(rametti[0], rametti[1] + 1))
    for k in range(n_r):
        a = 2 * math.pi * k / n_r + rng.uniform(-0.35, 0.35)
        lung_r = LATO * rng.uniform(0.28, 0.36)
        curva = rng.uniform(-0.5, 0.5)
        punti = [(c + math.cos(a + curva * t) * lung_r * t, c + math.sin(a + curva * t) * lung_r * t)
                 for t in (j / 11 for j in range(12))]
        rami.append(punti)
        n_f = int(rng.integers(per_rametto[0], per_rametto[1] + 1))
        for j in range(n_f):
            t = 0.2 + 0.8 * j / max(n_f - 1, 1)
            px, py = punti[min(11, int(t * 11))]
            aa = a + curva * t + (1 if j % 2 else -1) * rng.uniform(0.5, 1.1)
            l = rng.uniform(*dim) * (1.0 - 0.2 * t)
            elenco.append((t, px + math.cos(aa) * l * 0.45, py + math.sin(aa) * l * 0.45, l, aa))
        px, py = punti[-1]
        elenco.append((1.0, px + math.cos(a + curva) * 14, py + math.sin(a + curva) * 14, rng.uniform(*dim), a + curva))
        # Rametti secondari a metà ramo: riempiono lo spazio tra un ramo e l'altro.
        for lato_s in (-1, 1):
            t0 = rng.uniform(0.35, 0.6)
            px, py = punti[int(t0 * 11)]
            a2 = a + curva * t0 + lato_s * rng.uniform(0.6, 0.9)
            l2 = lung_r * rng.uniform(0.35, 0.5)
            sec = [(px + math.cos(a2) * l2 * u, py + math.sin(a2) * l2 * u) for u in (0, 0.5, 1)]
            rami.append(sec)
            for j in range(2):
                u = 0.45 + 0.55 * j
                qx, qy = px + math.cos(a2) * l2 * u, py + math.sin(a2) * l2 * u
                aa = a2 + (1 if j % 2 else -1) * rng.uniform(0.4, 1.0)
                l = rng.uniform(*dim) * 0.85
                elenco.append((0.5 + 0.5 * u * t0, qx + math.cos(aa) * l * 0.45, qy + math.sin(aa) * l * 0.45, l, aa))
    # Foglie di riempimento attorno al centro.
    for _ in range(16):
        r = rng.random() ** 0.6 * LATO * 0.22
        a = rng.random() * 2 * math.pi
        elenco.append((0.0, c + r * math.cos(a), c + r * math.sin(a), rng.uniform(*dim), rng.random() * 2 * math.pi))
    # Rametti sottili, visibili tra le foglie.
    for punti in rami:
        d.line([(x * s, y * s) for x, y in punti[:-1]], fill=(70, 52, 36, 255), width=int(2.2 * s))
    # Prima le foglie interne (più scure), poi quelle esterne in luce.
    elenco.sort(key=lambda f: f[0] + rng.random() * 0.3)
    for t, fx, fy, l, aa in elenco:
        base = toni[int(rng.integers(len(toni)))]
        k = rng.uniform(0.88, 1.08) * (0.84 + 0.22 * t)
        foglia(d, fx, fy, l, aa, tuple(int(min(255, ch * k)) for ch in base), s)
    return img.resize((LATO, LATO), Image.LANCZOS)


# Una texture per specie: seme e toni delle foglie.
SPECIE_FOGLIE = {
    "foglie_quercia": (60, [(80, 106, 44), (92, 116, 50), (70, 96, 40)]),       # verde oliva profondo
    "foglie_carpino": (61, [(72, 124, 82), (84, 138, 92), (64, 112, 76)]),      # verde freddo
    "foglie_pioppo": (62, [(124, 146, 58), (138, 156, 64), (112, 136, 52)]),    # verde chiaro, quasi giallo
    "foglie_nocciolo": (63, [(88, 120, 54), (100, 130, 60), (78, 108, 48)]),    # arbusti, verde medio
    "foglie_autunno": (64, [(214, 160, 52), (226, 178, 64), (200, 128, 44), (190, 150, 54)]),  # acero in autunno
}


def _ciocca(d, rng, x0, y0, lung, larg, fili, scuro, chiaro, s, ang=0.0, curva=0.0, spessore=(1.2, 2.4)):
    """Una ciocca: un fascio di fili che parte stretto dalla radice (y0, in basso) e si apre verso
    la punta, scuro alla radice e chiaro in punta (la luce prende le punte)."""
    for _ in range(fili):
        off = rng.normal(0, larg * 0.22)
        punti = []
        segmenti = 6
        l = lung * rng.uniform(0.75, 1.0)
        for k in range(segmenti + 1):
            t = k / segmenti
            x = x0 + off * (0.35 + 0.65 * t) + math.sin(ang) * l * t + curva * l * t * t
            y = y0 - math.cos(ang) * l * t
            punti.append((x * s, y * s, t))
        w0 = rng.uniform(*spessore) * s
        for k in range(segmenti):
            w = max(1, int(w0 * (1.0 - 0.6 * punti[k][2])))
            t = punti[k][2]
            c = tuple(int(scuro[i] + (chiaro[i] - scuro[i]) * (t ** 0.8)) for i in range(3))
            d.line([punti[k][:2], punti[k + 1][:2]], fill=c + (255,), width=w)


def pelo():
    """Pelo degli animali (26/11/2026, sui riferimenti di Fede): ciocche fitte che scorrono lungo v
    (sul corpo, dal dorso verso la pancia), radici scure e punte chiare. Quasi grigio: il colore
    del manto sta nei vertici del modello."""
    rng = np.random.default_rng(60)
    s = 2
    img = Image.new("RGBA", (LATO * s, LATO * s), (138, 133, 126, 255))
    d = ImageDraw.Draw(img)
    for _ in range(4200):
        x, y = rng.random() * LATO, rng.random() * LATO
        lung = rng.uniform(30, 60)
        k = rng.uniform(0.85, 1.15)
        scuro = tuple(int(c * k) for c in (112, 107, 100))
        chiaro = tuple(int(min(255, c * k)) for c in (236, 230, 220))
        for ox in (-LATO, 0, LATO):
            for oy in (-LATO, 0, LATO):
                if -80 < x + ox < LATO + 80 and -20 < y + oy < LATO + 90:
                    _ciocca(d, np.random.default_rng(int(x * 1000 + y)), x + ox, y + oy, lung, rng.uniform(8, 16), 7, scuro, chiaro, s,
                            ang=rng.normal(0, 0.12), curva=rng.normal(0, 0.08))
    f = np.asarray(img.convert("RGB").resize((LATO, LATO), Image.LANCZOS)).astype(float) / 255
    lento = 0.9 + 0.15 * fbm(LATO, 4, 3, 61)[..., None]
    return np.clip(f * lento, 0, 1)


def lana():
    """Vello della pecora (26/11/2026): riccioli a spirale fitti, chiari in cima e scuri tra un
    bioccolo e l'altro. Come il pelo, quasi grigia: il colore è nei vertici."""
    rng = np.random.default_rng(62)
    s = 2
    img = Image.new("RGB", (LATO * s, LATO * s), (120, 116, 108))
    d = ImageDraw.Draw(img)
    for _ in range(6500):
        x, y = rng.random() * LATO, rng.random() * LATO
        r = rng.uniform(3.5, 8)
        k = rng.uniform(0.8, 1.12)
        col = tuple(int(min(255, c * k)) for c in (240, 235, 225))
        w = max(1, int(rng.uniform(1.0, 2.2) * s))
        a0 = rng.uniform(0, 360)
        for ox in (-LATO, 0, LATO):
            for oy in (-LATO, 0, LATO):
                cx, cy = x + ox, y + oy
                if -20 < cx < LATO + 20 and -20 < cy < LATO + 20:
                    for g, rr in ((0, r), (120, r * 0.62)):
                        d.arc([(cx - rr) * s, (cy - rr) * s, (cx + rr) * s, (cy + rr) * s], a0 + g, a0 + g + 250, fill=col, width=w)
    f = np.asarray(img.resize((LATO, LATO), Image.LANCZOS)).astype(float) / 255
    bioccoli = 0.78 + 0.3 * fbm(LATO, 16, 2, 63)[..., None]
    return np.clip(f * bioccoli, 0, 1)


def ciocche():
    """Carte di pelo per la sagoma degli animali (26/11/2026), come le foglie degli alberi: quattro
    ciocche affiancate (una per colonna da 128 px), radice in basso e punta in alto, con l'alfa
    per il ritaglio."""
    rng = np.random.default_rng(64)
    s = 2
    w, h = 512, 512
    img = Image.new("RGBA", (w * s, h * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k in range(4):
        cx = 64 + k * 128
        for _ in range(16):
            _ciocca(d, rng, cx + rng.normal(0, 7), h - 4, h * rng.uniform(0.6, 0.97), 50, 14, (120, 114, 106), (240, 234, 224), s,
                    ang=rng.normal(0, 0.07), curva=rng.normal(0, 0.07), spessore=(2.5, 4.5))
    img = img.resize((w, h), Image.LANCZOS)
    return img


def ciocche_lana():
    """Carte di lana per la pecora (26/11/2026): quattro bioccoli arricciati con l'alfa, uno per
    colonna da 128 px."""
    rng = np.random.default_rng(65)
    s = 2
    w, h = 512, 512
    img = Image.new("RGBA", (w * s, h * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k in range(4):
        cx = 64 + k * 128
        for _ in range(140):
            a = rng.uniform(0, 2 * math.pi)
            rad = 46 * math.sqrt(rng.random())
            x = cx + math.cos(a) * rad
            y = h * 0.5 + math.sin(a) * rad * 3.2
            r = rng.uniform(6, 14)
            t = 1.0 - (y / h)
            kk = rng.uniform(0.75, 1.05) * (0.7 + 0.3 * t)
            col = tuple(int(min(255, c * kk)) for c in (242, 237, 226)) + (255,)
            a0 = rng.uniform(0, 360)
            for g, rr in ((0, r), (110, r * 0.6), (220, r * 0.3)):
                d.arc([(x - rr) * s, (y - rr) * s, (x + rr) * s, (y + rr) * s], a0 + g, a0 + g + 260, fill=col, width=int(3.2 * s))
    return img.resize((w, h), Image.LANCZOS)


TEXTURE_ANIMALI = [("pelo", pelo), ("lana", lana)]
TEXTURE_CIOCCHE = [("ciocche", ciocche), ("ciocche_lana", ciocche_lana)]


def main(uscita):
    os.makedirs(uscita, exist_ok=True)
    for nome, fn in [("paglia", paglia), ("argilla", argilla), ("legno", legno), ("corteccia", corteccia),
                     ("pietra", pietra), ("erba", erba), ("erba_secca", erba_secca), ("macchie", macchie)] + TEXTURE_ANIMALI:
        salva(fn(), os.path.join(uscita, nome + ".png"))
    for nome, fn in TEXTURE_CIOCCHE:
        fn().save(os.path.join(uscita, nome + ".png"))
    for nome, (seme, toni) in SPECIE_FOGLIE.items():
        foglie(seme, toni).save(os.path.join(uscita, nome + ".png"))
    print("Texture scritte in", uscita)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[2] == "animali":
        # Solo le texture degli animali, senza riscrivere le altre.
        for nome, fn in TEXTURE_ANIMALI:
            salva(fn(), os.path.join(sys.argv[1], nome + ".png"))
        for nome, fn in TEXTURE_CIOCCHE:
            fn().save(os.path.join(sys.argv[1], nome + ".png"))
    else:
        main(sys.argv[1] if len(sys.argv) > 1 else "gioco/asset/texture")
