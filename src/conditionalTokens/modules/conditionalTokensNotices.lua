local ao = require('.ao')
local json = require('json')

local ConditionalTokensNotices = {}

-- @dev Emitted upon the successful preparation of a condition.
-- @param sender The address of the account that prepared the condition.
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function ConditionalTokensNotices:conditionPreparationNotice(conditionId, resolutionAgent, questionId, outcomeSlotCount)
  ao.send({
    Target = 'DataIndex',
    Action = "Condition-Preparation-Notice",
    ConditionId = conditionId,
    ResolutionAgent = resolutionAgent,
    QuestionId = questionId,
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
-- @param parentCollectionId The parent collection ID.
-- @param conditionId The condition ID.
-- @param partition The partition.
-- @param quantity The quantity.
-- @param msg For sending X-Tags
function ConditionalTokensNotices:positionSplitNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity, msg)
  local notice = {
    Target = from,
    Action = "Split-Position-Notice",
    Process = ao.id,
    Stakeholder = from,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    Partition = json.encode(partition),
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
  ao.send(notice)
end


-- @dev Emitted when positions are successfully merged.
-- @param from The address of the account that merged the positions.
-- @param collateralToken The address of the collateral token.
-- @param parentCollectionId The parent collection ID.
-- @param conditionId The condition ID.
-- @param partition The partition.
-- @param quantity The quantity.
function ConditionalTokensNotices:positionsMergeNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity)
  ao.send({
    Target = from,
    Action = "Merge-Positions-Notice",
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    Partition = json.encode(partition),
    Quantity = quantity
  })
end

-- @dev Emitted when a position is successfully redeemed.
-- @param redeemer The address of the account that redeemed the position.
-- @param collateralToken The address of the collateral token.
-- @param parentCollectionId The parent collection ID.
-- @param conditionId The condition ID.
-- @param indexSets The index sets.
-- @param payout The payout amount.
function ConditionalTokensNotices:payoutRedemptionNotice(redeemer, collateralToken, parentCollectionId, conditionId, indexSets, payout)
  ao.send({
    Target = DataIndex,
    Action = "Payout-Redemption-Notice",
    Process = ao.id,
    Redeemer = redeemer,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    IndexSets = json.encode(indexSets),
    Payout = tostring(payout)
  })
end

return ConditionalTokensNotices
