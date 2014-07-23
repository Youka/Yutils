local Yutils = dofile("../Yutils.lua")

local bmp = Yutils.decode.create_bmp_reader("test.bmp")
print("File size: " .. bmp.file_size())
print("Width: " .. bmp.width())
print("Height: " .. bmp.height())
print("Depth: " .. bmp.bit_depth())
print("Data size: " .. bmp.data_size())
print("Row size: " .. bmp.row_size())
print("Packed data:\n" .. Yutils.table.tostring(bmp.data_packed()))
print("Data text: " .. bmp.data_text())

local font = Yutils.decode.create_font("Comic Sans MS", true, true, true, false, 64, 1, 1, 0.5)
print("Metrics:\n" .. Yutils.table.tostring(font.metrics()))
print("Extents:\n" .. Yutils.table.tostring(font.text_extents("TestのMy")))
print("Text shape: " .. font.text_to_shape("TestのMy"))
print("Fonts:")
for _, font in ipairs(Yutils.decode.list_fonts(true)) do
	print(string.format("\t%s (%s)", font.name, font.file))
end