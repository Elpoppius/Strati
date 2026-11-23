"""Alberi da posare sulla mappa: varianti per specie, in versione completa e leggera.

Riusa il generatore della prova di stile (prova_stile_verosimile.py, funzione albero).
La versione completa si usa da vicino; quella leggera (poche carte grandi, senza rami)
a media distanza; da lontano il terreno dipinge la volta delle chiome.

Uso:  blender-py strumenti/blender/alberi_mappa.py gioco/asset/alberi

L'acero autunnale non c'è: le stagioni nel gioco non sono ancora decise e un acero
giallo in un bosco estivo stonerebbe.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prova_stile_verosimile as base  # noqa: E402  (legge la cartella d'uscita da sys.argv[1])
import bpy  # noqa: E402

USCITA = base.USCITA

# (specie, numero della variante, altezza in metri)
VARIANTI = [
    ("quercia", 1, 12.0), ("quercia", 2, 14.5), ("quercia", 3, 10.5),
    ("carpino", 1, 10.0), ("carpino", 2, 11.5),
    ("pioppo", 1, 16.0), ("pioppo", 2, 18.5),
    ("cespuglio", 1, 2.8), ("cespuglio", 2, 3.5),
]


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(USCITA, exist_ok=True)
    bpy.context.scene.world = bpy.data.worlds.new("Mondo")
    # Suolo temporaneo per l'occlusione alla base dei tronchi.
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    for i, (specie, n, alta) in enumerate(VARIANTI):
        seme = 100 + i * 7
        for leggero in (False, True):
            nome = f"{specie}_{n}" + ("_leggero" if leggero else "")
            ob = base.albero(nome, seme, alta, specie, leggero)
            base.cuoci_occlusione(ob, 0.5)
            base.occlusione_chioma(ob)
            base.esporta(ob, os.path.join(USCITA, nome + ".glb"))
            d = ob.dimensions
            print(f"{nome}: {d.x:.1f} x {d.y:.1f} x {d.z:.1f} m, {len(ob.data.polygons)} facce")
            bpy.data.objects.remove(ob, do_unlink=True)


if __name__ == "__main__":
    main()
