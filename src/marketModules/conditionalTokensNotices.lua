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
    PayoutNumerators = json.encode(payoutNumerators),
    Data = "Successfully reported payouts"
  })
end

--- Position split notice
--- @param from string The address of the account that split the position
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The position split notice
function ConditionalTokensNotices.positionSplitNotice(from, collateralToken, quantity, detached, msg)
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
  -- Send notice
  if not detached then return msg.reply(notice) end
  notice.Target = from
  return ao.send(notice)
end

--- Positions merge notice
--- @param collateralToken string The address of the collateral token
--- @param quantity string The quantity
--- @param onBehalfOf string The address of the account to receive the collateral
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The positions merge notice
function ConditionalTokensNotices.positionsMergeNotice(collateralToken, quantity, onBehalfOf, detached, msg)
  local notice = {
    Action = "Merge-Positions-Notice",
    OnBehalfOf = onBehalfOf,
    CollateralToken = collateralToken,
    Quantity = quantity,
    Data = "Successfully merged positions"
  }
  if not detached then return msg.reply(notice) end
  notice.Target = msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Redeem positions notice
--- @param collateralToken string The address of the collateral token
--- @param payout number The payout amount
--- @param netPayout string The net payout amount (after fees)
--- @param onBehalfOf string The address of the account to receive the payout
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensNotices.redeemPositionsNotice(collateralToken, payout, netPayout, onBehalfOf, msg)
  return msg.reply({
    Action = "Redeem-Positions-Notice",
    CollateralToken = collateralToken,
    GrossPayout = tostring(payout),
    NetPayout = netPayout,
    OnBehalfOf = onBehalfOf,
    Data = "Successfully redeemed positions"
  })
end

return ConditionalTokensNotices
