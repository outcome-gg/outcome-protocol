--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See configurator.lua for full license details.
=========================================================
]]

local ConfiguratorNotices = {}

--- Sends a stage update notice
--- @param process string The process ID
--- @param action string The action name
--- @param tags string The JSON string of tags
--- @param data string The JSON string of data
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The stage update notice
function ConfiguratorNotices.stageUpdateNotice(process, action, tags, data, hash, msg)
  return msg.reply({
    Action = 'Stage-Update-Notice',
    UpdateProcess = process,
    UpdateAction = action,
    UpdateTags = tags,
    UpdateData = data,
    Hash = hash
  })
end

--- Sends an unstage update notice
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The unstage update notice
function ConfiguratorNotices.unstageUpdateNotice(hash, msg)
  return msg.reply({
    Action = 'Unstage-Update-Notice',
    Hash = hash
  })
end

--- Sends an action update notice
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The action update notice
function ConfiguratorNotices.actionUpdateNotice(hash, msg)
  return msg.reply({
    Action = 'Action-Update-Notice',
    Hash = hash
  })
end

--- Sends a stage update admin notice
--- @param admin string The admin address
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The stage update admin notice
function ConfiguratorNotices.stageUpdateAdminNotice(admin, hash, msg)
  return msg.reply({
    Action = 'Stage-Update-Admin-Notice',
    UpdateAdmin = admin,
    Hash = hash
  })
end

--- Sends an unstage update admin notice
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The unstage update admin notice
function ConfiguratorNotices.unstageUpdateAdminNotice(hash, msg)
  return msg.reply({
    Action = 'Unstage-Update-Admin-Notice',
    Hash = hash
  })
end

--- Sends an action update admin notice
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The action update admin notice
function ConfiguratorNotices.actionUpdateAdminNotice(hash, msg)
  return msg.reply({
    Action = 'Action-Update-Admin-Notice',
    Hash = hash
  })
end

--- Sends a stage update delay notice
--- @param delay number The delay time in seconds
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The stage update delay notice
function ConfiguratorNotices.stageUpdateDelayNotice(delay, hash, msg)
  return msg.reply({
    Action = 'Update-Delay-Staged',
    UpdateDelay = delay,
    Hash = hash
  })
end

--- Sends an unstage update delay notice
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The unstage update delay notice
function ConfiguratorNotices.unstageUpdateDelayNotice(hash, msg)
  return msg.reply({
    Action = 'Update-Delay-Unstaged',
    Hash = hash
  })
end

--- Sends an action update delay notice
--- @param hash string The hash of the update
--- @param msg Message The message received
--- @return Message The action update delay notice
function ConfiguratorNotices.actionUpdateDelayNotice(hash, msg)
  return msg.reply({
    Action = 'Update-Delay-Actioned',
    Hash = hash
  })
end

return ConfiguratorNotices