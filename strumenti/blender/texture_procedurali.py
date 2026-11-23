"""Genera texture procedurali ripetibili (tileable) per gli asset, senza scaricare nulla.

Uso:  python3 strumenti/blender/texture_procedurali.py gioco/asset/texture

Ogni texture è un PNG 512 x 512 in sRGB. Le foglie hanno il canale alfa (ritaglio).
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
    base = np.array([0.56, 0.46, 0.30])
    img = colore(base, campo)
    # Invecchiamento: zone ingrigite e più scure.
    grigio = np.array([0.42, 0.40, 0.36])
    peso = np.clip((macchie - 0.45) * 2.2, 0, 0.6)[..., None]
    return img * (1 - peso) + colore(grigio, campo) * peso


def argilla():
    n = fbm(LATO, 4, 6, 10)
    fine = fbm(LATO, 32, 3, 11)
    # Tracce dell'incannicciato sotto l'intonaco: righe orizzontali appena visibili.
    righe = 0.5 + 0.5 * np.sin(np.arange(LATO)[:, None] / LATO * 2 * math.pi * 14 + n * 3)
    campo = 0.78 + 0.3 * n + 0.12 * fine - 0.05 * righe
    return colore(np.array([0.55, 0.43, 0.31]), campo)


def legno():
    venature = rumore_anisotropo(LATO, 48, 4, 20)
    n = fbm(LATO, 8, 3, 21)
    campo = 0.7 + 0.4 * venature + 0.15 * n
    return colore(np.array([0.40, 0.30, 0.20]), campo)


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


def erba():
    n = fbm(LATO, 4, 5, 50)
    fine = np.random.default_rng(51).random((LATO, LATO))
    campo = 0.75 + 0.3 * n + 0.1 * fine
    terra = np.clip((fbm(LATO, 3, 3, 52) - 0.68) * 2, 0, 0.35)[..., None]
    return colore(np.array([0.36, 0.44, 0.22]), campo) * (1 - terra) + colore(np.array([0.42, 0.34, 0.24]), campo) * terra


def foglie(seme=60):
    """Ciuffo di foglie con trasparenza, per le carte di fogliame degli alberi."""
    rng = np.random.default_rng(seme)
    img = Image.new("RGBA", (LATO, LATO), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Più ciuffi sovrapposti, per un contorno irregolare e non circolare.
    centri = [(LATO / 2 + rng.uniform(-0.18, 0.18) * LATO, LATO / 2 + rng.uniform(-0.18, 0.18) * LATO, rng.uniform(0.18, 0.3) * LATO)
              for _ in range(5)]
    for _ in range(1600):
        ccx, ccy, rr = centri[rng.integers(len(centri))]
        r = rng.random() ** 0.7 * rr
        a = rng.random() * 2 * math.pi
        cx = ccx + r * math.cos(a); cy = ccy + r * math.sin(a)
        lung = 9 + rng.random() * 9; larg = lung * 0.45
        ang = rng.random() * math.pi
        luce = 0.75 + 0.45 * rng.random() - 0.25 * (r / rr)
        col = (int(62 * luce), int(86 * luce), int(38 * luce), 255)
        pts = []
        for k in range(10):
            t = k / 10 * 2 * math.pi
            px = lung * math.cos(t); py = larg * math.sin(t) * (1 - 0.3 * math.cos(t))
            pts.append((cx + px * math.cos(ang) - py * math.sin(ang), cy + px * math.sin(ang) + py * math.cos(ang)))
        d.polygon(pts, fill=col)
    return img


def main(uscita):
    os.makedirs(uscita, exist_ok=True)
    for nome, fn in [("paglia", paglia), ("argilla", argilla), ("legno", legno), ("corteccia", corteccia),
                     ("pietra", pietra), ("erba", erba)]:
        salva(fn(), os.path.join(uscita, nome + ".png"))
    foglie().save(os.path.join(uscita, "foglie.png"))
    print("Texture scritte in", uscita)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "gioco/asset/texture")
