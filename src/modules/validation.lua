local json = require('json')
local bint = require('.bint')(256)
local utils = require('.utils')

local validation = {}

---------------------------------------------------------------------------------
-- CPMM VALIDATION --------------------------------------------------------------
---------------------------------------------------------------------------------

function validation.init(msg)
  -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
  assert(CPMM.initialized == false, "Market already initialized!")
  assert(msg.Tags.MarketId, "MarketId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  -- Limit of 256 because we use a partition array that is a number of 256 bits.
  assert(outcomeSlotCount <= 256, "Too many outcome slots!")
  assert(outcomeSlotCount > 1, "There should be more than one outcome slot!")
  -- LP Token Parameters
  assert(msg.Tags.Name, "Name is required!")
  assert(msg.Tags.Ticker, "Ticker is required!")
  assert(msg.Tags.Logo, "Logo is required!")
  -- Fee Parameters
  assert(msg.Tags.LpFee, "LpFee is required!")
  assert(msg.Tags.CreatorFee, "CreatorFee is required!")
  assert(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget is required!")
  assert(msg.Tags.ProtocolFee, "ProtocolFee is required!")
  assert(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget is required!")
  -- Take Fee Capped at 1000 bps, ie. 10%
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Take Fee capped at 10%!')
  -- Admin Parameter
  assert(msg.Tags.Configurator, "Configurator is required!")
  -- Incentives
  assert(msg.Tags.Incentives, "Incentives is required!")
  -- @dev TODO: include "resolve-by" field to enable fallback resolution
end

function validation.addFunding(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
  assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
  assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
  -- @dev TODO: remove requirement for X-Distribution
end

function validation.removeFunding(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
  assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
end

function validation.buy(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
  assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
end

function validation.sell(msg)
  assert(msg.Tags.PositionId, 'PositionId is required!')
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
  assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
  assert(msg.Tags['ReturnAmount'], 'ReturnAmount is required!')
  assert(tonumber(msg.Tags['ReturnAmount']), 'ReturnAmount must be a number!')
  assert(tonumber(msg.Tags['ReturnAmount']) > 0, 'ReturnAmount must be greater than zero!')
  assert(tonumber(msg.Tags['ReturnAmount']) % 1 == 0, 'ReturnAmount must be an integer!')
  assert(msg.Tags['MaxOutcomeTokensToSell'], 'MaxOutcomeTokensToSell is required!')
  assert(tonumber(msg.Tags['MaxOutcomeTokensToSell']), 'MaxOutcomeTokensToSell must be a number!')
  assert(tonumber(msg.Tags['MaxOutcomeTokensToSell']) > 0, 'MaxOutcomeTokensToSell must be greater than zero!')
  assert(tonumber(msg.Tags['MaxOutcomeTokensToSell']) % 1 == 0, 'MaxOutcomeTokensToSell must be an integer!')
end

function validation.calcBuyAmount(msg)
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(msg.Tags.PositionId, 'PositionId is required!')
end

function validation.calcSellAmount(msg)
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(msg.Tags.PositionId, 'PositionId is required!')
end

---------------------------------------------------------------------------------
-- CTF VALIDATION ---------------------------------------------------------------
---------------------------------------------------------------------------------

function validation.merge(msg)
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
  assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
end

function validation.reportPayouts(msg)
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  assert(msg.Tags.Payouts, "Payouts is required!")
end

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN VALIDATION -----------------------------------------------
---------------------------------------------------------------------------------

-- function validation.transferSingle(msg)
--   assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
--   assert(type(msg.Tags.TokenId) == 'string', 'TokenId is required!')
--   assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
--   assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
--   assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
--   assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
-- end

-- function validation.transferBatch(msg)
--   assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
--   assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
--   local tokenIds = json.decode(msg.Tags.TokenIds)
--   assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
--   local quantities = json.decode(msg.Tags.Quantities)
--   assert(#tokenIds == #quantities, 'Input array lengths must match!')
--   for i = 1, #quantities do
--     assert(bint.__lt(0, bint(quantities[i])), 'Quantity must be greater than 0')
--   end
--   for i = 1, #tokenIds do
--     assert(utils.includes(tokenIds[i], CPMM.tokens.positionIds), 'Invalid tokenId!')
--   end
-- end

-- function validation.balanceById(msg)
--   assert(msg.Tags.TokenId, "TokenId is required!")
--   assert(tonumber(msg.Tags.TokenId), 'TokenId must be a number!')
--   assert(tonumber(msg.Tags.TokenId) > 0, 'TokenId must be greater than zero!')
--   assert(tonumber(msg.Tags.TokenId) % 1 == 0, 'TokenId must be an integer!')
-- end

-- function validation.balancesById(msg)
--   assert(msg.Tags.TokenId, "TokenId is required!")
--   assert(tonumber(msg.Tags.TokenId), 'TokenId must be a number!')
--   assert(tonumber(msg.Tags.TokenId) > 0, 'TokenId must be greater than zero!')
--   assert(tonumber(msg.Tags.TokenId) % 1 == 0, 'TokenId must be an integer!')
-- end

-- function validation.batchBalance(msg)
--   assert(msg.Tags.Recipients, "Recipients is required!")
--   local recipients = json.decode(msg.Tags.Recipients)
--   assert(msg.Tags.TokenIds, "TokenIds is required!")
--   local tokenIds = json.decode(msg.Tags.TokenIds)
--   assert(#recipients == #tokenIds, "Recipients and TokenIds must have same lengths")
--   for i = 1, #tokenIds do
--     assert(utils.includes(tokenIds[i], CPMM.tokens.positionIds), 'Invalid tokenId!')
--   end
-- end

-- function validation.batchBalances(msg)
--   assert(msg.Tags.TokenIds, "TokenIds is required!")
--   local tokenIds = json.decode(msg.Tags.TokenIds)
--   for i = 1, #tokenIds do
--     assert(utils.includes(tokenIds[i], CPMM.tokens.positionIds), 'Invalid tokenId!')
--   end
-- end

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------

function validation.updateConfigurator(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Configurator, 'Configurator is required!')
end

function validation.updateIncentives(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Incentives, 'Incentives is required!')
end

function validation.updateTakeFee(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.CreatorFee, 'CreatorFee is required!')
  assert(tonumber(msg.Tags.CreatorFee), 'CreatorFee must be a number!')
  assert(tonumber(msg.Tags.CreatorFee) > 0, 'CreatorFee must be greater than zero!')
  assert(tonumber(msg.Tags.CreatorFee) % 1 == 0, 'CreatorFee must be an integer!')
  assert(msg.Tags.ProtocolFee, 'ProtocolFee is required!')
  assert(tonumber(msg.Tags.ProtocolFee), 'ProtocolFee must be a number!')
  assert(tonumber(msg.Tags.ProtocolFee) > 0, 'ProtocolFee must be greater than zero!')
  assert(tonumber(msg.Tags.ProtocolFee) % 1 == 0, 'ProtocolFee must be an integer!')
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Net fee must be less than or equal to 1000 bps')
end

function validation.updateProtocolFeeTarget(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.ProtocolFeeTarget, 'ProtocolFeeTarget is required!')
end

function validation.updateLogo(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')
end

return validation