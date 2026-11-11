-- UTF-8. Português (Brasil) is built in: select it in Misc > Language without Lua.
-- This optional example copies that dictionary into a script-owned variant.
-- Native IDs en, zh-CN and pt-BR cannot be replaced by scripts.
local id = "pt-BR-example"
local translations = {}
for _, key in ipairs(ui.get_translation_keys()) do
    translations[key] = ui.translate(key, "pt-BR")
end
-- Customize individual entries here, for example:
-- translations["Language"] = "Idioma do menu"
assert(ui.register_language(id, "Português (Brasil) - exemplo", translations),
       "Cannot register pt-BR-example: the ID may belong to another script")

-- Optional: place your own font directly in %LOCALAPPDATA%/skeet.
-- A missing file keeps the default menu font, which supports Portuguese accents.
if type(ui.set_language_font) == "function" then
    local ok, reason = ui.set_language_font(id, "menu_pt_br.otf", 11)
    if not ok then client.log("Using the default menu font:", reason) end
end
assert(ui.set_language(id), "Cannot select pt-BR-example")

-- Script-authored captions/options remain literal, independent of menu language.
ui.create("checkbox", "pt_br_literal_enabled", "Enabled", false)
ui.create("combo", "pt_br_literal_hitboxes", "Hitboxes", 1, {"Head", "Chest"})
ui.create("checkbox", "pt_br_own_language", "Minha opção", false)

-- Unload removes this example variant; its saved ID falls back to English.
-- The built-in pt-BR remains available regardless of script lifecycle.
