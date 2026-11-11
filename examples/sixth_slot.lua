-- Slot 6 demonstration. Enable this Lua, then click the sixth sidebar icon.
-- Reserve the exclusive slot for large suites; small Lua should use ui.create
-- on the normal script page. Disable this demo before enabling another owner.
local slot = ui.create_tab("suite", "Lua Studio", {icon = "L", active_icon = "L"})
local general = ui.create_tab_group(slot, "general", "Lua Studio", 1, {top=0, bottom=.19, span=2})
local hud = ui.create_tab_group(slot, "hud", "Overlay", 1, {top=.19, bottom=.64})
local motion = ui.create_tab_group(slot, "motion", "Animation", 1, {top=.64, bottom=1})
local appearance = ui.create_tab_group(slot, "appearance", "Appearance / window", 2, {top=.19, bottom=1})

local function control(group, kind, id, label, default, ...)
    local item = ui.create(kind, id, label, default, ...)
    ui.attach_tab(item, slot, group)
    return item
end
local enabled = control(general, "checkbox", "enabled", "Demo overlay", false)
local mode = control(general, "combo", "mode", "Display", 1, {"Caption", "Caption + clock"})
local caption = control(hud, "text", "caption", "Caption", "LUA STUDIO")
local xpos = control(hud, "slider", "x", "Position X", 40, 0, 1600)
local ypos = control(hud, "slider", "y", "Position Y", 140, 0, 1000)
local opacity = control(hud, "slider", "opacity", "Opacity", 100, 0, 100)
local pulse = control(motion, "checkbox", "pulse", "Pulse", false)
local speed = control(motion, "slider", "speed", "Pulse speed", 2, .1, 8)
local tint = control(appearance, "color", "tint", "Text color", {255,255,255,255})
local panel = control(appearance, "checkbox", "panel", "Background", true)
local panel_color = control(appearance, "color", "panel_color", "Background color", {20,20,20,210})
local extra = control(appearance, "checkbox", "extra", "Separate window", false)
local window = xui.create_window("preview", "Lua Studio / preview", {
    x=740, y=140, width=320, height=240, key=118, open=false
}, function()
    xui.text("Independent Lua window (F7)")
    xui.text(ui.get(caption))
    if xui.menu_button("Toggle overlay", 220, 24) then ui.set(enabled, not ui.get(enabled)) end
    if xui.menu_button("Reset position", 220, 24) then
        ui.set(xpos, 40); ui.set(ypos, 140)
    end
    xui.text("Settings also remain on the script page.")
end)

-- Procedural RGBA code icon, with white glow baked into the active texture.
-- No external images and no resource creation in the menu drawing path.
local function icon(active)
    local pixels = {}
    for y=0,35 do
        for x=0,35 do
            local bracket = (math.abs(x-(7+math.abs(y-17)*.65)) < 1.3 or
                             math.abs(x-(28-math.abs(y-17)*.65)) < 1.3) and y>=8 and y<=26
            local slash = math.abs(x-(20-(y-10)*.25)) < 1.1 and y>=8 and y<=26
            local alpha = (bracket or slash) and 255 or 0
            if active and alpha==0 then
                local radius = math.sqrt((x-17.5)^2+(y-17.5)^2)
                alpha = math.floor(math.max(0, 1-radius/18)*32)
            end
            pixels[#pixels+1] = string.char(255,255,255,alpha)
        end
    end
    return table.concat(pixels)
end
local icons_attempted, previous_extra = false, false
events.on("paint", function()
    if not icons_attempted then
        icons_attempted = true
        local inactive = render.setup_texture_rgba(icon(false), 36, 36)
        local active = render.setup_texture_rgba(icon(true), 36, 36)
        if inactive and active then
            ui.set_tab_style(slot, {icon_texture=inactive, active_icon_texture=active})
        else client.log("Lua Studio: texture unavailable; using the L glyph") end
    end
    local show = ui.get(extra)
    if show ~= previous_extra then
        previous_extra = show
        ui.set_window_open(window, show)
    end
    if not ui.get(enabled) then return end
    local x,y = ui.get(xpos),ui.get(ypos)
    local color = ui.get(tint)
    local alpha = ui.get(opacity)/100
    if ui.get(pulse) then alpha = alpha*(.65+.35*math.sin(client.time()*ui.get(speed))) end
    color[4] = math.floor(color[4]*alpha)
    if ui.get(panel) then
        local bg = ui.get(panel_color); bg[4] = math.floor(bg[4]*alpha)
        render.rect(x-8, y-6, 260, ui.get(mode)==2 and 52 or 30, bg, true)
    end
    render.text(x, y, ui.get(caption), color)
    if ui.get(mode)==2 then
        render.text(x, y+20, string.format("Session time: %.1f", client.time()), color)
    end
end)
