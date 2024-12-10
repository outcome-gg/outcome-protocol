local json = require('json')

local validation = {}

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

local function isValidKeyValueJSON(str)
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

local function isValidArweaveAddress(address)
	return type(address) == "string" and #address == 43 and string.match(address, "^[%w-_]+$") ~= nil
end

function validation.updateProcess(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(isValidArweaveAddress(msg.Tags.UpdateProcess), 'UpdateProcess must be a valid Arweave address!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(isValidKeyValueJSON(msg.Tags.UpdateTags) or msg.Tags.UpdateTags == nil, 'UpdateTags must be valid JSON!')
  assert(isValidKeyValueJSON(msg.Tags.UpdateData) or msg.Tags.UpdateData == nil, 'UpdateData must be valid JSON!')
end

function validation.updateAdmin(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateAdmin) == 'string', 'UpdateAdmin is required!')
  assert(isValidArweaveAddress(msg.Tags.UpdateAdmin), 'UpdateAdmin must be a valid Arweave address!')
end

function validation.updateDelay(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
  assert(tonumber(msg.Tags.UpdateDelay), 'UpdateDelay must be a number!')
  assert(tonumber(msg.Tags.UpdateDelay) > 0, 'UpdateDelay must be greater than zero!')
  assert(tonumber(msg.Tags.UpdateDelay) % 1 == 0, 'UpdateDelay must be an integer!')
end

return validation