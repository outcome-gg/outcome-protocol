--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See activity.lua for full license details.
=========================================================
]]

local ActivityNotices = {}
local json = require('json')

function ActivityNotices.logFundingNotice(market, user, operation, collateral, amount, msg)
  return msg.reply({
    Action = "Log-Funding-Notice",
    Market = market,
    User = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = amount
  })
end

function ActivityNotices.logPredictionNotice(market, user, operation, collateral, outcome, amount, price, msg)
  return msg.reply({
    Action = "Log-Prediction-Notice",
    Market = market,
    User = user,
    Operation = operation,
    Collateral = collateral,
    Outcome = outcome,
    Quantity = amount,
    Price = price
  })
end


function ActivityNotices.logProbabilitiesNotice(market, probabilities, msg)
  return msg.reply({
    Action = "Log-Probabilities-Notice",
    Market = market,
    Probabilities = json.encode(probabilities)
  })
end

function ActivityNotices.updateIntervalsNotice(updateIntervals, msg)
  return msg.reply({
    Action = "Update-Intervals-Notice",
    UpdateIntervals = updateIntervals
  })
end

function ActivityNotices.updateRangeDurationsNotice(updateRangeDurations, msg)
  return msg.reply({
    Action = "Update-Range-Durations-Notice",
    UpdateRangeDurations = updateRangeDurations
  })
end

function ActivityNotices.updateMaxIntervalNotice(updateMaxInterval, msg)
  return msg.reply({
    Action = "Update-Max-Interval-Notice",
    UpdateMaxInterval = updateMaxInterval
  })
end

function ActivityNotices.updateMaxRangeDurationNotice(updateMaxRangeDuration, msg)
  return msg.reply({
    Action = "Update-Max-Range-Duration-Notice",
    UpdateMaxRangeDuration = updateMaxRangeDuration
  })
end

return ActivityNotices