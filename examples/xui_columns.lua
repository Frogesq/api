-- Two independent scrollable columns. F7 toggles this window.
local values={}
for i=1,30 do values[i]=false end
xui.create_window("columns","XUI columns",{
    x=200,y=140,width=560,height=420,key=118,open=true
},function()
    local w,h=xui.available()
    local column=math.max(1,(w-8)/2)
    if xui.begin_child("left",column,h,true) then
        xui.text("Switches")
        for i=1,30 do
            xui.push_id("row_"..i)
            values[i]=xui.checkbox("Option "..i,values[i])
            xui.pop_id()
        end
        xui.end_child()
    end
    xui.same_line(8)
    if xui.begin_child("right",column,h,true) then
        xui.text("Independent scroll")
        for i=1,45 do xui.text("Information row "..i) end
        xui.end_child()
    end
end)
