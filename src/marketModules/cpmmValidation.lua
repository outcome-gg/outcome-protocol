--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local cpmmValidation = {}
local sharedValidation = require('marketModules.sharedValidation')
local bint = require('.bint')(256)
local json = require("json")

--- Validates add funding
--- @param msg Message The message to be validated
--- @param totalSupply string The LP token total supply
--- @param positionIds table<string> The outcome position IDs
--- @return boolean, string|nil
function cpmmValidation.addFunding(msg, totalSupply, positionIds)
  local isValid, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not isValid then
    return false, err
  end

  -- Extract distribution
  local distribution = msg.Tags["X-Distribution"] and json.decode(msg.Tags["X-Distribution"]) or nil

  -- Check if distribution is required or must be omitted
  local isFirstFunding = bint.iszero(bint(totalSupply))
  if distribution then
    -- Ensure distribution is set only for initial funding
    if not isFirstFunding then
      return false, "Cannot specify distribution after initial funding"
    end

    -- Ensure distribution includes all position IDs
    if #distribution ~= #positionIds then
      return false, "Distribution length mismatch"
    end

    -- Validate distribution content
    local distributionSum = 0
    for i = 1, #distribution do
      if type(distribution[i]) ~= "number" then
        return false, "Distribution item must be a number"
      end
      distributionSum = distributionSum + distribution[i]
    end

    -- Ensure the distribution sum is greater than zero
    if distributionSum == 0 then
      return false, "Distribution sum must be greater than zero"
    end
  else
    -- Ensure distribution is provided for the first funding call
    if isFirstFunding then
      return false, "Must specify distribution for initial funding"
    end
  end

  return true
end

--- Validates remove funding
--- @param msg Message The message to be validated
--- @param balance string The balance of the sender's LP tokens
--- @return boolean, string|nil True if validation passes, otherwise false with an error message
function cpmmValidation.removeFunding(msg, balance)
  -- Validate that Quantity is a positive integer
  local isValid, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not isValid then
    return false, err
  end

  -- Ensure Quantity is within the sender's balance
  local quantity = bint(msg.Tags.Quantity)
  local userBalance = bint(balance or "0") -- Default to "0" if balance is nil

  if quantity > userBalance then
    return false, "Quantity must be less than or equal to balance!"
  end

  return true
end

--- Validates buy
--- @param msg Message The message to be validated
--- @param cpmm CPMM The CPMM instance for calculations
--- @return boolean, string|nil True if validation passes, otherwise false with an error message
function cpmmValidation.buy(msg, cpmm)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  local positionIds = cpmm.tokens.positionIds

  local success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
  if not success then return false, err end

  success, err = sharedValidation.validateItem(msg.Tags['X-PositionId'], positionIds, "X-PositionId")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags["X-MinPositionTokensToBuy"], "X-MinPositionTokensToBuy")
  if not success then return false, err end

  -- Calculate the actual buy amount
  local positionTokensToBuy = cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])

  -- Ensure minimum buy amount is met
  if bint(msg.Tags['X-MinPositionTokensToBuy']) > bint(positionTokensToBuy) then
    return false, 'Minimum buy amount not reached'
  end

  return true
end

--- Validates sell
--- @param msg Message The message to be validated
--- @param cpmm CPMM The CPMM instance for calculations
--- @return boolean, string|nil
function cpmmValidation.sell(msg, cpmm)
  local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.From
  local positionIds = cpmm.tokens.positionIds

  local success, err = sharedValidation.validateAddress(onBehalfOf, 'onBehalfOf')
  if not success then return false, err end

  success, err = sharedValidation.validateItem(msg.Tags.PositionId, positionIds, "PositionId")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.MaxPositionTokensToSell, "MaxPositionTokensToSell")
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  if not success then return false, err end

  -- Calculate the actual position tokens to sell
  local positionTokensToSell = cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)

 -- Ensure the sell amount does not exceed the maximum allowed
 if bint(positionTokensToSell) > bint(msg.Tags.MaxPositionTokensToSell) then
  return false, "Max position tokens to sell not sufficient!"
end

  return true
end

--- Validates calc buy amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
--- @return boolean, string|nil
function cpmmValidation.calcBuyAmount(msg, validPositionIds)
  local success, err = sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  if not success then return false, err end

  return sharedValidation.validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

--- Validates calc sell amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
--- @return boolean, string|nil
function cpmmValidation.calcSellAmount(msg, validPositionIds)
  local success, err = sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  if not success then return false, err end

  return sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

--- Validates fees withdrawable
--- @param msg Message The message to be validated
--- @return boolean, string|nil
function cpmmValidation.feesWithdrawable(msg)
  if msg.Tags["Recipient"] then
    return sharedValidation.validateAddress(msg.Tags['Recipient'], 'Recipient')
  end

  return true
end

--- Validates withdraw fees
--- @param msg Message The message to be validated
--- @return boolean, string|nil
function cpmmValidation.withdrawFees(msg)
  if msg.Tags["OnBehalfOf"] then
    return sharedValidation.validateAddress(msg.Tags['OnBehalfOf'], 'OnBehalfOf')
  end

  return true
end

--- Validates update configurator
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateConfigurator(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  return sharedValidation.validateAddress(msg.Tags.Configurator, 'Configurator')
end

--- Validates update take fee
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateTakeFee(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  local success, err = sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, 'CreatorFee')
  if not success then return false, err end

  success, err = sharedValidation.validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, 'ProtocolFee')
  if not success then return false, err end

  local totalFee = bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee))
  if not bint.__lt(totalFee, 1000) then
    return false, 'Net fee must be less than or equal to 1000 bps'
  end

  return true
end

--- Validates update protocol fee target
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateProtocolFeeTarget(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  if not msg.Tags.ProtocolFeeTarget then
    return false, 'ProtocolFeeTarget is required!'
  end

  return true
end

--- Validates update logo
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil
function cpmmValidation.updateLogo(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  if not msg.Tags.Logo then
    return false, 'Logo is required!'
  end

  return true
end

return cpmmValidation