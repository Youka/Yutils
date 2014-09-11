local Yutils = dofile("../src/Yutils.lua")

local s = "Äの"
print("Length: " .. Yutils.utf8.len(s))
for ci, char in Yutils.utf8.chars(s) do
	print(string.format("%d: %s (%d)", ci, char, Yutils.utf8.charrange(char,1)))
end