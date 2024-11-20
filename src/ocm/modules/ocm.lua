local json = require('json')
local bint = require('.bint')(256)
local ao = require('.ao')
local config = require('modules.config')
local Token = require('modules.token')

local OCM = {}
local OCMMethods = require('modules.cpmmNotices')

-- Constructor for OCM 
function OCM:new()
  -- Initialize Token and store the object
  local token = Token:new(config.UtilityToken.Balances, config.UtilityToken.TotalSupply, config.UtilityToken.Name, config.UtilityToken.Ticker, config.UtilityToken.Denomination, config.UtilityToken.Logo)

  -- Create a new OCM object
  local obj = {
    -- Token Vars
    token = token,
    -- OCM Vars
  }

  -- Set metatable for method lookups
  setmetatable(obj, {__index = OCMMethods})
  return obj
end

---------------------------------------------------------------------------------
-- TOKEN METHODS ----------------------------------------------------------------
---------------------------------------------------------------------------------
-- @dev Update before token transfers
function OCMMethods:_beforeTokenTransfer(from, to, amount)
  -- if from ~= nil then
  --   self:withdrawFees(from)
  -- end
  -- local totalSupply = self.token.totalSupply
  -- local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), amount), totalSupply)))

  -- if from ~= nil and to ~= nil then
  --   self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), withdrawnFeesTransfer))
  --   self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), withdrawnFeesTransfer))
  -- end
end

-- Token
-- @dev See tokensMethods:mint & _beforeTokenTransfer
function OCMMethods:mint(to, quantity)
  self:_beforeTokenTransfer(nil, to, quantity)
  self.token:mint(to, quantity)
end

-- @dev See tokenMethods:burn & _beforeTokenTransfer
function OCMMethods:burn(from, quantity)
  self:_beforeTokenTransfer(from, nil, quantity)
  self.token:burn(from, quantity)
end

-- @dev See tokenMethods:transfer & _beforeTokenTransfer
function OCMMethods:transfer(from, recipient, quantity, cast, msgTags, msgId)
  self:_beforeTokenTransfer(from, recipient, quantity)
  self.token:transfer(from, recipient, quantity, cast, msgTags, msgId)
end

return OCM