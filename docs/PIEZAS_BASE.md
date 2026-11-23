# Piezas base de Misión Helio-3

Estas piezas ya están hechas y probadas. **Úsalas para armar tu nivel** sin programar.
Se arrastran desde el panel *Sistema de archivos* hasta tu escena.

## Cómo hacer tu nivel

1. En *Sistema de archivos*, clic derecho en `scenes/niveles/plantilla_luna.tscn` → **Duplicar…**
2. Ponle tu nombre: `nivel_tunombre.tscn` y ábrelo.
3. Mueve, agrega o quita piezas. Presiona **F6** para probar **solo tu escena**.
4. Guarda (Cmd+S / Ctrl+S) → GitHub Desktop → **Commit** → **Push**.

> No edites las plantillas ni las piezas de las carpetas `scenes/objetos`, `scenes/ui`, `scenes/nave` ni `player`.
> Si las cambias, cambian en **todos** los niveles del equipo. Si quieres algo distinto, pídeselo al líder del equipo.

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
| Jugador | `player/player.tscn` | El astronauta en primera persona | `speed` (velocidad) |
| HUD | `scenes/ui/hud.tscn` | Muestra combustible, energía, regolito y helio-3 | `mostrar_mira` |
| Gravedad | `scenes/objetos/zona_gravedad.tscn` | Gravedad dentro de la caja | `gravedad`: Luna 1.62, Tierra 9.8 |
| Roca de regolito | `scenes/objetos/deposito_regolito.tscn` | Con **E** se excava y da regolito | `excavaciones`, `regolito_por_excavacion` |
| Extractor | `scenes/objetos/extractor_helio.tscn` | Con **E** calienta regolito y da helio-3 | `regolito_necesario`, `helio3_por_carga` |
| Reactor | `scenes/objetos/reactor.tscn` | Con **E** usa helio-3 y recarga la energía | `helio3_necesario` |
| Salida | `scenes/objetos/salida_nivel.tscn` | Al pisarla, pasa al siguiente nivel | `siguiente_nivel`, `helio3_necesario`, `necesita_energia_llena` |
| Nave | `scenes/nave/nave.tscn` | Módulo de aterrizaje: aterriza suave y derecho | `empuje`, `consumo`, `velocidad_segura`, `siguiente_nivel` |
| Vehículo extractor | `scenes/objetos/ExtractorHelio3/vehiculo_extractor.tscn` | Con **E** te subes y lo manejas con la cámara detrás (W/S, A/D, mouse). Si su rueda toca una roca minable, excava regolito | `velocidad_maxima`, `distancia_camara`; en el nodo `Excavadora`: `capacidad`, `regolito_por_roca` |
| Procesador de helio-3 | `scenes/objetos/procesador_helio.tscn` | Ponlo alrededor de un reactor. Si llegas con regolito, lo pinta, lo hace brillar y saca cápsulas de helio-3 (3 regolito = 1 cápsula) | `reactor` (elige el modelo), `regolito_por_helio`, `colores_reactor` |
| Cápsula de helio-3 | `scenes/objetos/capsula_helio3.tscn` | Al tocarla (a pie o en el vehículo) se recoge: +1 helio-3 | — |
| Carga de la nave | `scenes/objetos/carga_nave.tscn` | Ponla alrededor de la nave. Al llegar con cápsulas, se cargan en la nave | `helio3_necesario`, `siguiente_nivel` |

### Planta de helio-3 (etapas 3 a 7 del proceso real)

En la escena Cami la estación lunar funciona como planta. El reactor ya no hace las cápsulas solo:
el vehículo deja el regolito en la **tolva** y el jugador sigue las etapas en consolas con **E**.

| Etapa | Dónde | Qué hace el jugador |
|---|---|---|
| 3. Clasificación | Laboratorio | Malla del tamiz en 150 µm o menos + separadores magnético y electrostático |
| 4. Calentamiento | Reactor | Temperatura entre 700 y 1.000 °C y fuente de energía |
| 5. Captura de gases | Depósitos | Filtrar, comprimir y enfriar, en ese orden (se guarda el hidrógeno) |
| 6. Separación isotópica | Núcleo | 5 etapas de destilación criogénica hasta 99,9 % de helio-3 |
| 7. Almacenamiento | Esclusa | Llenar las cápsulas entre 150 y 300 bar; salen frente a la esclusa |

Piezas: `scripts/planta_helio.gd` (lleva la cuenta), `scripts/consola_planta.gd` (cada consola),
`scripts/estacion_planta.gd` (va en la estación: le pone choques y crea las consolas) y
`scripts/procesador_helio.gd` con su campo `planta`.

### Escalera de la plataforma

`scripts/nave_en_plataforma.gd` crea una escalera de 4 tramos junto a la torre (`scripts/escalera_plataforma.gd`).
Se puede subir caminando. Con **E** al pie (cuando la nave ya está cargada) se ve al astronauta subir en tercera
persona y entrar a la nave; al alunizar se le ve bajar. Si el astronauta trae animaciones llamadas
`caminar`, `subir_escaleras`, `bajar_escaleras` y `quieto` (por ejemplo de Mixamo), se usan solas.

**Rocas que se pueden excavar:** selecciona la roca → pestaña **Nodo** → **Grupos** → escribe `roca_minable` → **Añadir**.

Para hacer otro vehículo: copia `vehiculo_extractor.tscn` y cambia el modelo dentro de `Modelo`.
Mueve los puntos de `Excavadora/Cinta` para cambiar por dónde sube el material.

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
