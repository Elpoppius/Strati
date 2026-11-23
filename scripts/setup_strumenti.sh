#!/bin/sh
# Installa Godot 4.7.2 (senza grafica) e Blender 5.3 (come modulo Python) nell'ambiente di lavoro di Claude.
# Uso: sh setup_strumenti.sh   (circa 2-3 minuti)
set -e
BASE="$HOME/tools"
mkdir -p "$BASE/godot" "$HOME/bin"

# Godot 4.7.2, versione ufficiale da GitHub
if [ ! -x "$BASE/godot/Godot_v4.7.2-stable_linux.x86_64" ]; then
  curl -sSL -o /tmp/godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
  unzip -oq /tmp/godot.zip -d "$BASE/godot"
fi
ln -sf "$BASE/godot/Godot_v4.7.2-stable_linux.x86_64" "$HOME/bin/godot"

# Blender 5.3 come modulo Python (bpy), in un ambiente separato
pip install --break-system-packages -q uv
if [ ! -x "$BASE/blender-venv/bin/python" ]; then
  uv venv -q "$BASE/blender-venv" -p 3.13
fi
uv pip install -q --python "$BASE/blender-venv/bin/python" bpy==5.3.0
printf '#!/bin/sh\nexec %s/blender-venv/bin/python "$@"\n' "$BASE" > "$HOME/bin/blender-py"
chmod +x "$HOME/bin/blender-py"

"$HOME/bin/godot" --headless --version
"$HOME/bin/blender-py" -c "import bpy; print('Blender', bpy.app.version_string)"
