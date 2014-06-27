local Yutils = dofile("../Yutils.lua")

local t = {a = 1, {foo = "bar"}}
local t2 = Yutils.table.copy(t)
t.a = 2
print(Yutils.table.tostring(t2))