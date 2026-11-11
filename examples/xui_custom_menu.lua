-- Self-contained glass menu. F6 toggles it; drag its top 30px.
local tab,enabled,amount=1,storage.get("enabled",true),storage.get("amount",35)
local mode,text,tint=1,"Custom XUI",{110,175,255,255}
local selection,progress={true,false,true},amount/100
xui.create_window("custom","Custom XUI",{
    x=240,y=160,width=430,height=420,key=117,open=true,
    titlebar=false,background=false,padding=0
},function()
    local r=xui.window_rect()
    xui.blur(r.x,r.y,r.width,r.height,{15,18,27,170},12)
    xui.gradient(r.x,r.y,r.width,48,{45,70,110,140},{35,30,70,120},
        {20,23,32,15},{20,23,32,15},12)
    xui.rect(r.x,r.y,r.width,r.height,{145,180,230,65},12,1)
    xui.text_at(r.x+18,r.y+12,"CUSTOM / XUI",{220,235,255,255})
    xui.push_style_color("slider_fill",tint)
    xui.push_style_color("checkbox_mark",tint)
    xui.cursor(18,54)
    for i,label in ipairs({"Controls","Appearance"}) do
        xui.push_id("tab_"..i)
        local clicked,item=xui.invisible_button(label,150,28)
        local bg=tab==i and {42,62,90,220} or {24,28,38,180}
        if item.hovered then bg={52,72,100,230} end
        xui.rect_filled(item.x,item.y,item.width,item.height,bg,5)
        xui.text_at(item.x+12,item.y+6,label,{225,235,250,255})
        if clicked then tab=i end
        xui.pop_id()
        if i==1 then xui.same_line(8) end
    end
    xui.cursor(32,100)
    if tab==1 then
        local changed
        enabled,changed=xui.checkbox("Enabled",enabled)
        if changed then storage.set("enabled",enabled) end
        amount,changed=xui.slider_int("Amount",amount,0,100)
        if changed then storage.set("amount",amount) end
        mode=xui.combo("Mode",mode,{"Calm","Bright","Animated"})
        selection=xui.multicombo("Layers",selection,{"Panel","Particles","Border"})
        text=xui.input_text("Caption",text,128,"Your caption")
    else
        tint=xui.color_picker("Accent",tint)
        xui.text("Window theme stays local to this callback.")
        if xui.menu_button("Reset accent",180,24) then tint={110,175,255,255} end
    end
    local dt=math.min(client.frametime(),.1)
    progress=progress+(amount/100-progress)*(1-math.exp(-12*dt))
    local pulse=math.floor(110+40*math.sin(client.time()*2))
    xui.push_clip(r.x+18,r.y+r.height-44,r.width-36,28)
    xui.rect_filled(r.x+18,r.y+r.height-36,r.width-36,5,{35,42,54,220},2)
    xui.gradient(r.x+18,r.y+r.height-36,(r.width-36)*progress,5,
        tint,{170,110,255,pulse},{170,110,255,pulse},tint,2)
    xui.pop_clip()
    xui.pop_style_color()
    xui.pop_style_color()
end)
