-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local semiFungibleTokens = require('modules.semiFungibleTokens')
local conditionalTokensHelpers = require('modules.conditionalTokensHelpers')

local SemiFungibleTokens = {}
local ConditionalTokens = {}
local ConditionalTokensMethods = require('modules.conditionalTokensNotices')

-- Constructor for ConditionalTokens 
function ConditionalTokens:new(config)
  -- Initialize SemiFungibleTokens and store the object
  SemiFungibleTokens = semiFungibleTokens:new(config.tokens.name, config.tokens.ticker, config.tokens.logo, config.tokens.balancesById, config.tokens.totalSupplyByIdOf, config.tokens.denomination)

  -- Create a new ConditionalTokens object
  local obj = {
    -- SemiFungible Tokens
    tokens = SemiFungibleTokens,
    conditionId = config.ctf.conditionId,
    positionIds = config.ctf.positionIds,
    outcomeSlotCount = config.ctf.outcomeSlotCount,
    payoutNumerators = config.ctf.payoutNumerators,
    payoutDenominator = config.ctf.payoutDenominator,
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
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function ConditionalTokensMethods:prepareCondition(conditionId, outcomeSlotCount, msg)
  assert(self.payoutNumerators[conditionId] == nil, "condition already prepared")
  -- Initialize the payout vector associated with the condition.
  self.payoutNumerators[conditionId] = {}
  for _ = 1, outcomeSlotCount do
    table.insert(self.payoutNumerators[conditionId], 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  self.payoutDenominator[conditionId] = 0
  -- Send the condition preparation notice.
  self:conditionPreparationNotice(conditionId, outcomeSlotCount, msg)
end

-- @dev Called by the resolutionAgent for reporting results of conditions. Will set the payout vector for the condition with the ID `keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount))`, 
-- where ResolutionAgent is the message sender, QuestionId is one of the parameters of this function, and OutcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
-- @param QuestionId The question ID the oracle is answering for
-- @param Payouts The oracle's answer
function ConditionalTokensMethods:reportPayouts(questionId, payouts, msg)
  -- IMPORTANT, the payouts length accuracy is enforced because outcomeSlotCount is part of the hash.
  local outcomeSlotCount = #payouts
  assert(outcomeSlotCount > 1, "there should be more than one outcome slot")
  -- IMPORTANT, the resolutionAgent is enforced to be the sender because it's part of the hash.
  local conditionId = self.getConditionId(msg.From, questionId, tostring(outcomeSlotCount))
  assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] == outcomeSlotCount, "condition not prepared or found")
  assert(self.payoutDenominator[conditionId] == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, outcomeSlotCount do
    local num = payouts[i]
    den = den + num
    assert(self.payoutNumerators[conditionId][i] == 0, "payout numerator already set")
    self.payoutNumerators[conditionId][i] = num
  end
  assert(den > 0, "payout is all zeroes")
  self.payoutDenominator[conditionId] = den
  -- Send the condition resolution notice.
  self:conditionResolutionNotice(conditionId, msg.From, questionId, outcomeSlotCount, json.encode(self.payoutNumerators[conditionId]))
end

-- @dev This function splits a position from collateral. This contract will attempt to transfer `amount` collateral from the message sender to itself. 
-- If successful, `quantity` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert.
-- @param from The initiator of the original Split-Position / Create-Position action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param quantity The quantity of collateral or stake to split.
-- @param msg Msg passed to retrieve x-tags
function ConditionalTokensMethods:splitPosition(from, collateralToken, quantity, msg)
  assert(self.payoutNumerators[self.conditionId] and #self.payoutNumerators[self.conditionId] > 0, "condition not prepared yet")
  -- Create equal split positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Mint the stake in the split target positions.
  SemiFungibleTokens:batchMint(from, self.positionIds, quantities)
  -- Send notice.
  self:positionSplitNotice(from, collateralToken, self.conditionId, quantity, msg)
end

-- @dev This function merges positions. If merging to the collateral, this contract will attempt to transfer `quantity` collateral to the message sender.
-- Otherwise, this contract will burn `quantity` stake held by the message sender in the positions being merged worth of semi-fungible tokens.
-- If successful, `quantity` stake will be minted in the merged position. If any of the transfers, mints, or burns fail, the transaction will revert.
-- @param from The initiator of the original Merge-Positions action message.
-- @param onBehalfOf The address that will receive the collateral.
-- @param quantity The quantity of collateral or stake to merge.
-- @param msg Msg passed to retrieve x-tags
function ConditionalTokensMethods:mergePositions(from, onBehalfOf, quantity, isSell, msg)
  assert(self.payoutNumerators[self.conditionId] and #self.payoutNumerators[self.conditionId] > 0, "condition not prepared yet")
  -- Create equal merge positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Burn equal quantiies from user positions.
  self.tokens:batchBurn(from, self.positionIds, quantities, msg)
  -- @dev below already handled within the sell method. 
  -- sell method w/ a different quantity and recipient.
  if not isSell then
    -- Return the collateral to the user.
    ao.send({
      Target = self.collateralToken,
      Action = "Transfer",
      Quantity = quantity,
      Recipient = onBehalfOf
    })
  end
  -- Send notice.
  self:positionsMergeNotice(self.conditionId, quantity, msg)
end

-- @dev This function redeems positions. If redeeming to the collateral, this contract will attempt to transfer the payout to the message sender.
-- Otherwise, this contract will burn the stake held by the message sender in the positions being redeemed worth of semi-fungible tokens.
-- If successful, the payout will be minted in the parent position. If any of the transfers, mints, or burns fail, the transaction will revert.
-- @param from The initiator of the original Redeem-Positions action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the positions being redeemed and the parent position. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to redeem on.
-- @param indexSets An array of index sets representing the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
function ConditionalTokensMethods:redeemPositions(from, msg)
  local den = self.payoutDenominator[self.conditionId]
  assert(den > 0, "result for condition not received yet")
  assert(self.payoutNumerators[self.conditionId] and #self.payoutNumerators[self.conditionId] > 0, "condition not prepared yet")
  local totalPayout = 0
  for i = 1, #self.positionIds do
    local positionId = self.positionIds[i]
    local payoutNumerator = self.payoutNumerators[self.conditionId][positionId]

    -- Get the stake to redeem.
    if not self.tokens.balancesById[positionId] then self.tokens.balancesById[positionId] = {} end
    if not self.tokens.balancesById[positionId][from] then self.tokens.balancesById[positionId][from] = "0" end
    local payoutStake = self.tokens.balancesById[positionId][from]
    -- Calculate the payout and burn position.
    if bint.__lt(0, bint(payoutStake)) then
      totalPayout = math.floor(totalPayout + (payoutStake * payoutNumerator) / den)
      self:burn(from, positionId, payoutStake)
    end
  end
  -- Return totla payout minus take fee.
  if totalPayout > 0 then
    totalPayout = math.floor(totalPayout)
    self:returnTotalPayoutMinusTakeFee(self.collateralToken, from, totalPayout)
  end
  -- Send notice.
  self:payoutRedemptionNotice(self.collateralToken, self.conditionId, totalPayout, msg)
end

-- @dev Gets the outcome slot count of a condition.
-- @param ConditionId ID of the condition.
-- @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
function ConditionalTokensMethods:getOutcomeSlotCount(msg)
  return #self.payoutNumerators[msg.Tags.ConditionId]
end

return ConditionalTokens
