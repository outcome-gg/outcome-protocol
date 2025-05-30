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