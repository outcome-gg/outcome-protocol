--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local json = require('json')
local ao = ao or require('.ao')

local ConditionalTokensNotices = {}

--- Condition resolution notice
--- @param resolutionAgent string The process assigned to report the result for the prepared condition
--- @param payoutNumerators table<number> The payout numerators for each outcome slot
--- @param msg Message The message received
--- @return Message The condition resolution notice
function ConditionalTokensNotices.conditionResolutionNotice(resolutionAgent, payoutNumerators, msg)
  return msg.reply({
    Action = "Condition-Resolution-Notice",
    ResolutionAgent = resolutionAgent,
    PayoutNumerators = json.encode(payoutNumerators)
  })
end

--- Position split notice
--- @param from string The address of the account that split the position
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param msg Message The message received
--- @return Message The position split notice
function ConditionalTokensNotices.positionSplitNotice(from, collateralToken, quantity, msg)
  local notice = {
    Action = "Split-Position-Notice",
    Process = ao.id,
    Stakeholder = from,
    CollateralToken = collateralToken,
    Quantity = quantity
  }
  -- Forward tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice | @dev ao.send vs msg.reply to ensure message is sent to user (not collateralToken)
  return msg.forward(from, notice)
end

--- Positions merge notice
--- @param quantity string The quantity
--- @param msg Message The message received
--- @return Message The positions merge notice
function ConditionalTokensNotices.positionsMergeNotice(quantity, msg)
  return msg.reply({
    Action = "Merge-Positions-Notice",
    Quantity = quantity
  })
end

--- Payout redemption notice
--- @param collateralToken string The address of the collateral token
--- @param payout string The payout amount
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensNotices.payoutRedemptionNotice(collateralToken, payout, msg)
  return msg.reply({
    Action = "Payout-Redemption-Notice",
    Process = ao.id,
    CollateralToken = collateralToken,
    Payout = tostring(payout)
  })
end

return ConditionalTokensNotices
