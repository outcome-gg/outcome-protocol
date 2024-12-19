local bint = require('.bint')(256)
local utils = require('.utils')
local sharedUtils = require('modules.sharedUtils')

local cpmmValidation = {}

local function validateAddress(recipient, tagName)
  assert(type(recipient) == 'string', tagName .. ' is required!')
  assert(sharedUtils.isValidArweaveAddress(recipient), tagName .. ' must be a valid Arweave address!')
end

local function validatePositionId(positionId, validPositionIds)
  assert(type(positionId) == 'string', 'PositionId is required!')
  assert(utils.includes(positionId, validPositionIds), 'Invalid positionId!')
end

local function validatePositiveInteger(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

function cpmmValidation.init(msg, isInitialized)
  -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
  assert(isInitialized == false, "Market already initialized!")
  assert(msg.Tags.MarketId, "MarketId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  validateAddress(msg.Tags.CollateralToken, "CollateralToken")
  validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  -- Limit of 256 because we use a partition array that is a number of 256 bits.
  assert(outcomeSlotCount <= 256, "Too many outcome slots!")
  assert(outcomeSlotCount > 1, "There should be more than one outcome slot!")
  -- LP Token Parameters
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")
  -- Fee Parameters
  validatePositiveInteger(msg.Tags.LpFee, "LpFee")
  validatePositiveInteger(msg.Tags.CreatorFee, "CreatorFee")
  validatePositiveInteger(msg.Tags.ProtocolFee, "ProtocolFee")
  validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  validateAddress(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget")
  -- Take Fee Capped at 1000 bps, ie. 10%
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Take Fee capped at 10%!')
  -- Admin Parameter
  validateAddress(msg.Tags.Configurator, "Configurator")
  -- Incentives
  validateAddress(msg.Tags.Incentives, "Incentives")
  -- @dev TODO: include "resolve-by" field to enable fallback resolution
end

function cpmmValidation.addFunding(msg)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
  assert(sharedUtils.isJSONArray(msg.Tags['X-Distribution']), 'X-Distribution must be valid JSON Array!')
  -- @dev TODO: remove requirement for X-Distribution
end

function cpmmValidation.removeFunding(msg)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

function cpmmValidation.buy(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

function cpmmValidation.sell(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  validatePositiveInteger(msg.Tags.MaxOutcomeTokensToSell, "MaxOutcomeTokensToSell")
end

function cpmmValidation.calcBuyAmount(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

function cpmmValidation.calcSellAmount(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

function cpmmValidation.updateConfigurator(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.Configurator, 'Configurator is required!')
end

function cpmmValidation.updateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.Incentives, 'Incentives is required!')
end

function cpmmValidation.updateTakeFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.CreatorFee, 'CreatorFee is required!')
  assert(tonumber(msg.Tags.CreatorFee), 'CreatorFee must be a number!')
  assert(tonumber(msg.Tags.CreatorFee) >= 0, 'CreatorFee must be greater than or equal to zero!')
  assert(tonumber(msg.Tags.CreatorFee) % 1 == 0, 'CreatorFee must be an integer!')
  assert(msg.Tags.ProtocolFee, 'ProtocolFee is required!')
  assert(tonumber(msg.Tags.ProtocolFee), 'ProtocolFee must be a number!')
  assert(tonumber(msg.Tags.ProtocolFee) >= 0, 'ProtocolFee must be greater than or equal to zero!')
  assert(tonumber(msg.Tags.ProtocolFee) % 1 == 0, 'ProtocolFee must be an integer!')
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Net fee must be less than or equal to 1000 bps')
end

function cpmmValidation.updateProtocolFeeTarget(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.ProtocolFeeTarget, 'ProtocolFeeTarget is required!')
end

function cpmmValidation.updateLogo(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')
end

return cpmmValidation