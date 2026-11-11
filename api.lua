---@meta
-- IDE declarations only. Do not run this file as a game script.
-- Native FFI declarations are in ffi.lua; usage: FFI.ru.md.

---@class Vector3
---@field x number
---@field y number
---@field z number

---@alias Color integer[] RGBA, exactly four channels in 0..255.
---@alias EventName 'paint'|'create_move'|'pre_rage'|'post_rage'|'pre_legit'|'post_legit'|'post_move'|'finalize_command'|'prediction'|'frame_stage'|'game_event'|'shutdown'

---@class PlayerSnapshot
---@field id integer Controller index; 0 aliases local player.
---@field name string
---@field health integer
---@field alive boolean
---@field team integer
---@field enemy boolean
---@field origin Vector3
---@field velocity Vector3
---@field flags integer
---@field armor integer
---@field scoped boolean Local/client-known zoom state; false when unavailable.

---@class SettingDescriptor
---@field category string
---@field name string
---@field type string
---@field count integer
---@field writable boolean False for aim/shot settings, except visual colors; set/override/bind writes are rejected.

---@class CommandSnapshot
---@field number integer
---@field tick integer
---@field buttons integer
---@field buttons_changed integer
---@field buttons_scroll integer
---@field history_count integer
---@field forward number
---@field side number
---@field up number
---@field angles Vector3
---@field phase string
---@field writable boolean

---@class GameEvent
---@field name string
---@field userid integer? Controller index; 0 is the local player, nil if absent/unresolved.
---@field attacker integer? Controller index; 0 is the local player, nil if absent/unresolved.
---@field position Vector3? Present for bullet_impact only.
---@field dmg_health integer? player_hurt: health damage reported by the event.
---@field damage integer? Alias of dmg_health.
---@field dmg_armor integer? player_hurt: armor damage reported by the event.
---@field health integer? player_hurt: remaining health.
---@field armor integer? player_hurt: remaining armor.
---@field hitgroup integer? player_hurt: native hitgroup, not a bone/hitbox index.
---@field weapon string? player_hurt: event weapon name, copied before the event expires.

---@class LuaBudget
---@field instructions_remaining integer Effective current scope; approximate in steps of 1000.
---@field time_remaining_ms number Effective current scope; wall time, minimum 0.
---@field native_work_remaining integer Host API/conversion work; direct FFI calls are not API-counted.
---@field dispatch_instructions_remaining integer Shared dispatch remainder.
---@field dispatch_time_remaining_ms number Shared dispatch remainder.
---@field protect_depth integer Current nested protect depth.
---@field recovering boolean Dispatch exhausted; finish this callback now.
---@field retryable boolean Parent has not exhausted its budget; does not promise a task will fit.
---@class LuaBudgetError
---@field kind 'instructions'|'time'|'native_work'
---@field scope 'protect'|'dispatch'
---@field retryable boolean False when dispatch is exhausted.
api = { version = 3, lua = 'Lua 5.5', script = '', error_codes = { budget_exceeded = 'budget_exceeded' } }
---Catch ordinary errors and budget exhaustion. Allocation failures remain fatal.
---Pending command edits are restored on failure; settings, draws, UI and other effects are not rolled back. fn receives no arguments; use a closure.
---@param fn fun(): ...
---@param limits? {instructions?: integer, time_ms?: number} Defaults 1000000 / 25 ms; maxima 20000000 / 250 ms; parent limits apply.
---@return boolean ok
---@return string? error Exact 'budget_exceeded' for budget failure; ordinary errors have a traceback; nil on success.
---@return ... results All fn results including nils on success; LuaBudgetError as third result on budget failure.
function api.protect(fn, limits) end
---Budget snapshot; querying it consumes a host API call. Finish callback when recovering=true.
---@return LuaBudget budget
function api.budget() end
buttons = { attack=1, jump=2, duck=4, forward=8, back=16, use=32,
    moveleft=512, moveright=1024, attack2=2048, reload=8192, speed=65536,
    zoom=17179869184, score=8589934592, inspect=34359738368 }

events = {}
---@param name EventName
---@param callback fun(event: table) Callback return values are ignored.
---@overload fun(name: 'game_event', callback: fun(event: GameEvent)): integer
---@return integer subscription
function events.on(name, callback) end
---@param id integer
---@return boolean removed
function events.off(id) end

settings = {}
---@class WeaponProfile
---@field item_id integer Item definition index, suitable for combat.context().item_id / entity.weapon(index).item_id.
---@field key string Stable weapon slug, e.g. awp, ssg08, scar20, deagle.
---@field name string Display name, e.g. AWP.
---@field legacy_group string pistol, smg, rifle, sniper, shotgun or lmg; compatibility only.
---@field rage_category string Canonical category, e.g. ragebot - awp.
---@field legit_category string Canonical category, e.g. legitbot - awp.
---@return WeaponProfile[] All 34 firearms, stable menu order; available at script load, excludes Zeus/knives/grenades.
function settings.weapon_profiles() end
---Use exact per-weapon categories from weapon_profiles(). Aim/shot fields are read-only.
---Legacy get/bind reads use the held weapon in that class when the command context is valid, otherwise its first menu entry.
---@param category_filter? string
---@return SettingDescriptor[]
function settings.list(category_filter) end
---@param category string
---@param name string
---@return any value
function settings.get(category, name) end
---@param category string
---@param name string
---@param value any
function settings.set(category, name, value) end
---@param category string
---@param name string
---@param value any Pass nil to release this script's override.
function settings.override(category, name, value) end
---@param category string
---@param name string
---@param key? integer Windows virtual key, 0..255.
---@param mode? integer 0 toggle, 1 hold_on; legacy 2 is normalized to toggle.
---@return {key: integer, mode: integer, active: boolean}
function settings.bind(category, name, key, mode) end
---@class BindSnapshot
---@field category string
---@field name string
---@field key integer Windows virtual key.
---@field mode integer 0 toggle, 1 hold_on; legacy 2 is normalized to toggle.
---@field active boolean Whether the bind is active.
---@field value boolean Current setting value.
---@return BindSnapshot[] Native bound settings plus active scripts' Lua checkbox binds; includes inactive binds.
function settings.binds() end

client = {}
---@param ... any
function client.log(...) end
---@param level 'debug'|'info'|'warning'|'error'
---@param ... any
function client.log_level(level, ...) end
---@class ExecutionStats
---@field phase string
---@field instructions integer Approximate; sampled every 1000 Lua instructions.
---@field api_calls integer Native API entries, including this stats call.
---@field native_work integer API entries plus table conversion work.
---@field time_ms number Elapsed execution time excluding credited audio waits; not CPU/GPU time.
---@field memory_bytes integer Lua allocator usage; excludes graphics caches and native allocations.
---@class ScriptStats: ExecutionStats
---@field invocations integer Completed load/event dispatches since enabling this instance (all handlers together).
---@field protected_errors integer Ordinary errors and budget failures caught by api.protect since enabling.
---@field last ExecutionStats? Previous completed invocation; nil before the first one.
---@field budget LuaBudget Current budget snapshot.
---@return ScriptStats
function client.stats() end
---@return number seconds Monotonic, not game time.
function client.time() end
---@param vk integer
---@return boolean
function client.key_down(vk) end
---@return integer width
---@return integer height
function client.screen_size() end
---@return number seconds
function client.frametime() end

console = {}
---Queue game console commands for a following game frame-stage; true means queued.
---@param command string 1..1024 bytes; NUL forbidden. Game command batches are allowed.
---@return boolean accepted
---@return string? reason console_unavailable, queue_full, rate_limited or script_stopping.
function console.exec(command) end
---Queue literal text in the game console, with a trailing newline. Percent signs are literal.
---@param text string Up to 2048 bytes; NUL forbidden.
---@return boolean accepted
---@return string? reason
function console.print(text) end
---Queue a single quoted say/say_team command, without command injection.
---@param text string 1..200 UTF-8 bytes; controls, quotes, backslashes and semicolons forbidden.
---@param team_only? boolean Defaults to false.
---@return boolean accepted
---@return string? reason
function console.say(text, team_only) end
---Cancel this script's queued requests; requests already handed to the engine are unaffected.
---@return integer removed
function console.clear_pending() end

audio = {}
---Prepare once at top level during script loading. No playback is started.
---@param basename string MP3/WAV basename in muzon, or sounds/<basename>.mp3/.wav. Encoded file <=64 MiB; decoded PCM <=128 MiB.
---@return boolean ok
---@return string? error
function audio.preload(basename) end
---Prepared play uses retained PCM/voice. The first unprepared play loads synchronously.
---@param basename string MP3/WAV basename under %LOCALAPPDATA%/skeet/muzon, or sounds/<basename>.mp3/.wav under %LOCALAPPDATA%/skeet/sounds.
---@param loop? boolean Repeat until stopped.
---@return boolean ok
---@return string? error
function audio.play(basename, loop) end
---@param percent number Finite; clamped to 0..100. Per-script volume, also accepted before playback.
---@return boolean ok
function audio.volume(percent) end
---Stop playback but retain prepared sounds until script unload.
function audio.stop() end

cmd = {}
---Current command plus this script's staged values; post events are read-only.
---@return CommandSnapshot
function cmd.get() end
---Stage grenade view input in create_move after grenades.claim. Native firearm AA uses settings overrides.
---@param angles Vector3 Finite pitch clamped to -89..89, yaw normalized, roll zero.
---@param visible? boolean Also update camera on successful commit.
function cmd.set_angles(angles, visible) end
---Stage normalized movement before native prediction; whole script dispatch must succeed.
---@param forward number -1..1 (clamped).
---@param side number -1..1; positive is left, matching the native movement model.
---@param up? number -1..1.
function cmd.set_movement(forward, side, up) end
---create_move only. Movement buttons; attack/attack2 require active grenade claim. Other buttons rejected.
---@param mask integer
---@param pressed boolean
function cmd.set_button(mask, pressed) end
---Stage held/changed/scroll bits; same phase and mask rules as set_button.
---@param mask integer
---@param held boolean
---@param changed boolean
---@param scroll boolean
function cmd.set_button_state(mask, held, changed, scroll) end

---@class MovementSnapshot
---@field valid boolean
---@field command_number integer
---@field phase 'pre'
---@field flags integer
---@field on_ground boolean
---@field velocity Vector3 Networked velocity before the native transaction.
---@field absolute_velocity Vector3 Absolute velocity before the native transaction, NOT a forecast.
---@field origin Vector3
---@field surface_friction number
---@field stamina number
---@field move_type integer?
---@field forward number
---@field side number
---@field buttons integer
movement = {}
---Disable the selected native movement mode for this command after successful create_move dispatch.
---@param feature 'bhop'|'strafe'
function movement.claim(feature) end
---Prestate for the current command, nil when local player/movement/scene is unavailable.
---@return MovementSnapshot?
function movement.context() end
prediction = {}
---Alias of movement.context; no second prediction transaction is run.
---@return MovementSnapshot?
function prediction.before() end
---Actual native prediction result in prediction/post callbacks; nil before prediction or on invalid output.
---@return {valid: boolean, command_number: integer, phase: string, tick: integer, flags: integer, move_type: integer, origin: Vector3, velocity: Vector3, landed: boolean, landed_fraction: number}?
function prediction.result() end
grenades = {}
---Current grenade; all command callbacks. Missing optional schema data is nil, never guessed.
---@return {item_id: integer, handle: integer, command_number: integer, pin_pulled: boolean?, throw_time: number?, strength: number?}?
function grenades.context() end
---create_move only; authorize grenade angles/attack for the same weapon handle and suppress native AA for this command.
---@return boolean claimed False when no active grenade exists.
function grenades.claim() end
---Discard this script's pending command request. Does not undo published commands or unthrow a primed grenade.
function grenades.cancel() end
---@class GrenadePath
---@field points Vector3[] Ordered world positions; includes the initial point.
---@field bounces Vector3[] Observed collisions in the prediction model.
---@field end_pos Vector3 Last calculated position. A complete path may stop before detonation; inspect reason and detonated.
---@field duration number Predicted seconds from the supplied state, not from the original throw.
---@field valid boolean Completed donor path or at least two partial points; a completed stationary path can contain one point.
---@field complete boolean Reached a donor termination condition: detonation, stopped or contact_limit; not a trace-budget failure.
---@field detonated boolean Predicted condition, not confirmation of a real explosion.
---@field reason string detonation, stopped, contact_limit, invalid_input, collision_unavailable_or_budget, start_solid, invalid_collision, invalid_normal, tick_limit, or unavailable-data reason.
---@field traces integer Trace attempts in this simulation; excludes the throw-origin sweep.
---@field item_id? integer Present in grenades.preview results.
---@class GrenadeObservation
---@field id integer Cache generation; changes on reconstruction.
---@field index integer Entity index; may be reused.
---@field item_id integer 43..48, or 0 for inferno/unknown. Molotov and incendiary projectiles share kind molotov and ID 46.
---@field kind string flashbang, hegrenade, smokegrenade, molotov, decoy, inferno, or unknown.
---@field origin Vector3 Observed world position.
---@field velocity? Vector3 Observed units per second.
---@field observed boolean Always true.
---@field age? number Observed game time minus spawn time, in seconds.
---@field local_thrower boolean Resolved thrower is the local pawn; false also means unresolved.
---@field effect_started boolean Detonation/smoke/decoy effect observed, or this is an inferno.
---@field effect_ended boolean Effect/explosion ended according to available flags, burning patches or lifetime estimate; entity can still exist.
---@field opacity number 0..1 native indicator fade; do not draw records at zero opacity.
---@field geometry? {kind: string, points: Vector3[], exact_damage_boundary: boolean} Burning fire positions, up to 64; boundary flag is always false.
---@field detonation_time nil Exact future explosion time is not available.
---@field trajectory? GrenadePath Whole cached route from launch; nil when not requested or unavailable. Not a forecast from the current origin.
---@field trajectory_age? number Seconds since the trajectory was calculated; not grenade age.
---@field initial_position? Vector3 Observed launch position, nil when unavailable.
---@field initial_velocity? Vector3 Observed launch velocity, nil when unavailable.
---@field timer_remaining? number Estimated remaining effect/fuse seconds; nil when fields are unavailable or no timer applies.
---@field timer_duration? number Total timer duration; smoke 20, inferno 7, decoy 15; HE uses observed native times.
---Copied observations, at most 128. First call can be empty until the next render-start update; minimum refresh interval 8/16/50 ms according to active forecasts, expiry 250 ms.
---@param paths? boolean Request cached flight predictions; false by default. Does not trace in paint.
---@return GrenadeObservation[]
function grenades.observations(paths) end
---Request/read the held grenade preview from the game-thread cache. No command writes; first call may return nil.
---@return GrenadePath? path Approximate physics, including incomplete results; check valid and complete.
---@return string? reason snapshot_unavailable or preview_unavailable when no path exists.
function grenades.preview() end
---Command callbacks only. Bounded hull-trace prediction; does not run player prediction or edit commands.
---@param origin Vector3 Initial position in world units; magnitude at most 10000000.
---@param velocity Vector3 Initial units per second; magnitude at most 100000.
---@param item_id integer 43..48.
---@param age? number Seconds since release, finite and nonnegative; default 0.
---@return GrenadePath path Check valid and complete; never treat a budget-truncated endpoint as a landing.
function grenades.predict(origin, velocity, item_id, age) end
---Command callbacks only. Predict from the validated current first-person eye or pawn origin + view offset in third person, using the actual held grenade; does not throw it.
---@param angles Vector3 Desired pitch/yaw in degrees; pitch clamped to -89..89, roll ignored.
---@param strength number 0..1: secondary 0, both buttons 0.5, primary 1; intermediate strength is allowed.
---@return GrenadePath path May report no_active_grenade, player_velocity_unavailable, player_eye_unavailable, throw_origin_unavailable_or_budget, throw_origin_start_solid or throw_origin_invalid_collision. Missing native throw velocity uses the standard 750 profile.
function grenades.predict_throw(angles, strength) end

---@class RadarPlayer
---@field id integer Controller entity index.
---@field health integer Observed health, greater than zero.
---@field team integer Observed team.
---@field enemy boolean Relative to the viewed player's team under the current game mode.
---@field origin Vector3 World position.
---@field name string Player name.
---@class RadarSnapshot
---@field map string Current map name.
---@field center Vector3 Viewed pawn origin, camera origin if unavailable.
---@field yaw number Camera yaw in degrees.
---@field players RadarPlayer[] Up to 64 observed alive players, excluding the viewed pawn.
---@field grenades GrenadeObservation[] Up to 128 observations.
---@field age number Snapshot age in seconds, at most 0.25.
radar = {}
---Request/read copied client data; usable in paint. Nil outside a valid session or while the first snapshot is pending. No map texture is supplied.
---@param paths? boolean Also request cached grenade trajectories; default false.
---@return RadarSnapshot? snapshot
---@return string? reason snapshot_unavailable when nil.
function radar.snapshot(paths) end
---Pure coordinate conversion; does not read entities or trace. Rotation keeps camera forward at the top.
---@param world Vector3 Position to project.
---@param center Vector3 Radar center in world space, usually snapshot.center.
---@param yaw number Camera heading in degrees; ignored when rotate=false.
---@param range number Positive world distance from radar center to an edge.
---@param x number Screen X of the square's top-left corner.
---@param y number Screen Y of the square's top-left corner.
---@param size number Positive square side in pixels.
---@param rotate? boolean Default true; false keeps +X right and +Y up.
---@param clamp_edge? boolean Default true; outside points are clamped along the direction to the square edge.
---@return number x Screen coordinate.
---@return number y Screen coordinate.
---@return boolean inside Whether the original point was inside the square before clamping.
function radar.project(world, center, yaw, range, x, y, size, rotate, clamp_edge) end

entity = {}
---@return PlayerSnapshot?
function entity.local_player() end
---@param enemies_only? boolean
---@return PlayerSnapshot[]
function entity.players(enemies_only) end
---@param id integer
---@return PlayerSnapshot?
function entity.get(id) end
---@param id integer
---@param bone_index integer 0..127
---@return Vector3?
function entity.bone(id, bone_index) end
---@param id integer
---@return {x: number, y: number, w: number, h: number}?
function entity.bounds(id) end
---@return {id: integer, class_hash: integer, origin: Vector3}[]
function entity.items() end
---@param id integer
---@return {item_id: integer, ammo: integer, reloading: boolean}?
function entity.weapon(id) end

combat = {}
---@class DoubleTapSnapshot
---@field kind 'double_tap'
---@field state 'off'|'unavailable'|'weapon_blocked'|'cooldown'|'window_blocked'|'ready'|'committed'
---@field active boolean DT requested by the native settings.
---@field available boolean A fresh command was successfully serialized; not a target or hit guarantee.
---@field ready boolean Native model/window permits DT, independent of target visibility.
---@field committed boolean A DT-priority shot was serialized; not server acknowledgement or two confirmed bullets.
---@field charge number 0..1 model cooldown progress. Only ready reports 1; policy/history can hold it below 1.
---@field remaining number Seconds to the model cooldown deadline; 0 does not imply ready.
---@field age number Seconds since snapshot publication; older than 0.25 becomes unavailable with zero charge.
---@field command integer Observed command number, -1 before observation.
---@field weapon integer Item definition ID, 0 when unavailable before observation.
---Read a copied native observation in any callback, including paint. No engine simulation or mutation. Command callbacks before final serialization can see unavailable. Always returns a table; retain copies freely, fetch again for freshness.
---@return DoubleTapSnapshot
function combat.double_tap() end

indicators = {}
---@class ToggleIndicator
---@field kind 'toggle'
---@field category string Setting category.
---@field name string Setting name.
---@field active boolean Current effective Boolean setting, including applied binds/overrides; not proof of engine activity.
---@field state 'on'|'off'
---Read-only snapshot in any callback. The ragebot/double tap pair returns native DT state. Other Boolean settings return toggle state; missing, ambiguous or non-Boolean fields raise an error. No charge is invented for other features.
---@param category string Exact category from settings.list().
---@param name string Exact setting name from settings.list().
---@return DoubleTapSnapshot|ToggleIndicator
function indicators.get(category, name) end
---@return {valid: boolean, weapon_type: integer, item_id: integer, tick: integer, time: number, spread: number, inaccuracy: number, scoped: boolean, range: number, eye: Vector3}
function combat.context() end
---@return {item_id: integer, is_revolver: boolean, client_tick: integer, tick_base: integer, ready_tick: integer, next_primary_tick: integer, next_secondary_tick: integer, ammo: integer, reloading: boolean, can_start_primary: boolean, postponed_primary_ready: boolean}?
function combat.weapon_state() end
---Return native spread correction for the supplied aim/tick, or nil if no solution.
---@param aim Vector3
---@param tick? integer
---@param hidden_shot? boolean
---@return Vector3?
function combat.spread_correction(aim, tick, hidden_shot) end
---Sample the current weapon's native spread for an exact command angle/tick.
---@param angles Vector3
---@param tick? integer
---@return {seed: integer, x: number, y: number}?
function combat.spread_sample(angles, tick) end
---@param target_id integer
---@param world_point Vector3
---@return {damage: number, hitbox: integer, hitgroup: integer, penetrated: boolean}?
---@param record_tick? integer Must still be an available non-future record.
function combat.damage(target_id, world_point, record_tick) end
---@return boolean
---@param ignore_next_attack? boolean Still checks reload/ammo; useful while an R8 cock is already held.
function combat.can_shoot(ignore_next_attack) end
---@return Vector3?
function combat.aim_punch() end
---@param target_id integer
---@return {tick: integer, time: number, origin: Vector3, velocity: Vector3, ducked: boolean, extrapolated: boolean}[]
function combat.records(target_id) end

trace = {}
---@param start Vector3
---@param finish Vector3
---@param skip_player_id? integer
---@return {fraction: number, end_pos: Vector3, normal: Vector3, all_solid: boolean}
function trace.line(start, finish, skip_player_id) end

render = {}
---@param x number
---@param y number
---@param text string
---@param color Color
---@param font? integer Handle obtained by this script in paint.
function render.text(x, y, text, color, font) end
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param color Color
---@param thickness? number
function render.line(x1, y1, x2, y2, color, thickness) end
---@param x number
---@param y number
---@param width number
---@param height number
---@param color Color
---@param filled? boolean
function render.rect(x, y, width, height, color, filled) end
---@param x number
---@param y number
---@param radius number
---@param color Color
---@param filled? boolean
function render.circle(x, y, radius, color, filled) end
---@param text string
---@return number width
---@return number height
---@param font? integer Custom fonts require paint.
function render.measure_text(text, font) end
---@param world Vector3
---@return number? x
---@return number? y
---@return boolean? on_screen
function render.world_to_screen(world) end

ui = {}
---@param kind 'checkbox'|'slider'|'combo'|'color'|'text'
---@param id string
---@param label string
---@param default any
---@param min_or_options? number|string[]|{key: integer, mode: integer} Checkbox accepts optional bind table (key 0..255; mode 0 toggle, 1 hold_on; legacy 2 is normalized to toggle).
---@param max? number
---@return string id
function ui.create(kind, id, label, default, min_or_options, max) end
---@param id string
---@return any
function ui.get(id) end
---@param id string
---@param value any
function ui.set(id, value) end
---@param id string Checkbox control id.
---@param key? integer Windows VK 0..255; 0 removes the key.
---@param mode? integer 0 toggle, 1 hold_on; legacy 2 is normalized to toggle.
---@return {key: integer, mode: integer, active: boolean} bind
function ui.bind(id, key, mode) end

---@class MenuLanguage
---@field id string
---@field name string
---@field font? string Custom font basename in %LOCALAPPDATA%/skeet
---@field font_size? number Custom menu font size in pixels

---Registers/replaces this script's UTF-8 menu dictionary. Built-ins en/zh-CN/pt-BR are reserved.
---Removed on script unload/error; missing entries fall back to the original English text.
---Applies only to Skeet's native interface/editor shell; Lua UI, source and logs stay literal.
---@param id string ASCII letters/digits/-/_, 1..48 bytes
---@param name string UTF-8 display name, 1..96 bytes
---@param translations table<string,string> English visible text => UTF-8 translation
---@return boolean success False for another owner's ID or registry limit
function ui.register_language(id, name, translations) end
---@param id string
---@return boolean removed Only the owning script can remove a custom dictionary
function ui.unregister_language(id) end
---Associates a local TTF/OTF/TTC/OTC file with this script's registered language.
---CPU validation happens now; GPU font creation is deferred to the next menu frame.
---nil filename removes the language font, falling back to a menu override or the default.
---Lua UI/source/logs retain their own fonts.
---@param id string This script's language ID; built-ins/other owners are protected
---@param filename? string UTF-8 basename directly in %LOCALAPPDATA%/skeet
---@param size? number 8..24 pixels, default 11; one size across the native interface
---@return boolean success
---@return string? error File/format/ownership/cache failure; previous selection is preserved
function ui.set_language_font(id, filename, size) end
---Sets this script's default menu font without changing the selected language.
---A font attached to the selected language takes priority. Latest live default override wins.
---@param filename? string Basename in %LOCALAPPDATA%/skeet; nil releases this script's override
---@param size? number 8..24 pixels, default 11
---@return boolean success
---@return string? error
function ui.set_menu_font(filename, size) end
---@class MenuFontInfo
---@field language string Effective language ID
---@field source 'default'|'menu'|'language'
---@field filename? string Custom font basename
---@field size? number Custom font size
---@return MenuFontInfo font Metadata; GPU creation is deferred
function ui.get_menu_font() end
---@class LuaWindowOptions
---@field key? integer 0 follows Skeet; 1..255 uses a separate VK toggle key
---@field open? boolean Default true for key=0; false for a separate key
---@field x? number Default 120
---@field y? number Default 120
---@field width? number 180..1600, default 320
---@field height? number 120..1600, default 360
---@class LuaWindowInfo
---@field id string
---@field title string
---@field key integer
---@field open boolean Effective visibility
---@field follows_menu boolean
---@field x number
---@field y number
---@field width number
---@field height number
---Registers an interactive, draggable/resizable script window; at most 8 per script.
---@param id string Unique script-owned UTF-8 ID, 1..80 bytes
---@param title string Script-authored UTF-8 title, 1..160 bytes
---@param options? LuaWindowOptions
---@return string id
function ui.create_window(id, title, options) end
---Moves an existing ui.create control into this script's window; nil restores Config placement.
---@param control_id string
---@param window_id? string
function ui.attach_window(control_id, window_id) end
---@param id string
---@param key? integer Query if omitted; 0 follows Skeet, 1..255 independent VK key
---@return {key: integer, open: boolean, follows_menu: boolean} bind
function ui.window_bind(id, key) end
---@param id string
---@param open boolean Follow-mode windows remain hidden while Skeet is closed
function ui.set_window_open(id, open) end
---@param id string
---@return LuaWindowInfo window
function ui.get_window(id) end
---@return string id Effective language ID; en when the saved custom ID is unavailable
function ui.get_language() end
---@param id string
---@return boolean success False for an unknown ID; selection is saved with the config
function ui.set_language(id) end
---@param text string
---@param id? string Defaults to the effective menu language
---@return string text Unknown language/key returns the original text
function ui.translate(text, id) end
---@return string[] keys Sorted English menu text, without ## suffixes
function ui.get_translation_keys() end
---@return MenuLanguage[] languages English, Simplified Chinese, Brazilian Portuguese, then custom IDs in alphabetical order
function ui.get_languages() end

storage = {}
---@param key string
---@param default? any
---@return any
function storage.get(key, default) end
---@param key string 1..128 bytes.
---@param value any Pass nil to remove the key. Total serialized storage <=64 KiB; saved periodically and on unload.
function storage.set(key, value) end

---@class CustomModel
---@field id string Relative compiled file under game/csgo/characters/models, e.g. fatality/sas/player.vmdl_c.
---@field path string Virtual CS2 path passed to the player-model setter.

models = {}
---Excludes arm/arms/hand/hands filename tokens (case-insensitive; separators _, -, .).
---@return CustomModel[] models Up to 512 compiled models found under CS2 game/csgo/characters/models; filename filtering does not validate model contents.
function models.list() end
---@param id string ID returned by models.list().
---Compatible legacy CS body rigs are adapted in-match and in the main-menu character; selection is not animation validation.
---@return string path Virtual model path; this script's choice overrides the built-in agent changer while enabled.
function models.set(id) end
---Release this script's choice. The next Lua choice, built-in agent or native model is applied on a game frame.
function models.clear() end
---@return string? path This script's current virtual model path, or nil.
function models.current() end
---@return 'idle'|'ready'|'error' status Ready confirms file existence, not engine rendering.
---@return string? message Error detail when status is error.
function models.status() end

chams = {}
---@return string[] targets enemy, enemy_invisible, team, team_invisible, local, arms, weapon, attachments.
function chams.targets() end
---@param name string "bloom", "glow", "flat" or "glass". Load phase only.
---@return integer? handle Script-local handle with visible and ignorez variants.
---@return string? error "material_unavailable" on native failure.
function chams.builtin_material(name) end
---@param visible_path string Virtual materials/.../*.vmat or .vmat_c resource path. Load phase only.
---@param ignorez_path string? Optional separately authored ignorez material path.
---@return integer? handle Script-local handle; no ignorez variant unless explicitly provided.
---@return string? error Missing resource/interface errors; invalid arguments raise a Lua error.
function chams.load_material(visible_path, ignorez_path) end
---@param brightness number 0.1..8. Only allowed while the script loads.
---@param tint Color RGB baked into a new solidcolor material; alpha is ignored.
---@return integer handle Script-local handle, valid until the script is unloaded.
function chams.create_material(brightness, tint) end
---@param target string One of chams.targets().
---attachments: local owned inventory weapons in thirdperson, including held and holstered pistol/knife models.
---@param handle integer? Script-local material handle; nil releases this target.
---@param color Color? Render RGBA; required unless handle is nil.
function chams.set(target, handle, color) end

-- Read-only combat queries and math helpers.
---@class HitboxSnapshot
---@field index integer Hitbox index, not bone index.
---@field bone integer
---@field radius number
---@field mins Vector3 Hitbox-local minimum.
---@field maxs Vector3 Hitbox-local maximum.
---@field center Vector3 World-space center.
---@field capsule_a Vector3 World-space transformed mins endpoint.
---@field capsule_b Vector3 World-space transformed maxs endpoint.
---@field rotation {x:number,y:number,z:number,w:number} Bone quaternion.

---@class Vector2
---@field x number
---@field y number


---Command callbacks only. nil if the record expired; latest record if tick omitted.
---@param id integer
---@param record_tick? integer
---@return {tick: integer, time: number, hitboxes: HitboxSnapshot[]}?
function combat.hitboxes(id, record_tick) end
---At most 32 queries per command. Head probability excludes samples that first hit another hitbox of the target; no per-sample world traces.
---@param id integer
---@param point Vector3
---@param hitbox integer 0..18
---@param record_tick? integer
---@return number? percentage 0..100
function combat.hitchance(id, point, hitbox, record_tick) end

---Deferred self-unload after the current callback returns.
function client.unload() end
---paint only.
---@return boolean
function ui.is_menu_opened() end
---paint only. Screen pixels.
---@return {x: number, y: number, w: number, h: number}
function ui.get_menu_rect() end
---paint only. Current-frame mouse coordinates in screen pixels; clicked is a new left press, down is held.
---All paint callbacks see the same click. Drag only while the menu is open; stop on release or menu close.
---@return {x: number, y: number, down: boolean, clicked: boolean}
function ui.mouse_state() end
---@param src Vector3
---@param dst Vector3
---@return Vector3 angles Degrees.
function math.calc_angle(src, dst) end
---@param src Vector3
---@param dst Vector3
---@return number degrees
function math.calc_fov(src, dst) end
---@param degrees number
---@return number degrees -180..180
function math.normalize_angle(degrees) end
---@param forward Vector3
---@return Vector3 angles
function math.vector_angles(forward) end
---@param angles Vector3
---@return Vector3 forward
---@return Vector3 right
---@return Vector3 up
function math.angle_vectors(angles) end

-- Render additions. Drawing, resource creation and UI geometry require paint.
---@return integer count Number of scripting paint passes since DLL initialization.
function render.frame_count() end
---@return number seconds
function render.frame_time() end
---@return integer width
---@return integer height
function render.screen_size() end
---@param x number
---@param y number
---@param w number
---@param h number
---@param tl Color
---@param tr Color
---@param br Color
---@param bl Color
function render.rect_filled_fade(x, y, w, h, tl, tr, br, bl) end
---@param points Vector2[] 2..256 points.
---@param color Color
---@param thickness? number 0.1..100, default 1.
---@param closed? boolean Default false.
function render.poly_line(points, color, thickness, closed) end
---@param points Vector2[] 3..256 vertices; simple polygon without holes.
---@param color Color
function render.polygon(points, color) end
---@param points Vector2[] Same contract as polygon.
---@param color Color
function render.concave_polygon(points, color) end
---@param x number
---@param y number
---@param radius number
---@param start_angle number Radians.
---@param end_angle number Radians.
---@param color Color
---@param thickness? number Default 1.
---@param segments? integer 2..256, default 64.
function render.arc(x, y, radius, start_angle, end_angle, color, thickness, segments) end
---@param x number
---@param y number
---@param width number
---@param height number
function render.push_clip_rect(x, y, width, height) end
function render.pop_clip_rect() end
---@param x number
---@param y number
---@param radius number
---@param inside Color
---@param outside Color
function render.circle_fade(x, y, radius, inside, outside) end
---@param position Vector3
---@param radius number
---@param color Color
---@param normal? Vector3 Default {x=0,y=0,z=1}.
function render.circle_3d(position, radius, color, normal) end
---@param position Vector3
---@param radius number
---@param color Color
---@param normal? Vector3
function render.circle_filled_3d(position, radius, color, normal) end
---@param position Vector3
---@param radius number
---@param inside Color
---@param outside Color
---@param normal? Vector3
function render.circle_fade_3d(position, radius, inside, outside, normal) end
---@param basename string File under config_dir/resources/<basename>, or skeetles/name.png under config_dir/skeetles; at most 4 MiB.
---@return integer? texture Handle; nil on missing/unsupported image.
---@return string? error Resource failure code; nil on success.
function render.setup_texture(basename) end
---@param bytes string Binary encoded image, at most 4 MiB.
---@return integer? texture
---@return string? error Resource failure code; nil on success.
function render.setup_texture_from_memory(bytes) end
---@param bytes string Raw RGBA bytes; exactly width*height*4.
---@param width integer 1..4096, total pixels at most 1048576.
---@param height integer 1..4096
---@return integer? texture
---@return string? error Resource failure code; nil on success.
function render.setup_texture_rgba(bytes, width, height) end
---@param width integer 1..4096; total pixels <=1048576.
---@param height integer
---@return integer? texture Mutable, private to this script; retained/reused after unload.
---@return string? error
function render.create_texture_rgba(width, height) end
---@param texture integer Handle from render.create_texture_rgba.
---@param bytes string Exactly width*height*4 RGBA bytes; call before drawing this frame.
---@return boolean? success
---@return string? error
function render.update_texture_rgba(texture, bytes) end
---@param texture integer Handle from render.create_texture_rgba.
---@param bytes string Pixel bytes, <=4 MiB; at least pitch*(height-1)+row_bytes, at most pitch*height.
---@param format 'rgba8'|'bgra8'|'bgrx8'|'rgb565'|'rgb555' 16-bit formats use little-endian words.
---@param pitch? integer Bytes per source row; default tightly packed; >=width*bytes_per_pixel.
---@return boolean? success
---@return string? error Resource error; invalid arguments raise a Lua error.
function render.update_texture_pixels(texture, bytes, format, pitch) end
---@param texture integer Handle returned to this script.
---@return integer width Original pixel width.
---@return integer height Original pixel height.
function render.texture_size(texture) end
---@param texture integer Handle returned to this script.
---@param x number
---@param y number
---@param width number
---@param height number
---@param tint? Color Default white.
---@param rounding? number Default 0.
function render.texture(texture, x, y, width, height, tint, rounding) end
---@param texture integer Handle returned to this script.
---@param center_x number Rotation center in screen pixels.
---@param center_y number Rotation center in screen pixels.
---@param width number Drawn width.
---@param height number Drawn height.
---@param angle number Clockwise rotation in radians.
---@param tint? Color Default white.
function render.texture_rotated(texture, center_x, center_y, width, height, angle, tint) end
---@param basename string TTF/OTF under config_dir/resources/<basename>, or fonts/<basename> under config_dir/fonts.
---@param size number 6..96 pixels.
---@return integer? font
---@return string? error Resource failure code; nil on success.
function render.setup_font(basename, size) end
---Override built-in ESP labels, keybinds or watermark with a font loaded by this script.
---Call in paint; pass nil to release this script's override.
---@param target 'esp'|'keybinds'|'watermark'
---@param font? integer
function render.builtin_font(target, font) end

-- Native XUI windows and menu themes. See XUI.ru.md and UI.ru.md.

---@class XuiWindowOptions
---@field x? number Default 120, screen pixels.
---@field y? number Default 120, screen pixels.
---@field width? number 180..1600; default 320.
---@field height? number 120..1600; default 360.
---@field key? integer Windows VK 0..255; 0 follows the main menu, default 0.
---@field open? boolean Default true for key=0, otherwise false.
---@field titlebar? boolean Default true, including the close button.
---@field background? boolean Default true, blurred backdrop with style tint.
---@field movable? boolean Default true; top 30 pixels are the drag region.
---@field resizable? boolean Default true.
---@field padding? number 0..100, horizontal inset; titleless windows also use it vertically.
---@class XuiItemState
---@field x number Screen pixels.
---@field y number Screen pixels.
---@field width number
---@field height number
---@field hovered boolean Includes overlay, window and clipping checks.
---@field down boolean Mouse held over the region; no capture outside its bounds.
xui = {}
---@param id string
---@param title string
---@param options XuiWindowOptions
---@param callback fun() Runs once per visible rendered frame, inside its own XUI window.
---@return string
function xui.create_window(id, title, options, callback) end
---@param text string
---@param color? Color
function xui.text(text, color) end
---@return boolean
---@param label string
---@param width? number Available width by default.
---@param height? number Default 24.
function xui.button(label, width, height) end
---@return boolean, boolean
---@param label string
---@param value boolean
function xui.checkbox(label, value) end
---@return number, boolean
---@param label string
---@param value number
---@param minimum number
---@param maximum number
function xui.slider_float(label, value, minimum, maximum) end
---@return integer, boolean
---@param label string
---@param value integer
---@param minimum integer
---@param maximum integer
function xui.slider_int(label, value, minimum, maximum) end
---@return string, boolean
---@param label string
---@param value string
---@param capacity? integer 1..16384 bytes, default 4096.
---@param hint? string
function xui.input_text(label, value, capacity, hint) end
---@return integer, boolean
---@param label string
---@param selected integer 1-based.
---@param items string[] 1..128 entries.
---@param width? number
function xui.combo(label, selected, items, width) end
---@return boolean[], boolean
---@param label string
---@param selected boolean[] Same length as items.
---@param items string[] 1..128 entries.
function xui.multicombo(label, selected, items) end
---@return Color, boolean
---@param label string
---@param color Color
function xui.color_picker(label, color) end
---@param spacing? number Gap after the preceding item; 0 uses the current style.
function xui.same_line(spacing) end
---@param pixels number
function xui.spacing(pixels) end
---@return number?, number?
---@param x? number Omit both arguments to query.
---@param y? number Required when setting x.
function xui.cursor(x, y) end
---@return number, number
function xui.available() end
---@return {x:number, y:number, width:number, height:number} Screen pixels.
function xui.window_rect() end
---@return boolean
---Call end_child only when this returns true.
---@param id string
---@param width? number Default 0.
---@param height? number Default 0.
---@param scrollable? boolean Default false.
function xui.begin_child(id, width, height, scrollable) end
function xui.end_child() end
---@param id string
function xui.push_id(id) end
function xui.pop_id() end
---@param name string
---@param color Color
function xui.push_style_color(name, color) end
function xui.pop_style_color() end
---@param name string One of the 28 XUI scalar style variables.
---@param value number 0..1000.
function xui.push_style_var(name, value) end
function xui.pop_style_var() end
---@param font? integer Owned render font handle
---@param  nil selects default.
function xui.push_font(font) end
function xui.pop_font() end
---@param x number
---@param y number
---@param x2 number
---@param y2 number
---@param color Color
---@param thickness? number Default 1, clamped 0.1..100.
function xui.line(x, y, x2, y2, color, thickness) end
---@param x number
---@param y number
---@param width number
---@param height number
---@param color Color
---@param rounding? number Default 0, clamped 0..100.
---@param thickness? number Default 1, clamped 0.1..100.
function xui.rect(x, y, width, height, color, rounding, thickness) end
---@param x number
---@param y number
---@param width number
---@param height number
---@param color Color
---@param rounding? number Default 0, clamped 0..100.
function xui.rect_filled(x, y, width, height, color, rounding) end
---@param x number
---@param y number
---@param width number
---@param height number
---@param color Color
---@param rounding? number Default 0, clamped 0..100.
function xui.blur(x, y, width, height, color, rounding) end
---@param x number
---@param y number
---@param text string
---@param color Color
---@param font? integer Owned render font handle.
function xui.text_at(x, y, text, color, font) end
---@param x number
---@param y number
---@param radius number Clamped 0..10000.
---@param color Color
---@param filled? boolean Default false.
---@param thickness? number Default 1, clamped 0.1..100.
function xui.circle(x, y, radius, color, filled, thickness) end
---@param texture integer Owned render texture handle.
---@param width number
---@param height number
function xui.image(texture, width, height) end
---@return boolean
---Inline animated section. Width is reserved; content uses the available row width.
---@param expanded? boolean Default true; pass a checkbox value for collapsible content.
---@param id string
---@param width? number Reserved by current layout, default 200.
function xui.begin_popup(id, width, expanded) end
function xui.end_popup() end
---@return integer, boolean
---@param label string
---@param key integer 0..255 Windows VK.
function xui.keybind(label, key) end

---Classic menu button presentation; default width is available width, height 24.
---@return boolean clicked
---@param label string
---@param width? number Available width by default.
---@param height? number Default 24.
function xui.menu_button(label, width, height) end
function xui.separator() end
---Absolute screen coordinates; colors ordered clockwise from top-left. Does not advance layout.
---@param x number
---@param y number
---@param width number
---@param height number
---@param top_left Color
---@param top_right Color
---@param bottom_right Color
---@param bottom_left Color
---@param rounding? number Default 0, clamped 0..100.
function xui.gradient(x, y, width, height, top_left, top_right, bottom_right, bottom_left, rounding) end
---Intersect the current window clip. pop_clip must be the next matching scope close.
---@param x number
---@param y number
---@param width number
---@param height number
function xui.push_clip(x, y, width, height) end
function xui.pop_clip() end
---@return {x:number, y:number, dx:number, dy:number, down:boolean, clicked:boolean, released:boolean, right_down:boolean, right_clicked:boolean, wheel:number}
function xui.mouse_state() end
---Reserve a layout item and hit-test it, without drawing. Stable label/ID required.
---@return boolean clicked New left press, not release.
---@return XuiItemState state
---@param label string
---@param width number
---@param height number
function xui.invisible_button(label, width, height) end

---@param backend 'menu'|'xui'
---@return string[]
function ui.style_colors(backend) end
---@param backend 'menu'|'xui'
---@param name string
---@param color? Color nil removes this script's color override.
function ui.set_style_color(backend, name, color) end
---@param surface 'sidebar'|'header'|'body'|'surface'|'card'|'control'
---@param opacity? number 0..1; nil removes this script's override.
function ui.set_blur_opacity(surface, opacity) end
function ui.reset_theme() end

---@class MenuTabStyle
---@field title? string UTF-8 literal caption, 1..96 bytes, no ## or line breaks.
---@field icon? string UTF-8 icon/glyph text, 1..16 bytes; default ">".
---@field icon_texture? integer Owned render texture handle; 0 restores glyph icon.
---@field active_icon? string Selected glyph; omitted uses icon.
---@field active_icon_texture? integer Owned selected texture; 0 uses icon_texture. Create textures in paint.
---@field text_color? Color Reserved caption metadata; native section titles keep the menu theme.
---@field text_colors? Color[] Reserved caption metadata; at most 96 entries, not drawn by the icon-only sidebar.
---@field icon_color? Color Glyph/image tint.
---@field active_icon_color? Color Selected tint; defaults to white.
---@field background? Color Inactive row background.
---@field active_background? Color Selected row background.
---@param id string Script-local stable id, 1..80 UTF-8 bytes.
---@param title string Literal UTF-8 caption, 1..96 bytes.
---@param options? MenuTabStyle
---Claim the visible sixth menu slot. Only ONE active script may own it globally.
---The sidebar slot is hidden without an active owner; removing the selected slot returns to Config.
---A second claim raises an error; unload/failure or remove_tab releases the slot.
---Recommended for large comprehensive suites; small scripts should use the normal script page.
---@return string id One tab per owner. Controls also remain on the script page.
function ui.create_tab(id, title, options) end
---@param id string Owned tab id.
---@param options? MenuTabStyle Partial update; nil resets style/icon and preserves id/title/groups.
function ui.set_tab_style(id, options) end
---@param id string Owned tab id; controls remain on the script page.
function ui.remove_tab(id) end
---@param tab string Owned tab id.
---@param id string Stable group id, 1..80 bytes.
---@param title string Literal caption, 1..96 bytes.
---@param column? integer 1 left (default), 2 right. Up to 16 groups per tab.
---@param layout? MenuTabLayout Omit for equal-height cells per column. All groups must use the same layout mode.
---@return string id
function ui.create_tab_group(tab, id, title, column, layout) end
---@class MenuTabLayout
---@field top? number Top fraction 0..1, default 0.
---@field bottom? number Bottom fraction 0..1, default 1. Height must be at least 0.12.
---@field span? integer 1 column (default) or 2 (only from column 1). Cells must not overlap.
---@param control string Owned ui.create control.
---@param tab? string Owned slot id; controls remain on the script page; nil removes the association.
---@param group? string Required if the tab has groups. Otherwise nil uses a full-width default section.
function ui.attach_tab(control, tab, group) end

---Native grenade artwork, paint only; same owned texture handle as render.texture. One cached raster per kind.
---@param kind 'hegrenade'|'flashbang'|'smokegrenade'|'molotov'|'incgrenade'|'decoy'
---@return integer? handle
---@return integer|string width_or_error
---@return integer? height
function render.grenade_icon(kind) end
---Current map basename, or nil outside a session. No file path is returned.
---@return string?
function client.map_name() end
---Implemented features; false means unavailable, not a simulated success.
---@return {command_requests: boolean, prediction_snapshot: boolean, prediction_simulate: boolean, grenade_control: boolean, grenade_observations: boolean, grenade_icons: boolean, grenade_trajectory: boolean, inferno_geometry: boolean, radar_snapshot: boolean, double_tap_snapshot: boolean, custom_indicators: boolean, rage_control: boolean}
function api.capabilities() end
