-- Initalize library location
local lib_math = _G._YUTILS_GLOBAL and _G.math or {}

-- Load dependencies
local Ytype, Ytable = require("Yutils.type"), require("Yutils.table")

-- Shortcuts for optimization
local assert, isnum, sqrt, min, unpack, isnil, rad, sin, cos, istable, ipairs, deg, acos, atan2, random, ceil, floor, copy, default = _G.assert, Ytype.isnum, _G.math.sqrt, _G.math.min, _G.unpack or _G.table.unpack--[[Lua 5.2 change]], Ytype.isnil, _G.math.rad, _G.math.sin, _G.math.cos, Ytype.istable, _G.ipairs, _G.math.deg, _G.math.acos, _G.math.atan2, _G.math.random, _G.math.ceil, _G.math.floor, Ytable.copy, Ytype.default
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
lib_math.create_matrix = function(init_matrix)
	assert(isnil(init_matrix) or istable(init_matrix), "optional matrix table expected")
	local matrix, obj = {1, 0, 0, 0,
							0, 1, 0, 0,
							0, 0, 1, 0,
							0, 0, 0, 1}
	if init_matrix then
		assert(pcall(obj.set_data, init_matrix))
	end
	obj = {
		get_data = function()
			return copy(matrix)
		end,
		set_data = function(new_matrix)
			assert(istable(new_matrix), "matrix (table with 16 numbers) expected")
			for i=1, 16 do
				assert(isnum(new_matrix[i]), "matrix has to contain numbers only")
			end
			for i=1, 16 do
				matrix[i] = new_matrix[i]
			end
			return obj
		end,
		identity = function()
			matrix[1] = 1
			matrix[2] = 0
			matrix[3] = 0
			matrix[4] = 0
			matrix[5] = 0
			matrix[6] = 1
			matrix[7] = 0
			matrix[8] = 0
			matrix[9] = 0
			matrix[10] = 0
			matrix[11] = 1
			matrix[12] = 0
			matrix[13] = 0
			matrix[14] = 0
			matrix[15] = 0
			matrix[16] = 1
			return obj
		end,
		multiply = function(matrix2)
			assert(istable(matrix2), "matrix (table with 16 numbers) expected")
			for i=1, 16 do
				assert(isnum(matrix2[i]), "matrix has to contain numbers only")
			end
			-- Multipy matrices to create new one
			local new_matrix = {0, 0, 0, 0,
										0, 0, 0, 0,
										0, 0, 0, 0,
										0, 0, 0, 0}
			for i=1, 16 do
				for j=0, 3 do
					new_matrix[i] = new_matrix[i] + matrix[1 + (i-1) % 4 + j * 4] * matrix2[1 + floor((i-1) / 4) * 4 + j]
				end
			end
			matrix = new_matrix
			return obj
		end,
		translate = function(x, y, z)
			assert(isnum(x) and isnum(y) and isnum(z), "3 translation values expected")
			obj.multiply({1, 0, 0, 0,
							0, 1, 0, 0,
							0, 0, 1, 0,
							x, y, z, 1})
			return obj
		end,
		scale = function(x, y, z)
			assert(isnum(x) and isnum(y) and isnum(z), "3 scale factors expected")
			obj.multiply({x, 0, 0, 0,
							0, y, 0, 0,
							0, 0, z, 0,
							0, 0, 0, 1})
			return obj
		end,
		rotate = function(axis, angle)
			assert((axis == "x" or axis == "y" or axis == "z") and isnum(angle), "axis (as string) and angle (in degree) expected")
			angle = math.rad(angle)
			if axis == "x" then
				obj.multiply({1, 0, 0, 0,
							0, cos(angle), -sin(angle), 0,
							0, sin(angle), cos(angle), 0,
							0, 0, 0, 1})
			elseif axis == "y" then
				obj.multiply({cos(angle), 0, sin(angle), 0,
							0, 1, 0, 0,
							-sin(angle), 0, cos(angle), 0,
							0, 0, 0, 1})
			else	-- axis == "z"
				obj.multiply({cos(angle), -sin(angle), 0, 0,
							sin(angle), cos(angle), 0, 0,
							0, 0, 1, 0,
							0, 0, 0, 1})
			end
			return obj
		end,
		inverse = function()
			-- Create inversion matrix
			local inv_matrix = {
				matrix[6] * matrix[11] * matrix[16] - matrix[6] * matrix[15] * matrix[12] - matrix[7] * matrix[10] * matrix[16] + matrix[7] * matrix[14] * matrix[12] +matrix[8] * matrix[10] * matrix[15] - matrix[8] * matrix[14] * matrix[11],
				-matrix[2] * matrix[11] * matrix[16] + matrix[2] * matrix[15] * matrix[12] + matrix[3] * matrix[10] * matrix[16] - matrix[3] * matrix[14] * matrix[12] - matrix[4] * matrix[10] * matrix[15] + matrix[4] * matrix[14] * matrix[11],
				matrix[2] * matrix[7] * matrix[16] - matrix[2] * matrix[15] * matrix[8] - matrix[3] * matrix[6] * matrix[16] + matrix[3] * matrix[14] * matrix[8] + matrix[4] * matrix[6] * matrix[15] - matrix[4] * matrix[14] * matrix[7],
				-matrix[2] * matrix[7] * matrix[12] + matrix[2] * matrix[11] * matrix[8] +matrix[3] * matrix[6] * matrix[12] - matrix[3] * matrix[10] * matrix[8] - matrix[4] * matrix[6] * matrix[11] + matrix[4] * matrix[10] * matrix[7],
				-matrix[5] * matrix[11] * matrix[16] + matrix[5] * matrix[15] * matrix[12] + matrix[7] * matrix[9] * matrix[16] - matrix[7] * matrix[13] * matrix[12] - matrix[8] * matrix[9] * matrix[15] + matrix[8] * matrix[13] * matrix[11],
				matrix[1] * matrix[11] * matrix[16] - matrix[1] * matrix[15] * matrix[12] - matrix[3] * matrix[9] * matrix[16] + matrix[3] * matrix[13] * matrix[12] + matrix[4] * matrix[9] * matrix[15] - matrix[4] * matrix[13] * matrix[11],
				-matrix[1] * matrix[7] * matrix[16] + matrix[1] * matrix[15] * matrix[8] + matrix[3] * matrix[5] * matrix[16] - matrix[3] * matrix[13] * matrix[8] - matrix[4] * matrix[5] * matrix[15] + matrix[4] * matrix[13] * matrix[7],
				matrix[1] * matrix[7] * matrix[12] - matrix[1] * matrix[11] * matrix[8] - matrix[3] * matrix[5] * matrix[12] + matrix[3] * matrix[9] * matrix[8] + matrix[4] * matrix[5] * matrix[11] - matrix[4] * matrix[9] * matrix[7],
				matrix[5] * matrix[10] * matrix[16] - matrix[5] * matrix[14] * matrix[12] - matrix[6] * matrix[9] * matrix[16] + matrix[6] * matrix[13] * matrix[12] + matrix[8] * matrix[9] * matrix[14] - matrix[8] * matrix[13] * matrix[10],
				-matrix[1] * matrix[10] * matrix[16] + matrix[1] * matrix[14] * matrix[12] + matrix[2] * matrix[9] * matrix[16] - matrix[2] * matrix[13] * matrix[12] - matrix[4] * matrix[9] * matrix[14] + matrix[4] * matrix[13] * matrix[10],
				matrix[1] * matrix[6] * matrix[16] - matrix[1] * matrix[14] * matrix[8] - matrix[2] * matrix[5] * matrix[16] + matrix[2] * matrix[13] * matrix[8] + matrix[4] * matrix[5] * matrix[14] - matrix[4] * matrix[13] * matrix[6],
				-matrix[1] * matrix[6] * matrix[12] + matrix[1] * matrix[10] * matrix[8] + matrix[2] * matrix[5] * matrix[12] - matrix[2] * matrix[9] * matrix[8] - matrix[4] * matrix[5] * matrix[10] + matrix[4] * matrix[9] * matrix[6],
				-matrix[5] * matrix[10] * matrix[15] + matrix[5] * matrix[14] * matrix[11] + matrix[6] * matrix[9] * matrix[15] - matrix[6] * matrix[13] * matrix[11] - matrix[7] * matrix[9] * matrix[14] + matrix[7] * matrix[13] * matrix[10],
				matrix[1] * matrix[10] * matrix[15] - matrix[1] * matrix[14] * matrix[11] - matrix[2] * matrix[9] * matrix[15] + matrix[2] * matrix[13] * matrix[11] + matrix[3] * matrix[9] * matrix[14] - matrix[3] * matrix[13] * matrix[10],
				-matrix[1] * matrix[6] * matrix[15] + matrix[1] * matrix[14] * matrix[7] + matrix[2] * matrix[5] * matrix[15] - matrix[2] * matrix[13] * matrix[7] - matrix[3] * matrix[5] * matrix[14] + matrix[3] * matrix[13] * matrix[6],
				matrix[1] * matrix[6] * matrix[11] - matrix[1] * matrix[10] * matrix[7] - matrix[2] * matrix[5] * matrix[11] + matrix[2] * matrix[9] * matrix[7] + matrix[3] * matrix[5] * matrix[10] - matrix[3] * matrix[9] * matrix[6]
			}
			-- Calculate determinant
			local det = matrix[1] * inv_matrix[1] +
							matrix[5] * inv_matrix[2] +
							matrix[9] * inv_matrix[3] +
							matrix[13] * inv_matrix[4]
			-- Matrix inversion possible?
			if det ~= 0 then
				-- Invert matrix
				det = 1 / det
				for i=1, 16 do
					matrix[i] = inv_matrix[i] * det
				end
				-- Return this object
				return obj
			end
		end,
		transform = function(x, y, z, w)
			assert(isnum(x) and isnum(y) and isnum(z) and (isnil(w) or isnum(w)), "point (3 or 4 numbers) expected")
			w = default(w, 1)
			return x * matrix[1] + y * matrix[5] + z * matrix[9] + w * matrix[13],
					x * matrix[2] + y * matrix[6] + z * matrix[10] + w * matrix[14],
					x * matrix[3] + y * matrix[7] + z * matrix[11] + w * matrix[15],
					x * matrix[4] + y * matrix[8] + z * matrix[12] + w * matrix[16]
		end
	}
	return obj
end
lib_math.degree = function(x1, y1, z1, x2, y2, z2)
	assert(isnum(x1) and isnum(y1) and (isnil(z1) and isnil(x2) and isnil(y2) and isnil(z2) or isnum(z1) and isnum(x2) and isnum(y2) and isnum(z2)), "1 vector (2 numbers) or 2 vectors (each 3 numbers) expected")
	if z1 then
		local degree = deg(
				acos(
					(x1 * x2 + y1 * y2 + z1 * z2) /
					(lib_math.distance(x1, y1, z1) * lib_math.distance(x2, y2, z2))
				)
		)
		return (x1*y2 - y1*x2) < 0--[[sign by clockwise direction]] and -degree or degree
	else
		return deg(atan2(x1, y1))
	end
end
lib_math.distance = function(x, y, z)
	assert(isnum(x) and isnum(y) and (isnil(z) or isnum(z)), "one vector (2 or 3 numbers) expected")
	return z and sqrt(x*x + y*y + z*z) or sqrt(x*x + y*y)
end
lib_math.fac = function(n)
	assert(isint(n) and n > 0, "positive integer expected")
	local k = 1
	for i=2, n do
		k = k * i
	end
	return k
end
lib_math.interpolate = function(pct, a, b)
	assert(isnum(pct) and isnum(a) and isnum(b), "percent and 2 further numbers expected")
	return a + (b - a) * pct
end
lib_math.intersect = function(x0, y0, x1, y1, x2, y2, x3, y3, strict)
	assert(isnum(x0) and isnum(y0) and isnum(x1) and isnum(y1) and
			isnum(x2) and isnum(y2) and isnum(x3) and isnum(y3) and
			(isnil(strict) or isbool(strict)), "two lines and optional strictness flag expected")
	-- Get line vectors & check valid lengths
	local x10, y10, x32, y32 = x0 - x1, y0 - y1, x2 - x3, y2 - y3
	assert((x10 ~= 0 or y10 ~= 0) and (x32 ~= 0 or y32 =~ 0), "lines mustn't have zero length")
	-- Calculate determinant and check for parallel lines
	local det = x10 * y32 - y10 * x32
	if det ~= 0 then
		-- Calculate line intersection (endless line lengths)
		local pre, post = (x0 * y1 - y0 * x1), (x2 * y3 - y2 * x3)
		local ix, iy = (pre * x32 - x10 * post) / det, (pre * y32 - y10 * post) / det
		-- Check for line intersection with given line lengths
		if strict then
			local s, t = x10 ~= 0 and (ix - x1) / x10 or (iy - y1) / y10, x32 ~= 0 and (ix - x3) / x32 or (iy - y3) / y32
			if s < 0 or s > 1 or t < 0 or t > 1 then
				return 1/0	-- inf
			end
		end
		-- Return intersection point
		return ix, iy
	end
end
lib_math.ortho = function(x1, y1, z1, x2, y2, z2)
	assert(isnum(x1) and isnum(y1) and isnum(z1) and isnum(x2) and isnum(y2) and isnum(z3), "2 vectors (as 6 numbers) expected")
	return y1 * z2 - z1 * y2,
		z1 * x2 - x1 * z2,
		x1 * y2 - y1 * x2
end
lib_math.randomsteps = function(min_val, max_val, step)
	assert(isnum(min_val) and isnum(max_val) and isnum(step) and max_val >= min_val and step > 0, "minimal, maximal and step number expected")
	return min(min_val + random(0, ceil((max_val - min_val) / step)) * step, max_val)
end
lib_math.rotate = function(x, y, angle)
	assert(isnum(x) and isnum(y) and isnum(angle), "x & y coordinate and angle expected")
	local ra = rad(angle)
	return cos(ra)*x - sin(ra)*y,
		sin(ra)*x + cos(ra)*y
end
lib_math.round = function(x, dec)
	assert(isnum(x) and (isnil(dec) or isnum(dec)), "number and optional number expected")
	if dec and dec >= 1 then
		dec = 10^floor(dec)
		return floor(x * dec + 0.5) / dec
	else
		return floor(x + 0.5)
	end
end
lib_math.sign = function(x)
	assert(isnum(x), "number expected")
	return x >= 0 and 1 or -1
end
lib_math.stretch = function(x, y, z, length)
	assert(isnum(x) and isnum(y) and isnum(z) and isnum(length), "vector (3 numbers) and length expected")
	-- Get current vector length
	local cur_length = lib_math.distance(x, y, z)
	-- Scale vector to new length
	if cur_length == 0 then
		return 0, 0, 0
	else
		local factor = length / cur_length
		return x * factor, y * factor, z * factor
	end
end
lib_math.trim = function(x, min_val, max_val)
	assert(isnum(x) and isnum(min_val) and isnum(max_val), "3 numbers expected")
	return x < min and min or x > max and max or x
end

-- Return library
return lib_math