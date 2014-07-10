local Yutils = dofile("../Yutils.lua")

local t = {a = 1, {foo = "bar"}}
local t2 = Yutils.table.copy(t)
print(
	Yutils.table.tostring(Yutils.table.append(t, {true, false})) ..
	"\n\n" ..
	Yutils.table.tostring(t2)
)