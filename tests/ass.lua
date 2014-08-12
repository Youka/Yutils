local Yutils = dofile("../Yutils.lua")

print("Converted milliseconds: " .. Yutils.ass.convert_time(1500))
print("Converted timestamp: " .. Yutils.ass.convert_time("2:03:00.04"))
print("Converted ASS style color+alpha: ", Yutils.ass.convert_coloralpha("&H80FFFF20"))
print("Converted numeric color: " .. Yutils.ass.convert_coloralpha(255, 127, 0))
print("Interpolated ASS alpha: " .. Yutils.ass.interpolate_coloralpha(0.5, "&H00&", "&HFF&"))

local parser = Yutils.ass.create_parser([[
[Script Info]
WrapStyle: 1
ScaledBorderAndShadow: no
PlayResX: 1280
PlayResY: 720

[V4+ Styles]
Style: Default,Arial,80,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,0,0,7,10,10,10,1
Style: Default2,Arial,90,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,0,0,7,10,10,10,1

[Events]
Dialogue: 0,0:00:00.00,0:00:20.00,Default,Anyone,0,0,0,First line,Hello
Dialogue: 0,0:00:20.00,0:00:40.00,Default2,Someone,0,0,0,Second line,World!
]])
print("Meta:\n" .. Yutils.table.tostring(parser.meta()))
print("Styles:\n" .. Yutils.table.tostring(parser.styles()))
print("Dialogs:\n" .. Yutils.table.tostring(parser.dialogs({extra=true})))