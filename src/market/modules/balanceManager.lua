local bint = require('.bint')(256)

local BalanceManager = {}
local BalanceManagerMethods = {}

-- Constructor for BalanceManager 
function BalanceManager:new()
  -- This will store user balances for both available and locked collateral and conditional tokens
  local obj = {
    fundBalances = {},  -- { userId -> balance of available collateral tokens }
    shareBalances = {}, -- { userId -> balance of available conditional tokens (shares) }
    lockedFunds = {},   -- { userId -> balance of locked collateral tokens (e.g., tied to orders) }
    lockedShares = {}   -- { userId -> balance of locked conditional tokens (e.g., tied to orders) }
  }
  setmetatable(obj, { __index = BalanceManagerMethods })
  return obj
end

-- Add collateral funds to the user's available balance
function BalanceManagerMethods:addFunds(userId, amount)
  self.fundBalances[userId] = self.fundBalances[userId] or '0'
  self.fundBalances[userId] = tostring(bint.__add(bint(self.fundBalances[userId]), bint(amount)))
end

-- Add conditional tokens (shares) to the user's available balance
function BalanceManagerMethods:addShares(userId, amount)
  self.shareBalances[userId] = self.shareBalances[userId] or '0'
  self.shareBalances[userId] = tostring(bint.__add(bint(self.shareBalances[userId]), bint(amount)))
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

-- Get user's available collateral balance
function BalanceManagerMethods:getAvailableFunds(userId)
  return self.fundBalances[userId] or '0'
end

-- Get user's available conditional token (shares) balance
function BalanceManagerMethods:getAvailableShares(userId)
  return self.shareBalances[userId] or '0'
end

-- Get user's locked collateral balance
function BalanceManagerMethods:getLockedFunds(userId)
  return self.lockedFunds[userId] or '0'
end

-- Get user's locked conditional token (shares) balance
function BalanceManagerMethods:getLockedShares(userId)
  return self.lockedShares[userId] or '0'
end

return BalanceManager
