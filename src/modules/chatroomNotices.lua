--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See chatroom.lua for full license details.
=========================================================
]]

local ChatroomNotices = {}
local json = require('json')

function ChatroomNotices.broadcastNotice(message, msg)
  return msg.reply({
    Action = "Broadcast-Notice",
    Data = json.encode(message)
  })
end

function ChatroomNotices.setUserSilenceNotice(user, silenced, msg)
  return msg.reply({
    Action = "Set-User-Silence-Notice",
    Silenced = tostring(silenced),
    Data = json.encode(user)
  })
end

function ChatroomNotices.setMessageVisibilityNotice(messages, entity, visible, msg)
  return msg.reply({
    Action = "Set-Chatroom-Silence-Notice",
    Entity = entity,
    Visible = tostring(visible),
    Data = json.encode(messages)
  })
end

function ChatroomNotices.deleteMessagesNotice(id, entity, msg)
  return msg.reply({
    Action = "Delete-Entity-Messages-Notice",
    Entity = entity,
    Data = id
  })
end

function ChatroomNotices.deleteOldMessagesNotice(days, msg)
  return msg.reply({
    Action = "Delete-Old-Messages-Notice",
    Data = days
  })
end

return ChatroomNotices