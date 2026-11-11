# Типы данных Lua API

Таблицы снимков содержат копии значений. Они не являются engine pointers и не меняют игру при присваивании полям. `?` означает возможный nil или необязательное поле. Числовые координаты и единицы уточняются в руководствах [графики](RENDER.ru.md), [данных](DATA.ru.md) и [команд](COMMANDS.ru.md).

Составные возвращаемые типы, записанные прямо в сигнатуре, приведены в [справочнике функций](API_INDEX.ru.md).

## Псевдонимы

- `Color integer[] RGBA, exactly four channels in 0..255.`
- `EventName 'paint'|'create_move'|'pre_rage'|'post_rage'|'pre_legit'|'post_legit'|'post_move'|'finalize_command'|'prediction'|'frame_stage'|'game_event'|'shutdown'`

## Vector3

| Поле | Тип и смысл |
|---|---|
| `x` | number |
| `y` | number |
| `z` | number |

## PlayerSnapshot

| Поле | Тип и смысл |
|---|---|
| `id` | integer Controller index; 0 aliases local player. |
| `name` | string |
| `health` | integer |
| `alive` | boolean |
| `team` | integer |
| `enemy` | boolean |
| `origin` | Vector3 |
| `velocity` | Vector3 |
| `flags` | integer |
| `armor` | integer |
| `scoped` | boolean Local/client-known zoom state; false when unavailable. |

## SettingDescriptor

| Поле | Тип и смысл |
|---|---|
| `category` | string |
| `name` | string |
| `type` | string |
| `count` | integer |
| `writable` | boolean False for aim/shot settings, except visual colors; set/override/bind writes are rejected. |

## CommandSnapshot

| Поле | Тип и смысл |
|---|---|
| `number` | integer |
| `tick` | integer |
| `buttons` | integer |
| `buttons_changed` | integer |
| `buttons_scroll` | integer |
| `history_count` | integer |
| `forward` | number |
| `side` | number |
| `up` | number |
| `angles` | Vector3 |
| `phase` | string |
| `writable` | boolean |

## GameEvent

| Поле | Тип и смысл |
|---|---|
| `name` | string |
| `userid` | integer? Controller index; 0 is the local player, nil if absent/unresolved. |
| `attacker` | integer? Controller index; 0 is the local player, nil if absent/unresolved. |
| `position` | Vector3? Present for bullet_impact only. |
| `dmg_health` | integer? player_hurt: health damage reported by the event. |
| `damage` | integer? Alias of dmg_health. |
| `dmg_armor` | integer? player_hurt: armor damage reported by the event. |
| `health` | integer? player_hurt: remaining health. |
| `armor` | integer? player_hurt: remaining armor. |
| `hitgroup` | integer? player_hurt: native hitgroup, not a bone/hitbox index. |
| `weapon` | string? player_hurt: event weapon name, copied before the event expires. |

## LuaBudget

| Поле | Тип и смысл |
|---|---|
| `instructions_remaining` | integer Effective current scope; approximate in steps of 1000. |
| `time_remaining_ms` | number Effective current scope; wall time, minimum 0. |
| `native_work_remaining` | integer Host API/conversion work; direct FFI calls are not API-counted. |
| `dispatch_instructions_remaining` | integer Shared dispatch remainder. |
| `dispatch_time_remaining_ms` | number Shared dispatch remainder. |
| `protect_depth` | integer Current nested protect depth. |
| `recovering` | boolean Dispatch exhausted; finish this callback now. |
| `retryable` | boolean Parent has not exhausted its budget; does not promise a task will fit. |

## LuaBudgetError

| Поле | Тип и смысл |
|---|---|
| `kind` | 'instructions'&#124;'time'&#124;'native_work' |
| `scope` | 'protect'&#124;'dispatch' |
| `retryable` | boolean False when dispatch is exhausted. |

## WeaponProfile

| Поле | Тип и смысл |
|---|---|
| `item_id` | integer Item definition index, suitable for combat.context().item_id / entity.weapon(index).item_id. |
| `key` | string Stable weapon slug, e.g. awp, ssg08, scar20, deagle. |
| `name` | string Display name, e.g. AWP. |
| `legacy_group` | string pistol, smg, rifle, sniper, shotgun or lmg; compatibility only. |
| `rage_category` | string Canonical category, e.g. ragebot - awp. |
| `legit_category` | string Canonical category, e.g. legitbot - awp. |

## BindSnapshot

| Поле | Тип и смысл |
|---|---|
| `category` | string |
| `name` | string |
| `key` | integer Windows virtual key. |
| `mode` | integer 0 toggle, 1 hold_on; legacy 2 is normalized to toggle. |
| `active` | boolean Whether the bind is active. |
| `value` | boolean Current setting value. |

## ExecutionStats

| Поле | Тип и смысл |
|---|---|
| `phase` | string |
| `instructions` | integer Approximate; sampled every 1000 Lua instructions. |
| `api_calls` | integer Native API entries, including this stats call. |
| `native_work` | integer API entries plus table conversion work. |
| `time_ms` | number Elapsed execution time excluding credited audio waits; not CPU/GPU time. |
| `memory_bytes` | integer Lua allocator usage; excludes graphics caches and native allocations. |

## ScriptStats: ExecutionStats

| Поле | Тип и смысл |
|---|---|
| `invocations` | integer Completed load/event dispatches since enabling this instance (all handlers together). |
| `protected_errors` | integer Ordinary errors and budget failures caught by api.protect since enabling. |
| `last` | ExecutionStats? Previous completed invocation; nil before the first one. |
| `budget` | LuaBudget Current budget snapshot. |

## MovementSnapshot

| Поле | Тип и смысл |
|---|---|
| `valid` | boolean |
| `command_number` | integer |
| `phase` | 'pre' |
| `flags` | integer |
| `on_ground` | boolean |
| `velocity` | Vector3 Networked velocity before the native transaction. |
| `absolute_velocity` | Vector3 Absolute velocity before the native transaction, NOT a forecast. |
| `origin` | Vector3 |
| `surface_friction` | number |
| `stamina` | number |
| `move_type` | integer? |
| `forward` | number |
| `side` | number |
| `buttons` | integer |

## GrenadePath

| Поле | Тип и смысл |
|---|---|
| `points` | Vector3[] Ordered world positions; includes the initial point. |
| `bounces` | Vector3[] Observed collisions in the prediction model. |
| `end_pos` | Vector3 Last calculated position. A complete path may stop before detonation; inspect reason and detonated. |
| `duration` | number Predicted seconds from the supplied state, not from the original throw. |
| `valid` | boolean Completed donor path or at least two partial points; a completed stationary path can contain one point. |
| `complete` | boolean Reached a donor termination condition: detonation, stopped or contact_limit; not a trace-budget failure. |
| `detonated` | boolean Predicted condition, not confirmation of a real explosion. |
| `reason` | string detonation, stopped, contact_limit, invalid_input, collision_unavailable_or_budget, start_solid, invalid_collision, invalid_normal, tick_limit, or unavailable-data reason. |
| `traces` | integer Trace attempts in this simulation; excludes the throw-origin sweep. |
| `item_id?` | integer Present in grenades.preview results. |

## GrenadeObservation

| Поле | Тип и смысл |
|---|---|
| `id` | integer Cache generation; changes on reconstruction. |
| `index` | integer Entity index; may be reused. |
| `item_id` | integer 43..48, or 0 for inferno/unknown. Molotov and incendiary projectiles share kind molotov and ID 46. |
| `kind` | string flashbang, hegrenade, smokegrenade, molotov, decoy, inferno, or unknown. |
| `origin` | Vector3 Observed world position. |
| `velocity?` | Vector3 Observed units per second. |
| `observed` | boolean Always true. |
| `age?` | number Observed game time minus spawn time, in seconds. |
| `local_thrower` | boolean Resolved thrower is the local pawn; false also means unresolved. |
| `effect_started` | boolean Detonation/smoke/decoy effect observed, or this is an inferno. |
| `effect_ended` | boolean Effect/explosion ended according to available flags, burning patches or lifetime estimate; entity can still exist. |
| `opacity` | number 0..1 native indicator fade; do not draw records at zero opacity. |
| `geometry?` | {kind: string, points: Vector3[], exact_damage_boundary: boolean} Burning fire positions, up to 64; boundary flag is always false. |
| `detonation_time` | nil Exact future explosion time is not available. |
| `trajectory?` | GrenadePath Whole cached route from launch; nil when not requested or unavailable. Not a forecast from the current origin. |
| `trajectory_age?` | number Seconds since the trajectory was calculated; not grenade age. |
| `initial_position?` | Vector3 Observed launch position, nil when unavailable. |
| `initial_velocity?` | Vector3 Observed launch velocity, nil when unavailable. |
| `timer_remaining?` | number Estimated remaining effect/fuse seconds; nil when fields are unavailable or no timer applies. |
| `timer_duration?` | number Total timer duration; smoke 20, inferno 7, decoy 15; HE uses observed native times. |

## RadarPlayer

| Поле | Тип и смысл |
|---|---|
| `id` | integer Controller entity index. |
| `health` | integer Observed health, greater than zero. |
| `team` | integer Observed team. |
| `enemy` | boolean Relative to the viewed player's team under the current game mode. |
| `origin` | Vector3 World position. |
| `name` | string Player name. |

## RadarSnapshot

| Поле | Тип и смысл |
|---|---|
| `map` | string Current map name. |
| `center` | Vector3 Viewed pawn origin, camera origin if unavailable. |
| `yaw` | number Camera yaw in degrees. |
| `players` | RadarPlayer[] Up to 64 observed alive players, excluding the viewed pawn. |
| `grenades` | GrenadeObservation[] Up to 128 observations. |
| `age` | number Snapshot age in seconds, at most 0.25. |

## DoubleTapSnapshot

| Поле | Тип и смысл |
|---|---|
| `kind` | 'double_tap' |
| `state` | 'off'&#124;'unavailable'&#124;'weapon_blocked'&#124;'cooldown'&#124;'window_blocked'&#124;'ready'&#124;'committed' |
| `active` | boolean DT requested by the native settings. |
| `available` | boolean A fresh command was successfully serialized; not a target or hit guarantee. |
| `ready` | boolean Native model/window permits DT, independent of target visibility. |
| `committed` | boolean A DT-priority shot was serialized; not server acknowledgement or two confirmed bullets. |
| `charge` | number 0..1 model cooldown progress. Only ready reports 1; policy/history can hold it below 1. |
| `remaining` | number Seconds to the model cooldown deadline; 0 does not imply ready. |
| `age` | number Seconds since snapshot publication; older than 0.25 becomes unavailable with zero charge. |
| `command` | integer Observed command number, -1 before observation. |
| `weapon` | integer Item definition ID, 0 when unavailable before observation. |

## ToggleIndicator

| Поле | Тип и смысл |
|---|---|
| `kind` | 'toggle' |
| `category` | string Setting category. |
| `name` | string Setting name. |
| `active` | boolean Current effective Boolean setting, including applied binds/overrides; not proof of engine activity. |
| `state` | 'on'&#124;'off' |

## MenuLanguage

| Поле | Тип и смысл |
|---|---|
| `id` | string |
| `name` | string |
| `font?` | string Custom font basename in %LOCALAPPDATA%/skeet |
| `font_size?` | number Custom menu font size in pixels |

## MenuFontInfo

| Поле | Тип и смысл |
|---|---|
| `language` | string Effective language ID |
| `source` | 'default'&#124;'menu'&#124;'language' |
| `filename?` | string Custom font basename |
| `size?` | number Custom font size |

## LuaWindowOptions

| Поле | Тип и смысл |
|---|---|
| `key?` | integer 0 follows Skeet; 1..255 uses a separate VK toggle key |
| `open?` | boolean Default true for key=0; false for a separate key |
| `x?` | number Default 120 |
| `y?` | number Default 120 |
| `width?` | number 180..1600, default 320 |
| `height?` | number 120..1600, default 360 |

## LuaWindowInfo

| Поле | Тип и смысл |
|---|---|
| `id` | string |
| `title` | string |
| `key` | integer |
| `open` | boolean Effective visibility |
| `follows_menu` | boolean |
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |

## CustomModel

| Поле | Тип и смысл |
|---|---|
| `id` | string Relative compiled file under game/csgo/characters/models, e.g. fatality/sas/player.vmdl_c. |
| `path` | string Virtual CS2 path passed to the player-model setter. |

## HitboxSnapshot

| Поле | Тип и смысл |
|---|---|
| `index` | integer Hitbox index, not bone index. |
| `bone` | integer |
| `radius` | number |
| `mins` | Vector3 Hitbox-local minimum. |
| `maxs` | Vector3 Hitbox-local maximum. |
| `center` | Vector3 World-space center. |
| `capsule_a` | Vector3 World-space transformed mins endpoint. |
| `capsule_b` | Vector3 World-space transformed maxs endpoint. |
| `rotation` | {x:number,y:number,z:number,w:number} Bone quaternion. |

## Vector2

| Поле | Тип и смысл |
|---|---|
| `x` | number |
| `y` | number |

## XuiWindowOptions

| Поле | Тип и смысл |
|---|---|
| `x?` | number Default 120, screen pixels. |
| `y?` | number Default 120, screen pixels. |
| `width?` | number 180..1600; default 320. |
| `height?` | number 120..1600; default 360. |
| `key?` | integer Windows VK 0..255; 0 follows the main menu, default 0. |
| `open?` | boolean Default true for key=0, otherwise false. |
| `titlebar?` | boolean Default true, including the close button. |
| `background?` | boolean Default true, blurred backdrop with style tint. |
| `movable?` | boolean Default true; top 30 pixels are the drag region. |
| `resizable?` | boolean Default true. |
| `padding?` | number 0..100, horizontal inset; titleless windows also use it vertically. |

## XuiItemState

| Поле | Тип и смысл |
|---|---|
| `x` | number Screen pixels. |
| `y` | number Screen pixels. |
| `width` | number |
| `height` | number |
| `hovered` | boolean Includes overlay, window and clipping checks. |
| `down` | boolean Mouse held over the region; no capture outside its bounds. |

## MenuTabStyle

| Поле | Тип и смысл |
|---|---|
| `title?` | string UTF-8 literal caption, 1..96 bytes, no ## or line breaks. |
| `icon?` | string UTF-8 icon/glyph text, 1..16 bytes; default ">". |
| `icon_texture?` | integer Owned render texture handle; 0 restores glyph icon. |
| `active_icon?` | string Selected glyph; omitted uses icon. |
| `active_icon_texture?` | integer Owned selected texture; 0 uses icon_texture. Create textures in paint. |
| `text_color?` | Color Reserved caption metadata; native section titles keep the menu theme. |
| `text_colors?` | Color[] Reserved caption metadata; at most 96 entries, not drawn by the icon-only sidebar. |
| `icon_color?` | Color Glyph/image tint. |
| `active_icon_color?` | Color Selected tint; defaults to white. |
| `background?` | Color Inactive row background. |
| `active_background?` | Color Selected row background. |

## MenuTabLayout

| Поле | Тип и смысл |
|---|---|
| `top?` | number Top fraction 0..1, default 0. |
| `bottom?` | number Bottom fraction 0..1, default 1. Height must be at least 0.12. |
| `span?` | integer 1 column (default) or 2 (only from column 1). Cells must not overlap. |

## CData

Нативный тип FFI; его поля определяются C-объявлением.

## CType

Нативный тип FFI; его поля определяются C-объявлением.

## CCallback: CData

| Поле | Тип и смысл |
|---|---|
| `free` | fun(self: CCallback) |
| `set` | fun(self: CCallback, callback: function) |

## CLibrary

Нативный тип FFI; его поля определяются C-объявлением.

## FFI

| Поле | Тип и смысл |
|---|---|
| `C` | CLibrary |
| `os` | string |
| `arch` | string |
| `nullptr` | CData |

