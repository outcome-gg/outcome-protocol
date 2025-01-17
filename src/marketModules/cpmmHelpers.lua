--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local bint = require('.bint')(256)
local ao = require('.ao')

local CPMMHelpers = {}

--- Calculate the ceildiv of x / y
--- @param x number The numerator
--- @param y number The denominator
--- @return number The ceil div of x / y
function CPMMHelpers.ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end

--- Generate position IDs
--- @param outcomeSlotCount number The number of outcome slots
--- @return table<string> A basic partition based on outcomeSlotCount
function CPMMHelpers.getPositionIds(outcomeSlotCount)
  local positionIds = {}
  for i = 1, outcomeSlotCount do
    table.insert(positionIds, tostring(i))
  end
  return positionIds
end

--- Validate add funding
--- Returns funding to sender on error
--- @param from string The address of the sender
--- @param quantity number The amount of funding to add
--- @param distribution table<number> The distribution of funding
--- @return boolean True if error
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
      Target = self.tokens.collateralToken,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Add-Funding Error: ' .. errorMessage
    })
  end
  return not error
end

--- Validate remove funding
--- Returns LP tokens to sender on error
--- @param from string The address of the sender
--- @param quantity number The amount of funding to remove
--- @return boolean True if error
function CPMMHelpers:validateRemoveFunding(from, quantity)
  local error = false
  local errorMessage = ''
  -- Get balance
  local balance = self.token.balances[from] or '0'
  -- Check for errors
  if from == self.creatorFeeTarget and self.payoutDenominator and self.payoutDenominator == 0 then
    error = true
    errorMessage = 'Creator liquidity locked until market resolution!'
  elseif not bint.__le(bint(quantity), bint(balance)) then -- @dev TODO: remove as will never be called?
    error = true
    errorMessage = 'Quantity must be less than balance!'
  end
  -- Return funds on error.
  if error then
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = errorMessage
    })
  end
  return not error
end

--- Gets pool balances
--- @return table<string> Pool balances for each ID
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