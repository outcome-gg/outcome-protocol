local ao = require('.ao')
local json = require('json')

local AMMNotices = {}

function AMMNotices.newMarketNotice(collateralToken, conditionalTokens, conditionId, collectionIds, positionIds, fee, name, ticker, logo)
  ao.send({
    Target = DataIndex,
    Action = "New-Market-Notice",
    ConditionId = conditionId,
    ConditionalTokens = conditionalTokens,
    CollateralToken = collateralToken,
    CollectionIds = json.encode(collectionIds),
    PositionIds = json.encode(positionIds),
    Fee = fee,
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

function AMMNotices.sellNotice()
end

return AMMNotices