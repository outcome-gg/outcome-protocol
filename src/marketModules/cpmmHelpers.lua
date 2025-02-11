--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local bint = require('.bint')(256)
-- local ao = require('.ao') @dev required for unit tests?

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
--- @param distribution table<number>|nil The distribution of funding or `nil`
--- @return boolean True if error
function CPMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''

  if distribution then
    -- Ensure distribution set only for initial funding
    if not error and not bint.iszero(bint(self.token.totalSupply)) then
      error = true
      errorMessage = "Cannot specify distribution after initial funding"
    end
    -- Ensure distribution is set across all position ids
    if not error and #distribution ~= #self.tokens.positionIds then
      error = true
      errorMessage = "Distribution length mismatch"
    end
    if not error then
      -- Ensure distribution content is valid
      local distributionSum = 0
      for i = 1, #distribution do
        if not error and type(distribution[i]) ~= "number" then
          error = true
          errorMessage = "Distribution item must be number"
        else
          distributionSum = distributionSum + distribution[i]
        end
      end
      if not error and distributionSum == 0 then
        error = true
        errorMessage = "Distribution sum must be greater than zero"
      end
    end
  else
    if bint.iszero(bint(self.token.totalSupply)) then
      error = true
      errorMessage = "Must specify distribution for inititial funding"
    end
  end

  if error then
    -- Return funds and assert error
    ao.send({
      Target = self.tokens.collateralToken,
      Action = 'Transfer',
      Recipient = from,
      Quantity = tostring(quantity),
      ['X-Error'] = 'Add-Funding Error: ' .. errorMessage
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
  local errorMessage = ""
  -- Get balance
  local balance = self.token.balances[from] or '0'
  if not bint.__le(bint(quantity), bint(balance)) then
    error = true
    errorMessage = "Quantity must be less than balance!"
  end
  if error then
    -- Return funds and assert error
    ao.send({
      Target = from,
      Error = 'Remove-Funding Error: ' .. errorMessage
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