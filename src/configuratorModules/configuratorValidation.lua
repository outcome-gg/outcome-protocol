--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See configurator.lua for full license details.
=========================================================
]]

local ConfiguratorValidation = {}
local sharedUtils = require('configuratorModules.sharedUtils')

--- Validates the updateProcess message
--- @param msg Message The message to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConfiguratorValidation.updateProcess(msg)
  if msg.From ~= Configurator.admin then
    return false, 'Sender must be admin!'
  end
  if type(msg.Tags.UpdateProcess) ~= 'string' then
    return false, 'UpdateProcess is required and must be a string!'
  end
  if not sharedUtils.isValidArweaveAddress(msg.Tags.UpdateProcess) then
    return false, 'UpdateProcess must be a valid Arweave address!'
  end
  if type(msg.Tags.UpdateAction) ~= 'string' then
    return false, 'UpdateAction is required and must be a string!'
  end
  if msg.Tags.UpdateTags ~= nil and not sharedUtils.isValidKeyValueJSON(msg.Tags.UpdateTags) then
    return false, 'UpdateTags must be valid JSON!'
  end
  if msg.Tags.UpdateData ~= nil and not sharedUtils.isValidKeyValueJSON(msg.Tags.UpdateData) then
    return false, 'UpdateData must be valid JSON!'
  end

  return true
end

--- Validates the updateAdmin message
--- @param msg Message The message to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConfiguratorValidation.updateAdmin(msg)
  if msg.From ~= Configurator.admin then
    return false, 'Sender must be admin!'
  end
  if type(msg.Tags.UpdateAdmin) ~= 'string' then
    return false, 'UpdateAdmin is required and must be a string!'
  end
  if not sharedUtils.isValidArweaveAddress(msg.Tags.UpdateAdmin) then
    return false, 'UpdateAdmin must be a valid Arweave address!'
  end

  return true
end

--- Validates the updateDelay message
--- @param msg Message The message to be validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function ConfiguratorValidation.updateDelay(msg)
  if msg.From ~= Configurator.admin then
    return false, 'Sender must be admin!'
  end
  if not msg.Tags.UpdateDelay then
    return false, 'UpdateDelay is required!'
  end

  local delay = tonumber(msg.Tags.UpdateDelay)
  if not delay then
    return false, 'UpdateDelay must be a valid number!'
  end
  if delay <= 0 then
    return false, 'UpdateDelay must be greater than zero!'
  end
  if delay % 1 ~= 0 then
    return false, 'UpdateDelay must be an integer!'
  end

  return true
end

return ConfiguratorValidation