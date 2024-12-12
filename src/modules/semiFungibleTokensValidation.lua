local json = require("json")
local bint = require('.bint')(256)
local utils = require('.utils')
local sharedUtils = require('modules.sharedUtils')

local semiFunctionalTokensValidation = {}

local function validateRecipient(recipient)
  assert(type(recipient) == 'string', 'Recipient is required!')
  assert(sharedUtils.isValidArweaveAddress(recipient), 'Recipient must be a valid Arweave address!')
end

local function validateTokenId(tokenId)
  assert(type(tokenId) == 'string', 'TokenId is required!')
  assert(utils.includes(tokenId, CPMM.tokens.positionIds), 'Invalid tokenId!')
end

local function validateQuantity(quantity)
  assert(type(quantity) == 'string', 'Quantity is required!')
  assert(tonumber(quantity), 'Quantity must be a number!')
  assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
end

function semiFunctionalTokensValidation.transferSingle(msg)
  validateRecipient(msg.Tags.Recipient)
  validateTokenId(msg.Tags.TokenId)
  validateQuantity(msg.Tags.Quantity)
end

function semiFunctionalTokensValidation.transferBatch(msg)
  validateRecipient(msg.Tags.Recipient)
  assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
  local quantities = json.decode(msg.Tags.Quantities)
  assert(#tokenIds == #quantities, 'Input array lengths must match!')
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateTokenId(tokenIds[i])
    validateQuantity(quantities[i])
  end
end

function semiFunctionalTokensValidation.balanceById(msg)
  validateTokenId(msg.Tags.TokenId)
end

function semiFunctionalTokensValidation.balancesById(msg)
  validateTokenId(msg.Tags.TokenId)
end

function semiFunctionalTokensValidation.batchBalance(msg)
  assert(msg.Tags.Recipients, "Recipients is required!")
  local recipients = json.decode(msg.Tags.Recipients)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#recipients == #tokenIds, "Input array lengths must match!")
  assert(#recipients > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateRecipient(recipients[i])
    validateTokenId(tokenIds[i])
  end
end

function semiFunctionalTokensValidation.batchBalances(msg)
  assert(msg.Tags.TokenIds, "TokenIds is required!")
  local tokenIds = json.decode(msg.Tags.TokenIds)
  assert(#tokenIds > 0, "Input array length must be greater than zero!")
  for i = 1, #tokenIds do
    validateTokenId(tokenIds[i])
  end
end

return semiFunctionalTokensValidation