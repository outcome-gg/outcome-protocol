local ok, e
ok = nil
if not ok then
	ok, e = pcall(require, "bit") -- the LuaJIT one ?
end
if not ok then
	ok, e = pcall(require, "bit32") -- Lua 5.2
end
if not ok then
	ok, e = pcall(require, "bit.numberlua") -- for Lua 5.1, https://github.com/tst2005/lua-bit-numberlua/
end
if not ok then
	-- Lua 5.4 fallback
	e = {
		band = function(a, b) return a & b end,
		bor = function(a, b) return a | b end,
		bxor = function(a, b) return a ~ b end,
		lshift = function(a, b) return a << b end,
		rshift = function(a, b) return a >> b end,
		lrotate = function(a, n)
				return (a << n) | (a >> (32 - n))
		end,
		rrotate = function(a, n)
				return (a >> n) | (a << (32 - n))
		end
	}
end
assert(type(e) == "table", "invalid bit module")

-- Workaround to support Lua 5.2 bit32 API with the LuaJIT bit one
if e.rol and not e.lrotate then
	e.lrotate = e.rol
end
if e.ror and not e.rrotate then
	e.rrotate = e.ror
end

-- Workaround to support incomplete bit operations set
if not e.ror and not e.rrotate then
	local ror = function(b, n)
		return e.bor(e.rshift(b, n), e.lshift(b, 32 - n))
	end

	e.ror = ror
	e.rrotate = ror
end

if not e.rol and not e.lrotate then
	local rol = function(b, n)
		return e.bor(e.lshift(b, n), e.rshift(b, 32 - n))
	end

	e.rol = rol
	e.lrotate = rol
end

return e
