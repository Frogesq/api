# Lua API 3: справочник функций

Сигнатуры, параметры и результаты всех доступных методов. Обозначения: `?` — необязательный аргумент или nil; `[]` — массив; `...` — переменное число аргументов/результатов. Типы Lua и имена ошибок сохраняют написание API.

Правила вызова и примеры находятся в руководстве соответствующего модуля. Описание структуры результата: [типы данных](TYPES.ru.md). Lua-значения возвращаются по порядку; несколько результатов не являются одной таблицей.

## Модули

- [api](#api) — [Среда и обработка ошибок](RUNTIME.ru.md).
- [audio](#audio) — [Звук](SERVICES.ru.md).
- [chams](#chams) — [Материалы](SERVICES.ru.md).
- [client](#client) — [Состояние скрипта и клиента](SERVICES.ru.md).
- [cmd](#cmd) — [Командные запросы](COMMANDS.ru.md).
- [combat](#combat) — [Расчёты и данные оружия](DATA.ru.md).
- [console](#console) — [Игровая консоль](SERVICES.ru.md).
- [entity](#entity) — [Сущности](DATA.ru.md).
- [events](#events) — [События](EVENTS.ru.md).
- [grenades](#grenades) — [Гранаты](GRENADES.ru.md).
- [indicators](#indicators) — [Индикаторы](INDICATORS.ru.md).
- [math](#math) — [Математика](DATA.ru.md).
- [models](#models) — [Модели](SERVICES.ru.md).
- [movement](#movement) — [Движение](COMMANDS.ru.md).
- [prediction](#prediction) — [Снимки prediction](COMMANDS.ru.md).
- [radar](#radar) — [Радар](RADAR.ru.md).
- [render](#render) — [Графика](RENDER.ru.md).
- [settings](#settings) — [Настройки и бинды](SETTINGS.ru.md).
- [storage](#storage) — [Сохранение](SERVICES.ru.md).
- [trace](#trace) — [Трассировка](DATA.ru.md).
- [ui](#ui) — [Контролы и оформление](UI.ru.md).
- [xui](#xui) — [Собственные окна XUI](XUI.ru.md).

## api

Руководство: [Среда и обработка ошибок](RUNTIME.ru.md).

### api.budget

`api.budget()`

Budget snapshot; querying it consumes a host API call. Finish callback when recovering=true.

Результаты:

- LuaBudget budget

### api.capabilities

`api.capabilities()`

Implemented features; false means unavailable, not a simulated success.

Результаты:

- {command_requests: boolean, prediction_snapshot: boolean, prediction_simulate: boolean, grenade_control: boolean, grenade_observations: boolean, grenade_icons: boolean, grenade_trajectory: boolean, inferno_geometry: boolean, radar_snapshot: boolean, double_tap_snapshot: boolean, custom_indicators: boolean, rage_control: boolean}

### api.protect

`api.protect(fn, limits)`

Catch ordinary errors and budget exhaustion. Allocation failures remain fatal. Pending command edits are restored on failure; settings, draws, UI and other effects are not rolled back. fn receives no arguments; use a closure.

| Аргумент | Тип и условия |
|---|---|
| `fn` | fun(): ... |
| `limits?` | {instructions?: integer, time_ms?: number} Defaults 1000000 / 25 ms; maxima 20000000 / 250 ms; parent limits apply. |

Результаты:

- boolean ok
- string? error Exact 'budget_exceeded' for budget failure; ordinary errors have a traceback; nil on success.
- ... results All fn results including nils on success; LuaBudgetError as third result on budget failure.


## audio

Руководство: [Звук](SERVICES.ru.md).

### audio.play

`audio.play(basename, loop)`

Prepared play uses retained PCM/voice. The first unprepared play loads synchronously.

| Аргумент | Тип и условия |
|---|---|
| `basename` | string MP3/WAV basename under %LOCALAPPDATA%/skeet/muzon, or sounds/<basename>.mp3/.wav under %LOCALAPPDATA%/skeet/sounds. |
| `loop?` | boolean Repeat until stopped. |

Результаты:

- boolean ok
- string? error

### audio.preload

`audio.preload(basename)`

Prepare once at top level during script loading. No playback is started.

| Аргумент | Тип и условия |
|---|---|
| `basename` | string MP3/WAV basename in muzon, or sounds/<basename>.mp3/.wav. Encoded file <=64 MiB; decoded PCM <=128 MiB. |

Результаты:

- boolean ok
- string? error

### audio.stop

`audio.stop()`

Stop playback but retain prepared sounds until script unload.

Значения не возвращаются.

### audio.volume

`audio.volume(percent)`

| Аргумент | Тип и условия |
|---|---|
| `percent` | number Finite; clamped to 0..100. Per-script volume, also accepted before playback. |

Результаты:

- boolean ok


## chams

Руководство: [Материалы](SERVICES.ru.md).

### chams.builtin_material

`chams.builtin_material(name)`

| Аргумент | Тип и условия |
|---|---|
| `name` | string "bloom", "glow", "flat" or "glass". Load phase only. |

Результаты:

- integer? handle Script-local handle with visible and ignorez variants.
- string? error "material_unavailable" on native failure.

### chams.create_material

`chams.create_material(brightness, tint)`

| Аргумент | Тип и условия |
|---|---|
| `brightness` | number 0.1..8. Only allowed while the script loads. |
| `tint` | Color RGB baked into a new solidcolor material; alpha is ignored. |

Результаты:

- integer handle Script-local handle, valid until the script is unloaded.

### chams.load_material

`chams.load_material(visible_path, ignorez_path)`

| Аргумент | Тип и условия |
|---|---|
| `visible_path` | string Virtual materials/.../*.vmat or .vmat_c resource path. Load phase only. |
| `ignorez_path` | string? Optional separately authored ignorez material path. |

Результаты:

- integer? handle Script-local handle; no ignorez variant unless explicitly provided.
- string? error Missing resource/interface errors; invalid arguments raise a Lua error.

### chams.set

`chams.set(target, handle, color)`

attachments: local owned inventory weapons in thirdperson, including held and holstered pistol/knife models.

| Аргумент | Тип и условия |
|---|---|
| `target` | string One of chams.targets(). |
| `handle` | integer? Script-local material handle; nil releases this target. |
| `color` | Color? Render RGBA; required unless handle is nil. |

Значения не возвращаются.

### chams.targets

`chams.targets()`

Результаты:

- string[] targets enemy, enemy_invisible, team, team_invisible, local, arms, weapon, attachments.


## client

Руководство: [Состояние скрипта и клиента](SERVICES.ru.md).

### client.frametime

`client.frametime()`

Результаты:

- number seconds

### client.key_down

`client.key_down(vk)`

| Аргумент | Тип и условия |
|---|---|
| `vk` | integer |

Результаты:

- boolean

### client.log

`client.log(...)`

| Аргумент | Тип и условия |
|---|---|
| `...` | any |

Значения не возвращаются.

### client.log_level

`client.log_level(level, ...)`

| Аргумент | Тип и условия |
|---|---|
| `level` | 'debug'&#124;'info'&#124;'warning'&#124;'error' |
| `...` | any |

Значения не возвращаются.

### client.map_name

`client.map_name()`

Current map basename, or nil outside a session. No file path is returned.

Результаты:

- string?

### client.screen_size

`client.screen_size()`

Результаты:

- integer width
- integer height

### client.stats

`client.stats()`

Результаты:

- ScriptStats

### client.time

`client.time()`

Результаты:

- number seconds Monotonic, not game time.

### client.unload

`client.unload()`

Deferred self-unload after the current callback returns.

Значения не возвращаются.


## cmd

Руководство: [Командные запросы](COMMANDS.ru.md).

### cmd.get

`cmd.get()`

Current command plus this script's staged values; post events are read-only.

Результаты:

- CommandSnapshot

### cmd.set_angles

`cmd.set_angles(angles, visible)`

Stage grenade view input in create_move after grenades.claim. Native firearm AA uses settings overrides.

| Аргумент | Тип и условия |
|---|---|
| `angles` | Vector3 Finite pitch clamped to -89..89, yaw normalized, roll zero. |
| `visible?` | boolean Also update camera on successful commit. |

Значения не возвращаются.

### cmd.set_button

`cmd.set_button(mask, pressed)`

create_move only. Movement buttons; attack/attack2 require active grenade claim. Other buttons rejected.

| Аргумент | Тип и условия |
|---|---|
| `mask` | integer |
| `pressed` | boolean |

Значения не возвращаются.

### cmd.set_button_state

`cmd.set_button_state(mask, held, changed, scroll)`

Stage held/changed/scroll bits; same phase and mask rules as set_button.

| Аргумент | Тип и условия |
|---|---|
| `mask` | integer |
| `held` | boolean |
| `changed` | boolean |
| `scroll` | boolean |

Значения не возвращаются.

### cmd.set_movement

`cmd.set_movement(forward, side, up)`

Stage normalized movement before native prediction; whole script dispatch must succeed.

| Аргумент | Тип и условия |
|---|---|
| `forward` | number -1..1 (clamped). |
| `side` | number -1..1; positive is left, matching the native movement model. |
| `up?` | number -1..1. |

Значения не возвращаются.


## combat

Руководство: [Расчёты и данные оружия](DATA.ru.md).

### combat.aim_punch

`combat.aim_punch()`

Результаты:

- Vector3?

### combat.can_shoot

`combat.can_shoot(ignore_next_attack)`

| Аргумент | Тип и условия |
|---|---|
| `ignore_next_attack?` | boolean Still checks reload/ammo; useful while an R8 cock is already held. |

Результаты:

- boolean

### combat.context

`combat.context()`

Результаты:

- {valid: boolean, weapon_type: integer, item_id: integer, tick: integer, time: number, spread: number, inaccuracy: number, scoped: boolean, range: number, eye: Vector3}

### combat.damage

`combat.damage(target_id, world_point, record_tick)`

| Аргумент | Тип и условия |
|---|---|
| `target_id` | integer |
| `world_point` | Vector3 |
| `record_tick?` | integer Must still be an available non-future record. |

Результаты:

- {damage: number, hitbox: integer, hitgroup: integer, penetrated: boolean}?

### combat.double_tap

`combat.double_tap()`

Read a copied native observation in any callback, including paint. No engine simulation or mutation. Command callbacks before final serialization can see unavailable. Always returns a table; retain copies freely, fetch again for freshness.

Результаты:

- DoubleTapSnapshot

### combat.hitboxes

`combat.hitboxes(id, record_tick)`

Command callbacks only. nil if the record expired; latest record if tick omitted.

| Аргумент | Тип и условия |
|---|---|
| `id` | integer |
| `record_tick?` | integer |

Результаты:

- {tick: integer, time: number, hitboxes: HitboxSnapshot[]}?

### combat.hitchance

`combat.hitchance(id, point, hitbox, record_tick)`

At most 32 queries per command. Head probability excludes samples that first hit another hitbox of the target; no per-sample world traces.

| Аргумент | Тип и условия |
|---|---|
| `id` | integer |
| `point` | Vector3 |
| `hitbox` | integer 0..18 |
| `record_tick?` | integer |

Результаты:

- number? percentage 0..100

### combat.records

`combat.records(target_id)`

| Аргумент | Тип и условия |
|---|---|
| `target_id` | integer |

Результаты:

- {tick: integer, time: number, origin: Vector3, velocity: Vector3, ducked: boolean, extrapolated: boolean}[]

### combat.spread_correction

`combat.spread_correction(aim, tick, hidden_shot)`

Return native spread correction for the supplied aim/tick, or nil if no solution.

| Аргумент | Тип и условия |
|---|---|
| `aim` | Vector3 |
| `tick?` | integer |
| `hidden_shot?` | boolean |

Результаты:

- Vector3?

### combat.spread_sample

`combat.spread_sample(angles, tick)`

Sample the current weapon's native spread for an exact command angle/tick.

| Аргумент | Тип и условия |
|---|---|
| `angles` | Vector3 |
| `tick?` | integer |

Результаты:

- {seed: integer, x: number, y: number}?

### combat.weapon_state

`combat.weapon_state()`

Результаты:

- {item_id: integer, is_revolver: boolean, client_tick: integer, tick_base: integer, ready_tick: integer, next_primary_tick: integer, next_secondary_tick: integer, ammo: integer, reloading: boolean, can_start_primary: boolean, postponed_primary_ready: boolean}?


## console

Руководство: [Игровая консоль](SERVICES.ru.md).

### console.clear_pending

`console.clear_pending()`

Cancel this script's queued requests; requests already handed to the engine are unaffected.

Результаты:

- integer removed

### console.exec

`console.exec(command)`

Queue game console commands for a following game frame-stage; true means queued.

| Аргумент | Тип и условия |
|---|---|
| `command` | string 1..1024 bytes; NUL forbidden. Game command batches are allowed. |

Результаты:

- boolean accepted
- string? reason console_unavailable, queue_full, rate_limited or script_stopping.

### console.print

`console.print(text)`

Queue literal text in the game console, with a trailing newline. Percent signs are literal.

| Аргумент | Тип и условия |
|---|---|
| `text` | string Up to 2048 bytes; NUL forbidden. |

Результаты:

- boolean accepted
- string? reason

### console.say

`console.say(text, team_only)`

Queue a single quoted say/say_team command, without command injection.

| Аргумент | Тип и условия |
|---|---|
| `text` | string 1..200 UTF-8 bytes; controls, quotes, backslashes and semicolons forbidden. |
| `team_only?` | boolean Defaults to false. |

Результаты:

- boolean accepted
- string? reason


## entity

Руководство: [Сущности](DATA.ru.md).

### entity.bone

`entity.bone(id, bone_index)`

| Аргумент | Тип и условия |
|---|---|
| `id` | integer |
| `bone_index` | integer 0..127 |

Результаты:

- Vector3?

### entity.bounds

`entity.bounds(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | integer |

Результаты:

- {x: number, y: number, w: number, h: number}?

### entity.get

`entity.get(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | integer |

Результаты:

- PlayerSnapshot?

### entity.items

`entity.items()`

Результаты:

- {id: integer, class_hash: integer, origin: Vector3}[]

### entity.local_player

`entity.local_player()`

Результаты:

- PlayerSnapshot?

### entity.players

`entity.players(enemies_only)`

| Аргумент | Тип и условия |
|---|---|
| `enemies_only?` | boolean |

Результаты:

- PlayerSnapshot[]

### entity.weapon

`entity.weapon(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | integer |

Результаты:

- {item_id: integer, ammo: integer, reloading: boolean}?


## events

Руководство: [События](EVENTS.ru.md).

### events.off

`events.off(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | integer |

Результаты:

- boolean removed

### events.on

`events.on(name, callback)`

| Аргумент | Тип и условия |
|---|---|
| `name` | EventName |
| `callback` | fun(event: table) Callback return values are ignored. |

Результаты:

- integer subscription

Дополнительная типизированная форма: `fun(name: 'game_event', callback: fun(event: GameEvent)): integer`.


## grenades

Руководство: [Гранаты](GRENADES.ru.md).

### grenades.cancel

`grenades.cancel()`

Discard this script's pending command request. Does not undo published commands or unthrow a primed grenade.

Значения не возвращаются.

### grenades.claim

`grenades.claim()`

create_move only; authorize grenade angles/attack for the same weapon handle and suppress native AA for this command.

Результаты:

- boolean claimed False when no active grenade exists.

### grenades.context

`grenades.context()`

Current grenade; all command callbacks. Missing optional schema data is nil, never guessed.

Результаты:

- {item_id: integer, handle: integer, command_number: integer, pin_pulled: boolean?, throw_time: number?, strength: number?}?

### grenades.observations

`grenades.observations(paths)`

Copied observations, at most 128. First call can be empty until the next render-start update; minimum refresh interval 8/16/50 ms according to active forecasts, expiry 250 ms.

| Аргумент | Тип и условия |
|---|---|
| `paths?` | boolean Request cached flight predictions; false by default. Does not trace in paint. |

Результаты:

- GrenadeObservation[]

### grenades.predict

`grenades.predict(origin, velocity, item_id, age)`

Command callbacks only. Bounded hull-trace prediction; does not run player prediction or edit commands.

| Аргумент | Тип и условия |
|---|---|
| `origin` | Vector3 Initial position in world units; magnitude at most 10000000. |
| `velocity` | Vector3 Initial units per second; magnitude at most 100000. |
| `item_id` | integer 43..48. |
| `age?` | number Seconds since release, finite and nonnegative; default 0. |

Результаты:

- GrenadePath path Check valid and complete; never treat a budget-truncated endpoint as a landing.

### grenades.predict_throw

`grenades.predict_throw(angles, strength)`

Command callbacks only. Predict from the validated current first-person eye or pawn origin + view offset in third person, using the actual held grenade; does not throw it.

| Аргумент | Тип и условия |
|---|---|
| `angles` | Vector3 Desired pitch/yaw in degrees; pitch clamped to -89..89, roll ignored. |
| `strength` | number 0..1: secondary 0, both buttons 0.5, primary 1; intermediate strength is allowed. |

Результаты:

- GrenadePath path May report no_active_grenade, player_velocity_unavailable, player_eye_unavailable, throw_origin_unavailable_or_budget, throw_origin_start_solid or throw_origin_invalid_collision. Missing native throw velocity uses the standard 750 profile.

### grenades.preview

`grenades.preview()`

Request/read the held grenade preview from the game-thread cache. No command writes; first call may return nil.

Результаты:

- GrenadePath? path Approximate physics, including incomplete results; check valid and complete.
- string? reason snapshot_unavailable or preview_unavailable when no path exists.


## indicators

Руководство: [Индикаторы](INDICATORS.ru.md).

### indicators.get

`indicators.get(category, name)`

Read-only snapshot in any callback. The ragebot/double tap pair returns native DT state. Other Boolean settings return toggle state; missing, ambiguous or non-Boolean fields raise an error. No charge is invented for other features.

| Аргумент | Тип и условия |
|---|---|
| `category` | string Exact category from settings.list(). |
| `name` | string Exact setting name from settings.list(). |

Результаты:

- DoubleTapSnapshot&#124;ToggleIndicator


## math

Руководство: [Математика](DATA.ru.md).

### math.angle_vectors

`math.angle_vectors(angles)`

| Аргумент | Тип и условия |
|---|---|
| `angles` | Vector3 |

Результаты:

- Vector3 forward
- Vector3 right
- Vector3 up

### math.calc_angle

`math.calc_angle(src, dst)`

| Аргумент | Тип и условия |
|---|---|
| `src` | Vector3 |
| `dst` | Vector3 |

Результаты:

- Vector3 angles Degrees.

### math.calc_fov

`math.calc_fov(src, dst)`

| Аргумент | Тип и условия |
|---|---|
| `src` | Vector3 |
| `dst` | Vector3 |

Результаты:

- number degrees

### math.normalize_angle

`math.normalize_angle(degrees)`

| Аргумент | Тип и условия |
|---|---|
| `degrees` | number |

Результаты:

- number degrees -180..180

### math.vector_angles

`math.vector_angles(forward)`

| Аргумент | Тип и условия |
|---|---|
| `forward` | Vector3 |

Результаты:

- Vector3 angles


## models

Руководство: [Модели](SERVICES.ru.md).

### models.clear

`models.clear()`

Release this script's choice. The next Lua choice, built-in agent or native model is applied on a game frame.

Значения не возвращаются.

### models.current

`models.current()`

Результаты:

- string? path This script's current virtual model path, or nil.

### models.list

`models.list()`

Excludes arm/arms/hand/hands filename tokens (case-insensitive; separators _, -, .).

Результаты:

- CustomModel[] models Up to 512 compiled models found under CS2 game/csgo/characters/models; filename filtering does not validate model contents.

### models.set

`models.set(id)`

Compatible legacy CS body rigs are adapted in-match and in the main-menu character; selection is not animation validation.

| Аргумент | Тип и условия |
|---|---|
| `id` | string ID returned by models.list(). |

Результаты:

- string path Virtual model path; this script's choice overrides the built-in agent changer while enabled.

### models.status

`models.status()`

Результаты:

- 'idle'&#124;'ready'&#124;'error' status Ready confirms file existence, not engine rendering.
- string? message Error detail when status is error.


## movement

Руководство: [Движение](COMMANDS.ru.md).

### movement.claim

`movement.claim(feature)`

Disable the selected native movement mode for this command after successful create_move dispatch.

| Аргумент | Тип и условия |
|---|---|
| `feature` | 'bhop'&#124;'strafe' |

Значения не возвращаются.

### movement.context

`movement.context()`

Prestate for the current command, nil when local player/movement/scene is unavailable.

Результаты:

- MovementSnapshot?


## prediction

Руководство: [Снимки prediction](COMMANDS.ru.md).

### prediction.before

`prediction.before()`

Alias of movement.context; no second prediction transaction is run.

Результаты:

- MovementSnapshot?

### prediction.result

`prediction.result()`

Actual native prediction result in prediction/post callbacks; nil before prediction or on invalid output.

Результаты:

- {valid: boolean, command_number: integer, phase: string, tick: integer, flags: integer, move_type: integer, origin: Vector3, velocity: Vector3, landed: boolean, landed_fraction: number}?


## radar

Руководство: [Радар](RADAR.ru.md).

### radar.project

`radar.project(world, center, yaw, range, x, y, size, rotate, clamp_edge)`

Pure coordinate conversion; does not read entities or trace. Rotation keeps camera forward at the top.

| Аргумент | Тип и условия |
|---|---|
| `world` | Vector3 Position to project. |
| `center` | Vector3 Radar center in world space, usually snapshot.center. |
| `yaw` | number Camera heading in degrees; ignored when rotate=false. |
| `range` | number Positive world distance from radar center to an edge. |
| `x` | number Screen X of the square's top-left corner. |
| `y` | number Screen Y of the square's top-left corner. |
| `size` | number Positive square side in pixels. |
| `rotate?` | boolean Default true; false keeps +X right and +Y up. |
| `clamp_edge?` | boolean Default true; outside points are clamped along the direction to the square edge. |

Результаты:

- number x Screen coordinate.
- number y Screen coordinate.
- boolean inside Whether the original point was inside the square before clamping.

### radar.snapshot

`radar.snapshot(paths)`

Request/read copied client data; usable in paint. Nil outside a valid session or while the first snapshot is pending. No map texture is supplied.

| Аргумент | Тип и условия |
|---|---|
| `paths?` | boolean Also request cached grenade trajectories; default false. |

Результаты:

- RadarSnapshot? snapshot
- string? reason snapshot_unavailable when nil.


## render

Руководство: [Графика](RENDER.ru.md).

### render.arc

`render.arc(x, y, radius, start_angle, end_angle, color, thickness, segments)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `radius` | number |
| `start_angle` | number Radians. |
| `end_angle` | number Radians. |
| `color` | Color |
| `thickness?` | number Default 1. |
| `segments?` | integer 2..256, default 64. |

Значения не возвращаются.

### render.builtin_font

`render.builtin_font(target, font)`

Override built-in ESP labels, keybinds or watermark with a font loaded by this script. Call in paint; pass nil to release this script's override.

| Аргумент | Тип и условия |
|---|---|
| `target` | 'esp'&#124;'keybinds'&#124;'watermark' |
| `font?` | integer |

Значения не возвращаются.

### render.circle

`render.circle(x, y, radius, color, filled)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `radius` | number |
| `color` | Color |
| `filled?` | boolean |

Значения не возвращаются.

### render.circle_3d

`render.circle_3d(position, radius, color, normal)`

| Аргумент | Тип и условия |
|---|---|
| `position` | Vector3 |
| `radius` | number |
| `color` | Color |
| `normal?` | Vector3 Default {x=0,y=0,z=1}. |

Значения не возвращаются.

### render.circle_fade

`render.circle_fade(x, y, radius, inside, outside)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `radius` | number |
| `inside` | Color |
| `outside` | Color |

Значения не возвращаются.

### render.circle_fade_3d

`render.circle_fade_3d(position, radius, inside, outside, normal)`

| Аргумент | Тип и условия |
|---|---|
| `position` | Vector3 |
| `radius` | number |
| `inside` | Color |
| `outside` | Color |
| `normal?` | Vector3 |

Значения не возвращаются.

### render.circle_filled_3d

`render.circle_filled_3d(position, radius, color, normal)`

| Аргумент | Тип и условия |
|---|---|
| `position` | Vector3 |
| `radius` | number |
| `color` | Color |
| `normal?` | Vector3 |

Значения не возвращаются.

### render.concave_polygon

`render.concave_polygon(points, color)`

| Аргумент | Тип и условия |
|---|---|
| `points` | Vector2[] Same contract as polygon. |
| `color` | Color |

Значения не возвращаются.

### render.create_texture_rgba

`render.create_texture_rgba(width, height)`

| Аргумент | Тип и условия |
|---|---|
| `width` | integer 1..4096; total pixels <=1048576. |
| `height` | integer |

Результаты:

- integer? texture Mutable, private to this script; retained/reused after unload.
- string? error

### render.frame_count

`render.frame_count()`

Результаты:

- integer count Number of scripting paint passes since DLL initialization.

### render.frame_time

`render.frame_time()`

Результаты:

- number seconds

### render.grenade_icon

`render.grenade_icon(kind)`

Native grenade artwork, paint only; same owned texture handle as render.texture. One cached raster per kind.

| Аргумент | Тип и условия |
|---|---|
| `kind` | 'hegrenade'&#124;'flashbang'&#124;'smokegrenade'&#124;'molotov'&#124;'incgrenade'&#124;'decoy' |

Результаты:

- integer? handle
- integer&#124;string width_or_error
- integer? height

### render.line

`render.line(x1, y1, x2, y2, color, thickness)`

| Аргумент | Тип и условия |
|---|---|
| `x1` | number |
| `y1` | number |
| `x2` | number |
| `y2` | number |
| `color` | Color |
| `thickness?` | number |

Значения не возвращаются.

### render.measure_text

`render.measure_text(text, font)`

| Аргумент | Тип и условия |
|---|---|
| `text` | string |
| `font?` | integer Custom fonts require paint. |

Результаты:

- number width
- number height

### render.poly_line

`render.poly_line(points, color, thickness, closed)`

| Аргумент | Тип и условия |
|---|---|
| `points` | Vector2[] 2..256 points. |
| `color` | Color |
| `thickness?` | number 0.1..100, default 1. |
| `closed?` | boolean Default false. |

Значения не возвращаются.

### render.polygon

`render.polygon(points, color)`

| Аргумент | Тип и условия |
|---|---|
| `points` | Vector2[] 3..256 vertices; simple polygon without holes. |
| `color` | Color |

Значения не возвращаются.

### render.pop_clip_rect

`render.pop_clip_rect()`

Значения не возвращаются.

### render.push_clip_rect

`render.push_clip_rect(x, y, width, height)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |

Значения не возвращаются.

### render.rect

`render.rect(x, y, width, height, color, filled)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |
| `color` | Color |
| `filled?` | boolean |

Значения не возвращаются.

### render.rect_filled_fade

`render.rect_filled_fade(x, y, w, h, tl, tr, br, bl)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `w` | number |
| `h` | number |
| `tl` | Color |
| `tr` | Color |
| `br` | Color |
| `bl` | Color |

Значения не возвращаются.

### render.screen_size

`render.screen_size()`

Результаты:

- integer width
- integer height

### render.setup_font

`render.setup_font(basename, size)`

| Аргумент | Тип и условия |
|---|---|
| `basename` | string TTF/OTF under config_dir/resources/<basename>, or fonts/<basename> under config_dir/fonts. |
| `size` | number 6..96 pixels. |

Результаты:

- integer? font
- string? error Resource failure code; nil on success.

### render.setup_texture

`render.setup_texture(basename)`

| Аргумент | Тип и условия |
|---|---|
| `basename` | string File under config_dir/resources/<basename>, or skeetles/name.png under config_dir/skeetles; at most 4 MiB. |

Результаты:

- integer? texture Handle; nil on missing/unsupported image.
- string? error Resource failure code; nil on success.

### render.setup_texture_from_memory

`render.setup_texture_from_memory(bytes)`

| Аргумент | Тип и условия |
|---|---|
| `bytes` | string Binary encoded image, at most 4 MiB. |

Результаты:

- integer? texture
- string? error Resource failure code; nil on success.

### render.setup_texture_rgba

`render.setup_texture_rgba(bytes, width, height)`

| Аргумент | Тип и условия |
|---|---|
| `bytes` | string Raw RGBA bytes; exactly width*height*4. |
| `width` | integer 1..4096, total pixels at most 1048576. |
| `height` | integer 1..4096 |

Результаты:

- integer? texture
- string? error Resource failure code; nil on success.

### render.text

`render.text(x, y, text, color, font)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `text` | string |
| `color` | Color |
| `font?` | integer Handle obtained by this script in paint. |

Значения не возвращаются.

### render.texture

`render.texture(texture, x, y, width, height, tint, rounding)`

| Аргумент | Тип и условия |
|---|---|
| `texture` | integer Handle returned to this script. |
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |
| `tint?` | Color Default white. |
| `rounding?` | number Default 0. |

Значения не возвращаются.

### render.texture_rotated

`render.texture_rotated(texture, center_x, center_y, width, height, angle, tint)`

| Аргумент | Тип и условия |
|---|---|
| `texture` | integer Handle returned to this script. |
| `center_x` | number Rotation center in screen pixels. |
| `center_y` | number Rotation center in screen pixels. |
| `width` | number Drawn width. |
| `height` | number Drawn height. |
| `angle` | number Clockwise rotation in radians. |
| `tint?` | Color Default white. |

Значения не возвращаются.

### render.texture_size

`render.texture_size(texture)`

| Аргумент | Тип и условия |
|---|---|
| `texture` | integer Handle returned to this script. |

Результаты:

- integer width Original pixel width.
- integer height Original pixel height.

### render.update_texture_pixels

`render.update_texture_pixels(texture, bytes, format, pitch)`

| Аргумент | Тип и условия |
|---|---|
| `texture` | integer Handle from render.create_texture_rgba. |
| `bytes` | string Pixel bytes, <=4 MiB; at least pitch*(height-1)+row_bytes, at most pitch*height. |
| `format` | 'rgba8'&#124;'bgra8'&#124;'bgrx8'&#124;'rgb565'&#124;'rgb555' 16-bit formats use little-endian words. |
| `pitch?` | integer Bytes per source row; default tightly packed; >=width*bytes_per_pixel. |

Результаты:

- boolean? success
- string? error Resource error; invalid arguments raise a Lua error.

### render.update_texture_rgba

`render.update_texture_rgba(texture, bytes)`

| Аргумент | Тип и условия |
|---|---|
| `texture` | integer Handle from render.create_texture_rgba. |
| `bytes` | string Exactly width*height*4 RGBA bytes; call before drawing this frame. |

Результаты:

- boolean? success
- string? error

### render.world_to_screen

`render.world_to_screen(world)`

| Аргумент | Тип и условия |
|---|---|
| `world` | Vector3 |

Результаты:

- number? x
- number? y
- boolean? on_screen


## settings

Руководство: [Настройки и бинды](SETTINGS.ru.md).

### settings.bind

`settings.bind(category, name, key, mode)`

| Аргумент | Тип и условия |
|---|---|
| `category` | string |
| `name` | string |
| `key?` | integer Windows virtual key, 0..255. |
| `mode?` | integer 0 toggle, 1 hold_on; legacy 2 is normalized to toggle. |

Результаты:

- {key: integer, mode: integer, active: boolean}

### settings.binds

`settings.binds()`

Результаты:

- BindSnapshot[] Native bound settings plus active scripts' Lua checkbox binds; includes inactive binds.

### settings.get

`settings.get(category, name)`

| Аргумент | Тип и условия |
|---|---|
| `category` | string |
| `name` | string |

Результаты:

- any value

### settings.list

`settings.list(category_filter)`

Use exact per-weapon categories from weapon_profiles(). Aim/shot fields are read-only. Legacy get/bind reads use the held weapon in that class when the command context is valid, otherwise its first menu entry.

| Аргумент | Тип и условия |
|---|---|
| `category_filter?` | string |

Результаты:

- SettingDescriptor[]

### settings.override

`settings.override(category, name, value)`

| Аргумент | Тип и условия |
|---|---|
| `category` | string |
| `name` | string |
| `value` | any Pass nil to release this script's override. |

Значения не возвращаются.

### settings.set

`settings.set(category, name, value)`

| Аргумент | Тип и условия |
|---|---|
| `category` | string |
| `name` | string |
| `value` | any |

Значения не возвращаются.

### settings.weapon_profiles

`settings.weapon_profiles()`

Результаты:

- WeaponProfile[] All 34 firearms, stable menu order; available at script load, excludes Zeus/knives/grenades.


## storage

Руководство: [Сохранение](SERVICES.ru.md).

### storage.get

`storage.get(key, default)`

| Аргумент | Тип и условия |
|---|---|
| `key` | string |
| `default?` | any |

Результаты:

- any

### storage.set

`storage.set(key, value)`

| Аргумент | Тип и условия |
|---|---|
| `key` | string 1..128 bytes. |
| `value` | any Pass nil to remove the key. Total serialized storage <=64 KiB; saved periodically and on unload. |

Значения не возвращаются.


## trace

Руководство: [Трассировка](DATA.ru.md).

### trace.line

`trace.line(start, finish, skip_player_id)`

| Аргумент | Тип и условия |
|---|---|
| `start` | Vector3 |
| `finish` | Vector3 |
| `skip_player_id?` | integer |

Результаты:

- {fraction: number, end_pos: Vector3, normal: Vector3, all_solid: boolean}


## ui

Руководство: [Контролы и оформление](UI.ru.md).

### ui.attach_tab

`ui.attach_tab(control, tab, group)`

| Аргумент | Тип и условия |
|---|---|
| `control` | string Owned ui.create control. |
| `tab?` | string Owned slot id; controls remain on the script page; nil removes the association. |
| `group?` | string Required if the tab has groups. Otherwise nil uses a full-width default section. |

Значения не возвращаются.

### ui.attach_window

`ui.attach_window(control_id, window_id)`

Moves an existing ui.create control into this script's window; nil restores Config placement.

| Аргумент | Тип и условия |
|---|---|
| `control_id` | string |
| `window_id?` | string |

Значения не возвращаются.

### ui.bind

`ui.bind(id, key, mode)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string Checkbox control id. |
| `key?` | integer Windows VK 0..255; 0 removes the key. |
| `mode?` | integer 0 toggle, 1 hold_on; legacy 2 is normalized to toggle. |

Результаты:

- {key: integer, mode: integer, active: boolean} bind

### ui.create

`ui.create(kind, id, label, default, min_or_options, max)`

| Аргумент | Тип и условия |
|---|---|
| `kind` | 'checkbox'&#124;'slider'&#124;'combo'&#124;'color'&#124;'text' |
| `id` | string |
| `label` | string |
| `default` | any |
| `min_or_options?` | number&#124;string[]&#124;{key: integer, mode: integer} Checkbox accepts optional bind table (key 0..255; mode 0 toggle, 1 hold_on; legacy 2 is normalized to toggle). |
| `max?` | number |

Результаты:

- string id

### ui.create_tab

`ui.create_tab(id, title, options)`

Claim the visible sixth menu slot. Only ONE active script may own it globally. The sidebar slot is hidden without an active owner; removing the selected slot returns to Config. A second claim raises an error; unload/failure or remove_tab releases the slot. Recommended for large comprehensive suites; small scripts should use the normal script page.

| Аргумент | Тип и условия |
|---|---|
| `id` | string Script-local stable id, 1..80 UTF-8 bytes. |
| `title` | string Literal UTF-8 caption, 1..96 bytes. |
| `options?` | MenuTabStyle |

Результаты:

- string id One tab per owner. Controls also remain on the script page.

### ui.create_tab_group

`ui.create_tab_group(tab, id, title, column, layout)`

| Аргумент | Тип и условия |
|---|---|
| `tab` | string Owned tab id. |
| `id` | string Stable group id, 1..80 bytes. |
| `title` | string Literal caption, 1..96 bytes. |
| `column?` | integer 1 left (default), 2 right. Up to 16 groups per tab. |
| `layout?` | MenuTabLayout Omit for equal-height cells per column. All groups must use the same layout mode. |

Результаты:

- string id

### ui.create_window

`ui.create_window(id, title, options)`

Registers an interactive, draggable/resizable script window; at most 8 per script.

| Аргумент | Тип и условия |
|---|---|
| `id` | string Unique script-owned UTF-8 ID, 1..80 bytes |
| `title` | string Script-authored UTF-8 title, 1..160 bytes |
| `options?` | LuaWindowOptions |

Результаты:

- string id

### ui.get

`ui.get(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |

Результаты:

- any

### ui.get_language

`ui.get_language()`

Результаты:

- string id Effective language ID; en when the saved custom ID is unavailable

### ui.get_languages

`ui.get_languages()`

Результаты:

- MenuLanguage[] languages English, Simplified Chinese, Brazilian Portuguese, then custom IDs in alphabetical order

### ui.get_menu_font

`ui.get_menu_font()`

Результаты:

- MenuFontInfo font Metadata; GPU creation is deferred

### ui.get_menu_rect

`ui.get_menu_rect()`

paint only. Screen pixels.

Результаты:

- {x: number, y: number, w: number, h: number}

### ui.get_translation_keys

`ui.get_translation_keys()`

Результаты:

- string[] keys Sorted English menu text, without ## suffixes

### ui.get_window

`ui.get_window(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |

Результаты:

- LuaWindowInfo window

### ui.is_menu_opened

`ui.is_menu_opened()`

paint only.

Результаты:

- boolean

### ui.mouse_state

`ui.mouse_state()`

paint only. Current-frame mouse coordinates in screen pixels; clicked is a new left press, down is held. All paint callbacks see the same click. Drag only while the menu is open; stop on release or menu close.

Результаты:

- {x: number, y: number, down: boolean, clicked: boolean}

### ui.register_language

`ui.register_language(id, name, translations)`

Registers/replaces this script's UTF-8 menu dictionary. Built-ins en/zh-CN/pt-BR are reserved. Removed on script unload/error; missing entries fall back to the original English text. Applies only to Skeet's native interface/editor shell; Lua UI, source and logs stay literal.

| Аргумент | Тип и условия |
|---|---|
| `id` | string ASCII letters/digits/-/_, 1..48 bytes |
| `name` | string UTF-8 display name, 1..96 bytes |
| `translations` | table<string,string> English visible text => UTF-8 translation |

Результаты:

- boolean success False for another owner's ID or registry limit

### ui.remove_tab

`ui.remove_tab(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string Owned tab id; controls remain on the script page. |

Значения не возвращаются.

### ui.reset_theme

`ui.reset_theme()`

Значения не возвращаются.

### ui.set

`ui.set(id, value)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |
| `value` | any |

Значения не возвращаются.

### ui.set_blur_opacity

`ui.set_blur_opacity(surface, opacity)`

| Аргумент | Тип и условия |
|---|---|
| `surface` | 'sidebar'&#124;'header'&#124;'body'&#124;'surface'&#124;'card'&#124;'control' |
| `opacity?` | number 0..1; nil removes this script's override. |

Значения не возвращаются.

### ui.set_language

`ui.set_language(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |

Результаты:

- boolean success False for an unknown ID; selection is saved with the config

### ui.set_language_font

`ui.set_language_font(id, filename, size)`

Associates a local TTF/OTF/TTC/OTC file with this script's registered language. CPU validation happens now; GPU font creation is deferred to the next menu frame. nil filename removes the language font, falling back to a menu override or the default. Lua UI/source/logs retain their own fonts.

| Аргумент | Тип и условия |
|---|---|
| `id` | string This script's language ID; built-ins/other owners are protected |
| `filename?` | string UTF-8 basename directly in %LOCALAPPDATA%/skeet |
| `size?` | number 8..24 pixels, default 11; one size across the native interface |

Результаты:

- boolean success
- string? error File/format/ownership/cache failure; previous selection is preserved

### ui.set_menu_font

`ui.set_menu_font(filename, size)`

Sets this script's default menu font without changing the selected language. A font attached to the selected language takes priority. Latest live default override wins.

| Аргумент | Тип и условия |
|---|---|
| `filename?` | string Basename in %LOCALAPPDATA%/skeet; nil releases this script's override |
| `size?` | number 8..24 pixels, default 11 |

Результаты:

- boolean success
- string? error

### ui.set_style_color

`ui.set_style_color(backend, name, color)`

| Аргумент | Тип и условия |
|---|---|
| `backend` | 'menu'&#124;'xui' |
| `name` | string |
| `color?` | Color nil removes this script's color override. |

Значения не возвращаются.

### ui.set_tab_style

`ui.set_tab_style(id, options)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string Owned tab id. |
| `options?` | MenuTabStyle Partial update; nil resets style/icon and preserves id/title/groups. |

Значения не возвращаются.

### ui.set_window_open

`ui.set_window_open(id, open)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |
| `open` | boolean Follow-mode windows remain hidden while Skeet is closed |

Значения не возвращаются.

### ui.style_colors

`ui.style_colors(backend)`

| Аргумент | Тип и условия |
|---|---|
| `backend` | 'menu'&#124;'xui' |

Результаты:

- string[]

### ui.translate

`ui.translate(text, id)`

| Аргумент | Тип и условия |
|---|---|
| `text` | string |
| `id?` | string Defaults to the effective menu language |

Результаты:

- string text Unknown language/key returns the original text

### ui.unregister_language

`ui.unregister_language(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |

Результаты:

- boolean removed Only the owning script can remove a custom dictionary

### ui.window_bind

`ui.window_bind(id, key)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |
| `key?` | integer Query if omitted; 0 follows Skeet, 1..255 independent VK key |

Результаты:

- {key: integer, open: boolean, follows_menu: boolean} bind


## xui

Руководство: [Собственные окна XUI](XUI.ru.md).

### xui.available

`xui.available()`

Результаты:

- number, number

### xui.begin_child

`xui.begin_child(id, width, height, scrollable)`

Call end_child only when this returns true.

| Аргумент | Тип и условия |
|---|---|
| `id` | string |
| `width?` | number Default 0. |
| `height?` | number Default 0. |
| `scrollable?` | boolean Default false. |

Результаты:

- boolean

### xui.begin_popup

`xui.begin_popup(id, width, expanded)`

Inline animated section. Width is reserved; content uses the available row width.

| Аргумент | Тип и условия |
|---|---|
| `expanded?` | boolean Default true; pass a checkbox value for collapsible content. |
| `id` | string |
| `width?` | number Reserved by current layout, default 200. |

Результаты:

- boolean

### xui.blur

`xui.blur(x, y, width, height, color, rounding)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |
| `color` | Color |
| `rounding?` | number Default 0, clamped 0..100. |

Значения не возвращаются.

### xui.button

`xui.button(label, width, height)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `width?` | number Available width by default. |
| `height?` | number Default 24. |

Результаты:

- boolean

### xui.checkbox

`xui.checkbox(label, value)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `value` | boolean |

Результаты:

- boolean, boolean

### xui.circle

`xui.circle(x, y, radius, color, filled, thickness)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `radius` | number Clamped 0..10000. |
| `color` | Color |
| `filled?` | boolean Default false. |
| `thickness?` | number Default 1, clamped 0.1..100. |

Значения не возвращаются.

### xui.color_picker

`xui.color_picker(label, color)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `color` | Color |

Результаты:

- Color, boolean

### xui.combo

`xui.combo(label, selected, items, width)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `selected` | integer 1-based. |
| `items` | string[] 1..128 entries. |
| `width?` | number |

Результаты:

- integer, boolean

### xui.create_window

`xui.create_window(id, title, options, callback)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |
| `title` | string |
| `options` | XuiWindowOptions |
| `callback` | fun() Runs once per visible rendered frame, inside its own XUI window. |

Результаты:

- string

### xui.cursor

`xui.cursor(x, y)`

| Аргумент | Тип и условия |
|---|---|
| `x?` | number Omit both arguments to query. |
| `y?` | number Required when setting x. |

Результаты:

- number?, number?

### xui.end_child

`xui.end_child()`

Значения не возвращаются.

### xui.end_popup

`xui.end_popup()`

Значения не возвращаются.

### xui.gradient

`xui.gradient(x, y, width, height, top_left, top_right, bottom_right, bottom_left, rounding)`

Absolute screen coordinates; colors ordered clockwise from top-left. Does not advance layout.

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |
| `top_left` | Color |
| `top_right` | Color |
| `bottom_right` | Color |
| `bottom_left` | Color |
| `rounding?` | number Default 0, clamped 0..100. |

Значения не возвращаются.

### xui.image

`xui.image(texture, width, height)`

| Аргумент | Тип и условия |
|---|---|
| `texture` | integer Owned render texture handle. |
| `width` | number |
| `height` | number |

Значения не возвращаются.

### xui.input_text

`xui.input_text(label, value, capacity, hint)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `value` | string |
| `capacity?` | integer 1..16384 bytes, default 4096. |
| `hint?` | string |

Результаты:

- string, boolean

### xui.invisible_button

`xui.invisible_button(label, width, height)`

Reserve a layout item and hit-test it, without drawing. Stable label/ID required.

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `width` | number |
| `height` | number |

Результаты:

- boolean clicked New left press, not release.
- XuiItemState state

### xui.keybind

`xui.keybind(label, key)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `key` | integer 0..255 Windows VK. |

Результаты:

- integer, boolean

### xui.line

`xui.line(x, y, x2, y2, color, thickness)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `x2` | number |
| `y2` | number |
| `color` | Color |
| `thickness?` | number Default 1, clamped 0.1..100. |

Значения не возвращаются.

### xui.menu_button

`xui.menu_button(label, width, height)`

Classic menu button presentation; default width is available width, height 24.

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `width?` | number Available width by default. |
| `height?` | number Default 24. |

Результаты:

- boolean clicked

### xui.mouse_state

`xui.mouse_state()`

Результаты:

- {x:number, y:number, dx:number, dy:number, down:boolean, clicked:boolean, released:boolean, right_down:boolean, right_clicked:boolean, wheel:number}

### xui.multicombo

`xui.multicombo(label, selected, items)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `selected` | boolean[] Same length as items. |
| `items` | string[] 1..128 entries. |

Результаты:

- boolean[], boolean

### xui.pop_clip

`xui.pop_clip()`

Значения не возвращаются.

### xui.pop_font

`xui.pop_font()`

Значения не возвращаются.

### xui.pop_id

`xui.pop_id()`

Значения не возвращаются.

### xui.pop_style_color

`xui.pop_style_color()`

Значения не возвращаются.

### xui.pop_style_var

`xui.pop_style_var()`

Значения не возвращаются.

### xui.push_clip

`xui.push_clip(x, y, width, height)`

Intersect the current window clip. pop_clip must be the next matching scope close.

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |

Значения не возвращаются.

### xui.push_font

`xui.push_font(font)`

| Аргумент | Тип и условия |
|---|---|
| `font?` | integer Owned render font handle |
| `` | nil selects default. |

Значения не возвращаются.

### xui.push_id

`xui.push_id(id)`

| Аргумент | Тип и условия |
|---|---|
| `id` | string |

Значения не возвращаются.

### xui.push_style_color

`xui.push_style_color(name, color)`

| Аргумент | Тип и условия |
|---|---|
| `name` | string |
| `color` | Color |

Значения не возвращаются.

### xui.push_style_var

`xui.push_style_var(name, value)`

| Аргумент | Тип и условия |
|---|---|
| `name` | string One of the 28 XUI scalar style variables. |
| `value` | number 0..1000. |

Значения не возвращаются.

### xui.rect

`xui.rect(x, y, width, height, color, rounding, thickness)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |
| `color` | Color |
| `rounding?` | number Default 0, clamped 0..100. |
| `thickness?` | number Default 1, clamped 0.1..100. |

Значения не возвращаются.

### xui.rect_filled

`xui.rect_filled(x, y, width, height, color, rounding)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `width` | number |
| `height` | number |
| `color` | Color |
| `rounding?` | number Default 0, clamped 0..100. |

Значения не возвращаются.

### xui.same_line

`xui.same_line(spacing)`

| Аргумент | Тип и условия |
|---|---|
| `spacing?` | number Gap after the preceding item; 0 uses the current style. |

Значения не возвращаются.

### xui.separator

`xui.separator()`

Значения не возвращаются.

### xui.slider_float

`xui.slider_float(label, value, minimum, maximum)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `value` | number |
| `minimum` | number |
| `maximum` | number |

Результаты:

- number, boolean

### xui.slider_int

`xui.slider_int(label, value, minimum, maximum)`

| Аргумент | Тип и условия |
|---|---|
| `label` | string |
| `value` | integer |
| `minimum` | integer |
| `maximum` | integer |

Результаты:

- integer, boolean

### xui.spacing

`xui.spacing(pixels)`

| Аргумент | Тип и условия |
|---|---|
| `pixels` | number |

Значения не возвращаются.

### xui.text

`xui.text(text, color)`

| Аргумент | Тип и условия |
|---|---|
| `text` | string |
| `color?` | Color |

Значения не возвращаются.

### xui.text_at

`xui.text_at(x, y, text, color, font)`

| Аргумент | Тип и условия |
|---|---|
| `x` | number |
| `y` | number |
| `text` | string |
| `color` | Color |
| `font?` | integer Owned render font handle. |

Значения не возвращаются.

### xui.window_rect

`xui.window_rect()`

Результаты:

- {x:number, y:number, width:number, height:number} Screen pixels.

