local ao = require('.ao')
local json = require('json')

local CPMMNotices = {}

function CPMMNotices.newMarketNotice(configurator, incentives, collateralToken, marketId, conditionId, positionIds, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
  msg.reply({
    Action = "New-Market-Notice",
    MarketId = marketId,
    ConditionId = conditionId,
    Configurator = configurator,
    Incentives = incentives,
    CollateralToken = collateralToken,
    PositionIds = json.encode(positionIds),
    OutcomeSlotCount = tostring(outcomeSlotCount),
    LpFee = lpFee,
    CreatorFee = creatorFee,
    CreatorFeeTarget = creatorFeeTarget,
    ProtocolFee = protocolFee,
    ProtocolFeeTarget = protocolFeeTarget,
    Name = name,
    Ticker = ticker,
    Logo = logo,
    Data = "Successfully created market"
  })
end

function CPMMNotices.fundingAddedNotice(from, sendBackAmounts, mintAmount)
  ao.send({
    Target = from,
    Action = "Funding-Added-Notice",
    SendBackAmounts = json.encode(sendBackAmounts),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

function CPMMNotices.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  ao.send({
    Target = from,
    Action = "Funding-Removed-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
    SharesToBurn = tostring(sharesToBurn),
    Data = "Successfully removed funding"
  })
end

function CPMMNotices.buyNotice(from, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
  ao.send({
    Target = from,
    Action = "Buy-Notice",
    InvestmentAmount = tostring(investmentAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    OutcomeTokensToBuy = tostring(outcomeTokensToBuy),
    Data = "Successful buy order"
  })
end

function CPMMNotices.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
  ao.send({
    Target = from,
    Action = "Sell-Notice",
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    OutcomeTokensToSell = tostring(outcomeTokensToSell),
    Data = "Successful sell order"
  })
end

function CPMMNotices.updateConfiguratorNotice(configurator, msg)
  msg.reply({
    Action = "Configurator-Updated",
    Data = configurator
  })
end

function CPMMNotices.updateIncentivesNotice(incentives, msg)
  msg.reply({
    Action = "Incentives-Updated",
    Data = incentives
  })
end

function CPMMNotices.updateTakeFeeNotice(creatorFee, protocolFee, takeFee, msg)
  msg.reply({
    Action = "Take-Fee-Updated",
    CreatorFee = creatorFee,
    ProtocolFee = protocolFee,
    Data = takeFee
  })
end

function CPMMNotices.updateProtocolFeeTargetNotice(protocolFeeTarget, msg)
  msg.reply({
    Action = "Protocol-Fee-Target-Updated",
    Data = protocolFeeTarget
  })
end

function CPMMNotices.updateLogoNotice(logo, msg)
  msg.reply({
    Action = "Logo-Updated",
    Data = logo
  })
end

return CPMMNotices