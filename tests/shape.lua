local Yutils = dofile("../Yutils.lua")

local shape = "m -100.5 0 l 100 0 b 100 100 -100 100 -100.5 0 c"
print("Bounding: ", Yutils.shape.bounding(shape))
print("Filtered shape: " .. Yutils.shape.filter(shape, function(x, y)
	return x / 10, y * 2
end))
print("Flattened shape: " .. Yutils.shape.flatten(shape))
print("Moved shape: " .. Yutils.shape.move(shape, 5, -2))
print("Mirrored shape: " .. Yutils.shape.transform(shape, Yutils.math.create_matrix().rotate("y", 180)))
print("Shape with splitted lines: " .. Yutils.shape.split(shape, 15))
print("Shape outline: " .. Yutils.shape.to_outline(Yutils.shape.flatten(shape), 5.5, 10))
print("Pixels:\n" .. Yutils.table.tostring(Yutils.shape.to_pixels("m -4.5 -4 l 0 -4 0 0")))
print(
	"Detected shapes:\n" ..
	Yutils.table.tostring(
		Yutils.shape.detect(5, 5, {
			1, 1, 1, 1, 1,
			1, 0, 0, 2, 1,
			1, 0, 1, 0, 1,
			1, 0, 0, 0, 1,
			1, 1, 1, 1, 1
		})
	)
)
print(
	"Text on shape: " ..
	Yutils.shape.glue(
		Yutils.shape.split(Yutils.shape.flatten(Yutils.decode.create_font("Times New Roman", true, false, true, false, 100).text_to_shape("This is a long text for a test!")), 1),
		"m 0 0 b 0 -300 450 -300 450 0 b 450 240 90 240 93 0 b 90 -180 360 -180 360 0 b 360 120 180 120 180 0 b 180 -60 270 -60 270 0",
		function(x_pct, y_off)
			return 0.2 + x_pct * 0.8, y_off * 1.2
		end
	)
)