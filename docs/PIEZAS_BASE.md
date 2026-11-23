# Mission Helium-3 base pieces

These pieces are already built and tested. **Use them to build your level** without programming.
Drag them from the *FileSystem* panel into your scene.

## How to make your level

1. In *FileSystem*, right-click `scenes/niveles/plantilla_luna.tscn` → **Duplicate…**
2. Give it your name: `nivel_yourname.tscn` and open it.
3. Move, add or remove pieces. Press **F6** to test **only your scene**.
4. Save (Cmd+S / Ctrl+S) → GitHub Desktop → **Commit** → **Push**.

> Do not edit the templates or the pieces in the `scenes/objetos`, `scenes/ui`, `scenes/nave` or `player` folders.
> If you change them, they change in **every** level of the team. If you want something different, ask the team leader.

To move, rotate or resize a piece, select it and use the tools at the top
(**W** move, **E** rotate, **R** scale), or change the numbers in the **Inspector**.

## Game controls

| Key | What it does |
| --- | --- |
| W A S D | Walk (or tilt the ship) |
| Mouse | Look around |
| E | Use the object near you |
| Space | Ship thruster |
| R | Restart the level |

## The pieces

| Piece | File | What it does | What you can change in the Inspector |
| --- | --- | --- | --- |
| Player | `player/player.tscn` | The first-person astronaut | `speed` |
| HUD | `scenes/ui/hud.tscn` | Shows fuel, energy, regolith and helium-3 | `mostrar_mira` |
| Gravity | `scenes/objetos/zona_gravedad.tscn` | Gravity inside the box | `gravedad`: Moon 1.62, Earth 9.8 |
| Regolith rock | `scenes/objetos/deposito_regolito.tscn` | Dig it with **E** to get regolith | `excavaciones`, `regolito_por_excavacion` |
| Extractor | `scenes/objetos/extractor_helio.tscn` | With **E** it heats regolith and gives helium-3 | `regolito_necesario`, `helio3_por_carga` |
| Reactor | `scenes/objetos/reactor.tscn` | With **E** it uses helium-3 and refills energy | `helio3_necesario` |
| Exit | `scenes/objetos/salida_nivel.tscn` | Stepping on it goes to the next level | `siguiente_nivel`, `helio3_necesario`, `necesita_energia_llena` |
| Ship | `scenes/nave/nave.tscn` | Landing module: lands softly and straight | `empuje`, `consumo`, `velocidad_segura`, `siguiente_nivel` |
| Mining rover | `scenes/objetos/ExtractorHelio3/vehiculo_extractor.tscn` | Get in with **E** and drive it with the camera behind (W/S, A/D, mouse). If its wheel touches a minable rock, it digs regolith | `velocidad_maxima`, `distancia_camara`; in the `Excavadora` node: `capacidad`, `regolito_por_roca` |
| Helium-3 processor | `scenes/objetos/procesador_helio.tscn` | Place it around a reactor. If you arrive with regolith, it paints it, makes it glow and produces helium-3 capsules (3 regolith = 1 capsule) | `reactor` (choose the model), `regolito_por_helio`, `colores_reactor` |
| Helium-3 capsule | `scenes/objetos/capsula_helio3.tscn` | Touching it (on foot or in the rover) collects it: +1 helium-3 | — |
| Ship loading | `scenes/objetos/carga_nave.tscn` | Place it around the ship. When you arrive with capsules, they are loaded into the ship | `helio3_necesario`, `siguiente_nivel` |

### Helium-3 plant (stages 3 to 7 of the real process)

In the Cami scene the lunar station works as a plant. The reactor no longer makes the capsules by itself:
the rover drops the regolith in the **hopper** and the player follows the stages on consoles with **E**.

| Stage | Where | What the player does |
|---|---|---|
| 3. Beneficiation | Laboratory | Sieve mesh at 150 µm or less + magnetic and electrostatic separators |
| 4. Heating | Reactor | Temperature between 700 and 1,000 °C and an energy source |
| 5. Gas capture | Tanks | Filter, compress and cool, in that order (the hydrogen is saved) |
| 6. Isotope separation | Core | 5 cryogenic distillation stages up to 99.9% helium-3 |
| 7. Storage | Airlock | Fill the capsules between 150 and 300 bar; they come out in front of the airlock |

Pieces: `scripts/planta_helio.gd` (keeps count), `scripts/consola_planta.gd` (each console),
`scripts/estacion_planta.gd` (goes on the station: adds collisions and creates the consoles) and
`scripts/procesador_helio.gd` with its `planta` field.

### Platform stairs

`scripts/nave_en_plataforma.gd` creates a 4-flight staircase next to the tower (`scripts/escalera_plataforma.gd`).
You can walk up it. With **E** at the bottom (when the ship is already loaded) you see the astronaut climb in third
person and enter the ship; after the Moon landing you see the astronaut climb down. If the astronaut has animations named
`caminar`, `subir_escaleras`, `bajar_escaleras` and `quieto` (for example from Mixamo), they are used automatically.

**Rocks that can be dug:** select the rock → **Node** tab → **Groups** → type `roca_minable` → **Add**.

To make another vehicle: copy `vehiculo_extractor.tscn` and change the model inside `Modelo`.
Move the points of `Excavadora/Cinta` to change where the material goes up.

**Every level needs:** a floor, a HUD, a Gravity zone and a Player (or a Ship).

## The two templates

- `scenes/niveles/plantilla_luna.tscn`: lunar surface. Dig 3 rocks → extractor → 1 helium-3 → reactor → exit.
- `scenes/niveles/plantilla_alunizaje.tscn`: the ship falls from 40 m. Use Space to brake and land on the orange pad.

## For programmers

Data shared between levels is in `scripts/juego.gd` (used as `Juego` from any script):

```gdscript
Juego.agregar_regolito(1)
Juego.usar_helio3(3)          # returns false if there is not enough
Juego.gastar_combustible(5.0)
Juego.mostrar_mensaje("Hello!")
Juego.cambiar_nivel("res://scenes/niveles/nivel_luna.tscn")
```

To make a new object that is used with **E**, create a script that starts with `extends Interactuable`
and write what happens in `func interactuar() -> void:`. See `scripts/extractor_helio.gd` as an example.
