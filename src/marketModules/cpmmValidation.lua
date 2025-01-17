--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local cpmmValidation = {}
local sharedValidation = require('marketModules.sharedValidation')
local sharedUtils = require('marketModules.sharedUtils')
local bint = require('.bint')(256)

--- Validates add funding
--- @param msg Message The message to be validated
function cpmmValidation.addFunding(msg)
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
  assert(sharedUtils.isJSONArray(msg.Tags['X-Distribution']), 'X-Distribution must be valid JSON Array!')
  -- @dev TODO: remove requirement for X-Distribution
end

--- Validates remove funding
--- @param msg Message The message to be validated
function cpmmValidation.removeFunding(msg)
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates buy
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.buy(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates sell
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.sell(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  sharedValidation.validatePositiveInteger(msg.Tags.MaxOutcomeTokensToSell, "MaxOutcomeTokensToSell")
end

--- Validates calc buy amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcBuyAmount(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

--- Validates calc sell amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcSellAmount(msg, validPositionIds)
  sharedValidation.validateItem(msg.Tags.PositionId, validPositionIds, "PositionId")
  sharedValidation.validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

--- Validates update configurator
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateConfigurator(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.Configurator, 'Configurator')
end

--- Validates update incentives
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.Incentives, 'Incentives')
end

--- Validates update take fee
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateTakeFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, 'CreatorFee')
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, 'ProtocolFee')
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Net fee must be less than or equal to 1000 bps')
end

--- Validates update protocol fee target
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateProtocolFeeTarget(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.ProtocolFeeTarget, 'ProtocolFeeTarget is required!')
end

--- Validates update logo
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateLogo(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')
end

return cpmmValidation