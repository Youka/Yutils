-- Initalize library location
local lib_algorithm
if _G._YUTILS_GLOBAL then
	if not _G.algorithm then _G.algorithm = {} end
	lib_algorithm = _G.algorithm
else
	lib_algorithm = {}
end

-- Load dependencies
local Ytype = require("Yutils.type")

-- Shortcuts for optimization
local assert, isnum, ceil, isstring = _G.assert, Ytype.isnum, _G.math.ceil, Ytype.isstring

-- Set library methods
lib_algorithm.frames = function(starts, ends, dur)
	assert(isnum(starts) and isnum(ends) and isnum(dur) and dur ~= 0, "start, end and duration number expected")
	local i, n = 0, ceil((ends - starts) / dur)
	return function()
		i = i + 1
		if i <= n then
			local ret_starts = starts + (i-1) * dur
			local ret_ends = ret_starts + dur
			if dur < 0 and ret_ends < ends or dur > 0 and ret_ends > ends then
				ret_ends = ends
			end
			return ret_starts, ret_ends, i, n
		end
	end
end
lib_algorithm.lines = function(text)
	assert(isstring(text), "string expected")
	return function()
		-- Still text left?
		if text then
			-- Find possible line endings
			local cr = text:find("\r", 1, true)
			local lf = text:find("\n", 1, true)
			-- Find earliest line ending
			local text_end, next_step = #text, 0
			if lf then	-- ...\n...
				text_end, next_step = lf-1, 2
			end
			if cr then
				if not lf or cr < lf-1 then	-- ...\r...
					text_end, next_step = cr-1, 2
				elseif cr == lf-1 then	-- ...\r\n...
					text_end, next_step = cr-1, 3
				end
			end
			-- Cut line out & update text
			local line = text:sub(1, text_end)
			if next_step == 0 then
				text = nil
			else
				text = text:sub(text_end+next_step)
			end
			-- Return current line
			return line
		end
	end
end

-- Return library
return lib_algorithm