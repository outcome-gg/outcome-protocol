local bint = require('.bint')(256)
local json = require('json')

local BalanceManager = {}
local BalanceManagerMethods = {}

-- Constructor for BalanceManager 
function BalanceManager:new(decimals)
  -- This will store user balances for both available and locked collateral and conditional tokens
  local obj = {
    fundBalances = {},  -- { userId -> balance of available collateral tokens }
    shareBalances = {}, -- { userId -> balance of available conditional tokens (shares) }
    lockedFunds = {},   -- { userId -> balance of locked collateral tokens (e.g., tied to orders) }
    lockedShares = {},  -- { userId -> balance of locked conditional tokens (e.g., tied to orders) }
    decimals = decimals -- used for handling decimal precision
  }
  setmetatable(obj, { __index = BalanceManagerMethods })
  return obj
end

-- Add collateral funds to the user's available balance
function BalanceManagerMethods:addFunds(userId, amount)
  self.fundBalances[userId] = self.fundBalances[userId] or '0'
  self.fundBalances[userId] = tostring(bint.__add(bint(self.fundBalances[userId]), bint(amount * 10^self.decimals)))
end

-- Add conditional tokens (shares) to the user's available balance
function BalanceManagerMethods:addShares(userId, amount)
  self.shareBalances[userId] = self.shareBalances[userId] or '0'
  self.shareBalances[userId] = tostring(bint.__add(bint(self.shareBalances[userId]), bint(amount)))
end

-- Withdraw collateral funds from the user's available balance
function BalanceManagerMethods:withdrawFunds(userId, amount)
  self.fundBalances[userId] = self.fundBalances[userId] or '0'
  if not bint.__le(bint(amount * 10^self.decimals), bint(self.fundBalances[userId])) then
    return false, 'Insufficient fund balance'
  end

  self.fundBalances[userId] = tostring(bint.__sub(bint(self.fundBalances[userId]), bint(amount * 10^self.decimals)))
  return true, 'Withdraw funds succeeded'
end

-- Withdraw conditional tokens (shares) from the user's available balance
function BalanceManagerMethods:withdrawShares(userId, amount)
  self.shareBalances[userId] = self.shareBalances[userId] or '0'
  if not bint.__le(bint(amount), bint(self.shareBalances[userId])) then
    return false, 'Insufficient share balance'
  end

  self.shareBalances[userId] = tostring(bint.__sub(bint(self.shareBalances[userId]), bint(amount)))
  return true, 'Withdraw shares succeeded'
end

-- Lock collateral funds for an order
function BalanceManagerMethods:lockFunds(userId, amount)
  assert(self.fundBalances[userId], "Insufficient available funds")
  assert(bint.__le(bint(amount), bint(self.fundBalances[userId])), "Insufficient balance to lock")

  -- Move from available to locked
  self.fundBalances[userId] = tostring(bint.__sub(bint(self.fundBalances[userId]), bint(amount)))
  self.lockedFunds[userId] = self.lockedFunds[userId] or '0'
  self.lockedFunds[userId] = tostring(bint.__add(bint(self.lockedFunds[userId]), bint(amount)))
end

-- Lock conditional tokens (shares) for an order
function BalanceManagerMethods:lockShares(userId, amount)
  assert(self.shareBalances[userId], "Insufficient available shares")
  assert(bint.__le(bint(amount), bint(self.shareBalances[userId])), "Insufficient share balance to lock")

  -- Move from available to locked
  self.shareBalances[userId] = tostring(bint.__sub(bint(self.shareBalances[userId]), bint(amount)))
  self.lockedShares[userId] = self.lockedShares[userId] or '0'
  self.lockedShares[userId] = tostring(bint.__add(bint(self.lockedShares[userId]), bint(amount)))
end

-- Release locked collateral funds back to the user's available balance
function BalanceManagerMethods:releaseFunds(userId, amount)
  assert(self.lockedFunds[userId], "No locked funds")
  assert(bint.__le(bint(amount), self.lockedFunds[userId]), "Insufficient locked funds to release")

  -- Move from locked to available
  self.lockedFunds[userId] = tostring(bint.__sub(bint(self.lockedFunds[userId]), bint(amount)))
  self.fundBalances[userId] = tostring(bint.__add(bint(self.fundBalances[userId]), bint(amount)))
end

-- Release locked shares back to the user's available balance
function BalanceManagerMethods:releaseShares(userId, amount)
  assert(self.lockedShares[userId], "No locked shares")
  assert(bint.__le(bint(amount), self.lockedShares[userId]), "Insufficient locked shares to release")

  -- Move from locked to available
  self.lockedShares[userId] = tostring(bint.__sub(bint(self.lockedShares[userId]), bint(amount)))
  self.shareBalances[userId] = tostring(bint.__add(bint(self.shareBalances[userId]), bint(amount)))
end

function BalanceManagerMethods:settleTrade(buyerId, sellerId, price, amount)
  self.fundBalances[buyerId] = self.fundBalances[buyerId] or '0'
  self.fundBalances[sellerId] = self.fundBalances[sellerId] or '0'
  self.shareBalances[buyerId] = self.shareBalances[buyerId] or '0'
  self.shareBalances[sellerId] = self.shareBalances[sellerId] or '0'

  local fundAmount = tostring(math.floor(price * amount))

  if not bint.__le(bint(fundAmount), bint(self.lockedFunds[buyerId])) then
    return false, 'Insufficient buyer fund balance'
  elseif not bint.__le(bint(amount), bint(self.lockedShares[sellerId])) then
    return false, 'Insufficient seller share balance'
  end

  -- Move funds from buyer (locked) to seller (available)
  self.lockedFunds[buyerId] = tostring(bint.__sub(bint(self.lockedFunds[buyerId]), bint(fundAmount)))
  self.fundBalances[sellerId] = tostring(bint.__add(bint(self.fundBalances[sellerId]), bint(fundAmount)))
  -- Move shares from seller (locked) to buyer (available)
  self.lockedShares[sellerId] = tostring(bint.__sub(bint(self.lockedShares[sellerId]), bint(amount)))
  self.shareBalances[buyerId] = tostring(bint.__add(bint(self.shareBalances[buyerId]), bint(amount)))
  return true, 'Settlement succeeded'
end

function BalanceManagerMethods:unlockOvercommittedFunds(userId, amount)
  if not self.lockedFunds[userId] then
    return false, 'No locked funds'
  elseif not bint.__le(bint(amount * 10^self.decimals), self.lockedFunds[userId])  then
    return false, 'Insufficient locked funds to release'
  end

  self:releaseFunds(userId, amount * 10^self.decimals)
  return true, 'Unlock succeeded'
end

-- Get user's available collateral balance
function BalanceManagerMethods:getAvailableFunds(userId)
  return self.fundBalances[userId] and self.fundBalances[userId] / 10^self.decimals or 0
end

-- Get user's available conditional token (shares) balance
function BalanceManagerMethods:getAvailableShares(userId)
  return self.shareBalances[userId] or 0
end

-- Get user's locked collateral balance
function BalanceManagerMethods:getLockedFunds(userId)
  return self.lockedFunds[userId] and self.lockedFunds[userId] / 10^self.decimals or 0
end

-- Get user's locked conditional token (shares) balance
function BalanceManagerMethods:getLockedShares(userId)
  return self.lockedShares[userId] or 0
end

return BalanceManager
