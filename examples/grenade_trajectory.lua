-- Read-only trajectory display: it never claims movement or releases a grenade.
assert(grenades.preview and grenades.predict_throw,"This script requires grenade predictions")
local enabled=ui.create("checkbox","gt_enabled","Grenade trajectory",false)
local custom=ui.create("checkbox","gt_custom","Predict chosen throw angles",false)
local pitch=ui.create("slider","gt_pitch","Throw pitch",-20,-89,89)
local strength=ui.create("slider","gt_strength","Throw strength (%)",100,0,100)
local result,last,map,handle=nil,-1,nil,nil
events.on("create_move",function()
    if not ui.get(enabled) or not ui.get(custom) then result=nil;return end
    local g=grenades.context()
    local current_map=client.map_name()
    if not g then result=nil;handle=nil;return end
    if map~=current_map or handle~=g.handle then result=nil;last=-1 end
    map,handle=current_map,g.handle
    local now=client.time()
    if now-last<0.1 then return end
    last=now
    local angles=cmd.get().angles
    result=grenades.predict_throw({x=ui.get(pitch),y=angles.y,z=0},ui.get(strength)/100)
end)
events.on("paint",function()
    if not ui.get(enabled) then return end
    local p
    if ui.get(custom) then
        if client.map_name()==map and client.time()-last<=0.25 then p=result end
    else p=grenades.preview() end
    if not p then return end
    local color={255,255,255,p.complete and 220 or 160}
    if p.valid then
        for i=2,#p.points do
            local ax,ay=render.world_to_screen(p.points[i-1])
            local bx,by=render.world_to_screen(p.points[i])
            if ax and bx then render.line(ax,ay,bx,by,color,1.5) end
        end
        for _,point in ipairs(p.bounces) do render.circle_3d(point,3,color) end
        if p.complete then render.circle_3d(p.end_pos,7,color) end
    end
    render.text(30,210,p.complete and string.format("%s: %.2f s",p.reason,p.duration) or p.reason,color)
end)
