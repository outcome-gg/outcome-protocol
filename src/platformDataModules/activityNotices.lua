--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See activity.lua for full license details.
=========================================================
]]

local ActivityNotices = {}
local json = require('json')

function ActivityNotices.logFundingNotice(funding, msg)
  return msg.reply({
    Action = "Log-Funding-Notice",
    Data = json.encode(funding)
  })
end

function ActivityNotices.logPredictionNotice(prediction, msg)
  return msg.reply({
    Action = "Log-Prediction-Notice",
    Data = json.encode(prediction)
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