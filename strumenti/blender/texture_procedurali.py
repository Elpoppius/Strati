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
    # Fili di paglia lungo la verticale (che sul tetto corre lungo la falda).
    fibre = rumore_anisotropo(LATO, 160, 6, 1) * 0.6 + rumore_anisotropo(LATO, 64, 3, 2) * 0.4
    macchie = fbm(LATO, 4, 4, 3)
    campo = 0.62 + 0.55 * fibre
    # Corsi di paglia sovrapposti: bande orizzontali più scure alla base di ogni corso.
    y = (np.arange(LATO)[:, None] / LATO * 6 + rumore_anisotropo(LATO, 8, 4, 4) * 0.4) % 1.0
    corsi = 0.78 + 0.22 * np.clip(y * 1.6, 0, 1)
    grande = 0.85 + 0.3 * fbm(LATO, 2, 3, 5)
    campo = campo * corsi * grande
    base = np.array([0.70, 0.55, 0.31])
    img = colore(base, campo)
    # Invecchiamento: zone ingrigite e più scure.
    grigio = np.array([0.50, 0.45, 0.36])
    peso = np.clip((macchie - 0.55) * 2.0, 0, 0.4)[..., None]
    return img * (1 - peso) + colore(grigio, campo) * peso


def argilla():
    n = fbm(LATO, 4, 6, 10)
    fine = fbm(LATO, 32, 3, 11)
    # Tracce dell'incannicciato sotto l'intonaco: righe orizzontali appena visibili.
    righe = 0.5 + 0.5 * np.sin(np.arange(LATO)[:, None] / LATO * 2 * math.pi * 14 + n * 3)
    campo = 0.78 + 0.3 * n + 0.12 * fine - 0.05 * righe
    chiare = np.clip((fbm(LATO, 3, 3, 12) - 0.55) * 2.5, 0, 0.35)[..., None]
    return colore(np.array([0.66, 0.50, 0.34]), campo) * (1 - chiare) + colore(np.array([0.78, 0.66, 0.50]), campo) * chiare


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


def main(uscita):
    os.makedirs(uscita, exist_ok=True)
    for nome, fn in [("paglia", paglia), ("argilla", argilla), ("legno", legno), ("corteccia", corteccia),
                     ("pietra", pietra), ("erba", erba), ("erba_secca", erba_secca), ("macchie", macchie)]:
        salva(fn(), os.path.join(uscita, nome + ".png"))
    for nome, (seme, toni) in SPECIE_FOGLIE.items():
        foglie(seme, toni).save(os.path.join(uscita, nome + ".png"))
    print("Texture scritte in", uscita)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "gioco/asset/texture")
