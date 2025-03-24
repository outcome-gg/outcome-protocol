--[[
================================================================================
Module: token.lua
Adapted from the AO Cookbook Token Blueprint:
https://cookbook_ao.g8way.io/guides/aos/blueprints/token.html
Licensed under the Business Source License 1.1 (BSL 1.1)
================================================================================

Licensor:          Forward Research
Licensed Work:     aos codebase. The Licensed Work is (c) 2024 Forward Research
Official License:  https://github.com/permaweb/aos/blob/main/LICENSE
Additional Use Grant:
  The aos codebases are offered under the BSL 1.1 license for the duration
  of the testnet period. After the testnet phase is over, the code will be
  made available under either a new evolutionary forking license or a
  traditional OSS license (GPLv3/v2, MIT, etc).
  More info: https://arweave.medium.com/arweave-is-an-evolutionary-protocol-e072f5e69eaa
Change Date:       Four years from the date the Licensed Work is published.
Change License:    MPL 2.0

Notice:
This code is provided under the Business Source License 1.1. Redistribution,
modification, or unauthorized use of this code must comply with the terms of
the Business Source License.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
================================================================================
]]

local Token = {}
local TokenMethods = {}
local TokenNotices = require('marketModules.tokenNotices')
local bint = require('.bint')(256)
local sharedUtils = require("marketModules.sharedUtils")

--- Represents a Token
--- @class Token
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logo string The token logo Arweave TxID
--- @field balances table<string, string> The user token balances
--- @field totalSupply string The total supply of the token
--- @field denomination number The number of decimals

--- Creates a new Token instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logo string The token logo Arweave TxID
--- @param balances table<string, string> The user token balances
--- @param totalSupply string The total supply of the token
--- @param denomination number The number of decimals
--- @return Token token The new Token instance
function Token.new(name, ticker, logo, balances, totalSupply, denomination)
  local token = {
    name = name,
    ticker = ticker,
    logo = logo,
    balances = balances,
    totalSupply = totalSupply,
    denomination = denomination
  }
  setmetatable(token, {
    __index = function(_, k)
      if TokenMethods[k] then
        return TokenMethods[k]
      elseif TokenNotices[k] then
        return TokenNotices[k]
      else
        return nil
      end
    end
  })
  return token
end

--- Mint a quantity of tokens
--- @param to string The address that will own the minted tokens
--- @param quantity string The quantity of tokens to mint
--- @param cast boolean The cast is set to true to silence the notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The mint notice if not cast
function TokenMethods:mint(to, quantity, cast, detached, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- Mint tokens
  if not self.balances[to] then self.balances[to] = '0' end
  self.balances[to] = sharedUtils.safeAdd(self.balances[to], quantity)
  self.totalSupply = sharedUtils.safeAdd(self.totalSupply, quantity)
  -- Send notice
  if not cast then return self.mintNotice(to, quantity, detached, msg) end
end

--- Burn a quantity of tokens
--- @param from string The process ID that will no longer own the burned tokens
--- @param quantity string The quantity of tokens to burn
--- @param cast boolean The cast is set to true to silence the notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The burn notice if not cast
function TokenMethods:burn(from, quantity, cast, detached, msg)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balances[from], 'Must have token balance!')
  assert(bint.__le(bint(quantity), self.balances[from]), 'Must have sufficient tokens!')
  -- Burn tokens
  self.balances[from] = sharedUtils.safeSub(self.balances[from], quantity)
  self.totalSupply = sharedUtils.safeSub(self.totalSupply, quantity)
  -- Send notice
  if not cast then return self.burnNotice(quantity, detached, msg) end
end

--- Transfer a quantity of tokens
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function TokenMethods:transfer(from, recipient, quantity, cast, detached, msg)
  assert(from ~= recipient, "Recipient must be different from sender!")
  assert(bint.__lt(0, bint(quantity)), "Quantity must be greater than zero!")

  if not self.balances[from] then self.balances[from] = "0" end
  if not self.balances[recipient] then self.balances[recipient] = "0" end

  local balance = self.balances[from]

  if bint.__le(bint(quantity), bint(balance)) then
    self.balances[from] = sharedUtils.safeSub(balance, quantity)
    self.balances[recipient] = sharedUtils.safeAdd(self.balances[recipient], quantity)

    -- Only send the notifications to the Sender and Recipient
    -- if the Cast tag is not set on the Transfer message
    if not cast then
      -- Debit-Notice message template, that is sent to the Sender of the transfer
      local debitNotice = {
        Action = 'Debit-Notice',
        Recipient = recipient,
        Quantity = quantity,
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. quantity .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
      }
      -- Credit-Notice message template, that is sent to the Recipient of the transfer
      local creditNotice = {
        Action = 'Credit-Notice',
        Sender = from,
        Quantity = quantity,
        Data = Colors.gray ..
            "You received " ..
            Colors.blue .. quantity .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
      }

      -- Add forwarded tags to the credit and debit notice messages
      for tagName, tagValue in pairs(msg.Tags) do
        -- Tags beginning with "X-" are forwarded
        if string.sub(tagName, 1, 2) == "X-" then
          debitNotice[tagName] = tagValue
          creditNotice[tagName] = tagValue
        end
      end

      -- Send Debit-Notice and Credit-Notice
      return self.transferNotices(debitNotice, creditNotice, recipient, detached, msg)
    end
  else
    return self.transferErrorNotice(msg)
  end
end

return Token
