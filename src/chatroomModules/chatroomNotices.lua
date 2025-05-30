--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See chatroom.lua for full license details.
=========================================================
]]

local ChatroomNotices = {}
local json = require('json')

function ChatroomNotices.broadcastNotice(market, user, parentId, body, msg)
  return msg.reply({
    Action = "Broadcast-Notice",
    Market = market,
    User = user,
    ParentId = tostring(parentId),
    Data = body
  })
end

return ChatroomNotices
