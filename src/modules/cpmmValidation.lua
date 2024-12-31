--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

local bint = require('.bint')(256)
local utils = require('.utils')
local sharedUtils = require('modules.sharedUtils')
local json = require("json")
local cpmmValidation = {}

--- Validates address
--- @param address any The address to be validated
--- @param tagName string The name of the tag being validated
local function validateAddress(address, tagName)
  assert(type(address) == 'string', tagName .. ' is required!')
  assert(sharedUtils.isValidArweaveAddress(address), tagName .. ' must be a valid Arweave address!')
end

--- Validates position ID
--- @param positionId any The position ID to be validated
--- @param validPositionIds table<string> The array of valid position IDs
local function validatePositionId(positionId, validPositionIds)
  assert(type(positionId) == 'string', 'PositionId is required!')
  assert(utils.includes(positionId, validPositionIds), 'Invalid positionId!')
end

--- Validates positive integer
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
local function validatePositiveInteger(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

--- Validates positive integer or zero
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
local function validatePositiveIntegerOrZero(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) >= 0, tagName .. ' must be greater than or equal to zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

--- Validates add funding
--- @param msg Message The message to be validated
function cpmmValidation.addFunding(msg)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
  assert(sharedUtils.isJSONArray(msg.Tags['X-Distribution']), 'X-Distribution must be valid JSON Array!')
  -- @dev TODO: remove requirement for X-Distribution
end

--- Validates remove funding
--- @param msg Message The message to be validated
function cpmmValidation.removeFunding(msg)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates buy
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.buy(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validates sell
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.sell(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  validatePositiveInteger(msg.Tags.MaxOutcomeTokensToSell, "MaxOutcomeTokensToSell")
end

--- Validates calc buy amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcBuyAmount(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
end

--- Validates calc sell amount
--- @param msg Message The message to be validated
--- @param validPositionIds table<string> The array of valid position IDs
function cpmmValidation.calcSellAmount(msg, validPositionIds)
  validatePositionId(msg.Tags.PositionId, validPositionIds)
  validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
end

--- Validates update configurator
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateConfigurator(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  validateAddress(msg.Tags.Configurator, 'Configurator')
end

--- Validates update incentives
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  validateAddress(msg.Tags.Incentives, 'Incentives')
end

--- Validates update take fee
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function cpmmValidation.updateTakeFee(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  validatePositiveIntegerOrZero(msg.Tags.CreatorFee, 'CreatorFee')
  validatePositiveIntegerOrZero(msg.Tags.ProtocolFee, 'ProtocolFee')
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