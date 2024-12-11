local json = require('json')
local configurator = require('modules.configurator')
local configuratorValidation = require('modules.configuratorValidation')

---------------------------------------------------------------------------------
-- CONFIGURATOR -----------------------------------------------------------------
---------------------------------------------------------------------------------
Env = 'DEV'
Version = '1.0.1'
-- @dev Reset state on load while in DEV mode
if not Configurator or Env == 'DEV' then Configurator = configurator:new(Env) end

---------------------------------------------------------------------------------
-- READ HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
  return msg.reply({
    Admin = Configurator.admin,
    Delay = Configurator.delay,
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