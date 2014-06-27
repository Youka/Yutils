local Yutils = dofile("../Yutils.lua")

local shape = "m -100 0 l 100 0 b 100 100 -100 100 -100 0 c"
print("Bounding: ", Yutils.shape.bounding(shape))
print("Filtered shape: " .. Yutils.shape.filter(shape, function(x, y)
	return x / 10, y * 2
end))
print("Flattened shape: " .. Yutils.shape.flatten(shape))
print("Moved shape: " .. Yutils.shape.move(shape, 5, -2))
print("Shape with splitted lines: " .. Yutils.shape.split(shape, 15))
print("Shape outline: " .. Yutils.shape.to_outline(Yutils.shape.flatten(shape), 10))
print("Pixels:\n" .. Yutils.table.tostring(Yutils.shape.to_pixels("m -32 -32 l 0 -32 0 0")))