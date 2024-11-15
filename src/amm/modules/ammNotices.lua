local ao = require('.ao')
local json = require('json')

local AMMNotices = {}

function AMMNotices.newMarketNotice(collateralToken, conditionalTokens, marketId, conditionId, collectionIds, positionIds, outcomeSlotCount, name, ticker, logo, msg)
  msg.reply({
    Action = "New-Market-Notice",
    MarketId = marketId,
    ConditionId = conditionId,
    ConditionalTokens = conditionalTokens,
    CollateralToken = collateralToken,
    CollectionIds = json.encode(collectionIds),
    PositionIds = json.encode(positionIds),
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Name = name,
    Ticker = ticker,
    Logo = logo,
    Data = "Successfully created market"
  })
end

function AMMNotices.fundingAddedNotice(from, sendBackAmounts, mintAmount)
  ao.send({
    Target = from,
    Action = "Funding-Added-Notice",
    SendBackAmounts = json.encode(sendBackAmounts),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

function AMMNotices.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  ao.send({
    Target = from,
    Action = "Funding-Removed-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
    SharesToBurn = tostring(sharesToBurn),
    Data = "Successfully removed funding"
  })
end

function AMMNotices.buyNotice(from, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy)
  ao.send({
    Target = from,
    Action = "Buy-Notice",
    InvestmentAmount = tostring(investmentAmount),
    FeeAmount = tostring(feeAmount),
    OutcomeIndex = tostring(outcomeIndex),
    OutcomeTokensToBuy = tostring(outcomeTokensToBuy),
    Data = "Successfully buy order"
  })
end

function AMMNotices.sellNotice(from, returnAmount, feeAmount, outcomeIndex, outcomeTokensToSell)
  ao.send({
    Target = from,
    Action = "Sell-Notice",
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    OutcomeIndex = tostring(outcomeIndex),
    OutcomeTokensToSell = tostring(outcomeTokensToSell),
    Data = "Successfully sell order"
  })
end

return AMMNotices