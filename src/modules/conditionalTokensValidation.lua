local sharedUtils = require('modules.sharedUtils')
local json = require('json')
local conditionalTokensValidation = {}

local function validateQuantity(quantity)
  assert(type(quantity) == 'string', 'Quantity is required!')
  assert(tonumber(quantity), 'Quantity must be a number!')
  assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
  assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
end

local function validatePayouts(payouts)
  assert(payouts, "Payouts is required!")
  assert(sharedUtils.isJSONArray(payouts), "Payouts must be valid JSON Array!")
  for _, payout in ipairs(json.decode(payouts)) do
    assert(tonumber(payout), "Payouts item must be a number!")
  end
end

function conditionalTokensValidation.mergePositions(msg)
  validateQuantity(msg.Tags.Quantity)
end

function conditionalTokensValidation.reportPayouts(msg)
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  validatePayouts(msg.Tags.Payouts)
end

return conditionalTokensValidation