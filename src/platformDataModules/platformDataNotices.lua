--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See platformData.lua for full license details.
=========================================================
]]

local PlatformDataNotices = {}
local json = require('json')

function PlatformDataNotices.updateConfiguratorNotice(updateConfigurator, msg)
  return msg.reply({
    Action = "Update-Configurator-Notice",
    UpdateConfigurator = updateConfigurator
  })
end

function PlatformDataNotices.updateModeratorsNotice(moderators, msg)
  return msg.reply({
    Action = "Update-Moderators-Notice",
    Data = json.encode(moderators)
  })
end

function PlatformDataNotices.updateReadersNotice(updateReaders, msg)
  return msg.reply({
    Action = "Update-Readers-Notice",
    UpdateReaders = updateReaders
  })
end

return PlatformDataNotices