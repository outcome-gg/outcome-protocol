--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See activity.lua for full license details.
=========================================================
]]

local ActivityNotices = {}
local json = require('json')


function ActivityNotices.logMarketNotice(
  marketFactory,
  market,
  creator,
  creatorFee,
  creatorFeeTarget,
  question,
  questionSlug,
  rules,
  outcomeSlotCount,
  collateral,
  resolutionAgent,
  category,
  subcategory,
  logo,
  logos,
  eventId,
  chatroom,
  startTime,
  endTime,
  msg
)
  return msg.reply({
    Action = "Log-Market-Notice",
    MarketFactory = marketFactory,
    Market = market,
    Creator = creator,
    CreatorFee = tostring(creatorFee),
    CreatorFeeTarget = creatorFeeTarget,
    Question = question,
    QuestionSlug = questionSlug,
    Rules = rules,
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Collateral = collateral,
    ResolutionAgent = resolutionAgent,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    Logos = logos,
    EventId = eventId,
    Chatroom = chatroom,
    StartTime = startTime,
    EndTime = endTime
  })
end

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

function ActivityNotices.logPredictionNotice(market, user, operation, collateral, amount, outcome, shares, price, msg)
  return msg.reply({
    Action = "Log-Prediction-Notice",
    Market = market,
    User = user,
    Operation = operation,
    Collateral = collateral,
    Quantity = amount,
    Outcome = outcome,
    Shares = shares,
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

function ActivityNotices.logPayoutsNotice(market, payouts, msg)
  return msg.reply({
    Action = "Log-Payouts-Notice",
    Market = market,
    Probabilities = json.encode(payouts)
  })
end

return ActivityNotices