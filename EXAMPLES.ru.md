# Готовые примеры

Скопируйте выбранный `.lua` в `%LOCALAPPDATA%\skeet` и включите его в меню. Примеры независимы: не нужно включать всю папку. У многих демонстраций основной checkbox по умолчанию выключен. Внешние изображения, шрифты, звук и Doom core нужно разместить отдельно; Lua-файл не содержит их автоматически.

## С чего начать

| Пример | Что показывает |
|---|---|
| [hello](examples/hello.lua) | Базовый вывод и API |
| [persistent_ui](examples/persistent_ui.lua) | Контролы и сохранение |
| [bind_demo](examples/bind_demo.lua) | Checkbox-бинды |
| [protected_diagnostics](examples/protected_diagnostics.lua) | Ограниченная работа через api.protect |
| [api_showcase](examples/api_showcase.lua) | Сочетание нескольких возможностей |
| [custom_indicators](examples/custom_indicators.lua) | Плавный круг DT и индикаторы булевых функций; [контракт](INDICATORS.ru.md) |

## Интерфейсы и оформление

| Пример | Что показывает |
|---|---|
| [independent_menu](examples/independent_menu.lua) | Окно с независимой клавишей |
| [following_menu](examples/following_menu.lua) | Окно, следующее за главным меню |
| [xui_custom_menu](examples/xui_custom_menu.lua) | Своя отрисовка окна, страницы, контролы и mouse hit-test |
| [xui_columns](examples/xui_columns.lua) | Колонки и layout |
| [sixth_slot](examples/sixth_slot.lua) | Единственный специальный слот: две иконки, четыре секции, HUD и отдельное окно |
| [native/mixed_menu](native/mixed_menu.lua) | Совместное использование штатных и непосредственных контролов |
| [menu_font_only](examples/menu_font_only.lua) | Отдельный шрифт меню |
| [menu_localization_pt_br](examples/menu_localization_pt_br.lua) | Пользовательский вариант встроенного pt-BR и необязательный шрифт |
| [custom_keybinds](examples/custom_keybinds.lua) | Своя панель биндов; дополнительный шрифт необязателен |
| [custom_manual_arrows](examples/custom_manual_arrows.lua) | Свои manual arrows без картинок; временное скрытие штатных |
| [manual_arrow_images](examples/manual_arrow_images.lua) | Картинки вместо стрелок; штатная сторона остаётся при отсутствии файла |
| [graphics_v2](examples/graphics_v2.lua) | Примитивы и ресурсы; имя файла историческое, код предназначен для текущего набора |
| [draggable_image](examples/draggable_image.lua) | Перетаскиваемое изображение |

Варианты draggable_* используют свои файлы изображений. Смотрите basename внутри выбранного скрипта. Примеры rgb_* меняют разрешённые визуальные настройки: watermark, keybinds, ESP, chams, skybox, fog, sun, hitmarkers и другие. `rgb_autopeek` меняет цвет, а не алгоритм peek assistance. `rgb_menu_tab` открывает собственное XUI-окно и не занимает специальный слот.

Специальный слот рекомендуется оставлять для крупных Lua с обширным полезным функционалом. Для маленьких Lua используйте обычную страницу скрипта в меню Skeet. Только одна активная Lua может занимать слот; перед запуском другого владельца отключите `sixth_slot`. Подробности — в [UI](UI.ru.md).

## Игровые данные и визуализация

| Пример | Что показывает |
|---|---|
| [custom_esp](examples/custom_esp.lua) | Игроки, bounds и текст |
| [radar](examples/radar.lua) | Живые игроки, гранаты и очаги на своей панели; внешние изображения не требуются |
| [combat_probe](examples/combat_probe.lua) | Чтение/расчёты combat, без замены выстрела |
| [hitsound_killsound](examples/hitsound_killsound.lua) | Игровые события и звук |
| [soufiw_hitmarker](widgets/soufiw_hitmarker.lua) | Визуальный отклик на урон |
| [custom_model](examples/custom_model.lua) | Выбор внешней скомпилированной модели |
| [custom_material_chams](examples/custom_material_chams.lua) | Создание материала при загрузке |
| [material_path_chams](examples/material_path_chams.lua) | Выбор готового material resource |
| [scoped_local_glow](examples/scoped_local_glow.lua) | Состояние прицела и локальный chams |

## Движение и гранаты

| Пример | Что показывает |
|---|---|
| [lua_bhop](examples/lua_bhop.lua) | Владение bhop и jump до prediction |
| [lua_strafe](examples/lua_strafe.lua) | Владение strafe и боковая ось |
| [antiaim](examples/antiaim.lua) | Выбор штатных AA-настроек |
| [prediction](examples/prediction.lua) | Вывод фактического native prediction-снимка |
| [grenade_helper](examples/grenade_helper.lua) | Запись позиции/маршрута и командный бросок |
| [grenade_warning](examples/grenade_warning.lua) | Наблюдаемая позиция, иконка, очаги огня и приблизительный круг |
| [grenade_trajectory](examples/grenade_trajectory.lua) | Кэшированный прогноз и расчёт броска с выбранными углами; без управления игроком |

Запускайте один управляющий helper за раз. Учитывайте конфликтующие штатные movement-режимы. Точность бросков и физики проверяется в игре; макет Lua не заменяет такую проверку.

## Игры

[Tetris](games/tetris.lua) — Lua-демонстрация интерфейса и ввода. [Doom](games/DOOM.ru.md) использует внешнюю x64 DLL через FFI и отдельные игровые данные. Не переносите требования Doom на обычные скрипты: остальные примеры не нуждаются в PrBoom.

Остальные тематические Lua в examples — дополнительные варианты оформления или счётчиков. Имя вроде resolver_label не означает доступ к штатному resolver или его замену; оценивайте конкретные API-вызовы исходника.
