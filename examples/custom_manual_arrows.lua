-- Asset-free custom arrows. Enable Manual Arrows and bind Manual Left/Right.
-- Visibility overrides affect drawing only; never change the direction binds.
local enabled = ui.create("checkbox", "custom_arrows_enabled", "Custom manual arrows", false)
local size = ui.create("slider", "custom_arrows_size", "Arrow size", 12, 4, 32)
local function release()
    settings.override("anti aim", "manual left arrow", nil)
    settings.override("anti aim", "manual right arrow", nil)
end
events.on("paint", function()
    local me = entity.local_player()
    if not ui.get(enabled) or not me or not me.alive then release(); return end
    -- These historical setting IDs intentionally use category/name in this order.
    if not settings.get("manual arrows", "anti aim") then release(); return end
    settings.override("anti aim", "manual left arrow", false)
    settings.override("anti aim", "manual right arrow", false)
    local w, h = render.screen_size()
    local distance = math.max(20, math.min(300, settings.get("anti aim", "manual arrow distance")))
    local half = ui.get(size) * 0.5
    local function arrow(x, direction)
        local tip, base = x + direction * half * 0.8, x - direction * half * 0.8
        local color = {150, 225, 150, 255}
        render.line(base, h * 0.5 - half, tip, h * 0.5, {0, 0, 0, 163}, 4)
        render.line(tip, h * 0.5, base, h * 0.5 + half, {0, 0, 0, 163}, 4)
        render.line(base, h * 0.5 - half, tip, h * 0.5, color, 2)
        render.line(tip, h * 0.5, base, h * 0.5 + half, color, 2)
    end
    if settings.get("manual left", "anti aim") then arrow(w * 0.5 - distance * 0.5, -1) end
    if settings.get("manual right", "anti aim") then arrow(w * 0.5 + distance * 0.5, 1) end
end)
events.on("shutdown", release)
