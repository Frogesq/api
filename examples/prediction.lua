-- A snapshot of the engine's actual transaction, not a second simulation.
local enabled=ui.create("checkbox","pred_enabled","Prediction observation",false)
local sample
events.on("prediction",function() sample=prediction.result() end)
events.on("paint",function()
    if not ui.get(enabled) or not sample then return end
    render.text(30,210,string.format("Prediction cmd %d: %.1f / %.1f / %.1f",
        sample.command_number,sample.velocity.x,sample.velocity.y,sample.velocity.z),{220,230,255,255})
end)
