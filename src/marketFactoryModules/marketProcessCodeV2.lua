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

-- module: "marketModules.cpmmHelpers"
local function _loaded_mod_marketModules_cpmmHelpers()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

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
--- @param onBehalfOf string The address to receive the LP tokens
--- @param msg Message The message received
--- @return Message The funding added notice
function CPMMNotices.addFundingNotice(fundingAdded, mintAmount, onBehalfOf, msg)
  return msg.forward(msg.Tags.Sender, {
    Action = "Add-Funding-Notice",
    FundingAdded = json.encode(fundingAdded),
    MintAmount = tostring(mintAmount),
    OnBehalfOf = onBehalfOf,
    Data = "Successfully added funding"
  })
end

--- Sends a remove funding notice
--- @param sendAmounts table The send amounts
--- @param collateralRemovedFromFeePool string The collateral removed from the fee pool
--- @param sharesToBurn string The shares to burn
--- @param onBehalfOf string The address to receive the position tokens
--- @param msg Message The message received
--- @return Message The funding removed notice
function CPMMNotices.removeFundingNotice(sendAmounts, collateralRemovedFromFeePool, sharesToBurn, onBehalfOf, msg)
  return msg.reply({
    Action = "Remove-Funding-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = collateralRemovedFromFeePool,
    SharesToBurn = sharesToBurn,
    OnBehalfOf = onBehalfOf,
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
    Data = "Successfully bought"
  })
end

--- Sends a sell notice
--- @param from string The address that sold
--- @param onBehalfOf string The address that receives the collateral
--- @param returnAmount number The return amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param positionTokensSold number The outcome position tokens sold
--- @param msg Message The message received
--- @return Message The sell notice
function CPMMNotices.sellNotice(from, onBehalfOf, returnAmount, feeAmount, positionId, positionTokensSold, msg)
  return msg.forward(from, {
    Action = "Sell-Notice",
    OnBehalfOf = onBehalfOf,
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    PositionTokensSold = tostring(positionTokensSold),
    Data = "Successfully sold"
  })
end

--- Sends a withdraw fees notice
--- @notice Returns notice with `msg.reply` if `async` is true, otherwise uses `ao.send`
--- @dev Ensures the final notice is sent to the user, preventing unintended message handling
--- @param feeAmount number The fee amount
--- @param onBehalfOf string The address to receive the fees
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The withdraw fees notice
function CPMMNotices.withdrawFeesNotice(feeAmount, onBehalfOf, detached, msg)
  local notice = {
    Action = "Withdraw-Fees-Notice",
    OnBehalfOf = onBehalfOf,
    FeeAmount = tostring(feeAmount),
    Data = "Successfully withdrew fees"
  }
  if not detached then return msg.reply(notice) end
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

--- Sends an update logos notice
--- @param logos table<string> The updated logos
--- @param msg Message The message received
--- @return Message The logo updated notice
function CPMMNotices.updateLogosNotice(logos, msg)
  return msg.reply({
    Action = "Update-Logos-Notice",
    Data = json.encode(logos)
  })
end

return CPMMNotices
end

_G.package.loaded["marketModules.cpmmNotices"] = _loaded_mod_marketModules_cpmmNotices()

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
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The mint notice
function TokenNotices.mintNotice(recipient, quantity, detached, msg)
  local notice = {
    Recipient = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  }
  -- Send notice
  if not detached then return msg.reply(notice) end
  notice.Target = msg.From
  return ao.send(notice)
end

--- Burn notice
--- @param quantity string The quantity of tokens to burn
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The burn notice
function TokenNotices.burnNotice(quantity, detached, msg)
  local notice = {
    Target = msg.Sender and msg.Sender or msg.From,
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  }
  -- Send notice
  if not detached then return msg.reply(notice) end
  notice.Target =  msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Transfer notices
--- @param debitNotice Message The notice to send the spender
--- @param creditNotice Message The notice to send the receiver
--- @param recipient string The address that will receive the tokens
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The mesage received
--- @return table<Message> The transfer notices
function TokenNotices.transferNotices(debitNotice, creditNotice, recipient, detached, msg)
  if not detached then return { msg.reply(debitNotice), msg.forward(recipient, creditNotice) } end
  debitNotice.Target = msg.From
  creditNotice.Target = recipient
  return { ao.send(debitNotice), ao.send(creditNotice) }
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
function Token.new(name, ticker, logo, balances, totalSupply, denomination)
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
--- @param cast boolean The cast is set to true to silence the notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The mint notice if not cast
function TokenMethods:mint(to, quantity, cast, detached, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- Mint tokens
  if not self.balances[to] then self.balances[to] = '0' end
  self.balances[to] = tostring(bint.__add(bint(self.balances[to]), bint(quantity)))
  self.totalSupply = tostring(bint.__add(bint(self.totalSupply), bint(quantity)))
  -- Send notice
  if not cast then return self.mintNotice(to, quantity, detached, msg) end
end

--- Burn a quantity of tokens
--- @param from string The process ID that will no longer own the burned tokens
--- @param quantity string The quantity of tokens to burn
--- @param cast boolean The cast is set to true to silence the notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The burn notice if not cast
function TokenMethods:burn(from, quantity, cast, detached, msg)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balances[from], 'Must have token balance!')
  assert(bint.__le(bint(quantity), self.balances[from]), 'Must have sufficient tokens!')
  -- Burn tokens
  self.balances[from] = tostring(bint.__sub(self.balances[from], bint(quantity)))
  self.totalSupply = tostring(bint.__sub(bint(self.totalSupply), bint(quantity)))
  -- Send notice
  if not cast then return self.burnNotice(quantity, detached, msg) end
end

--- Transfer a quantity of tokens
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function TokenMethods:transfer(from, recipient, quantity, cast, detached, msg)
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
      return self.transferNotices(debitNotice, creditNotice, recipient, detached, msg)
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
constants.marketConfig = {
  configurator = "b9hj1yVw3eWGIggQgJxRDj1t8SZFCezctYD-7U5nYFk",
  dataIndex = "rXSAUKwZhJkIBTIEyBl1rf8Gtk_88RKQFsx5JvDOwlE",
  collateralToken = "jAyJBNpuSXmhn9lMMfwDR60TfIPANXI6r-f3n9zucYU",
  resolutionAgent = "KFHd4LyPakSIi0AyAFWDKUYJLKNVj7IiZE9n6H225Zw",
  creator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  question = "Liquid Ops oUSDC interest reaches 8% in March",
  rules = "Where we're going, we don't need rules",
  category = "Finance",
  sucategory = "Interest Rates",
  positionIds = json.encode({"1","2"}),
  name = "Mock Spawn Market",
  ticker = 'MSM',
  logo = "https://test.com/logo.png",
  logos = json.encode({"https://test.com/logo.png", "https://test.com/logo.png"}),
  lpFee = "100",
  creatorFee = "250",
  creatorFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  protocolFee = "250",
  protocolFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0"
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
    PayoutNumerators = json.encode(payoutNumerators),
    Data = "Successfully reported payouts"
  })
end

--- Position split notice
--- @param from string The address of the account that split the position
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The position split notice
function ConditionalTokensNotices.positionSplitNotice(from, collateralToken, quantity, detached, msg)
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
  -- Send notice
  if not detached then return msg.reply(notice) end
  notice.Target = from
  return ao.send(notice)
end

--- Positions merge notice
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param onBehalfOf string The address of the account to receive the collateral
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The positions merge notice
function ConditionalTokensNotices.positionsMergeNotice(collateralToken, quantity, onBehalfOf, detached, msg)
  local notice = {
    Action = "Merge-Positions-Notice",
    OnBehalfOf = onBehalfOf,
    CollateralToken = collateralToken,
    Quantity = quantity,
    Data = "Successfully merged positions"
  }
  if not detached then return msg.reply(notice) end
  notice.Target = msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Redeem positions notice
--- @param collateralToken string The address of the collateral token
--- @param payout number The payout amount
--- @param netPayout string The net payout amount (after fees)
--- @param onBehalfOf string The address of the account to receive the payout
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensNotices.redeemPositionsNotice(collateralToken, payout, netPayout, onBehalfOf, msg)
  return msg.reply({
    Action = "Redeem-Positions-Notice",
    CollateralToken = collateralToken,
    GrossPayout = tostring(payout),
    NetPayout = netPayout,
    OnBehalfOf = onBehalfOf,
    Data = "Successfully redeemed positions"
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
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The mint notice
function SemiFungibleTokensNotices.mintSingleNotice(to, id, quantity, detached, msg)
  local notice = {
    Recipient = to,
    PositionId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Mint-Single-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  }
  -- Send notice
  if not detached then return msg.reply(notice) end
  notice.Target = msg.From
  return ao.send(notice)
end

--- Mint batch notice
--- @param to string The address that will own the minted tokens
--- @param ids table<string> The IDs of the tokens to be minted
--- @param quantities table<string> The quantities of the tokens to be minted
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The batch mint notice
function SemiFungibleTokensNotices.mintBatchNotice(to, ids, quantities, detached, msg)
  local notice = {
    Recipient = to,
    PositionIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Action = 'Mint-Batch-Notice',
    Data = "Successfully minted batch"
  }
  -- Send notice
  if not detached then return msg.reply(notice) end
  notice.Target = msg.From
  return ao.send(notice)
end

--- Burn single notice
--- @param from string The address that will burn the token
--- @param id string The ID of the token to be burned
--- @param quantity string The quantity of the token to be burned
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The burn notice
function SemiFungibleTokensNotices.burnSingleNotice(from, id, quantity, detached, msg)
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
  if not detached then return msg.reply(notice) end
  notice.Target = from
  return ao.send(notice)
end

--- Burn batch notice
--- @param from string The address that will burn the tokens
--- @param positionIds table<string> The IDs of the positions to be burned
--- @param quantities table<string> The quantities of the tokens to be burned
--- @param remainingBalances table<string> The remaining balances of unburned tokens
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The burn notice
function SemiFungibleTokensNotices.burnBatchNotice(from, positionIds, quantities, remainingBalances, detached, msg)
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
  if not detached then return msg.reply(notice) end
  notice.Target = from
  return ao.send(notice)
end

--- Transfer single token notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param id string The ID of the token to be transferred
--- @param quantity string The quantity of the token to be transferred
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message> The debit and credit transfer notices
function SemiFungibleTokensNotices.transferSingleNotices(from, to, id, quantity, detached, msg)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Single-Notice',
    Recipient = to,
    PositionId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id "
      .. Colors.blue .. tostring(id) .. Colors.gray .. " to " .. Colors.green .. to .. Colors.reset
  }
  -- Prepare credit notice
  local creditNotice = {
    Action = 'Credit-Single-Notice',
    Sender = from,
    PositionId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You received " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id "
      .. Colors.blue .. tostring(id) .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
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
  if not detached then return { msg.reply(debitNotice), msg.forward(to, creditNotice) } end
  debitNotice.Target = from
  creditNotice.Target = to
  return { ao.send(debitNotice), ao.send(creditNotice) }
end

--- Transfer batch tokens notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param ids table<string> The IDs of the tokens to be transferred
--- @param quantities table<string> The quantities of the tokens to be transferred
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message> The debit and credit batch transfer notices
function SemiFungibleTokensNotices.transferBatchNotices(from, to, ids, quantities, detached, msg)
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
  if not detached then return { msg.reply(debitNotice), msg.forward(to, creditNotice) } end
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

-- Represents SemiFungibleTokens
--- @class SemiFungibleTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logos table<string> The token logos Arweave TxID for each ID
--- @field balancesById table<string, table<string, string>> The account token balances by ID
--- @field totalSupplyById table<string, string> The total supply of the token by ID
--- @field denomination number The number of decimals

--- Creates a new SemiFungibleTokens instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logos table<string> The token logos Arweave TxID for each ID
--- @param balancesById table<string, table<string, string>> The account token balances by ID
--- @param totalSupplyById table<string, string> The total supply of the token by ID
--- @param denomination number The number of decimals
--- @return SemiFungibleTokens semiFungibleTokens The new SemiFungibleTokens instance
function SemiFungibleTokens.new(name, ticker, logos, balancesById, totalSupplyById, denomination)
  local semiFungibleTokens = {
    name = name,
    ticker = ticker,
    logos = logos,
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
--- @param cast boolean The cast is set to true to silence the mint notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The mint notice if not cast
function SemiFungibleTokensMethods:mint(to, id, quantity, cast, detached, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- mint tokens
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][to] then self.balancesById[id][to] = "0" end
  if not self.totalSupplyById[id] then self.totalSupplyById[id] = "0" end
  self.balancesById[id][to] = tostring(bint.__add(self.balancesById[id][to], bint(quantity)))
  self.totalSupplyById[id] = tostring(bint.__add(self.totalSupplyById[id], bint(quantity)))
  -- send notice
  if not cast then return self.mintSingleNotice(to, id, quantity, detached, msg) end
end

--- Batch mint quantities of tokens with the given IDs
--- @param to string The address that will own the minted tokens
--- @param ids table<string> The IDs of the tokens to mint
--- @param quantities table<string> The quantities of tokens to mint
--- @param cast boolean The cast is set to true to silence the mint notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The batch mint notice if not cast
function SemiFungibleTokensMethods:batchMint(to, ids, quantities, cast, detached, msg)
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
  if not cast then return self.mintBatchNotice(to, ids, quantities, detached, msg) end
end

--- Burn a quantity of tokens with a given ID
--- @param from string The process ID that will no longer own the burned tokens
--- @param id string The ID of the tokens to burn
--- @param quantity string The quantity of tokens to burn
--- @param cast boolean The cast is set to true to silence the burn notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The burn notice if not cast
function SemiFungibleTokensMethods:burn(from, id, quantity, cast, detached, msg)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balancesById[id], 'Id must exist! ' .. id)
  assert(self.balancesById[id][from], 'Account must hold token! :: ' .. id)
  assert(bint.__le(bint(quantity), self.balancesById[id][from]), 'Account must have sufficient tokens! ' .. id)
  -- burn tokens
  self.balancesById[id][from] = tostring(bint.__sub(self.balancesById[id][from], bint(quantity)))
  self.totalSupplyById[id] = tostring(bint.__sub(self.totalSupplyById[id], bint(quantity)))
  -- send notice
  if not cast then return self.burnSingleNotice(from, id, quantity, detached, msg) end
end

--- Batch burn a quantity of tokens with the given IDs
--- @param from string The process ID that will no longer own the burned tokens
--- @param ids table<string> The IDs of the tokens to burn
--- @param quantities table<string> The quantities of tokens to burn
--- @param cast boolean The cast is set to true to silence the burn notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The batch burn notice if not cast
function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, cast, detached, msg)
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
  if not cast then return self.burnBatchNotice(from, ids, quantities, remainingBalances, detached, msg) end
end

--- Transfer a quantity of tokens with the given ID
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param id string The ID of the tokens to transfer
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, detached, msg)
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
      return self.transferSingleNotices(from, recipient, id, quantity, async, msg)
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
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, detached, msg)
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
    return self.transferBatchNotices(from, recipient, ids_, quantities_, detached, msg)
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

--- Get the logo for the token with the given ID
--- @param id string The ID of the token
--- @return string The Arweave TxID of the logo
function SemiFungibleTokensMethods:getLogo(id)
  local logo = ''
  if self.logos[tonumber(id)] then
    logo = self.logos[tonumber(id)]
  end
  -- return logo
  return logo
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
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

local ConditionalTokens = {}
local ConditionalTokensMethods = {}
local ConditionalTokensNotices = require('marketModules.conditionalTokensNotices')
local SemiFungibleTokens = require('marketModules.semiFungibleTokens')
local bint = require('.bint')(256)
local ao = ao or require('.ao')

--- Represents ConditionalTokens
--- @class ConditionalTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logos table<string> The token logos Arweave TxID for each ID
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
--- @param logos table<string> The token logos Arweave TxID for each ID
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
function ConditionalTokens.new(
  name,
  ticker,
  logos,
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
  local conditionalTokens = SemiFungibleTokens.new(name, ticker, logos, balancesById, totalSupplyById, denomination)
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
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message| nil The position split notice if not cast
function ConditionalTokensMethods:splitPosition(from, collateralToken, quantity, cast, sendInterim, detached, msg)
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "Condition not prepared!")
  -- Create equal split positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Mint the stake in the split target positions.
  self:batchMint(from, self.positionIds, quantities, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Send notice.
  if not cast then return self.positionSplitNotice(from, collateralToken, quantity, detached, msg) end
end

--- Merge positions
--- @param from string The process ID of the account that merged the positions
--- @param onBehalfOf string The process ID of the account that will receive the collateral
--- @param quantity string The quantity of collateral to merge
--- @param isSell boolean True if the merge is a sell, false otherwise
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The positions merge notice if not cast
function ConditionalTokensMethods:mergePositions(from, onBehalfOf, quantity, isSell, cast, sendInterim, detached, msg)
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "Condition not prepared!")
  -- Create equal merge positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Burn equal quantiies from user positions.
  self:batchBurn(from, self.positionIds, quantities, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- @dev below already handled within the sell method.
  -- sell method w/ a different quantity and recipient.
  if not isSell then
    -- Return the collateral to the user.
    ao.send({
      Target = self.collateralToken,
      Action = "Transfer",
      Quantity = quantity,
      Recipient = onBehalfOf,
    ---@diagnostic disable-next-line: assign-type-mismatch
      Cast = not sendInterim and "true" or nil
    })
  end
  -- Send notice.
  if not cast then return self.positionsMergeNotice(self.collateralToken, quantity, onBehalfOf, detached, msg) end
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
--- @param onBehalfOf string The process ID of the account to receive the collateral
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The payout redemption notice if not cast
function ConditionalTokensMethods:redeemPositions(onBehalfOf, cast, sendInterim, msg)
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
      self:burn(msg.From, positionId, payoutStake, not sendInterim, true, msg) -- @dev `true`: sends detatched message
    end
  end
  -- Return total payout minus take fee.
  if totalPayout > 0 then
    totalPayout = math.floor(totalPayout)
    totalPayoutMinusFee = self:returnTotalPayoutMinusTakeFee(self.collateralToken, onBehalfOf, totalPayout, not sendInterim)
  end
  -- Send notice.
  if not cast then return self.redeemPositionsNotice(self.collateralToken, totalPayout, totalPayoutMinusFee, onBehalfOf, msg) end
end

--- Return total payout minus take fee
--- Distributes payout and fees to the redeem account, creator and protocol
--- @param collateralToken string The collateral token
--- @param from string The account to receive the payout minus fees
--- @param totalPayout number The total payout assciated with the acount stake
--- @param cast boolean The cast is set to true to silence the notice
--- @return string The total payout minus fee amount
function ConditionalTokensMethods:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout, cast)
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
    Cast = cast and "true" or nil
  }
  local creatorFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = self.creatorFeeTarget,
    Quantity = creatorFee,
    Cast = cast and "true" or nil
  }
  local totalPayoutMinutTakeFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = from,
    Quantity = totalPayoutMinusFee,
    Cast = cast and "true" or nil
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
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

local CPMM = {}
local CPMMMethods = {}
local CPMMHelpers = require('marketModules.cpmmHelpers')
local CPMMNotices = require('marketModules.cpmmNotices')
local bint = require('.bint')(256)
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
--- @param logo string The CPMM LP token logo
--- @param logos table<string> The CPMM position tokens logos
--- @param lpFee number The liquidity provider fee
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @return CPMM cpmm The new CPMM instance
function CPMM.new(configurator, collateralToken, resolutionAgent, positionIds, name, ticker, logo, logos, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget)
  local cpmm = {
    configurator = configurator,
    poolBalances = {},
    withdrawnFees = {},
    feePoolWeight = "0",
    totalWithdrawnFees = "0",
    lpFee = tonumber(lpFee)
  }
  cpmm.token = token.new(
    name .. " LP Token",
    ticker,
    logo,
    {}, -- balances
    "0", -- totalSupply
    constants.denomination
  )
  cpmm.tokens = conditionalTokens.new(
    name .. " Conditional Tokens",
    ticker,
    logos,
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
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The funding added notice if not cast
function CPMMMethods:addFunding(onBehalfOf, addedFunds, distributionHint, cast, sendInterim, msg)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")
  local sendBackAmounts = {}
  local poolShareSupply = self.token.totalSupply
  local mintAmount

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
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, addedFunds, not sendInterim, sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Mint LP Tokens
  self:mint(onBehalfOf, mintAmount, not sendInterim, sendInterim, true, msg) -- @dev `true`: sends detatched message
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
    self.tokens:transferBatch(ao.id, onBehalfOf, nonZeroPositionIds, nonZeroAmounts, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  end
  -- Transform sendBackAmounts to array of amounts added
  for i = 1, #sendBackAmounts do
    sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
  end
  -- Send noticewith amounts added
  if not cast then return self.addFundingNotice(sendBackAmounts, mintAmount, onBehalfOf, msg) end
end

--- Remove funding
--- @param onBehalfOf string The process ID of the account to receive the position tokens
--- @param sharesToBurn string The amount of shares to burn
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The funding removed notice if not cast
function CPMMMethods:removeFunding(onBehalfOf, sharesToBurn, cast, sendInterim, msg)
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
  self:burn(msg.From, sharesToBurn, not sendInterim, sendInterim, true, msg) -- @dev `true`: sends detatched message
  local poolFeeBalance = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
  collateralRemovedFromFeePool = tostring(math.floor(poolFeeBalance - collateralRemovedFromFeePool))
  -- Send conditionalTokens amounts
  self.tokens:transferBatch(ao.id, onBehalfOf, self.tokens.positionIds, sendAmounts, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Send notice
  if not cast then return self.removeFundingNotice(sendAmounts, collateralRemovedFromFeePool, sharesToBurn, onBehalfOf, msg) end
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
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The buy notice if not cast
function CPMMMethods:buy(from, onBehalfOf, investmentAmount, positionId, minPositionTokensToBuy, cast, sendInterim, msg)
  local positionTokensToBuy = self:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__le(minPositionTokensToBuy, bint(positionTokensToBuy)), "Minimum position tokens not reached!")
  -- Calculate investmentAmountMinusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.lpFee), 1e4)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, investmentAmountMinusFees, not sendInterim, sendInterim, true, msg) --- @dev `true`: sends detatched message
  -- Transfer buy position to onBehalfOf
  self.tokens:transferSingle(ao.id, onBehalfOf, positionId, positionTokensToBuy, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Send notice.
  if not cast then return self.buyNotice(from, onBehalfOf, investmentAmount, feeAmount, positionId, positionTokensToBuy, msg) end
end

--- Sell
--- @param from string The process ID of the account that initiates the sell
--- @param onBehalfOf string The process ID of the account to receive the tokens
--- @param returnAmount number The amount to unstake from an outcome
--- @param positionId string The position ID of the outcome
--- @param maxPositionTokensToSell number The max outcome tokens to sell
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @return Message|nil The sell notice if not cast
function CPMMMethods:sell(from, onBehalfOf, returnAmount, positionId, maxPositionTokensToSell, cast, sendInterim, msg)
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
  self.tokens:transferSingle(from, ao.id, positionId, positionTokensToSell, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Merge positions through all conditions (burns returnAmountPlusFees).
  self.tokens:mergePositions(ao.id, '', positionTokensToSell, true, not sendInterim, sendInterim, true, msg) -- @dev `true`: isSell, `true`: sends detatched message
  -- Returns collateral to the user / onBehalfOf address
  ao.send({
    Action = "Transfer",
    Target = self.tokens.collateralToken,
    Quantity = tostring(returnAmount),
    Recipient = onBehalfOf,
    ---@diagnostic disable-next-line: assign-type-mismatch
    Cast = not sendInterim and "true" or nil
  })
  -- Send notice
  if not cast then return self.sellNotice(from, onBehalfOf, returnAmount, feeAmount, positionId, positionTokensToSell, msg) end
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
--- @param onBehalfOf string The process ID of the account to receive the fees
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The withdraw fees message if not cast
function CPMMMethods:withdrawFees(sender, onBehalfOf, cast, sendInterim, detached, msg)
  local feeAmount = self:feesWithdrawableBy(sender)
  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
    ao.send({
      Action = 'Transfer',
      Target = self.tokens.collateralToken,
      Recipient = onBehalfOf,
      Quantity = feeAmount,
      ---@diagnostic disable-next-line: assign-type-mismatch
      Cast = not sendInterim and "true" or nil
    })
  end
  if not cast then return self.withdrawFeesNotice(feeAmount, onBehalfOf, detached, msg) end
end

--- Before token transfer
--- Updates fee accounting before token transfers
--- @param from string|nil The process ID of the account executing the transaction
--- @param to string|nil The process ID of the account receiving the transaction
--- @param amount string The amount transferred
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
function CPMMMethods:_beforeTokenTransfer(from, to, amount, cast, sendInterim, msg)
  if from ~= nil and from ~= ao.id then
    self:withdrawFees(from, from, cast, sendInterim, true, msg) -- @dev `true`: sends detatched message
  end
  local totalSupply = self.token.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), bint(amount)), totalSupply)))

  if from ~= nil and to ~= nil and from ~= ao.id then
    self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), bint(withdrawnFeesTransfer)))
    self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), bint(withdrawnFeesTransfer)))
  end
end

--- @dev See `Mint` in modules.token
function CPMMMethods:mint(to, quantity, cast, sendInterim, detached, msg)
  self:_beforeTokenTransfer(nil, to, quantity, cast, sendInterim, msg)
  return self.token:mint(to, quantity, cast, detached, msg)
end

--- @dev See `Burn` in modules.token
-- @dev See tokenMethods:burn & _beforeTokenTransfer
function CPMMMethods:burn(from, quantity, cast, sendInterim, detached, msg)
  self:_beforeTokenTransfer(from, nil, quantity, cast, sendInterim, msg)
  return self.token:burn(from, quantity, cast, detached, msg)
end

--- @dev See `Transfer` in modules.token
-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function CPMMMethods:transfer(from, recipient, quantity, cast, sendInterim, detached, msg)
  self:_beforeTokenTransfer(from, recipient, quantity, cast, sendInterim, msg)
  return self.token:transfer(from, recipient, quantity, cast, detached, msg)
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
  return self.updateLogoNotice(logo, msg)
end

--- Update logos
--- @param logos table<string> The Arweave transaction IDs of the new logos
--- @param msg Message The message received
--- @return Message The update logos notice
function CPMMMethods:updateLogos(logos, msg)
  self.tokens.logos = logos
  return self.updateLogosNotice(logos, msg)
end

return CPMM
end

_G.package.loaded["marketModules.cpmm"] = _loaded_mod_marketModules_cpmm()

-- module: "marketModules.market"
local function _loaded_mod_marketModules_market()
--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

local Market = {}
local MarketMethods = {}
local MarketNotices = require('marketModules.marketNotices')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('marketModules.cpmm')

--- Represents a Market
--- @class Market
--- @field cpmm CPMM The Constant Product Market Maker

--- Creates a new Market instance
--- @param configurator string The process ID of the configurator
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
--- @param logo string The CPMM LP token logo
--- @param logos table<string> The CPMM position tokens logos
--- @param lpFee number The liquidity provider fee
--- @param creatorFee number The market creator fee
--- @param creatorFeeTarget string The market creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @return Market market The new Market instance
function Market.new(
  configurator,
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
  logos,
  lpFee,
  creatorFee,
  creatorFeeTarget,
  protocolFee,
  protocolFeeTarget
)
  local market = {
    cpmm = cpmm.new(
      configurator,
      collateralToken,
      resolutionAgent,
      positionIds,
      name,
      ticker,
      logo,
      logos,
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
    Logos = json.encode(self.cpmm.tokens.logos),
    Denomination = tostring(self.cpmm.token.denomination),
    PositionIds = json.encode(self.cpmm.tokens.positionIds),
    CollateralToken = self.cpmm.tokens.collateralToken,
    Configurator = self.cpmm.configurator,
    DataIndex = self.dataIndex,
    ResolutionAgent = self.cpmm.tokens.resolutionAgent,
    Question = self.question,
    Rules = self.rules,
    Category = self.category,
    Subcategory = self.subcategory,
    Creator = self.creator,
    CreatorFee = tostring(self.cpmm.tokens.creatorFee),
    CreatorFeeTarget = self.cpmm.tokens.creatorFeeTarget,
    ProtocolFee = tostring(self.cpmm.tokens.protocolFee),
    ProtocolFeeTarget = self.cpmm.tokens.protocolFeeTarget,
    LpFee = tostring(self.cpmm.lpFee),
    LpFeePoolWeight = self.cpmm.feePoolWeight,
    LpFeeTotalWithdrawn = self.cpmm.totalWithdrawnFees,
    Owner = Owner
  })
end

--[[
=============
ACTIVITY LOGS
=============
]]

local function logFunding(dataIndex, user, onBehalfOf, operation, collateral, quantity, msg)
  return msg.forward(dataIndex, {
    Action = "Log-Funding",
    User = user,
    OnBehalfOf = onBehalfOf,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity,
  })
end

local function logPrediction(dataIndex, user, onBehalfOf, operation, collateral, quantity, outcome, shares, price, msg)
  return msg.forward(dataIndex, {
    Action = "Log-Prediction",
    User = user,
    OnBehalfOf = onBehalfOf,
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
function MarketMethods:addFunding(msg)
  local distribution = msg.Tags['X-Distribution'] and json.decode(msg.Tags['X-Distribution']) or nil
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  local cast = msg.Tags['X-Cast'] or false
  local sendInterim = msg.Tags['X-SendInterim'] or false
  -- Add funding to the CPMM
  self.cpmm:addFunding(onBehalfOf, msg.Tags.Quantity, distribution, cast, sendInterim, msg)
  -- Log funding update to data index
  logFunding(self.dataIndex, msg.Tags.Sender, onBehalfOf, 'add', self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg)
end

--- Remove funding
--- Message forwarded from the LP token
--- @param msg Message The message received
function MarketMethods:removeFunding(msg)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  -- Remove funding from the CPMM
  self.cpmm:removeFunding(onBehalfOf, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags.SendInterim, msg)
  -- Log funding update to data index
  logFunding(self.dataIndex, msg.From, onBehalfOf, 'remove', self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg)
end

--- Buy
--- Message forwarded from the collateral token
--- @param msg Message The message received
function MarketMethods:buy(msg)
  local positionTokensToBuy = self.cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  local cast = msg.Tags['X-Cast'] or false
  local sendInterim = msg.Tags['X-SendInterim'] or false
  -- Buy position tokens from the CPMM
  self.cpmm:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinPositionTokensToBuy']), cast, sendInterim, msg)
  -- Log prediction and probability update to data index
  local price = tostring(bint.__div(bint(positionTokensToBuy), bint(msg.Tags.Quantity)))
  logPrediction(self.dataIndex, msg.Tags.Sender, onBehalfOf, "buy", self.cpmm.tokens.collateralToken, msg.Tags.Quantity, msg.Tags['X-PositionId'], positionTokensToBuy, price, msg)
  logProbabilities(self.dataIndex, self.cpmm:calcProbabilities(), msg)
end

--- Sell
--- @param msg Message The message received
function MarketMethods:sell(msg)
  local positionTokensToSell = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  -- Sell position tokens to the CPMM
  self.cpmm:sell(msg.From, onBehalfOf, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.MaxPositionTokensToSell, msg.Tags.Cast, msg.Tags.SendInterim, msg)
  -- Log prediction and probability update to data index
  local price = tostring(bint.__div(positionTokensToSell, bint(msg.Tags.ReturnAmount)))
  logPrediction(self.dataIndex, msg.From, onBehalfOf, "sell", self.cpmm.tokens.collateralToken, msg.Tags.ReturnAmount, msg.Tags.PositionId, positionTokensToSell, price, msg)
  logProbabilities(self.dataIndex, self.cpmm:calcProbabilities(), msg)
end

--- Withdraw fees
--- @param msg Message The message received
function MarketMethods:withdrawFees(msg)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  local detached = false
  self.cpmm:withdrawFees(msg.From, onBehalfOf, msg.Tags.Cast, msg.Tags.SendInterim, detached, msg)
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
  local account = msg.Tags["Recipient"] or msg.From
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
--- @notice SendInterim tag ignored as we always want to send interim (withdraw fees) notice
--- @param msg Message The message received
function MarketMethods:transfer(msg)
  local detached = false
  self.cpmm:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags.SendInterim, detached, msg)
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
function MarketMethods:mergePositions(msg)
  local onBehalfOf = msg.Tags["OnBehalfOf"] or msg.From
  local isSell = false
  local detached = false
  self.cpmm.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, isSell, msg.Tags.Cast, msg.Tags.SendInterim, detached, msg)
end

--- Report payouts
--- @notice Cast tag ignored as we always want to report payouts
--- @param msg Message The message received
function MarketMethods:reportPayouts(msg)
  local payouts = json.decode(msg.Tags.Payouts)
  self.cpmm.tokens:reportPayouts(payouts, msg)
end

--- Redeem positions
--- @param msg Message The message received
function MarketMethods:redeemPositions(msg)
  local onBehalfOf = msg.Tags["OnBehalfOf"] or msg.From
  self.cpmm.tokens:redeemPositions(onBehalfOf, msg.Tags.Cast, msg.Tags.SendInterim, msg)
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
function MarketMethods:transferSingle(msg)
  local detached = false
  self.cpmm.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.PositionId, msg.Tags.Quantity, msg.Tags.Cast, detached, msg)
end

--- Transfer batch
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferBatchNotices The transfer notices, error notice or nothing
function MarketMethods:transferBatch(msg)
  local positionIds = json.decode(msg.Tags.PositionIds)
  local quantities = json.decode(msg.Tags.Quantities)
  local detached = false
  return self.cpmm.tokens:transferBatch(msg.From, msg.Tags.Recipient, positionIds, quantities, msg.Tags.Cast, detached, msg)
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
  local bals = self.cpmm.tokens:getBalances(msg.Tags.PositionId)
  return msg.reply({
    PositionId = msg.Tags.PositionId,
    Data = json.encode(bals)
  })
end

--- Batch balance
--- @param msg Message The message received
--- @return Message batchBalance The balance accounts filtered by recipients and IDs
function MarketMethods:batchBalance(msg)
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

--- Logo by position ID
--- @param msg Message The message received
--- @return Message logoById The logo for a given position ID
function MarketMethods:logoById(msg)
  local logo = ""
  if self.cpmm.tokens.logos[msg.Tags.PositionId] then
    logo = self.cpmm.tokens.logos[msg.Tags.PositionId]
  end
  return msg.reply({
    PositionId = msg.Tags.PositionId,
    Data = logo
  })
end

--- Logos
--- @param msg Message The message received
--- @return Message logos The logos of the Conditional tokens
function MarketMethods:logos(msg)
  return msg.reply({ Data = json.encode(self.cpmm.tokens.logos) })
end

--[[
==========================
CONFIGURATOR WRITE METHODS
==========================
]]

--- Update configurator
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
function MarketMethods:updateConfigurator(msg)
  return self.cpmm:updateConfigurator(msg.Tags.Configurator, msg)
end

--- Update data index
--- @param msg Message The message received
--- @return Message updateDataIndexNotice The update data index notice
function MarketMethods:updateDataIndex(msg)
  self.dataIndex = msg.Tags.DataIndex
  return self.updateDataIndexNotice(msg.Tags.DataIndex, msg)
end

--- Update take fee
--- @param msg Message The message received
--- @return Message updateTakeFeeNotice The update take fee notice
function MarketMethods:updateTakeFee(msg)
  return self.cpmm:updateTakeFee(tonumber(msg.Tags.CreatorFee), tonumber(msg.Tags.ProtocolFee), msg)
end

--- Update protocol fee target
--- @param msg Message The message received
--- @return Message
function MarketMethods:updateProtocolFeeTarget(msg)
  return self.cpmm:updateProtocolFeeTarget(msg.Tags.ProtocolFeeTarget, msg)
end

--- Update logo
--- @param msg Message The message received
--- @return Message updateLogoNotice The update logo notice
function MarketMethods:updateLogo(msg)
  return self.cpmm:updateLogo(msg.Tags.Logo, msg)
end

--- Update logos
--- @param msg Message The message received
--- @return Message updateLogosNotice The update logo notice
function MarketMethods:updateLogos(msg)
  local logos = json.decode(msg.Tags.Logos)
  return self.cpmm:updateLogos(logos, msg)
end

return Market

end

_G.package.loaded["marketModules.market"] = _loaded_mod_marketModules_market()

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
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validateAddress(address, tagName)
  if type(address) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end
  if not sharedUtils.isValidArweaveAddress(address) then
    return false, tagName .. ' must be a valid Arweave address!'
  end
  return true
end

--- Validates array item
--- @param item any The item to be validated
--- @param validItems table<string> The array of valid items
--- @param tagName string The name of the tag being validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validateItem(item, validItems, tagName)
  if type(item) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end
  if not utils.includes(item, validItems) then
    return false, 'Invalid ' .. tagName .. '!'
  end
  return true
end

--- Validates positive integer
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validatePositiveInteger(quantity, tagName)
  if type(quantity) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end

  local num = tonumber(quantity)
  if not num then
    return false, tagName .. ' must be a valid number!'
  end
  if num <= 0 then
    return false, tagName .. ' must be greater than zero!'
  end
  if num % 1 ~= 0 then
    return false, tagName .. ' must be an integer!'
  end

  return true
end

--- Validates positive integer or zero
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validatePositiveIntegerOrZero(quantity, tagName)
  if type(quantity) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end

  local num = tonumber(quantity)
  if not num then
    return false, tagName .. ' must be a valid number!'
  end
  if num < 0 then
    return false, tagName .. ' must be greater than or equal to zero!'
  end
  if num % 1 ~= 0 then
    return false, tagName .. ' must be an integer!'
  end

  return true
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
local bint = require('.bint')(256)
local json = require("json")

--- Validates add funding
--- @param msg Message The message to be validated
--- @param totalSupply string The LP token total supply
--- @param positionIds table<string> The outcome position IDs
--- @return boolean, string|nil
function cpmmValidation.addFunding(msg, totalSupply, positionIds)
  local isValid, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not isValid then
    return false, err
  end

  -- Extract distribution
  local distribution = msg.Tags["X-Distribution"] and json.decode(msg.Tags["X-Distribution"]) or nil

  -- Check if distribution is required or must be omitted
  local isFirstFunding = bint.iszero(bint(totalSupply))
  if distribution then
    -- Ensure distribution is set only for initial funding
    if not isFirstFunding then
      return false, "Cannot specify distribution after initial funding"
    end

    -- Ensure distribution includes all position IDs
    if #distribution ~= #positionIds then
      return false, "Distribution length mismatch"
    end

    -- Validate distribution content
    local distributionSum = 0
    for i = 1, #distribution do
      if type(distribution[i]) ~= "number" then
        return false, "Distribution item must be a number"
      end
      distributionSum = distributionSum + distribution[i]
    end

    -- Ensure the distribution sum is greater than zero
    if distributionSum == 0 then
      return false, "Distribution sum must be greater than zero"
    end
  else
    -- Ensure distribution is provided for the first funding call
    if isFirstFunding then
      return false, "Must specify distribution for initial funding"
    end
  end

  return true
end

--- Validates remove funding
--- @param msg Message The message to be validated
--- @param balance string The balance of the sender's LP tokens
--- @return boolean, string|nil True if validation passes, otherwise false with an error message
function cpmmValidation.removeFunding(msg, balance)
  -- Validate that Quantity is a positive integer
  local isValid, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not isValid then
    return false, err
  end

  -- Ensure Quantity is within the sender's balance
  local quantity = bint(msg.Tags.Quantity)
  local userBalance = bint(balance or "0") -- Default to "0" if balance is nil

  if quantity > userBalance then
    return false, "Quantity must be less than or equal to balance!"
  end

  return true
end

--- Validates buy
--- @param msg Message The message to be validated
--- @param cpmm CPMM The CPMM instance for calculations
--- @return boolean, string|nil True if validation passes, otherwise false with an error message
function cpmmValidation.buy(msg, cpmm)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  local positionIds = cpmm.tokens.positionIds

  local success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
  if not success then return false, err end

  success, err = sharedValidation.validateItem(msg.Tags['X-PositionId'], positionIds, "X-PositionId")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags["X-MinPositionTokensToBuy"], "X-MinPositionTokensToBuy")
  if not success then return false, err end

  -- Calculate the actual buy amount
  local positionTokensToBuy = cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])

  -- Ensure minimum buy amount is met
  if bint(msg.Tags['X-MinPositionTokensToBuy']) > bint(positionTokensToBuy) then
    return false, 'Minimum buy amount not reached'
  end

  return true
end

--- Validates sell
--- @param msg Message The message to be validated
--- @param cpmm CPMM The CPMM instance for calculations
--- @return boolean, string|nil
function cpmmValidation.sell(msg, cpmm)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.From
  local positionIds = cpmm.tokens.positionIds

  local success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
  if not success then return false, err end

  success, err = sharedValidation.validateItem(msg.Tags.PositionId, positionIds, "PositionId")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.MaxPositionTokensToSell, "MaxPositionTokensToSell")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  if not success then return false, err end

  -- Calculate the actual position tokens to sell
  local positionTokensToSell = cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)

 -- Ensure the sell amount does not exceed the maximum allowed
 if bint(positionTokensToSell) > bint(msg.Tags.MaxPositionTokensToSell) then
  return false, "Max position tokens to sell not sufficient!"
end

  return true
end

--- Validates calc buy amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
--- @return boolean, string|nil
function cpmmValidation.calcBuyAmount(msg, validPositionIds)
  local success, err = sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  if not success then return false, err end

  return sharedValidation.validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

--- Validates calc sell amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
--- @return boolean, string|nil
function cpmmValidation.calcSellAmount(msg, validPositionIds)
  local success, err = sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  if not success then return false, err end

  return sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

--- Validates fees withdrawable
--- @param msg Message The message to be validated
--- @return boolean, string|nil
function cpmmValidation.feesWithdrawable(msg)
  if msg.Tags["Recipient"] then
    return sharedValidation.validateAddress(msg.Tags['Recipient'], 'Recipient')
  end

  return true
end

--- Validates withdraw fees
--- @param msg Message The message to be validated
--- @return boolean, string|nil
function cpmmValidation.withdrawFees(msg)
  if msg.Tags["OnBehalfOf"] then
    return sharedValidation.validateAddress(msg.Tags['OnBehalfOf'], 'OnBehalfOf')
  end

  return true
end

--- Validates update configurator
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateConfigurator(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  return sharedValidation.validateAddress(msg.Tags.Configurator, 'Configurator')
end

--- Validates update take fee
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateTakeFee(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  local success, err = sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, 'CreatorFee')
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, 'ProtocolFee')
  if not success then return false, err end

  local totalFee = bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee))
  if not bint.__lt(totalFee, 1000) then
    return false, 'Net fee must be less than or equal to 1000 bps'
  end

  return true
end

--- Validates update protocol fee target
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateProtocolFeeTarget(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  if not msg.Tags.ProtocolFeeTarget then
    return false, 'ProtocolFeeTarget is required!'
  end

  return true
end

--- Validates update logo
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateLogo(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  if not msg.Tags.Logo then
    return false, 'Logo is required!'
  end

  return true
end

--- Validates update logo
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateLogos(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  if not msg.Tags.Logos then
    return false, 'Logos is required!'
  end

  local logos = json.decode(msg.Tags.Logos)
  if type(logos) ~= 'table' then
    return false, 'Logos must be a table!'
  end

  for _, logo in ipairs(logos) do
    if type(logo) ~= 'string' then
      return false, 'Logos item must be a string!'
    end
  end

  return true
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
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function tokenValidation.transfer(msg)
  local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not success then return false, err end

  return true
end

--- Validates balance
--- @param msg Message The message to be validated
--- @return boolean, string|nil
function tokenValidation.balance(msg)
  if msg.Tags['Recipient'] then
    return sharedValidation.validateAddress(msg.Tags['Recipient'], 'Recipient')
  elseif msg.Tags['Target'] then
    return sharedValidation.validateAddress(msg.Tags['Target'], 'Target')
  end

  return true
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
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function MarketValidation.updateDataIndex(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  local success, err = sharedValidation.validateAddress(msg.Tags.DataIndex, 'DataIndex')
  if not success then return false, err end

  return true
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
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.transferSingle(msg, validPositionIds)
  local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  if not success then return false, err end

  success, err = sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not success then return false, err end

  return true
end

--- Validates a transferBatch message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.transferBatch(msg, validPositionIds)
  local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
  if not success then return false, err end

  if type(msg.Tags.PositionIds) ~= 'string' then
    return false, 'PositionIds is required!'
  end
  local positionIds = json.decode(msg.Tags.PositionIds)

  if type(msg.Tags.Quantities) ~= 'string' then
    return false, 'Quantities is required!'
  end
  local quantities = json.decode(msg.Tags.Quantities)

  if #positionIds ~= #quantities then
    return false, 'Input array lengths must match!'
  end
  if #positionIds == 0 then
    return false, "Input array length must be greater than zero!"
  end

  for i = 1, #positionIds do
    success, err = sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    if not success then return false, err end

    success, err = sharedValidation.validatePositiveInteger(quantities[i], "Quantity")
    if not success then return false, err end
  end

  return true
end

--- Validates a balanceById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.balanceById(msg, validPositionIds)
  if msg.Tags.Recipient then
    local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
    if not success then return false, err end
  end
  return sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

--- Validates a balancesById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.balancesById(msg, validPositionIds)
  if msg.Tags.Recipient then
    local success, err = sharedValidation.validateAddress(msg.Tags.Recipient, 'Recipient')
    if not success then return false, err end
  end
  return sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
end

--- Validates a batchBalance message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.batchBalance(msg, validPositionIds)
  if not msg.Tags.Recipients then
    return false, "Recipients is required!"
  end
  local recipients = json.decode(msg.Tags.Recipients)

  if not msg.Tags.PositionIds then
    return false, "PositionIds is required!"
  end
  local positionIds = json.decode(msg.Tags.PositionIds)

  if #recipients ~= #positionIds then
    return false, "Input array lengths must match!"
  end
  if #recipients == 0 then
    return false, "Input array length must be greater than zero!"
  end

  for i = 1, #positionIds do
    local success, err = sharedValidation.validateAddress(recipients[i], 'Recipient')
    if not success then return false, err end

    success, err = sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    if not success then return false, err end
  end

  return true
end

--- Validates a batchBalances message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.batchBalances(msg, validPositionIds)
  if not msg.Tags.PositionIds then
    return false, "PositionIds is required!"
  end
  local positionIds = json.decode(msg.Tags.PositionIds)

  if #positionIds == 0 then
    return false, "Input array length must be greater than zero!"
  end

  for i = 1, #positionIds do
    local success, err = sharedValidation.validateItem(positionIds[i], validPositionIds, "PositionId")
    if not success then return false, err end
  end

  return true
end

--- Validates a logoById message
--- @param msg Message The message received
--- @param validPositionIds table<string> The array of valid token IDs
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function semiFungibleTokensValidation.logoById(msg, validPositionIds)
  return sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
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
local sharedValidation = require('marketModules.sharedValidation')
local sharedUtils = require('marketModules.sharedUtils')
local bint = require('.bint')(256)
local json = require('json')

--- Validates quantity
--- @param quantity any The quantity to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
local function validateQuantity(quantity)
  if type(quantity) ~= 'string' then
    return false, 'Quantity is required and must be a string!'
  end

  local num = tonumber(quantity)
  if not num then
    return false, 'Quantity must be a valid number!'
  end
  if num <= 0 then
    return false, 'Quantity must be greater than zero!'
  end
  if num % 1 ~= 0 then
    return false, 'Quantity must be an integer!'
  end

  return true
end

--- Validates payouts
--- @param payouts any The payouts to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
local function validatePayouts(payouts)
  if not payouts then
    return false, "Payouts is required!"
  end
  if not sharedUtils.isJSONArray(payouts) then
    return false, "Payouts must be a valid JSON Array!"
  end

  local decodedPayouts = json.decode(payouts)
  for _, payout in ipairs(decodedPayouts) do
    if not tonumber(payout) then
      return false, "Payouts item must be a valid number!"
    end
  end

  return true
end

--- Validates the mergePositions message.
--- @param msg Message The message to be validated
--- @param cpmm CPMM The CPMM instance for checking token balances
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConditionalTokensValidation.mergePositions(msg, cpmm)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  local success, err

  if not onBehalfOf then
    success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
    if not success then return false, err end
  end

  success, err = validateQuantity(msg.Tags.Quantity)
  if not success then return false, err end

  -- Check user balances for each position
  for i = 1, #cpmm.tokens.positionIds do
    local positionId = cpmm.tokens.positionIds[i]

    if not cpmm.tokens.balancesById[positionId] then
      return false, "Invalid position! PositionId: " .. positionId
    end

    if not cpmm.tokens.balancesById[positionId][onBehalfOf] then
      return false, "Invalid user position! PositionId: " .. positionId
    end

    if bint(cpmm.tokens.balancesById[positionId][onBehalfOf]) < bint(msg.Tags.Quantity) then
      return false, "Insufficient tokens! PositionId: " .. positionId
    end
  end

  return true
end

--- Validates the redeemPositions message.
--- @param msg Message The message to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConditionalTokensValidation.redeemPositions(msg)
  local onBehalfOf = msg.Tags['OnBehalfOf'] or msg.From
  local success, err

  if not onBehalfOf then
    success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
    if not success then return false, err end
  end

  return true
end


--- Validates the reportPayouts message
--- @param msg Message The message to be validated
--- @param resolutionAgent string The resolution agent process ID
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConditionalTokensValidation.reportPayouts(msg, resolutionAgent)
  if msg.From ~= resolutionAgent then
    return false, "Sender must be the resolution agent!"
  end

  return validatePayouts(msg.Tags.Payouts)
end

return ConditionalTokensValidation

end

_G.package.loaded["marketModules.conditionalTokensValidation"] = _loaded_mod_marketModules_conditionalTokensValidation()

--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

local market = require('marketModules.market')
local constants = require('marketModules.constants')
local json = require('json')
local cpmmValidation = require('marketModules.cpmmValidation')
local tokenValidation = require('marketModules.tokenValidation')
local marketValidation = require('marketModules.marketValidation')
local semiFungibleTokensValidation = require('marketModules.semiFungibleTokensValidation')
local conditionalTokensValidation = require('marketModules.conditionalTokensValidation')

--[[
======
MARKET
======
]]

Env = ao.env.Process.Tags.Env or "DEV"

-- Revoke ownership if the Market is not in development mode
if Env ~= "DEV" then
  Owner = ""
end

--- Represents the Market Configuration
--- @class MarketConfiguration
--- @field configurator string The Configurator process ID
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
--- @field logo string The Market LP token logo
--- @field logos table<string> The Market Position tokens logos
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
    configurator = ao.env.Process.Tags.Configurator or constants.marketConfig.configurator,
    dataIndex = ao.env.Process.Tags.DataIndex or constants.marketConfig.dataIndex,
    collateralToken = ao.env.Process.Tags.CollateralToken or constants.marketConfig.collateralToken,
    resolutionAgent = ao.env.Process.Tags.ResolutionAgent or constants.marketConfig.resolutionAgent,
    creator = ao.env.Process.Tags.Creator or constants.marketConfig.creator,
    question = ao.env.Process.Tags.Question or constants.marketConfig.question,
    rules = ao.env.Process.Tags.Rules or constants.marketConfig.rules,
    category = ao.env.Process.Tags.Category or constants.marketConfig.category,
    subcategory = ao.env.Process.Tags.Subcategory or constants.marketConfig.subcategory,
    positionIds = json.decode(ao.env.Process.Tags.PositionIds or constants.marketConfig.positionIds),
    name = ao.env.Process.Tags.Name or constants.marketConfig.name,
    ticker = ao.env.Process.Tags.Ticker or constants.marketConfig.ticker,
    logo = ao.env.Process.Tags.Logo or constants.marketConfig.logo,
    logos = json.decode(ao.env.Process.Tags.Logos or constants.marketConfig.logos),
    lpFee = tonumber(ao.env.Process.Tags.LpFee or constants.marketConfig.lpFee),
    creatorFee = tonumber(ao.env.Process.Tags.CreatorFee or constants.marketConfig.creatorFee),
    creatorFeeTarget = ao.env.Process.Tags.CreatorFeeTarget or constants.marketConfig.creatorFeeTarget,
    protocolFee = tonumber(ao.env.Process.Tags.ProtocolFee or constants.marketConfig.protocolFee),
    protocolFeeTarget = ao.env.Process.Tags.ProtocolFeeTarget or constants.marketConfig.protocolFeeTarget
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
  Market = market.new(
    marketConfig.configurator,
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
    marketConfig.logos,
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
--- @note **Replies with the following tags:**
--- Name (string): The Market name
--- Ticker (string): The Market ticker
--- Logo (string): The Market LP token logo
--- Logos (string): The Market Position tokens logos (stringified table)
--- Denomination (string): The LP token denomination
--- PositionIds (string): The Market Position tokens process IDs (stringified table)
--- CollateralToken (string): The Market collateral token process ID
--- Configurator (string): The Market configurator process ID
--- DataIndex (string): The Market data index process ID
--- ResolutionAgent (string): The Market resolution agent process ID
--- Question (string): The Market question
--- Rules (string): The Market rules
--- Category (string): The Market category
--- Subcategory (string): The Market subcategory
--- Creator (string): The Market creator address
--- CreatorFee (string): The Market creator fee (numeric string, basis points)
--- CreatorFeeTarget (string): The Market creator fee target
--- ProtocolFee (string): The Market protocol fee (numeric string, basis points)
--- ProtocolFeeTarget (string): The Market protocol fee target
--- LpFee (string): The Market LP fee (numeric string, basis points)
--- LpFeePoolWeight (string): The Market LP fee pool weight
--- LpFeeTotalWithdrawn (string): The Market LP fee total withdrawn
--- Owner (string): The Market process owner
Handlers.add("Info", {Action = "Info"}, function(msg)
  Market:info(msg)
end)

--[[
===================
CPMM WRITE HANDLERS
===================
]]

--- Add funding handler
--- @notice On error the funding is returned to the sender
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity (string): The amount of funding to add (numeric string).
--- - msg.Tags.Distribution (stringified table):
---   * JSON-encoded table specifying the initial distribution of funding.
---   * Required on the first call to `addFunding`.
---   * Must NOT be included in subsequent calls, or the operation will fail.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the LP tokens.
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Notice`: **collateral → provider**     -- Transfers collateral tokens from the provider
--- - `Credit-Notice`: **collateral → market**   -- Transfers collateral tokens to the market
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Add-Funding-Error`: **market → provider** -- Returns an error message
--- - `Debit-Notice`: **collateral → market**     -- Returns collateral tokens from the market
--- - `Credit-Notice`: **collateral → provider**   -- Returns collateral tokens to the provider
--- **✨ Interim Notices (Default silenced) **
--- - `Mint-Batch-Notice`: **market → market**      -- Mints position tokens to the market
--- - `Split-Position-Notice`: **market → market**  -- Splits collateral into position tokens
--- - `Mint-Notice`: **market → provider**             -- Mints LP tokens to the provider
--- **✅ Success Notice (Default broadcast)**
--- - `Log-Funding-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the funding
--- **📊 Logging & Analytics**
--- - `Add-Funding-Notice`: **market → provider**  -- Logs the add funding action
--- @note **Replies with the following tags:**
--- Action (string): "Add-Funding-Notice"
--- FundingAdded (string) The amount of funding added for each position ID (stringified table)
--- MintAmount (string): The amount of LP tokens minted (numeric string)
--- OnBehalfOf (string): The address of the account to receive the LP tokens
--- Data (string): "Successfully added funding"
Handlers.add("Add-Funding", isAddFunding, function(msg)
  -- Validate input
  local success, err = cpmmValidation.addFunding(msg, Market.cpmm.token.totalSupply, Market.cpmm.tokens.positionIds)
  -- If validation fails, return funds to sender and provide error response.
  if not success then
    msg.reply({
      Action = "Transfer",
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      ["X-Action"] = "Add-Funding-Error",
      ["X-Error"] = err
    })
    return
  end
  -- If validation passes, add funding to the CPMM.
  Market:addFunding(msg)
end)

--- Remove funding handler
--- @notice Calling `marketRemoveFunding` will simultaneously return the liquidity provider's share of accrued fees
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity (string): The amount of LP tokens to burn (numeric string).
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the position tokens.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Remove-Funding-Error`: **market → provider** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Withdraw-Fees-Notice`: **market → provider**  -- Distributes accrued LP fees to the provider
--- - `Burn-Notice`: **market → market**  -- Burns the returned LP tokens
--- - `Debit-Batch-Notice`: **market → market** -- Transfers position tokens from the market
--- - `Credit-Batch-Notice`: **market → provider** -- Transfers position tokens to the provider
--- **📊 Logging & Analytics**
--- - `Log-Funding-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the funding
--- **✅ Success Notice (Default broadcast)**
--- - `Remove-Funding-Notice`: **market → provider** -- Logs the remove funding action
--- @note **Replies with the following tags:**
--- Action (string): "Remove-Funding-Notice"
--- SendAmounts (string): The amount of position tokens returned for each ID (stringified table)
--- CollateralRemovedFromFeePool (string): The amount of collateral removed from the fee pool (numeric string)
--- SharesToBurn (string): The amount of LP tokens to burn (numeric string)
--- OnBehalfOf (string): The address of the account to receive the position tokens
--- Data (string): "Successfully removed funding"
Handlers.add("Remove-Funding", {Action = "Remove-Funding"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.removeFunding(msg, Market.cpmm.token.balances[msg.From])
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Remove-Funding-Error",
      Error = err
    })
    return
  end
  -- If validation passes, remove funding from the CPMM.
  Market:removeFunding(msg)
end)

--- Buy handler
--- @warning Ensure sufficient liquidity exists before calling `marketBuy`, or the transaction may fail
--- @use Call `marketCalcBuyAmount` to verify liquidity and the number of outcome position tokens to be purchased
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity (string): The amount of collateral tokens transferred, i.e. the investment amount (numeric string).
--- - msg.Tags["X-PositionId"] (string): The position ID of the outcome token to purchase.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the position tokens.
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Notice`: **collateral → buyer**     -- Transfers collateral from the buyer
--- - `Credit-Notice`: **collateral → market**   -- Transfers collateral to the market
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Buy-Error`: **market → sender** -- Returns an error message
--- - `Debit-Notice`: **collateral → market**     -- Returns collateral from the market
--- - `Credit-Notice`: **collateral → buyer**   -- Returns collateral to the buyer
--- **✨ Interim Notices (Default silenced)**
--- - `Mint-Batch-Notice`: **market → market**      -- Mints new position tokens
--- - `Split-Position-Notice`: **market → market**  -- Splits collateral into position tokens
--- - `Debit-Single-Notice`: **market → market**    -- Transfers position tokens from the market
--- - `Credit-Single-Notice`: **market → buyer**    -- Transfers position tokens to the buyer
--- **📊 Logging & Analytics**
--- - `Log-Prediction-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the prediction
--- - `Log-Probabilities-Notice`: **market → Outcome.dataIndex**                            -- Logs the updated probabilities
--- **✅ Success Notice (Default broadcast)**
--- - `Buy-Notice`: **market → buyer**  -- Logs the buy action
--- @note **Replies with the following tags:**
--- Action (string): "Buy-Notice"
--- OnBehalfOf (string): The address of the account to receive the position tokens
--- InvestmentAmount (string): The amount of collateral tokens transferred, i.e. the investment amount (numeric string).
--- FeeAmount (string): The amount of fees paid (numeric string).
--- PositionId (string): The position ID of the outcome token purchased.
--- PositionTokensBought (string): The amount of outcome position tokens purchased (numeric string).
--- Data (string): "Successfully bought"
Handlers.add("Buy", isBuy, function(msg)
  -- Validate input
  local success, err = cpmmValidation.buy(msg, Market.cpmm)
  -- If validation fails, return funds to sender and provide error response.
  if not success then
    msg.reply({
      Action = "Transfer",
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      ["X-Action"] = "Buy-Error",
      ["X-Error"] = err
    })
    return
  end
  -- If validation passes, buy from the CPMM.
  Market:buy(msg)
end)

--- Sell handler
--- @warning Ensure sufficient liquidity exists before calling `marketSell`, or the transaction may fail
--- @use Call `marketCalcSellAmount` to verify liquidity and the number of outcome position tokens to be sold
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to sell.
--- - msg.Tags.MaxPositionTokensToSell (string) The maximum number of position tokens to sell (numeric string).
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the collateral tokens.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Sell-Error`: **market → seller** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Single-Notice`: **market → seller**     -- Transfers sold position tokens from the seller
--- - `Credit-Single-Notice`: **market → market**   -- Transfers sold position tokens to the market
--- - `Batch-Burn-Notice`: **market → market**      -- Burns sold position tokens
--- - `Merge-Positions-Notice`: **market → market** -- Merges sold position tokens back to collateral
--- - `Debit-Notice`: **collateral → market**       -- Transfers collateral from the seller
--- - `Credit-Notice`: **collateral → seller**       -- Transfers collateral to the buyer
--- - `Debit-Single-Notice`: **market → seller**     -- Returns unburned position tokens from the market
--- - `Credit-Single-Notice`: **market → market**   -- Returns unburned position tokens to the seller
--- **📊 Logging & Analytics**
--- - `Log-Prediction-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the prediction
--- - `Log-Probabilities-Notice`: **market → Outcome.dataIndex**                            -- Logs the updated probabilities
--- **✅ Success Notice (Default broadcast)**
--- - `Sell-Notice`: **market → seller** -- Logs the sell action
--- @note **Replies with the following tags:**
--- Action (string): "Sell-Notice"
--- OnBehalfOf (string): The address of the account to receive the collateral tokens
--- ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- FeeAmount (string): The amount of fees paid (numeric string).
--- PositionId (string): The position ID of the outcome token sold.
--- PositionTokensSold (string): The amount of outcome position tokens sold (numeric string).
--- Data (string): "Successfully sold"
Handlers.add("Sell", {Action = "Sell"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.sell(msg, Market.cpmm)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Sell-Error",
      Error = err
    })
    return
  end
  -- If validation passes, sell to the CPMM.
  Market:sell(msg)
end)

--- Withdraw fees handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Withdraw-Fees-Error`: **market → provider** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Notice`: **collateral → market**  -- Transfers LP fees from the market
--- - `Credit-Notice`: **collateral → provider**  -- Transfers LP fees to the provider
--- **✅ Success Notice (Default broadcast)**
--- - `Withdraw-Fees-Notice`: **market → provider** -- Logs the withdraw fees action
--- @note **Replies with the following tags:**
--- Action (string): "Withdraw-Fees-Notice"
--- OnBehalfOf (string): The address of the account to receive the fees
--- FeeAmount (string): The amount of fees withdrawn (numeric string).
--- Data (string): "Successfully withdrew fees"
Handlers.add("Withdraw-Fees", {Action = "Withdraw-Fees"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.withdrawFees(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Withdraw-Fees-Error",
      Error = err
    })
    return
  end
  -- If validation passes, withdraw fees from the CPMM.
  Market:withdrawFees(msg)
end)

--[[
==================
CPMM READ HANDLERS
==================
]]

--- Calc buy amount handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.InvestmentAmount (string): The amount of collateral tokens to invest (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to purchase.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Calc-Buy-Amount-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - BuyAmount (string): The amount of outcome tokens to purchase (numeric string).
--- - PositionId (string): The position ID of the outcome token to purchase.
--- - InvestmentAmount (string): The amount of collateral tokens to invest (numeric string).
--- - Data (string): The BuyAmount.
Handlers.add("Calc-Buy-Amount", {Action = "Calc-Buy-Amount"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.calcBuyAmount(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Calc-Buy-Amount-Error",
      Error = err
    })
    return
  end
  -- If validation passes, calculate the buy amount.
  Market:calcBuyAmount(msg)
end)

--- Calc sell amount handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to sell.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Calc-Sell-Amount-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - SellAmount (string): The amount of outcome tokens to sell (numeric string).
--- - PositionId (string): The position ID of the outcome token to sell.
--- - ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- - Data (string): The SellAmount.
Handlers.add("Calc-Sell-Amount", {Action = "Calc-Sell-Amount"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.calcSellAmount(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Calc-Sell-Amount-Error",
      Error = err
    })
    return
  end
  -- If validation passes, calculate the sell amount.
  Market:calcSellAmount(msg)
end)

--- Colleced fees handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - CollectedFees (string): The total unwithdrawn fees collected by the CPMM (numeric string).
--- - Data (string): The CollectedFees.
Handlers.add("Collected-Fees", {Action = "Collected-Fees"}, function(msg)
  Market:collectedFees(msg)
end)

--- Fees withdrawable handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the queried account.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Fees-Withdrawable-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - FeesWithdrawable (string): The total fees withdrawable by the account (numeric string).
--- - Account (string): The address of the queried account.
--- - Data (string): The FeesWithdrawable.
Handlers.add("Fees-Withdrawable", {Action = "Fees-Withdrawable"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.feesWithdrawable(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Fees-Withdrawable-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get fees withdrawable.
  Market:feesWithdrawable(msg)
end)

--[[
=======================
LP TOKEN WRITE HANDLERS
=======================
]]

--- Transfer handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the account to receive the LP tokens.
--- - msg.Tags.Quantity (string): The amount of LP tokens to transfer (numeric string).
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (string, optional) The sendInterim is set to send interim notices.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Transfer-Error`: **market → sender** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Notice`: **collateral → market**  -- Transfers LP fees from the market
--- - `Credit-Notice`: **collateral → provider**  -- Transfers LP fees to the provider
--- - `Withdraw-Fees-Notice`: **market → provider** -- Logs the withdraw fees action
--- **✅ Success Notices (Sent if `msg.Tags.Cast = nil`)**
--- - `Debit-Notice`: **market → provider**      -- Transfers LP tokens from the provider
--- - `Credit-Notice`: **market → recipient** -- Transfers LP tokens to the recipient
--- @note **Replies with the following tags:**
--- - Action (string): "Debit-Notice"
--- - Recipient (string): The address of the account to receive the LP tokens.
--- - Quantity (string): The amount of LP tokens transferred (numeric string).
--- - Data (string): "You transferred..."
--- - X-[Tag] (string): Any forwarded x-tags
Handlers.add('Transfer', {Action = "Transfer"}, function(msg)
  -- Validate input
  local success, err = tokenValidation.transfer(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Transfer-Error",
      Error = err
    })
    return
  end
  -- If validation passes, transfer the LP tokens.
  Market:transfer(msg)
end)

--[[
======================
LP TOKEN READ HANDLERS
======================
]]

--- Balance handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string, optional): The address of the account to query.
--- - msg.Tags.Target (string, optional): The address of the account to query (alternative option).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Balance-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - Balance (string): The LP token balance of the account (numeric string).
--- - Ticker (string): The LP token ticker.
--- - Account (string): The address of the queried account.
--- - Data (string): The Balance.
Handlers.add('Balance', {Action = "Balance"}, function(msg)
  -- Validate input
  local success, err = tokenValidation.balance(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Balance-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the LP token balance.
  Market:balance(msg)
end)

--- Balances handler
--- @warning Not recommended for production use; returns an unbounded amount of data.
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string) Balances of all LP token holders (stringified table).
Handlers.add('Balances', {Action = "Balances"}, function(msg)
  Market:balances(msg)
end)

--- Total supply handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string): The total supply of LP tokens (numeric string).
Handlers.add('Total-Supply', {Action = "Total-Supply"}, function(msg)
  Market:totalSupply(msg)
end)

--[[
=================================
CONDITIONAL TOKENS WRITE HANDLERS
=================================
]]

--- Merge positions handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity The quantity of outcome position tokens from each position ID to merge for collataral
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the position tokens.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Merge-Positions-Error`: **market → sender** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Burn-Batch-Notice`: **market → holder** -- Burns the position tokens
--- - `Debit-Notice`: **collateral → market** -- Transfers collateral from the market
--- - `Credit-Notice`: **collateral → onBehalfOf** -- Transfers collateral to onBehalfOf
--- **✅ Success Notice (Default broadcast)**
--- - `Merge-Positions-Notice`: **market → holder**  -- Logs the merge positions action
--- @note **Replies with the following tags:**
--- - Action (string): "Merge-Positions-Notice"
--- - OnBehalfOf (string): The address of the account to receive the collateral tokens
--- - Quantity (string): The quantity of outcome position tokens merged for collateral (numeric string)
--- - CollateralToken (string): The collateral token process ID
--- - Data (string): "Successfully merged positions"
Handlers.add("Merge-Positions", {Action = "Merge-Positions"}, function(msg)
  -- Validate input
  local success, err = conditionalTokensValidation.mergePositions(msg, Market.cpmm)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Merge-Positions-Error",
      Error = err
    })
    return
  end
  -- If validation passes, merge the positions.
  Market:mergePositions(msg)
end)

--- Report payouts handler
--- @warning Only callable by the resolution agent, and once, or the transaction will fail
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Payouts (stringified table): The payouts to report
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Replort-Payouts-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
---  - `Report-Payouts-Notice`: **market → resolutionAgent** -- Logs the report payouts action
--- @note **Replies with the following tags:**
--- - Action (string): "Report-Payouts-Notice"
--- - ResolutionAgent (string): The resolution agent process ID
--- - PayoutNumerators (string): The payout numerators for each outcome slot (stringified table)
--- - Data (string): "Successfully reported payouts"
Handlers.add("Report-Payouts", {Action = "Report-Payouts"}, function(msg)
  -- Validate input
  local success, err = conditionalTokensValidation.reportPayouts(msg, Market.cpmm.tokens.resolutionAgent)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Report-Payouts-Error",
      Error = err
    })
    return
  end
  -- If validation passes, report the payouts.
  Market:reportPayouts(msg)
end)

--- Redeem positions handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the collateral tokens.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Redeem-Positions-Error`: **market → sender** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Burn-Single-Notice`: **market → holder**    -- Burns redeemed position tokens (for each position ID held by the sender)
--- - `Debit-Notice`: **collateral → market**     -- Transfers collateral from the market
--- - `Credit-Notice`: **collateral → onBehalfOf**     -- Transfers collateral to onBehalfOf
--- **✅ Success Notice**
--- - `Redeem-Positions-Notice`: **market → holder** -- Logs the redeem positions action
--- @note **Replies with the following tags:**
--- - Action (string): "Redeem-Positions-Notice"
--- - CollateralToken (string): The collateral token process ID
--- - GrossPayout (string): The gross payout amount, before fees (numeric string)
--- - NetPayout (string): The net payout amount, after fees (numeric string)
--- - OnBehalfOf (string): The address of the account to receive the collateral tokens
--- - Data (string): "Successfully redeemed positions"
Handlers.add("Redeem-Positions", {Action = "Redeem-Positions"}, function(msg)
  -- Validate input
  local success, err = conditionalTokensValidation.redeemPositions(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Redeem-Positions-Error",
      Error = err
    })
    return
  end
  -- If validation passes, redeem positions.
  Market:redeemPositions(msg)
end)

--[[
================================
CONDITIONAL TOKENS READ HANDLERS
================================
]]

--- Get payout numerators handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string): The payout numerators (stringified table).
Handlers.add("Get-Payout-Numerators", {Action = "Get-Payout-Numerators"}, function(msg)
  Market:getPayoutNumerators(msg)
end)

--- Get payout denominator handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- @note - Data (string): The payout denominator (numeric string).
Handlers.add("Get-Payout-Denominator", {Action = "Get-Payout-Denominator"}, function(msg)
  Market:getPayoutDenominator(msg)
end)

--[[
===================================
SEMI-FUNGIBLE TOKENS WRITE HANDLERS
===================================
]]

--- Transfer single handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the account to receive the position tokens.
--- - msg.Tags.Quantity (string): The amount of position tokens to transfer (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to transfer.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Transfer-Single-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice (Default broadcast)**
--- - `Debit-Single-Notice`: **market → sender** -- Transfers tokens from the sender
--- - `Credit-Single-Notice`: **market → recipient** -- Transfers tokens to the recipient
--- @note **Replies with the following tags:**
--- - Action (string): "Debit-Single-Notice"
--- - Recipient (string): The address of the account to receive the position tokens.
--- - Quantity (string): The amount of position tokens transferred (numeric string).
--- - PositionId (string): The position ID of the outcome token transferred.
--- - Data (string): "You transferred..."
--- - X-[Tag] (string): Any forwarded x-tags
Handlers.add("Transfer-Single", {Action = "Transfer-Single"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.transferSingle(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Transfer-Single-Error",
      Error = err
    })
    return
  end
  -- If validation passes, execute transfer single.
  Market:transferSingle(msg)
end)

--- Transfer batch handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the account to receive the position tokens.
--- - msg.Tags.PositionIds (stringified table): The position IDs of the outcome tokens to transfer.
--- - msg.Tags.Quantities (stringified table): The amounts of position tokens to transfer.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Transfer-Batch-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notices (Sent if `msg.Tags.Cast = nil`)**
--- - `Debit-Batch-Notice`: **market → sender** -- Transfers tokens from the sender
--- - `Credit-Batch-Notice`: **market → recipient** -- Transfers tokens to the recipient
--- @note **Replies with the following tags:**
--- - Action (string): "Debit-Batch-Notice"
--- - Recipient (string): The address of the account to receive the position tokens.
--- - PositionIds (string): The IDs of the position tokens transferred (stringified table).
--- - Quantities (string): The amounts of position tokens transferred (stringified table).
--- - Data (string): "You transferred..."
--- - X-[Tag] (string): Any forwarded x-tags
Handlers.add('Transfer-Batch', {Action = "Transfer-Batch"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.transferBatch(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Transfer-Batch-Error",
      Error = err
    })
    return
  end
  -- If validation passes, execute transfer batch.
  Market:transferBatch(msg)
end)

--[[
==================================
SEMI-FUNGIBLE TOKENS READ HANDLERS
==================================
]]

--- Balance by ID handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionId (string): The position ID of the outcome token to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Balance-By-Id-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - Balance (string): The balance of the account (numeric string).
--- - PositionId (string): The position ID of the outcome token.
--- - Account (string): The address of the queried account.
--- - Data (string): The Balance.
Handlers.add("Balance-By-Id", {Action = "Balance-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.balanceById(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Balance-By-Id-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the balance by ID.
  Market:balanceById(msg)
end)

--- Balances by ID handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionId (string): The position ID of the outcome token to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Balances-By-Id-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionId (string): The position ID of the outcome token.
--- - Data (string): The balances of all accounts filtered by ID (stringified table).
Handlers.add('Balances-By-Id', {Action = "Balances-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.balancesById(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Balances-By-Id-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the balances by ID.
  Market:balancesById(msg)
end)

--- Batch balance handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipients (stringified table): The addresses of the accounts to query.
--- - msg.Tags.PositionIds (stringified table): The position IDs of the outcome tokens to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Batch-Balance-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionIds (string): The position IDs of the outcome tokens.
--- - Data (string): The balances of all accounts filtered by IDs (stringified table).
Handlers.add("Batch-Balance", {Action = "Batch-Balance"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.batchBalance(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Batch-Balance-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the batch balance.
  Market:batchBalance(msg)
end)

--- Batch balances handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionIds (stringified table): The position IDs of the outcome tokens to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Batch-Balances-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionIds (string): The position IDs of the outcome tokens.
--- - Data (string): The balances of all accounts filtered by ID (stringified table).
Handlers.add('Batch-Balances', {Action = "Batch-Balances"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.batchBalances(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Batch-Balances-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the batch balances.
  Market:batchBalances(msg)
end)

--- Balances all handler
--- @warning Not recommended for production use; returns an unbounded amount of data.
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string): Balances of all accounts (stringified table).
Handlers.add('Balances-All', {Action = "Balances-All"}, function(msg)
  Market:balancesAll(msg)
end)

--- Logo by ID handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionId (string): The position ID of the outcome token to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Logo-By-Id-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionId (string): The position ID of the outcome token.
--- - Data (string): The logo of the outcome token.
Handlers.add('Logo-By-Id', {Action = "Logo-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.logoById(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Logo-By-Id-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the logo by ID.
  Market:logoById(msg)
end)

--- Logos handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string): Logos of all outcome tokens (stringified table).
Handlers.add('Logos', {Action = "Logos"}, function(msg)
  Market:logos(msg)
end)

--[[
===========================
CONFIGURATOR WRITE HANDLERS
===========================
]]

--- Update configurator handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Configurator (string): The new configurator.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Configurator-Error`: **market → sender** -- Returns an error message
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Configurator-Notice`: **market → sender** -- Logs the update configurator action
Handlers.add('Update-Configurator', {Action = "Update-Configurator"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateConfigurator(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Configurator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the configurator.
  Market:updateConfigurator(msg)
end)

--- Update data index handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.DataIndex (string): The new data index.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Data-Index-Error`: **market → sender** -- Returns an error message
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-DataIndex-Notice`: **market → sender** -- Logs the update data index action
Handlers.add("Update-Data-Index", {Action = "Update-Data-Index"}, function(msg)
  -- Validate input
  local success, err = marketValidation.updateDataIndex(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Data-Index-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the data index.
  Market:updateDataIndex(msg)
end)

--- Update take fee handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.TakeFee (string): The new take fee.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Take-Fee-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-TakeFee-Notice`: **market → sender** -- Logs the update take fee action
Handlers.add('Update-Take-Fee', {Action = "Update-Take-Fee"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateTakeFee(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Take-Fee-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the take fee.
  Market:updateTakeFee(msg)
end)

--- Update protocol fee target handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ProtocolFeeTarget (string): The new protocol fee target.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Protocol-Fee-Target-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-ProtocolFeeTarget-Notice`: **market → sender** -- Logs the update protocol fee target action
Handlers.add('Update-Protocol-Fee-Target', {Action = "Update-Protocol-Fee-Target"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateProtocolFeeTarget(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Protocol-Fee-Target-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the protocol fee target.
  Market:updateProtocolFeeTarget(msg)
end)

--- Update logo handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Logo (string): The new logo.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Logo-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-Logo-Notice`: **market → sender** -- Logs the update logo action
Handlers.add('Update-Logo', {Action = "Update-Logo"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateLogo(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Logo-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the logo.
  Market:updateLogo(msg)
end)

--- Update logos handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Logos (stringified table): The new logos.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Logos-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-Logos-Notice`: **market → sender** -- Logs the update logos action
Handlers.add('Update-Logos', {Action = "Update-Logos"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateLogos(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Logos-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the logos.
  Market:updateLogos(msg)
end)

return "ok"

]===]