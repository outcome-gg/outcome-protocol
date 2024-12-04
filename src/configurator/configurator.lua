local json = require('json')
local config = require('modules.config')
local configurator = require('modules.configurator')

--[[
    Configurator ----------------------------------------------------------------
]]
-- @dev Create new instance of Configurator if doesn't exist
if not Config then Config = config:new() end
-- @dev Reset state on load while in DEV mode
if Configurator.resetState then Configurator = configurator:new(Config) end

Name = 'Configurator'

--[[
    Info
]]
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
  print("msg " .. json.encode(msg))
  -- msg.reply({ Data = "foo"})
  -- msg.reply({
  --   Admin = Configurator.admin,
  --   Delay = Configurator.delay,
  --   Staged = json.encode(Configurator.staged)
  -- })
end)

--[[
    PROTOCOL ----------------------------------------------------------------
]]

--[[
    Stage Update
]]
Handlers.add("Stage-Update", Handlers.utils.hasMatchingTag("Action", "Stage-Update"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(type(msg.Tags.UpdateTagName) == 'string', 'UpdateTagName is required!')
  assert(type(msg.Tags.UpdateTagValue) == 'string', 'UpdateTagValue is required!')

  Configurator:stageUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, msg.Tags.UpdateTagName, msg.Tags.UpdateTagValue)

  msg.reply({
    Action = 'Update-Staged',
    UpdateProcess = msg.Tags.UpdateProcess,
    UpdateAction = msg.Tags.UpdateAction,
    UpdateTagName = msg.Tags.UpdateTagName,
    UpdateTagValue = msg.Tags.UpdateTagValue
  })
end)

--[[
    Unstage Update
]]
Handlers.add("Unstage-Update", Handlers.utils.hasMatchingTag("Action", "Unstage-Update"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(type(msg.Tags.UpdateTagName) == 'string', 'UpdateTagName is required!')
  assert(type(msg.Tags.UpdateTagValue) == 'string', 'UpdateTagValue is required!')

  Configurator:unstageUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, msg.Tags.UpdateTagName, msg.Tags.UpdateTagValue)

  msg.reply({
    Action = 'Update-Unstaged',
    UpdateProcess = msg.Tags.UpdateProcess,
    UpdateAction = msg.Tags.UpdateAction,
    UpdateTagName = msg.Tags.UpdateTagName,
    UpdateTagValue = msg.Tags.UpdateTagValue
  })
end)


--[[
    Action Update
]]
Handlers.add("Action-Update", Handlers.utils.hasMatchingTag("Action", "Action-Update"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(type(msg.Tags.UpdateTagName) == 'string', 'UpdateTagName is required!')
  assert(type(msg.Tags.UpdateTagValue) == 'string', 'UpdateTagValue is required!')

  local success, message = Configurator:actionUpdate(msg.Tags.UpdateProcess, msg.Tags.UpdateAction, msg.Tags.UpdateTagName, msg.Tags.UpdateTagValue)

  if not success then
    msg.reply({
      Action = 'Action-Update-Error',
      Error = message
    })
    return
  end

  msg.reply({
    Action = 'Update-Actioned',
    UpdateProcess = msg.Tags.UpdateProcess,
    UpdateAction = msg.Tags.UpdateAction,
    UpdateTagName = msg.Tags.UpdateTagName,
    UpdateTagValue = msg.Tags.UpdateTagValue
  })
end)

--[[
    ADMIN ----------------------------------------------------------------
]]

--[[
    Stage Update Admin
]]
Handlers.add("Stage-Update-Admin", Handlers.utils.hasMatchingTag("Action", "Stage-Update-Admin"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
  Configurator:stageUpdateAdmin(msg.Tags.UpdateAdmin)

  msg.reply({ Action = 'Update-Admin-Staged', UpdateAdmin = msg.Tags.UpdateAdmin})
end)

--[[
    Unstage Update Admin
]]
Handlers.add("Unstage-Update-Admin", Handlers.utils.hasMatchingTag("Action", "Unstage-Update-Admin"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
  Configurator:unstageUpdateAdmin(msg.Tags.UpdateAdmin)

  msg.reply({ Action = 'Update-Admin-Unstaged', UpdateAdmin = msg.Tags.UpdateAdmin})
end)

--[[
    Action Update Admin
]]
Handlers.add("Action-Update-Admin", Handlers.utils.hasMatchingTag("Action", "Action-Update-Admin"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
  local success, message = Configurator:actionUpdateAdmin(msg.Tags.UpdateAdmin)

  if not success then
    msg.reply({
      Action = 'Action-Update-Admin-Error',
      Error = message
    })
    return
  end

  msg.reply({ Action = 'Update-Admin-Actioned', UpdateAdmin = msg.Tags.Admin})
end)

--[[
    DELAY TIME ----------------------------------------------------------------
]]

--[[
    Stage Update DelayTime
]]
Handlers.add("Stage-Update-DelayTime", Handlers.utils.hasMatchingTag("Action", "Stage-Update-DelayTime"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.DelayTime, 'DelayTime is required!')
  Configurator:stageUpdateDelayTime(msg.Tags.DelayTime)

  msg.reply({ Action = 'Update-DelayTime-Staged', UpdateDelayTime = msg.Tags.DelayTime})
end)

--[[
    Unstage Update DelayTime
]]
Handlers.add("Unstage-Update-DelayTime", Handlers.utils.hasMatchingTag("Action", "Unstage-Update-DelayTime"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.DelayTime, 'DelayTime is required!')
  Configurator:unstageUpdateDelayTime(msg.Tags.DelayTime)

  msg.reply({ Action = 'Update-DelayTime-Unstaged', UpdateDelayTime = msg.Tags.DelayTime})
end)

--[[
    Action Update DelayTime
]]
Handlers.add("Action-Update-DelayTime", Handlers.utils.hasMatchingTag("Action", "Action-Update-DelayTime"), function(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.DelayTime, 'DelayTime is required!')
  local success, message = Configurator:actionUpdateDelayTime(msg.Tags.DelayTime)

  if not success then
    msg.reply({
      Action = 'Action-Update-DelayTime-Error',
      Error = message
    })
    return
  end

  msg.reply({ Action = 'Update-DelayTime-Actioned', UpdateDelayTime = msg.Tags.DelayTime})
end)