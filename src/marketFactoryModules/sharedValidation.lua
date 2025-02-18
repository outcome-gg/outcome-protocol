--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local sharedValidation = {}
local sharedUtils = require('marketFactoryModules.sharedUtils')
local utils = require('.utils')

--- Validates address
--- @param address any The address to be validated
--- @param tagName string The name of the tag being validated
function sharedValidation.validateAddress(address, tagName)
  assert(type(address) == 'string', tagName .. ' is required!')
  assert(sharedUtils.isValidArweaveAddress(address), tagName .. ' must be a valid Arweave address!')
end

--- Validates array item
--- @param item any The item to be validated
--- @param validItems table<string> The array of valid items
--- @param tagName string The name of the tag being validated
function sharedValidation.validateItem(item, validItems, tagName)
  assert(type(item) == 'string', tagName .. ' is required!')
  assert(utils.includes(item, validItems), 'Invalid ' .. tagName .. '!')
end

--- Validates positive integer
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
function sharedValidation.validatePositiveInteger(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

--- Validates positive integer or zero
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
function sharedValidation.validatePositiveIntegerOrZero(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) >= 0, tagName .. ' must be greater than or equal to zero!')
  assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
end

--- Validates positive number
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
function sharedValidation.validatePositiveNumber(quantity, tagName)
  assert(type(quantity) == 'string', tagName .. ' is required!')
  assert(tonumber(quantity), tagName .. ' must be a number!')
  assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
end

return sharedValidation