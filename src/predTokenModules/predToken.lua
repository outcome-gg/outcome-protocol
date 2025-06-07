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
https://outcome.gg/terms
======================================================================================
]]

local PredToken = {}
local PredTokenMethods = {}
local PredTokenNotices = require('predTokenModules.predTokenNotices')
local token = require("predTokenModules.token")

-- Constants for time calculations
local SECONDS_PER_DAY = 86400  -- Number of seconds in a day
local MS_PER_DAY = SECONDS_PER_DAY * 1000  -- Number of milliseconds in a day

-- Function to get day count from epoch
local function getDayCountFromTimestamp(timestamp_ms)
  return tostring(math.floor(timestamp_ms / MS_PER_DAY))
end

--- Represents an PRED Token
--- @class PredToken
--- @field token Token The token

--- Creates a new PRED Token instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logo string The token logo Arweave TxID
--- @param balances table<string, string> The user token balances
--- @param totalSupply string The total supply of the token
--- @param denomination number The number of decimals
--- @return Token token The new Token instance
function PredToken.new(name, ticker, logo, balances, totalSupply, denomination)
  local predToken = {
    token = token.new(name, ticker, logo, balances, totalSupply, denomination),
    lastClaims = {}
  }
  setmetatable(predToken, {
    __index = function(_, k)
      if PredTokenMethods[k] then
        return PredTokenMethods[k]
      elseif PredTokenNotices[k] then
        return PredTokenNotices[k]
      else
        return nil
      end
    end
  })
  return predToken
end

--[[
=============
WRITE METHODS
=============
]]

--- Claim rewards
--- @param from string The address that will claim the rewards
--- @param cast boolean The cast is set to true to silence the notice
--- @param msg Message The message received
--- @return Message|nil The claim notice if cast
function PredTokenMethods:claim(from, cast, msg)
  -- Check user exists
  if not self.lastClaims[msg.From] then self.lastClaims[msg.From] = "0" end
  -- Check if use has already claimed today
  local dayCount = getDayCountFromTimestamp(msg.Timestamp)
  if (dayCount == self.lastClaims[msg.From]) then
    ao.send({
      Target = msg.From,
      Data = "You have already claimed your tokens today."
    })
    return
  end
  -- Set the last claim time
  self.lastClaims[from] = dayCount
  -- Mint tokens
  local quantity = "10000000000000" -- 10^13 to represent 1000 PRED with 10 decimals
  self.token:mint(from, quantity, true, msg) -- true to detach the mint notice
  -- Send notice
  if not cast then return self.claimNotice(quantity, msg) end
end

--- Transfer a quantity of tokens
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function PredTokenMethods:transfer(from, recipient, quantity, cast, msg)
  return self.token:transfer(from, recipient, quantity, cast, msg)
end

--- Burn a quantity of tokens
--- @param from string The process ID that will no longer own the burned tokens
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @return Message The burn notice
function PredTokenMethods:burn(from, quantity, msg)
  assert(msg.From == ao.id, 'Only the owner can burn tokens!')
  return self.token:burn(from, quantity, msg)
end

--[[
============
READ METHODS
============
]]

--- Last Claim
--- @param msg Message The message to handle
--- @return Message The last claim message
function PredTokenMethods:lastClaim(msg)
  local lastClaim = self.lastClaims[msg.From] or "0"
  return msg.reply({Data = lastClaim})
end

return PredToken