-- A live player/grenade radar. No external image or FFI is needed.
assert(radar and radar.snapshot, "This script requires the radar API")
local enabled=ui.create("checkbox","radar_enabled","Custom radar",false)
local range=ui.create("slider","radar_range","Radar range",1500,256,8192)
local size=ui.create("slider","radar_size","Radar size",220,120,600)
local rotate=ui.create("checkbox","radar_rotate","Rotate radar",true)
local left=ui.create("slider","radar_x","Radar X",30,0,7680)
local top=ui.create("slider","radar_y","Radar Y",250,0,4320)
local icons={}
local known={hegrenade=true,flashbang=true,smokegrenade=true,molotov=true,incgrenade=true,decoy=true}
events.on("paint",function()
    if not ui.get(enabled) then return end
    local s=radar.snapshot()
    if not s then return end
    local x,y,n=ui.get(left),ui.get(top),ui.get(size)
    local function project(p)
        return radar.project(p,s.center,s.yaw,ui.get(range),x,y,n,ui.get(rotate),true)
    end
    render.rect(x,y,n,n,{15,18,24,205},true)
    render.push_clip_rect(x,y,n,n)
    render.line(x+n/2,y,x+n/2,y+n,{70,80,100,100})
    render.line(x,y+n/2,x+n,y+n/2,{70,80,100,100})
    for _,p in ipairs(s.players) do
        local px,py,inside=project(p.origin)
        local color={255,255,255,230}
        render.circle(px,py,inside and 3 or 4,color,inside)
    end
    for _,g in ipairs(s.grenades) do
        local opacity=g.opacity or 1
        if opacity>0 then
            local color={255,255,255,math.floor(230*opacity)}
            local px,py=project(g.origin)
            local kind=g.kind=="inferno" and "molotov" or g.kind
            if icons[kind]==nil then icons[kind]=known[kind] and render.grenade_icon(kind) or false end
            if icons[kind] then render.texture(icons[kind],px-7,py-7,14,14,color)
            else render.circle(px,py,3,color,false) end
            if g.geometry then
                for _,point in ipairs(g.geometry.points) do
                    local fx,fy,inside=project(point)
                    if inside then render.circle(fx,fy,2,color,true) end
                end
            end
        end
    end
    render.circle(x+n/2,y+n/2,4,{255,255,255,255},true)
    render.pop_clip_rect()
    render.text(x,y-18,s.map,{255,255,255,220})
end)
