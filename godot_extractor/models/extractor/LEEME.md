# Cosechadora lunar de Helio-3 — Godot 4

Carpeta: `res://models/extractor/`

| Archivo | Para qué sirve |
|---|---|
| `cosechadora_helio3_lunar.glb` | Modelo 3D (≈3.800 triángulos) con 4 animaciones incluidas |
| `extractor.tscn` | **Escena lista para usar.** Es la que arrastras a tu juego |
| `extractor.gd` | Script de control (`class_name Extractor`): mueve la máquina y elige la animación |

En la raíz del proyecto hay además `demo.tscn` + `demo.gd`: una escena jugable de prueba.

---

## 1. Probarlo en 1 minuto

1. Abre **Godot 4.2 o superior** → *Importar* → elige `project.godot` de esta carpeta.
2. La primera vez Godot importa el `.glb` (unos segundos). Si al abrir ves algún error rojo por la escena,
   cierra el proyecto y vuelve a abrirlo: es porque la importación aún no había terminado.
3. Pulsa **F5**. Se ejecuta `demo.tscn`.

### Controles de la demo

| Tecla | Acción |
|---|---|
| `W` / ↑ | Avanzar |
| `S` / ↓ | Retroceder |
| `A` `D` / ← → | Girar (solo mientras avanza o retrocede) |
| `Espacio` | Activar / desactivar la minería |
| Arrastrar ratón | Orbitar la cámara |
| Rueda del ratón | Acercar / alejar |

---

## 2. Las animaciones

Todas duran 6 s y se repiten sin cortes (el script les activa el bucle automáticamente).

| Animación | Qué mueve | Cuándo se usa |
|---|---|---|
| `reposo` | Solo el espejo concentrador (balanceo suave) | Quieta y sin minar |
| `avanzar` | Zapatas de ambas orugas recorriendo la banda, 10 ruedas, espejo | Avanzando |
| `minar` | Rueda de cangilones, tambor calentador, tacos de la cinta transportadora, espejo | Quieta minando |
| `avanzar_minando` | Todo lo anterior a la vez | Avanzando y minando |

**Marcha atrás:** no hay animación aparte; el script reproduce `avanzar` con velocidad negativa.

**Sin patinar:** un ciclo de oruga equivale a 4,178 m de avance en 6 s → **0,696 m/s**.
El script ajusta `speed_scale` según la propiedad `velocidad`, así que si la cambias las orugas siguen
cuadrando con el suelo.

---

## 3. Usarla en tu propio proyecto

1. Copia la carpeta `models/extractor/` a tu proyecto (mantén la ruta o ajusta las rutas internas del `.tscn`).
2. Arrastra `extractor.tscn` a tu escena, o instáncialo por código:

```gdscript
var ext: Extractor = load("res://models/extractor/extractor.tscn").instantiate()
add_child(ext)
ext.global_position = Vector3(0, 0, 0)

ext.mover(1)          # avanzar     (-1 retroceder, 0 parar)
ext.girar(1.0)        # girar a la izquierda (-1 derecha), solo si se mueve
ext.minando = true    # activa rueda de cangilones + tambor + cinta
ext.velocidad = 1.5   # m/s (las orugas se acompasan solas)
ext.detener()

ext.animacion_cambiada.connect(func(nombre): print("Ahora suena: ", nombre))
```

### Propiedades exportadas (Inspector)

- `velocidad` — m/s de avance (por defecto 0,696).
- `velocidad_giro` — rad/s al girar (por defecto 0,35).
- `minando` — interruptor de la minería.

### Orientación

El GLB tiene el frente de la máquina en **+Z** (como exige glTF). Godot usa **-Z** como "adelante",
así que `extractor.tscn` ya incluye el nodo `Modelo` girado 180° en Y. Por eso, desde tu código,
**el frente de `Extractor` es `-global_transform.basis.z`**, igual que cualquier otro nodo de Godot
(`look_at()` funciona como esperas).

### Con colisiones y física

`Extractor` se mueve solo en su `_physics_process`. Si prefieres un `CharacterBody3D`:
desactiva ese movimiento y deja al script solo las animaciones.

```gdscript
extends CharacterBody3D            # nodo padre; "Extractor" es hijo suyo
@onready var ext: Extractor = $Extractor

func _ready() -> void:
	ext.set_physics_process(false)      # el script ya no mueve; solo anima

func _physics_process(delta: float) -> void:
	var f := Input.get_axis("ui_down", "ui_up")
	var g := Input.get_axis("ui_right", "ui_left")
	ext.mover(int(signf(f)))
	ext.girar(g)
	rotate_y(g * ext.velocidad_giro * delta * absf(f))
	velocity = -global_transform.basis.z * f * ext.velocidad
	move_and_slide()
```

Añade un `CollisionShape3D` hijo del `CharacterBody3D` (una caja ≈ 7,4 × 2 × 12,7 m, centrada en y = 1 m).

### Reproducir una animación a mano (sin el script)

```gdscript
var player: AnimationPlayer = ext.find_child("AnimationPlayer", true, false)
player.get_animation("avanzar").loop_mode = Animation.LOOP_LINEAR
player.play("avanzar_minando")
```

---

## 4. Partes del modelo (nodos con nombre)

Puedes engancharte a cualquiera con `ext.find_child("Nombre", true, false)`:

`Chasis`, `Oruga_Izquierda`, `Oruga_Derecha`, `Modulo_Electronico`, `Tanques_Helio3`, `Radiadores`,
`Panel_Solar`, `Sensores_Antena`, `Brazo_Excavador`, `Tolva_Cinta`,
**animadas:** `Rueda_Cangilones` (pivote en su eje), `Tambor_Calentador` (pivote en su eje),
`Espejo` (pivote en la punta del mástil), `Rueda_Motriz_*`, `Rueda_Apoyo_*`, `Zapata_*` (48), `Taco_Cinta_*` (12).

Ideas: `Brazo_Excavador` y `Rueda_Cangilones` son buen punto para lanzar partículas de polvo;
`Tanques_Helio3` para un indicador de carga de He-3.

Materiales (PBR): `casco`, `oro`, `metal`, `solar`, `marco`, `radiador`, `oscuro`, `detalle`,
`amarillo`, `oruga`, `espejo`. Para cambiar un color: doble clic en `cosechadora_helio3_lunar.glb` →
*Nuevo escena heredada*, o en *Importar → Materiales → Extraer*.

---

## 5. Problemas frecuentes

- **No se mueve ninguna animación:** selecciona el `.glb` en el panel *Sistema de archivos* → pestaña
  *Importar* → comprueba que está activo *Animation → Import* y pulsa *Reimportar*.
- **Error "no se encontró un AnimationPlayer":** el `.glb` no terminó de importarse; reimporta.
- **La máquina avanza hacia atrás:** estás instanciando el `.glb` directamente en vez de `extractor.tscn`
  (el GLB mira a +Z). Usa siempre `extractor.tscn`.
- **Las orugas "patinan":** no cambies `AnimationPlayer.speed_scale` a mano; usa `ext.velocidad`.

## 6. Datos técnicos

- Unidades: metros. Y arriba. Tamaño ≈ 7,4 m ancho × 12,7 m largo × 8 m alto.
- Ciclo de animación: 6 s; las zapatas siguen el recorrido real de la banda (tramos rectos + arcos sobre las ruedas).
- Rueda de cangilones: ½ vuelta por ciclo; tambor: ⅓ de vuelta por ciclo; cinta: 0,2 m/s.
