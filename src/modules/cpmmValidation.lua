local bint = require('.bint')(256)
local utils = require('utils')
local sharedUtils = require('modules.sharedUtils')

local cpmmValidation = {}

local function validateAddress(recipient, tagName)
  assert(type(recipient) == 'string', tagName .. ' is required!')
  assert(sharedUtils.isValidArweaveAddress(recipient), tagName .. ' must be a valid Arweave address!')
end

local function validatePositionId(positionId)
  assert(type(positionId) == 'string', 'PositionId is required!')
  assert(utils.includes(positionId, CPMM.tokens.positionIds), 'Invalid positionId!')
end

local function validatePositiveInteger(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

function cpmmValidation.init(msg)
  -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
  assert(CPMM.initialized == false, "Market already initialized!")
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

function cpmmValidation.buy(msg)
  validatePositionId(msg.Tags.PositionId)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

function cpmmValidation.sell(msg)
  validatePositionId(msg.Tags.PositionId)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  validatePositiveInteger(msg.Tags.MaxOutcomeTokensToSell, "MaxOutcomeTokensToSell")
end

function cpmmValidation.calcBuyAmount(msg)
  validatePositionId(msg.Tags.PositionId)
  validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

function cpmmValidation.calcSellAmount(msg)
  validatePositionId(msg.Tags.PositionId)
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

return cpmmValidation