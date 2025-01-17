--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local OcmToken = {}
local OcmTokenMethods = {}
local OcmTokenNotices = require('ocmTokenModules.ocmTokenNotices')
local incentives = require("ocmTokenModules.incentives")
local token = require("ocmTokenModules.token")
local bint = require('.bint')(256)
local json = require("json")

--- Represents an OCM Token
--- @class OcmToken
--- @field token Token The token
--- @field emissionStart number The token emission start timestamp
--- @field emissionInterval number The token emission interval in seconds
--- @field monthlyEmissionRate string The token monthly emission rate
--- @field mintedSupply string The token minted supply
--- @field lastEmission number The token last emission timestamp

--- Creates a new OCM Token instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logo string The token logo Arweave TxID
--- @param balances table<string, string> The user token balances
--- @param totalSupply string The total supply of the token
--- @param denomination number The number of decimals
--- @param maximumSupply string The maximum supply of the token
--- @param monthlyEmissionRate number The percentage of remaining tokens to distribute monthly
--- @param emissionStart number The timestamp from when to start emissions
--- @return Token token The new Token instance
function OcmToken:new(name, ticker, logo, balances, totalSupply, denomination, maximumSupply, monthlyEmissionRate, emissionStart)
  local ocmToken = {
    token = token:new(name, ticker, logo, balances, totalSupply, denomination),
    incentives = incentives:new(),
    claimBalances = {},
    maximumSupply = maximumSupply,
    monthlyEmissionRate = monthlyEmissionRate,
    emissionStart = emissionStart,
    lastEmission = nil,
  }
  setmetatable(ocmToken, {
    __index = function(_, k)
      if OcmTokenMethods[k] then
        return OcmTokenMethods[k]
      elseif OcmTokenNotices[k] then
        return OcmTokenNotices[k]
      else
        return nil
      end
    end
  })
  return ocmToken
end

--[[
=============
WRITE METHODS
=============
]]

--- Claim rewards
--- @param from string The address that will claim the rewards
--- @param onBehalfOf string The address that will claim the rewards on behalf of the user
--- @param msg Message The message received
--- @return Message The claim notice
function OcmTokenMethods:claim(from, onBehalfOf, msg)
  onBehalfOf = onBehalfOf or from
  assert(self.claimBalances[from], 'No rewards to claim!')
  -- retrieve rewards
  local quantity = self.claimBalances[from]
  -- transfer rewards
  self:transfer(ao.id, onBehalfOf, quantity, false, msg)
  -- reset claim balance
  self.claimBalances[from] = "0"
  -- send notice
  return self.claimNotice(quantity, onBehalfOf, msg)
end

--- Transfer a quantity of tokens
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token 
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function OcmTokenMethods:transfer(from, recipient, quantity, cast, msg)
  return self.token:transfer(from, recipient, quantity, cast, msg)
end

--- Burn a quantity of tokens
--- @param from string The process ID that will no longer own the burned tokens
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @return Message The burn notice
function OcmTokenMethods:burn(from, quantity, msg)
  return self.token:burn(from, quantity, msg)
end

--[[
============
READ METHODS
============
]]

--- Claim Balance
--- @param msg Message The message to handle
--- @return Message The claim balance message
function OcmTokenMethods:claimBalance(msg)
  local recipient = msg.Tags.Recipient or msg.From
  local bal = self.claimBalances[recipient] or "0"
  return msg.reply({ClaimBalance = bal, Account = recipient, Data = bal})
end

--- Claim Balances
--- @param msg Message The message to handle
--- @return Message The claim balances message
function OcmTokenMethods:claimBalances(msg)
  return msg.reply({Data = json.encode(self.claimBalances)})
end

--[[
============
CRON METHODS
============
]]

--- Emission
--- @param msg Message The message received
--- @return Message mintNotice The mint notice
function OcmTokenMethods:emission(msg)
  assert(os.time() >= self.emissionStart, 'Emission has not started yet!')
  -- calculate mint amount
  local intervalLength = self.lastEmission and os.time() - self.lastEmission or os.time() - self.emissionStart
  local secondsInMonth = 30 * 24 * 60 * 60
  local intervalEmissionRate = self.monthlyEmissionRate * intervalLength / secondsInMonth
  local remainingSupply = tostring(bint.__sub(self.maximumSupply, self.mintedSupply))
  local mintAmount = tostring(bint.__mul(bint(remainingSupply), intervalEmissionRate))
  -- update last emission timestamp
  self.lastEmission = os.time()
  -- mint tokens to self
  self.token:mint(ao.id, mintAmount, msg)
  -- calculate rewards
  local fundingRewards, predictionRewards = self.incentives:calcRewards(mintAmount)
  -- update claim balances
  for user, reward in ipairs(fundingRewards) do
    if not self.claimBalances[user] then self.claimBalances[user] = "0" end
    self.claimBalances[user] = tostring(bint.__add(self.claimBalances[user], reward))
  end
  for user, reward in ipairs(predictionRewards) do
    if not self.claimBalances[user] then self.claimBalances[user] = "0" end
    self.claimBalances[user] = tostring(bint.__add(self.claimBalances[user], reward))
  end
  -- send notice
  return self.emissionNotice(msg)
end

return OcmToken