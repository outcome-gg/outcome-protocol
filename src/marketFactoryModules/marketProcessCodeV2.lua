return [===[

-- module: "marketModules.marketNotices"
local function _loaded_mod_marketModules_marketNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local MarketNotices = {}

--- Sends an update incentives notice
--- @param incentives string The updated incentives address
--- @param msg Message The message received
--- @return Message The incentives updated notice
function MarketNotices.updateIncentivesNotice(incentives, msg)
  return msg.reply({
    Action = "Update-Incentives-Notice",
    Data = incentives
  })
end

--- Sends a update data index notice
--- @param dataIndex string The updated data index
--- @param msg Message The message received
--- @return Message The data index updated notice
function MarketNotices.updateDataIndexNotice(dataIndex, msg)
  return msg.reply({
    Action = "Update-Data-Index-Notice",
    Data = dataIndex
  })
end

return MarketNotices
end

_G.package.loaded["marketModules.marketNotices"] = _loaded_mod_marketModules_marketNotices()

-- module: "json"
local function _loaded_mod_json()
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
	["\\"] = "\\",
	['"'] = '"',
	["\b"] = "b",
	["\f"] = "f",
	["\n"] = "n",
	["\r"] = "r",
	["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
	escape_char_map_inv[v] = k
end

local function escape_char(c)
	return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function encode_nil()
	return "null"
end

local function encode_table(val, stack)
	local res = {}
	stack = stack or {}

	-- Circular reference?
	if stack[val] then
		error("circular reference")
	end

	stack[val] = true

	if rawget(val, 1) ~= nil or next(val) == nil then
		-- Treat as array -- check keys are valid and it is not sparse
		local n = 0
		for k in pairs(val) do
			if type(k) ~= "number" then
				error("invalid table: mixed or invalid key types")
			end
			n = n + 1
		end
		if n ~= #val then
			error("invalid table: sparse array")
		end
		-- Encode
		for _, v in ipairs(val) do
			table.insert(res, encode(v, stack))
		end
		stack[val] = nil
		return "[" .. table.concat(res, ",") .. "]"
	else
		-- Treat as an object
		for k, v in pairs(val) do
			if type(k) ~= "string" then
				error("invalid table: mixed or invalid key types")
			end
			table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
		end
		stack[val] = nil
		return "{" .. table.concat(res, ",") .. "}"
	end
end

local function encode_string(val)
	return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
	-- Check for NaN, -inf and inf
	if val ~= val or val <= -math.huge or val >= math.huge then
		error("unexpected number value '" .. tostring(val) .. "'")
	end
	-- Handle integer values separately to avoid floating-point conversion
	if math.type(val) == "integer" then
		return string.format("%d", val) -- Format as an integer
	else
		-- Use 20 significant digits for non-integer numbers
		return string.format("%.20g", val)
	end
end

local type_func_map = {
	["nil"] = encode_nil,
	["table"] = encode_table,
	["string"] = encode_string,
	["number"] = encode_number,
	["boolean"] = tostring,
}

encode = function(val, stack)
	local t = type(val)
	local f = type_func_map[t]
	if f then
		return f(val, stack)
	end
	error("unexpected type '" .. t .. "'")
end

function json.encode(val)
	return (encode(val))
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
	local res = {}
	for i = 1, select("#", ...) do
		res[select(i, ...)] = true
	end
	return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals = create_set("true", "false", "null")

local literal_map = {
	["true"] = true,
	["false"] = false,
	["null"] = nil,
}

local function next_char(str, idx, set, negate)
	for i = idx, #str do
		if set[str:sub(i, i)] ~= negate then
			return i
		end
	end
	return #str + 1
end

local function decode_error(str, idx, msg)
	local line_count = 1
	local col_count = 1
	for i = 1, idx - 1 do
		col_count = col_count + 1
		if str:sub(i, i) == "\n" then
			line_count = line_count + 1
			col_count = 1
		end
	end
	error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

local function codepoint_to_utf8(n)
	-- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
	local f = math.floor
	if n <= 0x7f then
		return string.char(n)
	elseif n <= 0x7ff then
		return string.char(f(n / 64) + 192, n % 64 + 128)
	elseif n <= 0xffff then
		return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
	elseif n <= 0x10ffff then
		return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
	end
	error(string.format("invalid unicode codepoint '%x'", n))
end

local function parse_unicode_escape(s)
	local n1 = tonumber(s:sub(1, 4), 16)
	local n2 = tonumber(s:sub(7, 10), 16)
	-- Surrogate pair?
	if n2 then
		return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
	else
		return codepoint_to_utf8(n1)
	end
end

local function parse_string(str, i)
	local res = ""
	local j = i + 1
	local k = j

	while j <= #str do
		local x = str:byte(j)

		if x < 32 then
			decode_error(str, j, "control character in string")
		elseif x == 92 then -- `\`: Escape
			res = res .. str:sub(k, j - 1)
			j = j + 1
			local c = str:sub(j, j)
			if c == "u" then
				local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
					or str:match("^%x%x%x%x", j + 1)
					or decode_error(str, j - 1, "invalid unicode escape in string")
				res = res .. parse_unicode_escape(hex)
				j = j + #hex
			else
				if not escape_chars[c] then
					decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
				end
				res = res .. escape_char_map_inv[c]
			end
			k = j + 1
		elseif x == 34 then -- `"`: End of string
			res = res .. str:sub(k, j - 1)
			return res, j + 1
		end

		j = j + 1
	end

	decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
	local x = next_char(str, i, delim_chars)
	local s = str:sub(i, x - 1)
	local n = tonumber(s)
	if not n then
		decode_error(str, i, "invalid number '" .. s .. "'")
	end
	return n, x
end

local function parse_literal(str, i)
	local x = next_char(str, i, delim_chars)
	local word = str:sub(i, x - 1)
	if not literals[word] then
		decode_error(str, i, "invalid literal '" .. word .. "'")
	end
	return literal_map[word], x
end

local function parse_array(str, i)
	local res = {}
	local n = 1
	i = i + 1
	while 1 do
		local x
		i = next_char(str, i, space_chars, true)
		-- Empty / end of array?
		if str:sub(i, i) == "]" then
			i = i + 1
			break
		end
		-- Read token
		x, i = parse(str, i)
		res[n] = x
		n = n + 1
		-- Next token
		i = next_char(str, i, space_chars, true)
		local chr = str:sub(i, i)
		i = i + 1
		if chr == "]" then
			break
		end
		if chr ~= "," then
			decode_error(str, i, "expected ']' or ','")
		end
	end
	return res, i
end

local function parse_object(str, i)
	local res = {}
	i = i + 1
	while 1 do
		local key, val
		i = next_char(str, i, space_chars, true)
		-- Empty / end of object?
		if str:sub(i, i) == "}" then
			i = i + 1
			break
		end
		-- Read key
		if str:sub(i, i) ~= '"' then
			decode_error(str, i, "expected string for key")
		end
		key, i = parse(str, i)
		-- Read ':' delimiter
		i = next_char(str, i, space_chars, true)
		if str:sub(i, i) ~= ":" then
			decode_error(str, i, "expected ':' after key")
		end
		i = next_char(str, i + 1, space_chars, true)
		-- Read value
		val, i = parse(str, i)
		-- Set
		res[key] = val
		-- Next token
		i = next_char(str, i, space_chars, true)
		local chr = str:sub(i, i)
		i = i + 1
		if chr == "}" then
			break
		end
		if chr ~= "," then
			decode_error(str, i, "expected '}' or ','")
		end
	end
	return res, i
end

local char_func_map = {
	['"'] = parse_string,
	["0"] = parse_number,
	["1"] = parse_number,
	["2"] = parse_number,
	["3"] = parse_number,
	["4"] = parse_number,
	["5"] = parse_number,
	["6"] = parse_number,
	["7"] = parse_number,
	["8"] = parse_number,
	["9"] = parse_number,
	["-"] = parse_number,
	["t"] = parse_literal,
	["f"] = parse_literal,
	["n"] = parse_literal,
	["["] = parse_array,
	["{"] = parse_object,
}

parse = function(str, idx)
	local chr = str:sub(idx, idx)
	local f = char_func_map[chr]
	if f then
		return f(str, idx)
	end
	decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

function json.decode(str)
	if type(str) ~= "string" then
		error("expected argument of type string, got " .. type(str))
	end
	local res, idx = parse(str, next_char(str, 1, space_chars, true))
	idx = next_char(str, idx, space_chars, true)
	if idx <= #str then
		decode_error(str, idx, "trailing garbage")
	end
	return res
end

return json

end

_G.package.loaded["json"] = _loaded_mod_json()

-- module: ".utils"
local function _loaded_mod_utils()
--- The Utils module provides a collection of utility functions for functional programming in Lua. It includes functions for array manipulation such as concatenation, mapping, reduction, filtering, and finding elements, as well as a property equality checker.
-- @module utils

--- The utils table
-- @table utils
-- @field _version The version number of the utils module
-- @field matchesPattern The matchesPattern function
-- @field matchesSpec The matchesSpec function
-- @field curry The curry function
-- @field concat The concat function
-- @field reduce The reduce function
-- @field map The map function
-- @field filter The filter function
-- @field find The find function
-- @field propEq The propEq function
-- @field reverse The reverse function
-- @field compose The compose function
-- @field prop The prop function
-- @field includes The includes function
-- @field keys The keys function
-- @field values The values function
local utils = { _version = "0.0.5" }

--- Given a pattern, a value, and a message, returns whether there is a pattern match.
-- @usage utils.matchesPattern(pattern, value, msg)
-- @param pattern The pattern to match
-- @param value The value to check for in the pattern
-- @param msg The message to check for the pattern
-- @treturn {boolean} Whether there is a pattern match
function utils.matchesPattern(pattern, value, msg)
  -- If the key is not in the message, then it does not match
  if (not pattern) then
    return false
  end
  -- if the patternMatchSpec is a wildcard, then it always matches
  if pattern == '_' then
    return true
  end
  -- if the patternMatchSpec is a function, then it is executed on the tag value
  if type(pattern) == "function" then
    if pattern(value, msg) then
      return true
    else
      return false
    end
  end
  
  -- if the patternMatchSpec is a string, check it for special symbols (less `-` alone)
  -- and exact string match mode
  if (type(pattern) == 'string') then
    if string.match(pattern, "[%^%$%(%)%%%.%[%]%*%+%?]") then
      if string.match(value, pattern) then
        return true
      end
    else
      if value == pattern then
        return true
      end
    end
  end

  -- if the pattern is a table, recursively check if any of its sub-patterns match
  if type(pattern) == 'table' then
    for _, subPattern in pairs(pattern) do
      if utils.matchesPattern(subPattern, value, msg) then
        return true
      end
    end
  end

  return false
end

--- Given a message and a spec, returns whether there is a spec match.
-- @usage utils.matchesSpec(msg, spec)
-- @param msg The message to check for the spec
-- @param spec The spec to check for in the message
-- @treturn {boolean} Whether there is a spec match
function utils.matchesSpec(msg, spec)
  if type(spec) == 'function' then
    return spec(msg)
  -- If the spec is a table, step through every key/value pair in the pattern and check if the msg matches
  -- Supported pattern types:
  --   - Exact string match
  --   - Lua gmatch string
  --   - '_' (wildcard: Message has tag, but can be any value)
  --   - Function execution on the tag, optionally using the msg as the second argument
  --   - Table of patterns, where ANY of the sub-patterns matching the tag will result in a match
  end
  if type(spec) == 'table' then
    for key, pattern in pairs(spec) do
      -- The key can either be in the top level of the 'msg' object or within the 'Tags' 

      local msgValue = msg[key]
      local msgTagValue = msg['Tags'] and msg['Tags'][key]
  
      if not msgValue and not msgTagValue then
        return false
      end
  
      local matchesMsgValue = utils.matchesPattern(pattern, msgValue, msg)
      local matchesMsgTagValue = utils.matchesPattern(pattern, msgTagValue, msg)
  
      if not matchesMsgValue and not matchesMsgTagValue then
        return false
      end
    end
    return true
  end
  
  if type(spec) == 'string' and msg.Action and msg.Action == spec then
    return true
  end
  return false
end

--- Given a table, returns whether it is an array.
-- An 'array' is defined as a table with integer keys starting from 1 and
-- having no gaps between the keys.
-- @lfunction isArray
-- @param table The table to check
-- @treturn {boolean} Whether the table is an array
local function isArray(table)
  if type(table) == "table" then
      local maxIndex = 0
      for k, v in pairs(table) do
          if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
              return false -- If there's a non-integer key, it's not an array
          end
          maxIndex = math.max(maxIndex, k)
      end
      -- If the highest numeric index is equal to the number of elements, it's an array
      return maxIndex == #table
  end
  return false
end

--- Curries a function.
-- @tparam {function} fn The function to curry
-- @tparam {number} arity The arity of the function
-- @treturn {function} The curried function
utils.curry = function (fn, arity)
  assert(type(fn) == "function", "function is required as first argument")
  arity = arity or debug.getinfo(fn, "u").nparams
  if arity < 2 then return fn end

  return function (...)
    local args = {...}

    if #args >= arity then
      return fn(table.unpack(args))
    else
      return utils.curry(function (...)
        return fn(table.unpack(args),  ...)
      end, arity - #args)
    end
  end
end

--- Concat two Array Tables
-- @function concat
-- @usage utils.concat(a)(b)
-- @usage utils.concat({1, 2})({3, 4}) --> {1, 2, 3, 4}
-- @tparam {table<Array>} a The first array
-- @tparam {table<Array>} b The second array
-- @treturn {table<Array>} The concatenated array
utils.concat = utils.curry(function (a, b)
  assert(type(a) == "table", "first argument should be a table that is an array")
  assert(type(b) == "table", "second argument should be a table that is an array")
  assert(isArray(a), "first argument should be a table")
  assert(isArray(b), "second argument should be a table")

  local result = {}
  for i = 1, #a do
      result[#result + 1] = a[i]
  end
  for i = 1, #b do
      result[#result + 1] = b[i]
  end
  return result
end, 2)

--- Applies a function to each element of a table, reducing it to a single value.
-- @function utils.reduce
-- @usage utils.reduce(fn)(initial)(t)
-- @usage utils.reduce(function(acc, x) return acc + x end)(0)({1, 2, 3}) --> 6
-- @tparam {function} fn The function to apply
-- @param initial The initial value
-- @tparam {table<Array>} t The table to reduce
-- @return The reduced value
utils.reduce = utils.curry(function (fn, initial, t)
  assert(type(fn) == "function", "first argument should be a function that accepts (result, value, key)")
  assert(type(t) == "table" and isArray(t), "third argument should be a table that is an array")
  local result = initial
  for k, v in pairs(t) do
    if result == nil then
      result = v
    else
      result = fn(result, v, k)
    end
  end
  return result
end, 3)

--- Applies a function to each element of an array table, mapping it to a new value.
-- @function utils.map
-- @usage utils.map(fn)(t)
-- @usage utils.map(function(x) return x * 2 end)({1, 2, 3}) --> {2, 4, 6}
-- @tparam {function} fn The function to apply to each element
-- @tparam {table<Array>} data The table to map over
-- @treturn {table<Array>} The mapped table
utils.map = utils.curry(function (fn, data)
  assert(type(fn) == "function", "first argument should be a unary function")
  assert(type(data) == "table" and isArray(data), "second argument should be an Array")

  local function map (result, v, k)
    result[k] = fn(v, k)
    return result
  end

  return utils.reduce(map, {}, data)
end, 2)

--- Filters an array table based on a predicate function.
-- @function utils.filter
-- @usage utils.filter(fn)(t)
-- @usage utils.filter(function(x) return x > 1 end)({1, 2, 3}) --> {2,3}
-- @tparam {function} fn The predicate function to determine if an element should be included.
-- @tparam {table<Array>} data The array to filter
-- @treturn {table<Array>} The filtered table
utils.filter = utils.curry(function (fn, data)
  assert(type(fn) == "function", "first argument should be a unary function")
  assert(type(data) == "table" and isArray(data), "second argument should be an Array")

  local function filter (result, v, _k)
    if fn(v) then
      table.insert(result, v)
    end
    return result
  end

  return utils.reduce(filter,{}, data)
end, 2)

--- Finds the first element in an array table that satisfies a predicate function.
-- @function utils.find
-- @usage utils.find(fn)(t)
-- @usage utils.find(function(x) return x > 1 end)({1, 2, 3}) --> 2
-- @tparam {function} fn The predicate function to determine if an element should be included.
-- @tparam {table<Array>} t The array table to search
-- @treturn The first element that satisfies the predicate function
utils.find = utils.curry(function (fn, t)
  assert(type(fn) == "function", "first argument should be a unary function")
  assert(type(t) == "table", "second argument should be a table that is an array")
  for _, v in pairs(t) do
    if fn(v) then
      return v
    end
  end
end, 2)

--- Checks if a property of an object is equal to a value.
-- @function utils.propEq
-- @usage utils.propEq(propName)(value)(object)
-- @usage utils.propEq("name")("Lua")({name = "Lua"}) --> true
-- @tparam {string} propName The property name to check
-- @tparam {string} value The value to check against
-- @tparam {table} object The object to check
-- @treturn {boolean} Whether the property is equal to the value
utils.propEq = utils.curry(function (propName, value, object)
  assert(type(propName) == "string", "first argument should be a string")
  assert(type(value) == "string", "second argument should be a string")
  assert(type(object) == "table", "third argument should be a table<object>")
  
  return object[propName] == value
end, 3)

--- Reverses an array table.
-- @function utils.reverse
-- @usage utils.reverse(data)
-- @usage utils.reverse({1, 2, 3}) --> {3, 2, 1}
-- @tparam {table<Array>} data The array table to reverse
-- @treturn {table<Array>} The reversed array table
utils.reverse = function (data)
  assert(type(data) == "table", "argument needs to be a table that is an array")
  return utils.reduce(
    function (result, v, i)
      result[#data - i + 1] = v
      return result
    end,
    {},
    data
  )
end

--- Composes a series of functions into a single function.
-- @function utils.compose
-- @usage utils.compose(fn1)(fn2)(fn3)(v)
-- @usage utils.compose(function(x) return x + 1 end)(function(x) return x * 2 end)(3) --> 7
-- @tparam {function} ... The functions to compose
-- @treturn {function} The composed function
utils.compose = utils.curry(function (...)
  local mutations = utils.reverse({...})

  return function (v)
    local result = v
    for _, fn in pairs(mutations) do
      assert(type(fn) == "function", "each argument needs to be a function")
      result = fn(result)
    end
    return result
  end
end, 2)

--- Returns the value of a property of an object.
-- @function utils.prop
-- @usage utils.prop(propName)(object)
-- @usage utils.prop("name")({name = "Lua"}) --> "Lua"
-- @tparam {string} propName The property name to get
-- @tparam {table} object The object to get the property from
-- @treturn The value of the property
utils.prop = utils.curry(function (propName, object) 
  return object[propName]
end, 2)

--- Checks if an array table includes a value.
-- @function utils.includes
-- @usage utils.includes(val)(t)
-- @usage utils.includes(2)({1, 2, 3}) --> true
-- @param val The value to check for
-- @tparam {table<Array>} t The array table to check
-- @treturn {boolean} Whether the value is in the array table
utils.includes = utils.curry(function (val, t)
  assert(type(t) == "table", "argument needs to be a table")
  assert(isArray(t), "argument should be a table that is an array")
  return utils.find(function (v) return v == val end, t) ~= nil
end, 2)

--- Returns the keys of a table.
-- @usage utils.keys(t)
-- @usage utils.keys({name = "Lua", age = 25}) --> {"name", "age"}
-- @tparam {table} t The table to get the keys from
-- @treturn {table<Array>} The keys of the table
utils.keys = function (t)
  assert(type(t) == "table", "argument needs to be a table")
  local keys = {}
  for key in pairs(t) do
    table.insert(keys, key)
  end
  return keys
end

--- Returns the values of a table.
-- @usage utils.values(t)
-- @usage utils.values({name = "Lua", age = 25}) --> {"Lua", 25}
-- @tparam {table} t The table to get the values from
-- @treturn {table<Array>} The values of the table
utils.values = function (t)
  assert(type(t) == "table", "argument needs to be a table")
  local values = {}
  for _, value in pairs(t) do
    table.insert(values, value)
  end
  return values
end

return utils
end

_G.package.loaded[".utils"] = _loaded_mod_utils()

-- module: "marketModules.cpmmHelpers"
local function _loaded_mod_marketModules_cpmmHelpers()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local bint = require('.bint')(256)
-- local ao = require('.ao') @dev required for unit tests?

local CPMMHelpers = {}

--- Calculate the ceildiv of x / y
--- @param x number The numerator
--- @param y number The denominator
--- @return number The ceil div of x / y
function CPMMHelpers.ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end

--- Generate position IDs
--- @param outcomeSlotCount number The number of outcome slots
--- @return table<string> A basic partition based on outcomeSlotCount
function CPMMHelpers.getPositionIds(outcomeSlotCount)
  local positionIds = {}
  for i = 1, outcomeSlotCount do
    table.insert(positionIds, tostring(i))
  end
  return positionIds
end

--- Validate add funding
--- Returns funding to sender on error
--- @param from string The address of the sender
--- @param quantity number The amount of funding to add
--- @param distribution table<number>|nil The distribution of funding or `nil`
--- @return boolean True if error
function CPMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''

  if distribution then
    -- Ensure distribution set only for initial funding
    if not error and not bint.iszero(bint(self.token.totalSupply)) then
      error = true
      errorMessage = "Cannot specify distribution after initial funding"
    end
    -- Ensure distribution is set across all position ids
    if not error and #distribution ~= #self.tokens.positionIds then
      error = true
      errorMessage = "Distribution length mismatch"
    end
    if not error then
      -- Ensure distribution content is valid
      local distributionSum = 0
      for i = 1, #distribution do
        if not error and type(distribution[i]) ~= "number" then
          error = true
          errorMessage = "Distribution item must be number"
        else
          distributionSum = distributionSum + distribution[i]
        end
      end
      if not error and distributionSum == 0 then
        error = true
        errorMessage = "Distribution sum must be greater than zero"
      end
    end
  else
    if bint.iszero(bint(self.token.totalSupply)) then
      error = true
      errorMessage = "Must specify distribution for inititial funding"
    end
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = self.tokens.collateralToken,
      Action = 'Transfer',
      Recipient = from,
      Quantity = tostring(quantity),
      ['X-Error'] = 'Add-Funding Error: ' .. errorMessage
    })
  end
  return not error
end

--- Validate remove funding
--- Returns LP tokens to sender on error
--- @param from string The address of the sender
--- @param quantity number The amount of funding to remove
--- @return boolean True if error
function CPMMHelpers:validateRemoveFunding(from, quantity, msg)
  local error = false
  local errorMessage = ""
  -- Get balance
  local balance = self.token.balances[from] or '0'
  if not bint.__le(bint(quantity), bint(balance)) then
    error = true
    errorMessage = "Quantity must be less than balance!"
  end
  if error then
    -- Return funds and assert error
    msg.reply({
      Action = "Remove-Funding-Error",
      Error = errorMessage
    })
  end
  return not error
end

--- Gets pool balances
--- @return table<string> Pool balances for each ID
function CPMMHelpers:getPoolBalances()
  -- Get poolBalances
  local selves = {}
  for _ = 1, #self.tokens.positionIds do
    table.insert(selves, ao.id)
  end
  local poolBalances = self.tokens:getBatchBalance(selves, self.tokens.positionIds)
  return poolBalances
end

return CPMMHelpers
end

_G.package.loaded["marketModules.cpmmHelpers"] = _loaded_mod_marketModules_cpmmHelpers()

-- module: "marketModules.cpmmNotices"
local function _loaded_mod_marketModules_cpmmNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

-- local ao = require('.ao') @dev required for unit tests?
local json = require('json')

local CPMMNotices = {}

--- Sends an add funding notice
--- @param fundingAdded table The funding added
--- @param mintAmount number The mint amount
--- @param msg Message The message received
--- @return Message The funding added notice
function CPMMNotices.addFundingNotice(fundingAdded, mintAmount, msg)
  return msg.forward(msg.Tags.Sender, {
    Action = "Add-Funding-Notice",
    FundingAdded = json.encode(fundingAdded),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

--- Sends a remove funding notice
--- @param sendAmounts table The send amounts
--- @param collateralRemovedFromFeePool string The collateral removed from the fee pool
--- @param sharesToBurn string The shares to burn
--- @param msg Message The message received
--- @return Message The funding removed notice
function CPMMNotices.removeFundingNotice(sendAmounts, collateralRemovedFromFeePool, sharesToBurn, msg)
  return msg.reply({
    Action = "Remove-Funding-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = collateralRemovedFromFeePool,
    SharesToBurn = sharesToBurn,
    Data = "Successfully removed funding"
  })
end

--- Sends a buy notice
--- @param from string The address that bought
--- @param onBehalfOf string The address that receives the outcome tokens
--- @param investmentAmount number The investment amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param positionTokensBought number The outcome position tokens bought
--- @param msg Message The message received
--- @return Message The buy notice
function CPMMNotices.buyNotice(from, onBehalfOf, investmentAmount, feeAmount, positionId, positionTokensBought, msg)
  return msg.forward(from, {
    Action = "Buy-Notice",
    OnBehalfOf = onBehalfOf,
    InvestmentAmount = tostring(investmentAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    PositionTokensBought = tostring(positionTokensBought),
    Data = "Successful buy order"
  })
end

--- Sends a sell notice
--- @param from string The address that sold
--- @param returnAmount number The return amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param positionTokensSold number The outcome position tokens sold
--- @param msg Message The message received
--- @return Message The sell notice
function CPMMNotices.sellNotice(from, returnAmount, feeAmount, positionId, positionTokensSold, msg)
  return msg.forward(from, {
    Action = "Sell-Notice",
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    PositionTokensSold = tostring(positionTokensSold),
    Data = "Successful sell order"
  })
end

--- Sends a withdraw fees notice
--- @notice Returns notice with `msg.reply` if `useReply` is true, otherwise uses `ao.send`
--- @dev Ensures the final notice is sent to the user, preventing unintended message handling 
--- @param feeAmount number The fee amount
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The withdraw fees notice
function CPMMNotices.withdrawFeesNotice(feeAmount, msg, useReply)
  local notice = {
    Action = "Withdraw-Fees-Notice",
    FeeAmount = tostring(feeAmount),
    Data = "Successfully withdrew fees"
  }
  if useReply then return msg.reply(notice) end
  notice.Target = msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Sends an update configurator notice
--- @param configurator string The updated configurator address
--- @param msg Message The message received
--- @return Message The configurator updated notice
function CPMMNotices.updateConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Update-Configurator-Notice",
    Data = configurator
  })
end

--- Sends an update take fee notice
--- @param creatorFee string The updated creator fee
--- @param protocolFee string The updated protocol fee
--- @param takeFee string The updated take fee
--- @param msg Message The message received
function CPMMNotices.updateTakeFeeNotice(creatorFee, protocolFee, takeFee, msg)
  return msg.reply({
    Action = "Update-Take-Fee-Notice",
    CreatorFee = tostring(creatorFee),
    ProtocolFee = tostring(protocolFee),
    Data = tostring(takeFee)
  })
end

--- Sends an update protocol fee target notice
--- @param protocolFeeTarget string The updated protocol fee target
--- @param msg Message The message received
--- @return Message The protocol fee target updated notice
function CPMMNotices.updateProtocolFeeTargetNotice(protocolFeeTarget, msg)
  return msg.reply({
    Action = "Update-Protocol-Fee-Target-Notice",
    Data = protocolFeeTarget
  })
end

--- Sends an update logo notice
--- @param logo string The updated logo
--- @param msg Message The message received
--- @return Message The logo updated notice
function CPMMNotices.updateLogoNotice(logo, msg)
  return msg.reply({
    Action = "Update-Logo-Notice",
    Data = logo
  })
end

return CPMMNotices
end

_G.package.loaded["marketModules.cpmmNotices"] = _loaded_mod_marketModules_cpmmNotices()

-- module: "marketModules.tokenNotices"
local function _loaded_mod_marketModules_tokenNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

-- local ao = require('.ao') @dev required for unit tests?
local TokenNotices = {}

--- Mint notice
--- @param recipient string The address that will own the minted tokens
--- @param quantity string The quantity of tokens to mint
--- @param msg Message The message received
--- @return Message The mint notice
function TokenNotices.mintNotice(recipient, quantity, msg)
  return msg.forward(recipient, {
    Recipient = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

--- Burn notice
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @return Message The burn notice
function TokenNotices.burnNotice(quantity, msg)
  return ao.send({
    Target = msg.Sender and msg.Sender or msg.From,
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

--- Transfer notices
--- @param debitNotice Message The notice to send the spender
--- @param creditNotice Message The notice to send the receiver
--- @param recipient string The address that will receive the tokens
--- @param msg Message The mesage received
--- @return table<Message> The transfer notices
function TokenNotices.transferNotices(debitNotice, creditNotice, recipient, msg)
  return { msg.reply(debitNotice), msg.forward(recipient, creditNotice) }
end

--- Transfer error notice
--- @param msg Message The mesage received
--- @return Message The transfer error notice
function TokenNotices.transferErrorNotice(msg)
  return msg.reply({
    Action = 'Transfer-Error',
    ['Message-Id'] = msg.Id,
    Error = 'Insufficient Balance!'
  })
end

return TokenNotices
end

_G.package.loaded["marketModules.tokenNotices"] = _loaded_mod_marketModules_tokenNotices()

-- module: "marketModules.token"
local function _loaded_mod_marketModules_token()
--[[
================================================================================
Module: token.lua
Adapted from the AO Cookbook Token Blueprint:
https://cookbook_ao.g8way.io/guides/aos/blueprints/token.html
Licensed under the Business Source License 1.1 (BSL 1.1)
================================================================================

Licensor:          Forward Research  
Licensed Work:     aos codebase. The Licensed Work is (c) 2024 Forward Research  
Official License:  https://github.com/permaweb/aos/blob/main/LICENSE  
Additional Use Grant:  
  The aos codebases are offered under the BSL 1.1 license for the duration  
  of the testnet period. After the testnet phase is over, the code will be  
  made available under either a new evolutionary forking license or a  
  traditional OSS license (GPLv3/v2, MIT, etc).  
  More info: https://arweave.medium.com/arweave-is-an-evolutionary-protocol-e072f5e69eaa  
Change Date:       Four years from the date the Licensed Work is published.  
Change License:    MPL 2.0  

Notice:  
This code is provided under the Business Source License 1.1. Redistribution,  
modification, or unauthorized use of this code must comply with the terms of  
the Business Source License.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  
FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
================================================================================
]]

local Token = {}
local TokenMethods = {}
local TokenNotices = require('marketModules.tokenNotices')
local bint = require('.bint')(256)
local json = require("json")

--- Represents a Token
--- @class Token
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logo string The token logo Arweave TxID
--- @field balances table<string, string> The user token balances
--- @field totalSupply string The total supply of the token
--- @field denomination number The number of decimals

--- Creates a new Token instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logo string The token logo Arweave TxID
--- @param balances table<string, string> The user token balances
--- @param totalSupply string The total supply of the token
--- @param denomination number The number of decimals
--- @return Token token The new Token instance
function Token:new(name, ticker, logo, balances, totalSupply, denomination)
  local token = {
    name = name,
    ticker = ticker,
    logo = logo,
    balances = balances,
    totalSupply = totalSupply,
    denomination = denomination
  }
  setmetatable(token, {
    __index = function(_, k)
      if TokenMethods[k] then
        return TokenMethods[k]
      elseif TokenNotices[k] then
        return TokenNotices[k]
      else
        return nil
      end
    end
  })
  return token
end

--- Mint a quantity of tokens
--- @param to string The address that will own the minted tokens
--- @param quantity string The quantity of tokens to mint
--- @param msg Message The message received
--- @return Message The mint notice
function TokenMethods:mint(to, quantity, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- Mint tokens
  if not self.balances[to] then self.balances[to] = '0' end
  self.balances[to] = tostring(bint.__add(bint(self.balances[to]), bint(quantity)))
  self.totalSupply = tostring(bint.__add(bint(self.totalSupply), bint(quantity)))
  -- Send notice
  return self.mintNotice(to, quantity, msg)
end

--- Burn a quantity of tokens
--- @param from string The process ID that will no longer own the burned tokens
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @return Message The burn notice
function TokenMethods:burn(from, quantity, msg)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balances[from], 'Must have token balance!')
  assert(bint.__le(bint(quantity), self.balances[from]), 'Must have sufficient tokens!')
  -- Burn tokens
  self.balances[from] = tostring(bint.__sub(self.balances[from], bint(quantity)))
  self.totalSupply = tostring(bint.__sub(bint(self.totalSupply), bint(quantity)))
  -- Send notice
  return self.burnNotice(quantity, msg)
end

--- Transfer a quantity of tokens
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token 
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function TokenMethods:transfer(from, recipient, quantity, cast, msg)
  if not self.balances[from] then self.balances[from] = "0" end
  if not self.balances[recipient] then self.balances[recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balances[from])

  if bint.__le(qty, balance) then
    self.balances[from] = tostring(bint.__sub(balance, qty))
    self.balances[recipient] = tostring(bint.__add(self.balances[recipient], qty))

    -- Only send the notifications to the Sender and Recipient
    -- if the Cast tag is not set on the Transfer message
    if not cast then
      -- Debit-Notice message template, that is sent to the Sender of the transfer
      local debitNotice = {
        Action = 'Debit-Notice',
        Recipient = recipient,
        Quantity = quantity,
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. quantity .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
      }
      -- Credit-Notice message template, that is sent to the Recipient of the transfer
      local creditNotice = {
        Action = 'Credit-Notice',
        Sender = from,
        Quantity = quantity,
        Data = Colors.gray ..
            "You received " ..
            Colors.blue .. quantity .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
      }

      -- Add forwarded tags to the credit and debit notice messages
      for tagName, tagValue in pairs(msg.Tags) do
        -- Tags beginning with "X-" are forwarded
        if string.sub(tagName, 1, 2) == "X-" then
          debitNotice[tagName] = tagValue
          creditNotice[tagName] = tagValue
        end
      end

      -- Send Debit-Notice and Credit-Notice
      return self.transferNotices(debitNotice, creditNotice, recipient, msg)
    end
  else
    return self.transferErrorNotice(msg)
  end
end

return Token

end

_G.package.loaded["marketModules.token"] = _loaded_mod_marketModules_token()

-- module: "marketModules.constants"
local function _loaded_mod_marketModules_constants()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local constants = {}
local json = require('json')
-- DB
constants.db = {
  intervals = {
    ["1h"] = "1 minute",
    ["6h"] = "1 minute",
    ["1d"] = "5 minutes",
    ["1w"] = "3 hours",
    ["1M"] = "12 hours",
    ["max"] = "1 day"
  },
  rangeDurations = {
    ["1h"] = "1 hour",
    ["6h"] = "6 hours",
    ["1d"] = "1 day",
    ["1w"] = "7 days",
    ["1M"] = "1 month"
  },
  maxInterval = "1 day",
  maxRangeDuration = "100 years",
  defaultLimit = 50,
  defaultOffset = 0,
  defaultActivityWindow = 24,
  moderators = {},
}
-- Market Factory
constants.marketFactory = {
  configurator = "test-this-is-valid-arweave-wallet-address-1",
  incentives = "test-this-is-valid-arweave-wallet-address-2",
  namePrefix = "Outcome Market",
  tickerPrefix = "OUTCOME",
  logo = "https://test.com/logo.png",
  lpFee = "100",
  protocolFee = "250",
  protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-3",
  maximumTakeFee = "500",
  utilityToken = "test-this-is-valid-arweave-wallet-address-4",
  minimumPayment = "1000",
  collateralTokens = {"test-this-is-valid-arweave-wallet-address-5"}
}
-- Market
constants.testMarketConfig = {
  configurator = "test-this-is-valid-arweave-wallet-address-6",
  incentives = "test-this-is-valid-arweave-wallet-address-8",
  collateralToken = "test-this-is-valid-arweave-wallet-address-2",
  conditionId = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
  positionIds = json.encode({"1", "2"}),
  name = "Test Market",
  ticker = "TST",
  logo = "https://test.com/logo.png",
  lpFee = "100",
  creatorFee = "100",
  creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-3",
  protocolFee = "100",
  protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-4"
}
-- Activity
constants.activity = {
  configurator = "test-this-is-valid-arweave-wallet-address-1",
}
-- CPMM
constants.denomination = 12
-- Market Config
constants.marketConfig = {}
constants.marketConfig["DEV"] = {
  configurator = "b9hj1yVw3eWGIggQgJxRDj1t8SZFCezctYD-7U5nYFk",
  incentives = "haUOiKKmYMGum59nWZx5TVFEkDgI5LakIEY7jgfQgAI",
  dataIndex = "rXSAUKwZhJkIBTIEyBl1rf8Gtk_88RKQFsx5JvDOwlE",
  collateralToken = "jAyJBNpuSXmhn9lMMfwDR60TfIPANXI6r-f3n9zucYU",
  resolutionAgent = "ukmrCFkEWdFH_xS4UicCErwCqGT2RJjr1qlk4U720C8",
  creator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  question = "Liquid Ops oUSDC interest reaches 8% in March",
  rules = "Where we're going, we don't need rules",
  category = "Finance",
  sucategory = "Interest Rates",
  positionIds = json.encode({"1","2"}),
  name = "Mock Spawn Market",
  ticker = 'MSM',
  logo = "https://test.com/logo.png",
  lpFee = "100",
  creatorFee = "250",
  creatorFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  protocolFee = "250",
  protocolFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0"
}
constants.marketConfig["PROD"] = {
  configurator = '',
  incentives = '',
  dataIndex = '',
  collateralToken = '',
  question = '',
  positionIds = {},
  name = '',
  ticker = '',
  logo ='',
  lpFee = 0,
  creatorFee = 0,
  creatorFeeTarget = '',
  protocolFee = 0,
  protocolFeeTarget = ''
}

return constants
end

_G.package.loaded["marketModules.constants"] = _loaded_mod_marketModules_constants()

-- module: ".ao"
local function _loaded_mod_ao()
--- The AO module provides functionality for managing the AO environment and handling messages. Returns the ao table.
-- @module ao

local oldao = ao or {}

--- The AO module
-- @table ao
-- @field _version The version number of the ao module
-- @field _module The module id of the process
-- @field id The id of the process
-- @field authorities A table of authorities of the process
-- @field reference The reference number of the process
-- @field outbox The outbox of the process
-- @field nonExtractableTags The non-extractable tags
-- @field nonForwardableTags The non-forwardable tags
-- @field clone The clone function
-- @field normalize The normalize function
-- @field sanitize The sanitize function
-- @field init The init function
-- @field log The log function
-- @field clearOutbox The clearOutbox function
-- @field send The send function
-- @field spawn The spawn function
-- @field assign The assign function
-- @field isTrusted The isTrusted function
-- @field result The result function
local ao = {
    _version = "0.0.6",
    id = oldao.id or "",
    _module = oldao._module or "",
    authorities = oldao.authorities or {},
    reference = oldao.reference or 0,
    outbox = oldao.outbox or
        {Output = {}, Messages = {}, Spawns = {}, Assignments = {}},
    nonExtractableTags = {
        'Data-Protocol', 'Variant', 'From-Process', 'From-Module', 'Type',
        'From', 'Owner', 'Anchor', 'Target', 'Data', 'Tags', 'Read-Only'
    },
    nonForwardableTags = {
        'Data-Protocol', 'Variant', 'From-Process', 'From-Module', 'Type',
        'From', 'Owner', 'Anchor', 'Target', 'Tags', 'TagArray', 'Hash-Chain',
        'Timestamp', 'Nonce', 'Epoch', 'Signature', 'Forwarded-By',
        'Pushed-For', 'Read-Only', 'Cron', 'Block-Height', 'Reference', 'Id',
        'Reply-To'
    }
}

--- Checks if a key exists in a list.
-- @lfunction _includes
-- @tparam {table} list The list to check against
-- @treturn {function} A function that takes a key and returns true if the key exists in the list
local function _includes(list)
    return function(key)
        local exists = false
        for _, listKey in ipairs(list) do
            if key == listKey then
                exists = true
                break
            end
        end
        if not exists then return false end
        return true
    end
end

--- Checks if a table is an array.
-- @lfunction isArray
-- @tparam {table} table The table to check
-- @treturn {boolean} True if the table is an array, false otherwise
local function isArray(table)
    if type(table) == "table" then
        local maxIndex = 0
        for k, v in pairs(table) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                return false -- If there's a non-integer key, it's not an array
            end
            maxIndex = math.max(maxIndex, k)
        end
        -- If the highest numeric index is equal to the number of elements, it's an array
        return maxIndex == #table
    end
    return false
end

--- Pads a number with leading zeros to 32 digits.
-- @lfunction padZero32
-- @tparam {number} num The number to pad
-- @treturn {string} The padded number as a string
local function padZero32(num) return string.format("%032d", num) end

--- Clones a table recursively.
-- @function clone
-- @tparam {any} obj The object to clone
-- @tparam {table} seen The table of seen objects (default is nil)
-- @treturn {any} The cloned object
function ao.clone(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[ao.clone(k, s)] = ao.clone(v, s) end
    return setmetatable(res, getmetatable(obj))
end

--- Normalizes a message by extracting tags.
-- @function normalize
-- @tparam {table} msg The message to normalize
-- @treturn {table} The normalized message
function ao.normalize(msg)
    for _, o in ipairs(msg.Tags) do
        if not _includes(ao.nonExtractableTags)(o.name) then
            msg[o.name] = o.value
        end
    end
    return msg
end

--- Sanitizes a message by removing non-forwardable tags.
-- @function sanitize
-- @tparam {table} msg The message to sanitize
-- @treturn {table} The sanitized message
function ao.sanitize(msg)
    local newMsg = ao.clone(msg)

    for k, _ in pairs(newMsg) do
        if _includes(ao.nonForwardableTags)(k) then newMsg[k] = nil end
    end

    return newMsg
end

--- Initializes the AO environment, including ID, module, authorities, outbox, and environment.
-- @function init
-- @tparam {table} env The environment object
function ao.init(env)
    if ao.id == "" then ao.id = env.Process.Id end

    if ao._module == "" then
        for _, o in ipairs(env.Process.Tags) do
            if o.name == "Module" then ao._module = o.value end
        end
    end

    if #ao.authorities < 1 then
        for _, o in ipairs(env.Process.Tags) do
            if o.name == "Authority" then
                table.insert(ao.authorities, o.value)
            end
        end
    end

    ao.outbox = {Output = {}, Messages = {}, Spawns = {}, Assignments = {}}
    ao.env = env

end

--- Logs a message to the output.
-- @function log
-- @tparam {string} txt The message to log
function ao.log(txt)
    if type(ao.outbox.Output) == 'string' then
        ao.outbox.Output = {ao.outbox.Output}
    end
    table.insert(ao.outbox.Output, txt)
end

--- Clears the outbox.
-- @function clearOutbox
function ao.clearOutbox()
    ao.outbox = {Output = {}, Messages = {}, Spawns = {}, Assignments = {}}
end

--- Sends a message.
-- @function send
-- @tparam {table} msg The message to send
function ao.send(msg)
    assert(type(msg) == 'table', 'msg should be a table')
    ao.reference = ao.reference + 1
    local referenceString = tostring(ao.reference)

    local message = {
        Target = msg.Target,
        Data = msg.Data,
        Anchor = padZero32(ao.reference),
        Tags = {
            {name = "Data-Protocol", value = "ao"},
            {name = "Variant", value = "ao.TN.1"},
            {name = "Type", value = "Message"},
            {name = "Reference", value = referenceString}
        }
    }

    -- if custom tags in root move them to tags
    for k, v in pairs(msg) do
        if not _includes({"Target", "Data", "Anchor", "Tags", "From"})(k) then
            table.insert(message.Tags, {name = k, value = v})
        end
    end

    if msg.Tags then
        if isArray(msg.Tags) then
            for _, o in ipairs(msg.Tags) do
                table.insert(message.Tags, o)
            end
        else
            for k, v in pairs(msg.Tags) do
                table.insert(message.Tags, {name = k, value = v})
            end
        end
    end

    -- If running in an environment without the AOS Handlers module, do not add
    -- the onReply and receive functions to the message.
    if not Handlers then return message end

    -- clone message info and add to outbox
    local extMessage = {}
    for k, v in pairs(message) do extMessage[k] = v end

    -- add message to outbox
    table.insert(ao.outbox.Messages, extMessage)

    -- add callback for onReply handler(s)
    message.onReply =
        function(...) -- Takes either (AddressThatWillReply, handler(s)) or (handler(s))
            local from, resolver
            if select("#", ...) == 2 then
                from = select(1, ...)
                resolver = select(2, ...)
            else
                from = message.Target
                resolver = select(1, ...)
            end

            -- Add a one-time callback that runs the user's (matching) resolver on reply
            Handlers.once({From = from, ["X-Reference"] = referenceString},
                          resolver)
        end

    message.receive = function(...)
        local from = message.Target
        if select("#", ...) == 1 then from = select(1, ...) end
        return
            Handlers.receive({From = from, ["X-Reference"] = referenceString})
    end

    return message
end

--- Spawns a process.
-- @function spawn
-- @tparam {string} module The module source id
-- @tparam {table} msg The message to send
function ao.spawn(module, msg)
    assert(type(module) == "string", "Module source id is required!")
    assert(type(msg) == 'table', 'Message must be a table')
    -- inc spawn reference
    ao.reference = ao.reference + 1
    local spawnRef = tostring(ao.reference)

    local spawn = {
        Data = msg.Data or "NODATA",
        Anchor = padZero32(ao.reference),
        Tags = {
            {name = "Data-Protocol", value = "ao"},
            {name = "Variant", value = "ao.TN.1"},
            {name = "Type", value = "Process"},
            {name = "From-Process", value = ao.id},
            {name = "From-Module", value = ao._module},
            {name = "Module", value = module},
            {name = "Reference", value = spawnRef}
        }
    }

    -- if custom tags in root move them to tags
    for k, v in pairs(msg) do
        if not _includes({"Target", "Data", "Anchor", "Tags", "From"})(k) then
            table.insert(spawn.Tags, {name = k, value = v})
        end
    end

    if msg.Tags then
        if isArray(msg.Tags) then
            for _, o in ipairs(msg.Tags) do
                table.insert(spawn.Tags, o)
            end
        else
            for k, v in pairs(msg.Tags) do
                table.insert(spawn.Tags, {name = k, value = v})
            end
        end
    end

    -- If running in an environment without the AOS Handlers module, do not add
    -- the after and receive functions to the spawn.
    if not Handlers then return spawn end

    -- clone spawn info and add to outbox
    local extSpawn = {}
    for k, v in pairs(spawn) do extSpawn[k] = v end

    table.insert(ao.outbox.Spawns, extSpawn)

    -- add 'after' callback to returned table
    -- local result = {}
    spawn.onReply = function(callback)
        Handlers.once({
            Action = "Spawned",
            From = ao.id,
            ["Reference"] = spawnRef
        }, callback)
    end

    spawn.receive = function()
        return Handlers.receive({
            Action = "Spawned",
            From = ao.id,
            ["Reference"] = spawnRef
        })

    end

    return spawn
end

--- Assigns a message to a process.
-- @function assign
-- @tparam {table} assignment The assignment to assign
function ao.assign(assignment)
    assert(type(assignment) == 'table', 'assignment should be a table')
    assert(type(assignment.Processes) == 'table', 'Processes should be a table')
    assert(type(assignment.Message) == "string", "Message should be a string")
    table.insert(ao.outbox.Assignments, assignment)
end

--- Checks if a message is trusted.
-- The default security model of AOS processes: Trust all and *only* those on the ao.authorities list.
-- @function isTrusted
-- @tparam {table} msg The message to check
-- @treturn {boolean} True if the message is trusted, false otherwise
function ao.isTrusted(msg)
    for _, authority in ipairs(ao.authorities) do
        if msg.From == authority then return true end
        if msg.Owner == authority then return true end
    end
    return false
end

--- Returns the result of the process.
-- @function result
-- @tparam {table} result The result of the process
-- @treturn {table} The result of the process, including Output, Messages, Spawns, and Assignments
function ao.result(result)
    -- if error then only send the Error to CU
    if ao.outbox.Error or result.Error then
        return {Error = result.Error or ao.outbox.Error}
    end
    return {
        Output = result.Output or ao.outbox.Output,
        Messages = ao.outbox.Messages,
        Spawns = ao.outbox.Spawns,
        Assignments = ao.outbox.Assignments
    }
end


--- Add the MatchSpec to the ao.assignables table. A optional name may be provided.
-- This implies that ao.assignables may have both number and string indices.
-- Added in the assignment module.
-- @function addAssignable
-- @tparam ?string|number|any nameOrMatchSpec The name of the MatchSpec
--        to be added to ao.assignables. if a MatchSpec is provided, then
--        no name is included
-- @tparam ?any matchSpec The MatchSpec to be added to ao.assignables. Only provided
--        if its name is passed as the first parameter
-- @treturn ?string|number name The name of the MatchSpec, either as provided
--          as an argument or as incremented
-- @see assignment

--- Remove the MatchSpec, either by name or by index
-- If the name is not found, or if the index does not exist, then do nothing.
-- Added in the assignment module.
-- @function removeAssignable
-- @tparam {string|number} name The name or index of the MatchSpec to be removed
-- @see assignment

--- Return whether the msg is an assignment or not. This can be determined by simply check whether the msg's Target is this process' id
-- Added in the assignment module.
-- @function isAssignment
-- @param msg The msg to be checked
-- @treturn boolean isAssignment
-- @see assignment

--- Check whether the msg matches any assignable MatchSpec.
-- If not assignables are configured, the msg is deemed not assignable, by default.
-- Added in the assignment module.
-- @function isAssignable
-- @param msg The msg to be checked
-- @treturn boolean isAssignable
-- @see assignment

return ao
end

_G.package.loaded[".ao"] = _loaded_mod_ao()

-- module: "marketModules.conditionalTokensNotices"
local function _loaded_mod_marketModules_conditionalTokensNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local json = require('json')
local ao = ao or require('.ao')

local ConditionalTokensNotices = {}

--- Report payouts notice
--- @param resolutionAgent string The process assigned to report the result for the prepared condition
--- @param payoutNumerators table<number> The payout numerators for each outcome slot
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The report payouts notice
function ConditionalTokensNotices.reportPayoutsNotice(resolutionAgent, payoutNumerators, msg)
  return msg.reply({
    Action = "Report-Payouts-Notice",
    ResolutionAgent = resolutionAgent,
    PayoutNumerators = json.encode(payoutNumerators)
  })
end

--- Position split notice
--- @param from string The address of the account that split the position
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param msg Message The message received
--- @return Message The position split notice
function ConditionalTokensNotices.positionSplitNotice(from, collateralToken, quantity, msg)
  local notice = {
    Action = "Split-Position-Notice",
    Process = ao.id,
    Stakeholder = from,
    CollateralToken = collateralToken,
    Quantity = quantity
  }
  -- Forward tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice | @dev ao.send vs msg.reply to ensure message is sent to user (not collateralToken)
  return msg.forward(from, notice)
end

--- Positions merge notice
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The positions merge notice
function ConditionalTokensNotices.positionsMergeNotice(collateralToken, quantity, msg, useReply)
  local notice = {
    Action = "Merge-Positions-Notice",
    CollateralToken = collateralToken,
    Quantity = quantity
  }
  if useReply then return msg.reply(notice) end
  notice.Target = msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Redeem positions notice
--- @param collateralToken string The address of the collateral token
--- @param payout number The payout amount
--- @param netPayout string The net payout amount (after fees)
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensNotices.redeemPositionsNotice(collateralToken, payout, netPayout, msg)
  return msg.reply({
    Action = "Redeem-Positions-Notice",
    CollateralToken = collateralToken,
    GrossPayout = tostring(payout),
    NetPayout = netPayout
  })
end

return ConditionalTokensNotices

end

_G.package.loaded["marketModules.conditionalTokensNotices"] = _loaded_mod_marketModules_conditionalTokensNotices()

-- module: "marketModules.semiFungibleTokensNotices"
local function _loaded_mod_marketModules_semiFungibleTokensNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See semiFungibleTokens.lua for full license details.
=========================================================
]]

-- local ao = require('.ao')
local json = require('json')

local SemiFungibleTokensNotices = {}

--- Mint single notice
--- @param to string The address that will own the minted token
--- @param id string The ID of the token to be minted
--- @param quantity string The quantity of the token to be minted
--- @param msg Message The message received
--- @return Message The mint notice
function SemiFungibleTokensNotices.mintSingleNotice(to, id, quantity, msg)
  return msg.reply({
    Recipient = to,
    PositionId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Mint-Single-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  })
end

--- Mint batch notice
--- @param to string The address that will own the minted tokens
--- @param ids table<string> The IDs of the tokens to be minted
--- @param quantities table<string> The quantities of the tokens to be minted
--- @param msg Message The message received
--- @return Message The batch mint notice
function SemiFungibleTokensNotices.mintBatchNotice(to, ids, quantities, msg)
  return msg.forward(to, {
    Recipient = to,
    PositionIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Action = 'Mint-Batch-Notice',
    Data = "Successfully minted batch"
  })
end

--- Burn single notice
--- @param from string The address that will burn the token
--- @param id string The ID of the token to be burned
--- @param quantity string The quantity of the token to be burned
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The burn notice
function SemiFungibleTokensNotices.burnSingleNotice(from, id, quantity, msg, useReply)
  -- Prepare notice
  local notice = {
    Recipient = from,
    PositionId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Burn-Single-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice
  if useReply then return msg.reply(notice) end
  notice.Target = from
  return ao.send(notice)
end

--- Burn batch notice
--- @param from string The address that will burn the tokens
--- @param positionIds table<string> The IDs of the positions to be burned
--- @param quantities table<string> The quantities of the tokens to be burned
--- @param remainingBalances table<string> The remaining balances of unburned tokens
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The burn notice
function SemiFungibleTokensNotices.burnBatchNotice(from, positionIds, quantities, remainingBalances, msg, useReply)
  -- Prepare notice
  local notice = {
    Recipient = from,
    PositionIds = json.encode(positionIds),
    Quantities = json.encode(quantities),
    RemainingBalances = json.encode(remainingBalances),
    Action = 'Burn-Batch-Notice',
    Data = "Successfully burned batch"
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice
  if useReply then return msg.reply(notice) end
  notice.Target = from
  return ao.send(notice)
end

--- Transfer single token notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param id string The ID of the token to be transferred
--- @param quantity string The quantity of the token to be transferred
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return table<Message> The debit and credit transfer notices
function SemiFungibleTokensNotices.transferSingleNotices(from, to, id, quantity, msg, useReply)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Single-Notice',
    Recipient = to,
    PositionId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " to " .. Colors.green .. to .. Colors.reset
  }
  -- Prepare credit notice
  local creditNotice = {
    Action = 'Credit-Single-Notice',
    Sender = from,
    PositionId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You received " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      debitNotice[tagName] = tagValue
      creditNotice[tagName] = tagValue
    end
  end
  -- Send notices
  if useReply then return { msg.reply(debitNotice), msg.forward(to, creditNotice) } end
  debitNotice.Target = from
  creditNotice.Target = to
  return { ao.send(debitNotice), ao.send(creditNotice) }
end

--- Transfer batch tokens notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param ids table<string> The IDs of the tokens to be transferred
--- @param quantities table<string> The quantities of the tokens to be transferred
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return table<Message> The debit and credit batch transfer notices
function SemiFungibleTokensNotices.transferBatchNotices(from, to, ids, quantities, msg, useReply)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Batch-Notice',
    Recipient = to,
    PositionIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You transferred batch to " .. Colors.green .. to .. Colors.reset
  }
  -- Prepare credit notice
  local creditNotice = {
    Action = 'Credit-Batch-Notice',
    Sender = from,
    PositionIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You received batch from " .. Colors.green .. from .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      debitNotice[tagName] = tagValue
      creditNotice[tagName] = tagValue
    end
  end
  -- Send notice
  if useReply then return { msg.reply(debitNotice), msg.forward(to, creditNotice) } end
  debitNotice.Target = from
  creditNotice.Target = to
  return {ao.send(debitNotice), ao.send(creditNotice)}
end

--- Transfer error notice
--- @param id string The ID of the token to be transferred
--- @param msg Message The message received
--- @return Message The transfer error notice
function SemiFungibleTokensNotices.transferErrorNotice(id, msg)
  return msg.reply({
    Action = 'Transfer-Error',
    ['Message-Id'] = msg.Id,
    ['PositionId'] = id,
    Error = 'Insufficient Balance!'
  })
end

return SemiFungibleTokensNotices

end

_G.package.loaded["marketModules.semiFungibleTokensNotices"] = _loaded_mod_marketModules_semiFungibleTokensNotices()

-- module: "marketModules.semiFungibleTokens"
local function _loaded_mod_marketModules_semiFungibleTokens()
--[[
==============================================================================
Outcome © 2025. MIT License.
Module: semiFungibleTokens.lua
==============================================================================
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
==============================================================================
]]

local SemiFungibleTokens = {}
local SemiFungibleTokensMethods = {}
local SemiFungibleTokensNotices = require('marketModules.semiFungibleTokensNotices')
local bint = require('.bint')(256)
local json = require('json')

-- Represents SemiFungibleTokens
--- @class SemiFungibleTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logo string The token logo Arweave TxID
--- @field balancesById table<string, table<string, string>> The account token balances by ID
--- @field totalSupplyById table<string, string> The total supply of the token by ID
--- @field denomination number The number of decimals

--- Creates a new SemiFungibleTokens instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logo string The token logo Arweave TxID
--- @param balancesById table<string, table<string, string>> The account token balances by ID
--- @param totalSupplyById table<string, string> The total supply of the token by ID
--- @param denomination number The number of decimals
--- @return SemiFungibleTokens semiFungibleTokens The new SemiFungibleTokens instance
function SemiFungibleTokens:new(name, ticker, logo, balancesById, totalSupplyById, denomination)
  local semiFungibleTokens = {
    name = name,
    ticker = ticker,
    logo = logo,
    balancesById = balancesById,
    totalSupplyById = totalSupplyById,
    denomination = denomination
  }
  setmetatable(semiFungibleTokens, {
    __index = function(_, k)
      if SemiFungibleTokensMethods[k] then
        return SemiFungibleTokensMethods[k]
      elseif SemiFungibleTokensNotices[k] then
        return SemiFungibleTokensNotices[k]
      else
        return nil
      end
    end
  })
  return semiFungibleTokens
end

--- Mint a quantity of tokens with the given ID
--- @param to string The address that will own the minted tokens
--- @param id string The ID of the tokens to mint
--- @param quantity string The quantity of tokens to mint
--- @param msg Message The message received
--- @return Message The mint notice
function SemiFungibleTokensMethods:mint(to, id, quantity, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- mint tokens
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][to] then self.balancesById[id][to] = "0" end
  if not self.totalSupplyById[id] then self.totalSupplyById[id] = "0" end
  self.balancesById[id][to] = tostring(bint.__add(self.balancesById[id][to], bint(quantity)))
  self.totalSupplyById[id] = tostring(bint.__add(self.totalSupplyById[id], bint(quantity)))
  -- send notice
  return self.mintSingleNotice(to, id, quantity, msg)
end

--- Batch mint quantities of tokens with the given IDs
--- @param to string The address that will own the minted tokens
--- @param ids table<string> The IDs of the tokens to mint
--- @param quantities table<string> The quantities of tokens to mint
--- @param msg Message The message received
--- @return Message The batch mint notice
function SemiFungibleTokensMethods:batchMint(to, ids, quantities, msg)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  -- mint tokens
  for i = 1, #ids do
    -- @dev spacing to resolve text to code eval issue
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][to] then self.balancesById[ ids[i] ][to] = "0" end
    if not self.totalSupplyById[ ids[i] ] then self.totalSupplyById[ ids[i] ] = "0" end
    self.balancesById[ ids[i] ][to] = tostring(bint.__add(self.balancesById[ ids[i] ][to], quantities[i]))
    self.totalSupplyById[ ids[i] ] = tostring(bint.__add(self.totalSupplyById[ ids[i] ], quantities[i]))
  end
  -- send notice
  return self.mintBatchNotice(to, ids, quantities, msg)
end

--- Burn a quantity of tokens with a given ID
--- @param from string The process ID that will no longer own the burned tokens
--- @param id string The ID of the tokens to burn
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The burn notice
function SemiFungibleTokensMethods:burn(from, id, quantity, msg, useReply)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balancesById[id], 'Id must exist! ' .. id)
  assert(self.balancesById[id][from], 'Account must hold token! :: ' .. id)
  assert(bint.__le(bint(quantity), self.balancesById[id][from]), 'Account must have sufficient tokens! ' .. id)
  -- burn tokens
  self.balancesById[id][from] = tostring(bint.__sub(self.balancesById[id][from], bint(quantity)))
  self.totalSupplyById[id] = tostring(bint.__sub(self.totalSupplyById[id], bint(quantity)))
  -- send notice
  return self.burnSingleNotice(from, id, quantity, msg, useReply)
end

--- Batch burn a quantity of tokens with the given IDs
--- @param from string The process ID that will no longer own the burned tokens
--- @param ids table<string> The IDs of the tokens to burn
--- @param quantities table<string> The quantities of tokens to burn
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The batch burn notice
function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, msg, useReply)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  for i = 1, #ids do
    assert(bint.__lt(0, quantities[i]), 'Quantity must be greater than zero!')
    assert(self.balancesById[ ids[i] ], 'Id must exist! ' .. ids[i])
    assert(self.balancesById[ ids[i] ][from], 'Account must hold token! ' .. ids[i])
    assert(bint.__le(quantities[i], self.balancesById[ ids[i] ][from]), 'Account must have sufficient tokens!')
  end
  -- burn tokens
  local remainingBalances = {}
  for i = 1, #ids do
    self.balancesById[ ids[i] ][from] = tostring(bint.__sub(self.balancesById[ ids[i] ][from], quantities[i]))
    self.totalSupplyById[ ids[i] ] = tostring(bint.__sub(self.totalSupplyById[ ids[i] ], quantities[i]))
    remainingBalances[i] = self.balancesById[ ids[i] ][from]
  end
  -- send notice
  return self.burnBatchNotice(from, ids, quantities, remainingBalances, msg, useReply)
end

--- Transfer a quantity of tokens with the given ID
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param id string The ID of the tokens to transfer
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, msg, useReply)
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][from] then self.balancesById[id][from] = "0" end
  if not self.balancesById[id][recipient] then self.balancesById[id][recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balancesById[id][from])
  if bint.__le(qty, balance) then
    self.balancesById[id][from] = tostring(bint.__sub(balance, qty))
    self.balancesById[id][recipient] = tostring(bint.__add(self.balancesById[id][recipient], qty))

    -- Only send the notifications if the cast tag is not set
    if not cast then
      return self.transferSingleNotices(from, recipient, id, quantity, msg, useReply)
    end
  else
    return self.transferErrorNotice(id, msg)
  end
end

--- Batch transfer quantities of tokens with the given IDs
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param ids table<string> The IDs of the tokens to transfer
--- @param quantities table<string> The quantities of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, msg, useReply)
  local ids_ = {}
  local quantities_ = {}

  for i = 1, #ids do
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][from] then self.balancesById[ ids[i] ][from] = "0" end
    if not self.balancesById[ ids[i] ][recipient] then self.balancesById[ ids[i] ][recipient] = "0" end

    local qty = bint(quantities[i])
    local balance = bint(self.balancesById[ ids[i] ][from])

    if bint.__le(qty, balance) then
      self.balancesById[ ids[i] ][from] = tostring(bint.__sub(balance, qty))
      self.balancesById[ ids[i] ][recipient] = tostring(bint.__add(self.balancesById[ ids[i] ][recipient], qty))
      table.insert(ids_, ids[i])
      table.insert(quantities_, quantities[i])
    else
      return self.transferErrorNotice(ids[i], msg)
    end
  end

  -- Only send the notifications if the cast tag is not set
  if not cast and #ids_ > 0 then
    return self.transferBatchNotices(from, recipient, ids_, quantities_, msg, useReply)
  end
end

--- Get account balance of tokens with the given ID
--- @param sender string The process ID of the sender
--- @param recipient string|nil The process ID of the recipient (optional)
--- @param id string The ID of the token
--- @return string The balance of the account for the given ID
function SemiFungibleTokensMethods:getBalance(sender, recipient, id)
  local bal = '0'
  -- If ID is found then continue
  if self.balancesById[id] then
    -- If recipient is not provided, return the senders balance
    if (recipient and self.balancesById[id][recipient]) then
      bal = self.balancesById[id][recipient]
    elseif self.balancesById[id][sender] then
      bal = self.balancesById[id][sender]
    end
  end
  -- return balance
  return bal
end

--- Get accounts' balance of tokens with the given IDs
--- @param recipients table<string> The process IDs of the recipients
--- @param ids table<string> The IDs of the tokens
--- @return table<string> The balances of the recipients for each respective ID
function SemiFungibleTokensMethods:getBatchBalance(recipients, ids)
  assert(#recipients == #ids, 'Recipients and Ids must have same lengths')
  local bals = {}

  for i = 1, #recipients do
    table.insert(bals, '0')
    if self.balancesById[ ids[i] ] then
      if self.balancesById[ ids[i] ][ recipients[i] ] then
        bals[i] = self.balancesById[ ids[i] ][ recipients[i] ]
      end
    end
  end

  return bals
end

--- Get account balances of tokens with the given ID
--- @param id string The ID of the token
--- @return table<string, string> The account balances for the given ID
function SemiFungibleTokensMethods:getBalances(id)
  local bals = {}
  if self.balancesById[id] then
    bals = self.balancesById[id]
  end
  -- return balances
  return bals
end

--- Get accounts' balances of tokens with the given IDs
--- @param positionIds table<string> The IDs of the tokens
--- @return table<string, table<string, string>> The account balances for each respective ID
function SemiFungibleTokensMethods:getBatchBalances(positionIds)
  local bals = {}

  for i = 1, #positionIds do
    bals[ positionIds[i] ] = {}
    if self.balancesById[ positionIds[i] ] then
      bals[ positionIds[i] ] = self.balancesById[ positionIds[i] ]
    end
  end
  -- return balances
  return bals
end

return SemiFungibleTokens

end

_G.package.loaded["marketModules.semiFungibleTokens"] = _loaded_mod_marketModules_semiFungibleTokens()

-- module: "marketModules.conditionalTokens"
local function _loaded_mod_marketModules_conditionalTokens()
--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local ConditionalTokens = {}
local ConditionalTokensMethods = {}
local ConditionalTokensNotices = require('marketModules.conditionalTokensNotices')
local SemiFungibleTokens = require('marketModules.semiFungibleTokens')
local bint = require('.bint')(256)
local crypto = require('.crypto')
local json = require("json")
local ao = ao or require('.ao')

--- Represents ConditionalTokens
--- @class ConditionalTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logo string The token logo Arweave TxID
--- @field balancesById table<string, table<string, string>> The account token balances by ID
--- @field totalSupplyById table<string, string> The total supply of the token by ID
--- @field denomination number The number of decimals
--- @field resolutionAgent string The process ID of the resolution agent
--- @field collateralToken string The process ID of the collateral token
--- @field positionIds table<string> The position IDs representing outcomes
--- @field payoutNumerators table<number> The relative payouts for each outcome slot
--- @field payoutDenominator number The sum of payout numerators, zero if unreported
--- @field creatorFee number The creator fee to be paid, in basis points
--- @field creatorFeeTarget string The process ID to receive the creator fee
--- @field protocolFee number The protocol fee to be paid, in basis points
--- @field protocolFeeTarget string The process ID to receive the protocol fee

--- Creates a new ConditionalTokens instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logo string The token logo Arweave TxID
--- @param balancesById table<string, table<string, string>> The account token balances by ID
--- @param totalSupplyById table<string, string> The total supply of the token by ID
--- @param denomination number The number of decimals
--- @param resolutionAgent string The process ID of the resolution agent
--- @param collateralToken string The process ID of the collateral token
--- @param positionIds table<string> The position IDs representing outcomes
--- @param creatorFee number The creator fee to be paid, in basis points
--- @param creatorFeeTarget string The process ID to receive the creator fee
--- @param protocolFee number The protocol fee to be paid, in basis points
--- @param protocolFeeTarget string The process ID to receive the protocol fee
--- @return ConditionalTokens conditionalTokens The new ConditionalTokens instance
function ConditionalTokens:new(
  name,
  ticker,
  logo,
  balancesById,
  totalSupplyById,
  denomination,
  resolutionAgent,
  collateralToken,
  positionIds,
  creatorFee,
  creatorFeeTarget,
  protocolFee,
  protocolFeeTarget
)
  ---@class ConditionalTokens : SemiFungibleTokens
  local conditionalTokens = SemiFungibleTokens:new(name, ticker, logo, balancesById, totalSupplyById, denomination)
  conditionalTokens.resolutionAgent = resolutionAgent
  conditionalTokens.collateralToken = collateralToken
  conditionalTokens.positionIds = positionIds
  conditionalTokens.creatorFee = tonumber(creatorFee) or 0
  conditionalTokens.creatorFeeTarget = creatorFeeTarget
  conditionalTokens.protocolFee = tonumber(protocolFee) or 0
  conditionalTokens.protocolFeeTarget = protocolFeeTarget
  conditionalTokens.payoutDenominator = 0
  -- Initialize the payout vector as zeros.
  conditionalTokens.payoutNumerators = {}
  for _ = 1, #positionIds do
    table.insert(conditionalTokens.payoutNumerators, 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  conditionalTokens.payoutDenominator = 0

  local semiFungibleTokensMetatable = getmetatable(conditionalTokens)
  setmetatable(conditionalTokens, {
    __index = function(_, k)
      if ConditionalTokensMethods[k] then
        return ConditionalTokensMethods[k]
      elseif ConditionalTokensNotices[k] then
        return ConditionalTokensNotices[k]
      else
        -- Fallback directly to the parent metatable
        return semiFungibleTokensMetatable.__index(_, k)
      end
    end
  })
  return conditionalTokens
end

--- Split position
--- @param from string The process ID of the account that split the position
--- @param collateralToken string The process ID of the collateral token
--- @param quantity string The quantity of collateral to split
--- @param msg Message The message received
--- @return Message The position split notice
function ConditionalTokensMethods:splitPosition(from, collateralToken, quantity, msg)
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "Condition not prepared!")
  -- Create equal split positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Mint the stake in the split target positions.
  self:batchMint(from, self.positionIds, quantities, msg)
  -- Send notice.
  return self.positionSplitNotice(from, collateralToken, quantity, msg)
end

--- Merge positions
--- @param from string The process ID of the account that merged the positions
--- @param onBehalfOf string The process ID of the account that will receive the collateral
--- @param quantity string The quantity of collateral to merge
--- @param isSell boolean True if the merge is a sell, false otherwise
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The positions merge notice
function ConditionalTokensMethods:mergePositions(from, onBehalfOf, quantity, isSell, msg, useReply)
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "Condition not prepared!")
  -- Create equal merge positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Burn equal quantiies from user positions.
  self:batchBurn(from, self.positionIds, quantities, msg, false)
  -- @dev below already handled within the sell method. 
  -- sell method w/ a different quantity and recipient.
  if not isSell then
    -- Return the collateral to the user.
    ao.send({
      Target = self.collateralToken,
      Action = "Transfer",
      Quantity = quantity,
      Recipient = onBehalfOf
    })
  end
  -- Send notice.
  return self.positionsMergeNotice(self.collateralToken, quantity, msg, useReply)
end

--- Report payouts
--- @param payouts table<number> The resolution agent's answer
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The report payouts notice
function ConditionalTokensMethods:reportPayouts(payouts, msg)
  assert(#payouts == #self.positionIds, "Payouts must match outcome slot count!")
  assert(msg.From == self.resolutionAgent, "Sender not resolution agent!")
  assert(self.payoutDenominator == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, #self.positionIds do
    local num = payouts[i]
    den = den + num
    assert(self.payoutNumerators[i] == 0, "payout numerator already set")
    self.payoutNumerators[i] = num
  end
  assert(den > 0, "payout is all zeroes")
  self.payoutDenominator = den
  -- Send notice.
  return self.reportPayoutsNotice(msg.From, self.payoutNumerators, msg)
end

--- Redeem positions
--- Transfers any payout minus fees to the message sender
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensMethods:redeemPositions(msg)
  local den = self.payoutDenominator
  assert(den > 0, "market not resolved")
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "market not initialized")
  local totalPayout = 0
  local totalPayoutMinusFee = "0"
  for i = 1, #self.positionIds do
    local positionId = self.positionIds[i]
    local payoutNumerator = self.payoutNumerators[tonumber(positionId)]
    -- Get the stake to redeem.
    if not self.balancesById[positionId] then self.balancesById[positionId] = {} end
    if not self.balancesById[positionId][msg.From] then self.balancesById[positionId][msg.From] = "0" end
    local payoutStake = self.balancesById[positionId][msg.From]
    if bint.__lt(0, bint(payoutStake)) then
      -- Calculate the payout and burn position.
      totalPayout = math.floor(totalPayout + (payoutStake * payoutNumerator) / den)
      self:burn(msg.From, positionId, payoutStake, msg, false)
    end
  end
  -- Return total payout minus take fee.
  if totalPayout > 0 then
    totalPayout = math.floor(totalPayout)
    totalPayoutMinusFee = self:returnTotalPayoutMinusTakeFee(self.collateralToken, msg.From, totalPayout, msg)
  end
  -- Send notice.
  return self.redeemPositionsNotice(self.collateralToken, totalPayout, totalPayoutMinusFee, msg)
end

--- Return total payout minus take fee
--- Distributes payout and fees to the redeem account, creator and protocol
--- @param collateralToken string The collateral token
--- @param from string The account to receive the payout minus fees
--- @param totalPayout number The total payout assciated with the acount stake
--- @param msg Message The message received
--- @return string The total payout minus fee amount
function ConditionalTokensMethods:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout, msg)
  local protocolFee =  tostring(bint.ceil(bint.__div(bint.__mul(totalPayout, self.protocolFee), 1e4)))
  local creatorFee =  tostring(bint.ceil(bint.__div(bint.__mul(totalPayout, self.creatorFee), 1e4)))
  local takeFee = tostring(bint.__add(bint(creatorFee), bint(protocolFee)))
  local totalPayoutMinusFee = tostring(bint.__sub(totalPayout, bint(takeFee)))
  -- prepare txns
  local protocolFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = self.protocolFeeTarget,
    Quantity = protocolFee,
  }
  local creatorFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = self.creatorFeeTarget,
    Quantity = creatorFee,
  }
  local totalPayoutMinutTakeFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = from,
    Quantity = totalPayoutMinusFee
  }
  -- send txns
  ao.send(protocolFeeTxn)
  ao.send(creatorFeeTxn)
  ao.send(totalPayoutMinutTakeFeeTxn)

  return totalPayoutMinusFee
end

return ConditionalTokens

end

_G.package.loaded["marketModules.conditionalTokens"] = _loaded_mod_marketModules_conditionalTokens()

-- module: "marketModules.cpmm"
local function _loaded_mod_marketModules_cpmm()
--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local CPMM = {}
local CPMMMethods = {}
local CPMMHelpers = require('marketModules.cpmmHelpers')
local CPMMNotices = require('marketModules.cpmmNotices')
local bint = require('.bint')(256)
local json = require('json')
-- local ao = require('.ao') @dev required for unit tests?
local utils = require(".utils")
local token = require('marketModules.token')
local constants = require("marketModules.constants")
local conditionalTokens = require('marketModules.conditionalTokens')

--- Represents a CPMM (Constant Product Market Maker)
--- @class CPMM
--- @field configurator string The process ID of the configurator
--- @field poolBalances table<string, ...> The pool balance for each respective position ID
--- @field withdrawnFees table<string, string> The amount of fees withdrawn by an account
--- @field feePoolWeight string The total amount of fees collected
--- @field totalWithdrawnFees string The total amount of fees withdrawn

--- Creates a new CPMM instance
--- @param configurator string The process ID of the configurator
--- @param collateralToken string The process ID of the collateral token
--- @param resolutionAgent string The process ID of the resolution agent
--- @param positionIds table<string, ...> The position IDs
--- @param name string The CPMM token(s) name 
--- @param ticker string The CPMM token(s) ticker 
--- @param logo string The CPMM token(s) logo 
--- @param lpFee number The liquidity provider fee
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @return CPMM cpmm The new CPMM instance 
function CPMM:new(configurator, collateralToken, resolutionAgent, positionIds, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget)
  local cpmm = {
    configurator = configurator,
    poolBalances = {},
    withdrawnFees = {},
    feePoolWeight = "0",
    totalWithdrawnFees = "0",
    lpFee = tonumber(lpFee)
  }
  cpmm.token = token:new(
    name .. " LP Token",
    ticker,
    logo,
    {}, -- balances
    "0", -- totalSupply
    constants.denomination
  )
  cpmm.tokens = conditionalTokens:new(
    name .. " Conditional Tokens",
    ticker,
    logo,
    {}, -- balancesById
    {}, -- totalSupplyById
    constants.denomination,
    resolutionAgent,
    collateralToken,
    positionIds,
    creatorFee,
    creatorFeeTarget,
    protocolFee,
    protocolFeeTarget
  )
  setmetatable(cpmm, {
    __index = function(_, k)
      if CPMMMethods[k] then
        return CPMMMethods[k]
      elseif CPMMHelpers[k] then
        return CPMMHelpers[k]
      elseif CPMMNotices[k] then
        return CPMMNotices[k]
      else
        return nil
      end
    end
  })
  return cpmm
end

--- Add funding
--- @param onBehalfOf string The process ID of the account to receive the LP tokens
--- @param addedFunds string The amount of funds to add
--- @param distributionHint table<number> The initial probability distribution
--- @param msg Message The message received
--- @return Message The funding added notice
function CPMMMethods:addFunding(onBehalfOf, addedFunds, distributionHint, msg)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")
  local sendBackAmounts = {}
  local poolShareSupply = self.token.totalSupply
  local mintAmount = '0'

  if bint.iszero(bint(poolShareSupply)) then
    assert(distributionHint, "must use distribution hint for initial funding")
    -- Initial Liquidity
    if #distributionHint > 0 then
      local maxHint = 0
      for i = 1, #distributionHint do
        local hint = distributionHint[i]
        if maxHint < hint then
          maxHint = hint
        end
      end
      -- Calculate sendBackAmounts
      for i = 1, #distributionHint do
        local remaining = math.floor((addedFunds * distributionHint[i]) / maxHint)
        assert(remaining > 0, "must hint a valid distribution")
        sendBackAmounts[i] = addedFunds - remaining
      end
    end
    -- Calculate mintAmount
    mintAmount = tostring(addedFunds)
  else
    -- Additional Liquidity 
    assert(not distributionHint, "cannot use distribution hint after initial funding")
    -- Get poolBalances
    local poolBalances = self:getPoolBalances()
    -- Calculate poolWeight
    local poolWeight = 0
    for i = 1, #poolBalances do
      local balance = poolBalances[i]
      if bint.__lt(poolWeight, bint(balance)) then
        poolWeight = bint(balance)
      end
    end
    -- Calculate sendBackAmounts
    for i = 1, #poolBalances do
      local remaining = math.floor((addedFunds * poolBalances[i]) / poolWeight)
      sendBackAmounts[i] = addedFunds - remaining
    end
    -- Calculate mintAmount
    ---@diagnostic disable-next-line: param-type-mismatch
    mintAmount = tostring(math.floor(tostring(bint.__div(bint.__mul(addedFunds, poolShareSupply), poolWeight))))
  end
  -- Mint Conditional Positions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, addedFunds, msg)
  -- Mint LP Tokens
  self:mint(onBehalfOf, mintAmount, msg)
  -- Remove non-zero items before transfer-batch
  local nonZeroAmounts = {}
  local nonZeroPositionIds = {}
  for i = 1, #sendBackAmounts do
    if sendBackAmounts[i] > 0 then
      table.insert(nonZeroAmounts, tostring(math.floor(sendBackAmounts[i])))
      table.insert(nonZeroPositionIds, self.tokens.positionIds[i])
    end
  end
  -- Send back conditional tokens should there be an uneven distribution
  if #nonZeroAmounts ~= 0 then
    self.tokens:transferBatch(ao.id, onBehalfOf, nonZeroPositionIds, nonZeroAmounts, true, msg)
  end
  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end
  -- Send notice with amounts added
  return self.addFundingNotice(sendBackAmounts, mintAmount, msg)
end

--- Remove funding
--- @param from string The process ID of the account that removed the funding
--- @param sharesToBurn string The amount of shares to burn
--- @param msg Message The message received
--- @return Message The funding removed notice
function CPMMMethods:removeFunding(from, sharesToBurn, msg)
  assert(bint.__lt(0, bint(sharesToBurn)), "funding must be non-zero")
  -- Get poolBalances
  local poolBalances = self:getPoolBalances()
  -- Calculate sendAmounts
  local sendAmounts = {}
  for i = 1, #poolBalances do
    sendAmounts[i] = tostring(math.floor((poolBalances[i] * sharesToBurn) / self.token.totalSupply))
  end
  -- Calculate collateralRemovedFromFeePool
  local collateralRemovedFromFeePool = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  self:burn(from, sharesToBurn, msg)
  local poolFeeBalance = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  collateralRemovedFromFeePool = tostring(math.floor(poolFeeBalance - collateralRemovedFromFeePool))
  -- Send collateralRemovedFromFeePool
  if bint(collateralRemovedFromFeePool) > 0 then
    ao.send({Target = self.tokens.collateralToke, Action = "Transfer", Recipient=from, Quantity=collateralRemovedFromFeePool})
  end
  -- Send conditionalTokens amounts
  self.tokens:transferBatch(ao.id, from, self.tokens.positionIds, sendAmounts, false, msg)
  -- Send notice
  return self.removeFundingNotice(sendAmounts, collateralRemovedFromFeePool, sharesToBurn, msg)
end

--- Calc buy amount
--- @param investmentAmount number The amount to stake on an outcome
--- @param positionId string The position ID of the outcome
--- @return string The amount of tokens to be purchased
function CPMMMethods:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__lt(0, investmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(utils.includes(positionId, self.tokens.positionIds), 'PositionId must be valid!')

  local poolBalances = self:getPoolBalances()
  local investmentAmountMinusFees = investmentAmount - ((investmentAmount * self.lpFee) / 1e4) -- converts fee from basis points to decimal
  local buyTokenPoolBalance = poolBalances[tonumber(positionId)]
  local endingOutcomeBalance = buyTokenPoolBalance * 1e4

  for i = 1, #poolBalances do
    if not bint.__eq(bint(i), bint(positionId)) then
      local poolBalance = poolBalances[i]
      endingOutcomeBalance = CPMMHelpers.ceildiv(endingOutcomeBalance * poolBalance, poolBalance + investmentAmountMinusFees)
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(buyTokenPoolBalance + investmentAmountMinusFees - CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4)))
end

--- Calc sell amount
--- @param returnAmount number The amount to unstake from an outcome
---@param positionId string The position ID of the outcome
---@return string The amount of tokens to be sold
function CPMMMethods:calcSellAmount(returnAmount, positionId)
  assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
  assert(utils.includes(positionId, self.tokens.positionIds), 'PositionId must be valid!')

  local poolBalances = self:getPoolBalances()
  local returnAmountPlusFees = CPMMHelpers.ceildiv(returnAmount * 1e4, 1e4 - self.lpFee)
  local sellTokenPoolBalance = poolBalances[tonumber(positionId)]
  local endingOutcomeBalance = sellTokenPoolBalance * 1e4

  for i = 1, #poolBalances do
    if not bint.__eq(bint(i), bint(positionId)) then
      local poolBalance = poolBalances[i]
      assert(poolBalance - returnAmountPlusFees > 0, "PoolBalance must be greater than return amount plus fees!")
      endingOutcomeBalance = CPMMHelpers.ceildiv(endingOutcomeBalance * poolBalance, poolBalance - returnAmountPlusFees)
    end
  end

  assert(endingOutcomeBalance > 0, "must have non-zero balances")
  return tostring(bint.ceil(returnAmountPlusFees + CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4) - sellTokenPoolBalance))
end

--- Calc probabilities
--- @return table<string, number> probabilities A table mapping each positionId to its probability (as a decimal percentage)
function CPMMMethods:calcProbabilities()
  local poolBalances = self:getPoolBalances()
  local totalBalance = bint(0)
  local probabilities = {}
  -- Calculate total balance
  for i = 1, #self.tokens.positionIds do
    totalBalance = bint.__add(totalBalance, bint(poolBalances[i]))
  end
  assert(bint.__lt(bint(0), totalBalance), 'Total pool balance must be greater than zero!')
  -- Calculate probabilities for each positionId
  for i = 1, #self.tokens.positionIds do
    local positionId = self.tokens.positionIds[i]
    local balance = bint(poolBalances[i])
    local probability = tostring(bint.__div(balance, totalBalance))
    probabilities[positionId] = probability
  end
  return probabilities
end

--- Buy
--- @param from string The process ID of the account that initiates the buy
--- @param onBehalfOf string The process ID of the account to receive the tokens
--- @param investmentAmount number The amount to stake on an outcome
--- @param positionId string The position ID of the outcome
--- @param minPositionTokensToBuy number The minimum number of outcome tokens to buy
--- @param msg Message The message received
--- @return Message The buy notice
function CPMMMethods:buy(from, onBehalfOf, investmentAmount, positionId, minPositionTokensToBuy, msg)
  local positionTokensToBuy = self:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__le(minPositionTokensToBuy, bint(positionTokensToBuy)), "Minimum position tokens not reached!")
  -- Calculate investmentAmountMinusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.lpFee), 1e4)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, investmentAmountMinusFees, msg)
  -- Transfer buy position to onBehalfOf
  self.tokens:transferSingle(ao.id, onBehalfOf, positionId, positionTokensToBuy, true, msg, false)
  -- Send notice.
  return self.buyNotice(from, onBehalfOf, investmentAmount, feeAmount, positionId, positionTokensToBuy, msg)
end

--- Sell
--- @param from string The process ID of the account that initiates the sell
--- @param returnAmount number The amount to unstake from an outcome
--- @param positionId string The position ID of the outcome
--- @param maxPositionTokensToSell number The max outcome tokens to sell
--- @return Message The sell notice
function CPMMMethods:sell(from, returnAmount, positionId, maxPositionTokensToSell, msg)
  -- Calculate outcome tokens to sell.
  local positionTokensToSell = self:calcSellAmount(returnAmount, positionId)
  assert(bint.__le(bint(positionTokensToSell), bint(maxPositionTokensToSell)), "Maximum sell amount exceeded!")
  -- Calculate returnAmountPlusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, self.lpFee), bint.__sub(1e4, self.lpFee))))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))
  -- Check sufficient liquidity within the process or revert.
  local collataralBalance = ao.send({Target = self.tokens.collateralToken, Action = "Balance", ["X-Action"] = "Check Liquidity"}).receive().Data
  assert(bint.__le(bint(returnAmountPlusFees), bint(collataralBalance)), "Insufficient liquidity!")
  -- Check user balance and transfer positionTokensToSell to process before merge.
  local balance = self.tokens:getBalance(from, nil, positionId)
  assert(bint.__le(bint(positionTokensToSell), bint(balance)), 'Insufficient balance!')
  self.tokens:transferSingle(from, ao.id, positionId, positionTokensToSell, true, msg, false)
  -- Merge positions through all conditions (burns returnAmountPlusFees).
  self.tokens:mergePositions(ao.id, '', positionTokensToSell, true, msg, false)
  -- Returns collateral to the user
  msg.forward(self.tokens.collateralToken,{
    Action = "Transfer",
    Quantity = tostring(returnAmount),
    Recipient = from
  })
  -- Send notice (Process continued via "SellOrderCompletionCollateralToken" and "SellOrderCompletionConditionalTokens" handlers)
  return self.sellNotice(from, returnAmount, feeAmount, positionId, positionTokensToSell, msg)
end

--- Colleced fees
--- @return string The total unwithdrawn fees collected by the CPMM
function CPMMMethods:collectedFees()
  return tostring(math.ceil(self.feePoolWeight - self.totalWithdrawnFees))
end

--- Fees withdrawable 
--- @param account string The process ID of the account
--- @return string The fees withdrawable by the account
function CPMMMethods:feesWithdrawableBy(account)
  local balance = self.token.balances[account] or '0'
  local rawAmount = '0'
  if bint(self.token.totalSupply) > 0 then
    rawAmount = string.format('%.0f', (bint.__div(bint.__mul(bint(self:collectedFees()), bint(balance)), self.token.totalSupply)))
  end
  return tostring(bint.max(bint(bint.__sub(bint(rawAmount), bint(self.withdrawnFees[account] or '0'))), 0))
end

--- Withdraw fees
--- @param sender string The process ID of the sender
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The withdraw fees message
function CPMMMethods:withdrawFees(sender, msg, useReply)
  local feeAmount = self:feesWithdrawableBy(sender)
  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
    msg.forward(self.tokens.collateralToken, {Action = 'Transfer', Recipient = sender, Quantity = feeAmount})
  end
  return self.withdrawFeesNotice(feeAmount, msg, useReply)
end

--- Before token transfer
--- Updates fee accounting before token transfers
--- @param from string|nil The process ID of the account executing the transaction
--- @param to string|nil The process ID of the account receiving the transaction
--- @param amount string The amount transferred
--- @param msg Message The message received
function CPMMMethods:_beforeTokenTransfer(from, to, amount, msg)
  if from ~= nil and from ~= ao.id then
    self:withdrawFees(from, msg, false)
  end
  local totalSupply = self.token.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), bint(amount)), totalSupply)))

  if from ~= nil and to ~= nil and from ~= ao.id then
    self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), bint(withdrawnFeesTransfer)))
    self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), bint(withdrawnFeesTransfer)))
  end
end

--- @dev See `Mint` in modules.token 
function CPMMMethods:mint(to, quantity, msg)
  self:_beforeTokenTransfer(nil, to, quantity, msg)
  return self.token:mint(to, quantity, msg)
end

--- @dev See `Burn` in modules.token 
-- @dev See tokenMethods:burn & _beforeTokenTransfer
function CPMMMethods:burn(from, quantity, msg)
  self:_beforeTokenTransfer(from, nil, quantity, msg)
  return self.token:burn(from, quantity, msg)
end

--- @dev See `Transfer` in modules.token 
-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function CPMMMethods:transfer(from, recipient, quantity, cast, msg)
  self:_beforeTokenTransfer(from, recipient, quantity, msg)
  return self.token:transfer(from, recipient, quantity, cast, msg)
end

--- Update configurator
--- @param configurator string The process ID of the new configurator
--- @param msg Message The message received
--- @return Message The update configurator notice
function CPMMMethods:updateConfigurator(configurator, msg)
  self.configurator = configurator
  return self.updateConfiguratorNotice(configurator, msg)
end

--- Update take fee
--- @param creatorFee string The new creator fee in basis points
--- @param protocolFee string The new protocol fee in basis points
--- @param msg Message The message received
--- @return Message The update take fee notice
function CPMMMethods:updateTakeFee(creatorFee, protocolFee, msg)
  self.tokens.creatorFee = creatorFee
  self.tokens.protocolFee = protocolFee
  return self.updateTakeFeeNotice(creatorFee, protocolFee, creatorFee + protocolFee, msg)
end

--- Update protocol fee targer
--- @param target string The process ID of the new protocol fee target
--- @param msg Message The message received
--- @return Message The update protocol fee target notice
function CPMMMethods:updateProtocolFeeTarget(target, msg)
  self.tokens.protocolFeeTarget = target
  return self.updateProtocolFeeTargetNotice(target, msg)
end

--- Update logo
--- @param logo string The Arweave transaction ID of the new logo
--- @param msg Message The message received
--- @return Message The update logo notice
function CPMMMethods:updateLogo(logo, msg)
  self.token.logo = logo
  self.tokens.logo = logo
  return self.updateLogoNotice(logo, msg)
end

return CPMM
end

_G.package.loaded["marketModules.cpmm"] = _loaded_mod_marketModules_cpmm()

-- module: "marketModules.sharedUtils"
local function _loaded_mod_marketModules_sharedUtils()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local sharedUtils = {}

--- Verify if extracted value is a JSON simple value
--- @param value any
--- @return boolean
local function isSimpleValue(value)
  -- Trim whitespace
  value = value:match("^%s*(.-)%s*$") or value
  -- Check for a quoted string: "someValue"
  if value:match('^"[^"]*"$') then
    return true
  end
  -- Check for a number (integer or float, optional minus sign): 123, -123, 123.45
  if value:match('^[-]?%d+%.?%d*$') then
    return true
  end
  -- Check for boolean
  if string.lower(value) == "true" or string.lower(value) == "false" then
    return true
  end
  return false
end

--- Verify if a valid JSON object
--- @param str any
--- @return boolean
function sharedUtils.isValidKeyValueJSON(str)
  if type(str) ~= "string" then return false end
  -- Trim whitespace
  str = str:match("^%s*(.-)%s*$")
  -- Ensure it starts with `{` and ends with `}`
  local isObject = str:match("^%{%s*(.-)%s*%}$")
  if not isObject then return false end
  -- This pattern only extracts the key and the entire raw value
  local keyValuePattern = '^%s*"([^"]+)"%s*:%s*(.-)%s*$'
  -- Check all key-value pairs
  for keyValue in isObject:gmatch("[^,]+") do
    local key, rawValue = keyValue:match(keyValuePattern)
    if not key or not rawValue then
      return false
    end
    -- Now validate that rawValue is a valid JSON simple value
    if not isSimpleValue(rawValue) then
      return false
    end
  end
  return true
end

--- Verify if a valid JSON array
--- @param str any
--- @return boolean
function sharedUtils.isJSONArray(str)
  if type(str) ~= "string" then return false end
  -- Trim whitespace
  str = str:match("^%s*(.-)%s*$")
  -- Ensure it starts with `[` and ends with `]`
  local isArray = str:match("^%[%s*(.-)%s*%]$")
  if not isArray then return false end
  -- Split the array elements and validate each one
  for value in isArray:gmatch("[^,]+") do
    value = value:match("^%s*(.-)%s*$") -- Trim whitespace around each value
    if not isSimpleValue(value) then
      return false
    end
  end
  return true
end

--- Verify if a valid Arweave address
--- @param address any
--- @return boolean
function sharedUtils.isValidArweaveAddress(address)
	return type(address) == "string" and #address == 43 and string.match(address, "^[%w-_]+$") ~= nil
end

--- Verify if a valid boolean string
--- @param value any
--- @return boolean
function sharedUtils.isValidBooleanString(value)
  return type(value) == "string" and (string.lower(value) == "true" or string.lower(value) == "false")
end

return sharedUtils
end

_G.package.loaded["marketModules.sharedUtils"] = _loaded_mod_marketModules_sharedUtils()

-- module: "marketModules.sharedValidation"
local function _loaded_mod_marketModules_sharedValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local sharedValidation = {}
local sharedUtils = require('marketModules.sharedUtils')
local utils = require('.utils')

--- Validates address
--- @param address any The address to be validated
--- @param tagName string The name of the tag being validated
function sharedValidation.validateAddress(address, tagName)
  assert(type(address) == 'string', tagName .. ' is required!')
  assert(sharedUtils.isValidArweaveAddress(address), tagName .. ' must be a valid Arweave address!')
end

--- Validates array item
--- @param item any The item to be validated
--- @param validItems table<string> The array of valid items
--- @param tagName string The name of the tag being validated
function sharedValidation.validateItem(item, validItems, tagName)
  assert(type(item) == 'string', tagName .. ' is required!')
  assert(utils.includes(item, validItems), 'Invalid ' .. tagName .. '!')
end

--- Validates positive integer
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
function sharedValidation.validatePositiveInteger(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

--- Validates positive integer or zero
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
function sharedValidation.validatePositiveIntegerOrZero(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) >= 0, tagName .. ' must be greater than or equal to zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

return sharedValidation
end

_G.package.loaded["marketModules.sharedValidation"] = _loaded_mod_marketModules_sharedValidation()

-- module: "marketModules.cpmmValidation"
local function _loaded_mod_marketModules_cpmmValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local cpmmValidation = {}
local sharedValidation = require('marketModules.sharedValidation')
local sharedUtils = require('marketModules.sharedUtils')
local bint = require('.bint')(256)
local json = require('json')

--- Validates add funding
--- @param msg Message The message to be validated
function cpmmValidation.addFunding(msg)
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates remove funding
--- @param msg Message The message to be validated
function cpmmValidation.removeFunding(msg)
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates buy
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.buy(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "X-PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  sharedValidation.validatePositiveInteger(msg.Tags["X-MinPositionTokensToBuy"], "X-MinPositionTokensToBuy")
end

--- Validates sell
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.sell(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.MaxPositionTokensToSell, "MaxPositionTokensToSell")
  sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

--- Validates calc buy amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcBuyAmount(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

--- Validates calc sell amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcSellAmount(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

--- Validates update configurator
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateConfigurator(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.Configurator, 'Configurator')
end

--- Validates update take fee
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateTakeFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, 'CreatorFee')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, 'ProtocolFee')
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Net fee must be less than or equal to 1000 bps')
end

--- Validates update protocol fee target
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateProtocolFeeTarget(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.ProtocolFeeTarget, 'ProtocolFeeTarget is required!')
end

--- Validates update logo
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateLogo(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')
end

return cpmmValidation
end

_G.package.loaded["marketModules.cpmmValidation"] = _loaded_mod_marketModules_cpmmValidation()

-- module: "marketModules.tokenValidation"
local function _loaded_mod_marketModules_tokenValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

local tokenValidation = {}
local sharedValidation = require('marketModules.sharedValidation')

--- Validates a transfer message
--- @param msg Message The message received
function tokenValidation.transfer(msg)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

return tokenValidation
end

_G.package.loaded["marketModules.tokenValidation"] = _loaded_mod_marketModules_tokenValidation()

-- module: "marketModules.marketValidation"
local function _loaded_mod_marketModules_marketValidation()
local MarketValidation = {}
local sharedValidation = require('marketModules.sharedValidation')

--- Validates update data index
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function MarketValidation.updateDataIndex(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.DataIndex, 'DataIndex')
end

--- Validates update incentives
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function MarketValidation.updateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.Incentives, 'Incentives')
end

return MarketValidation
end

_G.package.loaded["marketModules.marketValidation"] = _loaded_mod_marketModules_marketValidation()

-- module: "marketModules.semiFungibleTokensValidation"
local function _loaded_mod_marketModules_semiFungibleTokensValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See semiFungibleTokens.lua for full license details.
=========================================================
]]

local semiFungibleTokensValidation = {}
local sharedValidation = require('marketModules.sharedValidation')
local json = require("json")

--- Validates a transferSingle message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferSingle(msg, validPositionIds)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates a transferBatch message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferBatch(msg, validPositionIds)
  sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  assert(type(msg.Tags.PositionIds) == 'string', 'PositionIds is required!')
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#positionIds == #quantities, 'Input array lengths must match!')
  assert(#positionIds > 0, "Input array length must be greater than zero!")
  for i = 1, #positionIds do
    sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    sharedValidation.validatePositiveInteger(quantities[i], "Quantity")
  end
end

--- Validates a balanceById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balanceById(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

--- Validates a balancesById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balancesById(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

--- Validates a batchBalance message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalance(msg, validPositionIds)
  assert(msg.Tags.Recipients, "Recipients is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#recipients == #positionIds, "Input array lengths must match!")
  assert(#recipients > 0, "Input array length must be greater than zero!")
  for i = 1, #positionIds do
    sharedValidation.validateAddress(recipients[i], 'Recipient')
    sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
  end
end

--- Validates a batchBalances message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalances(msg, validPositionIds)
  assert(msg.Tags.PositionIds, "PositionIds is required!")
  local positionIds = json.decode(msg.Tags.PositionIds)
  assert(#positionIds > 0, "Input array length must be greater than zero!")
  for i = 1, #positionIds do
    sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
  end
end

return semiFungibleTokensValidation
end

_G.package.loaded["marketModules.semiFungibleTokensValidation"] = _loaded_mod_marketModules_semiFungibleTokensValidation()

-- module: "marketModules.conditionalTokensValidation"
local function _loaded_mod_marketModules_conditionalTokensValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local ConditionalTokensValidation = {}
local sharedUtils = require('marketModules.sharedUtils')
local json = require('json')

--- Validates quantity
--- @param quantity any The quantity to be validated
local function validateQuantity(quantity)
  assert(type(quantity) == 'string', 'Quantity is required!')
  assert(tonumber(quantity), 'Quantity must be a number!')
  assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
end

--- Validates payouts
--- @param payouts any The payouts to be validated
local function validatePayouts(payouts)
  assert(payouts, "Payouts is required!")
  assert(sharedUtils.isJSONArray(payouts), "Payouts must be valid JSON Array!")
  for _, payout in ipairs(json.decode(payouts)) do
    assert(tonumber(payout), "Payouts item must be a number!")
  end
end

--- Validates the mergePositions message
--- @param msg Message The message to be validated
function ConditionalTokensValidation.mergePositions(msg)
  validateQuantity(msg.Tags.Quantity)
end

--- Validates the reporrtPayouts message
--- @param msg Message The message to be validated
--- @param resolutionAgent string The resolution agent process ID
function ConditionalTokensValidation.reportPayouts(msg, resolutionAgent)
  assert(msg.From == resolutionAgent, "Sender must be resolution agent!")
  validatePayouts(msg.Tags.Payouts)
end

return ConditionalTokensValidation
end

_G.package.loaded["marketModules.conditionalTokensValidation"] = _loaded_mod_marketModules_conditionalTokensValidation()

-- module: "marketModules.market"
local function _loaded_mod_marketModules_market()
--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local Market = {}
local MarketMethods = {}
local MarketNotices = require('marketModules.marketNotices')
-- local ao = require('.ao') @dev required for unit tests?
local json = require('json')
local bint = require('.bint')(256)
local utils = require('.utils')
local cpmm = require('marketModules.cpmm')
local cpmmValidation = require('marketModules.cpmmValidation')
local tokenValidation = require('marketModules.tokenValidation')
local marketValidation = require('marketModules.marketValidation')
local semiFungibleTokensValidation = require('marketModules.semiFungibleTokensValidation')
local conditionalTokensValidation = require('marketModules.conditionalTokensValidation')

--- Represents a Market
--- @class Market
--- @field cpmm CPMM The Constant Product Market Maker

--- Creates a new Market instance
--- @param configurator string The process ID of the configurator
--- @param incentives string The process ID of the incentives controller
--- @param dataIndex string The process ID of the data index process
--- @param collateralToken string The process ID of the collateral token
--- @param resolutionAgent string The process ID of the resolution agent
--- @param creator string The address of the market creator
--- @param question string The market question
--- @param rules string The market rules
--- @param category string The market category
--- @param subcategory string The market subcategory
--- @param positionIds table<string, ...> The position IDs
--- @param name string The CPMM token(s) name 
--- @param ticker string The CPMM token(s) ticker 
--- @param logo string The CPMM token(s) logo 
--- @param lpFee number The liquidity provider fee
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @return Market market The new Market instance 
function Market:new(
  configurator,
  incentives,
  dataIndex,
  collateralToken,
  resolutionAgent,
  creator,
  question,
  rules,
  category,
  subcategory,
  positionIds,
  name,
  ticker,
  logo,
  lpFee,
  creatorFee,
  creatorFeeTarget,
  protocolFee,
  protocolFeeTarget
)
  local market = {
    cpmm = cpmm:new(
      configurator,
      collateralToken,
      resolutionAgent,
      positionIds,
      name,
      ticker,
      logo,
      lpFee,
      creatorFee,
      creatorFeeTarget,
      protocolFee,
      protocolFeeTarget
    ),
    question = question,
    rules = rules,
    category = category,
    subcategory = subcategory,
    creator = creator,
    incentives = incentives,
    dataIndex = dataIndex
  }
  setmetatable(market, {
    __index = function(_, k)
      if MarketMethods[k] then
        return MarketMethods[k]
      elseif MarketNotices[k] then
        return MarketNotices[k]
      else
        return nil
      end
    end
  })
  return market
end

--- Info
--- @param msg Message The message received
--- @return Message The info message
function MarketMethods:info(msg)
  return msg.reply({
    Name = self.cpmm.token.name,
    Ticker = self.cpmm.token.ticker,
    Logo = self.cpmm.token.logo,
    Denomination = tostring(self.cpmm.token.denomination),
    PositionIds = json.encode(self.cpmm.tokens.positionIds),
    CollateralToken = self.cpmm.tokens.collateralToken,
    Configurator = self.cpmm.configurator,
    Incentives = self.incentives,
    DataIndex = self.dataIndex,
    ResolutionAgent = self.cpmm.tokens.resolutionAgent,
    Question = self.question,
    Rules = self.rules,
    Category = self.category,
    Subcategory = self.subcategory,
    Creator = self.creator,
    LpFee = tostring(self.cpmm.lpFee),
    LpFeePoolWeight = self.cpmm.feePoolWeight,
    LpFeeTotalWithdrawn = self.cpmm.totalWithdrawnFees,
    CreatorFee = tostring(self.cpmm.tokens.creatorFee),
    CreatorFeeTarget = self.cpmm.tokens.creatorFeeTarget,
    ProtocolFee = tostring(self.cpmm.tokens.protocolFee),
    ProtocolFeeTarget = self.cpmm.tokens.protocolFeeTarget
  })
end

--[[
=============
ACTIVITY LOGS
=============
]]

local function logFunding(incentives, dataIndex, user, operation, collateral, quantity, msg)
  -- log funding for incentives
  ao.send({
    Target = incentives,
    Action = 'Log-Funding',
    User = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity
  })
  -- log funding for dataIndex
  return msg.forward(dataIndex, {
    Action = "Log-Funding",
    User = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity,
  })
end

local function logPrediction(incentives, dataIndex, user, operation, collateral, quantity, outcome, shares, price, msg)
  -- log prediction for incentives
  ao.send({
    Target = incentives,
    Action = 'Log-Prediction',
    User = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity
  })
  -- log prediction for dataIndex
  return msg.forward(dataIndex, {
    Action = "Log-Prediction",
    User = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity,
    Outcome = outcome,
    Shares = shares,
    Price = price
  })
end

local function logProbabilities(dataIndex, probabilities, msg)
  return msg.forward(dataIndex, {
    Action = "Log-Probabilities",
    Probabilities = json.encode(probabilities)
  })
end

--[[
==================
CPMM WRITE METHODS
==================
]]

--- Add funding
--- Message forwarded from the collateral token
--- @param msg Message The message received
--- @return nil -- TODO: send/specify notice
function MarketMethods:addFunding(msg)
  cpmmValidation.addFunding(msg)
  local distribution = msg.Tags['X-Distribution'] and json.decode(msg.Tags['X-Distribution']) or nil
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  -- @dev returns collateral tokens if invalid
  if self.cpmm:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    self.cpmm:addFunding(onBehalfOf, msg.Tags.Quantity, distribution, msg)
    -- log funding
    logFunding(self.incentives, self.dataIndex, msg.Tags.Sender, 'add', self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg)
  end
end

--- Remove funding
--- Message forwarded from the LP token
--- @param msg Message The message received
--- @return nil -- TODO: send/specify notice
function MarketMethods:removeFunding(msg)
  cpmmValidation.removeFunding(msg)
  -- @dev returns LP tokens if invalid
  if self.cpmm:validateRemoveFunding(msg.From, msg.Tags.Quantity, msg) then
    self.cpmm:removeFunding(msg.From, msg.Tags.Quantity, msg)
    -- log funding
    logFunding(self.incentives, self.dataIndex, msg.From, 'remove', self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg)
  end
end

--- Buy
--- Message forwarded from the collateral token
--- @param msg Message The message received
--- @return Message buyNotice The buy notice
function MarketMethods:buy(msg)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender

  local error = false
  local errorMessage = ''

  local positionTokensToBuy = '0'

  if not msg.Tags['X-PositionId'] then
    error = true
    errorMessage = 'X-PositionId is required!'
  elseif not utils.includes(msg.Tags['X-PositionId'], self.cpmm.tokens.positionIds) then
    error = true
    errorMessage = 'Invalid X-PositionId!'
  elseif not msg.Tags['X-MinPositionTokensToBuy'] then
    error = true
    errorMessage = 'X-MinPositionTokensToBuy is required!'
  else
    positionTokensToBuy = self.cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])
    if not bint.__le(bint(msg.Tags['X-MinPositionTokensToBuy']), bint(positionTokensToBuy)) then
      error = true
      errorMessage = 'minimum buy amount not reached'
    end
  end
  -- @dev returns collateral tokens on error
  if error then
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      Error = 'Buy Error: ' .. errorMessage
    })
    assert(false, errorMessage)
  end
  local notice = self.cpmm:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinPositionTokensToBuy']), msg)
  -- log prediction and probabilities
  local price = tostring(bint.__div(bint(positionTokensToBuy), bint(msg.Tags.Quantity)))
  logPrediction(self.incentives, self.dataIndex, onBehalfOf, "buy", self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg.Tags['X-PositionId'], positionTokensToBuy, price, msg)
  logProbabilities(self.dataIndex, self.cpmm:calcProbabilities(), msg)
  return notice
end

--- Sell
--- @param msg Message The message received
--- @return Message sellNotice The sell notice
function MarketMethods:sell(msg)
  cpmmValidation.sell(msg, self.cpmm.tokens.positionIds)
  local positionTokensToSell = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  assert(bint.__le(bint(positionTokensToSell), bint(msg.Tags.MaxPositionTokensToSell)), 'Max position tokens to sell not sufficient!')
  local notice = self.cpmm:sell(msg.From, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.MaxPositionTokensToSell, msg)
  -- log prediction and probabilities
  local price = tostring(bint.__div(positionTokensToSell, bint(msg.Tags.ReturnAmount)))
  logPrediction(self.incentives, self.dataIndex, msg.From, "sell", self.cpmm.tokens.collateralToken, msg.Tags.ReturnAmount, msg.Tags.PositionId, positionTokensToSell, price, msg)
  logProbabilities(self.dataIndex, self.cpmm:calcProbabilities(), msg)
  return notice
end

--- Withdraw fees
--- @param msg Message The message received
--- @return Message withdrawFees The amount withdrawn
function MarketMethods:withdrawFees(msg)
  return self.cpmm:withdrawFees(msg.From, msg, true)
end

--[[
=================
CPMM READ METHODS
=================
]]

--- Calc buy amount
--- @param msg Message The message received
--- @return Message calcBuyAmountNotice The calc buy amount notice
function MarketMethods:calcBuyAmount(msg)
  cpmmValidation.calcBuyAmount(msg, self.cpmm.tokens.positionIds)
  local buyAmount = self.cpmm:calcBuyAmount(msg.Tags.InvestmentAmount, msg.Tags.PositionId)
  return msg.reply({
    BuyAmount = buyAmount,
    PositionId =  msg.Tags.PositionId,
    InvestmentAmount = msg.Tags.InvestmentAmount,
    Data = buyAmount
  })
end

--- Calc sell amount
--- @param msg Message The message received
--- @return Message calcSellAmountNotice The calc sell amount notice
function MarketMethods:calcSellAmount(msg)
  cpmmValidation.calcSellAmount(msg, self.cpmm.tokens.positionIds)
  local sellAmount = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  return msg.reply({
    SellAmount = sellAmount,
    PositionId = msg.Tags.PositionId,
    ReturnAmount = msg.Tags.ReturnAmount,
    Data = sellAmount
  })
end

--- Colleced fees
--- @return Message collectedFees The total unwithdrawn fees collected by the CPMM
function MarketMethods:collectedFees(msg)
  local fees = self.cpmm:collectedFees()
  return msg.reply({
    CollectedFees = fees,
    Data = fees
  })
end

--- Fees withdrawable 
--- @param msg Message The message received
--- @return Message feesWithdrawable The fees withdrawable by the account
function MarketMethods:feesWithdrawable(msg)
  local account = msg.Tags['Recipient'] or msg.From
  local fees = self.cpmm:feesWithdrawableBy(account)
  return msg.reply({
    FeesWithdrawable = fees,
    Account = account,
    Data = fees
  })
end

--[[
======================
LP TOKEN WRITE METHODS
======================
]]

--- Transfer
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferNotices The transfer notices, error notice or nothing
function MarketMethods:transfer(msg)
  tokenValidation.transfer(msg)
  return self.cpmm:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg)
end

--[[
=====================
LP TOKEN READ METHODS
=====================
]]

--- Balance
--- @param msg Message The message received
--- @return Message balance The balance of the account
function MarketMethods:balance(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (self.cpmm.token.balances[msg.Tags.Recipient]) then
      bal = self.cpmm.token.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and self.cpmm.token.balances[msg.Tags.Target] then
    bal = self.cpmm.token.balances[msg.Tags.Target]
  elseif self.cpmm.token.balances[msg.From] then
    bal = self.cpmm.token.balances[msg.From]
  end

  return msg.reply({
    Balance = bal,
    Ticker = self.cpmm.token.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end

--- Balances
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
function MarketMethods:balances(msg)
  return msg.reply({ Data = json.encode(self.cpmm.token.balances) })
end

--- Total supply
--- @param msg Message The message received
--- @return Message totalSupply The total supply of the LP token
function MarketMethods:totalSupply(msg)
  return msg.reply({ Data = json.encode(self.cpmm.token.totalSupply) })
end

--[[
================================
CONDITIONAL TOKENS WRITE METHODS
================================
]]

--- Merge positions
--- @param msg Message The message received
--- @return Message mergePositionsNotice The positions merge notice or error message
function MarketMethods:mergePositions(msg)
  conditionalTokensValidation.mergePositions(msg)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  -- Check user balances
  local error = false
  local errorMessage = ''
  for i = 1, #self.cpmm.tokens.positionIds do
    if not error then
      if not self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ] then
        error = true
        errorMessage = "Invalid position! PositionId: " .. self.cpmm.tokens.positionIds[i]
      elseif not self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ][msg.From] then
        error = true
        errorMessage = "Invalid user position! PositionId: " .. self.cpmm.tokens.positionIds[i]
      elseif bint.__lt(bint(self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ][msg.From]), bint(msg.Tags.Quantity)) then
        error = true
        errorMessage = "Insufficient tokens! PositionId: " .. self.cpmm.tokens.positionIds[i]
      end
    end
  end
  -- Revert on error
  if error then
    return msg.reply({
      Action = 'Merge-Positions-Error',
      Error = errorMessage,
      Data = errorMessage
    })
  end
  return self.cpmm.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, false, msg, true)
end

--- Report payouts
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The condition resolution notice 
-- TODO: sync on naming conventions
function MarketMethods:reportPayouts(msg)
  conditionalTokensValidation.reportPayouts(msg, self.cpmm.tokens.resolutionAgent)
  local payouts = json.decode(msg.Tags.Payouts)
  return self.cpmm.tokens:reportPayouts(payouts, msg)
end

--- Redeem positions
--- @param msg Message The message received
--- @return Message payoutRedemptionNotice The payout redemption notice
function MarketMethods:redeemPositions(msg)
  return self.cpmm.tokens:redeemPositions(msg)
end

--[[
===============================
CONDITIONAL TOKENS READ METHODS
===============================
]]

--- Get payout numerators
--- @param msg Message The message received
--- @return Message payoutNumerators payout numerators for the condition
function MarketMethods:getPayoutNumerators(msg)
  return msg.reply({ Data = json.encode(self.cpmm.tokens.payoutNumerators) })
end

--- Get payout denominator
--- @param msg Message The message received
--- @return Message payoutDenominator The payout denominator for the condition
function MarketMethods:getPayoutDenominator(msg)
  return msg.reply({ Data = tostring(self.cpmm.tokens.payoutDenominator) })
end

--[[
==================================
SEMI-FUNGIBLE TOKENS WRITE METHODS
==================================
]]

--- Transfer single
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferSingleNotices The transfer notices, error notice or nothing
function MarketMethods:transferSingle(msg)
  semiFungibleTokensValidation.transferSingle(msg, self.cpmm.tokens.positionIds)
  return self.cpmm.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.PositionId, msg.Tags.Quantity, msg.Tags.Cast, msg, true)
end

--- Transfer batch
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferBatchNotices The transfer notices, error notice or nothing
function MarketMethods:transferBatch(msg)
  semiFungibleTokensValidation.transferBatch(msg, self.cpmm.tokens.positionIds)
  local positionIds = json.decode(msg.Tags.PositionIds)
  local quantities = json.decode(msg.Tags.Quantities)
  return self.cpmm.tokens:transferBatch(msg.From, msg.Tags.Recipient, positionIds, quantities, msg.Tags.Cast, msg, true)
end

--[[
=================================
SEMI-FUNGIBLE TOKENS READ METHODS
=================================
]]

--- Balance by ID
--- @param msg Message The message received
--- @return Message balanceById The balance of the account filtered by ID
function MarketMethods:balanceById(msg)
  semiFungibleTokensValidation.balanceById(msg, self.cpmm.tokens.positionIds)
  local account = msg.Tags.Recipient or msg.From
  local bal = self.cpmm.tokens:getBalance(msg.From, account, msg.Tags.PositionId)
  return msg.reply({
    Balance = bal,
    PositionId = msg.Tags.PositionId,
    Account = account,
    Data = bal
  })
end

--- Balances by ID
--- @param msg Message The message received
--- @return Message balancesById The balances of all accounts filtered by ID
function MarketMethods:balancesById(msg)
  semiFungibleTokensValidation.balancesById(msg, self.cpmm.tokens.positionIds)
  local bals = self.cpmm.tokens:getBalances(msg.Tags.PositionId)
  return msg.reply({
    PositionId = msg.Tags.PositionId,
    Data = json.encode(bals)
  })
end

--- Batch balance
--- @param msg Message The message received
--- @return Message batchBalance The balance accounts filtered by IDs
function MarketMethods:batchBalance(msg)
  semiFungibleTokensValidation.batchBalance(msg, self.cpmm.tokens.positionIds)
  local recipients = json.decode(msg.Tags.Recipients)
  local positionIds = json.decode(msg.Tags.PositionIds)
  local bals = self.cpmm.tokens:getBatchBalance(recipients, positionIds)
  return msg.reply({
    PositionIds = msg.Tags.PositionIds,
    Accounts = msg.Tags.Recipients,
    Data = json.encode(bals)
  })
end

--- Batch balances
--- @param msg Message The message received
--- @return Message batchBalances The balances of all accounts filtered by IDs
function MarketMethods:batchBalances(msg)
  semiFungibleTokensValidation.batchBalances(msg, self.cpmm.tokens.positionIds)
  local positionIds = json.decode(msg.Tags.PositionIds)
  local bals = self.cpmm.tokens:getBatchBalances(positionIds)
  return msg.reply({ Data = json.encode(bals) })
end

--- Balances all
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
function MarketMethods:balancesAll(msg)
  return msg.reply({ Data = json.encode(self.cpmm.tokens.balancesById) })
end

--[[
==========================
CONFIGURATOR WRITE METHODS
==========================
]]

--- Update configurator
--- @param msg Message The message received
--- @return Message configuratorUpdateNotice The configurator update notice
function MarketMethods:updateConfigurator(msg)
  cpmmValidation.updateConfigurator(msg, self.cpmm.configurator)
  return self.cpmm:updateConfigurator(msg.Tags.Configurator, msg)
end

--- Update data index
--- @param msg Message The message received
--- @return Message dataIndexUpdateNotice The incentives update notice
function MarketMethods:updateDataIndex(msg)
  marketValidation.updateDataIndex(msg, self.cpmm.configurator)
  self.dataIndex = msg.Tags.DataIndex
  return self.updateDataIndexNotice(msg.Tags.DataIndex, msg)
end

--- Update incentives
--- @param msg Message The message received
--- @return Message incentivesUpdateNotice The incentives update notice
function MarketMethods:updateIncentives(msg)
  marketValidation.updateIncentives(msg, self.cpmm.configurator)
  self.incentives = msg.Tags.Incentives
  return self.updateIncentivesNotice(msg.Tags.Incentives, msg)
end

--- Update take fee
--- @param msg Message The message received
--- @return Message takeFeeUpdateNotice The take fee update notice
function MarketMethods:updateTakeFee(msg)
  cpmmValidation.updateTakeFee(msg, self.cpmm.configurator)
  return self.cpmm:updateTakeFee(tonumber(msg.Tags.CreatorFee), tonumber(msg.Tags.ProtocolFee), msg)
end

--- Update protocol fee target
--- @param msg Message The message received
--- @return Message protocolTargetUpdateNotice The protocol fee target update notice
function MarketMethods:updateProtocolFeeTarget(msg)
  cpmmValidation.updateProtocolFeeTarget(msg, self.cpmm.configurator)
  return self.cpmm:updateProtocolFeeTarget(msg.Tags.ProtocolFeeTarget, msg)
end

--- Update logo
--- @param msg Message The message received
--- @return Message logoUpdateNotice The logo update notice
function MarketMethods:updateLogo(msg)
  cpmmValidation.updateLogo(msg, self.cpmm.configurator)
  return self.cpmm:updateLogo(msg.Tags.Logo, msg)
end

return Market

end

_G.package.loaded["marketModules.market"] = _loaded_mod_marketModules_market()

--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local market = require('marketModules.market')
local constants = require('marketModules.constants')
local json = require('json')

--[[
======
MARKET
======
]]

Env = "DEV"
Version = "1.0.1"

--- Represents the Market Configuration  
--- @class MarketConfiguration  
--- @field configurator string The Configurator process ID  
--- @field incentives string The Incentives process ID  
--- @field dataIndex string The Data Index process ID
--- @field collateralToken string The Collateral Token process ID  
--- @field resolutionAgent string The Resolution Agent process ID
--- @field creator string The Creator address
--- @field question string The Market question 
--- @field rules string The Market rules
--- @field category string The Market category
--- @field subcategory string The Market subcategory
--- @field positionIds table<string> The Position process IDs  
--- @field name string The Market name  
--- @field ticker string The Market ticker  
--- @field logo string The Market logo  
--- @field lpFee number The LP fee  
--- @field creatorFee number The Creator fee  
--- @field creatorFeeTarget string The Creator fee target  
--- @field protocolFee number The Protocol fee  
--- @field protocolFeeTarget string The Protocol fee target  

--- Retrieve Market Configuration  
--- Fetches configuration parameters from the environment, set by the market factory
--- @return MarketConfiguration marketConfiguration The market configuration  
local function retrieveMarketConfig()
  local config = {
    configurator = ao.env.Process.Tags.Configurator or constants.marketConfig[Env].configurator,
    incentives = ao.env.Process.Tags.Incentives or constants.marketConfig[Env].incentives,
    dataIndex = ao.env.Process.Tags.DataIndex or constants.marketConfig[Env].dataIndex,
    collateralToken = ao.env.Process.Tags.CollateralToken or constants.marketConfig[Env].collateralToken,
    resolutionAgent = ao.env.Process.Tags.ResolutionAgent or constants.marketConfig[Env].resolutionAgent,
    creator = ao.env.Process.Tags.Creator or constants.marketConfig[Env].creator,
    question = ao.env.Process.Tags.Question or constants.marketConfig[Env].question,
    rules = ao.env.Process.Tags.Rules or constants.marketConfig[Env].rules,
    category = ao.env.Process.Tags.Category or constants.marketConfig[Env].category,
    subcategory = ao.env.Process.Tags.Subcategory or constants.marketConfig[Env].subcategory,
    positionIds = json.decode(ao.env.Process.Tags.PositionIds or constants.marketConfig[Env].positionIds),
    name = ao.env.Process.Tags.Name or constants.marketConfig[Env].name,
    ticker = ao.env.Process.Tags.Ticker or constants.marketConfig[Env].ticker,
    logo = ao.env.Process.Tags.Logo or constants.marketConfig[Env].logo,
    lpFee = tonumber(ao.env.Process.Tags.LpFee or constants.marketConfig[Env].lpFee),
    creatorFee = tonumber(ao.env.Process.Tags.CreatorFee or constants.marketConfig[Env].creatorFee),
    creatorFeeTarget = ao.env.Process.Tags.CreatorFeeTarget or constants.marketConfig[Env].creatorFeeTarget,
    protocolFee = tonumber(ao.env.Process.Tags.ProtocolFee or constants.marketConfig[Env].protocolFee),
    protocolFeeTarget = ao.env.Process.Tags.ProtocolFeeTarget or constants.marketConfig[Env].protocolFeeTarget
  }
  -- update name and ticker with a unique postfix
  local postfix = string.sub(ao.id, 1, 4) .. string.sub(ao.id, -4)
  -- shorten name to first word and append postfix
  config.name = string.match(config.name, "^(%S+)") .. "-" .. postfix
  config.ticker = config.ticker .. "-" .. postfix
  return config
end

--- @dev Reset Market state during development mode or if uninitialized
if not Market or Env == 'DEV' then
  local marketConfig = retrieveMarketConfig()
  Market = market:new(
    marketConfig.configurator,
    marketConfig.incentives,
    marketConfig.dataIndex,
    marketConfig.collateralToken,
    marketConfig.resolutionAgent,
    marketConfig.creator,
    marketConfig.question,
    marketConfig.rules,
    marketConfig.category,
    marketConfig.subcategory,
    marketConfig.positionIds,
    marketConfig.name,
    marketConfig.ticker,
    marketConfig.logo,
    marketConfig.lpFee,
    marketConfig.creatorFee,
    marketConfig.creatorFeeTarget,
    marketConfig.protocolFee,
    marketConfig.protocolFeeTarget
  )
end

-- Set LP Token namespace variables
Denomination = constants.denomination

--[[
========
MATCHING
========
]]

--- Match on add funding to CPMM
--- @param msg Message The message to match
--- @return boolean True if the message is to add funding, false otherwise
local function isAddFunding(msg)
  if (
    msg.From == Market.cpmm.tokens.collateralToken and
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Add-Funding"
  ) then
    return true
  else
    return false
  end
end

--- Match on buy from CPMM
--- @param msg Message The message to match
--- @return boolean True if the message is to buy, false otherwise
local function isBuy(msg)
  if (
    msg.From == Market.cpmm.tokens.collateralToken and
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Buy"
  ) then
    return true
  else
    return false
  end
end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message received
--- @return Message infoNotice The info notice
Handlers.add("Info", {Action = "Info"}, function(msg)
  return Market:info(msg)
end)

--[[
===================
CPMM WRITE HANDLERS
===================
]]

--- Add funding handler
--- @param msg Message The message received
--- @return Message addFundingNotice The add funding notice
Handlers.add('Add-Funding', isAddFunding, function(msg)
  return Market:addFunding(msg)
end)

--- Remove funding handler
--- @param msg Message The message received
--- @return Message removeFundingNotice The remove funding notice
Handlers.add("Remove-Funding", {Action = "Remove-Funding"}, function(msg)
  return Market:removeFunding(msg)
end)

--- Buy handler
--- @param msg Message The message received
--- @return Message buyNotice The buy notice
Handlers.add("Buy", isBuy, function(msg)
  return Market:buy(msg)
end)

--- Sell handler
--- @param msg Message The message received
--- @return Message sellNotice The sell notice
Handlers.add("Sell", {Action = "Sell"}, function(msg)
  return Market:sell(msg)
end)

--- Withdraw fees handler
--- @param msg Message The message received
--- @return Message withdrawFees The amount withdrawn
Handlers.add("Withdraw-Fees", {Action = "Withdraw-Fees"}, function(msg)
  return Market:withdrawFees(msg)
end)

--[[
==================
CPMM READ HANDLERS
==================
]]

--- Calc buy amount handler
--- @param msg Message The message received
--- @return Message buyAmount The amount of tokens to be purchased
Handlers.add("Calc-Buy-Amount", {Action = "Calc-Buy-Amount"}, function(msg)
  return Market:calcBuyAmount(msg)
end)

--- Calc sell amount handler
--- @param msg Message The message received
--- @return Message sellAmount The amount of tokens to be sold
Handlers.add("Calc-Sell-Amount", {Action = "Calc-Sell-Amount"}, function(msg)
  return Market:calcSellAmount(msg)
end)

--- Colleced fees handler
--- @param msg Message The message received
--- @return Message collectedFees The total unwithdrawn fees collected by the CPMM
Handlers.add("Collected-Fees", {Action = "Collected-Fees"}, function(msg)
  return Market:collectedFees(msg)
end)

--- Fees withdrawable handler
--- @param msg Message The message received
--- @return Message feesWithdrawable The fees withdrawable by the account
Handlers.add("Fees-Withdrawable", {Action = "Fees-Withdrawable"}, function(msg)
  return Market:feesWithdrawable(msg)
end)

--[[
=======================
LP TOKEN WRITE HANDLERS
=======================
]]

--- Transfer handler
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferNotices The transfer notices, error notice or nothing
Handlers.add('Transfer', {Action = "Transfer"}, function(msg)
  return Market:transfer(msg)
end)

--[[
======================
LP TOKEN READ HANDLERS
======================
]]

--- Balance handler
--- @param msg Message The message received
--- @return Message balance The balance of the account
Handlers.add('Balance', {Action = "Balance"}, function(msg)
  return Market:balance(msg)
end)

--- Balances handler
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
Handlers.add('Balances', {Action = "Balances"}, function(msg)
  return Market:balances(msg)
end)

--- Total supply handler
--- @param msg Message The message received
--- @return Message totalSupply The total supply of the LP token
Handlers.add('Total-Supply', {Action = "Total-Supply"}, function(msg)
  return Market:totalSupply(msg)
end)

--[[
=================================
CONDITIONAL TOKENS WRITE HANDLERS
=================================
]]

--- Merge positions handler
--- @param msg Message The message received
--- @return Message mergePositionsNotice The positions merge notice or error message
Handlers.add("Merge-Positions", {Action = "Merge-Positions"}, function(msg)
  return Market:mergePositions(msg)
end)

--- Report payouts handler
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The condition resolution notice 
Handlers.add("Report-Payouts", {Action = "Report-Payouts"}, function(msg)
  return Market:reportPayouts(msg)
end)

--- Redeem positions handler
--- @param msg Message The message received
--- @return Message payoutRedemptionNotice The payout redemption notice
Handlers.add("Redeem-Positions", {Action = "Redeem-Positions"}, function(msg)
  return Market:redeemPositions(msg)
end)

--[[
================================
CONDITIONAL TOKENS READ HANDLERS
================================
]]

--- Get payout numerators handler
--- @param msg Message The message received
--- @return Message payoutNumerators payout numerators for the condition
Handlers.add("Get-Payout-Numerators", {Action = "Get-Payout-Numerators"}, function(msg)
  return Market:getPayoutNumerators(msg)
end)

--- Get payout denominator handler
--- @param msg Message The message received
--- @return Message payoutDenominator The payout denominator for the condition
Handlers.add("Get-Payout-Denominator", {Action = "Get-Payout-Denominator"}, function(msg)
  return Market:getPayoutDenominator(msg)
end)

--[[
===================================
SEMI-FUNGIBLE TOKENS WRITE HANDLERS
===================================
]]

--- Transfer single handler
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferSingleNotices The transfer notices, error notice or nothing
Handlers.add('Transfer-Single', {Action = "Transfer-Single"}, function(msg)
  return Market:transferSingle(msg)
end)

--- Transfer batch handler
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferBatchNotices The transfer notices, error notice or nothing
Handlers.add('Transfer-Batch', {Action = "Transfer-Batch"}, function(msg)
  return Market:transferBatch(msg)
end)

--[[
==================================
SEMI-FUNGIBLE TOKENS READ HANDLERS
==================================
]]

--- Balance by ID handler
--- @param msg Message The message received
--- @return Message balanceById The balance of the account filtered by ID
Handlers.add("Balance-By-Id", {Action = "Balance-By-Id"}, function(msg)
  return Market:balanceById(msg)
end)

--- Balances by ID handler
--- @param msg Message The message received
--- @return Message balancesById The balances of all accounts filtered by ID
Handlers.add('Balances-By-Id', {Action = "Balances-By-Id"}, function(msg)
  return Market:balancesById(msg)
end)

--- Batch balance handler
--- @param msg Message The message received
--- @return Message batchBalance The balance accounts filtered by IDs
Handlers.add("Batch-Balance", {Action = "Batch-Balance"}, function(msg)
  return Market:batchBalance(msg)
end)

--- Batch balances hanlder
--- @param msg Message The message received
--- @return Message batchBalances The balances of all accounts filtered by IDs
Handlers.add('Batch-Balances', {Action = "Batch-Balances"}, function(msg)
  return Market:batchBalances(msg)
end)

--- Balances all handler
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
Handlers.add('Balances-All', {Action = "Balances-All"}, function(msg)
  return Market:balancesAll(msg)
end)

--[[
===========================
CONFIGURATOR WRITE HANDLERS
===========================
]]

--- Update configurator handler
--- @param msg Message The message received
--- @return Message configuratorUpdateNotice The configurator update notice
Handlers.add('Update-Configurator', {Action = "Update-Configurator"}, function(msg)
  return Market:updateConfigurator(msg)
end)

--- Update incentives handler
--- @param msg Message The message received
--- @return Message incentivesUpdateNotice The incentives update notice
Handlers.add('Update-Incentives', {Action = "Update-Incentives"}, function(msg)
  return Market:updateIncentives(msg)
end)

--- Update take fee handler
--- @param msg Message The message received
--- @return Message takeFeeUpdateNotice The take fee update notice
Handlers.add('Update-Take-Fee', {Action = "Update-Take-Fee"}, function(msg)
  return Market:updateTakeFee(msg)
end)

--- Update protocol fee target handler
--- @param msg Message The message received
--- @return Message protocolTargetUpdateNotice The protocol fee target update notice
Handlers.add('Update-Protocol-Fee-Target', {Action = "Update-Protocol-Fee-Target"}, function(msg)
  return Market:updateProtocolFeeTarget(msg)
end)

--- Update logo handler
--- @param msg Message The message received
--- @return Message logoUpdateNotice The logo update notice
Handlers.add('Update-Logo', {Action = "Update-Logo"}, function(msg)
  return Market:updateLogo(msg)
end)

return "ok"

]===]