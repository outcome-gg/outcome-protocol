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

---------------------------------------------------------------------------------
-- CONFIGURATOR -----------------------------------------------------------------
---------------------------------------------------------------------------------
Env = 'DEV'
Version = '1.0.1'
Admin = Admin or "zpeP5Z3L2DfuDyvwymWoBWNz7zgC5CswhQTiBDRSljg" --'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I'
-- @dev Reset state on load while in DEV mode
if not Configurator or Env == 'DEV' then Configurator = configurator:new(Admin, Env) end

---------------------------------------------------------------------------------
-- READ HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
  return msg.reply({
    Admin = Configurator.admin,
    Delay = tostring(Configurator.delay),
    Staged = json.encode(Configurator.staged)
  })
end)

---------------------------------------------------------------------------------
-- GENERAL WRITE HANDLERS -------------------------------------------------------
---------------------------------------------------------------------------------

-- Stage Update
Handlers.add("Stage-Update", Handlers.utils.hasMatchingTag("Action", "Stage-Update"), function(msg)
  configuratorValidation.updateProcess(msg)
  local updateTags = msg.Tags.UpdateTags or ""
  local updateData = msg.Tags.UpdateData or ""
  return Configurator:stageUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, updateTags, updateData, msg)
end)

-- Unstage Update
Handlers.add("Unstage-Update", Handlers.utils.hasMatchingTag("Action", "Unstage-Update"), function(msg)
  configuratorValidation.updateProcess(msg)
  local updateTags = msg.Tags.UpdateTags or ""
  local updateData = msg.Tags.UpdateData or ""
  return Configurator:unstageUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, updateTags, updateData, msg)
end)

-- Action Update
Handlers.add("Action-Update", Handlers.utils.hasMatchingTag("Action", "Action-Update"), function(msg)
  configuratorValidation.updateProcess(msg)
  local updateTags = msg.Tags.UpdateTags or ""
  local updateData = msg.Tags.UpdateData or ""
  return Configurator:actionUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, updateTags, updateData, msg)
end)

---------------------------------------------------------------------------------
-- ADMIN WRITE HANDLERS ---------------------------------------------------------
---------------------------------------------------------------------------------

-- Stage Update Admin
Handlers.add("Stage-Update-Admin", Handlers.utils.hasMatchingTag("Action", "Stage-Update-Admin"), function(msg)
  configuratorValidation.updateAdmin(msg)
  return Configurator:stageUpdateAdmin(msg.Tags.UpdateAdmin, msg)
end)

-- Unstage Update Admin
Handlers.add("Unstage-Update-Admin", Handlers.utils.hasMatchingTag("Action", "Unstage-Update-Admin"), function(msg)
  configuratorValidation.updateAdmin(msg)
  return Configurator:unstageUpdateAdmin(msg.Tags.UpdateAdmin, msg)
end)

-- Action Update Admin
Handlers.add("Action-Update-Admin", Handlers.utils.hasMatchingTag("Action", "Action-Update-Admin"), function(msg)
  configuratorValidation.updateAdmin(msg)
  return Configurator:actionUpdateAdmin(msg.Tags.UpdateAdmin, msg)
end)

---------------------------------------------------------------------------------
-- DELAY WRITE HANDLERS ---------------------------------------------------------
---------------------------------------------------------------------------------

-- Stage Update DelayTime
Handlers.add("Stage-Update-Delay", Handlers.utils.hasMatchingTag("Action", "Stage-Update-Delay"), function(msg)
  configuratorValidation.updateDelay(msg)
  return Configurator:stageUpdateDelay(msg.Tags.UpdateDelay, msg)
end)

-- Unstage Update DelayTime
Handlers.add("Unstage-Update-Delay", Handlers.utils.hasMatchingTag("Action", "Unstage-Update-Delay"), function(msg)
  configuratorValidation.updateDelay(msg)
  return Configurator:unstageUpdateDelay(msg.Tags.UpdateDelay, msg)
end)

-- Action Update DelayTime
Handlers.add("Action-Update-Delay", Handlers.utils.hasMatchingTag("Action", "Action-Update-Delay"), function(msg)
  configuratorValidation.updateDelay(msg)
  return Configurator:actionUpdateDelay(msg.Tags.UpdateDelay, msg)
end)