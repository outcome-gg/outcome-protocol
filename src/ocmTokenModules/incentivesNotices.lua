--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See incentives.lua for full license details.
=========================================================
]]

local IncentivesNotices = {}
local json = require('json')

function IncentivesNotices.logFundingNotice(user, operation, collateral, quantity, msg)
  return msg.reply({
    Action = "Log-Funding-Notice",
    Account = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity
  })
end

function IncentivesNotices.logPredictionNotice(user, operation, collateral, quantity, msg)
  return msg.reply({
    Action = "Log-Prediction-Notice",
    Account = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = quantity
  })
end

function IncentivesNotices.updateConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Update-Configurator-Notice",
    Data = configurator
  })
end

function IncentivesNotices.updateLpToHolderRatioNotice(lpToHolderRatio, msg)
  return msg.reply({
    Action = "Update-LP-To-Holder-Ratio-Notice",
    Data = lpToHolderRatio
  })
end

function IncentivesNotices.updateCollateralPrices(collateralPrices, msg)
  return msg.reply({
    Action = "Update-Collateral-Prices-Notice",
    Data = json.encode(collateralPrices)
  })
end

function IncentivesNotices.updateCollateralFactors(collateralFactors, msg)
  return msg.reply({
    Action = "Update-Collateral-Factors-Notice",
    Data = json.encode(collateralFactors)
  })
end

function IncentivesNotices.updateCollateralDenominations(collateralDenominations, msg)
  return msg.reply({
    Action = "Update-Collateral-Denominations-Notice",
    Data = json.encode(collateralDenominations)
  })
end

return IncentivesNotices
