# Графика и ресурсы

## Координаты и цвета

Обычная отрисовка выполняется в `events.on("paint", ...)`. Экранные координаты заданы в пикселях: начало в левом верхнем углу, x вправо, y вниз. `client.screen_size()` и `render.screen_size()` возвращают **два числа**, width и height.

Color — массив ровно из четырёх целых чисел `{red, green, blue, alpha}`, каждое 0–255. Vector2 — `{x=...,y=...}`, Vector3 — `{x=...,y=...,z=...}`. Не смешивайте массив RGBA с объектом `{r=...}`. Числовые аргументы должны быть конечными.

## Двумерные примитивы

| Метод | Назначение |
|---|---|
| `render.text(x,y,text,color,font)` | Текст; font — необязательный свой handle |
| `render.measure_text(text,font)` | Два числа: ширина и высота текста |
| `render.line(x1,y1,x2,y2,color,thickness)` | Отрезок |
| `render.rect(x,y,w,h,color,filled)` | Прямоугольник, при filled=true с заливкой |
| `render.circle(x,y,radius,color,filled)` | Круг или окружность |
| `render.rect_filled_fade(x,y,w,h,tl,tr,br,bl)` | Градиент по четырём углам |
| `render.circle_fade(x,y,radius,inside,outside)` | Радиальный градиент |
| `render.arc(x,y,radius,start_angle,end_angle,color,thickness,segments)` | Дуга; углы в радианах, segments 2–256 |
| `render.poly_line(points,color,thickness,closed)` | 2–256 точек Vector2; при closed=true замыкается |
| `render.polygon(points,color)` | Простой заполненный многоугольник из 3–256 точек без отверстий |
| `render.concave_polygon(points,color)` | Тот же контракт для невыпуклого контура |

Для clip вызовите `render.push_clip_rect(x,y,w,h)`, нарисуйте содержимое, затем `render.pop_clip_rect()`. Не переносите открытый clip между callbacks. Порядок рисования определяет наложение элементов одного слоя.

```lua
events.on("paint", function()
    local width = render.screen_size()
    local label = "Custom overlay"
    local text_width = render.measure_text(label)
    render.rect(width-240, 20, 220, 54, {15,18,24,210}, true)
    render.text(width-130-text_width/2, 38, label, {255,255,255,255})
end)
```

## Проекция и фигуры в мире

`render.world_to_screen(Vector3)` возвращает **x, y, on_screen** либо nil. Это не таблица. При отсутствии камеры или точке за камерой нельзя обращаться к x/y. У проецируемой точки вне границ экрана могут быть координаты и `on_screen=false`.

```lua
events.on("paint", function()
    local me = entity.local_player()
    if not me then return end
    local x, y, on_screen = render.world_to_screen(me.origin)
    if x and on_screen then render.text(x, y, "Origin", {255,255,255,255}) end
end)
```

`render.circle_3d(position,radius,color,normal)`, `circle_filled_3d` и `circle_fade_3d` строят окружность/круг в мире. Позиция и радиус — игровые единицы. Normal задаёт нормаль плоскости, по умолчанию `{x=0,y=0,z=1}`. Отрисованный радиус не рассчитывает столкновения, урон или форму огня.

Для иконок гранат существует `render.grenade_icon`; его контракт описан в [разделе гранат](GRENADES.ru.md).

## Загрузка изображений

`render.setup_texture(basename)` читает закодированное изображение из `resources`; префикс `skeetles/` выбирает папку skeetles. Файл — до 4 МиБ. `render.setup_texture_from_memory(bytes)` принимает строку с закодированным изображением того же максимального размера. Поддержка зависит от декодера; неподдерживаемый файл возвращает ресурсную ошибку.

`render.setup_texture_rgba(bytes,width,height)` принимает точно width×height×4 сырых байт RGBA. Каждая сторона 1–4096, произведение — не более 1 048 576 пикселей. Результат всех setup-вызовов: texture handle либо `nil, reason`.

```lua
local texture, attempted
events.on("paint", function()
    if not attempted then
        attempted = true
        local reason
        texture, reason = render.setup_texture("logo.png")
        if not texture then client.log_level("warning", "Logo:", reason) end
    end
    if texture then render.texture(texture, 30, 140, 96, 96) end
end)
```

Один неудачный запрос не нужно повторять каждый кадр. После замены файла можно перезагрузить скрипт.

`render.texture_size(handle)` возвращает исходные width, height. `render.texture(handle,x,y,w,h,tint,rounding)` меняет размер отображения, но не исходное изображение. Tint по умолчанию белый, rounding — 0. `render.texture_rotated` принимает центр, размеры и угол **по часовой стрелке в радианах**.

## Обновляемые пиксели

Для видео или процедурной картинки один раз создайте `render.create_texture_rgba(width,height)`. Полученный mutable-handle принадлежит скрипту. Обновляйте его перед рисованием, вместо создания нового ресурса на каждом кадре.

`render.update_texture_rgba(handle,bytes)` требует точное число RGBA-байт. `render.update_texture_pixels(handle,bytes,format,pitch)` принимает:

| format | Байтов на пиксель |
|---|---|
| `rgba8`, `bgra8`, `bgrx8` | 4 |
| `rgb565`, `rgb555` | 2, little-endian |

Pitch — байтов на строку, по умолчанию width×bytes_per_pixel. Он не может быть меньше этой величины. Длина строки данных — от pitch×(height−1)+row_bytes до pitch×height, максимум 4 МиБ. `bgrx8` не использует исходный alpha как прозрачность. Неверные аргументы вызывают Lua-ошибку; недоступность ресурса возвращает nil и reason.

## Шрифты

`render.setup_font("font.ttf",size)` ищет файл в resources; `"fonts/font.ttf"` — в fonts. Используются TTF/OTF, размер 6–96 пикселей. Вызывайте в paint один раз, храните handle и передавайте в text/measure_text. nil-handle означает использование стандартного шрифта в методах, где он необязателен.

`render.builtin_font(target,handle)` временно меняет шрифт штатных `esp`, `keybinds` или `watermark`. Установка — в paint; nil освобождает свой override, в том числе из shutdown. Выбор шрифта меню настраивается отдельно через ui API.

## Общие лимиты ресурсов

Кэш текстур ограничен 64 слотами и 8 388 608 пикселями; шрифтов — 16 записями. Общий учёт resource bytes — 32 МиБ. Это не полный учёт native/GPU-памяти. Кэш может сохранять ресурсы после выгрузки для повторного использования; выключение скрипта не означает немедленного освобождения всех GPU-объектов.

`render.frame_count()` — счётчик Lua paint-проходов с инициализации, не сетевой tick. `render.frame_time()` — длительность кадра. Для ограничения частоты обновления данных используйте время, а не предположение о фиксированном FPS.
