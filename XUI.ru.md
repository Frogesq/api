# Собственные интерфейсы XUI

## Создание окна

XUI подходит для собственных меню, вкладок внутри окна, списков, панелей и интерактивных оверлеев. Callback окна выполняется только во время его отрисовки. Все `xui.*`, кроме `xui.create_window`, требуют этот callback; вызов из обычного `paint` не подходит.

```lua
local active = storage.get("active", true)
local amount = storage.get("amount", 50)

xui.create_window("main", "My interface", {
    x=220, y=160, width=360, height=240, key=117, open=true
}, function()
    local changed
    active, changed = xui.checkbox("Enabled", active)
    if changed then storage.set("active", active) end
    amount, changed = xui.slider_int("Amount", amount, 0, 100)
    if changed then storage.set("amount", amount) end
    xui.text("Value: " .. tostring(amount))
end)
```

В отличие от ui.create, XUI-контролы вызываются каждый кадр; значение хранит ваш Lua-код. Большинство интерактивных контролов возвращают новое значение и changed. Сохранение в storage делайте при changed, а не при каждом кадре.

У окна есть общие параметры key/open/x/y/width/height и дополнительные titlebar, background, movable, resizable, padding. Первые четыре дополнительных флага по умолчанию true; padding допускает 0–100. При `titlebar=false` вы можете нарисовать собственный заголовок; верхние 30 пикселей остаются областью перетаскивания, если movable=true.

## Контролы

| Функция | Возвращает / особенности |
|---|---|
| `xui.text(text, color)` | Текст; цвет можно опустить |
| `xui.button(label, width, height)` | clicked; defaults: доступная ширина, высота 24 |
| `xui.menu_button(label, width, height)` | clicked; оформление штатной кнопки меню |
| `xui.checkbox(label, value)` | boolean value, changed |
| `xui.slider_int(label, value, min, max)` | Целое value, changed |
| `xui.slider_float(label, value, min, max)` | Число value, changed |
| `xui.input_text(label, value, capacity, hint)` | Строка value, changed; capacity задаёт вместимость ввода |
| `xui.combo(label, selected, items, width)` | Индекс с 1, changed; 1–128 строк |
| `xui.multicombo(label, selected, items)` | Массив boolean, changed; длины массивов совпадают, 1–128 |
| `xui.color_picker(label, color)` | RGBA, changed |
| `xui.keybind(label, key)` | Windows VK 0–255, changed; выбор клавиши, не готовая логика действия |
| `xui.image(texture, width, height)` | Изображение как элемент layout; handle должен принадлежать скрипту |

Label одновременно участвует в идентификации виджета. Держите его постоянным, а динамический текст выводите отдельно. В цикле используйте `xui.push_id(tostring(index))` и `xui.pop_id()`, чтобы одинаковые подписи не делили состояние. В окне допускается до 512 идентификаторов виджетов; уникальные id на каждом кадре быстро исчерпают этот лимит.

## Раскладка

`xui.same_line(spacing)` продолжает строку; 0 использует текущий стиль. `xui.spacing(pixels)` добавляет отступ. `xui.separator()` рисует разделитель. `xui.cursor()` возвращает две координаты layout; `xui.cursor(x,y)` меняет их. Это координаты раскладки окна; они не взаимозаменяемы с абсолютными экранными координатами рисования.

`xui.available()` возвращает доступные ширину и высоту. `xui.window_rect()` — таблицу с x/y/width/height текущего окна в экранных координатах.

```lua
xui.create_window("sections", "Sections", {key=118}, function()
    if xui.begin_child("content", 260, 160, true) then
        xui.text("Scrollable child")
        xui.end_child()
    end
    if xui.begin_popup("details", 240, true) then
        xui.text("Inline expandable section")
        xui.end_popup()
    end
end)
```

End вызывается **только если begin вернул true**. `begin_popup` здесь означает встроенную анимированную секцию, а не произвольное отдельное всплывающее окно. Его параметр width зарезервирован; контент использует доступную ширину строки.

## Своя графика и hit-test

`xui.line`, `rect`, `rect_filled`, `blur`, `text_at`, `circle`, `gradient` рисуют в абсолютных экранных координатах и не заменяют layout-контролы. Цвета gradient идут по часовой стрелке: верхний левый, верхний правый, нижний правый, нижний левый. `xui.image` отличается: он резервирует layout-элемент.

`xui.invisible_button(label,w,h)` резервирует область и возвращает clicked, state. State содержит x/y/width/height/hovered/down. Click означает новое левое нажатие, не отпускание. Проверка учитывает окно, перекрывающий интерфейс и clip. Это основа собственной кнопки или строки списка.

`xui.mouse_state()` возвращает x/y, dx/dy, down/clicked/released, right_down/right_clicked, wheel. Координаты и дельты — экранные пиксели. Используйте hovered конкретного элемента, чтобы не обрабатывать одно нажатие всем окном.

`xui.push_clip(x,y,w,h)` ограничивает рисование пересечением с текущим clip; закрывайте его `xui.pop_clip()` в обратном порядке вложения.

## Временный стиль

`xui.push_style_color(name, rgba)` / `pop_style_color`, `push_style_var(name,value)` / `pop_style_var`, `push_font(handle)` / `pop_font`, `push_id(id)` / `pop_id` образуют парные области. Их нужно закрывать в обратном порядке в том же callback. Общая глубина — до 64. Неверный pop вызывает ошибку, а не закрывает произвольную область.

Имена цветов получите через `ui.style_colors("xui")`. Числовые переменные стиля допускают значения 0–1000:

```text
rounding checkbox_rounding slider_rounding button_rounding
keybind_rounding combo_rounding popup_rounding combo_popup_rounding
picker_popup_rounding color_swatch_rounding text_input_rounding
window_pad_x window_pad_y item_spacing_x item_spacing_y letter_spacing
frame_pad_x frame_pad_y border_thickness checkbox_size slider_h
keybind_w keybind_h combo_h combo_item_h swatch_w swatch_h text_input_h
```

Render-текстуры и шрифты загружайте в `paint`, храните handles и применяйте в callback окна через XUI. Обычные `render.text/rect/texture` и загрузка render-ресурсов требуют phase paint; они не становятся XUI-функциями только потому, что окно сейчас рисуется.

Практические примеры: [полностью своё меню](examples/xui_custom_menu.lua), [колонки](examples/xui_columns.lua), [контролы](native/mixed_menu.lua).
