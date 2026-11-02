# 🧊 CubeCraftPoly

A low-poly voxel survival game. Carve out a home in an endless blocky world, help the villagers who move in, tame a dog, a cat and a horse, and take down the four monster kings who rule the lands.

Built in **Godot 4.7** with **GDScript** and free CC0 low-poly art.

[![Download for Windows](https://img.shields.io/badge/Download-Windows-2ea44f?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/BroPilot-AI/CubeCraftPoly/releases/latest)
[![Made with Godot](https://img.shields.io/badge/Made%20with-Godot%204.7-478cbf?style=for-the-badge&logo=godotengine&logoColor=white)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

---

## ✨ Features

- **An endless world** — meadows, deserts and snowfields built chunk by chunk, hiding crystal caverns, brick ruins behind locked metal doors, old watchtowers with a chest on the roof, and abandoned mine tracks.
- **Survival or creative** — dig, mine, smelt ore in the furnace and build in survival, or build freely in creative.
- **A home that becomes a village** — villagers move in as you finish their quests, ask for daily trades, put bounties on monsters, hand out treasure maps, and want a well and a watchtower built.
- **Pets** — tame animals with Cheese: a **dog** that guards you, a **cat** that sniffs out chests, and a **horse** to ride.
- **Day, night and weather** — a sky dial for the time, rain, snow and thunderstorms, and a **Blood Moon** every few nights that turns the sky red and brings twice the monsters.
- **Goblin raids** — once your village grows, Goblins come for it at dawn.
- **Minecarts** — lay rails round corners and up slopes and ride them.
- **Four boss fights** — each king calls in waves of his own monsters, turns enraged in a second phase, and has attacks of his own.
- **The Wizard** — beat the first king and a Wizard moves in, selling legendary gear for Diamonds and Cheese.
- **Music made in code** — a gentle day tune, a slow night one, a harsh Blood Moon theme and a tense boss track that fade into each other.
- **Keyboard and mouse or gamepad** — Xbox and PlayStation pads work out of the box, the on-screen button pictures match whatever you're holding, and every control can be changed.

## 👑 The Kings

| Boss | Where | Calls in | Beating him gives |
|------|-------|----------|-------------------|
| 🧟 **The Zombie King** | Meadows | Zombies | **Regrowth** power (heals you) and brings the Wizard home |
| 😈 **The Demon Lord** | Deserts | Demons | **Fury** power (double damage) |
| 🧊 **The Frost Giant** | Snowfields | Yetis | **Frost** power (slows nearby monsters) |
| 💀 **The Skeleton King** | Your home, by a great crystal | Skeletons | Victory: he wakes at night once the last quest is done |

Powers are used with **R** and recharge after use.

## 🧙 The Wizard's Shop

| Item | What it does | Price | For sale after |
|------|--------------|-------|----------------|
| 🪶 **Feather Cloak** | Hold jump to glide, and falls never hurt you | 2 Diamonds + 5 Cheese | The Zombie King |
| 🔥 **Flame Blade** | Your sword's hits set monsters on fire | 4 Diamonds + 8 Cheese | The Demon Lord |
| 🐦‍🔥 **Phoenix Feather** | Once a day, rise again where you fall | 6 Diamonds + 12 Cheese | The Frost Giant |

## 🎮 Controls

| Action | Keyboard & mouse |
|--------|------------------|
| **Move** | W A S D |
| **Look** | Mouse |
| **Jump** | Space |
| **Sprint** | Shift |
| **Sneak** | Ctrl |
| **Break / hit** | Left click |
| **Place / use** | Right click |
| **Hotbar** | 1–9 or mouse wheel |
| **Backpack** | E |
| **Use power** | R |
| **Change view** | F5 |
| **Pause** | Esc |
| **Fullscreen** | F11 |

Every action has a gamepad button too, and all of them can be changed under **Settings → Controls**.

## 🚀 Play it

1. Grab **CubeCraftPoly-Windows.zip** from the **[latest release](https://github.com/BroPilot-AI/CubeCraftPoly/releases/latest)**.
2. Unzip it anywhere and run **CubeCraftPoly.exe**. Nothing to install.

Windows may show a SmartScreen warning because the exe isn't signed: click **More info**, then **Run anyway**.

## 🛠️ Running from source

1. Install **[Godot 4.7.2](https://godotengine.org/download)** (the standard build, not .NET).
2. Open `project.godot` in the Godot editor and press **F5**.

To build the exe, use **Project → Export → Windows Desktop**, or:

```
godot --headless --path . --export-release "Windows Desktop" build/CubeCraftPoly.exe
```

The `.godot/` import cache is rebuilt automatically on first open and is not tracked.

## 🎨 Credits & licensing

- **3D models and blocks** — [Cube World Kit](https://quaternius.com/packs/cubeworldkit.html) by Quaternius (CC0).
- **UI pieces** — [UI Pack 2.0](https://kenney.nl/assets/ui-pack) and [Input Prompts 1.5](https://kenney.nl/assets/input-prompts) by Kenney (CC0).
- **Font** — [Fredoka](https://github.com/hafontia/Fredoka-One), copyright 2016 The Fredoka Project Authors, under the SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
- **Godot logo** on the splash screen by Andrea Calabró, under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

**Code license:** [MIT](LICENSE). The assets in `assets/` keep their own licences, listed above.
**Engine:** made with [Godot Engine](https://godotengine.org), used under its MIT license. The release zip includes its licence text.
