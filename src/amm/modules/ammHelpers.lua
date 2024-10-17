local crypto = require('.crypto')
local bint = require('.bint')(256)
local json = require('json')
local ao = require('.ao')

local AMMHelpers = {}

-- Utility function: CeilDiv
function AMMHelpers.ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end

-- Generate basic partition
--@dev hardcoded to 2 outcomesSlotCount
function AMMHelpers.generateBasicPartition()
  local partition = {}
  for i = 0, 1 do
    table.insert(partition, 1 << i)
  end
  return partition
end

-- @dev validates addFunding
function AMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''

  -- Ensure distribution
  if not distribution then
    error = true
    errorMessage = 'X-Distribution is required!'
  elseif not error then
    if bint.iszero(bint(self.tokens.totalSupply)) then
      -- Ensure distribution is set across all position ids
      if #distribution ~= #self.positionIds then
        error = true
        errorMessage = "Distribution length mismatch"
      end
    else
      -- Ensure distribution set only for initial funding
      if bint.__lt(0, #distribution) then
        error = true
        errorMessage = "Cannot specify distribution after initial funding"
      end
    end
  end
  if error then
    -- Return funds and assert error
    ao.send({
      Target = self.collateralToken,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Add-Funding Error: ' .. errorMessage
    })
  end
  return not error
end

-- @dev validates removeFunding
function AMMHelpers:validateRemoveFunding(from, quantity)
  local error = false
  local balance = self.tokens.balances[from] or '0'
  if not bint.__lt(bint(quantity), bint(balance)) then
    error = true
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Remove-Funding Error: Quantity must be less than balance!'
    })
  end
  return not error
end

-- @dev creates a position within the conditionalTokens process
function AMMHelpers:createPosition(from, quantity, outcomeIndex, outcomeTokensToBuy, lpTokensMintAmount, sendBackAmounts)
  ao.send({
    Target = self.collateralToken,
    Action = "Transfer",
    Quantity = quantity,
    Recipient = self.conditionalTokens,
    ['X-Action'] = "Create-Position",
    ['X-ParentCollectionId'] = "",
    ['X-ConditionId'] = self.conditionId,
    ['X-Partition'] = json.encode(self.generateBasicPartition()),
    ['X-OutcomeIndex'] = tostring(outcomeIndex),
    ['X-OutcomeTokensToBuy'] = tostring(outcomeTokensToBuy),
    ['X-LPTokensMintAmount'] = tostring(lpTokensMintAmount),
    ['X-SendBackAmounts'] = json.encode(sendBackAmounts),
    ['X-Sender'] = from
  })
end

-- @dev merges positions within the conditionalTokens process
function AMMHelpers:mergePositions(from, returnAmount, returnAmountPlusFees, outcomeIndex, outcomeTokensToSell)
  ao.send({
    Target = self.conditionalTokens,
    Action = "Merge-Positions",
    ['X-Sender'] = from,
    ['X-ReturnAmount'] = returnAmount,
    ['X-OutcomeIndex'] = tostring(outcomeIndex),
    ['X-OutcomeTokensToSell'] = tostring(outcomeTokensToSell),
    Data = json.encode({
      collateralToken = self.collateralToken,
      parentCollectionId = '',
      conditionId = self.conditionId,
      partition = self.generateBasicPartition(),
      quantity = returnAmountPlusFees
    })
  })
end

return AMMHelpers