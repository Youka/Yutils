--[[
	Copyright (c) 2014, Christoph "Youka" Spanknebel

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
	-----------------------------------------------------------------------------------------------------------------
	Version: 1st July 2014, 05:01 (GMT+1)
	
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
				identity() -> table
				multiply(matrix2) -> table
				translate(x, y, z) -> table
				scale(x, y, z) -> table
				rotate(axis, angle) -> table
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
local pango
if ffi.os == "Windows" then
	-- Set C definitions for WinAPI
	ffi.cdef([[
typedef unsigned int UINT;
typedef unsigned long DWORD;
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

int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
HDC CreateCompatibleDC(HDC);
BOOL DeleteDC(HDC);
int SetMapMode(HDC, int);
int SetBkMode(HDC, int);
size_t wcslen(const wchar_t*);
HFONT CreateFontW(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
HGDIOBJ SelectObject(HDC, HGDIOBJ);
BOOL DeleteObject(HGDIOBJ);
BOOL GetTextMetricsW(HDC, LPTEXTMETRICW);
BOOL GetTextExtentPoint32W(HDC, LPCWSTR, int, LPSIZE);
BOOL BeginPath(HDC);
BOOL ExtTextOutW(HDC, int, int, UINT, LPCRECT, LPCWSTR, UINT, const INT*);
BOOL EndPath(HDC);
int GetPath(HDC, LPPOINT, PBYTE, int);
BOOL AbortPath(HDC);
	]])
else	-- Unix
	-- Load pangocairo library
	pango = ffi.load("libpangocairo-1.0.so")
	-- Set C definitions for Pangocairo
	ffi.cdef([[
typedef enum{
    CAIRO_FORMAT_INVALID   = -1,
    CAIRO_FORMAT_ARGB32    = 0,
    CAIRO_FORMAT_RGB24     = 1,
    CAIRO_FORMAT_A8        = 2,
    CAIRO_FORMAT_A1        = 3,
    CAIRO_FORMAT_RGB16_565 = 4,
    CAIRO_FORMAT_RGB30     = 5
}cairo_format_t;
typedef void cairo_surface_t;
typedef void cairo_t;
typedef void PangoLayout;
typedef void* gpointer;
typedef void PangoFontDescription;
typedef enum{
	PANGO_WEIGHT_THIN	= 100,
	PANGO_WEIGHT_ULTRALIGHT = 200,
	PANGO_WEIGHT_LIGHT = 300,
	PANGO_WEIGHT_NORMAL = 400,
	PANGO_WEIGHT_MEDIUM = 500,
	PANGO_WEIGHT_SEMIBOLD = 600,
	PANGO_WEIGHT_BOLD = 700,
	PANGO_WEIGHT_ULTRABOLD = 800,
	PANGO_WEIGHT_HEAVY = 900,
	PANGO_WEIGHT_ULTRAHEAVY = 1000
}PangoWeight;
typedef enum{
	PANGO_STYLE_NORMAL,
	PANGO_STYLE_OBLIQUE,
	PANGO_STYLE_ITALIC
}PangoStyle;
typedef void PangoAttrList;
typedef void PangoAttribute;
typedef enum{
	PANGO_UNDERLINE_NONE,
	PANGO_UNDERLINE_SINGLE,
	PANGO_UNDERLINE_DOUBLE,
	PANGO_UNDERLINE_LOW,
	PANGO_UNDERLINE_ERROR
}PangoUnderline;
typedef int gint;
typedef gint gboolean;
typedef void PangoContext;
typedef unsigned int guint;
typedef struct{
	guint ref_count;
	int ascent;
	int descent;
	int approximate_char_width;
	int approximate_digit_width;
	int underline_position;
	int underline_thickness;
	int strikethrough_position;
	int strikethrough_thickness;
}PangoFontMetrics;
typedef void PangoLanguage;
typedef struct{
	int x;
	int y;
	int width;
	int height;
}PangoRectangle;
typedef enum{
	CAIRO_STATUS_SUCCESS = 0
}cairo_status_t;
typedef enum{
	CAIRO_PATH_MOVE_TO,
	CAIRO_PATH_LINE_TO,
	CAIRO_PATH_CURVE_TO,
	CAIRO_PATH_CLOSE_PATH
}cairo_path_data_type_t;
typedef union{
	struct{
		cairo_path_data_type_t type;
		int length;
	}header;
	struct{
		double x, y;
	}point;
}cairo_path_data_t;
typedef struct{
	cairo_status_t status;
	cairo_path_data_t* data;
	int num_data;
}cairo_path_t;

cairo_surface_t* cairo_image_surface_create(cairo_format_t, int, int);
void cairo_surface_destroy(cairo_surface_t*);
cairo_t* cairo_create(cairo_surface_t*);
void cairo_destroy(cairo_t*);
PangoLayout* pango_cairo_create_layout(cairo_t*);
void g_object_unref(gpointer);
PangoFontDescription* pango_font_description_new(void);
void pango_font_description_free(PangoFontDescription*);
void pango_font_description_set_family(PangoFontDescription*, const char*);
void pango_font_description_set_weight(PangoFontDescription*, PangoWeight);
void pango_font_description_set_style(PangoFontDescription*, PangoStyle);
void pango_font_description_set_absolute_size(PangoFontDescription*, double);
void pango_layout_set_font_description(PangoLayout*, PangoFontDescription*);
PangoAttrList* pango_attr_list_new(void);
void pango_attr_list_unref(PangoAttrList*);
void pango_attr_list_insert(PangoAttrList*, PangoAttribute*);
PangoAttribute* pango_attr_underline_new(PangoUnderline);
PangoAttribute* pango_attr_strikethrough_new(gboolean);
void pango_layout_set_attributes(PangoLayout*, PangoAttrList*);
PangoContext* pango_layout_get_context(PangoLayout*);
const PangoFontDescription* pango_layout_get_font_description(PangoLayout*);
PangoFontMetrics* pango_context_get_metrics(PangoContext*, const PangoFontDescription*, PangoLanguage*);
void pango_font_metrics_unref(PangoFontMetrics*);
int pango_font_metrics_get_ascent(PangoFontMetrics*);
int pango_font_metrics_get_descent(PangoFontMetrics*);
int pango_layout_get_spacing(PangoLayout*);
void pango_layout_set_text(PangoLayout*, const char*, int);
void pango_layout_get_pixel_extents(PangoLayout*, PangoRectangle*, PangoRectangle*);
void cairo_save(cairo_t*);
void cairo_restore(cairo_t*);
void cairo_scale(cairo_t*, double, double);
void pango_cairo_layout_path(cairo_t*, PangoLayout*);
void cairo_new_path(cairo_t*);
cairo_path_t* cairo_copy_path(cairo_t*);
void cairo_path_destroy(cairo_path_t*);
	]])
end

-- Create library table
local Yutils
Yutils = {
	-- Table sublibrary
	table = {
		-- Copies table deep
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
		-- Converts table to string
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
			local char_i, s_pos, s_len = 0, 1, #s
			return function()
				if s_pos > s_len then
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
		-- Creates 3d matrix
		create_matrix = function()
			-- Matrix data
			local matrix = {1, 0, 0, 0,
								0, 1, 0, 0,
								0, 0, 1, 0,
								0, 0, 0, 1}
			-- Matrix object
			local obj
			obj = {
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
					-- Set matrix to default / no transformation
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
					-- Return this object
					return obj
				end,
				-- Multiplies matrix with given one
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
					-- Return this object
					return obj
				end,
				-- Applies translation to matrix
				translate = function(x, y, z)
					-- Check arguments
					if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
						error("3 translation values expected", 2)
					end
					-- Add translation to matrix
					obj.multiply({1, 0, 0, 0,
									0, 1, 0, 0,
									0, 0, 1, 0,
									x, y, z, 1})
					-- Return this object
					return obj
				end,
				-- Applies scale to matrix
				scale = function(x, y, z)
					-- Check arguments
					if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
						error("3 scale factors expected", 2)
					end
					-- Add scale to matrix
					obj.multiply({x, 0, 0, 0,
									0, y, 0, 0,
									0, 0, z, 0,
									0, 0, 0, 1})
					-- Return this object
					return obj
				end,
				-- Applies rotation to matrix
				rotate = function(axis, angle)
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
					-- Return this object
					return obj
				end,
				-- Applies matrix to point
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
			return math.min(min + math.random(0, math.ceil((max - min) / step)) * step, max)
		end,
		-- Rounds number
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
		-- Calculates shape bounding box
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
		-- Filters shape coordinates
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
		-- Converts shape curves to lines
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
				local i, n = 1, #vecs
				while i <= n do
					if vecs[i][1] == 0 and vecs[i][2] == 0 then
						table.remove(vecs, i)
						n = n - 1
					else
						i = i + 1
					end
				end
				-- Check flatness on remaining vectors
				if n < 2 then
					return true
				else
					for i=1, n-1 do
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
		-- Shifts shape coordinates
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
		-- Splits shape lines into shorter segments
		split = function(shape, max_len)
			-- Check arguments
			if type(shape) ~= "string" or type(max_len) ~= "number" or max_len <= 0 then
				error("shape and maximal line length expected", 2)
			end
			-- Remove shape closings (figures become line-completed)
			shape = shape:gsub("%s+c", "")
			-- Line splitter + string encoder
			local function line_split(x0, y0, x1, y1)
				-- Line direction & length
				local rel_x, rel_y = x1 - x0, y1 - y0
				local distance = Yutils.math.distance(rel_x, rel_y)
				-- Line too long -> split!
				if distance > max_len then
					-- Generate line segments
					local lines, lines_n, distance_rest, pct = {}, 0, distance % max_len
					for cur_distance = distance_rest > 0 and distance_rest or max_len, distance, max_len do
						pct = cur_distance / distance
						lines_n = lines_n + 1
						lines[lines_n] = string.format("%d %d ", x0 + rel_x * pct, y0 + rel_y * pct)
					end
					return table.concat(lines):sub(1,-2)
				-- No line split
				else
					return string.format("%d %d", x1, y1)
				end
			end
			-- Split shape long lines to short ones
			local line_mode, last_point, last_move = false
			shape = shape:gsub("(%a?)(%s*)(%-?%d+)%s+(%-?%d+)", function(typ, space, x, y)
				-- Output buffer
				local result = ""
				-- Close last figure
				if typ == "m" and last_point and last_move and not (last_point[1] == last_move[1] and last_point[2] == last_move[2]) then
					result = string.format("%s%s ", line_mode and "" or "l ", line_split(last_point[1], last_point[2], last_move[1], last_move[2]))
				end
				-- Add current type and space to output
				result = string.format("%s%s%s", result, typ, space)
				-- En-/disable line mode by current type
				if typ ~= "" then
					line_mode = typ == "l"
				end
				-- Line with previous point?
				if line_mode and last_point then
					result = result .. line_split(last_point[1], last_point[2], x, y)
				else
					result = string.format("%s%d %d", result, x, y)
				end
				-- Update last point & move
				last_point = {x, y}
				if typ == "m" then
					last_move = {x, y}
				end
				-- Return resulting point(s)
				return result
			end)
			-- Close last figure of shape
			if last_move then
				shape = shape:gsub("(%-?%d+)%s+(%-?%d+)%s*$", function(x, y)
					local result = string.format("%d %d", x, y)
					if not (last_move[1] == x and last_move[2] == y) then
						result = string.format("%s %s%s", result, line_mode and "" or "l ", line_split(x, y, last_move[1], last_move[2]))
					end
					return result
				end, 1)
			end
			return shape
		end,
		-- Converts shape to stroke version
		to_outline = function(shape, width)
			-- Check arguments
			if type(shape) ~= "string" or type(width) ~= "number" or width <= 0 then
				error("shape and line width expected", 2)
			end
			-- Collect figures
			local figures, figures_n, figure, figure_n = {}, 0, {}, 0
			local last_move
			for typ, x, y in shape:gmatch("(%a?)%s*(%-?%d+)%s+(%-?%d+)") do
				-- Check point type
				if typ ~= "m" and typ ~= "l" and typ ~= "" then
					error("shape have to contain only \"moves\" and \"lines\"", 2)
				end
				-- New figure?
				if not last_move or typ == "m" then
					-- Enough points in figure?
					if figure_n > 2 then
						-- Last point equal to first point? (yes: remove him)
						if last_move and figure[figure_n][1] == last_move[1] and figure[figure_n][2] == last_move[2] then
							figure[figure_n] = nil
						end
						-- Save figure
						figures_n = figures_n + 1
						figures[figures_n] = figure
					end
					-- Clear figure for new one
					figure, figure_n = {}, 0
					-- Save last move for figure closing check
					last_move = {x, y}
				end
				-- Add point to current figure (if not copy of last)
				if figure_n == 0 or not(figure[figure_n][1] == x and figure[figure_n][2] == y) then
					figure_n = figure_n + 1
					figure[figure_n] = {x, y}
				end
			end
			-- Insert last figure (with enough points)
			if figure_n > 2 then
				-- Last point equal to first point? (yes: remove him)
				if last_move and figure[figure_n][1] == last_move[1] and figure[figure_n][2] == last_move[2] then
					figure[figure_n] = nil
				end
				-- Save figure
				figures_n = figures_n + 1
				figures[figures_n] = figure
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
			-- Create stroke shape out of figures
			local stroke_shape, stroke_shape_n = {}, 0
			for fi, figure in ipairs(figures) do
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
						outline[outline_n] = string.format("%s%d %d",
																	outline_n == 1 and "m " or outline_n == 2 and "l " or "",
																	Yutils.math.round(point[1] + o_vec1_x), Yutils.math.round(point[2] + o_vec1_y))
						-- Round edge needed?
						local max_circ = 2
						if circ > max_circ then
							local circ_rest = circ % max_circ
							for cur_circ = circ_rest > 0 and circ_rest or max_circ, circ, max_circ do
								local curve_vec_x, curve_vec_y = rotate(o_vec1_x, o_vec1_y, cur_circ / circ * degree)
								outline_n = outline_n + 1
								outline[outline_n] = string.format("%s%d %d",
																			outline_n == 1 and "m " or outline_n == 2 and "l " or "",
																			Yutils.math.round(point[1] + curve_vec_x), Yutils.math.round(point[2] + curve_vec_y))
							end
						end
					end
					-- Insert inner or outer outline to stroke shape
					stroke_shape_n = stroke_shape_n + 1
					stroke_shape[stroke_shape_n] = table.concat(outline, " ")
				end
			end
			return table.concat(stroke_shape, " ")
		end,
		-- Converts shape to pixels
		to_pixels = function(shape)
			-- Check argument
			if type(shape) ~= "string" then
				error("shape expected", 2)
			end
			-- Scale values for later anti-aliasing
			local upscale = 8
			local downscale = 1 / upscale
			-- Get shape bounding
			local x1, y1, x2, y2 = Yutils.shape.bounding(shape)
			if not y2 then
				error("not enough shape points", 2)
			end
			-- Bring shape near origin in positive room
			local shift_x, shift_y = -(x1 - x1 % upscale), -(y1 - y1 % upscale)
			shape = Yutils.shape.move(shape, shift_x, shift_y)
			-- Renderer (on binary image with aliasing)
			local function render_shape(width, height, image, shape)
				-- Convert curves to lines
				shape = Yutils.shape.flatten(shape)
				-- Collect lines (points + vectors)
				local lines, lines_n, last_point, last_move = {}, 0
				for typ, x, y in shape:gmatch("(%a?)%s*(%-?%d+)%s+(%-?%d+)") do
					x, y = tonumber(x), tonumber(y)
					-- Move
					if typ == "m" then
						-- Close figure with non-horizontal line in image
						if last_move and last_move[2] ~= last_point[2] and not (last_point[2] < 0 and last_move[2] < 0) and not (last_point[2] > height and last_move[2] > height) then
							lines_n = lines_n + 1
							lines[lines_n] = {last_point[1], last_point[2], last_move[1] - last_point[1], last_move[2] - last_point[2]}
						end
						last_move = {x, y}
					-- Non-horizontal line in image
					elseif last_point and last_point[2] ~= y and not (last_point[2] < 0 and y < 0) and not (last_point[2] > height and y > height) then
						lines_n = lines_n + 1
						lines[lines_n] = {last_point[1], last_point[2], x - last_point[1], y - last_point[2]}
					end
					-- Remember last point
					last_point = {x, y}
				end
				-- Close last figure with non-horizontal line in image
				if last_move and last_move[2] ~= last_point[2] and not (last_point[2] < 0 and last_move[2] < 0) and not (last_point[2] > height and last_move[2] > height) then
					lines_n = lines_n + 1
					lines[lines_n] = {last_point[1], last_point[2], last_move[1] - last_point[1], last_move[2] - last_point[2]}
				end
				-- Calculates line x horizontal line intersection
				local function line_x_hline(x, y, vx, vy, y2)
					if vy ~= 0 then
						local s = (y2 - y) / vy
						if s >= 0 and s <= 1 then
							return x + s * vx, y2
						end
					end
				end
				-- Trims number in range
				local function num_trim(x, min, max)
					return x < min and min or x > max and max or x
				end
				-- Scan image rows in shape
				local _, y1, _, y2 = Yutils.shape.bounding(shape)
				for y = math.max(y1, 0), math.min(y2, height)-1 do
					-- Collect row intersections with lines
					local row_stops, row_stops_n = {}, 0
					for i=1, lines_n do
						local line = lines[i]
						local cx = line_x_hline(line[1], line[2], line[3], line[4], y + 0.5)
						if cx then
							row_stops_n = row_stops_n + 1
							row_stops[row_stops_n] = {num_trim(Yutils.math.round(cx), 0, width), line[4] > 0 and 1 or -1}	-- image trimmed stop position & line vertical direction
						end
					end
					-- Enough intersections / something to render?
					if row_stops_n > 1 then
						-- Sort row stops by horizontal position
						table.sort(row_stops, function(a, b)
							return a[1] < b[1]
						end)
						-- Render!
						local status, row_index = 0, 1 + y * width
						for i = 1, row_stops_n-1 do
							status = status + row_stops[i][2]
							if status ~= 0 then
								for x=row_stops[i][1], row_stops[i+1][1]-1 do
									image[row_index + x] = true
								end
							end
						end
					end
				end
			end
			-- Create image
			local img_width, img_height, img_data = math.ceil((x2 + shift_x) * downscale) * upscale, math.ceil((y2 + shift_y) * downscale) * upscale, {}
			for i=1, img_width*img_height do
				img_data[i] = false
			end
			-- Render shape on image
			render_shape(img_width, img_height, img_data, shape)
			-- Extract pixels from image
			local pixels, pixels_n, opacity = {}, 0
			for y=0, img_height-upscale, upscale do
				for x=0, img_width-upscale, upscale do
					opacity = 0
					for yy=0, upscale-1 do
						for xx=0, upscale-1 do
							if img_data[1 + (y+yy) * img_width + (x+xx)] then
								opacity = opacity + 255
							end
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
		-- Creates BMP file reader
		create_bmp_reader = function(filename)
			-- Check argument
			if type(filename) ~= "string" then
				error("bmp filename expected", 2)
			end
			-- Convert little-endian bytes string to Lua number
			local function bton(s)
				local bytes, n = {s:byte(1,#s)}, 0
				for i = 0, #bytes-1 do
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
				error("pixels in right-to-left order not supported", 2)
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
			if not bit_depth then
				error("bit depth not found", 2)
			end
			bit_depth = bton(bit_depth)
			if bit_depth ~= 24 and bit_depth ~= 32 then
				error("bit depth must be 24 or 32", 2)
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
			local row_size = math.floor((bit_depth * width + 31) / 32) * 4
			-- Return bitmap object
			local obj
			obj = {
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
					local data_packed, data_packed_n = {}, 0
					local first_row, last_row, row_step
					if height < 0 then
						first_row, last_row, row_step = 0, -height-1, 1
					else
						first_row, last_row, row_step = height-1, 0, -1
					end
					if bit_depth == 24 then
						local last_row_item, r, g, b = (width-1)*3
						for y=first_row, last_row, row_step do
							y = 1 + y * row_size
							for x=0, last_row_item, 3 do
								b, g, r = data:byte(y+x, y+x+2)
								data_packed_n = data_packed_n + 1
								data_packed[data_packed_n] = {
									r = r,
									g = g,
									b = b,
									a = 255
								}
							end
						end
					else	-- bit_depth == 32
						local last_row_item, r, g, b, a = (width-1)*4
						for y=first_row, last_row, row_step do
							y = 1 + y * row_size
							for x=0, last_row_item, 4 do
								b, g, r, a = data:byte(y+x, y+x+3)
								data_packed_n = data_packed_n + 1
								data_packed[data_packed_n] = {
									r = r,
									g = g,
									b = b,
									a = a
								}
							end
						end
					end
					return data_packed
				end,
				get_data_text = function()
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
						text[text_n] = string.format("{\\c&H%02X%02X%02X&\\1a&H%02X&}%s",
																data_pack[i].b, data_pack[i].g, data_pack[i].r, 255-data_pack[i].a, shape)
					end
					return table.concat(text)
				end
			}
			return obj
		end,
		-- Creates font
		create_font = function(family, bold, italic, underline, strikeout, size)
			-- Check arguments
			if type(family) ~= "string" or type(bold) ~= "boolean" or type(italic) ~= "boolean" or type(underline) ~= "boolean" or type(strikeout) ~= "boolean" or type(size) ~= "number" or size <= 0 then
				error("expected family, bold, italic, underline, strikeout and size", 2)
			end
			-- Font scale values for increased size & later downscaling to produce floating point coordinates
			local upscale = 64
			local downscale = 1 / upscale
			local shapescale = downscale * 8
			-- Body by operation system
			if ffi.os == "Windows" then
				-- Lua string in utf-8 to C string in utf-16
				local function utf8_to_utf16(s)
					-- Get resulting utf16 characters number (+ null-termination)
					local wlen = ffi.C.MultiByteToWideChar(65001, 0, s, -1, nil, 0)	-- 65001 = CP_UTF8
					-- Allocate array for utf16 characters storage
					local ws = ffi.new("wchar_t[?]", wlen)
					-- Convert utf8 string to utf16 characters
					ffi.C.MultiByteToWideChar(65001, 0, s, -1, ws, wlen)
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
					-- Converts text to ASS shape
					text_to_shape = function(text)
						-- Check argument
						if type(text) ~= "string" then
							error("text expected", 2)
						end
						-- Initialize shape as table
						local shape, shape_n = {}, 0
						-- Add path to device context
						text = utf8_to_utf16(text)
						local text_len = ffi.C.wcslen(text)
						if text_len > 8192 then
							error("text too long", 2)
						end
						ffi.C.BeginPath(dc)
						ffi.C.ExtTextOutW(dc, 0, 0, 0, nil, text, text_len, nil)
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
			else	-- Unix
				-- Create surface, context & layout
				local surface = pango.cairo_image_surface_create(ffi.C.CAIRO_FORMAT_A8, 1, 1)
				local context = pango.cairo_create(surface)
				local layout
				layout = ffi.gc(pango.pango_cairo_create_layout(context), function()
					pango.g_object_unref(layout)
					pango.cairo_destroy(context)
					pango.cairo_surface_destroy(surface)
				end)
				-- Set font to layout
				local font_desc = ffi.gc(pango.pango_font_description_new(), pango.pango_font_description_free)
				pango.pango_font_description_set_family(font_desc, family)
				pango.pango_font_description_set_weight(font_desc, bold and ffi.C.PANGO_WEIGHT_BOLD or ffi.C.PANGO_WEIGHT_NORMAL)
				pango.pango_font_description_set_style(font_desc, italic and ffi.C.PANGO_STYLE_ITALIC or ffi.C.PANGO_STYLE_NORMAL)
				pango.pango_font_description_set_absolute_size(font_desc, size * 1024 --[[PANGO_SCALE]] * upscale)
				pango.pango_layout_set_font_description(layout, font_desc)
				local attr = ffi.gc(pango.pango_attr_list_new(), pango.pango_attr_list_unref)
				pango.pango_attr_list_insert(attr, pango.pango_attr_underline_new(underline and ffi.C.PANGO_UNDERLINE_SINGLE or ffi.C.PANGO_UNDERLINE_NONE))
				pango.pango_attr_list_insert(attr, pango.pango_attr_strikethrough_new(strikeout))
				pango.pango_layout_set_attributes(layout, attr)
				-- Return font object
				return {
					-- Get font metrics
					metrics = function()
						local context = pango.pango_layout_get_context(layout)
						local font_desc = pango.pango_layout_get_font_description(layout)
						local metrics = ffi.gc(pango.pango_context_get_metrics(context, font_desc, nil), pango.pango_font_metrics_unref)
						local ascent, descent = pango.pango_font_metrics_get_ascent(metrics) / 1024 * downscale,
												pango.pango_font_metrics_get_descent(metrics) / 1024 * downscale
						return {
							height = ascent + descent,
							ascent = ascent,
							descent = descent,
							internal_leading = 0,
							external_leading = pango.pango_layout_get_spacing(layout) / 1024 * downscale
						}
					end,
					-- Get text extents
					text_extents = function(text)
						-- Check argument
						if type(text) ~= "string" then
							error("text expected", 2)
						end
						-- Set text to layout
						pango.pango_layout_set_text(layout, text, -1)
						-- Get text extents with this font
						local rect = ffi.new("PangoRectangle[1]")
						pango.pango_layout_get_pixel_extents(layout, nil, rect)
						return {
							width = rect[0].width * downscale,
							height = rect[0].height * downscale
						}
					end,
					-- Converts text to ASS shape
					text_to_shape = function(text)
						-- Check argument
						if type(text) ~= "string" then
							error("text expected", 2)
						end
						-- Set text path to layout
						pango.pango_layout_set_text(layout, text, -1)
						pango.cairo_save(context)
						pango.cairo_scale(context, shapescale, shapescale)
						pango.pango_cairo_layout_path(context, layout)
						pango.cairo_restore(context)
						-- Initialize shape as table
						local shape, shape_n = {}, 0
						-- Convert path to shape
						local path = ffi.gc(pango.cairo_copy_path(context), pango.cairo_path_destroy)
						if(path[0].status == ffi.C.CAIRO_STATUS_SUCCESS) then
							local i, cur_type, last_type = 0
							while(i < path[0].num_data) do
								cur_type = path[0].data[i].header.type
								if cur_type == ffi.C.CAIRO_PATH_MOVE_TO then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "m"
									end
									shape[shape_n+1] = Yutils.math.round(path[0].data[i+1].point.x)
									shape[shape_n+2] = Yutils.math.round(path[0].data[i+1].point.y)
									shape_n = shape_n + 2
								elseif cur_type == ffi.C.CAIRO_PATH_LINE_TO then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "l"
									end
									shape[shape_n+1] = Yutils.math.round(path[0].data[i+1].point.x)
									shape[shape_n+2] = Yutils.math.round(path[0].data[i+1].point.y)
									shape_n = shape_n + 2
								elseif cur_type == ffi.C.CAIRO_PATH_CURVE_TO then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "b"
									end
									shape[shape_n+1] = Yutils.math.round(path[0].data[i+1].point.x)
									shape[shape_n+2] = Yutils.math.round(path[0].data[i+1].point.y)
									shape[shape_n+3] = Yutils.math.round(path[0].data[i+2].point.x)
									shape[shape_n+4] = Yutils.math.round(path[0].data[i+2].point.y)
									shape[shape_n+5] = Yutils.math.round(path[0].data[i+3].point.x)
									shape[shape_n+6] = Yutils.math.round(path[0].data[i+3].point.y)
									shape_n = shape_n + 6
								elseif cur_type == ffi.C.CAIRO_PATH_CLOSE_PATH then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "c"
									end
								end
								last_type = cur_type
								i = i + path[0].data[i].header.length
							end
						end
						pango.cairo_new_path(context)
						return table.concat(shape, " ")
					end
				}
			end
		end
	}
}

-- Return library to script loader
return Yutils