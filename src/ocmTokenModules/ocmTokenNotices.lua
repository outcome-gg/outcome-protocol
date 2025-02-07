--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See ocmToken.lua for full license details.
=========================================================
]]

local OcmTokenNotices = {}

function OcmTokenNotices.emissionNotice(msg)
  return msg.reply({
    Action = "Emission-Notice",
    Data = "Successfully emitted tokens"
  })
end

function OcmTokenNotices.claimNotice(quantity, onBehalfOf, msg)
  return msg.reply({
    Action = "Claim-Notice",
    Quantity = tostring(quantity),
    Recipient = onBehalfOf,
    Data = "Successfully claimed tokens"
  })
end

return OcmTokenNotices