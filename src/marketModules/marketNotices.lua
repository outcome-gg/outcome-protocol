--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local MarketNotices = {}

--- Sends a update data index notice
--- @param dataIndex string The updated data index
--- @param msg Message The message received
--- @return Message The data index updated notice
function MarketNotices.updateDataIndexNotice(dataIndex, msg)
  return msg.reply({
    Action = "Update-Data-Index-Notice",
    Data = dataIndex
  })
end

return MarketNotices