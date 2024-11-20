-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local config = require('modules.config')
local semiFungibleTokens = require('modules.semiFungibleTokens')
local conditionalTokensHelpers = require('modules.conditionalTokensHelpers')

local SemiFungibleTokens = {}
local ConditionalTokens = {}
local ConditionalTokensMethods = require('modules.conditionalTokensNotices')

-- Constructor for ConditionalTokens 
function ConditionalTokens:new()
  -- Load config
  config = config:new()
  -- Initialize SemiFungibleTokens and store the object
  SemiFungibleTokens = semiFungibleTokens:new(config.tokens.name, config.tokens.ticker, config.tokens.logo, config.tokens.balancesOf, config.tokens.totalSupplyOf, config.tokens.denomination)

  -- Create a new ConditionalTokens object
  local obj = {
    -- SemiFungible Tokens
    tokens = SemiFungibleTokens,
    payoutNumerators = {},
    payoutDenominator = {},
    takeFeePercentage = config.takeFee.percentage,
    takeFeeTarget = config.takeFee.target,
    ONE = config.takeFee.ONE,
    resetState = config.resetState
  }

  -- Set metatable for method lookups from ConditionalTokensMethods, SemiFungibleTokensMethods, and ConditionalTokensHelpers
  setmetatable(obj, {
    __index = function(t, k)
      -- First, look up the key in ConditionalTokensMethods
      if ConditionalTokensMethods[k] then
        return ConditionalTokensMethods[k]
      -- Then, check in ConditionalTokensHelpers
      elseif conditionalTokensHelpers[k] then
        return conditionalTokensHelpers[k]
      -- Lastly, look up the key in the semiFungibleInstance methods
      elseif SemiFungibleTokens[k] then
        return SemiFungibleTokens[k]
      else
        return nil
      end
    end
  })
  return obj
end

-- @dev This function prepares a condition by initializing a payout vector associated with the condition.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function ConditionalTokensMethods:prepareCondition(msg)
  local data = json.decode(msg.Data)
  assert(data.resolutionAgent, "resolutionAgent is required!")
  assert(data.questionId, "questionId is required!")
  assert(data.outcomeSlotCount, "outcomeSlotCount is required!")
  assert(type(data.outcomeSlotCount) == 'number', "outcomeSlotCount must be a number!")
  -- Limit of 256 because we use a partition array that is a number of 256 bits.
  assert(data.outcomeSlotCount <= 256, "too many outcome slots")
  assert(data.outcomeSlotCount > 1, "there should be more than one outcome slot")
  -- Contruct conditionId from resolutionAgent, questionId, and outcomeSlotCount
  local conditionId = self.getConditionId(data.resolutionAgent, data.questionId, tostring(data.outcomeSlotCount))
  assert(self.payoutNumerators[conditionId] == nil, "condition already prepared")
  -- Initialize the payout vector associated with the condition.
  self.payoutNumerators[conditionId] = {}
  for _ = 1, data.outcomeSlotCount do
    table.insert(self.payoutNumerators[conditionId], 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  self.payoutDenominator[conditionId] = 0
  -- Send the condition preparation notice.
  self:conditionPreparationNotice(conditionId, data.resolutionAgent, data.questionId, data.outcomeSlotCount, msg)
end

-- @dev Called by the resolutionAgent for reporting results of conditions. Will set the payout vector for the condition with the ID `keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount))`, 
-- where ResolutionAgent is the message sender, QuestionId is one of the parameters of this function, and OutcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
-- @param QuestionId The question ID the oracle is answering for
-- @param Payouts The oracle's answer
function ConditionalTokensMethods:reportPayouts(msg)
  local data = json.decode(msg.Data)
  assert(data.questionId, "QuestionId is required!")
  assert(data.payouts, "Payouts is required!")
  -- IMPORTANT, the payouts length accuracy is enforced because outcomeSlotCount is part of the hash.
  local outcomeSlotCount = #data.payouts
  assert(outcomeSlotCount > 1, "there should be more than one outcome slot")
  -- IMPORTANT, the resolutionAgent is enforced to be the sender because it's part of the hash.
  local conditionId = self.getConditionId(msg.From, data.questionId, tostring(outcomeSlotCount))
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] == outcomeSlotCount, "condition not prepared or found")
  assert(self.payoutDenominator[conditionId] == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, outcomeSlotCount do
    local num = data.payouts[i]
    den = den + num
    assert(self.payoutNumerators[conditionId][i] == 0, "payout numerator already set")
    self.payoutNumerators[conditionId][i] = num
  end
  assert(den > 0, "payout is all zeroes")
  self.payoutDenominator[conditionId] = den
  -- Send the condition resolution notice.
  self:conditionResolutionNotice(conditionId, msg.From, data.questionId, outcomeSlotCount, json.encode(self.payoutNumerators[conditionId]))
end

-- @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. 
-- Otherwise, this contract will burn `quantity` stake held by the message sender in the position being split worth of semi-fungible tokens. 
-- Regardless, if successful, `quantity` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert.
-- The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
-- @param from The initiator of the original Split-Position / Create-Position action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to split on.
-- @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
-- @param quantity The quantity of collateral or stake to split.
-- @param isCreate True if the position is being split from the collateralToken.
-- @param msg Msg passed to retrieve x-tags
function ConditionalTokensMethods:splitPosition(from, collateralToken, parentCollectionId, conditionId, partition, quantity, isCreate, msg)
  assert(#partition > 1, "got empty or singleton partition")
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] > 0, "condition not prepared yet")

  local outcomeSlotCount = #self.payoutNumerators[conditionId]

  -- For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
  local fullIndexSet = (1 << outcomeSlotCount) - 1

  -- freeIndexSet starts as the full collection
  local freeIndexSet = fullIndexSet

  -- This loop checks that all condition sets are disjoint (the same outcome is not part of more than 1 set)
  local positionIds = {}
  local quantities = {}
  for i = 1, #partition do
    local indexSet = partition[i]
    assert(indexSet > 0 and indexSet < fullIndexSet, "got invalid index set " .. "partition: " .. json.encode(partition) .. tostring(indexSet) .. " " .. tostring(fullIndexSet))
    assert((indexSet & freeIndexSet) == indexSet, "partition not disjoint")
    freeIndexSet = freeIndexSet ~ indexSet
    positionIds[i] = self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, indexSet))
    quantities[i] = quantity
  end

  if freeIndexSet == 0 then
    -- Partitioning the full set of outcomes for the condition in this branch
    if parentCollectionId == "" then
      assert(isCreate, "could not receive collateral tokens")
    else
      SemiFungibleTokens:burn(from, self.getPositionId(collateralToken, parentCollectionId), quantity)
    end
  else
    -- Partitioning a subset of outcomes for the condition in this branch.
    -- For example, for a condition with three outcomes A, B, and C, this branch
    -- allows the splitting of a position $:(A|C) to positions $:(A) and $:(C).
    SemiFungibleTokens:burn(from, self.getPositionId(collateralToken, parentCollectionId), quantity)
  end

  SemiFungibleTokens:batchMint(from, positionIds, quantities)

  self:positionSplitNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity, msg)
end

-- @dev This function merges positions. If merging to the collateral, this contract will attempt to transfer `quantity` collateral to the message sender.
-- Otherwise, this contract will burn `quantity` stake held by the message sender in the positions being merged worth of semi-fungible tokens.
-- If successful, `quantity` stake will be minted in the merged position. If any of the transfers, mints, or burns fail, the transaction will revert.
-- @param from The initiator of the original Merge-Positions action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the positions being merged and the merged position. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to merge on.
-- @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
-- @param quantity The quantity of collateral or stake to merge.
-- @param msg Msg passed to retrieve x-tags
function ConditionalTokensMethods:mergePositions(from, collateralToken, parentCollectionId, conditionId, partition, quantity, msg)
  assert(#partition > 1, "got empty or singleton partition")
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] > 0, "condition not prepared yet")

  local outcomeSlotCount = #self.payoutNumerators[conditionId]

  -- For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
  local fullIndexSet = (1 << outcomeSlotCount) - 1

  -- freeIndexSet starts as the full collection
  local freeIndexSet = fullIndexSet
  -- This loop checks that all condition sets are disjoint (the same outcome is not part of more than 1 set)
  local positionIds = {}
  local quantities = {}
  for i = 1, #partition do
    local indexSet = partition[i]
    assert(indexSet > 0 and indexSet < fullIndexSet, "got invalid index set partition: " .. json.encode(partition) .. tostring(indexSet) .. " " .. tostring(fullIndexSet))
    assert((indexSet & freeIndexSet) == indexSet, "partition not disjoint")
    freeIndexSet = freeIndexSet ~ indexSet
    positionIds[i] = self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, indexSet))
    quantities[i] = quantity
  end

  SemiFungibleTokens:batchBurn(from, positionIds, quantities, msg)

  local mergeToCollateral = false

  if freeIndexSet == 0 then
    if parentCollectionId == "" then
      mergeToCollateral = true
      ao.send({
        Target = collateralToken,
        Action = "Transfer",
        Recipient = from,
        Quantity = tostring(quantity),
        ['X-Action'] = "Merge-Positions-Completion",
        ['X-CollateralToken'] = collateralToken,
        ['X-ParentCollectionId'] = parentCollectionId,
        ['X-ConditionId'] = conditionId,
        ['X-Partition'] = json.encode(partition),
        ['X-Sender'] = msg.Tags['X-Sender'], -- for amm
        ['X-ReturnAmount'] = msg.Tags['X-ReturnAmount'], -- for amm
      })
    else
      SemiFungibleTokens:mint(from, self.getPositionId(collateralToken, parentCollectionId), quantity)
    end
  else
    SemiFungibleTokens:mint(from, self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, fullIndexSet ~ freeIndexSet)), quantity, "")
  end

  if not mergeToCollateral then
    self:positionsMergeNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity)
  end
end

-- @dev This function redeems positions. If redeeming to the collateral, this contract will attempt to transfer the payout to the message sender.
-- Otherwise, this contract will burn the stake held by the message sender in the positions being redeemed worth of semi-fungible tokens.
-- If successful, the payout will be minted in the parent position. If any of the transfers, mints, or burns fail, the transaction will revert.
-- @param from The initiator of the original Redeem-Positions action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the positions being redeemed and the parent position. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to redeem on.
-- @param indexSets An array of index sets representing the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
function ConditionalTokensMethods:redeemPositions(from, collateralToken, parentCollectionId, conditionId, indexSets)
  local den = self.payoutDenominator[conditionId]
  assert(den > 0, "result for condition not received yet")
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] > 0, "condition not prepared yet")

  local outcomeSlotCount = #self.payoutNumerators[conditionId]
  local totalPayout = 0
  local fullIndexSet = (1 << outcomeSlotCount) - 1

  for i = 1, #indexSets do
    local indexSet = indexSets[i]
    assert(indexSet > 0 and indexSet < fullIndexSet, "got invalid index set")

    local positionId = self.getPositionId(collateralToken, self.getCollectionId(parentCollectionId, conditionId, indexSet))
    local payoutNumerator = 0

    for j = 0, outcomeSlotCount - 1 do
      if indexSet & (1 << j) ~= 0 then
        payoutNumerator = payoutNumerator + self.payoutNumerators[conditionId][j + 1]
      end
    end

    assert(self.tokens.balancesOf[positionId], "invalid position")
    if not self.tokens.balancesOf[positionId][from] then self.tokens.balancesOf[positionId][from] = "0" end
    local payoutStake = self.tokens.balancesOf[positionId][from]
    if bint.__lt(0, bint(payoutStake)) then
      totalPayout = totalPayout + (payoutStake * payoutNumerator) / den
      self:burn(from, positionId, payoutStake)
    end
  end

  if totalPayout > 0 then
    totalPayout = math.floor(totalPayout)
    if parentCollectionId == "" then
      self:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout, parentCollectionId, conditionId, indexSets)
    else
      SemiFungibleTokens:mint(from, self.getPositionId(collateralToken, parentCollectionId), totalPayout)
    end
  end

  self:payoutRedemptionNotice(from, collateralToken, parentCollectionId, conditionId, indexSets, totalPayout)
end

-- @dev Gets the outcome slot count of a condition.
-- @param ConditionId ID of the condition.
-- @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
function ConditionalTokensMethods:getOutcomeSlotCount(msg)
  return #self.payoutNumerators[msg.Tags.ConditionId]
end

return ConditionalTokens
