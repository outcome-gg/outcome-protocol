--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

local bint = require('.bint')(256)
local json = require('json')
local predToken = require('predTokenModules.predToken')

--[[
=========
PRED TOKEN
=========
]]

Name = "Outcome XP"
Ticker = "PRED"
Logo = "jbQ1I_WwOIqKOnRzoOToCUwpWVgO7v7retNGjkxWyKA"
Denomination = 10
EmissionStart = os.time()
Env = 'DEV'

-- @dev Reset state while in DEV mode
if not PredToken or Env == 'DEV' then
  PredToken = predToken.new(
    Name,
    Ticker,
    Logo,
    {}, -- balances,
    "0", -- totalSupply
    Denomination
  )
end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message to handle
--- @return Message The info message
Handlers.add("Info", {Action = "Info"}, function(msg)
  return msg.reply({
    Name = Name,
    Ticker = Ticker,
    Logo = Logo,
    Denomination = tostring(Denomination)
  })
end)

--[[
==============
WRITE HANDLERS
==============
]]

-- Claim
Handlers.add("Claim", {Action = "Claim"}, function(msg)
  PredToken:claim(msg.From, msg.Tags.Cast, msg)
end)

-- Transfer
Handlers.add("Transfer", {Action = "Transfer"}, function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  PredToken:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

--- Burn
Handlers.add("Burn", {Action = "Burn"}, function(msg)
  PredToken:burn(msg.From, msg.Tags.Quantity, msg)
end)

--[[
=============
READ HANDLERS
=============
]]

-- Balance
Handlers.add("Balance", {Action = "Balance"}, function(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient) then
    if (PredToken.token.balances[msg.Tags.Recipient]) then
      bal = PredToken.token.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and PredToken.token.balances[msg.Tags.Target] then
    bal = PredToken.token.balances[msg.Tags.Target]
  elseif PredToken.token.balances[msg.From] then
    bal = PredToken.token.balances[msg.From]
  end

  msg.reply({
    Balance = bal,
    Ticker = PredToken.token.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances
Handlers.add("Balances", {Action = "Balances"}, function(msg)
  msg.reply({ Data = json.encode(PredToken.token.balances) })
end)

-- Total Supply
Handlers.add("Total-Supply", {Action = "Total-Supply"}, function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  msg.reply({
    Action = 'Total-Supply',
    Data = PredToken.token.totalSupply,
    Ticker = PredToken.ticker
  })
end)

-- Last Claim
Handlers.add("Last-Claim", {Action = "Last-Claim"}, function(msg)
  PredToken:lastClaim(msg)
end)
