local sharedUtils = {}

-- Function to validate if the extracted value is a valid JSON simple value
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

function sharedUtils.isValidArweaveAddress(address)
	return type(address) == "string" and #address == 43 and string.match(address, "^[%w-_]+$") ~= nil
end

return sharedUtils