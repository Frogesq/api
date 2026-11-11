-- Observed positions only. Circles are user-selected display radii, NOT damage geometry.
assert(api.version >= 3, "grenade_warning requires Lua API 3")
local enabled=ui.create("checkbox","gw_enabled","Grenade warnings",false)
local radius=ui.create("slider","gw_radius","Display radius (approximate)",150,0,500)
local icons={}
local known={hegrenade=true,flashbang=true,smokegrenade=true,molotov=true,incgrenade=true,decoy=true}
events.on("paint",function()
    if not ui.get(enabled) then return end
    for _,g in ipairs(grenades.observations()) do
        local opacity=g.opacity or 1
        if opacity>0 then
            local kind=g.kind=="inferno" and "molotov" or g.kind
            if icons[kind]==nil then icons[kind]=known[kind] and render.grenade_icon(kind) or false end
            local x,y=render.world_to_screen(g.origin)
            local color={255,255,255,math.floor(210*opacity)}
            if ui.get(radius)>0 then render.circle_3d(g.origin,ui.get(radius),color) end
            if g.geometry and g.geometry.kind=="fire_points" then
                for _,point in ipairs(g.geometry.points) do render.circle_3d(point,14,color) end
            end
            if x then
                if icons[kind] then render.texture(icons[kind],x-12,y-30,24,24,color) end
                render.text(x+14,y-20,kind.." / observed",color)
            end
        end
    end
end)
