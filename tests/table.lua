local Yutils = dofile("../src/Yutils.lua")

local t = {a = 1, {foo = "bar"}}
print(Yutils.table.tostring(t))
print(string.format("Origin %s <> Copy %s", t, Yutils.table.copy(t, 1)))