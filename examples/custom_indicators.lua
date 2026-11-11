-- Read-only indicators. Adjust position/colors here; no combat setting writes.
local displayed, weapon = 0, 0
events.on("paint", function()
    local dt = combat.double_tap()
    local w, h = client.screen_size()
    local x, y = w * 0.5, h * 0.5 + 90
    if dt.active and dt.available then
        if weapon ~= dt.weapon or dt.charge < displayed then displayed = dt.charge end
        weapon = dt.weapon
        local elapsed = math.max(0, math.min(client.frametime(), 0.1))
        displayed = displayed + (dt.charge - displayed) * (1 - math.exp(-18 * elapsed))
        local color = dt.ready and {150, 225, 150, 255} or {255, 190, 90, 255}
        render.arc(x, y, 18, -math.pi / 2, math.pi * 1.5, {35, 39, 46, 220}, 3, 64)
        if displayed > 0 then
            render.arc(x, y, 18, -math.pi / 2, -math.pi / 2 + 2 * math.pi * displayed, color, 2, 64)
        end
        render.text(x - 7, y - 6, "DT", color)
        render.text(x + 26, y - 6, dt.state, color)
    else
        displayed, weapon = 0, 0
    end
    local offset = 28
    for _, feature in ipairs({{"movement", "bhop"}, {"anti aim", "anti aim"}}) do
        local ok, _, value = api.protect(function() return indicators.get(feature[1], feature[2]) end)
        if ok and value.active then
            render.text(x - 18, y + offset, feature[2], {210, 215, 225, 255})
            offset = offset + 16
        end
    end
end)
