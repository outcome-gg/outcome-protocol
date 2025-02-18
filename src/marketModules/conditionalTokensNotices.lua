--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See conditionalTokens.lua for full license details.
=========================================================
]]

local json = require('json')
local ao = ao or require('.ao')

local ConditionalTokensNotices = {}

--- Report payouts notice
--- @param resolutionAgent string The process assigned to report the result for the prepared condition
--- @param payoutNumerators table<number> The payout numerators for each outcome slot
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The report payouts notice
function ConditionalTokensNotices.reportPayoutsNotice(resolutionAgent, payoutNumerators, msg)
  return msg.reply({
    Action = "Report-Payouts-Notice",
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
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The positions merge notice
function ConditionalTokensNotices.positionsMergeNotice(collateralToken, quantity, msg, useReply)
  local notice = {
    Action = "Merge-Positions-Notice",
    CollateralToken = collateralToken,
    Quantity = quantity
  }
  if useReply then return msg.reply(notice) end
  notice.Target = msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Redeem positions notice
--- @param collateralToken string The address of the collateral token
--- @param payout number The payout amount
--- @param netPayout string The net payout amount (after fees)
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensNotices.redeemPositionsNotice(collateralToken, payout, netPayout, msg)
  return msg.reply({
    Action = "Redeem-Positions-Notice",
    CollateralToken = collateralToken,
    GrossPayout = tostring(payout),
    NetPayout = netPayout
  })
end

return ConditionalTokensNotices
