# Mission Helium-3

Game for the NASA Space Apps Challenge 2026, made with Godot 4 (GDScript).

## Story

An astronaut builds a rocket on Earth to travel to the Moon and research helium-3, a gas that the solar wind has been depositing in the lunar soil for billions of years and that could be fuel for the fusion energy of the future.

The plan is to launch with chemical-fuel engines and, once in space, switch on the plasma engine to test whether it works for long trips. However, halfway through the trip the reactor that powers it fails and the ship runs out of electrical power. This forces the astronaut to head to the Moon and make an emergency landing with the little chemical fuel left.

To survive and return to Earth, the astronaut must explore the surface, dig regolith and heat it to extract helium-3. With that same resource the astronaut refuels the reactor and repairs the plasma engine. In the end the ship lifts off from the Moon and returns safely to Earth with the samples, showing that helium-3 could be an energy source for humanity.

> Note: helium-3 fusion reactors do not exist yet; in the game they are future technology.

## How to open the project

1. Install **Godot 4** (standard version, not .NET). The whole team must use **the same version**: see `docs/VERSION.md`.
2. Clone the repo:
   ```
   git clone https://github.com/Camubermu/mision-helio-3.git
   ```
3. Open Godot → **Import** → select the `project.godot` file in this folder → **Import & Edit**.
4. (Optional) VS Code: install the recommended **godot-tools** extension and set Godot in *Editor Settings → Text Editor → External*.

## Structure

| Folder | Contents |
| --- | --- |
| `scenes/niveles/` | One scene per level |
| `scenes/ui/` | Menus, HUD, story screens |
| `scripts/` | Shared GDScript scripts |
| `assets/` | Sprites, audio and fonts |
| `docs/` | Script, notes and Godot version |

## Rules for teamwork

- **Run `git pull` before you start** and make small, frequent commits.
- **Each person works in their own scene.** Two people editing the same `.tscn` at the same time create conflicts that are hard to fix.
- Do not upload the `.godot/` folder (it is already in `.gitignore`).
- File names in `snake_case`: `nivel_aterrizaje.tscn`, `rover.gd`.
