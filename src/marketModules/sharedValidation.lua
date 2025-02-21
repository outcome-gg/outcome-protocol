--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local sharedValidation = {}
local sharedUtils = require('marketModules.sharedUtils')
local utils = require('.utils')

--- Validates address
--- @param address any The address to be validated
--- @param tagName string The name of the tag being validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validateAddress(address, tagName)
  if type(address) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end
  if not sharedUtils.isValidArweaveAddress(address) then
    return false, tagName .. ' must be a valid Arweave address!'
  end
  return true
end

--- Validates array item
--- @param item any The item to be validated
--- @param validItems table<string> The array of valid items
--- @param tagName string The name of the tag being validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validateItem(item, validItems, tagName)
  if type(item) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end
  if not utils.includes(item, validItems) then
    return false, 'Invalid ' .. tagName .. '!'
  end
  return true
end

--- Validates positive integer
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validatePositiveInteger(quantity, tagName)
  if type(quantity) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end

  local num = tonumber(quantity)
  if not num then
    return false, tagName .. ' must be a valid number!'
  end
  if num <= 0 then
    return false, tagName .. ' must be greater than zero!'
  end
  if num % 1 ~= 0 then
    return false, tagName .. ' must be an integer!'
  end

  return true
end

--- Validates positive integer or zero
--- @param quantity any The quantity to be validated
--- @param tagName string The name of the tag being validated
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function sharedValidation.validatePositiveIntegerOrZero(quantity, tagName)
  if type(quantity) ~= 'string' then
    return false, tagName .. ' is required and must be a string!'
  end

  local num = tonumber(quantity)
  if not num then
    return false, tagName .. ' must be a valid number!'
  end
  if num < 0 then
    return false, tagName .. ' must be greater than or equal to zero!'
  end
  if num % 1 ~= 0 then
    return false, tagName .. ' must be an integer!'
  end

  return true
end

return sharedValidation
