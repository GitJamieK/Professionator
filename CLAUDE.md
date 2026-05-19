# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Professionator is a World of Warcraft **Classic** addon (Interface 11508) that surfaces profession data — trainers, vendors, recipes — in a custom in-game UI. It is written in Lua + WoW's XML-less frame API and ships with the four standard Ace/BigWigs micro-libs (`LibStub`, `CallbackHandler-1.0`, `LibDataBroker-1.1`, `LibDBIcon-1.0`) under `Libs/`. **Only the First Aid profession is currently implemented**; the other 12 professions exist in `data/professions/prProfessionData.lua` but their trainer/vendor/recipe folders contain only `.gitkeep`.

## Running / testing

There is no build system, package manager, linter, or test suite. The addon is loaded directly by the WoW client.

- **Install for testing**: symlink or copy the repo into `<WoW>/_classic_era_/Interface/AddOns/Professionator` (or `_classic_` depending on the client flavor — the TOC targets Classic Era / Anniversary, `## Interface: 11508`).
- **Reload after edits**: run `/reload` in-game. New `.lua` files are *not* picked up by `/reload` alone — they must first be added to `Professionator.toc` (see below) and then the client restarted, otherwise WoW won't read them.
- **Open the UI**: `/professionator` (alias `/prof`). Subcommands: `toggle` (default), `open`/`show`, `close`/`hide`, `minimap`.
- **Saved variables**: `ProfessionatorDB` (declared in the TOC). Wiped by deleting `<WoW>/WTF/.../SavedVariables/Professionator.lua`.

## Architecture

### Initialization & namespace

Every file starts with `local _, ns = ...` to grab the **private addon namespace** that WoW passes as the second vararg. All cross-file communication happens by hanging tables off `ns` — there are no `require`s, no globals (other than the SLASH_* / SlashCmdList entries), and load order is dictated entirely by `Professionator.toc`.

Boot sequence (`core/prEvents.lua`):

1. `ADDON_LOADED` for our addon fires.
2. `ns:ApplyDefaults()` — merges `ns.defaults` into `ProfessionatorDB` (`core/prCore.lua`).
3. `ns.UI:Initialize()` — creates the main window (`ns.Window:Create`) and calls `ns.ProfessionMenu:Attach(window)` to mount the navigator onto `window.content`.
4. `ns.Minimap:Initialize()` — LibDBIcon button.
5. `ns:RegisterSlashCommands()`.

### TOC load order is load-bearing

`Professionator.toc` is the single source of truth for file load order, and the order matters because each file mutates `ns`:

- Libs first.
- `core/prCore.lua` (defines `ns`, defaults, helpers like `ns:GetBackdropTemplate`, `ns:Print`).
- `data/professions/prProfessionData.lua` (the 13 professions and `menuSections`; provides `ns.ProfessionData`).
- **`ui/professionMenu/categories/trainers/data/prProfessionTrainerData.lua` must load before any per-NPC trainer file**, because the NPC files call `TrainerData.RegisterTrainer(...)` at file scope.
- **Shared `teaches/` tables must load before the NPC files that reference them** (e.g. `prFirstAidTrainerTeaches.lua` before `prShainaFuller.lua`).
- UI base layer (`prUI.lua`, `prWindow.lua`) before menu shared (`prProfessionMenuShared.lua`) before menu core (`prProfessionMenuCore.lua`) before trainer category files.
- `core/prSlashCommands.lua` and `core/prEvents.lua` last so all subsystems exist before `ADDON_LOADED` fires.

When adding a new file, insert it in dependency order — a "file not found" or `attempt to index a nil value` at login is almost always a TOC ordering issue.

### Menu system

The navigator is a stack of slide-in views on a single `stage` frame:

- `ns.ProfessionMenu` (in `ui/professionMenu/prProfessionMenuCore.lua`) owns the stage, the root/professions/detail views, and the `TransitionTo(view, direction, name)` slide animation.
- Other view files (`prProfessionMenuTrainerMenuView.lua`, `…DetailView.lua`, `…TeachesView.lua`, `…ImagePreview.lua`) attach methods directly to `ProfessionMenu` (`function ProfessionMenu:CreateTrainerMenuView() ... end`). They are not separate objects.
- Categories register themselves with two hooks:
  - `ProfessionMenu:RegisterCategoryInitializer(fn)` — called from `Attach()` to build the category's views.
  - `ProfessionMenu:RegisterSectionHandler(sectionID, fn)` — called when the user clicks the matching action button on a profession's detail page.
  - Today only `trainers` is wired up (`ui/professionMenu/categories/trainers/prProfessionMenuTrainers.lua`). Adding `vendors` or `recipes` means creating a sibling folder and registering both hooks.
- View dimensions live in `Shared.WindowSizes` (`prProfessionMenuShared.lua`) and `Trainers.Constants` (`prProfessionMenuTrainerShared.lua`). The window auto-resizes per view via `ProfessionMenu:ResizeWindow(viewName)` → `ns.Window:ResizeTo`. New views should `Shared.RegisterWindowSize(name, w, h)` so the resize call works.

### Trainer data model

Trainer content is split into three layers:

1. **Per-NPC file** — `ui/professionMenu/categories/trainers/data/<profession>/<faction>/<slug>/pr<NpcName>.lua` calls `TrainerData.RegisterTrainer(professionID, factionID, { ... })` with fields like `npcID`, `name`, `area`, `zone`, `coords`, `targetImage`, `modelImage`, `mapImage`, and `teaches`. Image paths are produced by `TrainerData.AssetPath(profession, faction, slug, "target"|"model"|"map")` which resolves to `img/screenshots/trainers/<profession>/<faction>/<slug>/<type>.png`.
2. **Shared teaches table** — `data/<profession>/teaches/pr*Teaches.lua` returns the list of ranks/spells the trainer teaches. Multiple NPCs share the same table (e.g. `FirstAidTrainerTeaches` vs `FirstAidTraumaSurgeonTeaches`).
3. **Aggregation** — `RegisterTrainer` pushes into `ns.ProfessionData.trainerData[professionID][factionID]`, which is what the UI reads at runtime.

To add a trainer:
- Drop `target.png` / `model.png` / `map.png` into `img/screenshots/trainers/<profession>/<faction>/<slug>/`.
- Create the NPC file under the parallel `ui/.../data/<profession>/<faction>/<slug>/` folder.
- Add the file path to `Professionator.toc` **after** the relevant `teaches/` file.

### Profession registry

`data/professions/prProfessionData.lua` is the master list. Each profession has `id`, `name`, `group` (Crafting/Gathering/Secondary/Utility), `spellID` (used by `GetSpellTexture` for the in-game icon, with `icon` as fallback), and an `accent` RGB triple that drives UI tinting for that profession everywhere it appears. Adding a profession only requires editing this file — the menu list, detail view, and accent colors all read from here.

### Compatibility shims

`core/prCore.lua` wraps a few APIs that moved namespaces between WoW versions:

- `ns:GetBackdropTemplate()` returns `"BackdropTemplate"` when `BackdropTemplateMixin` exists (Shadowlands+ / modern Classic), otherwise `nil` — pass it to `CreateFrame` so backdrop-using frames work on older Classic builds.
- `ns:GetMetadata(field)` prefers `C_AddOns.GetAddOnMetadata` over the deprecated global.
- `Shared.ColorTexture` falls back from `SetColorTexture` to `SetTexture` for the same reason.

Preserve these patterns when adding new UI code; do not call the new APIs directly.
