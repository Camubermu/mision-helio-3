# Misión Helio-3

Juego para el NASA Space Apps Challenge 2026, hecho en Godot 4 (GDScript).

## Historia

Un astronauta construye su cohete en la Tierra para viajar a la Luna e investigar el helio-3, un gas que el viento solar ha depositado durante miles de millones de años en el suelo lunar y que podría ser combustible para la energía de fusión del futuro.

El plan es despegar con motores de combustible químico y, ya en el espacio, encender el motor de plasma para probar su viabilidad en viajes largos. Sin embargo, en pleno trayecto se presenta una falla en el reactor que lo alimenta y la nave se queda sin energía eléctrica. Esto obliga al astronauta a dirigirse a la Luna y alunizar de emergencia con el poco combustible químico que le queda.

Para sobrevivir y volver a la Tierra, debe explorar la superficie, excavar regolito y calentarlo para extraer el helio-3. Con ese mismo recurso recarga el reactor y repara el motor de plasma. Al final despega de la Luna y regresa sano y salvo a la Tierra con las muestras, demostrando que el helio-3 podría ser una fuente de energía para la humanidad.

> Nota: los reactores de fusión con helio-3 todavía no existen; en el juego es tecnología del futuro.

## Cómo abrir el proyecto

1. Instala **Godot 4** (versión estándar, no .NET). Todo el equipo debe usar **la misma versión**: ver `docs/VERSION.md`.
2. Clona el repo:
   ```
   git clone https://github.com/Camubermu/mision-helio-3.git
   ```
3. Abre Godot → **Import** → selecciona el archivo `project.godot` de esta carpeta → **Import & Edit**.
4. (Opcional) VS Code: instala la extensión recomendada **godot-tools** y configura Godot en *Editor Settings → Text Editor → External*.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `scenes/niveles/` | Una escena por nivel |
| `scenes/ui/` | Menús, HUD, pantallas de historia |
| `scripts/` | Scripts GDScript compartidos |
| `assets/` | Sprites, audio y fuentes |
| `docs/` | Guion, notas y versión de Godot |

## Reglas para trabajar en equipo

- **Haz `git pull` antes de empezar** y haz commits pequeños y seguidos.
- **Cada persona trabaja en su propia escena.** Dos personas editando el mismo `.tscn` a la vez generan conflictos difíciles de resolver.
- No subas la carpeta `.godot/` (ya está en `.gitignore`).
- Nombres de archivos en `snake_case`: `nivel_aterrizaje.tscn`, `rover.gd`.
