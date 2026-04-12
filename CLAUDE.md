# CLAUDE.md

OtClientV8 — Tibia game client. Engine em C++ (pré-compilado), lógica em **Lua** + **OTUI**. Sem build para Lua/OTUI; arquivos interpretados em runtime.

## Arquivos-chave

| Arquivo | Função |
|---|---|
| [`init.lua`](init.lua) | Entry point — IP, VERSION, layout, Services |
| [`data/modules/gamelib/const.lua`](data/modules/gamelib/const.lua) | Constantes de skill (`Skill.*`) |
| [`data/modules/gamelib/player.lua`](data/modules/gamelib/player.lua) | Constantes de inventory slot (`InventorySlot*`) |
| [`data/modules/game_skills/skills.lua`](data/modules/game_skills/skills.lua) | UI de skills, opcodes, formatação |
| [`data/modules/game_skills/skills.otui`](data/modules/game_skills/skills.otui) | Widgets de skills |
| [`data/modules/game_inventory/inventory.lua`](data/modules/game_inventory/inventory.lua) | `InventorySlotStyles` map |
| [`data/modules/game_features/features.lua`](data/modules/game_features/features.lua) | `GameExtendedOpcode` e outros feature flags |
| [`data/modules/game_topbar/topbar.lua`](data/modules/game_topbar/topbar.lua) | TopBar (habilitado por padrão) |
| [`data/modules/client_entergame/entergame.lua`](data/modules/client_entergame/entergame.lua) | Login screen, música |
| [`data/styles/`](data/styles/) | Stylesheets OTUI globais |
| [`layouts/mobile/`](layouts/mobile/) | Overrides do layout mobile (ativo) |
| [`data/modules/`](data/modules/) | Todos os módulos Lua |

## Regras Críticas (Não Óbvias)

### Layout
- Layout **hardcoded para `"mobile"`** em `init.lua` — nunca restaurar o branch `settings:getValue('layout')`.
- ComboBox de layout em `client_options/interface.otui` permanece `visible: false`.

### Custom Skills
- `Skill.AttackSpeed` (13) chega via **extended opcode 101**, não pelo protocolo binário padrão.
- Em `refresh()`, `Skill.AttackSpeed` é **pulado intencionalmente** — não sobrescrever com 0.
- Formatação em `onSkillChange`: `CriticalChance/Damage`, `LifeLeech*` → `/ 100` → `"%.2f%%"`; `LifeLeechChance`, `ManaLeechChance`, `AttackSpeed` → `/ 10` → `"%.2f%%"`.

### Custom Inventory Slots
- Slots 12 (Belt) e 13 (Gloves) são customizados. Ao adicionar slot: atualizar as **3 OTUI files** de inventory + `InventorySlotStyles` + altura do `InventoryWindow`.
- Inventory OTUIs: [`data/styles/40-inventory.otui`](data/styles/40-inventory.otui), [`layouts/retro/styles/40-inventory.otui`](layouts/retro/styles/40-inventory.otui), [`layouts/mobile/styles/40-inventory.otui`](layouts/mobile/styles/40-inventory.otui).

### Extended Opcodes
- `registerExtendedOpcode` **lança erro** se opcode já registrado; `unregisterExtendedOpcode` lança se não registrado — usar `pcall` em reload.
- Nunca depender do servidor enviar dados no login — sempre usar padrão request/response em `onGameStart`.
- Buffer recebido tem prefixo `"O"` — fazer `buffer:sub(2)` antes de `json.decode`.

### UI
- `MiniWindow`: `getChildById` **não é recursivo** — navegar via `contentsPanel` explicitamente.
- `TextList`: sem `addItem()`/`clearItems()` — usar `destroyChildren()` e `g_ui.createWidget()`.
- `TabBar`: sempre limpar tabs antes de reconstruir (`tab:destroy()` em cada item).
- `displayUI` → `MainWindow` (dialog central); `loadUI(..., getRightPanel())` → `MiniWindow` (painel lateral).

### Login / Áudio
- `stopLoginMusic` deve chamar `channel:setEnabled(false)` **e** `channel:stop(0)` — só `stop()` não basta.
- Campo de token (`accountTokenTextEdit`) existe mas está oculto (`visible: false`, `height: 0`) — intencional.

## Hot Reload
**Ctrl+Shift+R** — recarrega todos os módulos Lua sem reiniciar o cliente.

## Related Projects

| Project | CLAUDE.md |
|---|---|
| Canary | `C:\Users\Pedro\Documents\tiablo\server\CLAUDE.md` |

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.
