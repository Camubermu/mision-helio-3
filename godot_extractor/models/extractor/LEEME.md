# Lunar Helium-3 harvester — Godot 4

Folder: `res://models/extractor/`

| File | What it is for |
|---|---|
| `cosechadora_helio3_lunar.glb` | 3D model (≈3,800 triangles) with 4 built-in animations |
| `extractor.tscn` | **Ready-to-use scene.** This is the one you drag into your game |
| `extractor.gd` | Control script (`class_name Extractor`): moves the machine and picks the animation |

The project root also has `demo.tscn` + `demo.gd`: a playable test scene.

---

## 1. Try it in 1 minute

1. Open **Godot 4.2 or later** → *Import* → choose `project.godot` in this folder.
2. The first time, Godot imports the `.glb` (a few seconds). If you see a red error about the scene when opening,
   close the project and open it again: the import had not finished yet.
3. Press **F5**. `demo.tscn` runs.

### Demo controls

| Key | Action |
|---|---|
| `W` / ↑ | Move forward |
| `S` / ↓ | Move backward |
| `A` `D` / ← → | Turn (only while moving forward or backward) |
| `Space` | Turn mining on / off |
| Drag mouse | Orbit the camera |
| Mouse wheel | Zoom in / out |

---

## 2. The animations

All last 6 s and loop seamlessly (the script turns on looping automatically).

| Animation | What moves | When it is used |
|---|---|---|
| `reposo` | Only the concentrator mirror (gentle sway) | Idle and not mining |
| `avanzar` | Shoes of both tracks running along the belt, 10 wheels, mirror | Moving forward |
| `minar` | Bucket wheel, heating drum, conveyor belt cleats, mirror | Idle and mining |
| `avanzar_minando` | All of the above at once | Moving and mining |

**Reverse:** there is no separate animation; the script plays `avanzar` with negative speed.

**No slipping:** one track cycle equals 4.178 m of travel in 6 s → **0.696 m/s**.
The script adjusts `speed_scale` from the `velocidad` property, so if you change it the tracks still
match the ground.

---

## 3. Using it in your own project

1. Copy the `models/extractor/` folder into your project (keep the path or adjust the internal paths of the `.tscn`).
2. Drag `extractor.tscn` into your scene, or instance it from code:

```gdscript
var ext: Extractor = load("res://models/extractor/extractor.tscn").instantiate()
add_child(ext)
ext.global_position = Vector3(0, 0, 0)

ext.mover(1)          # move forward  (-1 backward, 0 stop)
ext.girar(1.0)        # turn left (-1 right), only while moving
ext.minando = true    # turns on bucket wheel + drum + belt
ext.velocidad = 1.5   # m/s (the tracks keep pace automatically)
ext.detener()

ext.animacion_cambiada.connect(func(nombre): print("Now playing: ", nombre))
```

### Exported properties (Inspector)

- `velocidad` — forward speed in m/s (default 0.696).
- `velocidad_giro` — rad/s when turning (default 0.35).
- `minando` — mining switch.

### Orientation

The GLB has the front of the machine on **+Z** (as glTF requires). Godot uses **-Z** as "forward",
so `extractor.tscn` already includes the `Modelo` node rotated 180° on Y. That is why, from your code,
**the front of `Extractor` is `-global_transform.basis.z`**, like any other Godot node
(`look_at()` works as you expect).

### With collisions and physics

`Extractor` moves by itself in its `_physics_process`. If you prefer a `CharacterBody3D`:
turn off that movement and leave only the animations to the script.

```gdscript
extends CharacterBody3D            # parent node; "Extractor" is its child
@onready var ext: Extractor = $Extractor

func _ready() -> void:
	ext.set_physics_process(false)      # the script no longer moves; it only animates

func _physics_process(delta: float) -> void:
	var f := Input.get_axis("ui_down", "ui_up")
	var g := Input.get_axis("ui_right", "ui_left")
	ext.mover(int(signf(f)))
	ext.girar(g)
	rotate_y(g * ext.velocidad_giro * delta * absf(f))
	velocity = -global_transform.basis.z * f * ext.velocidad
	move_and_slide()
```

Add a `CollisionShape3D` as a child of the `CharacterBody3D` (a box ≈ 7.4 × 2 × 12.7 m, centered at y = 1 m).

### Playing an animation by hand (without the script)

```gdscript
var player: AnimationPlayer = ext.find_child("AnimationPlayer", true, false)
player.get_animation("avanzar").loop_mode = Animation.LOOP_LINEAR
player.play("avanzar_minando")
```

---

## 4. Model parts (named nodes)

You can hook into any of them with `ext.find_child("Name", true, false)`:

`Chasis`, `Oruga_Izquierda`, `Oruga_Derecha`, `Modulo_Electronico`, `Tanques_Helio3`, `Radiadores`,
`Panel_Solar`, `Sensores_Antena`, `Brazo_Excavador`, `Tolva_Cinta`,
**animated:** `Rueda_Cangilones` (pivot on its axis), `Tambor_Calentador` (pivot on its axis),
`Espejo` (pivot at the tip of the mast), `Rueda_Motriz_*`, `Rueda_Apoyo_*`, `Zapata_*` (48), `Taco_Cinta_*` (12).

Ideas: `Brazo_Excavador` and `Rueda_Cangilones` are good points to emit dust particles;
`Tanques_Helio3` for a He-3 load indicator.

Materials (PBR): `casco`, `oro`, `metal`, `solar`, `marco`, `radiador`, `oscuro`, `detalle`,
`amarillo`, `oruga`, `espejo`. To change a color: double-click `cosechadora_helio3_lunar.glb` →
*New Inherited Scene*, or in *Import → Materials → Extract*.

---

## 5. Common problems

- **No animation moves:** select the `.glb` in the *FileSystem* panel → *Import* tab
  → check that *Animation → Import* is on and press *Reimport*.
- **Error "AnimationPlayer not found":** the `.glb` did not finish importing; reimport it.
- **The machine moves backward:** you are instancing the `.glb` directly instead of `extractor.tscn`
  (the GLB faces +Z). Always use `extractor.tscn`.
- **The tracks "slip":** do not change `AnimationPlayer.speed_scale` by hand; use `ext.velocidad`.

## 6. Technical data

- Units: meters. Y up. Size ≈ 7.4 m wide × 12.7 m long × 8 m high.
- Animation cycle: 6 s; the shoes follow the real path of the belt (straight sections + arcs over the wheels).
- Bucket wheel: ½ turn per cycle; drum: ⅓ turn per cycle; belt: 0.2 m/s.
