--[[
==============================================================================
Outcome © 2025. MIT License.
Module: semiFungibleTokens.lua
==============================================================================
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
==============================================================================
]]

local SemiFungibleTokens = {}
local SemiFungibleTokensMethods = {}
local SemiFungibleTokensNotices = require('marketModules.semiFungibleTokensNotices')
local bint = require('.bint')(256)
local json = require('json')

-- Represents SemiFungibleTokens
--- @class SemiFungibleTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logo string The token logo Arweave TxID
--- @field balancesById table<string, table<string, string>> The account token balances by ID
--- @field totalSupplyById table<string, string> The total supply of the token by ID
--- @field denomination number The number of decimals

--- Creates a new SemiFungibleTokens instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logo string The token logo Arweave TxID
--- @param balancesById table<string, table<string, string>> The account token balances by ID
--- @param totalSupplyById table<string, string> The total supply of the token by ID
--- @param denomination number The number of decimals
--- @return SemiFungibleTokens semiFungibleTokens The new SemiFungibleTokens instance
function SemiFungibleTokens:new(name, ticker, logo, balancesById, totalSupplyById, denomination)
  local semiFungibleTokens = {
    name = name,
    ticker = ticker,
    logo = logo,
    balancesById = balancesById,
    totalSupplyById = totalSupplyById,
    denomination = denomination
  }
  setmetatable(semiFungibleTokens, {
    __index = function(_, k)
      if SemiFungibleTokensMethods[k] then
        return SemiFungibleTokensMethods[k]
      elseif SemiFungibleTokensNotices[k] then
        return SemiFungibleTokensNotices[k]
      else
        return nil
      end
    end
  })
  return semiFungibleTokens
end

--- Mint a quantity of tokens with the given ID
--- @param to string The address that will own the minted tokens
--- @param id string The ID of the tokens to mint
--- @param quantity string The quantity of tokens to mint
--- @param msg Message The message received
--- @return Message The mint notice
function SemiFungibleTokensMethods:mint(to, id, quantity, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- mint tokens
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][to] then self.balancesById[id][to] = "0" end
  if not self.totalSupplyById[id] then self.totalSupplyById[id] = "0" end
  self.balancesById[id][to] = tostring(bint.__add(self.balancesById[id][to], bint(quantity)))
  self.totalSupplyById[id] = tostring(bint.__add(self.totalSupplyById[id], bint(quantity)))
  -- send notice
  return self.mintSingleNotice(to, id, quantity, msg)
end

--- Batch mint quantities of tokens with the given IDs
--- @param to string The address that will own the minted tokens
--- @param ids table<string> The IDs of the tokens to mint
--- @param quantities table<string> The quantities of tokens to mint
--- @param msg Message The message received
--- @return Message The batch mint notice
function SemiFungibleTokensMethods:batchMint(to, ids, quantities, msg)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  -- mint tokens
  for i = 1, #ids do
    -- @dev spacing to resolve text to code eval issue
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][to] then self.balancesById[ ids[i] ][to] = "0" end
    if not self.totalSupplyById[ ids[i] ] then self.totalSupplyById[ ids[i] ] = "0" end
    self.balancesById[ ids[i] ][to] = tostring(bint.__add(self.balancesById[ ids[i] ][to], quantities[i]))
    self.totalSupplyById[ ids[i] ] = tostring(bint.__add(self.totalSupplyById[ ids[i] ], quantities[i]))
  end
  -- send notice
  return self.mintBatchNotice(to, ids, quantities, msg)
end

--- Burn a quantity of tokens with a given ID
--- @param from string The process ID that will no longer own the burned tokens
--- @param id string The ID of the tokens to burn
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The burn notice
function SemiFungibleTokensMethods:burn(from, id, quantity, msg, useReply)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balancesById[id], 'Id must exist! ' .. id)
  assert(self.balancesById[id][from], 'Account must hold token! :: ' .. id)
  assert(bint.__le(bint(quantity), self.balancesById[id][from]), 'Account must have sufficient tokens! ' .. id)
  -- burn tokens
  self.balancesById[id][from] = tostring(bint.__sub(self.balancesById[id][from], bint(quantity)))
  self.totalSupplyById[id] = tostring(bint.__sub(self.totalSupplyById[id], bint(quantity)))
  -- send notice
  return self.burnSingleNotice(from, id, quantity, msg, useReply)
end

--- Batch burn a quantity of tokens with the given IDs
--- @param from string The process ID that will no longer own the burned tokens
--- @param ids table<string> The IDs of the tokens to burn
--- @param quantities table<string> The quantities of tokens to burn
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The batch burn notice
function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, msg, useReply)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  for i = 1, #ids do
    assert(bint.__lt(0, quantities[i]), 'Quantity must be greater than zero!')
    assert(self.balancesById[ ids[i] ], 'Id must exist! ' .. ids[i])
    assert(self.balancesById[ ids[i] ][from], 'Account must hold token! ' .. ids[i])
    assert(bint.__le(quantities[i], self.balancesById[ ids[i] ][from]), 'Account must have sufficient tokens!')
  end
  -- burn tokens
  local remainingBalances = {}
  for i = 1, #ids do
    self.balancesById[ ids[i] ][from] = tostring(bint.__sub(self.balancesById[ ids[i] ][from], quantities[i]))
    self.totalSupplyById[ ids[i] ] = tostring(bint.__sub(self.totalSupplyById[ ids[i] ], quantities[i]))
    remainingBalances[i] = self.balancesById[ ids[i] ][from]
  end
  -- send notice
  return self.burnBatchNotice(from, ids, quantities, remainingBalances, msg, useReply)
end

--- Transfer a quantity of tokens with the given ID
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param id string The ID of the tokens to transfer
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, msg, useReply)
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][from] then self.balancesById[id][from] = "0" end
  if not self.balancesById[id][recipient] then self.balancesById[id][recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balancesById[id][from])
  if bint.__le(qty, balance) then
    self.balancesById[id][from] = tostring(bint.__sub(balance, qty))
    self.balancesById[id][recipient] = tostring(bint.__add(self.balancesById[id][recipient], qty))

    -- Only send the notifications if the cast tag is not set
    if not cast then
      return self.transferSingleNotices(from, recipient, id, quantity, msg, useReply)
    end
  else
    return self.transferErrorNotice(id, msg)
  end
end

--- Batch transfer quantities of tokens with the given IDs
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param ids table<string> The IDs of the tokens to transfer
--- @param quantities table<string> The quantities of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, msg, useReply)
  local ids_ = {}
  local quantities_ = {}

  for i = 1, #ids do
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][from] then self.balancesById[ ids[i] ][from] = "0" end
    if not self.balancesById[ ids[i] ][recipient] then self.balancesById[ ids[i] ][recipient] = "0" end

    local qty = bint(quantities[i])
    local balance = bint(self.balancesById[ ids[i] ][from])

    if bint.__le(qty, balance) then
      self.balancesById[ ids[i] ][from] = tostring(bint.__sub(balance, qty))
      self.balancesById[ ids[i] ][recipient] = tostring(bint.__add(self.balancesById[ ids[i] ][recipient], qty))
      table.insert(ids_, ids[i])
      table.insert(quantities_, quantities[i])
    else
      return self.transferErrorNotice(ids[i], msg)
    end
  end

  -- Only send the notifications if the cast tag is not set
  if not cast and #ids_ > 0 then
    return self.transferBatchNotices(from, recipient, ids_, quantities_, msg, useReply)
  end
end

--- Get account balance of tokens with the given ID
--- @param sender string The process ID of the sender
--- @param recipient string|nil The process ID of the recipient (optional)
--- @param id string The ID of the token
--- @return string The balance of the account for the given ID
function SemiFungibleTokensMethods:getBalance(sender, recipient, id)
  local bal = '0'
  -- If ID is found then continue
  if self.balancesById[id] then
    -- If recipient is not provided, return the senders balance
    if (recipient and self.balancesById[id][recipient]) then
      bal = self.balancesById[id][recipient]
    elseif self.balancesById[id][sender] then
      bal = self.balancesById[id][sender]
    end
  end
  -- return balance
  return bal
end

--- Get accounts' balance of tokens with the given IDs
--- @param recipients table<string> The process IDs of the recipients
--- @param ids table<string> The IDs of the tokens
--- @return table<string> The balances of the recipients for each respective ID
function SemiFungibleTokensMethods:getBatchBalance(recipients, ids)
  assert(#recipients == #ids, 'Recipients and Ids must have same lengths')
  local bals = {}

  for i = 1, #recipients do
    table.insert(bals, '0')
    if self.balancesById[ ids[i] ] then
      if self.balancesById[ ids[i] ][ recipients[i] ] then
        bals[i] = self.balancesById[ ids[i] ][ recipients[i] ]
      end
    end
  end

  return bals
end

--- Get account balances of tokens with the given ID
--- @param id string The ID of the token
--- @return table<string, string> The account balances for the given ID
function SemiFungibleTokensMethods:getBalances(id)
  local bals = {}
  if self.balancesById[id] then
    bals = self.balancesById[id]
  end
  -- return balances
  return bals
end

--- Get accounts' balances of tokens with the given IDs
--- @param positionIds table<string> The IDs of the tokens
--- @return table<string, table<string, string>> The account balances for each respective ID
function SemiFungibleTokensMethods:getBatchBalances(positionIds)
  local bals = {}

  for i = 1, #positionIds do
    bals[ positionIds[i] ] = {}
    if self.balancesById[ positionIds[i] ] then
      bals[ positionIds[i] ] = self.balancesById[ positionIds[i] ]
    end
  end
  -- return balances
  return bals
end

return SemiFungibleTokens
