
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See platformData.lua for full license details.
=========================================================
]]

local PlatformDataValidation = {}
local sharedValidation = require('chatroomModules.sharedValidation')
local json = require('json')

--- Validate updateConfigurator
--- @param msg Message The message received
function PlatformDataValidation.validateUpdateConfigurator(configurator, msg)
  assert(msg.From == configurator, "Sender must be the configurator!")
  sharedValidation.validateAddress(msg.Tags.Configurator, "Configurator")
end

--- Validate updateModerators
--- @param msg Message The message received
function PlatformDataValidation.validateUpdateModerators(configurator, msg)
  assert(msg.From == configurator, "Sender must be the configurator!")
  assert(type(msg.Tags.Moderators) == 'table', "Moderators is required!")
  local moderators = json.decode(msg.tags.Moderators)
  for _, moderator in ipairs(moderators) do
    sharedValidation.validateAddress(moderator, "Moderator")
  end
end

return PlatformDataValidation