# Игровые данные, трассировка и математика

Для индикаторов DT используйте `combat.double_tap()`: это отдельный снимок,
доступный также в `paint`. Его поля, сроки актуальности и состояния описаны в
[руководстве индикаторов](INDICATORS.ru.md).

## Снимки игроков

`entity.local_player()` возвращает локального игрока либо nil. `entity.players(enemies_only)` — массив доступных снимков; true оставляет врагов. `entity.get(id)` получает одного игрока. Id здесь — **индекс controller**, не pawn pointer; `0` служит псевдонимом local player.

PlayerSnapshot содержит id, name, health, alive, team, enemy, origin, velocity, flags, armor, scoped. Origin/velocity — Vector3. Scoped отражает клиенту известное состояние; false не доказывает, что любое состояние удалённого оружия полностью известно.

```lua
events.on("paint", function()
    for _, player in ipairs(entity.players(true)) do
        if player.alive then
            local x, y, visible = render.world_to_screen(player.origin)
            if x and visible then
                render.text(x, y, player.name .. " " .. player.health, {255,210,120,255})
            end
        end
    end
end)
```

Таблицы — копии. Их редактирование не меняет сущность. Повторное использование индекса другим игроком возможно; не храните один id как бессрочное доказательство личности. При отсутствии локального игрока, переходе карты или смерти проверяйте nil и alive.

## Кости, границы, оружие и предметы

| Метод | Результат |
|---|---|
| `entity.bone(id,bone_index)` | Мировая Vector3 либо nil; bone_index 0–127 |
| `entity.bounds(id)` | Экранный прямоугольник `{x,y,w,h}` либо nil |
| `entity.weapon(id)` | `{item_id,ammo,reloading}` либо nil |
| `entity.items()` | Массив `{id,class_hash,origin}` для известных предметов/оружия |

Bone index, hitbox index и hitgroup — разные пространства значений. `class_hash` не является именем schema и не должен передаваться как индекс игрока. Projectile и inferno получайте через grenades.observations, а не через entity.items.

## Трассировка

`trace.line(start,finish,skip_player_id)` доступен в командном событии. Start/finish — Vector3 в мировых координатах. Skip по умолчанию 0, локальный игрок. Результат: fraction, end_pos, normal, all_solid. Поле all_solid всегда boolean, а не числовой байт.

Fraction описывает пройденную долю линии; end_pos — полученную конечную точку, normal — нормаль контакта. All_solid проверяйте отдельно. Это линия, не sweep объёма игрока или гранаты. Нельзя считать отсутствие пересечения линии доказательством свободного прохода целого player hull.

```lua
events.on("create_move", function()
    local me = entity.local_player()
    if not me or not me.alive then return end
    local finish = {x=me.origin.x, y=me.origin.y, z=me.origin.z-64}
    local hit = trace.line(me.origin, finish, 0)
    if hit.all_solid then return end
    -- hit.end_pos можно сохранить для последующего вывода в paint.
end)
```

## Контекст оружия и расчёты combat

Все combat-методы вызываются в командных событиях. Они читают текущие данные или выполняют расчёт. Ни один из них не публикует ваш выстрел и не предоставляет override сканирования.

| Метод | Назначение и недоступный результат |
|---|---|
| `combat.context()` | Таблица valid/weapon_type/item_id/tick/time/spread/inaccuracy/scoped/range/eye; сначала проверять valid |
| `combat.weapon_state()` | Tick-поля готовности, ammo/reloading и признаки револьвера; nil без контекста |
| `combat.can_shoot(ignore_next_attack)` | Boolean штатной проверки; true не является командой стрелять |
| `combat.aim_punch()` | Vector3 или nil |
| `combat.records(target_id)` | Доступные lag-records: tick,time,origin,velocity,ducked,extrapolated |
| `combat.hitboxes(target_id,record_tick)` | `{tick,time,hitboxes}` или nil; без tick выбирается доступная последняя запись |
| `combat.damage(target_id,world_point,record_tick)` | `{damage,hitbox,hitgroup,penetrated}` либо nil |
| `combat.hitchance(target_id,point,hitbox,record_tick)` | Процент 0–100 либо nil; hitbox 0–18 |
| `combat.spread_sample(angles,tick)` | `{seed,x,y}` либо nil для заданных углов и tick |
| `combat.spread_correction(aim,tick,hidden_shot)` | Углы коррекции Vector3 либо nil |

Поля weapon_state: item_id, is_revolver, client_tick, tick_base, ready_tick, next_primary_tick, next_secondary_tick, ammo, reloading, can_start_primary, postponed_primary_ready. Это снимок, не гарантия будущей возможности выстрела. `can_shoot(true)` пропускает проверку next attack в этом запросе, но не убирает reload/ammo-проверки и не меняет native firing.

Record tick должен оставаться доступным в момент вызова; прошлая таблица records не удерживает внутреннюю запись. Future-record для damage не принимается. Nil означает отсутствие подходящего результата, а не нулевой урон.

В hitboxes каждый элемент содержит index, bone, radius, mins/maxs, center, capsule_a/capsule_b и rotation. Mins/maxs — локальные координаты hitbox; center и capsule endpoints — мировые. Rotation — quaternion x/y/z/w кости, не Euler-углы. Records ограничен 64 записями; hitchance — 32 запросами на команду для скрипта.

Head hitchance исключает выборки, которые сначала попали в другой hitbox цели; это не отдельная трассировка мира для каждого sample. Не называйте этот процент доказанной вероятностью фактического попадания с учётом всех будущих условий.

Запросы damage/hitchance/spread могут быть дорогими. Ограничивайте их число и частоту. Для визуального списка игроков они не нужны. Вычисленное значение не следует использовать как основание для записи запрещённого firearm attack через cmd.

## Математические функции

| Метод | Контракт |
|---|---|
| `math.calc_angle(src,dst)` | Углы Vector3 от мировой точки src к dst, в градусах |
| `math.calc_fov(src,dst)` | Угловое отличие двух направлений-углов, в градусах |
| `math.normalize_angle(degrees)` | Нормализованный угол −180…180 |
| `math.vector_angles(forward)` | Углы Vector3 по вектору направления |
| `math.angle_vectors(angles)` | Три результата Vector3: forward, right, up |

Это дополнения к обычной math Lua. В Lua 5.5 для угла по двум компонентам используется `math.atan(y,x)`. Стандартные sin/cos принимают радианы; view angles и перечисленные angle-helpers — градусы. Для перевода используйте `math.rad` и `math.deg`.
