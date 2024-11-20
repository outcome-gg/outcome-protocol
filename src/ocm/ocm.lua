local bint = require('.bint')(256)
local ao = require('.ao')
local json = require('json')
local config = require('modules.config')
local ocm = require('ocm')

---------------------------------------------------------------------------------
-- OCM --------------------------------------------------------------------------
---------------------------------------------------------------------------------
if not OCM or config.ResetState then OCM = ocm:new() end

-- @dev Link expected namespace variables
Name = OCM.token.name
Ticker = OCM.token.ticker
Logo = OCM.token.logo
Balances = OCM.token.balances
TotalSupply = OCM.token.totalSupply
Denomination = OCM.token.denomination

---------------------------------------------------------------------------------
-- CORE HANDLERS ----------------------------------------------------------------
---------------------------------------------------------------------------------
-- Balance
Handlers.add('Balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (OCM.token.balances[msg.Tags.Recipient]) then
      bal = OCM.token.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and OCM.token.balances[msg.Tags.Target] then
    bal = OCM.token.balances[msg.Tags.Target]
  elseif OCM.token.balances[msg.From] then
    bal = OCM.token.balances[msg.From]
  end

  msg.reply({
    Balance = bal,
    Ticker = OCM.token.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances
Handlers.add('Balances', Handlers.utils.hasMatchingTag('Action', 'Balances'),
  function(msg) msg.reply({ Data = json.encode(OCM.token.balances) })
end)

-- Transfer
Handlers.add('Transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  OCM:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

-- Total Supply
Handlers.add('Total-Supply', Handlers.utils.hasMatchingTag('Action', 'Total-Supply'), function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  msg.reply({
    Action = 'Total-Supply',
    Data = OCM.token.totalSupply,
    Ticker = OCM.ticker
  })
end)