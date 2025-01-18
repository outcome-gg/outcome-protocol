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

function IncentivesNotices.setLpToHolderRatioNotice(lpToHolderRatio, msg)
  return msg.reply({
    Action = "Set-LP-to-Holder-Ratio-Notice",
    Data = lpToHolderRatio
  })
end

function IncentivesNotices.setCollateralPrices(collateralPrices, msg)
  return msg.reply({
    Action = "Set-Collateral-Prices-Notice",
    Data = json.encode(collateralPrices)
  })
end

function IncentivesNotices.setCollateralFactors(collateralFactors, msg)
  return msg.reply({
    Action = "Set-Collateral-Factors-Notice",
    Data = json.encode(collateralFactors)
  })
end

function IncentivesNotices.setCollateralDenominations(collateralDenominations, msg)
  return msg.reply({
    Action = "Set-Collateral-Denominations-Notice",
    Data = json.encode(collateralDenominations)
  })
end

function IncentivesNotices.setConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Set-Configurator-Notice",
    Data = configurator
  })
end

return IncentivesNotices
