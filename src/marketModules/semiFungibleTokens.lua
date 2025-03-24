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
local sharedUtils = require("marketModules.sharedUtils")
local json = require("json")

-- Represents SemiFungibleTokens
--- @class SemiFungibleTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logos table<string> The token logos Arweave TxID for each ID
--- @field balancesById table<string, table<string, string>> The account token balances by ID
--- @field totalSupplyById table<string, string> The total supply of the token by ID
--- @field denomination number The number of decimals

--- Creates a new SemiFungibleTokens instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logos table<string> The token logos Arweave TxID for each ID
--- @param balancesById table<string, table<string, string>> The account token balances by ID
--- @param totalSupplyById table<string, string> The total supply of the token by ID
--- @param denomination number The number of decimals
--- @return SemiFungibleTokens semiFungibleTokens The new SemiFungibleTokens instance
function SemiFungibleTokens.new(name, ticker, logos, balancesById, totalSupplyById, denomination)
  local semiFungibleTokens = {
    name = name,
    ticker = ticker,
    logos = logos,
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
--- @param cast boolean The cast is set to true to silence the mint notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The mint notice if not cast
function SemiFungibleTokensMethods:mint(to, id, quantity, cast, detached, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  -- mint tokens
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][to] then self.balancesById[id][to] = "0" end
  if not self.totalSupplyById[id] then self.totalSupplyById[id] = "0" end
  self.balancesById[id][to] = sharedUtils.safeAdd(self.balancesById[id][to], quantity)
  self.totalSupplyById[id] = sharedUtils.safeAdd(self.totalSupplyById[id], quantity)
  -- send notice
  if not cast then return self.mintSingleNotice(to, id, quantity, detached, msg) end
end

--- Batch mint quantities of tokens with the given IDs
--- @param to string The address that will own the minted tokens
--- @param ids table<string> The IDs of the tokens to mint
--- @param quantities table<string> The quantities of tokens to mint
--- @param cast boolean The cast is set to true to silence the mint notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The batch mint notice if not cast
function SemiFungibleTokensMethods:batchMint(to, ids, quantities, cast, detached, msg)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  for i = 1, #ids do
    assert(bint.__lt(0, quantities[i]), 'Quantity must be greater than zero!')
  end
  -- mint tokens
  for i = 1, #ids do
    -- @dev spacing to resolve text to code eval issue
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][to] then self.balancesById[ ids[i] ][to] = "0" end
    if not self.totalSupplyById[ ids[i] ] then self.totalSupplyById[ ids[i] ] = "0" end
    self.balancesById[ ids[i] ][to] = sharedUtils.safeAdd(self.balancesById[ ids[i] ][to], quantities[i])
    self.totalSupplyById[ ids[i] ] = sharedUtils.safeAdd(self.totalSupplyById[ ids[i] ], quantities[i])
  end
  -- send notice
  if not cast then return self.mintBatchNotice(to, ids, quantities, detached, msg) end
end

--- Burn a quantity of tokens with a given ID
--- @param from string The process ID that will no longer own the burned tokens
--- @param id string The ID of the tokens to burn
--- @param quantity string The quantity of tokens to burn
--- @param cast boolean The cast is set to true to silence the burn notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The burn notice if not cast
function SemiFungibleTokensMethods:burn(from, id, quantity, cast, detached, msg)
  assert(bint.__lt(0, bint(quantity)), 'Quantity must be greater than zero!')
  assert(self.balancesById[id], 'Id must exist! ' .. id)
  assert(self.balancesById[id][from], 'Account must hold token! :: ' .. id)
  assert(bint.__le(bint(quantity), self.balancesById[id][from]), 'Account must have sufficient tokens! ' .. id)
  -- burn tokens
  self.balancesById[id][from] = sharedUtils.safeSub(self.balancesById[id][from], quantity)
  self.totalSupplyById[id] = sharedUtils.safeSub(self.totalSupplyById[id], quantity)
  -- send notice
  if not cast then return self.burnSingleNotice(from, id, quantity, detached, msg) end
end

--- Batch burn a quantity of tokens with the given IDs
--- @param from string The process ID that will no longer own the burned tokens
--- @param ids table<string> The IDs of the tokens to burn
--- @param quantities table<string> The quantities of tokens to burn
--- @param cast boolean The cast is set to true to silence the burn notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The batch burn notice if not cast
function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, cast, detached, msg)
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
    self.balancesById[ ids[i] ][from] = sharedUtils.safeSub(self.balancesById[ ids[i] ][from], quantities[i])
    self.totalSupplyById[ ids[i] ] = sharedUtils.safeSub(self.totalSupplyById[ ids[i] ], quantities[i])
    remainingBalances[i] = self.balancesById[ ids[i] ][from]
  end
  -- send notice
  if not cast then return self.burnBatchNotice(from, ids, quantities, remainingBalances, detached, msg) end
end

--- Transfer a quantity of tokens with the given ID
--- @param from string The process ID that will send the token
--- @param recipient string The process ID that will receive the token
--- @param id string The ID of the tokens to transfer
--- @param quantity string The quantity of tokens to transfer
--- @param cast boolean The cast is set to true to silence the transfer notice
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, detached, msg)
  if not self.balancesById[id] then self.balancesById[id] = {} end
  if not self.balancesById[id][from] then self.balancesById[id][from] = "0" end
  if not self.balancesById[id][recipient] then self.balancesById[id][recipient] = "0" end

  local balance = self.balancesById[id][from]
  if bint.__le(bint(quantity), bint(balance)) then
    self.balancesById[id][from] = sharedUtils.safeSub(balance, quantity)
    self.balancesById[id][recipient] = sharedUtils.safeAdd(self.balancesById[id][recipient], quantity)

    -- Only send the notifications if the cast tag is not set
    if not cast then
      return self.transferSingleNotices(from, recipient, id, quantity, detached, msg)
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
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return table<Message>|Message|nil The transfer notices, error notice or nothing
function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, detached, msg)
  local ids_ = {}
  local quantities_ = {}

  for i = 1, #ids do
    if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
    if not self.balancesById[ ids[i] ][from] then self.balancesById[ ids[i] ][from] = "0" end
    if not self.balancesById[ ids[i] ][recipient] then self.balancesById[ ids[i] ][recipient] = "0" end

    local qty = quantities[i]
    local balance = self.balancesById[ ids[i] ][from]

    if bint.__le(bint(qty), bint(balance)) then
      self.balancesById[ ids[i] ][from] = sharedUtils.safeSub(balance, qty)
      self.balancesById[ ids[i] ][recipient] = sharedUtils.safeAdd(self.balancesById[ ids[i] ][recipient], qty)
      table.insert(ids_, ids[i])
      table.insert(quantities_, quantities[i])
    else
      return self.transferErrorNotice(ids[i], msg)
    end
  end

  -- Only send the notifications if the cast tag is not set
  if not cast and #ids_ > 0 then
    return self.transferBatchNotices(from, recipient, ids_, quantities_, detached, msg)
  end
end

--- Get the token balance for a specific account and token ID.
--- @notice If `onBehalfOf` is provided, the balance for that account is returned;
--- otherwise, the balance for `sender` is used.
--- @param sender string The process ID of the sender
--- @param onBehalfOf string|nil An optional alternative process ID to query the balance for
--- @param id string The ID of the token
--- @return string The balance of the account for the given ID
function SemiFungibleTokensMethods:getBalance(sender, onBehalfOf, id)
  -- Use the alternative account if provided; otherwise default to sender
  local account = onBehalfOf and onBehalfOf or sender
  local bal = "0"
  --- Check if the token ID exists
  if self.balancesById[id] then
    -- Return the balance for the account or "0" if not found
    bal = self.balancesById[id][account] or "0"
  end
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

--- Get the logo for the token with the given ID
--- @param id string The ID of the token
--- @return string The Arweave TxID of the logo
function SemiFungibleTokensMethods:getLogo(id)
  local logo = ''
  if self.logos[tonumber(id)] then
    logo = self.logos[tonumber(id)]
  end
  -- return logo
  return logo
end

return SemiFungibleTokens
