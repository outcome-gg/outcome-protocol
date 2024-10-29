local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local ao = require('.ao')
local config = require('modules.config')

local Tokens = {}
local TokensMethods = require('modules.tokensNotices')

-- Constructor for Tokens 
function Tokens:new(balances, totalSupply, name, ticker, denomination, logo)
  -- This will store user balancesOf semi-fungible tokens and metadata
  local obj = {
    balances = balances,
    totalSupply = totalSupply,
    name = name,
    ticker = ticker,
    denomination = denomination,
    logo = logo
  }
  setmetatable(obj, { __index = TokensMethods })
  return obj
end

-- @dev Internal function to mint a quantity of tokens
-- @param to The address that will own the minted token
-- @param quantity Quantity of the token to be minted
function TokensMethods:mint(to, quantity)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  -- Mint tokens
  if not self.balances[to] then self.balances[to] = '0' end
  self.balances[to] = tostring(bint.__add(bint(self.balances[to]), quantity))
  self.totalSupply = tostring(bint.__add(bint(self.totalSupply), quantity))
  -- Send notice
  self.mintNotice(to, quantity)
end

-- @dev Internal function to burn a quantity of tokens
-- @param from The address that will burn the token
-- @param quantity Quantity of the token to be burned
function TokensMethods:burn(from, quantity)
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  assert(bint.__le(quantity, self.balances[ao.id]), 'Must have sufficient tokens!')
  -- Burn tokens
  self.balances[ao.id] = tostring(bint.__sub(self.balances[ao.id], quantity))
  self.totalSupply = tostring(bint.__sub(bint(self.totalSupply), quantity))
  -- Send notice
  self.burnNotice(from, quantity)
end

-- @dev Internal function to transfer a quantity of tokens
-- @param recipient The address that will send the token
-- @param from The address that will receive the token
-- @param quantity Quantity of the token to be burned
-- @param cast Cast to silence the transfer notice
-- @param msgTags The message tags (used for x-tag forwarding)
-- @param msgId The message ID (used for error reporting)
function TokensMethods:transfer(from, recipient, quantity, cast, msgTags, msgId)
  if not self.balances[from] then self.balances[from] = "0" end
  if not self.balances[recipient] then self.balances[recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balances[from])
  if bint.__le(qty, balance) then
    self.balances[from] = tostring(bint.__sub(balance, qty))
    self.balances[recipient] = tostring(bint.__add(self.balances[recipient], qty))

    --[[
         Only send the notifications to the Sender and Recipient
         if the Cast tag is not set on the Transfer message
       ]]
    --
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
      for tagName, tagValue in pairs(msgTags) do
        -- Tags beginning with "X-" are forwarded
        if string.sub(tagName, 1, 2) == "X-" then
          debitNotice[tagName] = tagValue
          creditNotice[tagName] = tagValue
        end
      end

      -- Send Debit-Notice and Credit-Notice
      self.transferNotices(debitNotice, creditNotice)
    end
  else
    self.transferErrorNotice(from, msgId)
  end
end

return Tokens
