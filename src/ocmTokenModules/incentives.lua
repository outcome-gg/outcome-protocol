local Incentives = {}
local IncentivesMethods = {}
local IncentivesNotices = {}
local bint = require('.bint')(256)
local constants = require("ocmTokenModules.constants")

function Incentives:new()
  local incentives = {
    configurator = constants.incentives.configurator,
    lpToHolderRatio = constants.incentives.lpToHolderRatio,
    collateralPrices = constants.incentives.collateralPrices,
    collateralFactors = constants.incentives.collateralFactors,
    collateralDenominations = constants.incentives.collateralDenominations,
    normalizedCollateralFundingBalances = {},
    normalizedCollateralPredictionBalances = {},
    normalizedCollateralFundingTWAB = {},
    normalizedCollateralPredictionTWAB = {},
    lastUpdateTimestamps = { funding = {}, prediction = {} },
    lastDistributionTimestamp = os.time()
  }
  setmetatable(incentives, {
    __index = function(_, k)
      if IncentivesMethods[k] then
        return IncentivesMethods[k]
      elseif IncentivesNotices[k] then
        return IncentivesNotices[k]
      else
        return nil
      end
    end
  })
  return incentives
end

--[[
=============
WRITE METHODS
=============
]]

function IncentivesMethods:updateBalanceAndTWAB(user, collateral, balanceType, newBalance, timestamp)
  local balances = balanceType == "funding" and self.normalizedCollateralFundingBalances or self.normalizedCollateralPredictionBalances
  local twabTable = balanceType == "funding" and self.normalizedCollateralFundingTWAB or self.normalizedCollateralPredictionTWAB
  local lastTimestamps = balanceType == "funding" and self.lastUpdateTimestamps.funding or self.lastUpdateTimestamps.prediction
  -- initialize tables
  balances[collateral] = balances[collateral] or {}
  twabTable[collateral] = twabTable[collateral] or {}
  lastTimestamps[collateral] = lastTimestamps[collateral] or {}
  -- retrieve previous balance and timestamp
  local previousBalance = tonumber(balances[collateral][user] or 0)
  local lastTimestamp = lastTimestamps[collateral][user] or self.lastDistributionTimestamp
  local elapsedTime = timestamp - lastTimestamp
  -- update TWAB with elapsed time and previous balance
  twabTable[collateral][user] = (twabTable[collateral][user] or 0) + (previousBalance * elapsedTime)
  -- update current balance and timestamp
  balances[collateral][user] = tostring(newBalance)
  lastTimestamps[collateral][user] = timestamp
end

function IncentivesMethods:logFunding(user, operation, collateral, quantity, timestamp, msg)
  self.normalizedCollateralFundingBalances[collateral] = self.normalizedCollateralFundingBalances[collateral] or {}
  self.normalizedCollateralFundingBalances[collateral][user] = self.normalizedCollateralFundingBalances[collateral][user] or "0"
  -- retrieve existing balance
  local fundingBalance = self.normalizedCollateralFundingBalances[collateral][user]
  -- normalize quantity irrespective of collateral denomination
  local normalizedQuantity = quantity * (10 ^ (12 - self.collateralDenominations[collateral]))
  -- calculate new balance 
  local newBalance = operation == "add" and tostring(bint.__add(fundingBalance, normalizedQuantity)) or tostring(bint.__sub(fundingBalance, normalizedQuantity))
  -- update balances
  self:updateBalanceAndTWAB(user, collateral, "funding", newBalance, timestamp)
  -- send notice
  return self.logFundingNotice(user, operation, collateral, quantity, msg)
end

function IncentivesMethods:logPrediction(user, operation, collateral, quantity, timestamp, msg)
  self.normalizedCollateralPredictionBalances[collateral] = self.normalizedCollateralPredictionBalances[collateral] or {}
  self.normalizedCollateralPredictionBalances[collateral][user] = self.normalizedCollateralPredictionBalances[collateral][user] or "0"
  -- retrieve existing balance
  local predictionBalance = self.normalizedCollateralPredictionBalances[collateral][user]
  -- normalize quantity irrespective of collateral denomination
  local normalizedQuantity = quantity * (10 ^ (12 - self.collateralDenominations[collateral]))
  -- calculate new balance 
  local newBalance = operation == "buy" and tostring(bint.__add(predictionBalance, normalizedQuantity)) or tostring(bint.__sub(predictionBalance, normalizedQuantity))
  -- update balances
  self:updateBalanceAndTWAB(user, collateral, "prediction", newBalance, timestamp)
  -- send notice 
  self.logPredictionNotice(user, operation, collateral, quantity, msg)
end

--[[
============
READ METHODS
============
]]

function IncentivesMethods:getFundingWeights()
  local fundingWeights = {}
  local totalFundingWeight = 0
  local elapsedTime = os.time() - self.lastDistributionTimestamp
  -- iterate over all collateral balances
  for collateral, twabTable in pairs(self.normalizedCollateralFundingTWAB) do
    local collateralPrice = self.collateralPrices[collateral]
    local collateralFactor = self.collateralFactors[collateral] or 0
    -- iterate over all user balances
    for user, weightedBalance in pairs(twabTable) do
      local averageBalance = weightedBalance / elapsedTime
      local weightedValue = averageBalance * collateralPrice * collateralFactor
      fundingWeights[user] = (fundingWeights[user] or 0) + weightedValue
      totalFundingWeight = totalFundingWeight + weightedValue
    end
  end
  return fundingWeights, totalFundingWeight
end

function IncentivesMethods:getPredictionWeight()
  local predictionWeight = {}
  local totalPredictionWeight = 0
  local elapsedTime = os.time() - self.lastDistributionTimestamp
  -- iterate over all collateral balances
  for collateral, twabTable in pairs(self.normalizedCollateralPredictionTWAB) do
    local collateralPrice = self.collateralPrices[collateral]
    local collateralFactor = self.collateralFactors[collateral] or 0
    -- iterate over all user balances
    for user, weightedBalance in pairs(twabTable) do
      local averageBalance = weightedBalance / elapsedTime
      local weightedValue = averageBalance * collateralPrice * collateralFactor
      predictionWeight[user] = (predictionWeight[user] or 0) + weightedValue
      totalPredictionWeight = totalPredictionWeight + weightedValue
    end
  end
  return predictionWeight, totalPredictionWeight
end

function IncentivesMethods:calcFundingRewards(mintAmount)
  local fundingWeights, totalFundingWeight = self:getAggregatedFundingBalances()
  local fundingRewards = {}
  for user, weight in pairs(fundingWeights) do
    local reward = mintAmount * self.lpToHolderRatio * weight / totalFundingWeight
    fundingRewards[user] = reward
  end
  return fundingRewards
end

function IncentivesMethods:calcPredictionRewards(mintAmount)
  local predictionWeights, totalPredictionWeight = self:getAggregatedPredictionBalances()
  local predictionRewards = {}
  for user, weight in pairs(predictionWeights) do
    local reward = mintAmount * (1 - self.lpToHolderRatio) * weight / totalPredictionWeight
    predictionRewards[user] = reward
  end
  return predictionRewards
end

function IncentivesMethods:distributeRewards(mintAmount)
  local fundingRewards = self:calcFundingRewards(mintAmount)
  local predictionRewards = self:calcPredictionRewards(mintAmount)
  -- reset TWABs and update distribution timestamp
  self.normalizedCollateralFundingTWAB = {}
  self.normalizedCollateralPredictionTWAB = {}
  self.lastDistributionTimestamp = os.time()
  -- return rewards
  return fundingRewards, predictionRewards
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

function IncentivesMethods:updateConfigurator(configurator, msg)
  self.configurator = configurator
  self.updateConfiguratorNotice(configurator, msg)
end

function IncentivesMethods:updateLpToHolderRatio(lpToHolderRatio, msg)
  self.lpToHolderRatio = tonumber(lpToHolderRatio)
  self.updateLpToHolderRatioNotice(lpToHolderRatio, msg)
end

function IncentivesMethods:updateCollateralPrices(collateralPrices, msg)
  self.collateralPrices = collateralPrices
  self.updateCollateralPricesNotice(collateralPrices, msg)
end

function IncentivesMethods:updateCollateralFactors(collateralFactors, msg)
  self.collateralFactors = collateralFactors
  self.updateCollateralFactorsNotice(collateralFactors, msg)
end

function IncentivesMethods:updateCollateralDenominations(collateralDenominations, msg)
  self.collateralDenominations = collateralDenominations
  self.updateCollateralDenominationsNotice(collateralDenominations, msg)
end

return Incentives