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

## Custom Skills

This client extends the standard Tibia skill set. Skill constants are defined in [`data/modules/gamelib/const.lua`](data/modules/gamelib/const.lua):

| Constant | Value | Notes |
|---|---|---|
| `Skill.Fist` | 0 | |
| `Skill.Club` | 1 | |
| `Skill.Sword` | 2 | |
| `Skill.Axe` | 3 | |
| `Skill.Distance` | 4 | |
| `Skill.Shielding` | 5 | |
| `Skill.Fishing` | 6 | |
| `Skill.CriticalChance` | 7 | Additional skill |
| `Skill.CriticalDamage` | 8 | Additional skill |
| `Skill.LifeLeechChance` | 9 | Additional skill |
| `Skill.LifeLeechAmount` | 10 | Additional skill |
| `Skill.ManaLeechChance` | 11 | Additional skill |
| `Skill.ManaLeechAmount` | 12 | Additional skill |
| `Skill.AttackSpeed` | 13 | **Custom** — not in standard Tibia binary protocol |

### Attack Speed Skill

`Skill.AttackSpeed` (13) is not transmitted via the standard binary protocol. Its value is delivered via **extended opcode 101** (`ATTACK_SPEED_OPCODE`) in [`data/modules/game_skills/skills.lua`](data/modules/game_skills/skills.lua).

- The server sends a raw numeric string; the client parses it and displays `value / 10` as `"%.2f%%"`.
- The UI widget is `skillId13` ("Bonus Attack Speed") in [`data/modules/game_skills/skills.otui`](data/modules/game_skills/skills.otui).
- In `refresh()`, `Skill.AttackSpeed` is **skipped** intentionally to avoid overwriting the opcode-provided value with `0`. This is the correct pattern for any skill whose value arrives out-of-band.
- `refresh()` also sends a `'request'` payload on opcode 101 after game start so the server pushes the current value.

### Skill Display Formatting

`onSkillChange` in `skills.lua` applies special formatting based on skill id:

| Skills | Format |
|---|---|
| `CriticalChance`, `CriticalDamage`, `LifeLeechAmount`, `ManaLeechAmount` | `level / 100` → `"%.2f%%"` |
| `LifeLeechChance`, `ManaLeechChance`, `AttackSpeed` | `level / 10` → `"%.2f%%"` |
| All others | raw integer |

## Extended Opcodes (Client ↔ Server)

Extended opcodes require `GameExtendedOpcode` to be enabled in `data/modules/game_features/features.lua`:

```lua
g_game.enableFeature(GameExtendedOpcode)
```

### Receiving from Server

Register a callback via `ProtocolGame.registerExtendedOpcode` in `init()`. The callback receives the raw buffer string including its prefix character.

```lua
ProtocolGame.registerExtendedOpcode(100, onMyData)

function onMyData(protocol, opcode, buffer)
    local jsonStr = buffer:sub(2)  -- strip "O" prefix
    local ok, data = pcall(function() return json.decode(jsonStr) end)
    if not ok or type(data) ~= 'table' then return end
    -- use data
end
```

Always unregister in `terminate()`:

```lua
ProtocolGame.unregisterExtendedOpcode(100)
```

**`registerExtendedOpcode` throws if opcode already taken.** The `unregisterExtendedOpcode` also throws if not registered. If there's a risk of partial cleanup (e.g., during reload), use `pcall`.

### Sending to Server

```lua
local protocolGame = g_game.getProtocolGame()
if protocolGame then
    protocolGame:sendExtendedOpcode(100, '{"action":"teleport","waypoint_id":1}')
end
```

### Timing: Request Pattern (Critical)

Server opcodes sent during login arrive **before modules finish reloading**. Never rely on the server pushing data on login. Instead, the client must request data after `onGameStart`:

```lua
function init()
    ProtocolGame.registerExtendedOpcode(MY_OPCODE, onData)
    connect(g_game, { onGameStart = requestData, onGameEnd = onGameEnd })
    if g_game.isOnline() then  -- handles Ctrl+Shift+R reload while in-game
        requestData()
    end
end

function requestData()
    local pg = g_game.getProtocolGame()
    if pg then pg:sendExtendedOpcode(MY_OPCODE, '{"action":"request"}') end
end
```

## UI Patterns

### Centered Dialog vs Side Panel

- **Side panel** (MiniWindow): use `g_ui.loadUI('file', modules.game_interface.getRightPanel())`
- **Centered dialog** (like prey/hotkeys): use `g_ui.displayUI('file')` with `MainWindow` in the `.otui`

With `displayUI`, call `window:hide()` right after creation and show/hide manually.

### `getChildById` is NOT Recursive in MiniWindow

`MiniWindow` wraps its content inside `MiniWindowContents`, which is always accessible as `contentsPanel`. Navigate explicitly:

```lua
-- WRONG: returns nil
waypointList = window:getChildById('waypointList')

-- CORRECT: go through contentsPanel first
local contents = window:getChildById('contentsPanel')
waypointList = contents:getChildById('waypointList')
```

For `MainWindow` (used with `displayUI`), `getChildById` finds direct children and works for flat layouts.

### TextList API

`TextList` does **not** have `addItem()` or `clearItems()`. The correct API:

```lua
-- Clear
list:destroyChildren()

-- Add item (define a style in .otui first)
local label = g_ui.createWidget('MyListLabel', list)
label:setText('Item name')
label:setId('item_123')

-- Get selected item
local selected = list:getFocusedChild()  -- NOT getFocusedItem()
```

### List Item Style Template

```otui
MyListLabel < Label
  font: verdana-11px-monochrome
  background-color: alpha
  text-offset: 2 0
  focusable: true

  $focus:
    background-color: #ffffff22
    color: #ffffff
```

### Dynamic Tabs (TabBar)

Use `TabBar` (horizontal) from `data/styles/20-tabbars.otui`. Tabs and their panels are managed automatically. To use tabs for filtering (without separate panels per tab), skip `setContentWidget` and hook `onTabChange`:

```lua
tabBar.onTabChange = function(tabBar, tab)
    filterList(tab:getText())
end

-- Add tab dynamically
tabBar:addTab('Category Name')  -- auto-sizes button width to text
```

**Always clear tabs before rebuilding** (e.g., on reconnect) — the TabBar accumulates tabs otherwise:

```lua
local function clearTabs()
    tabBar.currentTab = nil      -- prevent selectTab from touching a destroyed widget
    local tabs = tabBar.tabs
    tabBar.tabs = {}
    for _, t in ipairs(tabs) do
        t:destroy()              -- tab.onDestroy also destroys t.tabPanel
    end
end
```

Call `clearTabs()` in `onGameEnd` and at the start of every data refresh.

### Child Focus Change

```lua
list.onChildFocusChange = function(list, child)
    if child and child.someData then
        label:setText(child.someData.description)
    end
end
```

### Image Source

```lua
widget:setImageSource('/images/mypath/name')  -- no .png extension needed
-- check existence before setting:
if g_resources.fileExists('/images/mypath/name.png') then
    widget:setImageSource('/images/mypath/name')
end
```

### Double-Click on Widget

```lua
item.onDoubleClick = function()
    doSomething()
    return true  -- consume event
end
```

## Localization

Language files are under [data/locales/](data/locales/) (de, en, es, pl, pt, sv). Strings are referenced via `tr("key")`.
