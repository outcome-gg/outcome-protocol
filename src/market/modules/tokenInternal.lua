local bint = require('.bint')(256)
local json = require('json')
local ao = require('.ao')

local Token = {}
local TokenMethods = require('modules.tokenNotices')

-- Constructor for Token 
function Token:new()
  -- This will store user balances of tokens and metadata
  local obj = {
    name = '',
    ticker = '',
    logo = '',
    balances = {},
    totalSupply = '0',
    denomination = 12
  }
  setmetatable(obj, { __index = TokenMethods })
  return obj
end

-- @dev Internal function to mint a quantity of tokens
-- @param to The address that will own the minted token
-- @param quantity Quantity of the token to be minted
function TokenMethods:mint(to, quantity, msg)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  -- Mint tokens
  if not self.balances[to] then self.balances[to] = '0' end
  self.balances[to] = tostring(bint.__add(bint(self.balances[to]), quantity))
  self.totalSupply = tostring(bint.__add(bint(self.totalSupply), quantity))
  -- Send notice
  return self.mintNotice(to, quantity, msg)
end

-- @dev Internal function to burn a quantity of tokens
-- @param from The address that will burn the token
-- @param quantity Quantity of the token to be burned
function TokenMethods:burn(from, quantity, msg)
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  assert(self.balances[from], 'Must have token balance!')
  assert(bint.__le(quantity, self.balances[from]), 'Must have sufficient tokens!')
  -- Burn tokens
  self.balances[from] = tostring(bint.__sub(self.balances[from], quantity))
  self.totalSupply = tostring(bint.__sub(bint(self.totalSupply), quantity))
  -- Send notice
  return self.burnNotice(quantity, msg)
end

-- @dev Internal function to transfer a quantity of tokens
-- @param recipient The address that will send the token
-- @param from The address that will receive the token
-- @param quantity Quantity of the token to be burned
-- @param cast Cast to silence the transfer notice
-- @param msg The message (used for x-tag forwarding and reporting)
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
