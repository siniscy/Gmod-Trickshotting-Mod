<div align="center">

# 🎯 Gmod Trickshotting Mod

**Call of Duty–style trickshotting for Garry's Mod: final killcams, CoD HUDs, Sesh bot lobbies, instaswaps, wallbangs, and native controller support.**

![Garry's Mod](https://img.shields.io/badge/Garry's%20Mod-addon-1194f0?style=for-the-badge&logo=steam&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-GLua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![Controller](https://img.shields.io/badge/Controller-native%20support-107C10?style=for-the-badge&logo=xbox&logoColor=white)
![Status](https://img.shields.io/badge/status-active%20development-orange?style=for-the-badge)

*Hit the shot, watch it back in slow motion from your own eyes, and see your playercard come up, just like a CoD final killcam.*

</div>

---

## 📑 Contents

- [What it is](#-what-it-is)
- [Features](#-features)
- [Installation](#-installation)
- [Quick start](#-quick-start)
- [Controls & binds](#-controls--binds)
  - [Keyboard & mouse](#keyboard--mouse)
  - [Controller](#controller)
  - [Recommended autoexec](#recommended-autoexec)
- [Game modes](#-game-modes)
- [Trickshot mechanics](#-trickshot-mechanics)
- [The final killcam](#-the-final-killcam)
- [Console commands](#-console-commands)
- [ConVars reference](#%EF%B8%8F-convars-reference)
- [Project layout](#-project-layout)
- [Credits](#-credits)
- [Disclaimer](#%EF%B8%8F-disclaimer)

---

## 🧭 What it is

This addon turns a Garry's Mod listen server into a **CoD trickshotting lobby**. It bundles:

- a **CoD HUD** for six games (CoD4, WaW, MW2, MW3, BO1, BO2): killfeed, scorebar, medals, announcer, crosshair, scoreboard and lobby
- a **real final killcam** that replays the killer's actual first-person view
- **"Gmod Sesh" modes**: you (and your friends) against bots built for trickshot lobbies
- **trickshot quality-of-life**: instaswap, wallbang-everything, Fast Last, a knife on R3, CoD spawns and Create-a-Class loadouts
- **built-in controller support** tuned for spinning, without Steam Input key emulation

Everything is configured through an in-game **Private Match lobby** and the **CoD HUD Settings** menu. Every option is also a ConVar, so you can script it.

---

## ✨ Features

### 🎥 Final Killcam
- Archive-based, **the same model Call of Duty uses**: the server records every player, bot, NPC and projectile every tick, and each client records its **own exact first-person view**.
- On the winning kill, the window around the shot is cut from the archive and **played back locally on every client**: the killer's camera, viewmodel animation, iron sights, sway, recoil, scope overlay, muzzle flashes, bullets, sounds, hitmarkers and **physics ragdolls thrown by the real killing blow**.
- **Slow motion at the kill**, with configurable speed and hold.
- Reloads that start after the kill **finish on camera**.
- Bots and AI that get the final kill get a killcam too, seen through their eyes.
- **Custom playercards**: title, emblem, rank icon, level, clan tag and text (`kc_menu`).

### 🖥️ CoD HUD (six games)
- **CoD4 · World at War · MW2 · MW3 · Black Ops 1 · Black Ops 2** styles, with factions and announcer per game.
- Killfeed, scorebar, **kill medals**, XP popups, challenges, minimap, weapon info and compass, target ID, damage and grenade indicators, low-health blood and breathing, round start and round end screens, end-game music, scoreboard and chat.
- **Accurate crosshairs** ported from the games' own reticle code, driven by each game's real weapon spread data.
- **Final kill distance** readout.

### 🤖 Gmod Sesh modes
- **TDM, FFA, S&D and S&D Set** against `CreateNextBot` bots with navmesh pathing, jumping and ducking.
- Bots have **50 HP** (players have 100).
- In **S&D Set**, the host can **press L to move a bot to the crosshair** to set up a shot, and can turn on **God Mode** for their own team.

### 🔫 Trickshot mechanics
- **Instaswap**: the classic CoD quickswitch, built in (see [below](#-trickshot-mechanics)).
- **Wallbang everything**: every bullet from you and your team goes through walls and props. Bots never get it.
- **Fast Last**: after your first kill, the score jumps to one kill from the limit, so the next kill is the final killcam.
- **Create a Class**: six preset classes (BO2, MW3, BO1, MW2, WaW, MW1), a Custom class, or No Class. Press **K** mid-match to change it.
- **Knife on R3** for CoD4 Equipment weapons, plus a thrown knife and claymores.
- **CoD-style spawns**: you never spawn inside anyone, enemies spawn far away, and teammates spawn together.
- **Weapon dropping**, a global spread multiplier, explosive bullets (non-Sesh modes only), lerped viewmodels and a third-person hold-type fix.

### 🧰 SteezMod v1b (by reha), built in
- **Save / load position**: `savepos` saves your spot and `loadpos` teleports you back to it with your momentum cancelled, so you can run the same shot over and over. On a controller, `loadpos` is **RB**.
- **reha's MW2/MW3 snipers**: the Intervention in every attachment combo (ACOG, Thermal, heartbeat sensor, silencer), the L118A, the Barrett .50 Cal, plus the MW2 M4A1, the M9 and reha's gun, scoped, shotgun and grenade bases.
- **Floating hit damage numbers**, M9K-style C4 and grenades, and a **SteezMod** panel under Q-menu › Utilities with buttons for save/load position, the killcam menu, a killcam replay, an explosive bullets slider, and the Sleight of Hand, Reverse Reload and Cowboy toggles.

### 🎮 Native controller support
- Turn it on with `kc_controller 1`. The pad is read straight from GMod's input system, with **no emulated keyboard keys**, so the cursor never pops mid-spin.
- Look speed, response curve, deadzones, invert Y and a CoD sprint latch are all adjustable.
- `kc_controller_measure` copies the spin speed from any other setup.

---

## 📦 Installation

### Option A: full download (recommended)

1. Go to **[Releases](https://github.com/siniscy/Gmod-Trickshotting-Mod/releases/latest)** and download **`Gmod-Trickshotting-Mod.zip`** (about 1.1 GB). It contains everything: the Lua, the HUD art for all six games, the announcer and music, the killcam playercards, fonts, localization, and SteezMod's weapons.
2. Extract it into `<Steam>/steamapps/common/GarrysMod/garrysmod/addons/`, so you end up with `addons/Gmod-Trickshotting-Mod/lua`, `.../materials` and so on.
3. Restart Garry's Mod.

### Option B: clone the code (for developers)

The git repo holds the **Lua and localization only**. The `materials/`, `sound/`, `models/` and fonts are too big for git, so they only ship in the Release zip.

```bash
cd "<Steam>/steamapps/common/GarrysMod/garrysmod/addons"
git clone https://github.com/siniscy/Gmod-Trickshotting-Mod.git
```

Then copy `materials/`, `models/`, `sound/` and `resource/fonts/` from the Release zip into the cloned folder.

### Extra weapons (optional)

The Create a Class presets use these Workshop packs. Any weapon you have installed also appears in the class menu under **Other Installed Weapons**.

| Addon | Used for |
   |---|---|
| [Call of Duty 4: Equipment](https://steamcommunity.com/sharedfiles/filedetails/?id=528146710) | Knife, claymore and CoD4 equipment |
| [Call of Duty: Black Ops II Weapons Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=299164995) | BO2 weapons such as the DSR-50 and KAP-40 |
| Dread's and reha's CoD weapon packs | M4, MP5, Kar98k, Barrett, Intervention, MSR, Striker and SPAS-12 in the class menu |

### Running it

Start a **listen server** (Start New Game, with 2 or more player slots) on a map **with a navmesh** so the bots can path. Run `nav_generate` once on maps that don't have one.

> [!TIP]
> **Unsubscribe from or disable** the original *CoD HUD Collection* and *SteezMod* if you have them. Both are already built in, and keeping a second copy makes the two fight over the same `lua/codhud/` and weapon files.

---

## 🚀 Quick start

1. Load into a map. The **Private Match lobby** opens.
2. **Game Setup** (host only): choose the **HUD** (CoD4, WaW, MW2, MW3, BO1 or BO2), the **Gamemode** and the **Pregame Timer**, and tick **Fast Last**, **God Mode** or **Show Time Limit** if you want them.
3. **Create a Class**: pick a preset, build a Custom class, or choose No Class.
4. **Callsign**: set up the playercard shown in your killcam (title, emblem, rank, level, clan tag).
5. **Start Game**, hit your shot, and watch the final killcam.

> 💡 To practise a single shot, use **Gmod Sesh S&D Set** with **God Mode** on. Press **L** to drop the bot where you're aiming, then go for it.

---

## 🕹️ Controls & binds

### Keyboard & mouse

| Key / bind | Action | Notes |
|---|---|---|
| **K** | Open or close **Create a Class** | Works mid-match. Ignored while typing in chat or the console. |
| **L** | **Move a bot to your crosshair** | Host only, in **Sesh S&D Set**. Ignored while typing. |
| `invnext` / `invprev` (mouse wheel) | Cycle weapons | Skips the equipment slot, which is isolated. |
| `kc_equip` | Quick-switch to **equipment** | Also arms an **instaswap**. Bind it yourself (example below). |
| `+drop` | **Drop** the active weapon | Allowed when `sv_dropweapon_enablecommand 1`. |
| `kc_cod4_knife` | **Knife** with CoD4 Equipment weapons | Also on R3 for controllers. |
| `savepos` | **Save position** | Your trickshot spot |
| `loadpos` | **Load position** | Teleports you back and cancels your momentum. RB on controller. |
| `+alt2` / `+alt1` | Save / load position (alternate) | One saved spot shared by all players |
| `+showscores` (Tab) | CoD scoreboard | Scroll wheel scrolls the scoreboard. |
| `kc_classmenu` | Open Create a Class | Same as **K**. |
| `kc_menu` | Killcam **playercard** customizer | Also in the lobby under **Callsign**. |
| `codhud_openmenu` | **CoD HUD Settings** | Also in the C-menu (desktop icon) and under Q-menu › Options. |

> **K** and **L** are read from the raw key state, so they work without binding anything and don't change your existing binds.

### Controller

Turn on with `kc_controller 1`, or in **CoD HUD Settings › Controller**. Keyboard and mouse keep working while it's on.

```
            LT  Aim                                   RT  Fire
            LB  Equipment (kc_equip / instaswap)      RB  Load position
     ┌─────────────────────────────────────────────────────────┐
     │   Back: Pause menu                Start: Scoreboard (hold)
     │
     │   L-Stick: Move                   Y: Weapon switch (invprev)
     │   L3: Sprint (CoD latch)       X: Reload (tap)   B: Crouch
     │                                   A: Jump
     │   D-pad ▲ Weapon switch           R-Stick: Look
     │   D-pad ◀ S&D Set bot placement   R3: Knife (CoD4 Equipment)
     │   D-pad ▶ Reload
     │   D-pad ▼ Noclip
     └─────────────────────────────────────────────────────────┘
```

| Button | Action |
|---|---|
| **RT** / **LT** | Fire / aim down sights |
| **A** / **B** | Jump / crouch |
| **X**, **D-pad right** | Reload (tap) |
| **Y**, **D-pad up** | Weapon switch (`invprev`) |
| **LB** | Equipment: `kc_equip`, which also performs the instaswap |
| **RB** | `loadpos`: teleport back to your saved position. Save it first with `savepos`. |
| **L3** | Sprint. One tap keeps you sprinting until you stop or aim (`kc_controller_sprint_latch`). |
| **R3** | Knife (`kc_cod4_knife_stick`) |
| **D-pad left** | S&D Set: move bot to crosshair (host) |
| **D-pad down** | Noclip |
| **Back** / **Start** | Pause menu / scoreboard (hold) |

**Tuning the sticks**

| ConVar | Default | What it does |
|---|---|---|
| `kc_controller` | `0` | `1` = controller layout, `0` = keyboard & mouse |
| `kc_controller_look_speed` | `400` | Degrees per second at full right-stick push. **This sets your spin speed.** |
| `kc_controller_look_curve` | `1` | `1` = linear. Higher values give finer aim near the centre. |
| `kc_controller_deadzone` | `0.08` | Inner deadzone of the look stick (0–1) |
| `kc_controller_outer` | `0.845` | How far the stick must be pushed to count as full deflection (0–1) |
| `kc_controller_invert_y` | `0` | Invert look up/down |
| `kc_controller_sprint_latch` | `1` | Tap L3 to keep sprinting |
| `kc_controller_measure` | — | Spin using any other setup. It measures the speed and copies it into `look_speed`. |
| `kc_controller_debug` | — | Prints raw stick and trigger values for 5 seconds |

> [!NOTE]
> **Coming from Steam Input?** Steam-emulated *keyboard keys* pressed mid-spin make the cursor pop and hitch the spin. The built-in layout avoids that by reading the pad directly. If you keep your own Steam layout, use mouse outputs or virtual-gamepad outputs for anything you press while spinning, not keyboard keys.

### Recommended autoexec

Put this in `garrysmod/cfg/autoexec.cfg` and change the keys to suit you:

```cfg
// --- Gmod Trickshotting Mod ---
bind "q"      "kc_equip"          // equipment / instaswap
bind "g"      "+drop"             // drop weapon
bind "v"      "kc_cod4_knife"     // knife (CoD4 Equipment weapons)
bind "n"      "savepos"           // save your trickshot spot
bind "b"      "loadpos"           // teleport back to it
bind "F3"     "codhud_openmenu"   // CoD HUD settings
bind "F4"     "kc_menu"           // playercard customizer
// K = Create a Class and L = S&D Set bot placement work without a bind

// Instaswap timing (seconds)
kc_instaswap_draw_window     "0.6"
kc_instaswap_confirm_window  "1.0"

// Viewmodel feel
lerpedvm_sensitivity "1"
lerpedvm_strength    "1"

// Controller (uncomment to use)
// kc_controller "1"
// kc_controller_look_speed "400"
```

---

## 🏆 Game modes

Choose these in **Game Setup** or with `codhud_selected_gamemode <id>`.

| Mode | ID | Description |
|---|---|---|
| Team Deathmatch | `war` | Standard TDM. Score limit is `codhud_score_limit`. |
| Free-for-All | `dm` | Standard FFA |
| Search & Destroy | `sd` | Standard S&D |
| **Gmod Sesh TDM** | `sesh_war` | You and the other real players against **6 bots** (`sesh_bot_count_tdm`) |
| **Gmod Sesh FFA** | `sesh_dm` | FFA against **6 bots** (`sesh_bot_count_ffa`), with its own kill limit |
| **Gmod Sesh S&D** | `sesh_sd` | Rounds against **2 bots** (`sesh_bot_count_sd`). First to `sesh_sd_rounds`, capped at `sesh_sd_maxrounds`. |
| **Gmod Sesh S&D Set** | `sesh_sd_set` | Practice S&D. **L** places a bot and **God Mode** works here. |

In every Sesh mode, real players are on one team and every bot is on the other. Bots have 50 HP. Wallbangs never apply to bots, and explosive bullets are off.

---

## 🔁 Trickshot mechanics

### Instaswap

This reproduces the classic CoD quickswitch:

1. Switch weapons (`invnext`/`invprev`). The new weapon starts its draw animation.
2. While it's **still drawing**, press **`kc_equip`** (LB on controller) to divert into your equipment.
3. Within **`kc_instaswap_confirm_window`** seconds (default 1.0), switch again. You **snap straight to the weapon fully drawn**, skipping its draw animation.

| ConVar | Default | |
|---|---|---|
| `kc_instaswap_draw_window` | `0.6` | Fallback time a weapon counts as mid-draw, for weapon bases that don't expose a draw timer |
| `kc_instaswap_confirm_window` | `1.0` | Time after the equipment divert in which the next switch confirms the instaswap |

### Wallbang everything
`kc_wallbang_everything 1` makes every bullet from the host and the host's real teammates (in FFA, every real player) keep going through world geometry and props, up to `kc_wallbang_max_penetrations` surfaces. Damage still goes through the normal pipeline, so friendly fire rules, hitmarkers and blood all work. **Bots never get wallbangs.**

### Fast Last
`kc_fastlast_enabled 1` (or **Fast Last** in the lobby): the round's first kill counts normally, then the score jumps to **one below the limit**, so the **next kill ends the game** and plays the final killcam. In TDM it waits for the host's team; in FFA it waits for the host. Supports `war`, `sesh_war`, `dm` and `sesh_dm`.

### God Mode
`kc_godmode_enabled 1` (or **God Mode** in the lobby) makes the host and real players on the host's team invulnerable, and hides the low-health effects. It only works in **Sesh S&D Set** and never applies to bots.

### Create a Class
Press **K** (or use the lobby). Changes apply instantly mid-match.

| Preset | |
|---|---|
| Black Ops 2 · Modern Warfare 3 · Black Ops 1 · Modern Warfare 2 · World at War · Modern Warfare 1 | Six preset classes. Each slot can be overridden and reset to its default. |
| **Custom** | Choose any primary, secondary and equipment (`kc_custom_primary`, `kc_custom_secondary`, `kc_custom_equipment`) |
| **No Class** | Pick up weapons manually. Optional equipment with `kc_noclass_equipment`. |

---

## 🎬 The final killcam

```
 ┌──────────── during the match ────────────┐      ┌───────── winning kill ─────────┐
 │ SERVER  sv_archive.lua                   │      │ server cuts [kill-5s, kill+3s] │
 │  every tick: players, bots, NPCs,        │ ───► │ asks killer's client for its   │
 │  projectiles, bullets, sounds, hits      │      │ matching POV slice             │
 │                                          │      │            │                   │
 │ EVERY CLIENT  cl_povrecord.lua           │      │            ▼                   │
 │  its own camera, viewmodel anim/pos,     │      │ both are sent to every client  │
 │  scope overlay, gun sounds (~90 Hz)      │      │ cl_replay.lua plays it locally │
 └──────────────────────────────────────────┘      └────────────────────────────────┘
```

Nothing in the live game is moved, respawned or re-simulated. The killcam is purely a **replay of what actually happened**.

| ConVar | Default | |
|---|---|---|
| `kc_replay_pretime` | `5` | Seconds shown before the kill (CoD4 final killcam: 5) |
| `kc_replay_posttime` | `3` | Seconds shown after the kill |
| `kc_replay_reloadext` | `2` | Extra seconds so a reload started after the kill can finish on camera |
| `kc_replay_slowmo` | `-1` | `0` = off, anything else = slow motion at the kill |
| `kc_replay_slowmo_speed` | `0.15` | Playback speed at the slowest point (MW2 uses 0.25) |
| `kc_replay_slowmo_hold` | `0.4` | How long the slow motion holds after the kill |
| `kc_replay_buffer` | `25` | Seconds of match history kept in the archive |
| `kc_killcam_bots` | `1` | Show the killcam when a bot or AI gets the winning kill |
| `kc_replay_debug` | `0` | Print archive diagnostics |

**Playercard** (`kc_menu`, or set directly): `killcam_hud_title`, `killcam_hud_icon`, `killcam_hud_lvl_icon`, `killcam_hud_lvl`, `killcam_hud_text`, `killcam_hud_clantag`.

---

## ⌨️ Console commands

| Command | Realm | Description |
|---|---|---|
| `kc_classmenu` | Client | Open Create a Class |
| `kc_menu` | Client | Playercard / killcam customizer |
| `codhud_openmenu` | Client | CoD HUD Settings |
| `kc_equip` | Client | Equipment quick-switch and instaswap |
| `kc_cod4_knife` | Server | Knife with a CoD4 Equipment weapon |
| `+drop` | Server | Drop the active weapon |
| `kc_apply_loadout_now` | Server | Re-apply your selected class immediately |
| `savepos` / `loadpos` | Shared | Save your position / teleport back to it |
| `codhud_setfaction <faction>` | Server | Join a faction |
| `sesh_move_bot_to_crosshair` | Server | S&D Set: move a bot to where you're aiming |
| `sv_dropweapon_blacklist_add <class>` / `_remove` | Server | Edit the drop blacklist |
| `kc_play` / `kc_stop` | Server | Debug: play or stop a killcam of the last few seconds |
| `kc_controller_measure` / `kc_controller_debug` | Client | Controller tuning (see above) |
| `kc_debug_loadout`, `sesh_debug_factions`, `codhud_challenge_debug`, `codhud_challenge_clear`, `kc_debug_map_textures` | — | Debug and diagnostic tools |

---

## ⚙️ ConVars reference

<details>
<summary><b>Match / server</b></summary>

| ConVar | Default | Description |
|---|---|---|
| `codhud_game` | `mw2` | HUD and factions: `cod4`, `waw`, `mw2`, `mw3`, `bo1`, `bo2` |
| `codhud_selected_gamemode` | `war` | See [Game modes](#-game-modes) |
| `codhud_score_limit` | `75` | Kill limit |
| `codhud_time_limit` | `10` | Time limit (minutes) |
| `codhud_matchstart_timer` | `10` | Pregame countdown |
| `codhud_friendly_fire` | `0` | Allow damage between teammates |
| `codhud_restrictfactions` | `1` | 0 = disabled, 1 = free, 2 = pool only |
| `codhud_autobalance_on_roundstart` | `0` | Rebalance factions each round |
| `codhud_autofaction_limit` | `2` | Max active factions before auto-balance |
| `codhud_enable_roundend` | `1` | Round end screen |
| `codhud_enable_roundend_startnext` | `1` | Start the next round automatically |
| `sesh_war_limit` | `75` | Sesh TDM kill limit |
| `sesh_sd_rounds` / `sesh_sd_maxrounds` | `4` / `7` | Sesh S&D: rounds to win / hard cap |
| `sesh_bot_count_tdm` / `_ffa` / `_sd` | `6` / `6` / `2` | Bots per Sesh mode |
| `kc_fastlast_enabled` | `0` | Fast Last |
| `kc_godmode_enabled` | `0` | God Mode (S&D Set only) |
| `kc_wallbang_everything` | `1` | Wallbang everything |
| `kc_wallbang_max_penetrations` | `64` | Max surfaces a bullet passes through |
| `kc_spawn_enabled` | `1` | CoD-style spawn selection |
| `kc_spawn_enemy_min` | `1200` | Preferred minimum distance from enemies (units) |
| `kc_spawn_mate_range` | `500` | Teammates prefer to spawn within this distance |
| `sv_spread_multiplier` | `1` | Global bullet spread (0 = laser) |
| `eb_enabled` / `eb` | `0` / `25` | Explosive bullets and blast radius (non-Sesh modes only) |
| `get_sleightofhand` / `get_reversereload` | `0` | Perks used by some preset-class weapons |
| `sv_dropweapon_enablecommand` | `1` | Allow `+drop` |
| `sv_dropweapon_ondeath` / `_activeonly` | `0` / `1` | Drop weapons on death |
| `sv_dropweapon_blacklist` | `weapon_fists,` | Weapons that can't be dropped |
| `sv_dropweapon_blacklist_adminbypass` | `0` | Admins can drop blacklisted weapons |
| `kc_disable_bot_pathing` / `kc_bot_nav_debug` | `0` | Bot navigation diagnostics |

</details>

<details>
<summary><b>HUD (client)</b></summary>

| ConVar | Default | Description |
|---|---|---|
| `codhud_quickdisable_hud` / `_audio` | `0` | Turn off all HUD elements or all audio at once |
| `codhud_enable_killfeed` | `1` | Kill feed |
| `codhud_enable_scorebar` | `1` | Scorebar |
| `codhud_enable_scoreboard` | `1` | Scoreboard |
| `codhud_enable_hitmarker` | `1` | Hitmarker |
| `codhud_enable_medals` / `_medal_faster` | `1` / `0` | Kill medals / speed up a medal queue |
| `codhud_enable_xp` | `1` | XP text |
| `codhud_enable_challenges` | `1` | Challenge popups |
| `codhud_enable_minimap` | `1` | Minimap |
| `codhud_enable_weaponinfo` | `1` | Weapon info and compass |
| `codhud_enable_prompts` | `1` | Weapon prompts |
| `codhud_enable_chat` | `1` | CoD chat |
| `codhud_enable_iff` | `1` | Target ID labels |
| `codhud_enable_deathicon` | `1` | Icon where a teammate died |
| `codhud_enable_grenadeindicator` | `1` | Grenade indicator |
| `codhud_enable_outlinedtext` | `0` | Outline on some HUD text |
| `codhud_hide_timer` | `0` | Hide the round timer |
| `codhud_fullscreen` | `0` | Open settings fullscreen |
| `codhud_enable_announcer` / `_english` | `1` / `0` | Announcer / force English voice |
| `codhud_enable_music` / `codhud_enable_suspense` | `1` | End-game music / ambient music |
| `lowhealtheffect_health` | `30` | Low-health effect threshold |
| `lowhealtheffect_time` | `10` | Seconds before the low-health sounds stop |
| `lowhealtheffect_gender` | `male` | Breathing voice |
| `lowhealtheffect_heartbeat` | `1` | Heartbeat sound |

</details>

<details>
<summary><b>Crosshair (client)</b></summary>

| ConVar | Default | Description |
|---|---|---|
| `codhud_crosshair` | `1` | Draw the CoD crosshair |
| `codhud_crosshair_game` | *(empty)* | Force one game's crosshair (`cod4`, `waw`, `mw2`, `mw3`, `bo1`, `bo2`). Empty follows the HUD. |
| `codhud_crosshair_fov` | `65` | `cg_fov` the spread is mapped with |
| `cod4_crosshair_red` / `_green` / `_blue` / `_alpha` | `255` | Crosshair colour |

</details>

<details>
<summary><b>Loadouts, weapons & feel (client)</b></summary>

| ConVar | Default | Description |
|---|---|---|
| `kc_loadout_mode` | `default_4` | Selected class (`default_1`–`default_6`, `custom` or `none`). New players start on Modern Warfare 2. |
| `kc_custom_primary` / `_secondary` / `_equipment` | `mw2cr_cheytac` / `reha_mw2pp2000` / `kc_equip_knife` | Custom class |
| `kc_noclass_equipment` | *(empty)* | Equipment for No Class |
| `kc_instaswap_draw_window` / `_confirm_window` | `0.6` / `1.0` | Instaswap timing |
| `kc_cod4_knife_stick` | `1` | Knife on R3 |
| `lerpedvm_sensitivity` / `lerpedvm_strength` | `1` / `1` | Viewmodel lerp |

</details>

<details>
<summary><b>SteezMod</b></summary>

| ConVar | Default | Description |
|---|---|---|
| `hitnums_enable` | `1` | Show floating damage numbers (client) |
| `sv_hitnums_show` | `1` | Send damage numbers to players (server) |
| `sv_hitnums_showalldamage` | `0` | Also show damage that wasn't dealt by a player |
| `M9KDamageMultiplier` | `1` | Damage multiplier for M9K-style weapons |
| `M9KDisablePenetration` | `0` | Turn off M9K penetration and ricochets |
| `M9KDynamicRecoil` | `1` | Recoil moves your aim |
| `M9KDefaultClip` | `-1` | Clips weapons spawn with (negative = default) |
| `M9KUniqueSlots` | `1` | Give M9K weapons their own slots |
| `M9KWeaponStrip` | `0` | Strip empty weapons |
| `M9KAmmoDetonation` | `1` | Ammo crates can explode |
| `M9KGasEffect` / `M9KClientGasDisable` | `1` / `0` | Barrel gas effect when shooting |

</details>

---

## 🗂️ Project layout

```
lua/
├── autorun/                 entry points & standalone features
│   ├── killcam_init.lua         loads lua/killcam/*
│   ├── codhud_init.lua          loads lua/codhud/*
│   ├── killcam_codhud_integration.lua   glue between HUD rounds and the killcam
│   ├── codhud_crosshair.lua     per-game CoD reticles
│   ├── sv_wallbang_everything.lua · sv_fastlast.lua · sv_godmode.lua
│   ├── sh_cod4_knife_stick.lua · sh_cod4_claymore_support.lua
│   ├── drop_weapon.lua · lerped_viewmodels.lua · sh_bulletspread.lua
│   ├── SaveLoad.lua · SaveLoad2.lua · menu.lua · sounds.lua   SteezMod
│   ├── client/ & server/ ..._hitdamagenumbers.lua             SteezMod hit numbers
│   └── client/cl_kc_controller.lua   native controller layout
├── killcam/                 archive-based final killcam
│   ├── sh_archive.lua           codec, tunables, slow-mo timeline
│   ├── sv_archive.lua           server world recorder (ring buffer)
│   ├── cl_povrecord.lua         client first-person recorder
│   ├── cl_replay.lua            local playback
│   ├── sv_main.lua · sv_hudsync.lua · cl_hud.lua · cl_ui_menu.lua
├── codhud/                  the CoD HUD, lobby, modes, loadouts
│   ├── games/{cod4,waw,mw2,mw3,bo1,bo2}.lua   per-game HUD & factions
│   ├── cl_lobby.lua · cl_class_menu.lua · cl_settings.lua
│   ├── sv_sesh_teams.lua · sv_spawns.lua · sv_loadouts_give.lua
│   └── ... killfeed, medals, scorebar, scoreboard, announcer, etc.
├── ffa/sv_ffa_bots.lua      Sesh bots (navmesh AI)
├── weapons/ · entities/ · effects/   weapon bases, knife, claymore, smoke
├── xpgui/ · scalar/         UI toolkit & resolution scaling
└── killcam_cfg.lua · killcam_lang.lua
```

---

## 🙏 Credits

This project is a **group build**. Everyone below agreed to have their work included here. All code and assets belong to their original authors.

- **reha** (`@rehaiu`): **SteezMod v1b** (save/load position, the MW2/MW3 snipers, reha's weapon bases, hit damage numbers)
- **Scripts&Maps**: *Garry's Mod Killcam*, which the playercard customizer (`kc_menu`) and the original killcam came from
- **Call of Duty HUD Collection / Mini DM gamemode**: the HUD this mod is forked from ([Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3720590485))
- **KatBug**: *Call of Duty 4: Equipment* (claymore, knife) ([Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=528146710))
- **Generic Default, Worshipper, Clavus & Bob**: the Bob's / BO2 weapon bases ([BO2 Weapons Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=299164995))
- **reha** and **Dread**: the CoD weapon ports used by the preset classes
- **YuRaNnNzZZ**: *Lerped Viewmodels* and *Drop Weapon*
- **xpgui** and **Scalar** UI libraries
- **Activision, Infinity Ward, Treyarch & Sledgehammer Games**: Call of Duty, which this is a fan tribute to

---

## ⚠️ Disclaimer

This is a **non-commercial fan project**, not affiliated with or endorsed by Activision or any Call of Duty developer. *Call of Duty* and related names are trademarks of Activision Publishing, Inc. Game audio and art in the Release download remain the property of their owners and are included for fan, non-commercial use only.

<div align="center">

**Made for the trickshot community. Hit your shots. 🎯**

</div>
