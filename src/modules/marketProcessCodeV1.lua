return [===[


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

-- module: "modules.cpmmHelpers"
local function _loaded_mod_modules_cpmmHelpers()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local bint = require('.bint')(256)
local ao = require('.ao')
local json = require('json')

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
--- @param distribution table<number> The distribution of funding
--- @return boolean True if error
function CPMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''
  -- Ensure distribution
  if not distribution then
    error = true
    errorMessage = 'X-Distribution is required!'
  elseif not error then
    if bint.iszero(bint(self.token.totalSupply)) then
      -- Ensure distribution is set across all position ids
      if #distribution ~= #self.tokens.positionIds then
        error = true
        errorMessage = "Distribution length mismatch"
      end
    else
      -- Ensure distribution set only for initial funding
      if bint.__lt(0, #distribution) then
        error = true
        errorMessage = "Cannot specify distribution after initial funding"
      end
    end
  end
  if error then
    -- Return funds and assert error
    ao.send({
      Target = self.tokens.collateralToken,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Add-Funding Error: ' .. errorMessage
    })
  end
  return not error
end

--- Validate remove funding
--- Returns LP tokens to sender on error
--- @param from string The address of the sender
--- @param quantity number The amount of funding to remove
--- @return boolean True if error
function CPMMHelpers:validateRemoveFunding(from, quantity)
  local error = false
  local errorMessage = ''
  -- Get balance
  local balance = self.token.balances[from] or '0'
  -- Check for errors
  if from == self.creatorFeeTarget and self.payoutDenominator and self.payoutDenominator == 0 then
    error = true
    errorMessage = 'Creator liquidity locked until market resolution!'
  elseif not bint.__le(bint(quantity), bint(balance)) then -- @dev TODO: remove as will never be called?
    error = true
    errorMessage = 'Quantity must be less than balance!'
  end
  -- Return funds on error.
  if error then
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
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

_G.package.loaded["modules.cpmmHelpers"] = _loaded_mod_modules_cpmmHelpers()

-- module: "modules.cpmmNotices"
local function _loaded_mod_modules_cpmmNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local ao = require('.ao')
local json = require('json')

local CPMMNotices = {}

--- Sends a funding added notice
--- @param from string The address that added funding
--- @param fundingAdded table The funding added
--- @param mintAmount number The mint amount
--- @return Message The funding added notice
function CPMMNotices.fundingAddedNotice(from, fundingAdded, mintAmount)
  return ao.send({
    Target = from,
    Action = "Funding-Added-Notice",
    FundingAdded = json.encode(fundingAdded),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

--- Sends a funding removed notice
--- @param from string The address that removed funding
--- @param sendAmounts table The send amounts
--- @param collateralRemovedFromFeePool number The collateral removed from the fee pool
--- @param sharesToBurn number The shares to burn
--- @return Message The funding removed notice
function CPMMNotices.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  return ao.send({
    Target = from,
    Action = "Funding-Removed-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
    SharesToBurn = tostring(sharesToBurn),
    Data = "Successfully removed funding"
  })
end

--- Sends a buy notice
--- @param from string The address that bought
--- @param investmentAmount number The investment amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param outcomeTokensToBuy number The outcome tokens to buy
--- @return Message The buy notice
function CPMMNotices.buyNotice(from, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
  return ao.send({
    Target = from,
    Action = "Buy-Notice",
    InvestmentAmount = tostring(investmentAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    OutcomeTokensToBuy = tostring(outcomeTokensToBuy),
    Data = "Successful buy order"
  })
end

--- Sends a sell notice
--- @param from string The address that sold
--- @param returnAmount number The return amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param outcomeTokensToSell number The outcome tokens to sell
--- @return Message The sell notice
function CPMMNotices.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
  return ao.send({
    Target = from,
    Action = "Sell-Notice",
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    OutcomeTokensToSell = tostring(outcomeTokensToSell),
    Data = "Successful sell order"
  })
end

--- Sends an update configurator notice
--- @param configurator string The updated configurator address
--- @param msg Message The message received
--- @return Message The configurator updated notice
function CPMMNotices.updateConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Configurator-Updated",
    Data = configurator
  })
end

--- Sends an update incentives notice
--- @param incentives string The updated incentives address
--- @param msg Message The message received
--- @return Message The incentives updated notice
function CPMMNotices.updateIncentivesNotice(incentives, msg)
  return msg.reply({
    Action = "Incentives-Updated",
    Data = incentives
  })
end

--- Sends an update take fee notice
--- @param creatorFee string The updated creator fee
--- @param protocolFee string The updated protocol fee
--- @param takeFee string The updated take fee
--- @param msg Message The message received
function CPMMNotices.updateTakeFeeNotice(creatorFee, protocolFee, takeFee, msg)
  return msg.reply({
    Action = "Take-Fee-Updated",
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
    Action = "Protocol-Fee-Target-Updated",
    Data = protocolFeeTarget
  })
end

--- Sends an update logo notice
--- @param logo string The updated logo
--- @param msg Message The message received
--- @return Message The logo updated notice
function CPMMNotices.updateLogoNotice(logo, msg)
  return msg.reply({
    Action = "Logo-Updated",
    Data = logo
  })
end

return CPMMNotices
end

_G.package.loaded["modules.cpmmNotices"] = _loaded_mod_modules_cpmmNotices()

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

-- module: "modules.tokenNotices"
local function _loaded_mod_modules_tokenNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

local ao = require('.ao')
local TokenNotices = {}

--- Mint notice
--- @param recipient string The address that will own the minted tokens
--- @param quantity string The quantity of tokens to mint
--- @param msg Message The message received
--- @return Message The mint notice
function TokenNotices.mintNotice(recipient, quantity, msg)
  return msg.reply({
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
  return msg.reply({
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

--- Transfer notices
--- @param debitNotice Message The notice to send the spender
--- @param creditNotice Message The notice to send the receiver
--- @param msg Message The mesage received
--- @return table<Message> The transfer notices
function TokenNotices.transferNotices(debitNotice, creditNotice, msg)
  return { msg.reply(debitNotice), ao.send(creditNotice) }
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

_G.package.loaded["modules.tokenNotices"] = _loaded_mod_modules_tokenNotices()

-- module: "modules.token"
local function _loaded_mod_modules_token()
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
local TokenMethods = require('modules.tokenNotices')
local TokenNotices = require('modules.tokenNotices')
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
        Target = from,
        Action = 'Debit-Notice',
        Recipient = recipient,
        Quantity = quantity,
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. quantity .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
      }
      -- Credit-Notice message template, that is sent to the Recipient of the transfer
      local creditNotice = {
        Target = recipient,
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
      return self.transferNotices(debitNotice, creditNotice, msg)
    end
  else
    return self.transferErrorNotice(msg)
  end
end

return Token

end

_G.package.loaded["modules.token"] = _loaded_mod_modules_token()

-- module: "modules.constants"
local function _loaded_mod_modules_constants()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local constants = {}
local json = require('json')
-- Market Factory
constants.configurator = "test-this-is-valid-arweave-wallet-address-1"
constants.incentives = "test-this-is-valid-arweave-wallet-address-2"
constants.collateralToken = "test-this-is-valid-arweave-wallet-address-3"
constants.conditionId = "test-this-is-valid-condition-id-1"
constants.positionIds = json.encode({"1", "2"})
constants.marketName = "Outcome Market"
constants.marketTicker = "OUTCOME"
constants.marketLogo = "https://test.com/logo.png"
constants.lpFee = "100"
constants.creatorFee = "250"
constants.creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-4"
constants.protocolFee = "250"
constants.protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-5"
constants.maximumTakeFee = "500"
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
-- CPMM
constants.denomination = 12

return constants
end

_G.package.loaded["modules.constants"] = _loaded_mod_modules_constants()

-- module: "modules.conditionalTokensNotices"
local function _loaded_mod_modules_conditionalTokensNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local json = require('json')
local ao = ao or require('.ao')

local ConditionalTokensNotices = {}

--- Condition resolution notice
--- @param conditionId string The condition ID
--- @param resolutionAgent string The process assigned to report the result for the prepared condition
--- @param questionId string An identifier for the question to be answered by the resolutionAgent
--- @param outcomeSlotCount number The number of outcome slots
--- @param payoutNumerators table<number> The payout numerators for each outcome slot
--- @param msg Message The message received
--- @return Message The condition resolution notice
function ConditionalTokensNotices.conditionResolutionNotice(conditionId, resolutionAgent, questionId, outcomeSlotCount, payoutNumerators, msg)
  return msg.reply({
    Action = "Condition-Resolution-Notice",
    ConditionId = conditionId,
    ResolutionAgent = resolutionAgent,
    QuestionId = questionId,
    OutcomeSlotCount = tostring(outcomeSlotCount),
    PayoutNumerators = json.encode(payoutNumerators)
  })
end

--- Position split notice
--- @param from string The address of the account that split the position
--- @param collateralToken string The address of the collateral token
--- @param conditionId string The condition ID
--- @param quantity string The quantity
--- @param msg Message The message received
--- @return Message The position split notice
function ConditionalTokensNotices.positionSplitNotice(from, collateralToken, conditionId, quantity, msg)
  local notice = {
    Action = "Split-Position-Notice",
    Process = ao.id,
    Stakeholder = from,
    CollateralToken = collateralToken,
    ConditionId = conditionId,
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
--- @param conditionId string The condition ID
--- @param quantity string The quantity
--- @param msg Message The message received
--- @return Message The positions merge notice
function ConditionalTokensNotices.positionsMergeNotice(conditionId, quantity, msg)
  return msg.reply({
    Action = "Merge-Positions-Notice",
    ConditionId = conditionId, -- TODO: Check if this is needed
    Quantity = quantity
  })
end

--- Payout redemption notice
--- @param collateralToken string The address of the collateral token
--- @param conditionId string The condition ID
--- @param payout string The payout amount
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensNotices.payoutRedemptionNotice(collateralToken, conditionId, payout, msg)
  return msg.reply({
    Action = "Payout-Redemption-Notice",
    Process = ao.id,
    CollateralToken = collateralToken,
    ConditionId = conditionId,
    Payout = tostring(payout)
  })
end

return ConditionalTokensNotices

end

_G.package.loaded["modules.conditionalTokensNotices"] = _loaded_mod_modules_conditionalTokensNotices()

-- module: "modules.semiFungibleTokensNotices"
local function _loaded_mod_modules_semiFungibleTokensNotices()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See semiFungibleTokens.lua for full license details.
=========================================================
]]

local ao = require('.ao')
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
    TokenId = tostring(id),
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
  return msg.reply({
    Recipient = to,
    TokenIds = json.encode(ids),
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
--- @return Message The burn notice
function SemiFungibleTokensNotices.burnSingleNotice(from, id, quantity, msg)
  -- Prepare notice
  local notice = {
    Recipient = from,
    TokenId = tostring(id),
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
  return msg.reply(notice)
end

--- Burn batch notice
--- @param notice Message The prepared notice to be sent
--- @param msg Message The message received
--- @return Message The burn notice
function SemiFungibleTokensNotices.burnBatchNotice(notice, msg)
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice
  return msg.reply(notice)
end

--- Transfer single token notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param id string The ID of the token to be transferred
--- @param quantity string The quantity of the token to be transferred
--- @param msg Message The message received
--- @return table<Message> The debit and credit transfer notices
function SemiFungibleTokensNotices.transferSingleNotices(from, to, id, quantity, msg)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Single-Notice',
    Recipient = to,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " to " .. Colors.green .. to .. Colors.reset
  }
  -- Prepare credit notice
  local creditNotice = {
    Target = to,
    Action = 'Credit-Single-Notice',
    Sender = from,
    TokenId = tostring(id),
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
  return { msg.reply(debitNotice), ao.send(creditNotice) }
end

--- Transfer batch tokens notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param ids table<string> The IDs of the tokens to be transferred
--- @param quantities table<string> The quantities of the tokens to be transferred
--- @param msg Message The message received
--- @return table<Message> The debit and credit batch transfer notices
function SemiFungibleTokensNotices.transferBatchNotices(from, to, ids, quantities, msg)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Batch-Notice',
    Recipient = to,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You transferred batch to " .. Colors.green .. to .. Colors.reset
  }
  -- Prepare credit notice
  local creditNotice = {
    Target = to,
    Action = 'Credit-Batch-Notice',
    Sender = from,
    TokenIds = json.encode(ids),
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
  return {msg.reply(debitNotice), ao.send(creditNotice)}
end

--- Transfer error notice
--- @param id string The ID of the token to be transferred
--- @param msg Message The message received
--- @return Message The transfer error notice
function SemiFungibleTokensNotices.transferErrorNotice(id, msg)
  return msg.reply({
    Action = 'Transfer-Error',
    ['Message-Id'] = msg.Id,
    ['Token-Id'] = id,
    Error = 'Insufficient Balance!'
  })
end

return SemiFungibleTokensNotices

end

_G.package.loaded["modules.semiFungibleTokensNotices"] = _loaded_mod_modules_semiFungibleTokensNotices()

-- module: "modules.semiFungibleTokens"
local function _loaded_mod_modules_semiFungibleTokens()
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
local SemiFungibleTokensNotices = require('modules.semiFungibleTokensNotices')
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
--- @return Message The burn notice
function SemiFungibleTokensMethods:burn(from, id, quantity, msg)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balancesById[id], 'Id must exist! ' .. id)
  assert(self.balancesById[id][from], 'Account must hold token! :: ' .. id)
  assert(bint.__le(bint(quantity), self.balancesById[id][from]), 'Account must have sufficient tokens! ' .. id)
  -- burn tokens
  self.balancesById[id][from] = tostring(bint.__sub(self.balancesById[id][from], bint(quantity)))
  self.totalSupplyById[id] = tostring(bint.__sub(self.totalSupplyById[id], bint(quantity)))
  -- send notice
  return self.burnSingleNotice(from, id, quantity, msg)
end

--- Batch burn a quantity of tokens with the given IDs
--- @param from string The process ID that will no longer own the burned tokens
--- @param ids table<string> The IDs of the tokens to burn
--- @param quantities table<string> The quantities of tokens to burn
--- @param msg Message The message received
--- @return Message The batch burn notice
function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, msg)
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
  -- draft notice
  local notice = {
    Recipient = from,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    RemainingBalances = json.encode(remainingBalances),
    Action = 'Burn-Batch-Notice',
    Data = "Successfully burned batch"
  }
  -- forward x-tags
  for tagName, tagValue in pairs(msg) do
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- send notice
  return self.burnBatchNotice(notice, msg)
end

--- Transfer a quantity of tokens with the given ID
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param id string The ID of the tokens to transfer
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, msg)
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
      return self.transferSingleNotices(from, recipient, id, quantity, msg)
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
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, msg)
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
    return self.transferBatchNotices(from, recipient, ids_, quantities_, msg)
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
--- @param tokenIds table<string> The IDs of the tokens
--- @return table<string, table<string, string>> The account balances for each respective ID
function SemiFungibleTokensMethods:getBatchBalances(tokenIds)
  local bals = {}

  for i = 1, #tokenIds do
    bals[ tokenIds[i] ] = {}
    if self.balancesById[ tokenIds[i] ] then
      bals[ tokenIds[i] ] = self.balancesById[ tokenIds[i] ]
    end
  end
  -- return balances
  return bals
end

return SemiFungibleTokens

end

_G.package.loaded["modules.semiFungibleTokens"] = _loaded_mod_modules_semiFungibleTokens()

-- module: "modules.conditionalTokens"
local function _loaded_mod_modules_conditionalTokens()
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
local ConditionalTokensNotices = require('modules.conditionalTokensNotices')
local SemiFungibleTokens = require('modules.semiFungibleTokens')
local bint = require('.bint')(256)
local crypto = require('.crypto')
local ao = require('.ao')
local json = require("json")

--- Represents ConditionalTokens
--- @class ConditionalTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logo string The token logo Arweave TxID
--- @field balancesById table<string, table<string, string>> The account token balances by ID
--- @field totalSupplyById table<string, string> The total supply of the token by ID
--- @field denomination number The number of decimals
--- @field conditionId string The condition ID
--- @field collateralToken string The process ID of the collateral token
--- @field outcomeSlotCount number The number of outcome slots
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
--- @param conditionId string The condition ID
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
  conditionId,
  collateralToken,
  positionIds,
  creatorFee,
  creatorFeeTarget,
  protocolFee,
  protocolFeeTarget
)
  ---@class ConditionalTokens : SemiFungibleTokens
  local conditionalTokens = SemiFungibleTokens:new(name, ticker, logo, balancesById, totalSupplyById, denomination)
  conditionalTokens.conditionId = conditionId
  conditionalTokens.collateralToken = collateralToken
  conditionalTokens.outcomeSlotCount = #positionIds
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
  return self.positionSplitNotice(from, collateralToken, self.conditionId, quantity, msg)
end

--- Merge positions
--- @param from string The process ID of the account that merged the positions
--- @param onBehalfOf string The process ID of the account that will receive the collateral
--- @param quantity string The quantity of collateral to merge
--- @param isSell boolean True if the merge is a sell, false otherwise
--- @param msg Message The message received
--- @return Message The positions merge notice
function ConditionalTokensMethods:mergePositions(from, onBehalfOf, quantity, isSell, msg)
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "Condition not prepared!")
  -- Create equal merge positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Burn equal quantiies from user positions.
  self:batchBurn(from, self.positionIds, quantities, msg)
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
  return self.positionsMergeNotice(self.conditionId, quantity, msg)
end

--- Report payouts
--- @param questionId string The question ID the resolution agent is answering for (TODO: remove)
--- @param payouts table<number> The resolution agent's answer
--- @param msg Message The message received
--- @return Message The condition resolution notice
function ConditionalTokensMethods:reportPayouts(questionId, payouts, msg)
  -- IMPORTANT, the payouts length accuracy is enforced because outcomeSlotCount is part of the hash.
  local outcomeSlotCount = #payouts
  assert(#payouts == self.outcomeSlotCount, "Payouts must match outcome slot count!")
  -- IMPORTANT, the resolutionAgent is enforced to be the sender because it's part of the hash.
  local conditionId = self.getConditionId(msg.From, questionId, tostring(outcomeSlotCount))
  assert(conditionId == self.conditionId, "Sender not resolution agent!")
  assert(self.payoutDenominator == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, outcomeSlotCount do
    local num = payouts[i]
    den = den + num
    assert(self.payoutNumerators[i] == 0, "payout numerator already set")
    self.payoutNumerators[i] = num
  end
  assert(den > 0, "payout is all zeroes")
  self.payoutDenominator = den
  -- Send the condition resolution notice.
  return self.conditionResolutionNotice(conditionId, msg.From, questionId, outcomeSlotCount, self.payoutNumerators, msg)
end

--- Redeem positions
--- Transfers any payout minus fees to the message sender
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensMethods:redeemPositions(msg)
  local den = self.payoutDenominator
  assert(den > 0, "result for condition not received yet")
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "condition not prepared yet")
  local totalPayout = 0
  for i = 1, #self.positionIds do
    local positionId = self.positionIds[i]
    local payoutNumerator = self.payoutNumerators[tonumber(positionId)]
    -- Get the stake to redeem.
    if not self.balancesById[positionId] then self.balancesById[positionId] = {} end
    if not self.balancesById[positionId][msg.From] then self.balancesById[positionId][msg.From] = "0" end
    local payoutStake = self.balancesById[positionId][msg.From]
    assert(bint.__lt(0, bint(payoutStake)), "no stake to redeem")
    -- Calculate the payout and burn position.
    totalPayout = math.floor(totalPayout + (payoutStake * payoutNumerator) / den)
    self:burn(msg.From, positionId, payoutStake, msg)
  end
  -- Return total payout minus take fee.
  if totalPayout > 0 then
    totalPayout = math.floor(totalPayout)
    self:returnTotalPayoutMinusTakeFee(self.collateralToken, msg.From, totalPayout)
  end
  -- Send notice.
  return self.payoutRedemptionNotice(self.collateralToken, self.conditionId, totalPayout, msg)
end

--- Get OutcomeSlotCount
--- Gets the number of outcome slots associated with a condition
---@param msg Message The message received
---@return number The number of outcome slots, zero if the condition has not been prepared
function ConditionalTokensMethods:getOutcomeSlotCount(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  return self.payoutNumerators and #self.payoutNumerators or 0
end

--- Get ConditionId
--- Constructs a condition ID from a resolutionAgent, question ID, and the outcome slot count
--- @param resolutionAgent string The process ID assigned to report the result for the prepared condition
--- @param questionId string An identifier for the question to be answered by the resolutionAgent
--- @param outcomeSlotCount string The number of outcome slots used for this condition. Must not exceed 256.
--- @return string The condition ID
function ConditionalTokensMethods.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
end

--- Return total payout minus take fee
--- Distributes payout and fees to the redeem account, creator and protocol
--- @param collateralToken string The collateral token
--- @param from string The account to receive the payout minus fees
--- @param totalPayout number The total payout assciated with the acount stake
--- @return table<Message> The protocol fee, creator fee and payout messages
function ConditionalTokensMethods:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout)
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
  return { ao.send(protocolFeeTxn), ao.send(creatorFeeTxn), ao.send(totalPayoutMinutTakeFeeTxn) }
end

return ConditionalTokens

end

_G.package.loaded["modules.conditionalTokens"] = _loaded_mod_modules_conditionalTokens()

-- module: "modules.cpmm"
local function _loaded_mod_modules_cpmm()
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
local CPMMHelpers = require('modules.cpmmHelpers')
local CPMMNotices = require('modules.cpmmNotices')
local bint = require('.bint')(256)
local ao = require('.ao')
local utils = require(".utils")
local token = require('modules.token')
local constants = require("modules.constants")
local conditionalTokens = require('modules.conditionalTokens')

--- Represents a CPMM (Constant Product Market Maker)
--- @class CPMM
--- @field incentives string The process ID of the incentives controller
--- @field configurator string The process ID of the configurator
--- @field initialized boolean The flag that is set to true once initialized
--- @field poolBalances table<string, ...> The pool balance for each respective position ID
--- @field withdrawnFees table<string, string> The amount of fees withdrawn by an account
--- @field feePoolWeight string The total amount of fees collected
--- @field totalWithdrawnFees string The total amount of fees withdrawn

--- Creates a new CPMM instance
--- @param configurator string The process ID of the configurator
--- @param incentives string The process ID of the incentives controller
--- @param collateralToken string The address of the collateral token
--- @param conditionId string The condition ID
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
function CPMM:new(configurator, incentives, collateralToken, conditionId, positionIds, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget)
  local cpmm = {
    configurator = configurator,
    incentives = incentives,
    poolBalances = {},
    withdrawnFees = {},
    feePoolWeight = "0",
    totalWithdrawnFees = "0",
    lpFee = tonumber(lpFee),
    initialized = true
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
    name .. " Conditional Token",
    ticker,
    logo,
    {}, -- balancesById
    {}, -- totalSupplyById
    constants.denomination,
    conditionId,
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
--- @param from string The process ID of the account that added the funding
--- @param onBehalfOf string The process ID of the account to receive the LP tokens
--- @param addedFunds string The amount of funds to add
--- @param distributionHint table<number, ...> The initial probability distribution
--- @param msg Message The message received
--- @return Message The funding added notice
function CPMMMethods:addFunding(from, onBehalfOf, addedFunds, distributionHint, msg)
  assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")
  local sendBackAmounts = {}
  local poolShareSupply = self.token.totalSupply
  local mintAmount = '0'

  if bint.__lt(0, bint(poolShareSupply)) then
    -- Additional Liquidity 
    assert(#distributionHint == 0, "cannot use distribution hint after initial funding")
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
  else
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
  return self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
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
    ao.send({ Target = self.tokens.collateralToken, Action = "Transfer", Recipient=from, Quantity=collateralRemovedFromFeePool})
  end
  -- Send conditionalTokens amounts
  self.tokens:transferBatch(ao.id, from, self.tokens.positionIds, sendAmounts, false, msg)
  -- Send notice
  return self.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
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

--- Buy
--- @param from string The process ID of the account that initiates the buy
--- @param onBehalfOf string The process ID of the account to receive the tokens
--- @param investmentAmount number The amount to stake on an outcome
--- @param positionId string The position ID of the outcome
--- @param minOutcomeTokensToBuy number The minimum number of outcome tokens to buy
--- @param msg Message The message received
--- @return Message The buy notice
function CPMMMethods:buy(from, onBehalfOf, investmentAmount, positionId, minOutcomeTokensToBuy, msg)
  local outcomeTokensToBuy = self:calcBuyAmount(investmentAmount, positionId)
  assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")
  -- Calculate investmentAmountMinusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.lpFee), 1e4)))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
  -- Split position through all conditions
  self.tokens:splitPosition(ao.id, self.tokens.collateralToken, investmentAmountMinusFees, msg)
  -- Transfer buy position to onBehalfOf
  self.tokens:transferSingle(ao.id, onBehalfOf, positionId, outcomeTokensToBuy, false, msg)
  -- Send notice.
  return self.buyNotice(from, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
end

--- Sell
--- Returns collateral and excess outcome tokens to the sender
--- @param from string The process ID of the account that initiates the sell
--- @param returnAmount number The amount to unstake from an outcome
--- @param positionId string The position ID of the outcome
--- @param quantity number The quantity of tokens sent for this transaction
--- @param maxOutcomeTokensToSell number The maximum number of outcome tokens to sell
--- @return Message The sell notice
function CPMMMethods:sell(from, returnAmount, positionId, quantity, maxOutcomeTokensToSell, msg)
  -- Calculate outcome tokens to sell.
  local outcomeTokensToSell = self:calcSellAmount(returnAmount, positionId)
  assert(bint.__le(bint(outcomeTokensToSell), bint(maxOutcomeTokensToSell)), "Maximum sell amount exceeded!")
  -- Calculate returnAmountPlusFees.
  local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, self.lpFee), bint.__sub(1e4, self.lpFee))))
  self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
  local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))
  -- Check sufficient liquidity within the process or revert.
  local collataralBalance = ao.send({Target = self.tokens.collateralToken, Action = "Balance"}).receive().Data
  assert(bint.__le(bint(returnAmountPlusFees), bint(collataralBalance)), "Insufficient liquidity!")
  -- Check user balance and transfer outcomeTokensToSell to process before merge.
  local balance = self.tokens:getBalance(from, nil, positionId)
  assert(bint.__le(bint(quantity), bint(balance)), 'Insufficient balance!')
  self.tokens:transferSingle(from, ao.id, positionId, outcomeTokensToSell, true, msg)
  -- Merge positions through all conditions (burns returnAmountPlusFees).
  self.tokens:mergePositions(ao.id, '', returnAmountPlusFees, true, msg)
  -- Returns collateral to the user
  ao.send({
    Target = self.tokens.collateralToken,
    Action = "Transfer",
    Quantity = returnAmount,
    Recipient = from
  }).receive()
  -- Returns unburned conditional tokens to user 
  local unburned = tostring(bint.__sub(bint(quantity), bint(returnAmountPlusFees)))
  self.tokens:transferSingle(ao.id, from, positionId, unburned, true, msg)
  -- Send notice (Process continued via "SellOrderCompletionCollateralToken" and "SellOrderCompletionConditionalTokens" handlers)
  return self.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
end

--- Colleced fees
--- @return string The total unwithdrawn fees collected by the CPMM
function CPMMMethods:collectedFees()
  return tostring(self.feePoolWeight - self.totalWithdrawnFees)
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
--- @return string The amount of fees withdrawn to the sender
function CPMMMethods:withdrawFees(sender, msg)
  local feeAmount = self:feesWithdrawableBy(sender)
  if bint.__lt(0, bint(feeAmount)) then
    self.withdrawnFees[sender] = feeAmount
    self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
    msg.forward(self.tokens.collateralToken, {Action = 'Transfer', Recipient = sender, Quantity = feeAmount})
  end
  return feeAmount
end

--- Before token transfer
--- Updates fee accounting before token transfers
--- @param from string|nil The process ID of the account executing the transaction
--- @param to string|nil The process ID of the account receiving the transaction
--- @param amount string The amount transferred
--- @param msg Message The message received
function CPMMMethods:_beforeTokenTransfer(from, to, amount, msg)
  if from ~= nil then
    self:withdrawFees(from, msg)
  end
  local totalSupply = self.token.totalSupply
  local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), bint(amount)), totalSupply)))

  if from ~= nil and to ~= nil then
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

--- Update incentives controller
--- @param incentives string The process ID of the new incentives controller
--- @param msg Message The message received
--- @return Message The update incentives notice
function CPMMMethods:updateIncentives(incentives, msg)
  self.incentives = incentives
  return self.updateIncentivesNotice(incentives, msg)
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

_G.package.loaded["modules.cpmm"] = _loaded_mod_modules_cpmm()

-- module: "modules.sharedUtils"
local function _loaded_mod_modules_sharedUtils()
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
  if value == "true" or value == "false" then
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

return sharedUtils
end

_G.package.loaded["modules.sharedUtils"] = _loaded_mod_modules_sharedUtils()

-- module: "modules.cpmmValidation"
local function _loaded_mod_modules_cpmmValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local bint = require('.bint')(256)
local utils = require('.utils')
local sharedUtils = require('modules.sharedUtils')
local json = require("json")
local cpmmValidation = {}

--- Validates address
--- @param address any The address to be validated
--- @param tagName string The name of the tag being validated
local function validateAddress(address, tagName)
  assert(type(address) == 'string', tagName .. ' is required!')
  assert(sharedUtils.isValidArweaveAddress(address), tagName .. ' must be a valid Arweave address!')
end

--- Validates position ID
--- @param positionId any The position ID to be validated
--- @param validPositionIds table<string> The array of valid position IDs
local function validatePositionId(positionId, validPositionIds)
  assert(type(positionId) == 'string', 'PositionId is required!')
  assert(utils.includes(positionId, validPositionIds), 'Invalid positionId!')
end

--- Validates positive integer
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
local function validatePositiveInteger(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

--- Validates positive integer or zero
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
local function validatePositiveIntegerOrZero(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) >= 0, tagName .. ' must be greater than or equal to zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

--- Validates add funding
--- @param msg Message The message to be validated
function cpmmValidation.addFunding(msg)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
  assert(sharedUtils.isJSONArray(msg.Tags['X-Distribution']), 'X-Distribution must be valid JSON Array!')
  -- @dev TODO: remove requirement for X-Distribution
end

--- Validates remove funding
--- @param msg Message The message to be validated
function cpmmValidation.removeFunding(msg)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates buy
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.buy(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates sell
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.sell(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  validatePositiveInteger(msg.Tags.MaxOutcomeTokensToSell, "MaxOutcomeTokensToSell")
end

--- Validates calc buy amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcBuyAmount(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

--- Validates calc sell amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcSellAmount(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

--- Validates update configurator
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateConfigurator(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  validateAddress(msg.Tags.Configurator, 'Configurator')
end

--- Validates update incentives
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  validateAddress(msg.Tags.Incentives, 'Incentives')
end

--- Validates update take fee
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateTakeFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  validatePositiveIntegerOrZero(msg.Tags.CreatorFee, 'CreatorFee')
  validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, 'ProtocolFee')
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

_G.package.loaded["modules.cpmmValidation"] = _loaded_mod_modules_cpmmValidation()

-- module: "modules.tokenValidation"
local function _loaded_mod_modules_tokenValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

local sharedUtils = require('modules.sharedUtils')
local tokenValidation = {}

--- Validates a transfer message
--- @param msg Message The message received
function tokenValidation.transfer(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(sharedUtils.isValidArweaveAddress(msg.Tags.Recipient), 'Recipient must be a valid Arweave address!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
  assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
end

return tokenValidation
end

_G.package.loaded["modules.tokenValidation"] = _loaded_mod_modules_tokenValidation()

-- module: "modules.semiFungibleTokensValidation"
local function _loaded_mod_modules_semiFungibleTokensValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See semiFungibleTokens.lua for full license details.
=========================================================
]]

local json = require("json")
local bint = require('.bint')(256)
local utils = require('.utils')
local sharedUtils = require('modules.sharedUtils')

local semiFungibleTokensValidation = {}

--- Validates a recipient
--- @param recipient string The recipient address
local function validateRecipient(recipient)
  assert(type(recipient) == 'string', 'Recipient is required!')
  assert(sharedUtils.isValidArweaveAddress(recipient), 'Recipient must be a valid Arweave address!')
end

--- Validates a tokenId givent an array of valid token ids
--- @param tokenId string The ID to be be validated
--- @param validTokenIds table<string> The array of valid IDs
local function validateTokenId(tokenId, validTokenIds)
  assert(type(tokenId) == 'string', 'TokenId is required!')
  assert(utils.includes(tokenId, validTokenIds), 'Invalid tokenId!')
end

--- Validates a quantity
--- @param quantity string The quantity to be validated
local function validateQuantity(quantity)
  assert(type(quantity) == 'string', 'Quantity is required!')
  assert(tonumber(quantity), 'Quantity must be a number!')
  assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
end

--- Validates a transferSingle message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferSingle(msg, validTokenIds)
  validateRecipient(msg.Tags.Recipient)
  validateTokenId(msg.Tags.TokenId, validTokenIds)
  validateQuantity(msg.Tags.Quantity)
end

--- Validates a transferBatch message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.transferBatch(msg, validTokenIds)
  validateRecipient(msg.Tags.Recipient)
  assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#tokenIds == #quantities, 'Input array lengths must match!')
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateTokenId(tokenIds[i], validTokenIds)
    validateQuantity(quantities[i])
  end
end

--- Validates a balanceById message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balanceById(msg, validTokenIds)
  validateTokenId(msg.Tags.TokenId, validTokenIds)
end

--- Validates a balancesById message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.balancesById(msg, validTokenIds)
  validateTokenId(msg.Tags.TokenId, validTokenIds)
end

--- Validates a batchBalance message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalance(msg, validTokenIds)
  assert(msg.Tags.Recipients, "Recipients is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Input array lengths must match!")
  assert(#recipients > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateRecipient(recipients[i])
    validateTokenId(tokenIds[i], validTokenIds)
  end
end

--- Validates a batchBalances message
--- @param msg Message The message received
--- @param validTokenIds table<string> The array of valid token IDs
function semiFungibleTokensValidation.batchBalances(msg, validTokenIds)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateTokenId(tokenIds[i], validTokenIds)
  end
end

return semiFungibleTokensValidation
end

_G.package.loaded["modules.semiFungibleTokensValidation"] = _loaded_mod_modules_semiFungibleTokensValidation()

-- module: "modules.conditionalTokensValidation"
local function _loaded_mod_modules_conditionalTokensValidation()
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local ConditionalTokensValidation = {}
local sharedUtils = require('modules.sharedUtils')
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
function ConditionalTokensValidation.reportPayouts(msg)
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  validatePayouts(msg.Tags.Payouts)
end

return ConditionalTokensValidation
end

_G.package.loaded["modules.conditionalTokensValidation"] = _loaded_mod_modules_conditionalTokensValidation()

-- module: "modules.market"
local function _loaded_mod_modules_market()
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
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local cpmm = require('modules.cpmm')
local cpmmValidation = require('modules.cpmmValidation')
local tokenValidation = require('modules.tokenValidation')
local semiFungibleTokensValidation = require('modules.semiFungibleTokensValidation')
local conditionalTokensValidation = require('modules.conditionalTokensValidation')

--- Represents a Market
--- @class Market
--- @field cpmm CPMM The Constant Product Market Maker

--- Creates a new Market instance
--- @param configurator string The process ID of the configurator
--- @param incentives string The process ID of the incentives controller
--- @param collateralToken string The address of the collateral token
--- @param conditionId string The condition ID
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
  collateralToken,
  conditionId,
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
      incentives,
      collateralToken,
      conditionId,
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
  }
  setmetatable(market, { __index = MarketMethods })
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
    ConditionId = self.cpmm.tokens.conditionId,
    PositionIds = json.encode(self.cpmm.tokens.positionIds),
    CollateralToken = self.cpmm.tokens.collateralToken,
    Configurator = self.cpmm.configurator,
    Incentives = self.cpmm.incentives,
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
  local distribution = json.decode(msg.Tags['X-Distribution'])
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  -- @dev returns collateral tokens if invalid
  if self.cpmm:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
    self.cpmm:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, distribution, msg)
  end
end

--- Remove funding
--- Message forwarded from the LP token
--- @param msg Message The message received
--- @return nil -- TODO: send/specify notice
function MarketMethods:removeFunding(msg)
  cpmmValidation.removeFunding(msg)
  -- @dev returns LP tokens if invalid
  if self.cpmm:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
    self.cpmm:removeFunding(msg.Tags.Sender, msg.Tags.Quantity, msg)
  end
end

--- Buy
--- Message forwarded from the collateral token
--- @param msg Message The message received
--- @return Message buyNotice The buy notice
function MarketMethods:buy(msg)
  cpmmValidation.buy(msg, self.cpmm.positionIds)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender

  local error = false
  local errorMessage = ''

  local outcomeTokensToBuy = '0'

  if not msg.Tags['X-PositionId'] then
    error = true
    errorMessage = 'X-PositionId is required!'
  elseif not msg.Tags['X-MinOutcomeTokensToBuy'] then
    error = true
    errorMessage = 'X-MinOutcomeTokensToBuy is required!'
  else
    outcomeTokensToBuy = self.cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])
    if not bint.__le(bint(msg.Tags['X-MinOutcomeTokensToBuy']), bint(outcomeTokensToBuy)) then
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
  return self.cpmm:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
end

--- Sell
--- @param msg Message The message received
--- @return Message sellNotice The sell notice
function MarketMethods:sell(msg)
  cpmmValidation.sell(msg, self.cpmm.positionIds)
  local outcomeTokensToSell = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  assert(bint.__le(bint(outcomeTokensToSell), bint(msg.Tags.MaxOutcomeTokensToSell)), 'Maximum sell amount not sufficient!')
  return self.cpmm:sell(msg.From, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.Quantity, tonumber(msg.Tags.MaxOutcomeTokensToSell), msg)
end

--- Withdraw fees
--- @param msg Message The message received
--- @return Message withdrawFees The amount withdrawn
function MarketMethods:withdrawFees(msg)
  return msg.reply({ Data = self.cpmm:withdrawFees(msg.From) })
end

--[[
=================
CPMM READ METHODS
=================
]]

--- Calc buy amount
--- @param msg Message The message received
--- @return Message buyAmount The amount of tokens to be purchased
function MarketMethods:calcBuyAmount(msg)
  cpmmValidation.calcBuyAmount(msg, self.cpmm.positionIds)
  local buyAmount = self.cpmm:calcBuyAmount(msg.Tags.InvestmentAmount, msg.Tags.PositionId)
  return msg.reply({ Data = buyAmount })
end

--- Calc sell amount
--- @param msg Message The message received
--- @return Message sellAmount The amount of tokens to be sold
function MarketMethods:calcSellAmount(msg)
  cpmmValidation.calcSellAmount(msg, self.cpmm.positionIds)
  local sellAmount = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
  return msg.reply({ Data = sellAmount })
end

--- Colleced fees
--- @return Message collectedFees The total unwithdrawn fees collected by the CPMM
function MarketMethods:collectedFees(msg)
  return msg.reply({ Data = self.cpmm:collectedFees() })
end

--- Fees withdrawable 
--- @param msg Message The message received
--- @return Message feesWithdrawable The fees withdrawable by the account
function MarketMethods:feesWithdrawable(msg)
  local account = msg.Tags['Recipient'] or msg.From
  return msg.reply({ Data = self.cpmm:feesWithdrawableBy(account) })
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
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.From
  -- Check user balances
  local error = false
  local errorMessage = ''
  for i = 1, #self.cpmm.tokens.positionIds do
    if not self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ] then
      error = true
      errorMessage = "Invalid position! PositionId: " .. self.cpmm.positionIds[i]
    end
    if not self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ][msg.From] then
      error = true
      errorMessage = "Invalid user position! PositionId: " .. self.cpmm.positionIds[i]
    end
    if bint.__lt(bint(self.cpmm.tokens.balancesById[ self.cpmm.tokens.positionIds[i] ][msg.From]), bint(msg.Tags.Quantity)) then
      error = true
      errorMessage = "Insufficient tokens! PositionId: " .. self.cpmm.positionIds[i]
    end
  end
  -- Revert on error
  if error then
    return msg.reply({ Action = 'Error', Data = errorMessage })
  end
  return self.cpmm.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, false, msg)
end

--- Report payouts
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The condition resolution notice 
-- TODO: sync on naming conventions
function MarketMethods:reportPayouts(msg)
  conditionalTokensValidation.reportPayouts(msg)
  local payouts = json.decode(msg.Tags.Payouts)
  return self.cpmm.tokens:reportPayouts(msg.Tags.QuestionId, payouts, msg)
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
  return msg.reply({
    Action = "Payout-Numerators",
    ConditionId = self.cpmm.tokens.conditionId,
    Data = json.encode(self.cpmm.tokens.payoutNumerators)
  })
end

--- Get payout denominator
--- @param msg Message The message received
--- @return Message payoutDenominator The payout denominator for the condition
function MarketMethods:getPayoutDenominator(msg)
  return msg.reply({
    Action = "Payout-Denominator",
    ConditionId = self.cpmm.tokens.conditionId,
    Data = self.cpmm.tokens.payoutDenominator
  })
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
  return self.cpmm.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
end

--- Transfer batch
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferBatchNotices The transfer notices, error notice or nothing
function MarketMethods:transferBatch(msg)
  semiFungibleTokensValidation.transferBatch(msg, self.cpmm.tokens.positionIds)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local quantities = json.decode(msg.Tags.Quantities)
  return self.cpmm.tokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
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
  local bal = self.cpmm.tokens:getBalance(msg.From, account, msg.Tags.TokenId)
  return msg.reply({
    Balance = bal,
    TokenId = msg.Tags.TokenId,
    Ticker = Ticker,
    Account = account,
    Data = bal
  })
end

--- Balances by ID
--- @param msg Message The message received
--- @return Message balancesById The balances of all accounts filtered by ID
function MarketMethods:balancesById(msg)
  semiFungibleTokensValidation.balancesById(msg, self.cpmm.tokens.positionIds)
  local bals = self.cpmm.tokens:getBalances(msg.Tags.TokenId)
  return msg.reply({ Data = bals })
end

--- Batch balance
--- @param msg Message The message received
--- @return Message batchBalance The balance accounts filtered by IDs
function MarketMethods:batchBalance(msg)
  semiFungibleTokensValidation.batchBalance(msg, self.cpmm.tokens.positionIds)
  local recipients = json.decode(msg.Tags.Recipients)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = self.cpmm.tokens:getBatchBalance(recipients, tokenIds)
  return msg.reply({ Data = bals })
end

--- Batch balances
--- @param msg Message The message received
--- @return Message batchBalances The balances of all accounts filtered by IDs
function MarketMethods:batchBalances(msg)
  semiFungibleTokensValidation.batchBalances(msg, self.cpmm.tokens.positionIds)
  local tokenIds = json.decode(msg.Tags.TokenIds)
  local bals = self.cpmm.tokens:getBatchBalances(tokenIds)
  return msg.reply({ Data = bals })
end

--- Balances all
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
function MarketMethods:balancesAll(msg)
  return msg.reply({ Data = self.cpmm.tokens.balancesById })
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

--- Update incentives
--- @param msg Message The message received
--- @return Message incentivesUpdateNotice The incentives update notice
function MarketMethods:updateIncentives(msg)
  cpmmValidation.updateIncentives(msg, self.cpmm.configurator)
  return self.cpmm:updateIncentives(msg.Tags.Incentives, msg)
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

--[[
==================
EVAL WRITE METHODS
==================
]]

--- Eval
--- @param msg Message The message received
--- @return Message The eval complete notice
function MarketMethods:completeEval(msg)
  return msg.forward('NRKvM8X3TqjGGyrqyB677aVbxgONo5fBHkbxbUSa_Ug', {
    Action = 'Eval-Completed',
    Data = 'Eval-Completed'
  })
end

return Market

end

_G.package.loaded["modules.market"] = _loaded_mod_modules_market()

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

local market = require('modules.market')
local constants = require('modules.constants')
local json = require('json')

--[[
======
MARKET
======
]]

Env = "DEV"
Version = "1.0.1"

--- Represents Market Configuration  
--- @class MarketConfiguration  
--- @field configurator string The Configurator process ID  
--- @field incentives string The Incentives process ID  
--- @field collateralToken string The Collateral Token process ID  
--- @field marketId string The Market process ID  
--- @field conditionId string The Condition process ID  
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
    configurator = ao.env.Process.Tags.Configurator or '',
    incentives = ao.env.Process.Tags.Incentives or '',
    collateralToken = ao.env.Process.Tags.CollateralToken or '',
    conditionId = ao.env.Process.Tags.ConditionId or '',
    positionIds = json.decode(ao.env.Process.Tags.PositionIds or '[]'),
    name = ao.env.Process.Tags.Name or '',
    ticker = ao.env.Process.Tags.Ticker or '',
    logo = ao.env.Process.Tags.Logo or '',
    lpFee = tonumber(ao.env.Process.Tags.LpFee) or 0,
    creatorFee = tonumber(ao.env.Process.Tags.CreatorFee) or 0,
    creatorFeeTarget = ao.env.Process.Tags.CreatorFeeTarget or '',
    protocolFee = tonumber(ao.env.Process.Tags.ProtocolFee) or 0,
    protocolFeeTarget = ao.env.Process.Tags.ProtocolFeeTarget or ''
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
    marketConfig.collateralToken,
    marketConfig.conditionId,
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

--- Match on remove funding from CPMM
--- @param msg Message The message to match
--- @return boolean True if the message is to remove funding, false otherwise
local function isRemoveFunding(msg)
  if (
    msg.From == ao.id and
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Remove-Funding"
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
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
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

--[[
=============
EVAL HANDLERS
=============
]]

--- Eval 
--- @param msg Message The message received
--- @return Message The eval complete notice
Handlers.once("Complete-Eval", {Action = "Complete-Eval"}, function(msg)
  return Market:completeEval(msg)
end)

-- @dev TODO: remove?
ao.send({Target = ao.id, Action = 'Complete-Eval'})

return "ok"

]===]