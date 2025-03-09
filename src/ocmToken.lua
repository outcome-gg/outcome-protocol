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
-- local ao = require('.ao') -- @dev required for unit tests?
local json = require('json')
local ocmToken = require('ocmTokenModules.ocmToken')

--[[
=========
OCM TOKEN
=========
]]

Name = "Outcome Token"
Ticker = "OCM"
Logo = "" -- @dev TODO
Denomination = 12
MaximumSupply = "1000000000000000000000"
MonthlyEmissionRate = 0.01425 -- same as AO
EmissionStart = os.time()
Env = 'DEV'

-- @dev Reset state while in DEV mode
if not OcmToken or Env == 'DEV' then
  OcmToken = ocmToken.new(
    Name,
    Ticker,
    Logo,
    {}, -- balances,
    "0", -- totalSupply
    Denomination,
    MaximumSupply,
    MonthlyEmissionRate,
    EmissionStart
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
    Denomination = tostring(Denomination),
    MaximumSupply = MaximumSupply,
  })
end)

--[[
==============
WRITE HANDLERS
==============
]]

-- Claim
Handlers.add("Claim", {Action = "Claim"}, function(msg)
  OcmToken:claim(msg.From, msg.Tags.OnBehalfOf, msg)
end)

-- Transfer
Handlers.add("Transfer", {Action = "Transfer"}, function(msg)
  assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than 0')
  OcmToken:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg.Tags, msg.Id)
end)

--- Burn
Handlers.add("Burn", {Action = "Burn"}, function(msg)
  OcmToken:burn(msg.From, msg.Tags.Quantity, msg)
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
    if (OcmToken.token.balances[msg.Tags.Recipient]) then
      bal = OcmToken.token.balances[msg.Tags.Recipient]
    end
  elseif msg.Tags.Target and OcmToken.token.balances[msg.Tags.Target] then
    bal = OcmToken.token.balances[msg.Tags.Target]
  elseif OcmToken.token.balances[msg.From] then
    bal = OcmToken.token.balances[msg.From]
  end

  msg.reply({
    Balance = bal,
    Ticker = OcmToken.token.ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end)

-- Balances
Handlers.add("Balances", {Action = "Balances"}, function(msg)
  msg.reply({ Data = json.encode(OcmToken.token.balances) })
end)

-- Total Supply
Handlers.add("Total-Supply", {Action = "Total-Supply"}, function(msg)
  assert(msg.From ~= ao.id, 'Cannot call Total-Supply from the same process!')

  msg.reply({
    Action = 'Total-Supply',
    Data = OcmToken.token.totalSupply,
    Ticker = OcmToken.ticker
  })
end)

-- Claim Balance
Handlers.add("Claim-Balance", {Action = "Claim-Balance"}, function(msg)
  OcmToken:claimBalance(msg)
end)

-- Claim Balances
Handlers.add("Claim-Balances", {Action = "Claim-Balances"}, function(msg)
  OcmToken:claimBalances(msg)
end)

--[[
=====================
CONFIGURATOR HANDLERS
=====================
]]

Handlers.add("Update-Configurator", {Action = "Update-Configurator"}, function(msg)
  assert(msg.From == OcmToken.incentives.configurator, 'Sender must be configurator!')
  assert(type(msg.Tags.Configurator) == 'string', 'Configurator is required!')
  OcmToken:updateConfigurator(msg.Tags.Configurator, msg)
end)

Handlers.add("Update-LP-To-Holder-Ratio", {Action = "Update-LP-To-Holder-Ratio"}, function(msg)
  assert(msg.From == OcmToken.incentives.configurator, 'Sender must be configurator!')
  assert(type(msg.Tags.Ratio) == 'string', 'Ratio is required!')
  OcmToken.incentives:updateLpToHolderRatio(msg.Tags.Ratio, msg)
end)

Handlers.add("Update-Collateral-Prices", {Action = "Update-Collateral-Prices"}, function(msg)
  assert(msg.From == OcmToken.incentives.configurator, 'Sender must be configurator!')
  assert(type(msg.Tags.CollateralPrices) == 'string', 'CollateralPrices is required!')
  -- TODO validate table
  local collateralPrices = json.decode(msg.Tags.CollateralPrices)
  OcmToken.incentives:updateCollateralPrices(collateralPrices, msg)
end)

Handlers.add("Update-Collateral-Factors", {Action = "Update-Collateral-Factors"}, function(msg)
  assert(msg.From == OcmToken.incentives.configurator, 'Sender must be configurator!')
  assert(type(msg.Tags.CollateralFactors) == 'string', 'CollateralFactors is required!')
  -- TODO validate table
  local collateralFactors = json.decode(msg.Tags.CollateralFactors)
  OcmToken.incentives:updateCollateralFactors(collateralFactors, msg)
end)

Handlers.add("Update-Collateral-Denominations", {Action = "Update-Collateral-Denominations"}, function(msg)
  assert(msg.From == OcmToken.incentives.configurator, 'Sender must be configurator!')
  assert(type(msg.Tags.CollateralDenominations) == 'string', 'CollateralDenominations is required!')
  -- TODO validate table
  local collateralDenominations = json.decode(msg.Tags.CollateralDenominations)
  OcmToken.incentives:updateCollateralDenominations(collateralDenominations, msg)
end)

--[[
============
CRON HANDLER
============
]]
Handlers.add("Cron", {Action = "Cron"}, function(msg)
  OcmToken:tokenEmission(msg)
end)