local Yutils = dofile("../src/Yutils.lua")

local font = Yutils.decode.create_font("Comic Sans MS", true, true, true, false, 64, 1, 1, 0.5)
print("Metrics:\n" .. Yutils.table.tostring(font.metrics()))
print("Extents:\n" .. Yutils.table.tostring(font.text_extents("TestのMy")))
print("Text shape: " .. font.text_to_shape("TestのMy"))
print("Fonts:")
for _, font in ipairs(Yutils.decode.list_fonts(true)) do
	print(string.format("\t%s: %s (%s)", font.name, font.style, font.file))
end