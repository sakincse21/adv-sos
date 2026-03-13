# Godot 3D Visualization — Detailed Code Documentation

This document explains every file in `ui/godot_project/`, the Godot 4 frontend that renders the AI match in 3D with animated Kaiju characters and a jungle environment.

---

## Architecture Overview

```
Godot Scene Tree:
Main (Node3D)
├── HttpClient (HTTPRequest)       → Polls Python API every 0.5s
├── BoardRenderer (Node3D)         → 3D board, characters, symbols, animations
├── JungleEnv (Node3D)             → Procedural trees and floor
├── Camera3D                       → Angled overhead camera
├── WorldEnvironment               → Fog, ambient light, background color
├── SunLight (DirectionalLight3D)  → Warm primary lighting
├── FillLight (DirectionalLight3D) → Cool secondary fill light
├── JungleFloor (CSGBox3D)         → 30×30 green ground plane
└── UI (CanvasLayer)
    └── AgentVisualizer (Control)  → 2D HUD overlay
```

---

## File: `project.godot` — Project Configuration

Standard Godot 4 config file. Key settings:
- **Project name:** `Advanced SOS Game 3D`
- **Main scene:** `res://main.tscn`
- **Renderer:** Forward Plus (Godot 4 default)

---

## File: `main.tscn` — Scene Definition

The `.tscn` file defines the complete scene graph in Godot's text-based scene format.

### Environment Settings

```
background_mode = 1               → Solid color background
background_color = (0.06, 0.12, 0.05)  → Very dark green
ambient_light_color = (0.3, 0.45, 0.25) → Green ambient tint
fog_enabled = true
fog_light_color = (0.25, 0.4, 0.2)     → Green fog
fog_density = 0.012                      → Subtle depth fog
```

### Camera

```
transform = Transform3D(1, 0, 0, 0, 0.6, 0.8, 0, -0.8, 0.6, 3.5, 10, 10)
fov = 55.0
```

This places the camera at an overhead angle looking down at the board center `(3.5, 0, 3.5)`, with a 55° field of view for a focused view.

### Dual Lighting

| Light | Color | Energy | Purpose |
|-------|-------|--------|---------|
| SunLight | Warm white `(1, 0.95, 0.8)` | 1.2 | Primary sun — casts shadows |
| FillLight | Cool blue `(0.6, 0.75, 0.9)` | 0.4 | Secondary fill — softens shadows |

---

## File: `board_renderer.gd` — Board, Characters, and Animations

This is the largest and most complex script (~500 lines). It handles:

### 1. Board Construction

```gdscript
# Base platform (dark wood)
CSGBox3D: size=(8.6, 0.3, 8.6)

# Tile grid (8×8 checkerboard)
for r in range(8):
    for c in range(8):
        CSGBox3D: size=(0.92, 0.12, 0.92)
        # Alternating cream/brown colors
```

Each tile is tracked in a `tiles[r][c]` dictionary with:
- `node` — the CSGBox3D tile mesh
- `symbol` — current value (0=EMPTY, 1=S, 2=O, 3=X)
- `piece` — the 3D symbol mesh placed on top

### 2. King Kong Model (Player 1) 🦍

Built from **~15 CSG primitives**:

| Part | Shape | Color | Position |
|------|-------|-------|----------|
| Torso | Box 0.7×0.8×0.5 | Dark brown (0.22, 0.12, 0.06) | y=0.9 |
| Belly patch | Box 0.35×0.35 | Light brown (0.35, 0.22, 0.12) | Front center |
| Head | Sphere r=0.28 | Dark brown | y=1.55 |
| Eyes (×2) | Sphere r=0.06 | White + emission | y=1.60 |
| Pupils (×2) | Sphere r=0.03 | Nearly black | Slightly in front of eyes |
| Mouth | Box 0.18×0.06 | Dark red | y=1.42 |
| Arms (×2) | Cylinder r=0.12 | Brown | Angled ±20° |
| Fists (×2) | Sphere r=0.13 | Brown | End of arms |
| Legs (×2) | Cylinder r=0.14 | Dark brown | y=0.25 |
| Name label | Label3D "KING KONG" | Gold | Billboard, y=2.0 |

### 3. Godzilla Model (Player 2) 🦎

Built from **~20 CSG primitives**:

| Part | Shape | Color | Special |
|------|-------|-------|---------|
| Body | Box 0.6×0.9×0.7 | Dark green (0.15, 0.28, 0.12) | — |
| Underbelly | Box 0.3×0.5 | Light green | Front face |
| Head | Box 0.35×0.3×0.45 | Green | Blocky reptilian |
| Snout | Box 0.22×0.15×0.25 | Green | Extends forward |
| Jaw | Box 0.20×0.06 | Dark red | Below snout |
| Eyes (×2) | Sphere r=0.05 | Orange | **Glowing emission ×2.0** |
| Dorsal spines (×5) | Polygon3D | Silver-blue | **Blue emission glow** |
| Arms (×2) | Cylinder r=0.08 | Green | Small, angled ±35° |
| Legs (×2) | Cylinder r=0.15 | Dark green | Thick |
| Tail (×4 segments) | Cylinder | Green | Tapers, extends backward |
| Name label | Label3D "GODZILLA" | Green | Billboard, y=2.1 |

### 4. Animation System

**State sync approach:** No animation queue. Each API poll delivers the latest `last_move`. The renderer compares it (via `str()`) to the previously animated move. If different → trigger animation. This eliminates desync issues.

**Three animation types:**

#### S/O Placement — Gentle Stomp
```
1. Walk to tile (0.55s, CUBIC ease)
2. Lift up 0.35 units (0.12s)
3. Bounce down (0.15s, BOUNCE ease)
4. Pause 0.25s
5. Walk home (0.55s, CUBIC ease)
```

#### X Placement — Thunder Bolt ⚡
```
1. Walk to tile (0.55s, CUBIC ease)
2. Rise up 0.6 units — power charge (0.25s, BACK ease)
3. Hold 0.2s
4. Stomp down (0.15s, QUAD ease)
5. Spawn lightning VFX at tile
6. Hold 0.6s (while bolt animates)
7. Walk home (0.55s)
```

**Lightning bolt VFX (`_spawn_thunder_bolt`):**
- Main beam: `CSGCylinder3D`, height=8.0, yellow emission ×5.0, semi-transparent
- Impact glow: `CSGSphere3D`, radius=0.5, gold emission ×4.0
- Forked bolts (×3): thin cylinders at various angles, blue-white emission
- Animation: scale 0.3→1.0 (flash in 0.08s), hold 0.35s, scale→0 (fade 0.2s), then `queue_free()`

#### Skip/Force — Head Nod "No" 🙅
```
1. Walk to tile (0.55s, CUBIC ease)
2. Pause 0.15s
3. Rotate Y: 0° → +25° → -25° → +20° → -18° → 0°
   (SINE ease, ~1 second total)
4. Pause 0.15s
5. Walk home (0.55s)
```

### 5. Symbol Spawning

| Symbol | Shape | Appearance | Animation |
|--------|-------|------------|-----------|
| **S** | `Label3D` | Blue text, font_size=80 | Drop from y=2.0, bounce |
| **O** | `CSGTorus3D` | Red, metallic | Drop from y=2.0, bounce |
| **X** | `Label3D` | Gold with dark red outline | Scale from 0.01→1.0, elastic ease (appears at ground level — "scorched" by thunder) |

---

## File: `jungle_environment.gd` — Procedural Jungle

### Ground Floor
Applies a green material (`Color(0.18, 0.35, 0.12)`) to the `JungleFloor` CSGBox3D defined in the scene.

### Tree Generation

Uses a **seeded RNG** (`seed = 42`) for deterministic tree placement:

1. **Ring trees (20):** Placed in a circle around the board at radius 7–13 units
2. **Scattered trees (up to 8):** Random positions, skipped if too close to the board

Each tree consists of:
- **Trunk:** `CSGCylinder3D`, height 2.5–5.0, radius 0.12–0.22, brown with roughness=0.85
- **Canopy (2–3):** `CSGSphere3D`, radius 0.8–1.8, positioned near trunk top, varying greens

---

## File: `agent_visualizer.gd` — HUD Overlay

### UI Layout

| Panel | Position | Content |
|-------|----------|---------|
| Log panel (top-left) | (12, 12), 320×200 | Semi-transparent black, rounded corners, RichTextLabel with BBCode |
| Stats panel (left) | (12, 225), 320×160 | Score display with player names |
| Button panel (right) | Right edge, 230px wide | 4 styled buttons |

### Buttons

| Button | Action |
|--------|--------|
| `Minimax vs MCTS` | POST `/api/start` with `{agent1: "minimax", agent2: "mcts"}` |
| `MCTS vs MCTS` | POST `/api/start` with `{agent1: "mcts", agent2: "mcts"}` |
| `Minimax vs Minimax` | POST `/api/start` with `{agent1: "minimax", agent2: "minimax"}` |
| `Pause / Resume` | POST `/api/pause` |

### Live Updates

Every state poll updates:
- **Logs:** Last 5 move history entries with BBCode coloring
- **Scores:** "KING KONG (P1): X" and "GODZILLA (P2): Y"
- **Turn indicator:** Shows whose turn it is when the match is running

---

## File: `http_client.gd` — API Communication

### Polling

```gdscript
func _poll():
    if polling:
        request(base_url + "/state")     # GET /api/state

func _on_request_completed(...):
    if response_code == 200:
        parse JSON → emit state_updated signal
    
    if polling:
        wait 0.5 seconds → _poll()      # Poll again after delay
```

**Polling interval:** 0.5 seconds. This balances responsiveness with avoiding state floods.

### Sending Commands

```gdscript
func send_command(endpoint, data={}):
    # Creates a temporary HTTPRequest node
    # Sends POST with JSON body
    # Auto-cleans up on completion
```

Used for `/start` and `/pause` endpoints.
