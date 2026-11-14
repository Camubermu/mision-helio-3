# Piezas base de Misión Helio-3

Estas piezas ya están hechas y probadas. **Úsalas para armar tu nivel** sin programar.
Se arrastran desde el panel *Sistema de archivos* hasta tu escena.

## Cómo hacer tu nivel

1. En *Sistema de archivos*, clic derecho en `scenes/niveles/plantilla_luna.tscn` → **Duplicar…**
2. Ponle tu nombre: `nivel_tunombre.tscn` y ábrelo.
3. Mueve, agrega o quita piezas. Presiona **F6** para probar **solo tu escena**.
4. Guarda (Cmd+S / Ctrl+S) → GitHub Desktop → **Commit** → **Push**.

> No edites las plantillas ni las piezas de las carpetas `scenes/objetos`, `scenes/ui`, `scenes/nave` ni `player`.
> Si las cambias, cambian en **todos** los niveles del equipo. Si quieres algo distinto, pídeselo a Camilo.

Para mover, girar o cambiar el tamaño de una pieza, selecciónala y usa las herramientas de arriba
(**W** mover, **E** girar, **R** escalar), o cambia los números en el **Inspector**.

## Controles del juego

| Tecla | Qué hace |
| --- | --- |
| W A S D | Caminar (o inclinar la nave) |
| Mouse | Mirar alrededor |
| E | Usar el objeto que tienes cerca |
| Espacio | Propulsor de la nave |
| R | Reiniciar el nivel |

## Las piezas

| Pieza | Archivo | Qué hace | Lo que puedes cambiar en el Inspector |
| --- | --- | --- | --- |
| Jugador | `player/player.tscn` | El astronauta en primera persona (hecho por JustPatrox) | `speed` (velocidad) |
| HUD | `scenes/ui/hud.tscn` | Muestra combustible, energía, regolito y helio-3 | `mostrar_mira` |
| Gravedad | `scenes/objetos/zona_gravedad.tscn` | Gravedad dentro de la caja | `gravedad`: Luna 1.62, Tierra 9.8 |
| Roca de regolito | `scenes/objetos/deposito_regolito.tscn` | Con **E** se excava y da regolito | `excavaciones`, `regolito_por_excavacion` |
| Extractor | `scenes/objetos/extractor_helio.tscn` | Con **E** calienta regolito y da helio-3 | `regolito_necesario`, `helio3_por_carga` |
| Reactor | `scenes/objetos/reactor.tscn` | Con **E** usa helio-3 y recarga la energía | `helio3_necesario` |
| Salida | `scenes/objetos/salida_nivel.tscn` | Al pisarla, pasa al siguiente nivel | `siguiente_nivel`, `helio3_necesario`, `necesita_energia_llena` |
| Nave | `scenes/nave/nave.tscn` | Módulo de aterrizaje: aterriza suave y derecho | `empuje`, `consumo`, `velocidad_segura`, `siguiente_nivel` |

**Todo nivel necesita:** un suelo, un HUD, una Zona de gravedad y un Jugador (o una Nave).

## Las dos plantillas

- `scenes/niveles/plantilla_luna.tscn`: superficie lunar. Excava 3 rocas → extractor → 1 helio-3 → reactor → salida.
- `scenes/niveles/plantilla_alunizaje.tscn`: la nave cae desde 40 m. Usa Espacio para frenar y aterriza en la plataforma naranja.

## Para programadores

Los datos que se comparten entre niveles están en `scripts/juego.gd` (se usa como `Juego` desde cualquier script):

```gdscript
Juego.agregar_regolito(1)
Juego.usar_helio3(3)          # devuelve false si no alcanza
Juego.gastar_combustible(5.0)
Juego.mostrar_mensaje("¡Hola!")
Juego.cambiar_nivel("res://scenes/niveles/nivel_luna.tscn")
```

Para hacer un objeto nuevo que se use con **E**, crea un script que empiece con `extends Interactuable`
y escribe qué pasa en `func interactuar() -> void:`. Mira `scripts/extractor_helio.gd` como ejemplo.
