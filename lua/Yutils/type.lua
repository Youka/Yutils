-- Initalize library location
local lib_type = _G._YUTILS_GLOBAL and _G or {}

-- Shortcuts for optimization
local type, floor, pairs, getupvalue = _G.type, _G.math.floor, _G.pairs, _G.debug.getupvalue

-- Set library methods
lib_type.isnil = function(x)
	return x == nil
end
lib_type.isbool = function(x)
	return x == true or x == false
end
lib_type.isnum = function(x)
	return type(x) == "number"
end
lib_type.isint = function(x)
	return lib_type.isnum(x) and floor(x) == x
end
lib_type.isstring = function(x)
	return type(x) == "string"
end
lib_type.istext = function(x)
	return lib_type.isstring(x) and lib_type.isnil(x:find("[%z\1-\6\14-\31]"))
end

lib_type.istable = function(x)
	return type(x) == "table"
end
lib_type.isarray = function(x)
	if not lib_type.istable(x) then return false end
	for key in pairs(x) do
		if not lib_type.isint(key) or key < 1 then return false end
	end
	return true
end
lib_type.isfunc = function(x)
	return type(x) == "function"
end
lib_type.ispure = function(x)
	return lib_type.isfunc(x) and lib_type.isnil(getupvalue(x, 1))
end
lib_type.isthread = function(x)
	return type(x) == "thread"
end
lib_type.isudata = function(x)
	return type(x) == "userdata"
end
lib_type.iscdata = function(x)
	return type(x) == "cdata"
end
lib_type.issame = function(a, b)
	return type(a) == type(b)
end
lib_type.default = function(x, opt)
	return lib_type.isnil(x) and opt or x
end

-- Return library
return lib_type