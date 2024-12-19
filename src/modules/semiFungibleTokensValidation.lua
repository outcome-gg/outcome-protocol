local json = require("json")
local bint = require('.bint')(256)
local utils = require('.utils')
local sharedUtils = require('modules.sharedUtils')

local semiFungibleTokensValidation = {}

local function validateRecipient(recipient)
  assert(type(recipient) == 'string', 'Recipient is required!')
  assert(sharedUtils.isValidArweaveAddress(recipient), 'Recipient must be a valid Arweave address!')
end

local function validateTokenId(tokenId, validTokenIds)
  assert(type(tokenId) == 'string', 'TokenId is required!')
  assert(utils.includes(tokenId, validTokenIds), 'Invalid tokenId!')
end

local function validateQuantity(quantity)
  assert(type(quantity) == 'string', 'Quantity is required!')
  assert(tonumber(quantity), 'Quantity must be a number!')
  assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
end

function semiFungibleTokensValidation.transferSingle(msg, validTokenIds)
  validateRecipient(msg.Tags.Recipient)
  validateTokenId(msg.Tags.TokenId, validTokenIds)
  validateQuantity(msg.Tags.Quantity)
end

function semiFungibleTokensValidation.transferBatch(msg, validTokenIds)
  validateRecipient(msg.Tags.Recipient)
  assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#tokenIds == #quantities, 'Input array lengths must match!')
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateTokenId(tokenIds[i], validTokenIds)
    validateQuantity(quantities[i])
  end
end

function semiFungibleTokensValidation.balanceById(msg, validTokenIds)
  validateTokenId(msg.Tags.TokenId, validTokenIds)
end

function semiFungibleTokensValidation.balancesById(msg, validTokenIds)
  validateTokenId(msg.Tags.TokenId, validTokenIds)
end

function semiFungibleTokensValidation.batchBalance(msg, validTokenIds)
  assert(msg.Tags.Recipients, "Recipients is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Input array lengths must match!")
  assert(#recipients > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateRecipient(recipients[i])
    validateTokenId(tokenIds[i], validTokenIds)
  end
end

function semiFungibleTokensValidation.batchBalances(msg, validTokenIds)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateTokenId(tokenIds[i], validTokenIds)
  end
end

return semiFungibleTokensValidation