-- Initalize library location
local lib_string = _G._YUTILS_GLOBAL and _G.string or {}

-- Load dependencies
local Ytype = require("Yutils.type")

-- Shortcuts for optimization
local assert, isstring, isnil, isint, pcall = _G.assert, Ytype.isstring, Ytype.isnil, Ytype.isint, _G.pcall

-- Set library methods
--[[
		UTF32 -> UTF8
		--------------
		U-00000000 - U-0000007F:		0xxxxxxx
		U-00000080 - U-000007FF:		110xxxxx 10xxxxxx
		U-00000800 - U-0000FFFF:		1110xxxx 10xxxxxx 10xxxxxx
		U-00010000 - U-001FFFFF:		11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
		U-00200000 - U-03FFFFFF:		111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
		U-04000000 - U-7FFFFFFF:		1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
]]
lib_string.clen = function(s, i)
	assert(isstring(s) and (isnil(i) or isint(i)), "string and optional character index expected")
	local byte = s:byte(i)
	return not byte and 0 or
			byte < 192 and 1 or
			byte < 224 and 2 or
			byte < 240 and 3 or
			byte < 248 and 4 or
			byte < 252 and 5 or
			6
end
lib_string.chars = function(s)
	assert(isstring(s), "string expected")
	local ci, si, sn, clen = 0, 1, #s, lib_string.clen
	return function()
		if si <= sn then
			local last_si = si
			si = si + clen(s, si)
			if si-1 <= sn then	-- check full utf8 character
				ci = ci + 1
				return ci, s:sub(last_si, si-1)
			end
		end
	end
end
lib_string.slen = function(s)
	assert(isstring(s), "string expected")
	local n = 0
	for _ in lib_string.chars(s) do
		n = n + 1
	end
	return n
end

-- Set luajit/windows-only library methods
local success, ffi = pcall(require, "ffi")
if success and ffi.os == "Windows" then
	local kernel32 = ffi.load("kernel32")
	local CP_UTF8 = 65001	-- No static values in C definitions to avoid ffi override errors
	ffi.cdef([[
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef const char* LPCSTR;
typedef const wchar_t* LPCWSTR;
typedef wchar_t* LPWSTR;
typedef char* LPSTR;
typedef int BOOL;
typedef BOOL* LPBOOL;

int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
int WideCharToMultiByte(UINT, DWORD, LPCWSTR, int, LPSTR, int, LPCSTR, LPBOOL);
	]])
	lib_string.utf8toutf16 = function(s)
		assert(isstring(s), "string expected")
		local wlen = kernel32.MultiByteToWideChar(CP_UTF8, 0x0, s, -1, nil, 0)
		if wlen > 0 then
			local ws = ffi.new("wchar_t[?]", wlen)
			if kernel32.MultiByteToWideChar(CP_UTF8, 0x0, s, -1, ws, wlen) > 0 then
				return ffi.string(ws, wlen*ffi.sizeof("wchar_t"))
			end
		end
	end
	lib_string.utf16toutf8 = function(ws)
		assert(isstring(ws), "string expected")
		if not ws:find("%z%z") then	-- Make sure input is null-terminated
			ws = ws .. "\0"	-- Last zero is already part of Lua string internal
		end
		local pws = ffi.cast("LPCWSTR", ws)
		local len = kernel32.WideCharToMultiByte(CP_UTF8, 0x0, pws, -1, nil, 0, nil, nil)
		if len > 0 then
			local s = ffi.new("char[?]", len)
			if kernel32.WideCharToMultiByte(CP_UTF8, 0x0, pws, -1, s, len, nil, nil) > 0 then
				return ffi.string(s, len)
			end
		end
	end
end

-- Return library
return lib_string