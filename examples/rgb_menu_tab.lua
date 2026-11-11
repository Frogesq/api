-- Own visible tabs inside an XUI window. F6 toggles this RGB menu.
local tab,speed,enabled=1,1,true
local function rgb(phase,alpha)
    return {math.floor(127.5+127.5*math.sin(phase)),
        math.floor(127.5+127.5*math.sin(phase+2.0944)),
        math.floor(127.5+127.5*math.sin(phase+4.1888)),alpha or 255}
end
xui.create_window("rgb","RGB Lab",{
    x=280,y=150,width=410,height=290,key=117,open=true
},function()
    local r=xui.window_rect()
    local phase=client.time()*speed
    for i=1,#"RGB Lab" do
        xui.text_at(r.x+18+(i-1)*12,r.y+40,("RGB Lab"):sub(i,i),rgb(phase+i*.45))
    end
    xui.cursor(18,72)
    if xui.menu_button("Demo",150,24) then tab=1 end
    xui.same_line(8)
    if xui.menu_button("Appearance",150,24) then tab=2 end
    xui.cursor(32,112)
    xui.push_style_color("checkbox_mark",rgb(phase))
    xui.push_style_color("slider_fill",rgb(phase+.5))
    if tab==1 then
        enabled=xui.checkbox("Show colored bar",enabled)
        if enabled then
            xui.gradient(r.x+24,r.y+r.height-30,r.width-48,5,
                rgb(phase),rgb(phase+2),rgb(phase+2),rgb(phase),2)
        end
    else
        speed=xui.slider_float("RGB speed",speed,.1,4)
    end
    xui.pop_style_color()
    xui.pop_style_color()
end)
