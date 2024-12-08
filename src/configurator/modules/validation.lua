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

  -- Check for boolean or null
  if value == "true" or value == "false" or value == "null" then
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

local function updateValidation(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(isValidKeyValueJSON(msg.Tags.UpdateTags) or msg.Tags.UpdateTags == nil, 'UpdateTags must be valid JSON! ' ..  json.encode(msg.Tags.UpdateTags))
  assert(isValidKeyValueJSON(msg.Tags.UpdateData) or msg.Tags.UpdateData == nil, 'UpdateData must be valid JSON!')
end

function validation.stageUpdate(msg)
  updateValidation(msg)
end

function validation.unstageUpdate(msg)
  updateValidation(msg)
end

function validation.actionUpdate(msg)
  updateValidation(msg)
end

function validation.stageAdminUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
end

function validation.unstageAdminUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
end

function validation.actionAdminUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
end

function validation.stageDelayUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
  assert(tonumber(msg.Tags.UpdateDelay), 'UpdateDelay must be a number!')
  assert(tonumber(msg.Tags.UpdateDelay) > 0, 'UpdateDelay must be greater than zero!')
  assert(tonumber(msg.Tags.UpdateDelay) % 1 == 0, 'UpdateDelay must be an integer!')
end

function validation.unstageDelayUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
end

function validation.actionDelayUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
end

return validation