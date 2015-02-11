-- Initalize library location
local lib_math = _G._YUTILS_GLOBAL and _G.math or {}

-- Load dependencies
local Ytype = require("Yutils.type")

-- Shortcuts for optimization
local assert, isnum, sqrt, min, unpack, isnil, rad, sin, cos, istable, ipairs = _G.assert, Ytype.isnum, _G.math.sqrt, _G.math.min, _G.unpack or _G.table.unpack--[[Lua 5.2 change]], Ytype.isnil, _G.math.rad, _G.math.sin, _G.math.cos, Ytype.istable, _G.ipairs
local kappa = 4 * (sqrt(2) - 1) / 3	-- Factor for bezier control points distance to node points

-- Set library methods
lib_math.arccurve = function(x, y, cx, cy, angle)
	assert(isnum(x) and isnum(y) and isnum(cx) and isnum(cy) and isnum(angle) and angle >= -360 and angle <= 360, "start & center point and valid angle (-360<=x<=360) expected")
	-- Something to do?
	if angle ~= 0 then
		-- Define arc clock direction & set angle to positive range
		local cw = lib_math.sign(angle)
		if angle < 0 then angle = -angle end
		-- Relative start point to center
		local rx0, ry0 = x - cx, y - cy
		-- Create curves in 90 degree chunks
		local curves, curves_n, angle_sum, rotate, stretch = {}, 0, 0, lib_math.rotate, lib_math.stretch
		repeat
			-- Get arc end point
			local cur_angle_pct = min(angle - angle_sum, 90) / 90
			local rx3, ry3 = rotate(rx0, ry0, cw * 90 * cur_angle_pct)
			-- Get arc start to end vector
			local rx03, ry03 = rx3 - rx0, ry3 - ry0
			-- Scale arc vector to curve node <-> control point distance
			rx03, ry03 = stretch(rx03, ry03, 0, sqrt((rx03*rx03 + ry03*ry03)/2) * kappa)
			-- Get curve control points
			local rx1, ry1 = rotate(rx03, ry03, cw * -45 * cur_angle_pct)
			rx1, ry1 = rx0 + rx1, ry0 + ry1
			local rx2, ry2 = rotate(-rx03, -ry03, cw * 45 * cur_angle_pct)
			rx2, ry2 = rx3 + rx2, ry3 + ry2
			-- Insert curve to output
			curves[curves_n+1], curves[curves_n+2], curves[curves_n+3], curves[curves_n+4],
			curves[curves_n+5], curves[curves_n+6], curves[curves_n+7], curves[curves_n+8] =
			cx + rx0, cy + ry0, cx + rx1, cy + ry1, cx + rx2, cy + ry2, cx + rx3, cy + ry3
			curves_n = curves_n + 8
			-- Prepare next curve
			rx0, ry0 = rx3, ry3
			angle_sum = angle_sum + 90
		until angle_sum >= angle
		-- Return curve points as tuple
		return unpack(curves)
	end
end
lib_math.bezier = function(pct, pts)
	assert(isnum(pct) and pct >= 0 and pct <= 1 and istable(pts), "percent number and points table expected")
	local pts_n = #pts
	assert(pts_n >= 2, "at least 2 points expected")
	for _, value in ipairs(pts) do
		assert(istable(value) and isnum(value[1]) and isnum(value[2]) and (isnil(value[3]) or isnum(value[3])), "points have to be tables with 2 or 3 numbers")
	end
	-- Pick a fitting fast calculation
	local pct_inv = 1 - pct
	if pts_n == 2 then	-- Linear curve
		return pct_inv * pts[1][1] + pct * pts[2][1],
				pct_inv * pts[1][2] + pct * pts[2][2],
				pts[1][3] and pts[2][3] and pct_inv * pts[1][3] + pct * pts[2][3] or 0
	elseif pts_n == 3 then	-- Quadratic curve
		return pct_inv * pct_inv * pts[1][1] + 2 * pct_inv * pct * pts[2][1] + pct * pct * pts[3][1],
				pct_inv * pct_inv * pts[1][2] + 2 * pct_inv * pct * pts[2][2] + pct * pct * pts[3][2],
				pts[1][3] and pts[2][3] and pct_inv * pct_inv * pts[1][3] + 2 * pct_inv * pct * pts[2][3] + pct * pct * pts[3][3] or 0
	elseif pts_n == 4 then	-- Cubic curve
		return pct_inv * pct_inv * pct_inv * pts[1][1] + 3 * pct_inv * pct_inv * pct * pts[2][1] + 3 * pct_inv * pct * pct * pts[3][1] + pct * pct * pct * pts[4][1],
				pct_inv * pct_inv * pct_inv * pts[1][2] + 3 * pct_inv * pct_inv * pct * pts[2][2] + 3 * pct_inv * pct * pct * pts[3][2] + pct * pct * pct * pts[4][2],
				pts[1][3] and pts[2][3] and pts[3][3] and pts[4][3] and pct_inv * pct_inv * pct_inv * pts[1][3] + 3 * pct_inv * pct_inv * pct * pts[2][3] + 3 * pct_inv * pct * pct * pts[3][3] + pct * pct * pct * pts[4][3] or 0
	else	-- pts_n > 4
		-- Calculate coordinate
		local ret_x, ret_y, ret_z, n, fac = 0, 0, 0, pts_n - 1, lib_math.fac
		for i=0, n do
			local pt = pts[1+i]
			-- Bernstein polynom
			local bern = fac(n) / (fac(i) * fac(n - i)) *	--Binomial coefficient
					pct^i * pct_inv^(n - i)
			ret_x = ret_x + pt[1] * bern
			ret_y = ret_y + pt[2] * bern
			if pt[3] then ret_z = ret_z + pt[3] * bern end
		end
		return ret_x, ret_y, ret_z
	end
end
lib_math.distance = function(x, y, z)
	assert(isnum(x) and isnum(y) and (isnil(z) or isnum(z)), "one vector (2 or 3 numbers) expected")
	return z and sqrt(x*x + y*y + z*z) or sqrt(x*x + y*y)
end
lib_math.fac = function(n)
	assert(isnum(n), "number expected")
	local k = 1
	for i=2, n do
		k = k * i
	end
	return k
end
lib_math.rotate = function(x, y, angle)
	assert(isnum(x) and isnum(y) and isnum(angle), "x & y coordinate and angle expected")
	local ra = rad(angle)
	return cos(ra)*x - sin(ra)*y,
		sin(ra)*x + cos(ra)*y
end
lib_math.sign = function(x)
	assert(isnum(x), "number expected")
	return x >= 0 and 1 or -1
end
lib_math.stretch = function(x, y, z, length)
	assert(isnum(x) and isnum(y) and isnum(z) and isnum(length), "vector (3d) and length expected")
	local cur_length = lib_math.distance(x, y, z)
	if cur_length == 0 then
		return 0, 0, 0
	else
		local factor = length / cur_length
		return x * factor, y * factor, z * factor
	end
end

-- Return library
return lib_math