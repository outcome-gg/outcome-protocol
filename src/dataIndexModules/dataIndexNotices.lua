--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See dataIndex.lua for full license details.
=========================================================
]]

local DataIndexNotices = {}
local json = require('json')

function DataIndexNotices.updateConfiguratorNotice(updateConfigurator, msg)
  return msg.reply({
    Action = "Update-Configurator-Notice",
    UpdateConfigurator = updateConfigurator
  })
end

function DataIndexNotices.updateModeratorsNotice(moderators, msg)
  return msg.reply({
    Action = "Update-Moderators-Notice",
    Data = json.encode(moderators)
  })
end

function DataIndexNotices.updateViewersNotice(updateViewers, msg)
  return msg.reply({
    Action = "Update-Viewers-Notice",
    UpdateViewers = updateViewers
  })
end

return DataIndexNotices