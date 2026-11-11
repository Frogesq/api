# Консоль, storage, звук, модели и chams

## Журнал скрипта

`client.log(...)` пишет значения в Lua-журнал, `client.log_level(level,...)` задаёт debug/info/warning/error. Глобальный print направлен в журнал скрипта. Для игрового console output используйте console.print.

`client.time()` возвращает монотонное время в секундах; `client.frametime()` — длительность кадра. `client.map_name()` возвращает короткое имя карты либо nil вне известной сессии. `client.key_down(vk)` читает состояние клавиши Windows 0–255; это не автоматическая обработка перехода «нажали только сейчас».

```lua
local previous = false
events.on("paint", function()
    local down = client.key_down(117)
    if down and not previous then client.log("F6 pressed") end
    previous = down
end)
```

## Игровая консоль

Skeet поддерживает игровой voice включённым для синхронизации. Если команда,
конфиг или скрипт выключает `voice_modenable`, `cl_voiceenabled` или существующий
в данной версии `voice_enable`, секундная проверка возвращает значение в `1`.
Громкость и push-to-talk не изменяются. `console.exec` сохраняет обычные правила
очереди, но выключение этих флагов не является устойчивым изменением настройки.

| Метод | Вход и результат |
|---|---|
| `console.exec(command)` | Строка 1–1024 байт без NUL; допускает игровые команды и их группы |
| `console.print(text)` | До 2048 байт без NUL; добавляет перевод строки, `%` печатается буквально |
| `console.say(text,team_only)` | 1–200 UTF-8 байт; team_only по умолчанию false |
| `console.clear_pending()` | Удаляет ещё не переданные запросы этого скрипта; возвращает число |

Exec/print/say возвращают accepted и при отказе reason: console_unavailable, queue_full, rate_limited, script_stopping. True означает постановку в очередь, **не успешное выполнение команды движком**. Очередь обслуживается на игровом frame-stage. При выгрузке принадлежащие скрипту непереданные запросы снимаются; уже переданные не отменяются.

До 32 запросов в секунду на скрипт, до 16 одновременно в его очереди, до 128 суммарно. В shutdown новые запросы отклоняются. Не отправляйте команду из каждого paint-кадра.

Say формирует одну цитированную say/say_team команду. Кавычки, обратный слеш, точка с запятой и управляющие символы в сообщении запрещены. Для произвольного вывода текста используйте console.print, а не конкатенацию текста с console.exec.

```lua
local ok, reason = console.print("Lua ready: 100%")
if not ok then client.log_level("warning", reason) end
```

Консоль не является частью pending cmd-запроса. Вызовы движения/attack через console не подчиняются grenade claim и не откатываются вместе с Lua-командой.

## Сохранение данных

`storage.get(key,default)` возвращает сохранённое значение или default. `storage.set(key,value)` меняет значение; nil удаляет ключ. Ключ — строка 1–128 байт, весь сериализованный storage ограничен 64 КиБ. Данные записываются в `<имя>.lua.json`: при изменениях примерно раз в 5 секунд на paint-проходе и при штатной выгрузке. Аварийное завершение процесса может потерять последние изменения. Контролы ui.create сохраняются отдельно, в конфигурации Skeet.

Храните числа, строки, boolean и сериализуемые таблицы. Не сохраняйте функции, циклические таблицы, CData, указатели и resource handles. У таблиц используйте последовательные числовые индексы для массива либо строковые ключи для объекта; не создавайте смешанную структуру без необходимости.

```lua
local config = storage.get("my_options", {version=1, radius=100})
if type(config) ~= "table" or config.version ~= 1 or type(config.radius) ~= "number" then
    config = {version=1, radius=100}
end
config.radius = math.max(0, math.min(500, config.radius))
storage.set("my_options", config)
```

После обновления своего формата проверяйте version и все необходимые поля. Имя Lua-файла определяет отдельное пространство сохранения; переименование может выглядеть как сброс настроек.

## Звук

Поддерживаются MP3/WAV. Обычный basename ищется под muzon, префикс sounds/ — под sounds. Ограничения: закодированный файл до 64 МиБ, декодированный PCM до 128 МиБ.

`audio.preload(basename)` вызывайте при загрузке. Он подготавливает звук без воспроизведения. `audio.play(basename,loop)` использует подготовленные данные; первый неподготовленный play читает и декодирует синхронно. `audio.volume(percent)` ограничивает конечное число диапазоном 0–100 и действует на этот скрипт. `audio.stop()` останавливает звук, сохраняя подготовленные ресурсы до выгрузки.

```lua
local ready, reason = audio.preload("sounds/hit.wav")
if not ready then client.log_level("warning", reason) end
audio.volume(30)
events.on("game_event", function(e)
    if ready and e.name == "player_hurt" and e.attacker == 0 then
        local ok, err = audio.play("sounds/hit.wav", false)
        if not ok then client.log_level("warning", err) end
    end
end)
```

Не подготавливайте заново большие звуки на каждом hit/paint. Обрабатывайте false и текст ошибки при отсутствии файла, устройства или неподдерживаемом содержимом.

## Модель локального игрока

`models.list()` ищет до 512 скомпилированных моделей под `game/csgo/characters/models` и возвращает `{id,path}`. `models.set(id)` принимает именно id из этого списка и возвращает virtual path. Выбор этого скрипта перекрывает штатный agent changer, пока действует.

Список скрывает файлы рук по отдельным словам `arm`, `arms`, `hand`, `hands`
в имени файла: без учёта регистра, с разделителями `_`, `-`, `.`. Имена каталогов
не учитываются. Это фильтр названий, а не анализ содержимого; ранее сохранённые
пути и проверка наличия файла в `models.set/status` не меняются.

`models.current()` — путь выбора этого скрипта либо nil. `models.clear()` освобождает выбор; в следующем игровом кадре применится другой Lua-владелец, штатный agent или native model. `models.status()` возвращает idle/ready/error и возможное сообщение. Ready подтверждает наличие файла, но не правильность модели, анимаций или её отображения движком.

Не подставляйте произвольный путь вместо id. Пример: [custom_model.lua](examples/custom_model.lua).

Совместимые старые модели тела с основными костями CS получают адаптацию к
текущему скелету анимации автоматически, в том числе при выборе из Lua.
Файлы модели не переписываются. Адаптер применяется к живому локальному игроку
в матче и выбранному персонажу главного меню; отдельные руки и ragdoll не входят
в эту адаптацию. `ready` по-прежнему означает наличие файла, а не успешную анимацию.
Для совместимых старых моделей без точки крепления `weapon` changer также
адаптирует положение удерживаемого оружия по текущей анимации с учётом цепочки
родительских костей. Дополнительных вызовов Lua для этого не требуется.
В меню модель без графа `uimodel` получает
штатный граф UI-персонажа и сопоставление его костей. Визуальный результат зависит
от совместимости модели и требует проверки в игре.

## Chams

`chams.targets()` перечисляет enemy, enemy_invisible, team, team_invisible, local, arms, weapon, attachments. Attachments — принадлежащие локальному игроку inventory-модели оружия в thirdperson, включая удерживаемые и убранные модели.

Материалы подготавливаются **только при загрузке**:

| Метод | Назначение |
|---|---|
| `chams.builtin_material(name)` | bloom, glow, flat или glass; handle включает visible/ignorez варианты |
| `chams.load_material(visible_path,ignorez_path)` | Virtual materials/.../*.vmat или .vmat_c; ignorez вариант нужно указать отдельно |
| `chams.create_material(brightness,tint)` | Собственный solidcolor, brightness 0.1–8; RGB записывается в материал, alpha tint игнорируется |

`chams.set(target,handle,color)` назначает материал и render RGBA. `chams.set(target,nil)` освобождает свой выбор. Handle принадлежит создавшему скрипту. Отсутствующий ресурс возвращает nil/reason у соответствующих методов; неправильные аргументы вызывают ошибку.

Не создавайте новый материал каждый кадр ради смены оттенка. Подготовьте handle один раз, а затем меняйте render color через chams.set. [custom_material_chams.lua](examples/custom_material_chams.lua) и [material_path_chams.lua](examples/material_path_chams.lua) показывают оба подхода.
