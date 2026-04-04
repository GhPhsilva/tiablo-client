# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

This is **OtClientV8** — a Tibia game client desktop application. The core engine is written in C++, but all game logic, UI, and configuration is done in **Lua** with a custom **OTUI** markup system. There is no build process for the Lua/OTUI layer; files are interpreted at runtime. The C++ engine binaries (`otclient_dx.exe`, `otclient_gl.exe`, etc.) are pre-compiled.

## Primary Configuration

[init.lua](init.lua) is the entry point. Key values to change:

```lua
IP = "127.0.0.1"    -- game server address
VERSION = "1100"     -- protocol version (1100 = Tibia 13.20 sprites)
g_app.setName("Fazendo Tibia")
DEFAULT_LAYOUT = "retro"
ALLOW_CUSTOM_SERVERS = false
```

## Architecture

### Module Loading Order (init.lua)
1. **corelib** — Lua utilities (math, strings, tables, JSON, HTTP)
2. **Libraries (0–99)** — `g_modules.autoLoadModules(99)`
3. **gamelib** — Game classes (creature, player, protocol)
4. **Client (100–499)** — `g_modules.autoLoadModules(499)` + `client`
5. **Game (500–999)** — `g_modules.autoLoadModules(999)` + `game_interface`
6. **Mods (1000–9999)** — User mods

### Directory Layout

- [data/modules/](data/modules/) — All Lua modules. Each module has a `.otmod` manifest declaring its name, load order, and scripts.
- [data/modules/corelib/](data/modules/corelib/) — Core utilities available everywhere (HTTP, events, UI helpers)
- [data/modules/gamelib/](data/modules/gamelib/) — Game-specific classes (creature, player, market, protocol opcodes)
- [data/modules/game_*/](data/modules/) — Feature modules (battle, inventory, skills, minimap, bot, shop, etc.)
- [data/modules/client_*/](data/modules/) — Client UI modules (options, login screen, terminal, profiles)
- [data/styles/](data/styles/) — Global OTUI stylesheets
- [layouts/](layouts/) — Layout overrides. Files here shadow their counterpart under `/data`. E.g., `/layouts/retro/images/foo.png` overrides `/data/images/foo.png` when the retro layout is active. Do **not** create a layout named `default`.
- [mods/](mods/) — User-installed mods (load order 1000–9999)

### Module Manifest (`.otmod`)

Every module has an `.otmod` file that controls its lifecycle:

```lua
Module
  name: game_battle
  description: Battle list
  author: edubart
  version: 1
  load-priority: 10
  scripts: [ battle.lua ]
  @onLoad: init()
  @onUnload: terminate()
```

### OTUI Markup

UI files use `.otui`, an XML-like format. Stylesheets are separate `.otui` files under [data/styles/](data/styles/) and [layouts/](layouts/). Widgets reference styles by name.

### Event System

Lua modules communicate via signal/slot using `connect()` / `disconnect()`:

```lua
connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
connect(g_app, { onRun = startup, onExit = exit })
```

Global objects available everywhere: `g_game`, `g_app`, `g_window`, `g_settings`, `g_crypt`, `g_logger`, `g_resources`, `g_modules`, `g_configs`.

### HTTP API (corelib)

```lua
HTTP.get(url, callback)
HTTP.getJSON(url, callback)
HTTP.post(url, data, callback)
HTTP.postJSON(url, data, callback)
HTTP.download(url, file, callback)
```

### Settings Persistence

```lua
g_settings.get(key)
g_settings.set(key, value)
g_settings.save()
g_crypt.encrypt(data)   -- password encryption
g_crypt.genUUID()
```

### Services (init.lua)

The `Services` table in [init.lua](init.lua) enables optional features:

```lua
Services = {
  crash = "https://...",    -- enables crash_reporter module
  updater = "https://...",  -- enables updater module (requires data.zip)
}
```

## Hot Reload

While the client is running: **Ctrl+Shift+R** reloads all Lua modules without restarting.

## Custom Inventory Slots

This client extends the standard Tibia inventory with custom slots. Slot constants are defined in [`data/modules/gamelib/player.lua`](data/modules/gamelib/player.lua):

| Constant | Value | Notes |
|---|---|---|
| `InventorySlotHead` | 1 | |
| `InventorySlotNeck` | 2 | |
| `InventorySlotBack` | 3 | |
| `InventorySlotBody` | 4 | |
| `InventorySlotRight` | 5 | |
| `InventorySlotLeft` | 6 | |
| `InventorySlotLeg` | 7 | |
| `InventorySlotFeet` | 8 | |
| `InventorySlotFinger` | 9 | |
| `InventorySlotAmmo` | 10 | |
| `InventorySlotPurse` | 11 | |
| `InventorySlotBelt` | 12 | **Custom** — not in standard Tibia |
| `InventorySlotLast` | 12 | Upper bound for slot iteration |

The `BeltSlot` UI widget (`id: slot12`, `&position: {x=65535, y=12, z=0}`) is defined in both:
- [`data/styles/40-inventory.otui`](data/styles/40-inventory.otui)
- [`layouts/retro/styles/40-inventory.otui`](layouts/retro/styles/40-inventory.otui)

Slot images live in [`data/images/game/slots/`](data/images/game/slots/) (`belt.png`, `belt-blessed.png`).

The `InventorySlotStyles` map in [`data/modules/game_inventory/inventory.lua`](data/modules/game_inventory/inventory.lua) must be updated whenever a new slot is added.

## Localization

Language files are under [data/locales/](data/locales/) (de, en, es, pl, pt, sv). Strings are referenced via `tr("key")`.
