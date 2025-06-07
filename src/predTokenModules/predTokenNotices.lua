--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See ocmToken.lua for full license details.
=========================================================
]]

local PredTokenNotices = {}

function PredTokenNotices.claimNotice(quantity, msg)
  return msg.reply({
    Action = "Claim-Notice",
    Quantity = tostring(quantity),
    Data = "Successfully claimed tokens"
  })
end

return PredTokenNotices