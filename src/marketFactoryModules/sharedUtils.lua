--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local sharedUtils = {}
local bint = require('.bint')(256)

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
	return type(address) == "string" and #address == 43 and string.match(address, "^[A-Za-z0-9_-]+$") ~= nil
end

--- Verify if a valid boolean string
--- @param value any
--- @return boolean
function sharedUtils.isValidBooleanString(value)
  return type(value) == "string" and (string.lower(value) == "true" or string.lower(value) == "false")
end

--- Safely adds two numeric strings using bint, with overflow detection.
--- @param a string A string representing an integer value
--- @param b string A string representing an integer value
--- @return string The sum of a and b as a string
function sharedUtils.safeAdd(a, b)
  local aInt = bint(a)
  local bInt = bint(b)
  local result = bint.__add(aInt, bInt)

  -- Overflow check: if the result is smaller than either operand, assume overflow
  if bint.__lt(result, aInt) or bint.__lt(result, bInt) then
    error("Overflow detected in safeAdd")
  end

  return tostring(result)
end

--- Safely subtracts b from a using bint, with underflow detection.
--- @param a string A string representing an integer value.
--- @param b string A string representing an integer value.
--- @return string The difference (a - b) as a string.
function sharedUtils.safeSub(a, b)
  local aInt = bint(a)
  local bInt = bint(b)

  -- Underflow check: b must be <= a
  if not bint.__le(bInt, aInt) then
    error("Underflow detected in safeSub")
  end

  local result = bint.__sub(aInt, bInt)
  return tostring(result)
end

return sharedUtils