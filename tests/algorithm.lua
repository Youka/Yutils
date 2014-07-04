local Yutils = dofile("../Yutils.lua")

for s, e, i, n in Yutils.algorithm.frames(0, 10, 1.5) do
	print(string.format("Start: %f - End: %f - Index: %d - Max: %d", s, e, i, n))
end
for line in Yutils.algorithm.lines("Hello\n\r\n\rworld!") do
	print(string.format("#%d: %s", #line, line))
end