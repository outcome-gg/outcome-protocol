--[[
================================================================================
Based on the AO Cookbook Token Blueprint:
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
local TokenMethods = require('modules.tokenNotices')
local TokenNotices = require('modules.tokenNotices')
local bint = require('.bint')(256)

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
function Token:new(name, ticker, logo, balances, totalSupply, denomination)
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
--- @param msg Message The message received
--- @return Message The mint notice
function TokenMethods:mint(to, quantity, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- Mint tokens
  if not self.balances[to] then self.balances[to] = '0' end
  self.balances[to] = tostring(bint.__add(bint(self.balances[to]), bint(quantity)))
  self.totalSupply = tostring(bint.__add(bint(self.totalSupply), bint(quantity)))
  -- Send notice
  return self.mintNotice(to, quantity, msg)
end

--- Burn a quantity of tokens
--- @param from string The process ID that will no longer own the burned tokens
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @return Message The burn notice
function TokenMethods:burn(from, quantity, msg)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balances[from], 'Must have token balance!')
  assert(bint.__le(bint(quantity), self.balances[from]), 'Must have sufficient tokens!')
  -- Burn tokens
  self.balances[from] = tostring(bint.__sub(self.balances[from], bint(quantity)))
  self.totalSupply = tostring(bint.__sub(bint(self.totalSupply), bint(quantity)))
  -- Send notice
  return self.burnNotice(quantity, msg)
end

--- Transfer a quantity of tokens
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token 
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function TokenMethods:transfer(from, recipient, quantity, cast, msg)
  if not self.balances[from] then self.balances[from] = "0" end
  if not self.balances[recipient] then self.balances[recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balances[from])

  if bint.__le(qty, balance) then
    self.balances[from] = tostring(bint.__sub(balance, qty))
    self.balances[recipient] = tostring(bint.__add(self.balances[recipient], qty))

    -- Only send the notifications to the Sender and Recipient
    -- if the Cast tag is not set on the Transfer message
    if not cast then
      -- Debit-Notice message template, that is sent to the Sender of the transfer
      local debitNotice = {
        Target = from,
        Action = 'Debit-Notice',
        Recipient = recipient,
        Quantity = quantity,
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. quantity .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
      }
      -- Credit-Notice message template, that is sent to the Recipient of the transfer
      local creditNotice = {
        Target = recipient,
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
      return self.transferNotices(debitNotice, creditNotice, msg)
    end
  else
    return self.transferErrorNotice(msg)
  end
end

return Token
