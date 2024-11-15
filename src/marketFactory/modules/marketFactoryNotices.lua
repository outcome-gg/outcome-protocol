local ao = require('.ao')
local json = require('json')

MarketFactoryNotices = {}

-- @dev Emitted upon the successful creation of a market.
-- @param target The address to send the notice to.
-- @param marketId The market Id.
function MarketFactoryNotices.marketCreatedNotice(target, marketId, processId, resolutionAgent, question, questionId, conditionId, conditionalTokens, collateralToken, parentCollectionId, collectionIds, positionIds, outcomeSlotCount, partition, distribution, quantity)
  -- TODO: Decide if to be sent to user and/or Data Index
  ao.send({
    Target = target,
    Action = "Market-Created-Notice",
    MarketId = marketId,
    ProcessId = processId,
    ResolutionAgent = resolutionAgent,
    Question = question,
    QuestionId = questionId,
    ConditionId = conditionId,
    ConditionalTokens = conditionalTokens,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    CollectionIds = json.encode(collectionIds),
    PositionIds = json.encode(positionIds),
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Partition = json.encode(partition),
    Distribution = json.encode(distribution),
    Quantity = quantity
  })
end

-- @dev Emitted upon the successful init of a market.
-- @param target The address to send the notice to.
-- @param marketId The market Id.
function MarketFactoryNotices.marketInitNotice(marketId, msg)
  -- TODO: Decide if to be sent to user and/or Data Index
  msg.reply({
    Action = "Market-Init-Notice",
    MarketId = marketId
  })
end

-- @dev Emitted upon the successful funding of a market.
-- @param target The address to send the notice to.
-- @param marketId The market Id.
function MarketFactoryNotices:marketFundedNotice(target, marketId)
  -- TODO: Decide if to be sent to user and/or Data Index
  ao.send({
    Target = target,
    Action = "Market-Funded-Notice",
    MarketId = marketId
  })
end


return MarketFactoryNotices
