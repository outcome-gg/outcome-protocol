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

local json = require('json')
local configurator = require('configuratorModules.configurator')
local configuratorValidation = require('configuratorModules.configuratorValidation')

--[[
============
CONFIGURATOR
============
]]

Env = 'DEV'
Admin = Admin or 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I'
-- @dev Reset state on load while in DEV mode
if not Configurator or Env == 'DEV' then Configurator = configurator.new(Admin, Env) end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message received
--- @return Message The reply message
Handlers.add("Info", {Action = "Info"}, function(msg)
  return msg.reply({
    Admin = Configurator.admin,
    Delay = tostring(Configurator.delay),
    Staged = json.encode(Configurator.staged)
  })
end)

--[[
=====================
UPDATE WRITE HANDLERS
=====================
]]
--- Stage update handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateProcess string The update process
---  - msg.Tags.UpdateAction string The update action
---  - msg.Tags.UpdateTags? string|nil The update tags or `nil`
---  - msg.Tags.UpdateData? string|nil The update data or `nil`
--- @return Message The reply message
Handlers.add("Stage-Update", {Action = "Stage-Update"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateProcess(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Stage-Update-Error",
      Error = err
    })
  end
  -- If validation passes, stage the update.
  local updateTags = msg.Tags.UpdateTags or ""
  local updateData = msg.Tags.UpdateData or ""
  return Configurator:stageUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, updateTags, updateData, msg)
end)

--- Unstage update handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateProcess string The update process
---  - msg.Tags.UpdateAction string The update action
---  - msg.Tags.UpdateTags? string|nil The update tags or `nil`
---  - msg.Tags.UpdateData? string|nil The update data or `nil`
--- @return Message The reply message
Handlers.add("Unstage-Update", {Action = "Unstage-Update"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateProcess(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Unstage-Update-Error",
      Error = err
    })
  end
  -- If validation passes, unstage the update.
  local updateTags = msg.Tags.UpdateTags or ""
  local updateData = msg.Tags.UpdateData or ""
  return Configurator:unstageUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, updateTags, updateData, msg)
end)

--- Action update handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateProcess string The update process
---  - msg.Tags.UpdateAction string The update action
---  - msg.Tags.UpdateTags? string|nil The update tags or `nil`
---  - msg.Tags.UpdateData? string|nil The update data or `nil`
--- @return Message The reply message
Handlers.add("Action-Update", {Action = "Action-Update"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateProcess(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Action-Update-Error",
      Error = err
    })
  end
  -- If validation passes, action the update.
  local updateTags = msg.Tags.UpdateTags or ""
  local updateData = msg.Tags.UpdateData or ""
  return Configurator:actionUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, updateTags, updateData, msg)
end)

--[[
===========================
UPDATE ADMIN WRITE HANDLERS
===========================
]]

--- Stage update admin handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateAdmin string The new admin address
--- @return Message The reply message
Handlers.add("Stage-Update-Admin", {Action = "Stage-Update-Admin"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateAdmin(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Stage-Update-Admin-Error",
      Error = err
    })
  end
  -- If validation passes, stage the update admin.
  return Configurator:stageUpdateAdmin(msg.Tags.UpdateAdmin, msg)
end)

--- Unstage update admin handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateAdmin string The new admin address
--- @return Message The reply message
Handlers.add("Unstage-Update-Admin", {Action = "Unstage-Update-Admin"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateAdmin(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Unstage-Update-Admin-Error",
      Error = err
    })
  end
  -- If validation passes, unstage the update admin.
  return Configurator:unstageUpdateAdmin(msg.Tags.UpdateAdmin, msg)
end)

--- Action update admin handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateAdmin string The new admin address
--- @return Message The reply message
Handlers.add("Action-Update-Admin", {Action = "Action-Update-Admin"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateAdmin(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Action-Update-Admin-Error",
      Error = err
    })
  end
  -- If validation passes, action the update admin.
  return Configurator:actionUpdateAdmin(msg.Tags.UpdateAdmin, msg)
end)

--[[
===========================
UPDATE DELAY WRITE HANDLERS
===========================
]]

--- Stage update delay handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateDelay string The updated delay time in seconds
--- @return Message The reply message
Handlers.add("Stage-Update-Delay", {Action = "Stage-Update-Delay"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateDelay(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Stage-Update-Delay-Error",
      Error = err
    })
  end
  -- If validation passes, stage the update delay.
  return Configurator:stageUpdateDelay(msg.Tags.UpdateDelay, msg)
end)

--- Unstage update delay handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateDelay string The updated delay time in seconds
--- @return Message The reply message
Handlers.add("Unstage-Update-Delay", {Action = "Unstage-Update-Delay"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateDelay(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Unstage-Update-Delay-Error",
      Error = err
    })
  end
  -- If validation passes, unstage the update delay.
  return Configurator:unstageUpdateDelay(msg.Tags.UpdateDelay, msg)
end)

--- Action update delay handler
--- @param msg Message The message received, expected to contain:
---  - msg.Tags.UpdateDelay string The updated delay time in seconds
--- @return Message The reply message
Handlers.add("Action-Update-Delay", {Action = "Action-Update-Delay"}, function(msg)
  -- Validate input
  local success, err = configuratorValidation.updateDelay(msg)
  -- If validation fails, provide error response.
  if not success then
    return msg.reply({
      Action = "Action-Update-Delay-Error",
      Error = err
    })
  end
  -- If validation passes, action the update delay.
  return Configurator:actionUpdateDelay(msg.Tags.UpdateDelay, msg)
end)