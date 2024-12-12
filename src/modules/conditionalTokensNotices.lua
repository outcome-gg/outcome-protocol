local ao = require('.ao')
local json = require('json')

local ConditionalTokensNotices = {}

-- @dev Emitted upon the successful preparation of a condition.
-- @param sender The address of the account that prepared the condition.
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
-- @param msg For sending msg.reply
function ConditionalTokensNotices:conditionPreparationNotice(conditionId, outcomeSlotCount, msg)
  -- TODO: Decide if to be sent to user and/or Data Index
  msg.reply({
    Action = "Condition-Preparation-Notice",
    ConditionId = conditionId,
    OutcomeSlotCount = tostring(outcomeSlotCount)
  })
end

-- @dev Emitted upon the successful condition resolution.
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
-- @param payoutNumerators The payout numerators for each outcome slot.
function ConditionalTokensNotices:conditionResolutionNotice(conditionId, resolutionAgent, questionId, outcomeSlotCount, payoutNumerators)
  -- TODO: Decide if to be sent to user and/or Data Index
  ao.send({
      Target = 'DataIndex',
      Action = "Condition-Resolution-Notice",
      ConditionId = conditionId,
      ResolutionAgent = resolutionAgent,
      QuestionId = questionId,
      OutcomeSlotCount = tostring(outcomeSlotCount),
      PayoutNumerators = payoutNumerators
  })
end

-- @dev Emitted when a position is successfully split.
-- @param from The address of the account that split the position.
-- @param collateralToken The address of the collateral token.
-- @param conditionId The condition ID.
-- @param quantity The quantity.
-- @param msg For sending X-Tags
function ConditionalTokensNotices:positionSplitNotice(from, collateralToken, conditionId, quantity, msg)
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
  msg.forward(from, notice)
end


-- @dev Emitted when positions are successfully merged.
-- @param from The address of the account that merged the positions.
-- @param conditionId The condition ID.
-- @param quantity The quantity.
function ConditionalTokensNotices:positionsMergeNotice(conditionId, quantity, msg)
  msg.reply({
    Action = "Merge-Positions-Notice",
    ConditionId = conditionId,
    Quantity = quantity
  })
end

-- @dev Emitted when a position is successfully redeemed.
-- @param redeemer The address of the account that redeemed the position.
-- @param collateralToken The address of the collateral token.
-- @param conditionId The condition ID.
-- @param payout The payout amount.
function ConditionalTokensNotices:payoutRedemptionNotice(collateralToken, conditionId, payout, msg)
  -- TODO: Decide if to be sent to user and/or Data Index
  msg.reply({
    Action = "Payout-Redemption-Notice",
    Process = ao.id,
    CollateralToken = collateralToken,
    ConditionId = conditionId,
    Payout = tostring(payout)
  })
end

return ConditionalTokensNotices
