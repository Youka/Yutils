--[[
	Copyright (c) 2014, Christoph "Youka" Spanknebel
	All rights reserved.
	
	Version: 26th June 2014, 19:15 (GMT+1)
	
	Yutils
		table
			copy(t) -> table
			tostring(t) -> string
		utf8
			charrange(s, i) -> number
			chars(s) -> function
			len(s) -> number
		math
			bezier(pct, pts) -> number, number, number
			create_matrix() -> table
				get_data() -> table
				set_data(matrix)
				identity()
				multiply(matrix2)
				translate(x, y, z)
				scale(x, y, z)
				rotate(axis, angle)
				transform(x, y, z, w) -> number, number, number, number
			distance(x, y, z) -> number
			degree(x1, y1, z1, x2, y2, z2) -> number
			ortho(x1, y1, z1, x2, y2, z2) -> number, number, number
			randomsteps(min, max, step) -> number
			round(x) -> number
		algorithm
			frames(starts, ends, dur) -> function
		shape
			bounding(shape) -> number, number, number, number
			filter(shape, filter) -> string
			flatten(shape) -> string
			move(shape, x, y) -> string
			split(shape, max_len) -> string
			to_outline(shape, width) -> string
			to_pixels(shape) -> table
		decode
			create_bmp_reader(filename) -> table
				get_file_size() -> number
				get_width() -> number
				get_height() -> number
				get_data_size() -> number
				get_row_size() -> number
				get_data_raw() -> string
				get_data_packed() -> table
				get_data_text() -> string
			create_font(font, bold, italic, underline, strikeout, size) -> table
				metrics() -> table
				text_extents(text) -> table
				text_to_shape(text) -> string
]]

-- Load FFI interface
local ffi = require("ffi")
-- Check OS
if ffi.os ~= "Windows" then
	error("just windows supported", 1)
end
-- Set C definitions
ffi.cdef([[
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef unsigned short WORD;
typedef const char* LPCSTR;
typedef wchar_t* LPWSTR;
typedef void* HANDLE;
typedef HANDLE HDC;
typedef int BOOL;
typedef unsigned int size_t;
typedef HANDLE HFONT;
typedef const wchar_t* LPCWSTR;
typedef HANDLE HGDIOBJ;
typedef long LONG;
typedef wchar_t WCHAR;
typedef unsigned char BYTE;
typedef struct{
	LONG tmHeight;
	LONG tmAscent;
	LONG tmDescent;
	LONG tmInternalLeading;
	LONG tmExternalLeading;
	LONG tmAveCharWidth;
	LONG tmMaxCharWidth;
	LONG tmWeight;
	LONG tmOverhang;
	LONG tmDigitizedAspectX;
	LONG tmDigitizedAspectY;
	WCHAR tmFirstChar;
	WCHAR tmLastChar;
	WCHAR tmDefaultChar;
	WCHAR tmBreakChar;
	BYTE tmItalic;
	BYTE tmUnderlined;
	BYTE tmStruckOut;
	BYTE tmPitchAndFamily;
	BYTE tmCharSet;
}TEXTMETRICW, *LPTEXTMETRICW;
typedef struct{
	LONG cx;
	LONG cy;
}SIZE, *LPSIZE;
typedef struct{
	LONG left;
	LONG top;
	LONG right;
	LONG bottom;
}RECT;
typedef const RECT* LPCRECT;
typedef int INT;
typedef struct{
	LONG x;
	LONG y;
}POINT, *LPPOINT;
typedef BYTE* PBYTE;
typedef HANDLE HBITMAP;
typedef struct{
	DWORD biSize;
	LONG biWidth;
	LONG biHeight;
	WORD biPlanes;
	WORD biBitCount;
	DWORD biCompression;
	DWORD biSizeImage;
	LONG biXPelsPerMeter;
	LONG biYPelsPerMeter;
	DWORD biClrUsed;
	DWORD biClrImportant;
}BITMAPINFOHEADER;
typedef struct{
	BYTE rgbBlue;
	BYTE rgbGreen;
	BYTE rgbRed;
	BYTE rgbReserved;
} RGBQUAD;
typedef struct{
	BITMAPINFOHEADER bmiHeader;
	RGBQUAD* bmiColors;
}BITMAPINFO;

int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
HDC CreateCompatibleDC(HDC);
BOOL DeleteDC(HDC);
int SetMapMode(HDC, int);
int SetBkMode(HDC, int);
int SetPolyFillMode(HDC, int);
size_t wcslen(const wchar_t*);
HFONT CreateFontW(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
HGDIOBJ SelectObject(HDC, HGDIOBJ);
BOOL DeleteObject(HGDIOBJ);
BOOL GetTextMetricsW(HDC, LPTEXTMETRICW);
BOOL GetTextExtentPoint32W(HDC, LPCWSTR, int, LPSIZE);
BOOL BeginPath(HDC);
BOOL ExtTextOutW(HDC, int, int, UINT, LPCRECT, LPCWSTR, UINT, const INT*);
BOOL PolyDraw(HDC, const POINT*, const BYTE*, int);
BOOL EndPath(HDC);
int GetPath(HDC, LPPOINT, PBYTE, int);
BOOL AbortPath(HDC);
BOOL FillPath(HDC);
BOOL GdiFlush();
HBITMAP CreateDIBSection(HDC, const BITMAPINFO*, UINT, void**, HANDLE, int);
]])

-- Create library table
local Yutils
Yutils = {
	-- Table sublibrary
	table = {
		-- Copy table deep
		copy = function(t)
			-- Check arguments
			if type(t) ~= "table" then
				error("table expected", 2)
			end
			-- Copy & return
			local function copy_recursive(old_t)
				local new_t = {}
				for key, value in pairs(old_t) do
					new_t[key] = type(value) == "table" and copy_recursive(value) or value
				end
				return new_t
			end
			return copy_recursive(t)
		end,
		-- Convert table to string
		tostring = function(t)
			-- Check arguments
			if type(t) ~= "table" then
				error("table expected", 2)
			end
			-- Result storage
			local result, result_n = {}, 0
			-- Convert to string!
			local function convert_recursive(t, space)
				for key, value in pairs(t) do
					if type(key) == "string" then
						key = string.format("%q", key)
					end
					if type(value) == "string" then
						value = string.format("%q", value)
					end
					result_n = result_n + 1
					result[result_n] = string.format("%s[%s] = %s", space, tostring(key), tostring(value))
					if type(value) == "table" then
						convert_recursive(value, space .. "\t")
					end
				end
			end
			convert_recursive(t, "")
			-- Return result as string
			return table.concat(result, "\n")
		end
	},
	-- UTF8 sublibrary
	utf8 = {
--[[
		UTF16 -> UTF8
		--------------
		U-00000000 - U-0000007F:		0xxxxxxx
		U-00000080 - U-000007FF:		110xxxxx 10xxxxxx
		U-00000800 - U-0000FFFF:		1110xxxx 10xxxxxx 10xxxxxx
		U-00010000 - U-001FFFFF:		11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
		U-00200000 - U-03FFFFFF:		111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
		U-04000000 - U-7FFFFFFF:		1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
]]
		-- UTF8 character range at string codepoint
		charrange = function(s, i)
			-- Check arguments
			if type(s) ~= "string" or type(i) ~= "number" or i < 1 or i > #s then
				error("string and string index expected", 2)
			end
			-- Evaluate codepoint to range
			local byte = s:byte(i)
			return not byte and 0 or
					byte < 192 and 1 or
					byte < 224 and 2 or
					byte < 240 and 3 or
					byte < 248 and 4 or
					byte < 252 and 5 or
					6
		end,
		-- Creates iterator through UTF8 characters
		chars = function(s)
			-- Check argument
			if type(s) ~= "string" then
				error("string expected", 2)
			end
			-- Return utf8 characters iterator
			local char_i, s_pos = 0, 1
			return function()
				if s_pos > #s then
					return
				else
					char_i = char_i + 1
					local cur_pos = s_pos
					s_pos = s_pos + Yutils.utf8.charrange(s, s_pos)
					return char_i, s:sub(cur_pos, s_pos-1)
				end
			end
		end,
		-- Get UTF8 characters number in string
		len = function(s)
			-- Check argument
			if type(s) ~= "string" then
				error("string expected", 2)
			end
			-- Count UTF8 characters
			local n = 0
			for _ in Yutils.utf8.chars(s) do
				n = n + 1
			end
			return n
		end
	},
	-- Math sublibrary
	math = {
		-- Get points on n-degree bezier curve
		bezier = function(pct, pts)
			-- Check arguments
			if type(pct) ~= "number" or type(pts) ~= "table" or pct < 0 or pct > 1 then
				error("percent number and points table expected", 2)
			end
			for _, value in ipairs(pts) do
				if type(value[1]) ~= "number" or type(value[2]) ~= "number" or (value[3] ~= nil and type(value[3]) ~= "number") then
					error("points have to be tables with 2 or 3 numbers", 2)
				end
			end
			--Factorial
			local function fac(n)
				local k = 1
				if n > 1 then
					for i=2, n do
						k = k * i
					end
				end
				return k
			end
			--Binomial coefficient
			local function bin(i, n)
				return fac(n) / (fac(i) * fac(n-i))
			end
			--Bernstein polynom
			local function bernstein(pct, i, n)
				return bin(i, n) * pct^i * (1 - pct)^(n - i)
			end
			--Calculate coordinate
			local ret_x, ret_y, ret_z = 0, 0, 0
			local n, bern, pt = #pts - 1
			for i=0, n do
				bern = bernstein(pct, i, n)
				pt = pts[i+1]
				ret_x = ret_x + pt[1] * bern
				ret_y = ret_y + pt[2] * bern
				ret_z = ret_z + (pt[3] or 0) * bern
			end
			return ret_x, ret_y, ret_z
		end,
		-- Create 3d matrix
		create_matrix = function()
			-- Matrix data
			local matrix = {1, 0, 0, 0,
								0, 1, 0, 0,
								0, 0, 1, 0,
								0, 0, 0, 1}
			-- Matrix object
			local obj = {
				-- Get matrix data
				get_data = function()
					return Yutils.table.copy(matrix)
				end,
				-- Set matrix data
				set_data = function(new_matrix)
					-- Check arguments
					if type(new_matrix) ~= "table" or #new_matrix ~= 16 then
						error("4x4 matrix expected", 2)
					end
					for _, value in ipairs(new_matrix) do
						if type(value) ~= "number" then
							error("matrix must contain only numbers", 2)
						end
					end
					-- Replace old matrix
					matrix = Yutils.table.copy(new_matrix)
				end,
				-- Set matrix to identity
				identity = function()
					matrix = {1, 0, 0, 0,
								0, 1, 0, 0,
								0, 0, 1, 0,
								0, 0, 0, 1}
				end,
				-- Multiply matrix with given one
				multiply = function(matrix2)
					-- Check arguments
					if type(matrix2) ~= "table" or #matrix2 ~= 16 then
						error("4x4 matrix expected", 2)
					end
					for _, value in ipairs(matrix2) do
						if type(value) ~= "number" then
							error("matrix must contain only numbers", 2)
						end
					end
					-- Multipy matrices to create new one
					local new_matrix = {0, 0, 0, 0,
												0, 0, 0, 0,
												0, 0, 0, 0,
												0, 0, 0, 0}
					for i=1, 16 do
						for j=0, 3 do
							new_matrix[i] = new_matrix[i] + matrix[1 + (i-1) % 4 + j * 4] * matrix2[1 + math.floor((i-1) / 4) * 4 + j]
						end
					end
					-- Replace old matrix with multiply result
					matrix = new_matrix
				end,
				-- Apply matrix to point 
				transform = function(x, y, z, w)
					-- Check arguments
					if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or (w ~= nil and type(w) ~= "number") then
						error("point (3 or 4 numbers) expected", 2)
					end
					-- Set 4th coordinate
					if not w then
						w = 1
					end
					-- Calculate new point
					return x * matrix[1] + y * matrix[5] + z * matrix[9] + w * matrix[13],
							x * matrix[2] + y * matrix[6] + z * matrix[10] + w * matrix[14],
							x * matrix[3] + y * matrix[7] + z * matrix[11] + w * matrix[15],
							x * matrix[4] + y * matrix[8] + z * matrix[12] + w * matrix[16]
				end
			}
			-- Apply translation to matrix
			obj.translate = function(x, y, z)
				-- Check arguments
				if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
					error("3 translation values expected", 2)
				end
				-- Add translation to matrix
				obj.multiply({1, 0, 0, 0,
								0, 1, 0, 0,
								0, 0, 1, 0,
								x, y, z, 1})
			end
			-- Apply scale to matrix
			obj.scale = function(x, y, z)
				-- Check arguments
				if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
					error("3 scale factors expected", 2)
				end
				-- Add scale to matrix
				obj.multiply({x, 0, 0, 0,
								0, y, 0, 0,
								0, 0, z, 0,
								0, 0, 0, 1})
			end
			-- Applay rotation to matrix
			obj.rotate = function(axis, angle)
				-- Check arguments
				if (axis ~= "x" and axis ~= "y" and axis ~= "z") or type(angle) ~= "number" then
					error("axis (as string) and angle (in degree) expected", 2)
				end
				-- Convert angle from degree to radian
				angle = math.rad(angle)
				-- Rotate by axis
				if axis == "x" then
					obj.multiply({1, 0, 0, 0,
								0, math.cos(angle), -math.sin(angle), 0,
								0, math.sin(angle), math.cos(angle), 0,
								0, 0, 0, 1})
				elseif axis == "y" then
					obj.multiply({math.cos(angle), 0, math.sin(angle), 0,
								0, 1, 0, 0,
								-math.sin(angle), 0, math.cos(angle), 0,
								0, 0, 0, 1})
				else	-- axis == "z"
					obj.multiply({math.cos(angle), -math.sin(angle), 0, 0,
								math.sin(angle), math.cos(angle), 0, 0,
								0, 0, 1, 0,
								0, 0, 0, 1})
				end
			end
			return obj
		end,
		-- Length of vector
		distance = function(x, y, z)
			-- Check arguments
			if type(x) ~= "number" or type(y) ~= "number" or (z ~= nil and type(z) ~= "number") then
				error("one vector (2 or 3 numbers) expected", 2)
			end
			-- Calculate length
			return z and math.sqrt(x*x + y*y + z*z) or math.sqrt(x*x + y*y)
		end,
		-- Degree between two 3d vectors
		degree = function(x1, y1, z1, x2, y2, z2)
			-- Check arguments
			if type(x1) ~= "number" or type(y1) ~= "number" or type(z1) ~= "number" or
				type(x2) ~= "number" or type(y2) ~= "number" or type(z2) ~= "number" then
				error("2 vectors (as 6 numbers) expected", 2)
			end
			-- Calculate degree
			local degree = math.deg(
					math.acos(
						(x1 * x2 + y1 * y2 + z1 * z2) /
						(Yutils.math.distance(x1, y1, z1) * Yutils.math.distance(x2, y2, z2))
					)
			)
			-- Return with sign by clockwise direction
			return (x1*y2 - y1*x2) < 0 and -degree or degree
		end,
		-- Get orthogonal vector of 2 given vectors
		ortho = function(x1, y1, z1, x2, y2, z2)
			-- Check arguments
			if type(x1) ~= "number" or type(y1) ~= "number" or type(z1) ~= "number" or
				type(x2) ~= "number" or type(y2) ~= "number" or type(z2) ~= "number" then
				error("2 vectors (as 6 numbers) expected", 2)
			end
			-- Calculate orthogonal
			return y1 * z2 - z1 * y2,
				z1 * x2 - x1 * z2,
				x1 * y2 - y1 * x2
		end,
		-- Generates a random number in given range with specific distance to others
		randomsteps = function(min, max, step)
			-- Check arguments
			if type(min) ~= "number" or type(max) ~= "number" or type(step) ~= "number" or max < min or step <= 0 then
				error("minimal, maximal and step number expected", 2)
			end
			-- Generate random number
			local r = min + math.random(0, math.ceil((max - min) / step)) * step
			return r > max and max or r
		end,
		-- Round number
		round = function(x)
			-- Check argument
			if type(x) ~= "number" then
				error("number expected", 2)
			end
			-- Return number rounded to nearest integer
			return math.floor(x + 0.5)
		end
	},
	-- Algorithm sublibrary
	algorithm = {
		-- Creates iterator through frames
		frames = function(starts, ends, dur)
			-- Check arguments
			if type(starts) ~= "number" or type(ends) ~= "number" or type(dur) ~= "number" or dur == 0 then
				error("start, end and duration number expected", 2)
			end
			-- Iteration state
			local i, n = 0, math.ceil((ends - starts) / dur)
			-- Return iterator
			return function()
				i = i + 1
				if i > n then
					return
				else
					local ret_starts = starts + (i-1) * dur
					local ret_ends = ret_starts + dur
					if dur < 0 and ret_ends < ends then
						ret_ends = ends
					elseif dur > 0 and ret_ends > ends then
						ret_ends = ends
					end
					return ret_starts, ret_ends, i, n
				end
			end
		end
	},
	-- Shape sublibrary
	shape = {
		-- Calculate shape bounding box
		bounding = function(shape)
			-- Check argument
			if type(shape) ~= "string" then
				error("shape expected", 2)
			end
			-- Bounding data
			local x1, y1, x2, y2
			-- Calculate minimal and maximal coordinates
			for cx, cy in shape:gmatch("(%-?%d+)%s+(%-?%d+)") do
				cx, cy = tonumber(cx), tonumber(cy)
				x1 = x1 and math.min(x1, cx) or cx
				y1 = y1 and math.min(y1, cy) or cy
				x2 = x2 and math.max(x2, cx) or cx
				y2 = y2 and math.max(y2, cy) or cy
			end
			return x1, y1, x2, y2
		end,
		-- Filter shape coordinates
		filter = function(shape, filter)
			-- Check arguments
			if type(shape) ~= "string" or type(filter) ~= "function" then
				error("shape and filter function expected", 2)
			end
			-- Filter!
			local new_shape = shape:gsub("(%-?%d+)%s+(%-?%d+)", function(cx, cy)
				local new_cx, new_cy = filter(tonumber(cx), tonumber(cy))
				if type(new_cx) == "number" and type(new_cy) == "number" then
					return string.format("%d %d", new_cx, new_cy)
				end
			end)
			return new_shape
		end,
		-- Convert shape curves to lines
		flatten = function(shape)
			-- Check argument
			if type(shape) ~= "string" then
				error("shape expected", 2)
			end
			-- 4th degree curve subdivider
			local function curve4_subdivide(x0, y0, x1, y1, x2, y2, x3, y3, pct)
				-- Calculate points on curve vectors
				local x01, y01, x12, y12, x23, y23 = (x0+x1)*pct, (y0+y1)*pct, (x1+x2)*pct, (y1+y2)*pct, (x2+x3)*pct, (y2+y3)*pct
				local x012, y012, x123, y123 = (x01+x12)*pct, (y01+y12)*pct, (x12+x23)*pct, (y12+y23)*pct
				local x0123, y0123 = (x012+x123)*pct, (y012+y123)*pct
				-- Return new 2 curves
				return x0, y0, x01, y01, x012, y012, x0123, y0123,
						x0123, y0123, x123, y123, x23, y23, x3, y3
			end
			-- Check flatness of 4th degree curve with angles
			local function curve4_is_flat(x0, y0, x1, y1, x2, y2, x3, y3, tolerance)
				-- Pack curve vectors
				local vecs = {{x1 - x0, y1 - y0}, {x2 - x1, y2 - y1}, {x3 - x2, y3 - y2}}
				-- Remove zero length vectors
				local i = 1
				while i <= #vecs do
					if vecs[i][1] == 0 and vecs[i][2] == 0 then
						table.remove(vecs, i)
					else
						i = i + 1
					end
				end
				-- Check flatness on remaining vectors
				if #vecs < 2 then
					return true
				else
					for i=1, #vecs-1 do
						if math.abs(Yutils.math.degree(vecs[i][1], vecs[i][2], 0, vecs[i+1][1], vecs[i+1][2], 0)) > tolerance then
							return false
						end
					end
					return true
				end
			end
			-- Convert 4th degree curve to line points
			local function curve4_to_lines(x0, y0, x1, y1, x2, y2, x3, y3)
				-- Line points buffer
				local pts, pts_n = {x0, y0}, 2
				-- Conversion in recursive processing
				local function convert_recursive(x0, y0, x1, y1, x2, y2, x3, y3)
					if curve4_is_flat(x0, y0, x1, y1, x2, y2, x3, y3, 1) then
						pts[pts_n+1] = x3
						pts[pts_n+2] = y3
						pts_n = pts_n + 2
					else
						local x10, y10, x11, y11, x12, y12, x13, y13, x20, y20, x21, y21, x22, y22, x23, y23 = curve4_subdivide(x0, y0, x1, y1, x2, y2, x3, y3, 0.5)
						convert_recursive(x10, y10, x11, y11, x12, y12, x13, y13)
						convert_recursive(x20, y20, x21, y21, x22, y22, x23, y23)
					end
				end
				convert_recursive(x0, y0, x1, y1, x2, y2, x3, y3)
				-- Return resulting points
				return pts
			end
			-- Search for curves
			local search_pos = 1
			while true do
				-- Did find a curve chain beginning?
				local curves_start, curves_end, x0, y0 = shape:find("(%-?%d+)%s+(%-?%d+)%s+b%s+", search_pos)
				-- No curves
				if not curves_start then
					-- End curves search
					break
				-- Curve(s) found!
				else
					-- Find end of curves chain
					local curves_end = shape:find("[^%-%d%s]", curves_end)
					if not curves_end then
						curves_end = #shape
					end
					-- Get curves string
					local curves_text = shape:sub(curves_start, curves_end)
					-- Convert curves to lines
					curves_text = curves_text:gsub("b", "l", 1)
					local last_x, last_y = x0, y0
					curves_text = curves_text:gsub("(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)", function(x1, y1, x2, y2, x3, y3)
						local line_points = curve4_to_lines(last_x, last_y, x1, y1, x2, y2, x3, y3)
						for i=1, #line_points do
							line_points[i] = Yutils.math.round(tonumber(line_points[i]))
						end
						last_x, last_y = x3, y3
						return table.concat(line_points, " ")
					end)
					-- Replace old curves in shape with new lines
					shape = string.format("%s%s%s", shape:sub(1,curves_start-1), curves_text, shape:sub(curves_end+1))
					-- Set start for next iteration behind the current found
					search_pos = curves_end + 1
				end
			end
			-- Return shape without curves
			return shape
		end,
		-- Shift shape coordinates
		move = function(shape, x, y)
			-- Check arguments
			if type(shape) ~= "string" or type(x) ~= "number" or type(y) ~= "number" then
				error("shape, horizontal shift and vertical shift expected", 2)
			end
			-- Shift!
			return Yutils.shape.filter(shape, function(cx, cy)
				return cx + x, cy + y
			end)
		end,
		-- Split shape lines into shorter segments
		split = function(shape, max_len)
			-- Check arguments
			if type(shape) ~= "string" or type(max_len) ~= "number" or max_len <= 0 then
				error("shape and maximal line length expected", 2)
			end
			-- Split shape long lines to short ones
			local line_mode, last_point = false
			shape = shape:gsub("(%a?)(%s*)(%-?%d+)%s+(%-?%d+)", function(typ, space, x, y)
				-- En-/disable line mode
				if typ ~= "" then
					line_mode = typ == "l"
				end
				-- Lines buffer
				local lines
				-- Line with previous point?
				if line_mode and last_point then
					-- Line direction & length
					local rel_x, rel_y = x - last_point[1], y - last_point[2]
					local distance = Yutils.math.distance(rel_x, rel_y)
					-- Line too long -> split!
					if distance > max_len then
						-- Generate line segments
						lines = {typ .. space}
						local lines_n, distance_rest, pct = 1, distance % max_len
						for cur_distance = distance_rest > 0 and distance_rest or max_len, distance, max_len do
							pct = cur_distance / distance
							lines_n = lines_n + 1
							lines[lines_n] = string.format("%d %d ", last_point[1] + rel_x * pct, last_point[2] + rel_y * pct)
						end
						lines = table.concat(lines):sub(1,-2)
					-- No line split
					else
						lines = string.format("%s%s%d %d", typ, space, x, y)
					end
				-- No line split
				else
					lines = string.format("%s%s%d %d", typ, space, x, y)
				end
				-- Update last point
				last_point = {x, y}
				-- Return new lines
				return lines
			end)
			return shape
		end,
		-- Convert shape to stroke version
		to_outline = function(shape, width)
			-- Check arguments
			if type(shape) ~= "string" or type(width) ~= "number" or width <= 0 then
				error("shape and line width expected", 2)
			end
			-- Collect figures
			local figures, figures_n = {}, 0
			local figure, figure_n = {}, 0
			for typ, x, y in shape:gmatch("(%a?)%s*(%-?%d+)%s+(%-?%d+)") do
				-- Check point type
				if typ ~= "m" and typ ~= "l" and typ ~= "" then
					error("shape have to contain only \"moves\" and \"lines\"", 2)
				end
				-- Last figure finished?
				if typ == "m" and figure_n ~= 0 then
					-- Enough figure points?
					if figure_n < 3 then
						error("every figure must have more than 2 points", 2)
					end
					-- Save figure
					figures_n = figures_n + 1
					figures[figures_n] = figure
					figure = {}
					figure_n = 0
				end
				-- Add point to current figure
				figure_n = figure_n + 1
				figure[figure_n] = {x, y}
			end
			-- Insert last figure
			if figure_n ~= 0 then
				-- Enough figure points?
				if figure_n < 3 then
					error("every figure must have more than 2 points", 2)
				end
				-- Save figure
				figures_n = figures_n + 1
				figures[figures_n] = figure
				figure = {}
				figure_n = 0
			end
			-- Remove double points (recreate figures)
			for fi = 1, figures_n do
				local old_figure, old_figure_n = figures[fi], #figures[fi]
				local new_figure, new_figure_n = {}, 0
				for pi, point in ipairs(old_figure) do
					local pre_point
					if pi == 1 then
						pre_point = old_figure[old_figure_n]
					else
						pre_point = old_figure[pi-1]
					end
					if not (point[1] == pre_point[1] and point[2] == pre_point[2]) then
						new_figure_n = new_figure_n + 1
						new_figure[new_figure_n] = point
					end
				end
				figures[fi] = new_figure
			end
			-- Vector sizer
			local function vec_sizer(x, y, size)
				local len = Yutils.math.distance(x, y)
				if len == 0 then
					return 0, 0
				else
					return x / len * size, y / len * size
				end
			end
			-- Point rotater
			local function rotate(x, y, angle)
				local ra = math.rad(angle)
				return math.cos(ra)*x - math.sin(ra)*y,
						math.sin(ra)*x + math.cos(ra)*y
			end
			-- Stroke figures
			local stroke_figures = {{}, {}}	-- inner + outer
			local stroke_subfigures_i = 0
			-- Through figures
			for fi, figure in ipairs(figures) do
				stroke_subfigures_i = stroke_subfigures_i + 1
				-- One pass for inner, one for outer outline
				for i = 1, 2 do
					-- Outline buffer
					local outline, outline_n = {}, 0
					-- Point iteration order = inner or outer outline
					local loop_begin, loop_end, loop_steps
					if i == 1 then
						loop_begin, loop_end, loop_step = #figure, 1, -1
					else
						loop_begin, loop_end, loop_step = 1, #figure, 1
					end
					-- Iterate through figure points
					for pi = loop_begin, loop_end, loop_step do
						-- Collect current, previous and next point
						local point = figure[pi]
						local pre_point, post_point
						if i == 1 then
							if pi == 1 then
								pre_point = figure[pi+1]
								post_point = figure[#figure]
							elseif pi == #figure then
								pre_point = figure[1]
								post_point = figure[pi-1]
							else
								pre_point = figure[pi+1]
								post_point = figure[pi-1]
							end
						else
							if pi == 1 then
								pre_point = figure[#figure]
								post_point = figure[pi+1]
							elseif pi == #figure then
								pre_point = figure[pi-1]
								post_point = figure[1]
							else
								pre_point = figure[pi-1]
								post_point = figure[pi+1]
							end
						end
						-- Calculate orthogonal vectors to both neighbour points
						local o_vec1_x, o_vec1_y = Yutils.math.ortho(point[1]-pre_point[1], point[2]-pre_point[2], 0, 0, 0, 1)
						o_vec1_x, o_vec1_y = vec_sizer(o_vec1_x, o_vec1_y, width)
						local o_vec2_x, o_vec2_y = Yutils.math.ortho(post_point[1]-point[1], post_point[2]-point[2], 0, 0, 0, 1)
						o_vec2_x, o_vec2_y = vec_sizer(o_vec2_x, o_vec2_y, width)
						-- Calculate degree & circumference between orthogonal vectors
						local degree = Yutils.math.degree(o_vec1_x, o_vec1_y, 0, o_vec2_x, o_vec2_y, 0)
						local circ = math.abs(math.rad(degree)) * width
						-- Add first edge point
						outline_n = outline_n + 1
						outline[outline_n] = {Yutils.math.round(point[1] + o_vec1_x), Yutils.math.round(point[2] + o_vec1_y)}
						-- Round edge needed?
						local max_circ = 2
						if circ > max_circ then
							local circ_rest = circ % max_circ
							for cur_circ = circ_rest > 0 and circ_rest or max_circ, circ, max_circ do
								local curve_vec_x, curve_vec_y = rotate(o_vec1_x, o_vec1_y, cur_circ / circ * degree)
								outline_n = outline_n + 1
								outline[outline_n] = {Yutils.math.round(point[1] + curve_vec_x), Yutils.math.round(point[2] + curve_vec_y)}
							end
						end
					end
					-- Insert inner or outer outline
					stroke_figures[i][stroke_subfigures_i] = outline
				end
			end
			-- Convert stroke figures to shape
			local stroke_shape, stroke_shape_n = {}, 0
			for fi = 1, figures_n do
				-- Closed inner outline to shape
				local inner_outline = stroke_figures[1][fi]
				for pi, point in ipairs(inner_outline) do
					stroke_shape_n = stroke_shape_n + 1
					stroke_shape[stroke_shape_n] = string.format("%s%d %d", pi == 1 and "m " or pi == 2 and "l " or "", point[1], point[2])
				end
				stroke_shape_n = stroke_shape_n + 1
				stroke_shape[stroke_shape_n] = string.format("%d %d", inner_outline[1][1], inner_outline[1][2])
				-- Closed outer outline to shape
				local outer_outline = stroke_figures[2][fi]
				for pi, point in ipairs(outer_outline) do
					stroke_shape_n = stroke_shape_n + 1
					stroke_shape[stroke_shape_n] = string.format("%s%d %d", pi == 1 and "m " or pi == 2 and "l " or "", point[1], point[2])
				end
				stroke_shape_n = stroke_shape_n + 1
				stroke_shape[stroke_shape_n] = string.format("%d %d", outer_outline[1][1], outer_outline[1][2])
			end
			return table.concat(stroke_shape, " ")
		end,
		-- Convert shape to pixels
		to_pixels = function(shape)
			-- Check argument
			if type(shape) ~= "string" then
				error("shape expected", 2)
			end
			-- Scale values for later anti-aliasing
			local upscale = 8
			local downscale = 1 / upscale
			-- Get shape size
			local x1, y1, x2, y2 = Yutils.shape.bounding(shape)
			if not y2 then
				error("not enough shape points", 2)
			elseif (x2-x1)%upscale ~= 0 or (y2-y1)%upscale ~= 0 then
				error("shape size must be a multiple of " .. upscale, 2)
			end
			-- Bring shape near origin in positive room
			local shift_x, shift_y = -(x1 - x1 % upscale), -(y1 - y1 % upscale)
			shape = Yutils.shape.move(shape, shift_x, shift_y)
			-- Convert shape to tables (with C types: 6 = PT_MOVETO, 2 = PT_LINETO, 4 = PT_BEZIERTO)
			local types, points, points_n = {}, {}, 0
			local cur_type, cur_x = 6
			for token in shape:gmatch("([^%s]+)") do
				if token == "m" then
					cur_type = 6
				elseif token == "l" then
					cur_type = 2
				elseif token == "b" then
					cur_type = 4
				else
					token = tonumber(token)
					if token then
						if not cur_x then
							cur_x = token
						else
							points_n = points_n + 1
							types[points_n] = cur_type
							points[points_n] = {cur_x, token}
							cur_x = nil
						end
					end
				end
			end
			-- Convert shape tables to C data for context compatibility
			local ctypes, cpoints = ffi.new("BYTE[?]", points_n), ffi.new("POINT[?]", points_n)
			for i=1, points_n do
				ctypes[i-1] = types[i]
				cpoints[i-1].x = points[i][1]
				cpoints[i-1].y = points[i][2]
			end
			-- Create device context
			local dc = ffi.gc(ffi.C.CreateCompatibleDC(nil), ffi.C.DeleteDC)
			-- Set context coordinates mapping mode
			ffi.C.SetMapMode(dc, 1)	-- 1 = MM_TEXT
			-- Set context backgrounds to transparent
			ffi.C.SetBkMode(dc, 1)	-- 1 = TRANSPARENT
			-- Set context filling mode to winding pattern
			ffi.C.SetPolyFillMode(dc, 2)	-- 2 = WINDING
			-- Add bitmap to context
			local bmp_width, bmp_height = math.ceil((x2 + shift_x) * downscale) * upscale, math.ceil((y2 + shift_y) * downscale) * upscale
			local bmp_info = ffi.new("BITMAPINFO[1]")
			bmp_info[0].bmiHeader.biSize = ffi.sizeof("BITMAPINFOHEADER")
			bmp_info[0].bmiHeader.biWidth = bmp_width
			bmp_info[0].bmiHeader.biHeight = -bmp_height
			bmp_info[0].bmiHeader.biPlanes = 1
			bmp_info[0].bmiHeader.biBitCount = 24
			bmp_info[0].bmiHeader.biCompression = 0	-- BI_RGB
			bmp_info[0].bmiHeader.biSizeImage = 0	-- ignored with BI_RGB
			bmp_info[0].bmiHeader.biXPelsPerMeter = 0
			bmp_info[0].bmiHeader.biYPelsPerMeter = 0
			bmp_info[0].bmiHeader.biClrUsed = 0
			bmp_info[0].bmiHeader.biClrImportant = 0
			bmp_info[0].bmiColors = nil
			local data = ffi.new("BYTE*[1]")
			local bmp = ffi.gc(ffi.C.CreateDIBSection(dc, bmp_info, 0, ffi.cast("void**", data), nil, 0), ffi.C.DeleteObject)
			ffi.C.SelectObject(dc, bmp)
			-- Add shape to context path
			ffi.C.BeginPath(dc)
			ffi.C.PolyDraw(dc, cpoints, ctypes, points_n)
			ffi.C.EndPath(dc)
			-- Fill context path
			ffi.C.FillPath(dc)
			ffi.C.GdiFlush()
			-- Extract pixels from context
			local pixels, pixels_n, opacity = {}, 0
			for y=0, bmp_height-upscale, upscale do
				for x=0, bmp_width-upscale, upscale do
					opacity = 0
					for yy=0, upscale-1 do
						for xx=0, upscale-1 do
							opacity = opacity + data[0][(y+yy) * bmp_width * 3 + (x+xx) * 3]
						end
					end
					if opacity > 0 then
						pixels_n = pixels_n + 1
						pixels[pixels_n] = {
							alpha = opacity * (downscale * downscale),
							x = (x - shift_x) * downscale,
							y = (y - shift_y) * downscale
						}
					end
				end
			end
			return pixels
		end
	},
	-- Decoder sublibrary
	decode = {
		-- Create BMP file reader
		create_bmp_reader = function(filename)
			-- Check argument
			if type(filename) ~= "string" then
				error("bmp filename expected", 2)
			end
			-- Convert little-endian bytes string to Lua number
			local function bton(s)
				local bytes = {s:byte(1,#s)}
				local n, bytes_n = 0, #bytes
				for i = 0, bytes_n-1 do
					n = n + bytes[1+i] * 2^(i*8)
				end
				return n
			end
			-- Open file handle
			local file = io.open(filename, "rb")
			if not file then
				error(string.format("couldn't open file %q", filename), 2)
			end
			-- Read bitmap header
			if file:read(2) ~= "BM" then
				error("not a windows bitmap file", 2)
			end
			local file_size = file:read(4)
			if not file_size then
				error("file size not found", 2)
			end
			file_size = bton(file_size)
			file:seek("cur", 4)	-- skip application reserved bytes
			local data_offset = file:read(4)
			if not data_offset then
				error("data offset not found", 2)
			end
			data_offset = bton(data_offset)
			-- DIB Header
			file:seek("cur", 4)	-- skip header size
			local width = file:read(4)
			if not width then
				error("width not found", 2)
			end
			width = bton(width)
			if width >= 2^31 then
				width = width - 2^32
			end
			local height = file:read(4)
			if not height then
				error("height not found", 2)
			end
			height = bton(height)
			if height >= 2^31 then
				height = height - 2^32
			end
			local planes = file:read(2)
			if not planes or bton(planes) ~= 1 then
				error("planes must be 1", 2)
			end
			local bit_depth = file:read(2)
			if not bit_depth or bton(bit_depth) ~= 24 then
				error("bit depth must be 24", 2)
			end
			local compression = file:read(4)
			if not compression or bton(compression) ~= 0 then
				error("must be uncompressed RGB", 2)
			end
			local data_size = file:read(4)
			if not data_size then
				error("data size not found", 2)
			end
			data_size = bton(data_size)
			if data_size == 0 then
				error("data size must not be zero", 2)
			end
			-- Data
			file:seek("set", data_offset)
			local data = file:read(data_size)
			if not data or #data ~= data_size then
				error("not enough data", 2)
			end
			-- Calculate row size (round up to multiple of 4)
			local row_size = math.floor((24 * width + 31) / 32) * 4
			-- Return bitmap object
			local obj = {
				get_file_size = function()
					return file_size
				end,
				get_width = function()
					return width
				end,
				get_height = function()
					return height
				end,
				get_data_size = function()
					return data_size
				end,
				get_row_size = function()
					return row_size
				end,
				get_data_raw = function()
					return data
				end,
				get_data_packed = function()
					local data_packed, data_packed_n, last_row_item, r, g, b = {}, 0, (width-1)*3
					local first_row, last_row, row_step
					if height < 0 then
						first_row, last_row, row_step = 0, height-1, 1
					else
						first_row, last_row, row_step = height-1, 0, -1
					end
					for y=first_row, last_row, row_step do
						y = 1 + y * row_size
						for x=0, last_row_item, 3 do
							b, g, r = data:byte(y+x, y+x+2)
							data_packed_n = data_packed_n + 1
							data_packed[data_packed_n] = {
								r = r,
								g = g,
								b = b
							}
						end
					end
					return data_packed
				end
			}
			obj.get_data_text = function()
				local data_pack, text, text_n, cur_x, off_x, off_y, shape = obj.get_data_packed(), {"{\\bord0\\shad0\\an7\\p1}"}, 1, 0, 0, 0, "m 0 0 l 1 0 1 1 0 1"
				for i=1, #data_pack do
					if cur_x == width then
						cur_x = 1
						off_x = off_x - width
						off_y = off_y + 1
						shape = string.format("m %d %d l %d %d  %d %d  %d %d", off_x, off_y, off_x+1, off_y, off_x+1, off_y+1, off_x, off_y+1)
					else
						cur_x = cur_x + 1
					end
					text_n = text_n + 1
					text[text_n] = string.format("{\\c&H%02X%02X%02X&}%s",
															data_pack[i].b, data_pack[i].g, data_pack[i].r, shape)
				end
				return table.concat(text)
			end
			return obj
		end,
		-- Create font
		create_font = function(family, bold, italic, underline, strikeout, size)
			-- Check arguments
			if type(family) ~= "string" or type(bold) ~= "boolean" or type(italic) ~= "boolean" or type(underline) ~= "boolean" or type(strikeout) ~= "boolean" or type(size) ~= "number" or size <= 0 then
				error("expected family, bold, italic, underline, strikeout and size", 2)
			end
			-- Font scale values for increased size & later downscaling to produce floating point coordinates
			local upscale = 64
			local downscale = 1 / upscale
			local shapescale = downscale * 8
			-- Lua string in utf-8 to C string in utf-16
			local function utf8_to_utf16(s)
				-- Get string length
				local len = #s
				-- Get resulting utf16 characters number
				local wlen = ffi.C.MultiByteToWideChar(65001, 0, s, len, nil, 0)	-- 65001 = CP_UTF8
				-- Allocate array for utf16 characters storage
				local ws = ffi.new("wchar_t[?]", wlen+1)
				-- Convert utf8 string to utf16 characters
				ffi.C.MultiByteToWideChar(65001, 0, s, len, ws, wlen)
				-- Set null-termination to utf16 storage
				ws[wlen] = 0
				-- Return utf16 C string
				return ws
			end
			-- Create device context and set light resources deleter
			local resources_deleter
			local dc = ffi.gc(ffi.C.CreateCompatibleDC(nil), resources_deleter)
			-- Set context coordinates mapping mode
			ffi.C.SetMapMode(dc, 1)	-- 1 = MM_TEXT
			-- Set context backgrounds to transparent
			ffi.C.SetBkMode(dc, 1)	-- 1 = TRANSPARENT
			-- Convert family from utf8 to utf16
			family = utf8_to_utf16(family)
			if ffi.C.wcslen(family) > 31 then
				error("family name to long", 2)
			end
			-- Create font handle
			local font = ffi.C.CreateFontW(
				size * upscale,	-- nHeight
				0,	-- nWidth
				0,	-- nEscapement
				0,	-- nOrientation
				bold and 700 or 400,	-- fnWeight (700 = FW_BOLD, 400 = FW_NORMAL)
				italic and 1 or 0,	-- fdwItalic
				underline and 1 or 0,	--fdwUnderline
				strikeout and 1 or 0,	-- fdwStrikeOut
				1,	-- fdwCharSet (1 = DEFAULT_CHARSET)
				4,	-- fdwOutputPrecision (4 = OUT_TT_PRECIS)
				0,	-- fdwClipPrecision (0 = CLIP_DEFAULT_PRECIS)
				4,	-- fdwQuality (4 = ANTIALIASED_QUALITY)
				0,	-- fdwPitchAndFamily (0 = FF_DONTCARE)
				family
			)
			-- Set new font to device context
			local old_font = ffi.C.SelectObject(dc, font)
			-- Define light resources deleter
			resources_deleter = function()
				ffi.C.SelectObject(dc, old_font)
				ffi.C.DeleteObject(font)
				ffi.C.DeleteDC(dc)
			end
			-- Return font object
			return {
				-- Get font metrics
				metrics = function()
					-- Get font metrics from device context
					local metrics = ffi.new("TEXTMETRICW[1]")
					ffi.C.GetTextMetricsW(dc, metrics)
					return {
						height = metrics[0].tmHeight * downscale,
						ascent = metrics[0].tmAscent * downscale,
						descent = metrics[0].tmDescent * downscale,
						internal_leading = metrics[0].tmInternalLeading * downscale,
						external_leading = metrics[0].tmExternalLeading * downscale
					}
				end,
				-- Get text extents
				text_extents = function(text)
					-- Check argument
					if type(text) ~= "string" then
						error("text expected", 2)
					end
					-- Get text extents with this font
					text = utf8_to_utf16(text)
					local size = ffi.new("SIZE[1]")
					ffi.C.GetTextExtentPoint32W(dc, text, ffi.C.wcslen(text), size)
					return {
						width = size[0].cx * downscale,
						height = size[0].cy * downscale
					}
				end,
				-- Convert text to ASS shape
				text_to_shape = function(text)
					-- Check argument
					if type(text) ~= "string" then
						error("text expected", 2)
					end
					-- Initialize shape as table
					local shape, shape_n = {}, 0
					-- Add path to device context
					text = utf8_to_utf16(text)
					ffi.C.BeginPath(dc)
					ffi.C.ExtTextOutW(dc, 0, 0, 0, nil, text, ffi.C.wcslen(text), nil)
					ffi.C.EndPath(dc)
					-- Get path data
					local points_n = ffi.C.GetPath(dc, nil, nil, 0)
					if points_n > 0 then
						local points, types = ffi.new("POINT[?]", points_n), ffi.new("BYTE[?]", points_n)
						ffi.C.GetPath(dc, points, types, points_n)
						-- Convert points to shape
						local i, last_type, cur_type, cur_point = 0
						while i < points_n do
							cur_type, cur_point = types[i], points[i]
							if cur_type == 6 then	-- 6 = PT_MOVETO
								if last_type ~= 6 then
									shape_n = shape_n + 1
									shape[shape_n] = "m"
									last_type = cur_type
								end
								shape[shape_n+1] = Yutils.math.round(cur_point.x * shapescale)
								shape[shape_n+2] = Yutils.math.round(cur_point.y * shapescale)
								shape_n = shape_n + 2
								i = i + 1
							elseif cur_type == 2 or cur_type == 3 then	-- 2 = PT_LINETO, 3 = PT_LINETO|PT_CLOSEFIGURE
								if last_type ~= 2 then
									shape_n = shape_n + 1
									shape[shape_n] = "l"
									last_type = cur_type
								end
								shape[shape_n+1] = Yutils.math.round(cur_point.x * shapescale)
								shape[shape_n+2] = Yutils.math.round(cur_point.y * shapescale)
								shape_n = shape_n + 2
								i = i + 1
							elseif cur_type == 4 or cur_type == 5 then	-- 4 = PT_BEZIERTO, 5 = PT_BEZIERTO|PT_CLOSEFIGURE
								if last_type ~= 4 then
									shape_n = shape_n + 1
									shape[shape_n] = "b"
									last_type = cur_type
								end
								shape[shape_n+1] = Yutils.math.round(cur_point.x * shapescale)
								shape[shape_n+2] = Yutils.math.round(cur_point.y * shapescale)
								shape[shape_n+3] = Yutils.math.round(points[i+1].x * shapescale)
								shape[shape_n+4] = Yutils.math.round(points[i+1].y * shapescale)						
								shape[shape_n+5] = Yutils.math.round(points[i+2].x * shapescale)
								shape[shape_n+6] = Yutils.math.round(points[i+2].y * shapescale)
								shape_n = shape_n + 6
								i = i + 3
							else	-- invalid type (should never happen, but let us be safe)
								i = i + 1
							end
							if cur_type % 2 == 1 then	-- odd = PT_CLOSEFIGURE
								shape_n = shape_n + 1
								shape[shape_n] = "c"
							end
						end
					end
					-- Clear device context path
					ffi.C.AbortPath(dc)
					-- Return shape as string
					return table.concat(shape, " ")
				end
			}
		end
	}
}

-- Return library to script loader
return Yutils