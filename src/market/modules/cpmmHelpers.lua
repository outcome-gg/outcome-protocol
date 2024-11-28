local bint = require('.bint')(256)
local ao = require('.ao')

local CPMMHelpers = {}

-- Utility function: CeilDiv
function CPMMHelpers.ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end


--@dev generates basic partition based on outcomesSlotCount
function CPMMHelpers.generateBasicPartition(outcomeSlotCount)
  local partition = {}
  for i = 0, outcomeSlotCount - 1 do
    table.insert(partition, 1 << i)
  end
  return partition
end

-- @dev validates addFunding
function CPMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''

  -- Ensure distribution
  if not distribution then
    error = true
    errorMessage = 'X-Distribution is required!'
  elseif not error then
    if bint.iszero(bint(self.token.totalSupply)) then
      -- Ensure distribution is set across all position ids
      if #distribution ~= #self.tokens.positionIds then
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
function CPMMHelpers:validateRemoveFunding(from, quantity)
  local error = false
  local balance = self.token.balances[from] or '0'
  if not bint.__le(bint(quantity), bint(balance)) then
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

-- @dev get pool balances
function CPMMHelpers:getPoolBalances()
  -- Get poolBalances
  local selves = {}
  for _ = 1, #self.tokens.positionIds do
    table.insert(selves, ao.id)
  end
  local poolBalances = self.tokens:getBatchBalance(selves, self.tokens.positionIds)
  return poolBalances
end

return CPMMHelpers