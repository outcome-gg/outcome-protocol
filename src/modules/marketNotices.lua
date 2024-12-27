local MarketNotices = {}
local json = require('json')

function MarketNotices.newMarketNotice(configurator, incentives, collateralToken, marketId, conditionId, positionIds, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
  return msg.reply({
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

return MarketNotices