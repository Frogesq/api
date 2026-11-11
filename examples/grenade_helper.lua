-- API 3: recorded waypoint approach and command-timed grenade release.
-- F6 saves a throw; F7 records an approach waypoint; F8 starts/cancels.
-- Disable conflicting native movement/peek assistance before use.
assert(api.version >= 3, "grenade_helper requires Lua API 3")
local enabled = ui.create("checkbox", "gh_enabled", "Grenade helper", false)
local slot = ui.create("slider", "gh_slot", "Lineup slot", 1, 1, 16)
local jump = ui.create("checkbox", "gh_jump", "Jump throw", false)
local run = ui.create("checkbox", "gh_run", "Run throw", false)
local crouch = ui.create("checkbox", "gh_crouch", "Crouch throw", false)
local strength = ui.create("combo", "gh_strength", "Throw buttons", 1, {"Primary", "Secondary", "Both"})
local lineups = storage.get("lineups_v1", {})
local route, previous, task = {}, {}, nil
local status = "F7 waypoint / F6 save / F8 start"
local function edge(key)
    local pressed = client.key_down(key)
    local result = pressed and not previous[key]
    previous[key] = pressed
    return result
end
local function cancel(reason) grenades.cancel(); task = nil; status = reason end
local function distance(a,b)
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
events.on("create_move", function()
    local record, waypoint, toggle = edge(117), edge(118), edge(119)
    if not ui.get(enabled) then cancel("Disabled"); return end
    local state, grenade, command = movement.context(), grenades.context(), cmd.get()
    local map = client.map_name()
    if not state or not grenade or not map then cancel("Equip a grenade on a map"); return end
    local key = map .. ":" .. tostring(ui.get(slot))
    if waypoint and not task then
        if #route < 32 then route[#route+1] = state.origin; status = "Waypoint " .. #route end
    end
    if record and not task then
        lineups[key] = {version=1, map=map, item=grenade.item_id, origin=state.origin,
            angles=command.angles, route=route, jump=ui.get(jump), run=ui.get(run),
            crouch=ui.get(crouch), strength=ui.get(strength)}
        storage.set("lineups_v1", lineups); route={}; status="Saved slot " .. ui.get(slot)
    end
    if toggle then
        if task then cancel("Cancelled; a primed grenade may still throw"); return end
        local entry = lineups[key]
        if not entry or entry.version~=1 or entry.item~=grenade.item_id then status="No matching lineup"; return end
        task={entry=entry, handle=grenade.handle, stage="approach", next=1, start=client.time()}
    end
    if not task then return end
    if task.handle~=grenade.handle or task.entry.map~=map or client.time()-task.start>20 then cancel("Weapon/map changed or timeout"); return end
    for _,keycode in ipairs({87,65,83,68,32,16,17,1,2}) do
        if client.key_down(keycode) then cancel("Manual input; a primed grenade may still throw"); return end
    end
    for _,name in ipairs({"slowwalk","edgestop","edgejump","fast ladder","quick stop","strafe assist","jump bug"}) do
        if settings.get("movement",name) then cancel("Disable movement: "..name); return end
    end
    if settings.get("peek assistance","quick peek") then cancel("Disable native peek assistance");return end
    if task.last_angles and (math.abs(command.angles.x-task.last_angles.x)>2 or
        math.abs((command.angles.y-task.last_angles.y+180)%360-180)>2) then cancel("Manual camera input");return end
    if not grenades.claim() then cancel("Grenade unavailable"); return end
    movement.claim("bhop");movement.claim("strafe")
    local entry=task.entry
    cmd.set_angles(entry.angles,true)
    task.last_angles=entry.angles
    cmd.set_button(buttons.duck,entry.crouch)
    cmd.set_movement(0,0,0)
    status=task.stage
    if task.stage=="approach" then
        local target=entry.route[task.next] or entry.origin
        if distance(state.origin,target)<2.5 then
            if entry.route[task.next] then task.next=task.next+1
            elseif state.on_ground and math.sqrt(state.velocity.x^2+state.velocity.y^2)<3 then task.stage="prime" end
        else
            local a={x=state.origin.x,y=state.origin.y,z=state.origin.z+36}
            local b={x=target.x,y=target.y,z=target.z+36}
            local hit=trace.line(a,b,0)
            if hit.all_solid or hit.fraction<0.98 or math.abs(target.z-state.origin.z)>24 then cancel("Route blocked; record closer waypoints");return end
            local dx,dy=target.x-state.origin.x,target.y-state.origin.y
            local length=math.sqrt(dx*dx+dy*dy)
            local yaw=math.rad(entry.angles.y)
            local scale=math.min(1,length/32)
            cmd.set_movement((math.cos(yaw)*dx+math.sin(yaw)*dy)/length*scale,
                (-math.sin(yaw)*dx+math.cos(yaw)*dy)/length*scale,0)
        end
    elseif task.stage=="prime" then
        if grenade.pin_pulled==nil then cancel("Pin state unavailable");return end
        cmd.set_button(buttons.attack,entry.strength~=2)
        cmd.set_button(buttons.attack2,entry.strength~=1)
        if grenade.pin_pulled then task.stage="prepare";task.command=command.number end
    elseif task.stage=="prepare" then
        cmd.set_button(buttons.attack,entry.strength~=2);cmd.set_button(buttons.attack2,entry.strength~=1)
        if entry.run then cmd.set_movement(1,0,0) end
        if entry.jump then cmd.set_button(buttons.jump,true) end
        if command.number>task.command then task.stage="release" end
    elseif task.stage=="release" then
        if entry.run then cmd.set_movement(1,0,0) end
        cmd.set_button(buttons.attack,false);cmd.set_button(buttons.attack2,false)
        task=nil;status="Release requested; verify landing in game"
    end
end)
events.on("paint",function() if ui.get(enabled) then render.text(30,180,"Grenade helper: "..status,{235,220,160,255}) end end)
