local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)

local SemiFungibleTokens = {}
local SemiFungibleTokensMethods = require('modules.semiFungibleTokensNotices')

-- Constructor for SemiFungibleTokens 
function SemiFungibleTokens:new(name, ticker, denomination, logo)
  -- This will store user balancesOf semi-fungible tokens and metadata
  local obj = {
    balancesOf = {},  -- { userId -> id -> balance of semi-fungible tokens }
    name = name,
    ticker = ticker,
    denomination = denomination,
    logo = logo
  }
  setmetatable(obj, { __index = SemiFungibleTokensMethods })
  return obj
end

-- @dev Mint a quantity of a token with the given ID
-- @param to The address that will own the minted token
-- @param id ID of the token to be minted
-- @param quantity Quantity of the token to be minted
function SemiFungibleTokensMethods:mint(to, id, quantity)
  assert(quantity, 'Quantity is required!')
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')

  if not self.balancesOf[id] then self.balancesOf[id] = {} end
  if not self.balancesOf[id][to] then self.balancesOf[id][to] = "0" end

  self.balancesOf[id][to] = tostring(bint.__add(self.balancesOf[id][to], quantity))
  -- Send notice
  self:mintSingleNotice(to, id, quantity)
end

-- @dev Batch mint quantities of tokens with the given IDs
-- @param to The address that will own the minted token
-- @param ids IDs of the tokens to be minted
-- @param quantities Quantities of the tokens to be minted
function SemiFungibleTokensMethods:batchMint(to, ids, quantities)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')

  for i = 1, #ids do
    if not self.balancesOf[ids[i]] then self.balancesOf[ids[i]] = {} end
    if not self.balancesOf[ids[i]][to] then self.balancesOf[ids[i]][to] = "0" end

    self.balancesOf[ids[i]][to] = tostring(bint.__add(self.balancesOf[ids[i]][to], quantities[i]))
  end

  -- Send notice
  self:mintBatchNotice(to, ids, quantities)
end

-- @dev Burn a quantity of a token with the given ID
-- @param from The address that will burn the token
-- @param id ID of the token to be burned
-- @param quantity Quantity of the token to be burned
function SemiFungibleTokensMethods:burn(from, id, quantity)
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  assert(self.balancesOf[id], 'Id must exist! ' .. id)
  assert(self.balancesOf[id][from], 'User must hold token! :: ' .. id)
  assert(bint.__le(quantity, self.balancesOf[id][from]), 'User must have sufficient tokens! ' .. id)

  -- Burn tokens
  self.balancesOf[id][from] = tostring(bint.__sub(self.balancesOf[id][from], quantity))
  -- Send notice
  self:burnSingleNotice(from, id, quantity)
end

-- @dev Batch burn quantities of tokens with the given IDs
-- @param from The address that will burn the tokens
-- @param ids IDs of the tokens to be burned
-- @param quantities Quantities of the tokens to be burned
-- @param msg For sending X-Tags
function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, msg)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')

  for i = 1, #ids do
    assert(bint.__lt(0, quantities[i]), 'Quantity must be greater than zero!')
    assert(self.balancesOf[ids[i]], 'Id must exist! ' .. ids[i])
    assert(self.balancesOf[ids[i]][from], 'User must hold token! ' .. ids[i])
    assert(bint.__le(quantities[i], self.balancesOf[ids[i]][from]), 'User must have sufficient tokens!')
  end

  local remainingBalances = {}

  -- Burn tokens
  for i = 1, #ids do
    self.balancesOf[ids[i]][from] = tostring(bint.__sub(self.balancesOf[ids[i]][from], quantities[i]))
    remainingBalances[i] = BalancesOf[ids[i]][from]
  end
  -- Draft notice
  local notice = {
    Target = from,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    RemainingBalances = json.encode(remainingBalances),
    Action = 'Burn-Batch-Notice',
    Data = "Successfully burned batch"
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      notice[tagName] = tagValue
    end
  end
  -- Send notice
  self:burnBatchNotice(notice)
end

-- @dev Transfer a quantity of tokens with the given ID
-- @param from The address to be debited
-- @param recipient The address to be credited
-- @param id ID of the tokens to be transferred
-- @param quantity Quantity of the tokens to be transferred
-- @param cast The boolean to silence transfer notifications
-- @param msg For sending X-Tags
function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, msg)
  if not self.balancesOf[id] then self.balancesOf[id] = {} end
  if not self.balancesOf[id][from] then self.balancesOf[id][from] = "0" end
  if not self.balancesOf[id][recipient] then self.balancesOf[id][recipient] = "0" end

  local qty = bint(quantity)
  local balance = bint(self.balancesOf[id][from])
  if bint.__le(qty, balance) then
    self.balancesOf[id][from] = tostring(bint.__sub(balance, qty))
    self.balancesOf[id][recipient] = tostring(bint.__add(self.balancesOf[id][recipient], qty))

    -- Only send the notifications if the cast tag is not set
    if not cast then
      self:transferSingleNotices(from, recipient, id, quantity, msg)
    end
  else
    self:transferErrorNotice(from, id, msg.Id)
  end
end

-- @dev Batch transfer quantities of tokens with the given IDs
-- @param from The address to be debited
-- @param recipient The address to be credited
-- @param ids IDs of the tokens to be transferred
-- @param quantities Quantities of the tokens to be transferred
-- @param cast The boolean to silence transfer notifications
-- @param msg For sending X-Tags
function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, msg)
  local ids_ = {}
  local quantities_ = {}

  for i = 1, #ids do
    if not self.balancesOf[ids[i]] then self.balancesOf[ids[i]] = {} end
    if not self.balancesOf[ids[i]][from] then self.balancesOf[ids[i]][from] = "0" end
    if not self.balancesOf[ids[i]][recipient] then self.balancesOf[ids[i]][recipient] = "0" end

    local qty = bint(quantities[i])
    local balance = bint(self.balancesOf[ids[i]][from])

    if bint.__le(qty, balance) then
      self.balancesOf[ids[i]][from] = tostring(bint.__sub(balance, qty))
      self.balancesOf[ids[i]][recipient] = tostring(bint.__add(self.balancesOf[ids[i]][recipient], qty))
      table.insert(ids_, ids[i])
      table.insert(quantities_, quantities[i])
    else
      self:transferErrorNotice(from, ids[i], msg.id)
    end
  end

  -- Only send the notifications if the cast tag is not set
  if not cast and #ids_ > 0 then
    self:transferBatchNotices(from, recipient, ids_, quantities_, msg)
  end
end

function SemiFungibleTokensMethods:getBalanceOf(from, recipient, tokenId)
  local bal = '0'
  -- If Id is found then cointinue
  if self.balancesOf[tokenId] then
    -- If not Recipient is provided, then return the Senders balance
    if (recipient and self.balancesOf[tokenId][recipient]) then
      bal = self.balancesOf[tokenId][recipient]
    elseif self.balancesOf[tokenId][from] then
      bal = self.balancesOf[tokenId][from]
    end
  end
  -- return balance
  return bal
end

function SemiFungibleTokensMethods:getBalanceOfBatch(recipients, tokenIds)
  assert(#recipients == #tokenIds, 'Recipients and TokenIds must have same lengths')
  local bals = {}

  for i = 1, #recipients do
    table.insert(bals, '0')
    if self.balancesOf[tokenIds[i]] then
      if self.balancesOf[tokenIds[i]][recipients[i]] then
        bals[i] = self.balancesOf[tokenIds[i]][recipients[i]]
      end
    end
  end

  return bals
end

function SemiFungibleTokensMethods:getBalancesOf(from, tokenId)
  local bals = {}
  if self.balancesOf[tokenId] then
    bals = self.balancesOf[tokenId]
  end
  -- return balances
  return bals
end

return SemiFungibleTokens
