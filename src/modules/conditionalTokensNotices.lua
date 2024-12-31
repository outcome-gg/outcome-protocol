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
--- @param conditionId string The condition ID
--- @param resolutionAgent string The process assigned to report the result for the prepared condition
--- @param questionId string An identifier for the question to be answered by the resolutionAgent
--- @param outcomeSlotCount number The number of outcome slots
--- @param payoutNumerators table<number> The payout numerators for each outcome slot
--- @param msg Message The message received
--- @return Message The condition resolution notice
function ConditionalTokensNotices.conditionResolutionNotice(conditionId, resolutionAgent, questionId, outcomeSlotCount, payoutNumerators, msg)
  return msg.reply({
    Action = "Condition-Resolution-Notice",
    ConditionId = conditionId,
    ResolutionAgent = resolutionAgent,
    QuestionId = questionId,
    OutcomeSlotCount = tostring(outcomeSlotCount),
    PayoutNumerators = json.encode(payoutNumerators)
  })
end

--- Position split notice
--- @param from string The address of the account that split the position
--- @param collateralToken string The address of the collateral token
--- @param conditionId string The condition ID
--- @param quantity string The quantity
--- @param msg Message The message received
--- @return Message The position split notice
function ConditionalTokensNotices.positionSplitNotice(from, collateralToken, conditionId, quantity, msg)
  local notice = {
    Action = "Split-Position-Notice",
    Process = ao.id,
    Stakeholder = from,
    CollateralToken = collateralToken,
    ConditionId = conditionId,
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
--- @param conditionId string The condition ID
--- @param quantity string The quantity
--- @param msg Message The message received
--- @return Message The positions merge notice
function ConditionalTokensNotices.positionsMergeNotice(conditionId, quantity, msg)
  return msg.reply({
    Action = "Merge-Positions-Notice",
    ConditionId = conditionId, -- TODO: Check if this is needed
    Quantity = quantity
  })
end

--- Payout redemption notice
--- @param collateralToken string The address of the collateral token
--- @param conditionId string The condition ID
--- @param payout string The payout amount
--- @param msg Message The message received
--- @return Message The payout redemption notice
function ConditionalTokensNotices.payoutRedemptionNotice(collateralToken, conditionId, payout, msg)
  return msg.reply({
    Action = "Payout-Redemption-Notice",
    Process = ao.id,
    CollateralToken = collateralToken,
    ConditionId = conditionId,
    Payout = tostring(payout)
  })
end

return ConditionalTokensNotices
