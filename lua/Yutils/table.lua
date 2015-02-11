-- Initalize library location
local lib_table = _G._YUTILS_GLOBAL and _G.table or {}

-- Load dependencies
local Ytype = require("Yutils.type")

-- Shortcuts for optimization
local assert, istable, isnil, isint, pairs, isstring, concat = _G.assert, Ytype.istable, Ytype.isnil, Ytype.isint, _G.pairs, Ytype.isstring, _G.table.concat

-- Set library methods
lib_table.copy = function(t, depth)
	assert(istable(t) and (isnil(depth) or isint(depth) and depth >= 1), "table and optional depth expected")
	-- Recursive table copy without limit
	local function copy_recursive(old_t)
		local new_t = {}
		for key, value in pairs(old_t) do
			new_t[key] = istable(value) and copy_recursive(value) or value
		end
		return new_t
	end
	-- Recursive table copy with limit
	local function copy_recursive_n(old_t, depth)
		local new_t = {}
		for key, value in pairs(old_t) do
			new_t[key] = istable(value) and depth >= 2 and copy_recursive_n(value, depth-1) or value
		end
		return new_t
	end
	return depth and copy_recursive_n(t, depth) or copy_recursive(t)
end
lib_table.tostring = function(t)
	assert(istable(t), "table expected")
	local result, result_n = {}, 0
	local function convert_recursive(t, space)
		for key, value in pairs(t) do
			result_n = result_n + 1
			result[result_n] = ("%s[%s] = %s"):format(space,
																	isstring(key) and ("%q"):format(key) or key,
																	isstring(value) and ("%q"):format(value) or value)
			if istable(value) then
				convert_recursive(value, space .. "\t")
			end
		end
	end
	convert_recursive(t, "")
	return concat(result, "\n")
end

-- Return library
return lib_table